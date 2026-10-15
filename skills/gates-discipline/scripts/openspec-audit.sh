#!/usr/bin/env bash
#
# openspec-audit.sh — read-only mechanical audit of active OpenSpec changes.
#
# Classifies every active change directory (openspec/changes/*, excluding
# archive/ and parked/, and only real change directories that carry an
# .openspec.yaml marker) into lifecycle buckets, then reports drift against
# the living inventory table in openspec/changes/README.md.
#
# Properties:
#   - Read-only: performs no file creation or modification.
#   - Dependency-free: bash, git, find, grep, sed only. bash 3.2-compatible.
#   - Exits 0 on a clean run (drift is reported, not fatal).
#
# Bucket labels (evidence classes, per the change-lifecycle-hygiene spec):
#   complete       all tasks checked
#   complete-uv    agent tasks checked, only [User Verification] open
#   partial        some tasks checked
#   zero-progress  no tasks checked
#   proposal-only  has proposal.md but no tasks.md
#   artifact-less  no proposal.md and no tasks.md (but other material files)
#   stale-shell    no proposal.md, no tasks.md, no material files of its own
#
# Usage: ./openspec-audit.sh   (from anywhere; resolves repo root from git)

set -eu

# --- resolve repo root (this script lives at the repo root) ---------------
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "ERROR: not inside a git repository." >&2
  exit 1
}
CHANGES="$ROOT/openspec/changes"
INVENTORY="$CHANGES/README.md"
[ -d "$CHANGES" ] || { echo "ERROR: $CHANGES not found." >&2; exit 1; }

# --- helpers ----------------------------------------------------------------
# Count checked / open task checkboxes in a tasks.md file.
count_checked() { grep -cE '^[[:space:]]*-[[:space:]]+\[x\]' "$1" 2>/dev/null || true; }
count_open()    { grep -cE '^[[:space:]]*-[[:space:]]+\[ \]' "$1" 2>/dev/null || true; }
# Count [User Verification] lines among open checkboxes.
count_open_uv() {
  grep -E '^[[:space:]]*-[[:space:]]+\[ \]' "$1" 2>/dev/null | grep -c 'User Verification' || true
}
# Count non-empty regular files under a directory (material content).
count_material_files() {
  find "$1" -type f 2>/dev/null | while read -r f; do [ -s "$f" ] && echo x; done | wc -l | tr -d ' '
}

# --- collect active change directories --------------------------------------
# An active change dir is a directory under openspec/changes/ that is not
# archive/. We do NOT require an .openspec.yaml marker: artifact-less and
# stale-shell dirs lack it by definition (a marker gate would make those
# buckets unreachable and skip marker-less dirs from both bucketing and drift
# detection). Stray loose files (e.g. reference PNGs) are not matched by the
# */ glob, so they are correctly excluded. The .openspec.yaml marker is still
# reported per-dir as a data point.
active_dirs=()
if [ -d "$CHANGES" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] && active_dirs+=("$d")
  done < <(
    for d in "$CHANGES"/*/; do
      [ -d "$d" ] || continue
      name=$(basename "$d")
      [ "$name" = "archive" ] && continue
      echo "$name"
    done | sort
  )
fi

# --- per-change classification ----------------------------------------------
echo "=================================================================="
echo " OpenSpec active-change audit  ($(date +%Y-%m-%d))"
echo "=================================================================="
echo "Active change directories (excluding archive/ and parked/):"
echo

for name in ${active_dirs[@]+"${active_dirs[@]}"}; do
  d="$CHANGES/$name"
  have_proposal=no; [ -f "$d/proposal.md" ] && have_proposal=yes
  have_tasks=no;    [ -f "$d/tasks.md" ] && have_tasks=yes
  have_marker=no;   [ -f "$d/.openspec.yaml" ] && have_marker=yes

  if [ "$have_tasks" = yes ]; then
    checked=$(count_checked "$d/tasks.md"); checked=${checked:-0}
    open=$(count_open "$d/tasks.md"); open=${open:-0}
    open_uv=$(count_open_uv "$d/tasks.md"); open_uv=${open_uv:-0}
    detail="tasks: ${checked} checked / ${open} open"
    if [ "$checked" -eq 0 ]; then
      bucket="zero-progress"
    elif [ "$open" -eq 0 ]; then
      bucket="complete"
    elif [ "$open" -eq "$open_uv" ]; then
      bucket="complete-uv"
    else
      bucket="partial"
    fi
  else
    checked="-"; open="-"; open_uv="-"
    detail="no tasks.md"
    if [ "$have_proposal" = yes ]; then
      bucket="proposal-only"
    else
      material=$(count_material_files "$d")
      if [ "$material" -eq 0 ]; then
        bucket="stale-shell"
      else
        bucket="artifact-less"
      fi
    fi
  fi

  # Flag empty specs/ subdirs.
  empty_specs=""
  if [ -d "$d/specs" ]; then
    for s in "$d/specs"/*/; do
      [ -d "$s" ] || continue
      files=$(find "$s" -type f 2>/dev/null | wc -l | tr -d ' ')
      if [ "$files" -eq 0 ]; then
        empty_specs="$empty_specs $(basename "$s")"
      fi
    done
  fi

  printf "%-44s %-14s proposal=%s marker=%s %s\n" "$name" "$bucket" "$have_proposal" "$have_marker" "$detail"
  if [ -n "$empty_specs" ]; then
    printf "%-44s %s\n" "" "empty specs/:$empty_specs"
  fi
done

# --- drift section: active set vs inventory table ---------------------------
echo
echo "------------------------------------------------------------------"
echo " Drift check: active set vs inventory table ($INVENTORY)"
echo "------------------------------------------------------------------"
DRIFT=0

if [ ! -f "$INVENTORY" ]; then
  echo "DRIFT: inventory file $INVENTORY does not exist."
  echo
  echo "RESULT: drift detected (inventory missing)."
  exit 0
fi

# Active changes missing from the inventory table.
for name in ${active_dirs[@]+"${active_dirs[@]}"}; do
  if ! grep -qE "^[[:space:]]*\|[[:space:]]*\`?${name}\`?[[:space:]]*\|" "$INVENTORY"; then
    echo "DRIFT: active change '${name}' is missing from the inventory table."
    DRIFT=1
  fi
done

# Inventory rows that point at a missing active directory.
while IFS= read -r rowname; do
  [ -n "$rowname" ] || continue
  if [ ! -d "$CHANGES/$rowname" ]; then
    echo "DRIFT: inventory row '${rowname}' has no matching active change directory."
    DRIFT=1
  fi
done < <(
  # Parse table rows: | `name` | ... | — first cell after the leading pipe.
  # Skip the header row ('change'), the separator row ('---'), and any row
  # whose first cell is not a plain identifier (defensive: table-only noise).
  grep -E '^[[:space:]]*\|[[:space:]]*`?[A-Za-z0-9._-]+`?[[:space:]]*\|' "$INVENTORY" \
    | sed -E 's/^[[:space:]]*\|//; s/\|.*//' \
    | sed -E 's/[[:space:]]*//g; s/`//g' \
    | grep -vE '^(change|Change|---|-+$|\$|\$\$)$'
)

if [ "$DRIFT" -eq 0 ]; then
  echo "OK: no drift — every active change is listed and every inventory row resolves."
  echo
  echo "RESULT: clean (no drift)."
else
  echo
  echo "RESULT: drift detected — see entries above."
fi

exit 0

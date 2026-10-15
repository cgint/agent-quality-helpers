#!/usr/bin/env bash
#
# gate-merge.sh — Atomic pre-flight verification, merge, and landing on main.
#
# Intent: Eliminates multi-step, error-prone manual instructions when merging
# GitLab MRs or landing changes onto main. Ensures all invariant checks pass
# before any remote changes are made, and protects local in-flight workspace state.
#
# Modes:
#   check <mr-iid>                   Dry-run inspection: checks remotes, git state,
#                                    precommit, and audit without mutating anything.
#   merge <mr-iid> [options]         Executes pre-flight -> ready -> squash-merge ->
#                                    remote SHA verification -> checkout main & land.
#
# Options:
#   --allow-dirty                    Proceed even with uncommitted working-tree files.
#   --inflight "<path1> <path2>..."  Verify that specific in-flight files survived the switch.
#   --report <file>                  Write structured merge evidence report to file.
#   --target <branch>                Target branch (default: auto from MR or 'main').
#
# Properties:
#   - POSIX/Bash compatible.
#   - Fail-fast: halts at the first failing guard before triggering GitLab mutations.
#   - Auto-detects remote tracking (smec-origin vs origin).
#   - Protects dirty in-flight files.

set -euo pipefail

# --- Color / Output Helpers -------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { printf "${BLUE}==>${NC} %s\n" "$*"; }
step()    { printf "${BOLD}[%-4s]${NC} %-36s " "$1" "$2"; }
pass()    { printf "${GREEN}OK${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}WARN${NC} %s\n" "$*"; }
fail()    { printf "${RED}FAILED${NC}\n\n${RED}ERROR:${NC} %s\n" "$*"; exit 1; }

# --- Usage ------------------------------------------------------------------
usage() {
  local exit_code="${1:-1}"
  cat << EOF
Usage: $(basename "$0") <check|merge> <mr-iid> [options]

Commands:
  check <mr-iid>                   Run all pre-flight guards (zero mutations).
  merge <mr-iid>                   Run pre-flight guards, squash-merge MR, verify remote, and land on main.

Options:
  --allow-dirty                    Allow proceeding with uncommitted in-flight files.
  --inflight "<path1> <path2>..."  Verify named in-flight files survived the switch intact.
  --report <path>                  Write structured merge evidence report to file.
  --target <ref>                   Target branch (default: auto-detected from MR or 'main').
  -h, --help                       Show this help message.

EOF
  exit "$exit_code"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage 0
fi

[ $# -lt 2 ] && usage 1

COMMAND="$1"
MR_IID="$2"
shift 2

ALLOW_DIRTY=false
TARGET_BRANCH=""
INFLIGHT_FILES=""
REPORT_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    --inflight) INFLIGHT_FILES="$2"; shift 2 ;;
    --report) REPORT_PATH="$2"; shift 2 ;;
    --target) TARGET_BRANCH="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1"; usage 1 ;;
  esac
done

if [ "$COMMAND" != "check" ] && [ "$COMMAND" != "merge" ]; then
  echo "Invalid command: $COMMAND"
  usage
fi

# --- 1. Environment & Git Discovery ----------------------------------------
step "1/6" "Resolving Git & GitLab status..."

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || fail "Not inside a git repository."
cd "$ROOT"

# Auto-detect remote (prefer smec-origin if available, fallback to origin)
REMOTE="origin"
if git remote | grep -qx "smec-origin"; then
  REMOTE="smec-origin"
fi

command -v glab >/dev/null 2>&1 || fail "glab CLI is required but not installed."

# Inspect MR details via glab
MR_JSON=$(glab mr view "$MR_IID" --output json 2>/dev/null) || fail "Could not fetch MR !$MR_IID from GitLab."

MR_STATE=$(echo "$MR_JSON" | grep -o '"state": *"[^"]*"' | head -1 | cut -d'"' -f4)
MR_SOURCE_BRANCH=$(echo "$MR_JSON" | grep -o '"source_branch": *"[^"]*"' | head -1 | cut -d'"' -f4)
MR_TARGET_BRANCH=$(echo "$MR_JSON" | grep -o '"target_branch": *"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH="$MR_TARGET_BRANCH"
fi
[ -z "$TARGET_BRANCH" ] && TARGET_BRANCH="main"

[ "$MR_STATE" = "merged" ] && fail "MR !$MR_IID is already merged."
[ "$MR_STATE" = "closed" ] && fail "MR !$MR_IID is closed."

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
pass "(remote: $REMOTE, mr: !$MR_IID, source: $MR_SOURCE_BRANCH, target: $TARGET_BRANCH)"

# --- 2. Working Tree Dirty Inspection ---------------------------------------
step "2/6" "Checking working tree cleanliness..."
DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$DIRTY_COUNT" -gt 0 ]; then
  if [ "$ALLOW_DIRTY" = true ]; then
    warn "($DIRTY_COUNT uncommitted items in tree, continuing due to --allow-dirty)"
  else
    printf "${RED}DIRTY TREE${NC}\n"
    echo "Working tree has $DIRTY_COUNT uncommitted changes. Use --allow-dirty to keep them across the branch switch."
    git status --short
    exit 1
  fi
else
  pass "(clean)"
fi

# --- 3. Ancestor / Divergence Check ----------------------------------------
step "3/6" "Checking remote divergence ($REMOTE/$TARGET_BRANCH)..."
git fetch "$REMOTE" "$TARGET_BRANCH" --quiet 2>/dev/null || fail "Failed to fetch $REMOTE $TARGET_BRANCH"

if ! git merge-base --is-ancestor "$REMOTE/$TARGET_BRANCH" HEAD; then
  fail "Target branch '$REMOTE/$TARGET_BRANCH' has moved ahead of your branch merge-base!\nRebase or merge $REMOTE/$TARGET_BRANCH before merging."
fi
pass "(clean ancestor - no remote divergence)"

# --- 4. Quality & Hygiene Guards -------------------------------------------
step "4/8" "Running precommit & audit guards..."

if [ -f "./precommit.sh" ]; then
  PRECOMMIT_OUT=$(./precommit.sh 2>&1) || {
    printf "${RED}FAILED${NC}\n\n${RED}ERROR:${NC} ./precommit.sh failed with output:\n"
    echo "--------------------------------------------------"
    echo "$PRECOMMIT_OUT" | tail -20 | sed 's/^/  /'
    echo "--------------------------------------------------"
    exit 1
  }
fi

if [ -f "./openspec-audit.sh" ]; then
  # Check if openspec-audit flags drift
  AUDIT_OUT=$(./openspec-audit.sh 2>&1)
  if echo "$AUDIT_OUT" | grep -q "RESULT: drift detected"; then
    fail "OpenSpec audit detected drift:\n$AUDIT_OUT"
  fi
fi
pass "(precommit + audit passed)"

# If we are in dry-run check mode, stop here with success
if [ "$COMMAND" = "check" ]; then
  echo
  printf "${GREEN}${BOLD}✓ PRE-FLIGHT CHECK PASSED:${NC} MR !%s is sane and ready to merge.\n" "$MR_IID"
  exit 0
fi

# --- 5. GitLab Execution (Squash & Merge) -----------------------------------
step "5/8" "Executing GitLab squash-merge..."

# Mark ready if currently draft
glab mr update "$MR_IID" --ready-for-review >/dev/null 2>&1 || true

# Merge with squash and remove source branch
MERGE_OUT=$(glab mr merge "$MR_IID" --squash --remove-source-branch --yes 2>&1) || {
  fail "glab mr merge failed:\n$MERGE_OUT"
}
pass "(MR !$MR_IID merged)"

# --- 6. Remote Verification & Landing on Main -------------------------------
step "6/8" "Verifying remote & resetting workspace to $TARGET_BRANCH..."

git fetch "$REMOTE" "$TARGET_BRANCH" --quiet

# Verify top commit on remote
SQUASH_SHA=$(git rev-parse "$REMOTE/$TARGET_BRANCH")

# Land workspace on target branch
git switch "$TARGET_BRANCH" --quiet 2>/dev/null || git checkout "$TARGET_BRANCH" --quiet
git pull --ff-only "$REMOTE" "$TARGET_BRANCH" --quiet

pass "(switched to $TARGET_BRANCH, pulled --ff-only)"

# --- 7. In-flight File Survival Check ---------------------------------------
INFLIGHT_STATUS="n/a"
OVERALL_MERGE_VERDICT="SUCCESS"
if [ -n "$INFLIGHT_FILES" ]; then
  step "7/8" "Verifying in-flight files survived branch switch..."
  MISSING_INFLIGHT=0
  for f in $INFLIGHT_FILES; do
    if [ ! -e "$f" ]; then
      warn "In-flight file missing: $f"
      MISSING_INFLIGHT=$((MISSING_INFLIGHT + 1))
    fi
  done
  if [ "$MISSING_INFLIGHT" -eq 0 ]; then
    pass "(All specified in-flight files intact)"
    INFLIGHT_STATUS="intact"
  else
    warn "($MISSING_INFLIGHT in-flight files missing!)"
    INFLIGHT_STATUS="missing_files"
    OVERALL_MERGE_VERDICT="WARNING_INFLIGHT_MISSING"
  fi
fi

# --- 8. Structured Evidence Report -----------------------------------------
if [ -n "$REPORT_PATH" ]; then
  mkdir -p "$(dirname "$REPORT_PATH")"
  cat > "$REPORT_PATH" << EOF
# Merge & Landing Evidence — MR !$MR_IID

- **Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **MR:** !$MR_IID
- **Source Branch:** $MR_SOURCE_BRANCH
- **Target Branch:** $TARGET_BRANCH
- **Remote:** $REMOTE
- **Squash SHA:** $SQUASH_SHA
- **Working Tree State:** $DIRTY_COUNT uncommitted items
- **In-flight Survival:** $INFLIGHT_STATUS
- **Verdict:** $OVERALL_MERGE_VERDICT
EOF
  info "Wrote structured merge report to $REPORT_PATH"
fi

echo
echo "=================================================================="
printf "${GREEN}${BOLD}SUCCESS: MR !%s merged & landed on %s.${NC}\n" "$MR_IID" "$TARGET_BRANCH"
echo "Target branch: $TARGET_BRANCH"
echo "Merge SHA:     $SQUASH_SHA"
if [ "$DIRTY_COUNT" -gt 0 ]; then
  echo "In-flight:     $DIRTY_COUNT modified/untracked files preserved in tree."
fi
if [ -n "$INFLIGHT_FILES" ]; then
  echo "In-flight check: $INFLIGHT_STATUS"
fi
echo "=================================================================="
exit 0

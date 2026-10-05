#!/usr/bin/env bash
#
# gate-check.sh — Mechanical validator for living task ledgers (GATES_*.md).
#
# Intent: Provides an instantaneous, dependency-free check of the current gate,
# gate permissions, and worker launch safety. Can be used by supervisors,
# CI, or preflight scripts before launching delegated workers.
#
# Usage:
#   gate-check.sh [ledger-file]                     # Print current gate & status summary
#   gate-check.sh [ledger-file] --assert <N>         # Exit 0 if current_gate == N, else exit 1
#   gate-check.sh [ledger-file] --allowed-mode       # Print 'readonly' or 'editable' for current gate
#   gate-check.sh [ledger-file] --preflight <gate> <mode> # Strict check: gate matches & mode allowed
#   gate-check.sh [ledger-file] --worktree <target>  # Verify running inside expected git worktree
#   gate-check.sh [ledger-file] --json               # Output parsed machine state as JSON
#
# Invariants:
#   - Dependency-free: awk, sed, grep only (POSIX/bash 3.2+).
#   - Parses YAML between ```yaml and ``` within ## Machine State.
#   - Read-only, zero side-effects.

set -euo pipefail

# Action early help check
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat << EOF
Usage: $(basename "$0") [ledger-file] [options]

Commands & Options:
  [ledger-file]                     Print current gate & status summary
  [ledger-file] --assert <N>        Exit 0 if current_gate == N, else exit 1
  [ledger-file] --allowed-mode      Print 'readonly' or 'editable' for current gate
  [ledger-file] --preflight <gate> <mode> Strict check: gate matches & mode allowed
  [ledger-file] --worktree <target> Verify running inside expected git worktree
  [ledger-file] --json              Output parsed machine state as JSON
  -h, --help                        Show this help message
EOF
  exit 0
fi

# Parse arguments cleanly: separate ledger path from options
LEDGER=""
FLAG=""
FLAG_ARGS=()

if [ $# -gt 0 ]; then
  if [[ "$1" != --* ]]; then
    LEDGER="$1"
    shift
  fi
fi

if [ $# -gt 0 ]; then
  FLAG="$1"
  shift
  FLAG_ARGS=("$@")
fi

# Auto-discover task ledger if not explicitly passed
if [ -z "$LEDGER" ]; then
  CWD_LEDGERS=($(find . -maxdepth 1 -name "GATES_*.md" 2>/dev/null || true))
  LEDGER_COUNT=${#CWD_LEDGERS[@]}

  if [ "$LEDGER_COUNT" -eq 1 ]; then
    LEDGER="${CWD_LEDGERS[0]}"
  elif [ "$LEDGER_COUNT" -gt 1 ]; then
    echo "ERROR: Multiple task ledgers found in current directory:" >&2
    for l in "${CWD_LEDGERS[@]}"; do echo "  - $l" >&2; done
    echo "Specify the target ledger explicitly (e.g. $(basename "$0") ${CWD_LEDGERS[0]} ...)" >&2
    exit 2
  else
    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -n "$ROOT" ] && [ "$ROOT" != "$(pwd)" ]; then
      ROOT_LEDGERS=($(find "$ROOT" -maxdepth 1 -name "GATES_*.md" 2>/dev/null || true))
      ROOT_COUNT=${#ROOT_LEDGERS[@]}
      if [ "$ROOT_COUNT" -eq 1 ]; then
        LEDGER="${ROOT_LEDGERS[0]}"
      elif [ "$ROOT_COUNT" -gt 1 ]; then
        echo "ERROR: Multiple task ledgers found in repo root ($ROOT):" >&2
        for l in "${ROOT_LEDGERS[@]}"; do echo "  - $l" >&2; done
        echo "Specify the target ledger explicitly." >&2
        exit 2
      fi
    fi
  fi
fi

if [ -z "$LEDGER" ] || [ ! -f "$LEDGER" ]; then
  SEARCH_LOC="current directory $(pwd)"
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [ -n "$ROOT" ] && SEARCH_LOC="$SEARCH_LOC and repo root $ROOT"
  echo "ERROR: Task ledger not found (searched in $SEARCH_LOC)." >&2
  echo "Provide path to GATES_<task>.md or create one." >&2
  exit 2
fi

# Extract YAML inside ```yaml fence under ## Machine State
extract_yaml() {
  awk '
    BEGIN { in_section=0; in_fence=0 }
    /^## Machine State/ { in_section=1; next }
    in_section && /^```yaml/ { in_fence=1; next }
    in_section && in_fence && /^```/ { exit }
    in_section && in_fence { print }
  ' "$LEDGER"
}

YAML_CONTENT=$(extract_yaml)

if [ -z "$YAML_CONTENT" ]; then
  # Fallback: check top-of-file frontmatter if someone used standard Jekyll frontmatter
  YAML_CONTENT=$(awk '
    NR==1 && /^---$/ { in_fence=1; next }
    in_fence && /^---$/ { exit }
    in_fence { print }
  ' "$LEDGER")
fi

if [ -z "$YAML_CONTENT" ]; then
  echo "ERROR: No valid machine state found in $LEDGER (expected fenced \`\`\`yaml under ## Machine State)." >&2
  exit 2
fi

# Extract current_gate
CURRENT_GATE=$(echo "$YAML_CONTENT" | awk -F':' '/^[[:space:]]*current_gate:/ { gsub(/[[:space:]]/, "", $2); print $2 }')

if [ -z "$CURRENT_GATE" ]; then
  echo "ERROR: 'current_gate' not defined in $LEDGER machine state." >&2
  exit 2
fi

# Determine allowed mode based on canonical GATES rule:
# Gate 1 (Explore): readonly
# Gate 2 (Concept / Spec): readonly (only specs/proposal authored, review is readonly)
# Gate 3 (Implementation / TDD): editable
# Gate 4 (Review, Merge & Land): readonly
ALLOWED_MODE="readonly"
if [ "$CURRENT_GATE" -eq 3 ]; then
  ALLOWED_MODE="editable"
fi

# Action dispatch
case "$FLAG" in
  --assert)
    EXPECTED="${FLAG_ARGS[0]:-}"
    if [ -z "$EXPECTED" ]; then
      echo "ERROR: --assert requires expected gate number (e.g. --assert 2)" >&2
      exit 2
    fi
    if [ "$CURRENT_GATE" -ne "$EXPECTED" ]; then
      echo "GATE MISMATCH: Ledger current_gate is $CURRENT_GATE, expected $EXPECTED" >&2
      exit 1
    fi
    exit 0
    ;;

  --allowed-mode)
    echo "$ALLOWED_MODE"
    exit 0
    ;;

  --current-gate)
    echo "$CURRENT_GATE"
    exit 0
    ;;

  --preflight)
    WORK_GATE="${FLAG_ARGS[0]:-}"
    WORK_MODE="${FLAG_ARGS[1]:-}"
    if [ -z "$WORK_GATE" ] || [ -z "$WORK_MODE" ]; then
      echo "ERROR: --preflight requires <gate-number> <mode> (e.g. --preflight 2 readonly)" >&2
      exit 2
    fi

    # 1. Gate match check: work_gate == current_gate
    if [ "$WORK_GATE" -ne "$CURRENT_GATE" ]; then
      echo "PREFLIGHT FAILED: Requested work is for Gate $WORK_GATE, but ledger is at Gate $CURRENT_GATE." >&2
      echo "Moving to a future gate requires passing exit criteria first. Regressing requires explicit ledger update." >&2
      exit 1
    fi

    # 2. Mode permission check
    if [ "$WORK_MODE" = "editable" ] && [ "$ALLOWED_MODE" != "editable" ]; then
      echo "PREFLIGHT FAILED: Mode 'editable' is FORBIDDEN at Gate $CURRENT_GATE. Only '$ALLOWED_MODE' authorized." >&2
      exit 1
    fi

    echo "PREFLIGHT PASSED: Gate $WORK_GATE ($WORK_MODE) authorized per $LEDGER"
    exit 0
    ;;

  --worktree)
    EXPECTED_TREE="${FLAG_ARGS[0]:-}"
    if [ -z "$EXPECTED_TREE" ]; then
      echo "ERROR: --worktree requires expected worktree name or path" >&2
      exit 2
    fi
    ACTUAL_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    ACTUAL_NAME=$(basename "$ACTUAL_ROOT")
    if [ "$ACTUAL_ROOT" != "$EXPECTED_TREE" ] && [ "$ACTUAL_NAME" != "$EXPECTED_TREE" ]; then
      echo "WORKTREE MISMATCH: Operating in '$ACTUAL_ROOT' (basename: '$ACTUAL_NAME'), expected '$EXPECTED_TREE'." >&2
      echo "Re-anchor to the correct worktree before running operations." >&2
      exit 1
    fi
    echo "WORKTREE OK: Operating inside '$ACTUAL_ROOT'"
    exit 0
    ;;

  --json)
    # Lightweight, escaped JSON output for ledger status
    ESCAPED_LEDGER=$(printf '%s' "$LEDGER" | sed 's/\\/\\\\/g; s/"/\\"/g')
    cat << EOF
{
  "ledger": "$ESCAPED_LEDGER",
  "current_gate": $CURRENT_GATE,
  "allowed_mode": "$ALLOWED_MODE"
}
EOF
    exit 0
    ;;

  *)
    echo "=================================================================="
    echo " Task Ledger Gate Status: $(basename "$LEDGER")"
    echo "=================================================================="
    echo "Current Gate:      Gate $CURRENT_GATE"
    echo "Authorized Mode:   $ALLOWED_MODE"
    echo "------------------------------------------------------------------"
    echo "Gate States:"
    echo "$YAML_CONTENT" | grep -E '^[[:space:]]*gate_[0-9]:' | sed 's/^[[:space:]]*/  - /'
    echo "=================================================================="
    ;;
esac

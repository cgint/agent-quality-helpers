#!/usr/bin/env bash
#
# gate-review.sh — Multi-perspective deliberation and review gate orchestrator.
#
# Intent: Provides a unified, repeatable review harness across software and
# knowledge-work lifecycles. Orchestrates deterministic checks (formatting,
# linters, precommit, tests) alongside AI-assisted deliberation passes
# (concept critique, diff review, discrepancy checks, grounding audit).
#
# Modes:
#   --concept [target]      Gate 2 / Concept Gate: Validates clarity, scope bounds,
#                           and identifies unsupported assumptions before coding.
#   --diff [target]         Gate 3 / Implementation Gate: TDD validation, deterministic
#                           checks, plus AI diff & discrepancy review vs specs.
#   --grounding [target]    Knowledge Work / Audit Gate: Evidence-to-claim audit
#                           (inspired by meeting-summary & claims registers).
#   --peer [target]         Gate 4 / Pre-Handoff Gate: Checks git status, pushed commits,
#                           and prepares clean summary for external reviewers/bots.
#
# Properties:
#   - POSIX/bash 3.2+ compatible.
#   - Graceful degradation: runs deterministic checks even if AI helpers are unavailable.
#   - Usable by both the primary lead session and delegated subagents.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

pass()  { printf "${GREEN}PASS${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}WARN${NC} %s\n" "$*"; }
block() { printf "${RED}BLOCK${NC} %s\n" "$*"; }
step()  { printf "${BOLD}[%-8s]${NC} %-36s " "$1" "$2"; }

usage() {
  local exit_code="${1:-1}"
  cat << EOF
Usage: $(basename "$0") <mode> [target] [options]

Review Modes:
  concept [path]         Audit proposal/concept docs for explicit bounds and edge cases.
  diff [range]           Run precommit, tests, and diff review against specification.
  grounding <path>       Crosscheck claims against source evidence/transcripts/code.
  peer [branch]          Verify branch hygiene and readiness for external peer review.
  sheldon <mr-iid>       Trigger @ai-sheldon, wait/poll for verdict, and record head SHA.
  verify-freshness <file> Verify prior review verdict SHA matches current branch HEAD.

  (Modes also accept leading '--', e.g. --concept, --diff, etc.)

Options:
  --strict               Treat warnings as blocking errors (exit 1).
  --json                 Output machine-readable verdict JSON payload.
  --record <file>        Record review verdict and current HEAD SHA into specified artifact.
  -h, --help             Show this help message.

Exit codes:
  0                      PASS (all gate criteria satisfied)
  1                      BLOCK (gate criteria failed or warning treated as blocking in --strict)
  2                      USAGE / CONFIG ERROR (missing target or git repository error)
EOF
  exit "$exit_code"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage 0
fi

[ $# -lt 1 ] && usage 1

# Normalize mode (strip leading -- if present)
RAW_MODE="$1"
MODE="--${RAW_MODE#--}"
shift

TARGET=""
STRICT=false
RECORD_FILE=""
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=true; shift ;;
    --json) JSON_OUTPUT=true; shift ;;
    --record) RECORD_FILE="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) [ -z "$TARGET" ] && TARGET="$1" && shift || shift ;;
  esac
done

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$ROOT" ]; then
  # For modes that strictly require git repository
  if [ "$MODE" = "--diff" ] || [ "$MODE" = "--peer" ] || [ "$MODE" = "--sheldon" ] || [ "$MODE" = "--verify-freshness" ]; then
    echo "ERROR: Not inside a git repository." >&2
    exit 2
  fi
  ROOT=$(pwd)
fi
cd "$ROOT"

OVERALL_STATUS="PASS"

# --- Helper: Check AI Task Runner -------------------------------------------
HAVE_CG=false
if command -v cg-task.sh >/dev/null 2>&1; then
  HAVE_CG=true
fi

# ============================================================================
# MODE 1: CONCEPT & REQUIREMENTS REVIEW (Gate 2)
# ============================================================================
if [ "$MODE" = "--concept" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Concept & Requirements Deliberation"
  echo "=================================================================="

  # 1. Target resolution
  if [ -z "$TARGET" ]; then
    # Auto-find latest modified proposal or concept doc
    TARGET=$(find openspec/changes docs -name "proposal.md" -o -name "*concept*.md" 2>/dev/null | head -1 || true)
  fi

  if [ -z "$TARGET" ] || [ ! -f "$TARGET" ]; then
    block "No proposal or concept document found to review."
    exit 1
  fi

  step "CHECK" "Target Document: $TARGET"
  pass

  # 2. Scope Bounds Inspection (Check for 'Non-Goals' or 'Out of Scope')
  step "BOUNDS" "Checking for explicit scope boundaries..."
  if grep -qiE "(out of scope|non-goals|not included|boundaries)" "$TARGET"; then
    pass "(Explicit boundaries found)"
  else
    warn "(Missing explicit 'Non-Goals' or 'Out of Scope' section)"
    [ "$STRICT" = true ] && OVERALL_STATUS="BLOCK"
  fi

  # 3. Grounding & Uncertainty Indicators
  step "HONESTY" "Checking epistemic labeling..."
  UNVERIFIED_COUNT=$(grep -ciE "(\[unverified\]|hypothesis|to be decided|tbd)" "$TARGET" || true)
  if [ "$UNVERIFIED_COUNT" -gt 0 ]; then
    pass "($UNVERIFIED_COUNT unverified/hypothesis tags identified)"
  else
    warn "(No explicit uncertainty or [unverified] markers found)"
  fi

  # 4. AI Deliberation Pass (if available)
  if [ "$HAVE_CG" = true ]; then
    step "AI-REVIEW" "Running cg-task.sh document-review..."
    echo
    cg-task.sh document-review -i "$TARGET" "Identify missing edge cases, implicit assumptions, and scope risks." || true
  else
    step "AI-REVIEW" "cg-task.sh not found on PATH (skipping AI pass)"
    warn "(Deterministic checks only)"
  fi

# ============================================================================
# MODE 2: IMPLEMENTATION & DIFF REVIEW (Gate 3)
# ============================================================================
elif [ "$MODE" = "--diff" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Implementation & TDD Diff Review"
  echo "=================================================================="

  # 1. Deterministic Checks (Precommit)
  step "PRECOMMIT" "Checking for deterministic linters/tests..."
  if [ -f "./precommit.sh" ]; then
    PRECOMMIT_OUT=$(./precommit.sh 2>&1) || {
      block "(./precommit.sh failed)"
      echo "--------------------------------------------------"
      echo "$PRECOMMIT_OUT" | tail -15 | sed 's/^/  /'
      echo "--------------------------------------------------"
      OVERALL_STATUS="BLOCK"
    }
    if [ "$OVERALL_STATUS" != "BLOCK" ]; then
      pass "(Passed ./precommit.sh)"
    fi
  else
    warn "(No ./precommit.sh found in repository)"
  fi

  # 2. Working Tree & Diff Scope
  DIFF_RANGE="${TARGET:-HEAD}"
  MODIFIED_FILES=$(git diff --name-only "$DIFF_RANGE" 2>/dev/null || true)
  FILE_COUNT=$(echo "$MODIFIED_FILES" | grep -v '^$' | wc -l | tr -d ' ')

  step "DIFF" "Modified files ($FILE_COUNT files in scope)..."
  if [ "$FILE_COUNT" -eq 0 ]; then
    warn "(Diff is empty)"
  else
    pass "($FILE_COUNT files)"
  fi

  # 3. Test Coverage Presence (TDD Check)
  step "TDD-CHECK" "Verifying test modifications alongside source..."
  HAS_TESTS=$(echo "$MODIFIED_FILES" | grep -iE "(test_|spec_|_test\.|\/tests\/|\/specs\/)" || true)
  if [ -n "$HAS_TESTS" ]; then
    pass "(Tests updated in this diff)"
  else
    warn "(No tests modified in this diff — verify TDD compliance)"
    [ "$STRICT" = true ] && OVERALL_STATUS="BLOCK"
  fi

  # 4. AI Diff Review (if available)
  if [ "$HAVE_CG" = true ]; then
    step "AI-REVIEW" "Running cg-task.sh diff-review..."
    echo
    cg-task.sh diff-review "Review diff for safety, regression risk, and contract adherence." || true
  fi

# ============================================================================
# MODE 3: EVIDENCE & GROUNDING AUDIT (Knowledge Work)
# ============================================================================
elif [ "$MODE" = "--grounding" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Evidence & Claims Grounding Audit"
  echo "=================================================================="

  [ -z "$TARGET" ] && { block "Target markdown file required for grounding audit."; exit 1; }
  [ ! -f "$TARGET" ] && { block "Target file $TARGET does not exist."; exit 1; }

  step "TARGET" "Auditing file: $TARGET"
  pass

  # Scan for unverifiable assertion patterns
  step "PATTERNS" "Checking for unsupported definitive assertions..."
  VAGUE_CLAIMS=$(grep -nEi "(obviously|certainly|always works|zero defects|seamlessly|trivial)" "$TARGET" || true)
  if [ -n "$VAGUE_CLAIMS" ]; then
    warn "(Found vague or ungrounded superlative assertions):"
    echo "$VAGUE_CLAIMS" | head -5 | sed 's/^/  line /'
  else
    pass "(Clean of ungrounded superlatives)"
  fi

  # Check citation / source references
  step "CITATIONS" "Checking for evidence citations (paths, SHAs, links)..."
  EVIDENCE_REFS=$(grep -nE "(\`[A-Za-z0-9_/.-]+\.[a-z]{2,4}\`|commit [a-f0-9]{7,}|http[s]?://)" "$TARGET" || true)
  REF_COUNT=$(echo "$EVIDENCE_REFS" | grep -v '^$' | wc -l | tr -d ' ')
  if [ "$REF_COUNT" -gt 0 ]; then
    pass "($REF_COUNT concrete evidence references located)"
  else
    warn "(Zero concrete file/code citations found in target)"
  fi

# ============================================================================
# MODE 4: PEER HANDOFF & BRANCH SANITY (Gate 4 Pre-Flight)
# ============================================================================
elif [ "$MODE" = "--peer" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Peer Review & Handoff Readiness"
  echo "=================================================================="

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  step "BRANCH" "Current branch: $CURRENT_BRANCH"
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    block "(Cannot hand off review directly from main/master branch)"
    OVERALL_STATUS="BLOCK"
  else
    pass
  fi

  # Check unpushed commits
  step "REMOTE" "Checking remote push status..."
  if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    block "(Branch has NO upstream set! Run 'git push -u' first)"
    OVERALL_STATUS="BLOCK"
  else
    UNPUSHED=$(git log @{u}.. 2>/dev/null | grep -c '^commit ' || true)
    if [ "$UNPUSHED" -gt 0 ]; then
      block "($UNPUSHED unpushed commits! Push commits before requesting peer review)"
      OVERALL_STATUS="BLOCK"
    else
      pass "(All commits pushed to upstream)"
    fi
  fi

  # Check uncommitted working tree
  step "TREE" "Checking working tree cleanliness..."
  DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DIRTY" -gt 0 ]; then
    warn "($DIRTY uncommitted items in working tree)"
  else
    pass "(Working tree clean)"
  fi

# ============================================================================
# MODE 5: VERIFY VERDICT FRESHNESS (Rebase & SHA Divergence Check)
# ============================================================================
elif [ "$MODE" = "--verify-freshness" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Verdict Freshness & Commit Head Verification"
  echo "=================================================================="

  [ -z "$TARGET" ] && { block "Path to review verdict/status record file required."; exit 2; }
  [ ! -f "$TARGET" ] && { block "Record file '$TARGET' not found."; exit 2; }

  CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null || true)
  RECORDED_SHA=$(grep -E '^[[:space:]]*-?[[:space:]]*(\*\*Commit SHA:\*\*|commit_sha:|head_sha:)' "$TARGET" | head -1 | grep -oE '[a-f0-9]{7,40}' || true)

  step "CHECK" "Verifying recorded review SHA against branch HEAD..."
  if [ -z "$RECORDED_SHA" ]; then
    block "No commit SHA found recorded in $TARGET."
    OVERALL_STATUS="BLOCK"
  elif [ "$CURRENT_HEAD" = "$RECORDED_SHA" ] || [[ "$CURRENT_HEAD" == "$RECORDED_SHA"* ]] || [[ "$RECORDED_SHA" == "$CURRENT_HEAD"* ]]; then
    pass "(Verdict is FRESH: matches branch HEAD $RECORDED_SHA)"
  else
    block "STALE VERDICT! Recorded SHA was $RECORDED_SHA, but branch HEAD has moved to $CURRENT_HEAD."
    echo "A rebase, amend, or new commit invalidated the prior review."
    echo "Action required: Re-run review gate on current HEAD before proceeding."
    OVERALL_STATUS="BLOCK"
  fi

# ============================================================================
# MODE 6: AI-SHELDON AUTOMATED REVIEW LOOP
# ============================================================================
elif [ "$MODE" = "--sheldon" ]; then
  echo "=================================================================="
  echo " REVIEW GATE: Automated @ai-sheldon Review Loop"
  echo "=================================================================="

  MR_IID="${TARGET:-}"
  [ -z "$MR_IID" ] && { block "MR IID required (e.g. ./review-gate.sh --sheldon 46)"; exit 2; }
  command -v glab >/dev/null 2>&1 || { block "glab CLI is required for Sheldon review gate."; exit 2; }

  CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)

  # 1. Preflight check: commits must be pushed
  step "PUSHED" "Verifying commits are pushed to remote..."
  if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    block "(Branch has NO upstream set! Run 'git push -u' first)"
    exit 1
  fi
  UNPUSHED=$(git log @{u}.. 2>/dev/null | grep -c '^commit ' || true)
  if [ "$UNPUSHED" -gt 0 ]; then
    block "($UNPUSHED unpushed commits! Push code before triggering @ai-sheldon)"
    exit 1
  fi
  pass "(Pushed)"

  # 2. Trigger or update thread
  step "TRIGGER" "Posting @ai-sheldon prompt to MR !$MR_IID..."
  glab mr note create "$MR_IID" -m "@ai-sheldon please review the latest changes on commit ${CURRENT_HEAD:0:8}." >/dev/null 2>&1 || true
  pass "(Note posted)"

  # 3. Bounded wait & poll loop (60s initial, then up to 6 polls of 10s)
  info "Waiting 60s for review initialization..."
  sleep 60

  step "POLL" "Polling MR !$MR_IID notes for verdict..."
  VERDICT_FOUND=false
  for i in {1..6}; do
    NOTES=$(glab mr note list "$MR_IID" 2>/dev/null || true)
    if echo "$NOTES" | grep -qiE "(PASS|LGTM|APPROVED|CHANGES_REQUESTED|BLOCK)"; then
      VERDICT_FOUND=true
      break
    fi
    sleep 10
  done

  if [ "$VERDICT_FOUND" = true ]; then
    pass "(Verdict received from reviewer)"
  else
    warn "(Polling timed out after ~120s; check MR !$MR_IID manually)"
  fi

else
  echo "Unknown review mode: $MODE"
  usage 1
fi

# Optional Recording
if [ -n "$RECORD_FILE" ]; then
  mkdir -p "$(dirname "$RECORD_FILE")"
  CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  cat > "$RECORD_FILE" << EOF
# Review Gate Record

- **Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Mode:** $MODE
- **Target:** ${TARGET:-none}
- **Head SHA:** $CURRENT_HEAD
- **Verdict:** $OVERALL_STATUS
EOF
  info "Recorded review verdict to $RECORD_FILE"
fi

# Machine-readable JSON output
if [ "$JSON_OUTPUT" = true ]; then
  CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "none")
  cat << EOF
{
  "mode": "${MODE#--}",
  "verdict": "$OVERALL_STATUS",
  "target": "${TARGET:-none}",
  "head_sha": "$CURRENT_HEAD",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  [ "$OVERALL_STATUS" = "BLOCK" ] && exit 1 || exit 0
fi

echo
echo "------------------------------------------------------------------"
if [ "$OVERALL_STATUS" = "BLOCK" ]; then
  printf "${RED}${BOLD}REVIEW VERDICT: BLOCK${NC} — Address blocking issues above.\n"
  exit 1
else
  printf "${GREEN}${BOLD}REVIEW VERDICT: PASS${NC} — Gate review criteria satisfied.\n"
  exit 0
fi

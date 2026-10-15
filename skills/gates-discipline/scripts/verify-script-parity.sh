#!/usr/bin/env bash
#
# verify-script-parity.sh — Assert that the bundled skill copies of the
# gate-*.sh scripts are byte-identical to their canonical root-level originals.
#
# Intent: Catch silent drift the moment a root-level maintenance fix lands
# without a matching update to the bundled skill copies, before it ships.
#
# Usage:
#   scripts/verify-script-parity.sh
#
# Exit 0 if all bundled copies match their root originals; exit 1 (with a
# clear per-file diff) if any copy has drifted. Run this as part of precommit
# whenever gate-check.sh, gate-review.sh, or gate-merge.sh is edited at the
# repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

DRIFTED=0
for name in gate-check.sh gate-review.sh gate-merge.sh openspec-audit.sh; do
  root_file="$REPO_ROOT/$name"
  bundled_file="$SCRIPT_DIR/$name"
  if ! diff -q "$root_file" "$bundled_file" > /dev/null 2>&1; then
    echo "DRIFT DETECTED: $bundled_file differs from $root_file"
    diff "$root_file" "$bundled_file" || true
    DRIFTED=1
  fi
done

# Also guard the ledger template against drift
ASSETS_DIR="$SCRIPT_DIR/../assets"
if ! diff -q "$REPO_ROOT/GATES_TEMPLATE.md" "$ASSETS_DIR/GATES_TEMPLATE.md" > /dev/null 2>&1; then
  echo "DRIFT DETECTED: $ASSETS_DIR/GATES_TEMPLATE.md differs from $REPO_ROOT/GATES_TEMPLATE.md"
  diff "$REPO_ROOT/GATES_TEMPLATE.md" "$ASSETS_DIR/GATES_TEMPLATE.md" || true
  DRIFTED=1
fi

if [ "$DRIFTED" -ne 0 ]; then
  echo "FAIL: bundled skill scripts have drifted from their root originals. Re-sync and re-run."
  exit 1
fi

echo "OK: all bundled gate-*.sh scripts match their root-level originals."

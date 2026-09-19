#!/usr/bin/env bash
# Run the headless test scene and FAIL on any script error, not only on a failed check
# (a parse error in one class silently skips every check that used it).
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}
OUT=$(timeout 600 "$GODOT" --headless --path . res://tests/run_tests.tscn 2>&1)
CODE=$?
echo "$OUT" | grep -v '^\s*$'
ERRS=$(echo "$OUT" | grep -c -E 'SCRIPT ERROR|^ERROR:|USER ERROR' || true)
if [ "$ERRS" != "0" ]; then echo "!! $ERRS engine error line(s) — see above"; exit 2; fi
# "0 checks passed" with no failures also prints TESTS_OK; a run that asserted
# nothing is not a green run.
grep -q "^0 checks passed" <<< "$OUT" && { echo "!! 0 checks ran"; exit 1; }
echo "$OUT" | grep -q '^TESTS_OK' || { echo "!! TESTS_OK not printed (exit $CODE)"; exit 1; }
exit 0

#!/usr/bin/env bash
# Run the headless test scene and FAIL on any script error, not only on a failed check.
# A parse error in one class silently skips every check that used it (it happened in the
# sibling: 90 passed with idle.gd not compiled), so the run is only green when the engine
# printed no errors at all.
#
# Regenerate the JS side first if the shipped kernel changed:
#   node tests/conformance_gen.cjs
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}
OUT=$(timeout 600 "$GODOT" --headless --path . res://tests/run_tests.tscn 2>&1)
CODE=$?
echo "$OUT" | grep -v '^\s*$' | tail -40
ERRS=$(echo "$OUT" | grep -c -E 'SCRIPT ERROR|^ERROR:|USER ERROR' || true)
if [ "$ERRS" != "0" ]; then echo "!! $ERRS engine error line(s) — see above"; exit 2; fi
echo "$OUT" | grep -q '^TESTS_OK' || { echo "!! TESTS_OK not printed (exit $CODE)"; exit 1; }
exit 0

#!/usr/bin/env bash
# Run the headless test scene and FAIL on any script error, not only on a failed check.
# A parse error in one class silently skips every check that used it, so the run is only
# green when the engine printed no error lines at all. (The pattern, and the reason for
# it, are from play/overtime-idle-godot/tests/run.sh.)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}
[ -x "$GODOT" ] || { echo "Godot 4.7 not found; set \$GODOT" >&2; exit 2; }
# regenerate the JS fixture if node is available, so the two sides cannot drift
if command -v node >/dev/null && [ -d ../fold/frontend ]; then
  node tests/conformance_gen.cjs || { echo "!! conformance_gen.cjs failed"; exit 2; }
fi
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
OUT=$(timeout 600 "$GODOT" --headless --path . res://tests/run_tests.tscn 2>&1)
CODE=$?
echo "$OUT" | grep -v '^\s*$'
ERRS=$(echo "$OUT" | grep -c -E 'SCRIPT ERROR|^ERROR:|USER ERROR' || true)
if [ "$ERRS" != "0" ]; then echo "!! $ERRS engine error line(s) — see above"; exit 2; fi
echo "$OUT" | grep -q '^TESTS_OK' || { echo "!! TESTS_OK not printed (exit $CODE)"; exit 1; }
exit 0

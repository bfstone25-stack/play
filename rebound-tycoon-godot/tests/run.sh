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

# Two things the conformance suite cannot see, because they are about the PACKAGE rather
# than the rules. Both have shipped broken here before.
#   parse.tscn  every script in scripts/ can actually be instantiated. A GDScript parse
#               error does not fail the export, does not raise a JS exception and is only
#               a browser console line, so an autoload can silently never exist.
#   cjk.tscn    the shipped font subset contains every character the copy uses. The web
#               export has no system font to fall back on, so a missing glyph is a tofu
#               box in zh/ja and nothing anywhere says so.
for SCENE in parse cjk; do
    OUT=$(timeout 300 "$GODOT" --headless --path . "res://tests/$SCENE.tscn" 2>&1) || {
        echo "$OUT" | tail -6; echo "!! tests/$SCENE.tscn failed"; exit 3; }
    echo "$OUT" | grep -E '^(ok|[0-9]+ )' | tail -2
done
exit 0

#!/usr/bin/env bash
# Prove the central claim of the gate: the uncensored plates are not in the free package.
#
# Not "censored in", not "hidden in" — not in. This exports the web build and greps the
# exported pack for every file under assets/plates_x/, and also exports the Linux (paid)
# build and greps it for the same names to prove the paid package really does carry them.
# A gate that can be beaten by unzipping the download is not a gate, and the only way to
# know which kind you shipped is to look inside the thing you actually shipped.
#
#   tools/pack_audit.sh /path/to/Godot_v4.7-stable_linux.x86_64
#
# Ported from the same check in play/overnight-clause.
set -euo pipefail

GODOT="${1:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
names=()
for f in assets/plates_x/*.png; do
    names+=("$(basename "$f" .png)")
done
echo "uncensored plates in this checkout: ${names[*]}"

echo
echo "== exporting the free web build =="
rm -rf build/web
mkdir -p build/web
"$GODOT" --headless --path "$ROOT" --export-release "Web" build/web/index.html >/dev/null 2>&1 || true
WEB_PCK="build/web/index.pck"
if [ ! -f "$WEB_PCK" ]; then
    echo "FAIL: no web pack was produced at $WEB_PCK"
    exit 1
fi
echo "   $(du -h "$WEB_PCK" | cut -f1)  $WEB_PCK"

# The pack stores resource paths as plain text, so grep is the whole audit. The strings
# output is dumped to a file first rather than piped: `strings | grep -q` under `set -o
# pipefail` fails the pipeline with SIGPIPE the moment grep finds a match and exits, which
# reads as "not found" and quietly inverts every check in this script. It did exactly that
# on the first run of this audit.
WEB_STRINGS="$(mktemp)"
PAID_STRINGS="$(mktemp)"
trap 'rm -f "$WEB_STRINGS" "$PAID_STRINGS"' EXIT
strings -a "$WEB_PCK" > "$WEB_STRINGS"

if grep -q "plates_x" "$WEB_STRINGS"; then
    echo "FAIL: the free web pack mentions plates_x:"
    grep "plates_x" "$WEB_STRINGS" | sed 's/^/     /'
    fail=1
else
    echo "   OK: no reference to assets/plates_x/ anywhere in the free web pack"
fi

# And every censored stand-in that exists must be present, or the free build shows
# nothing at all where it could have shown a silhouette.
#
# Derived from assets/plates/, not from assets/plates_x/: a slot whose uncensored art has
# not been rendered yet has no file in plates_x, so keying this off that directory quietly
# stopped checking exactly the stand-ins that are doing the most work. cg_ring is the live
# example — no uncensored plate, a real censored one, and it must ship.
locked=()
for f in assets/plates/*_locked.png; do
    [ -e "$f" ] || continue
    locked+=("$(basename "$f" .png)")
done
missing=0
for n in "${locked[@]}"; do
    if ! grep -q "$n" "$WEB_STRINGS"; then
        echo "FAIL: censored stand-in $n is missing from the free web pack"
        missing=1
    fi
done
[ "$missing" -eq 0 ] && echo "   OK: all ${#locked[@]} censored stand-ins are in the free web pack"
# The painted grounds are loaded by scripts/game.gd and were placed with no .import
# sidecar, which is the one way a file can be in the checkout and not in the export.
for n in bg_shop bg_market; do
    if grep -q "$n" "$WEB_STRINGS"; then
        echo "   OK: $n is in the free web pack"
    else
        echo "FAIL: $n is loaded by game.gd but did not make it into the pack"
        fail=1
    fi
done
fail=$((fail + missing))

echo
echo "== exporting the paid Linux build =="
rm -rf build/linux
mkdir -p build/linux
"$GODOT" --headless --path "$ROOT" --export-release "Linux" build/linux/midnight-pawn-collateral.x86_64 >/dev/null 2>&1 || true
PAID_PCK="build/linux/midnight-pawn-collateral.pck"
if [ ! -f "$PAID_PCK" ]; then
    echo "FAIL: no paid pack was produced at $PAID_PCK"
    exit 1
fi
echo "   $(du -h "$PAID_PCK" | cut -f1)  $PAID_PCK"
strings -a "$PAID_PCK" > "$PAID_STRINGS"
for n in "${names[@]}"; do
    if grep -q "plates_x/${n}" "$PAID_STRINGS"; then
        echo "   OK: $n is in the paid pack"
    else
        echo "FAIL: $n is missing from the PAID pack — the people who paid get silhouettes"
        fail=1
    fi
done

echo
if [ "$fail" -eq 0 ]; then
    echo "PACK_AUDIT_OK  free=$(du -h "$WEB_PCK" | cut -f1) paid=$(du -h "$PAID_PCK" | cut -f1)"
    exit 0
fi
echo "PACK_AUDIT_FAILED"
exit 1

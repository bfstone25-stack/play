#!/usr/bin/env bash
# Every headless check: rules unit tests, the data cross-reference, hour one x10 balance+pacing,
# the whole night on the three ending paths (solvent / factor / collateral) with the flags each
# must set, and the reckless player that must lose.
#   tools/verify_all.sh            # data check tolerates missing art
#   STRICT=1 tools/verify_all.sh   # the DLsite build: every room, figure and CG must be real
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
rc=0
"$G" --headless --path ../night-rpg-core -s tests/rules_test.gd 2>&1 | grep -E "^ok|^FAIL|rules:" || rc=1
python3 tools/check_data.py ${STRICT:+--strict} || rc=1
run() { "$G" --headless --path . res://tests/sim.tscn -- "$@" 2>&1 | grep -E "^h[1-5]|^ok |^FAIL|stuck|SCRIPT ERROR"; }
out=$(run --nights=h1 --runs=10 --min=18 --max=50); echo "$out"; echo "$out" | grep -q "^FAIL" && rc=1
ALL=h1,h2,h3,h4,h5
# the normal player: reads the finial and the veil, declines Ivo, prices fair, refuses Calder -> solvent
out=$(run --nights=$ALL --runs=1 --min=0 --max=999 --expect=ending_solvent,read_finial,read_veil,refused_ring,second_ivo,heart_seen,calder_done)
echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
# sells the newest reading to Calder -> factor
out=$(run --nights=$ALL --runs=1 --min=0 --max=999 --prefer="h4_sell_" --expect=ending_factor,sold)
echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
# reads all three (looks at the ring though Ivo asked) -> collateral, and the gated readings
out=$(run --nights=$ALL --runs=1 --min=0 --max=999 --prefer="h2_take|price_finial_high|price_veil_high|h3_take|h1_read" --expect=ending_collateral,read_ring,read_finial,read_veil)
echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
# the counter must matter: the same normal player who never uses it (sends every walk-in away,
# sells and buys nothing) ends the night short of the estate and in Collateral, with a till
# at least 100 lower than the player who works the counter
runt() { "$G" --headless --path . res://tests/sim.tscn -- "$@" 2>&1 | grep -E "^h5: till" | sed 's/.*till \([0-9]*\).*/\1/'; }
busy=$(runt --nights=$ALL --runs=1 --min=0 --max=999)
lazy=$(runt --nights=$ALL --runs=1 --min=0 --max=999 --counter=ignore)
out=$(run --nights=$ALL --runs=1 --min=0 --max=999 --counter=ignore --expect=ending_collateral)
echo "$out" | grep -E "FAIL|ending"; echo "counter used: till $busy at dawn; counter ignored: till $lazy"
echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
[ -n "$busy" ] && [ -n "$lazy" ] && [ $((busy - lazy)) -ge 100 ] || { echo "!! ignoring the counter is not measurably worse"; rc=1; }
out=$(run --nights=h1 --runs=2 --policy=reckless --min=0 --max=999); echo "$out"
echo "$out" | grep -qE "^FAIL h1 (winnable|finished)" || { echo "!! the reckless player did not lose: the balance check cannot fail"; rc=1; }
echo "verify_all rc=$rc"; exit $rc

#!/usr/bin/env bash
# Every headless check: core rules tests, the data cross-reference, night one x5 balance+pacing,
# the whole campaign for three office players (each in its own user:// so saves never cross):
#   smart   builds the board, recruits with the surplus  -> must pay every night, no loss,
#           and end in Full occupancy
#   random  places the same pieces at random              -> must earn far less (board matters)
#   ignore  never opens the office                       -> must pay no rent, take reloads, and
#           end in Holding on (the management loop matters)
# and the reckless player (security first) who must lose.
#   tools/verify_all.sh            # data check tolerates missing art
#   STRICT=1 tools/verify_all.sh   # the DLsite build: every room, figure and CG must be real
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
rc=0
"$G" --headless --path ../night-rpg-core -s tests/rules_test.gd 2>&1 | grep -E "^ok|^FAIL|rules:" || rc=1
python3 tools/check_data.py ${STRICT:+--strict} || rc=1
mkdir -p shots
run() { XDG_DATA_HOME=$PWD/shots/xdg_$1 "$G" --headless --path . res://tests/sim.tscn -- "${@:2}" 2>&1 | grep -E "^n[1-5]|^ok |^FAIL|stuck|SCRIPT ERROR"; }
out=$(run n1 --nights=n1 --runs=5 --min=15 --max=45); echo "$out"; echo "$out" | grep -qE "^FAIL|SCRIPT ERROR" && rc=1
for o in smart random ignore; do
  exp=""; [ $o = smart ] && exp="--expect=ending_full,n5_paid,seen_mara_a,seen_priya_a"; [ $o = ignore ] && exp="--expect=ending_hold"
  ( run $o --nights=n5 --runs=1 --min=0 --max=999 --office=$o $exp > shots/sim_$o.txt ) &
done
wait
for o in smart random ignore; do echo "== office=$o"; cut -c1-260 shots/sim_$o.txt; done
grep -qE "SCRIPT ERROR|stuck" shots/sim_*.txt && { echo "!! script error or stuck"; rc=1; }
paid() { grep -E "^n[1-5]: till" shots/sim_$1.txt | grep -c "paid true"; }
loss() { grep -E "^n[1-5]: till" shots/sim_$1.txt | sed 's/.*losses \([0-9]*\).*/\1/' | paste -sd+ | bc; }
earn() { grep -E "^n[1-5]: till" shots/sim_$1.txt | sed 's/.*shift \([0-9]*\),.*/\1/' | paste -sd+ | bc; }
echo "paid nights: smart $(paid smart)/5, random $(paid random)/5, ignore $(paid ignore)/5; reloads: smart $(loss smart), random $(loss random), ignore $(loss ignore); shift income: smart $(earn smart), random $(earn random)"
[ "$(paid smart)" -eq 5 ] && [ "$(loss smart)" -eq 0 ] || { echo "!! the normal player hit a wall"; rc=1; }
grep -qE "^FAIL" shots/sim_smart.txt && { echo "!! the normal player failed a check"; rc=1; }
grep -q "^ok   flag ending_hold" shots/sim_ignore.txt || { echo "!! the player who ignores the office did not end in Holding on"; rc=1; }
[ "$(paid ignore)" -eq 0 ] && [ "$(loss ignore)" -ge 2 ] || { echo "!! ignoring the office is not measurably worse"; rc=1; }
[ "$(earn smart)" -ge $(( 2 * $(earn random) )) ] || { echo "!! a random board earns within half of a built one: the board does not matter"; rc=1; }
out=$(run reckless --nights=n1 --runs=2 --policy=reckless --min=0 --max=999); echo "$out"
echo "$out" | grep -qE "^FAIL n1 (winnable|finished)" || { echo "!! the reckless player did not lose: the balance check cannot fail"; rc=1; }
echo "verify_all rc=$rc"; exit $rc

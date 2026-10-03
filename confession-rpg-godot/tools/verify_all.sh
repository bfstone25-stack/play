#!/usr/bin/env bash
# Every headless check: rules unit tests, the data cross-reference, Case 1 balance+pacing,
# the whole game (three cases + epilogue) with every clean ending, every route and the three
# epilogue scenes reached, and the reckless player that must lose.
#   tools/verify_all.sh            # data check tolerates placeholder art
#   STRICT=1 tools/verify_all.sh   # the DLsite build: every plate, sprite and CG must be real
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
rc=0
"$G" --headless --path ../night-rpg-core -s tests/rules_test.gd 2>&1 | grep -E "^ok|^FAIL|rules:" || rc=1
python3 tools/check_data.py ${STRICT:+--strict} || rc=1
run() { "$G" --headless --path . res://tests/sim.tscn -- "$@" 2>&1 | grep -E "^night|^epilogue|^ok |^FAIL|stuck|SCRIPT ERROR"; }
out=$(run --nights=night1 --runs=10 --min=35 --max=75); echo "$out"; echo "$out" | grep -q "^FAIL" && rc=1
out=$(run --nights=night1,night2,night3,epilogue --runs=1 --min=0 --max=999 \
  --expect=c1_clean,c2_clean,c3_clean,route_c1_nikolai,route_c1_adaeze,route_c1_vee,route_c2_nikolai,route_c2_adaeze,route_c2_vee,route_c3_nikolai,route_c3_adaeze,route_c3_vee,ep_nikolai,ep_adaeze,ep_vee)
echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
out=$(run --nights=night1 --runs=2 --policy=reckless --min=0 --max=999); echo "$out"
echo "$out" | grep -qE "^FAIL night1 (winnable|finished)" || { echo "!! the reckless player did not lose: the balance check cannot fail"; rc=1; }
echo "verify_all rc=$rc"; exit $rc

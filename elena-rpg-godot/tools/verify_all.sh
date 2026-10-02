#!/usr/bin/env bash
# Every headless check: rules unit tests, the data cross-reference, Night 1 balance+pacing,
# all five nights on each of the three route/ending paths, and the reckless player that must lose.
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
rc=0
"$G" --headless --path ../night-rpg-core -s tests/rules_test.gd 2>&1 | grep -E "^ok|^FAIL|rules:" || rc=1
python3 tools/check_data.py || rc=1
run() { "$G" --headless --path . res://tests/sim.tscn -- "$@" 2>&1 | grep -E "^night|^ok |^FAIL|stuck|SCRIPT ERROR"; }
out=$(run --nights=night1 --runs=10); echo "$out"; echo "$out" | grep -q "^FAIL" && rc=1
for spec in 'hand over hers|Every name goes back:route_pact,ending_rewrite' 'Take the ledger out|Guardian:route_control,ending_expose' 'Go home, Elena|Walk past them:route_walk,ending_abscond'; do
  out=$(run --nights=night1,night2,night3,night4,night5 --runs=1 "--prefer=${spec%%:*}" "--expect=${spec##*:}" --min=0 --max=999)
  echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
done
out=$(run --nights=night1 --runs=2 --policy=reckless); echo "$out"
echo "$out" | grep -q "^FAIL night1 winnable" || { echo "!! the reckless player did not lose: the balance check cannot fail"; rc=1; }
echo "verify_all rc=$rc"; exit $rc

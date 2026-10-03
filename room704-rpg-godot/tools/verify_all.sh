#!/usr/bin/env bash
# Every headless check: rules unit tests, the data cross-reference, Shift 1 balance+pacing,
# all shifts on each of the three route/ending paths, and the reckless player that must lose.
set -uo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
rc=0
"$G" --headless --path ../night-rpg-core -s tests/rules_test.gd 2>&1 | grep -E "^ok|^FAIL|rules:" || rc=1
python3 tools/check_data.py || rc=1
run() { "$G" --headless --path . res://tests/sim.tscn -- "$@" 2>&1 | grep -E "^shift|^epilogue|^ok |^FAIL|stuck|SCRIPT ERROR"; }
out=$(run --nights=shift1 --runs=10 --min=25); echo "$out"; echo "$out" | grep -q "^FAIL" && rc=1
# cover + ask why + stay awake -> together; cash + stonewall + get some sleep -> train; book + sold + no -> alone
for spec in 'Ask her why|checked in|Sit next to her|Stay awake with me:route_cover,scene_yes,ending_together' \
            'Take the cash|discuss guests|Take the chair|Say no:route_stonewall,scene_no,ending_train' \
            'Do it properly|Slide the register|Watch the car|Close the curtain:route_sold,scene_no,ending_alone'; do
  out=$(run --nights=shift1,shift2,shift3,epilogue --runs=1 "--prefer=${spec%%:*}" "--expect=${spec##*:}" --min=0 --max=999)
  echo "$out"; echo "$out" | grep -qE "^FAIL|stuck|SCRIPT ERROR" && rc=1
done
out=$(run --nights=shift1 --runs=2 --policy=reckless); echo "$out"
echo "$out" | grep -qE "^FAIL shift1 (winnable|finished)" || { echo "!! the reckless player did not lose: the balance check cannot fail"; rc=1; }
echo "verify_all rc=$rc"; exit $rc

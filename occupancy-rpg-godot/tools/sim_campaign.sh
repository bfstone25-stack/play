#!/usr/bin/env bash
# One campaign per office policy in parallel; per-night report lines into shots/sim_<policy>.txt
cd "$(dirname "$0")/.."
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
mkdir -p shots
for o in ${@:-smart ignore random}; do
  ( XDG_DATA_HOME=$PWD/shots/xdg_$o timeout 1200 "$G" --headless --path . res://tests/sim.tscn -- --nights=n5 --runs=1 --min=0 --max=999 --office=$o 2>&1 | grep -E "^n[1-5]: till|SCRIPT ERROR|^ok|^FAIL" > shots/sim_$o.txt ) &
done
wait
for o in ${@:-smart ignore random}; do echo "== $o"; cat shots/sim_$o.txt; done

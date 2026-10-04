#!/usr/bin/env bash
# Screenshot run on the GPU box (bfs@100.121.195.19) under Xvfb with Vulkan forced.
# Fails if the render device is not the RTX 3060 (Xvfb silently falls back to CPU otherwise;
# memory: xvfb-godot-renders-on-cpu) or if the expected shots are missing.
#   tools/remote_shots.sh [scene=res://tests/shots.tscn] [outdir=shots/latest] [extra args...]
set -euo pipefail
cd "$(dirname "$0")/.."
HOST="${REMOTE_HOST:-bfs@100.121.195.19}"
SCENE="${1:-res://tests/shots.tscn}"; OUT="${2:-shots/latest}"; shift 2 || true
GODOT_LOCAL="$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64"
R=rpgtest_occ
ssh -o ConnectTimeout=10 -o BatchMode=yes "$HOST" "mkdir -p ~/$R/bin ~/$R/game"
ssh "$HOST" "test -x ~/$R/bin/godot" || rsync -a "$GODOT_LOCAL" "$HOST:$R/bin/godot"
rsync -aL --delete --exclude .godot --exclude shots --exclude build ./ "$HOST:$R/game/"
ssh "$HOST" "cd ~/$R/game && rm -rf shots_out && mkdir shots_out && \
  timeout 200 ~/$R/bin/godot --headless --path . --import >/dev/null 2>&1; \
  timeout 1600 xvfb-run -a -s '-screen 0 1280x720x24' ~/$R/bin/godot --rendering-driver vulkan --path . $SCENE -- --out=\$PWD/shots_out $* > shots_out/log.txt 2>&1; echo rc=\$?" 
mkdir -p "$OUT"
rsync -a "$HOST:$R/game/shots_out/" "$OUT/"
grep -E "RENDER DEVICE|SHOTS|SCRIPT ERROR|ERROR|^ok |^FAIL|ui_smoke:" "$OUT/log.txt" | head -40
grep -q "RENDER DEVICE: .*3060" "$OUT/log.txt" || { echo "!! not rendered on the RTX 3060"; exit 3; }
n=$(ls "$OUT"/*.png 2>/dev/null | wc -l || true); echo "$n shots in $OUT"
[ "$n" -ge "${MIN_SHOTS:-8}" ] || { echo "!! too few shots"; exit 4; }

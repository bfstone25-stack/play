#!/usr/bin/env bash
# Boot an exported zip the way a buyer would: copy the -pc zip to the GPU box, unzip it, run
# the Linux binary under Xvfb on the RTX 3060 and grab the screen after it has drawn (scrot).
#   tools/zip_boot.sh build/dist/occupancy-rpg-trial-v1.0.0-pc.zip shots/exported/trial_zip_boot.png
set -euo pipefail
cd "$(dirname "$0")/.."
ZIP="$1"; OUT="${2:-shots/exported/$(basename "$ZIP" .zip)_boot.png}"
HOST="${REMOTE_HOST:-bfs@100.121.195.19}"
R=rpgtest_occ/zipboot
name=$(basename "$ZIP" .zip)
ssh -o BatchMode=yes "$HOST" "rm -rf ~/$R && mkdir -p ~/$R"
rsync -a "$ZIP" "$HOST:$R/"
ssh "$HOST" "cd ~/$R && unzip -q $name.zip && cd $name && chmod +x *.x86_64 && \
  xvfb-run -a -s '-screen 0 1280x720x24' bash -c './Occupancy.x86_64 --rendering-driver vulkan > boot.log 2>&1 & pid=\$!; sleep 14; scrot ../boot.png; kill \$pid; wait \$pid 2>/dev/null || true'; \
  grep -iE 'RENDER|SCRIPT ERROR|ERROR' $name/boot.log | head -5; echo booted"
mkdir -p "$(dirname "$OUT")"
rsync -a "$HOST:$R/boot.png" "$OUT"
python3 - "$OUT" <<'EOF'
import sys; from PIL import Image, ImageStat
im = Image.open(sys.argv[1]).convert("RGB"); m = ImageStat.Stat(im).mean
print(sys.argv[1], im.size, "mean rgb %.0f %.0f %.0f" % tuple(m))
assert sum(m) > 15, "black frame: the game did not draw"
EOF

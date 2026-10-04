#!/usr/bin/env bash
# Package on the GPU box (pop-os is Blaze's office machine: no exports there). Syncs the
# project (symlinked core resolved), runs tools/package.sh remotely with the box's Godot and
# export templates, copies build/dist back.  tools/remote_package.sh [version=1.0.0]
set -euo pipefail
cd "$(dirname "$0")/.."
V="${1:-1.0.0}"
HOST="${REMOTE_HOST:-bfs@100.121.195.19}"
R=rpgtest_occ
ssh "$HOST" "mkdir -p ~/$R/bin ~/$R/game ~/.local/share/godot/export_templates ~/Products/ops"
ssh "$HOST" "test -x ~/$R/bin/godot" || rsync -a "$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64" "$HOST:$R/bin/godot"
ssh "$HOST" "test -d ~/.local/share/godot/export_templates/4.7.stable" || rsync -a "$HOME/.local/share/godot/export_templates/4.7.stable" "$HOST:.local/share/godot/export_templates/"
rsync -a ../../ops/godot_parse_all.gd "$HOST:Products/ops/"
rsync -aL --delete --exclude .godot --exclude shots --exclude build ./ "$HOST:$R/game/"
# package.sh reads ../../ops/godot_parse_all.gd relative to the game; give it that layout
ssh "$HOST" "mkdir -p ~/$R/x/y && rm -rf ~/$R/x/y/game && ln -sfn ~/$R/game ~/$R/x/y/game && mkdir -p ~/$R/ops && cp ~/Products/ops/godot_parse_all.gd ~/$R/ops/ && cd ~/$R/game && \
  sed -i 's#python3 tools/import_art.py >/dev/null#true#; s#cp ../../ops/godot_parse_all.gd#cp ~/$R/ops/godot_parse_all.gd#' tools/package.sh && \
  GODOT=~/$R/bin/godot nice -n 5 bash tools/package.sh $V" 2>&1 | tail -8
mkdir -p build/dist
rsync -a "$HOST:$R/game/build/dist/" build/dist/
cat build/dist/SHA256SUMS.txt

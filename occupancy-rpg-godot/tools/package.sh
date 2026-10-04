#!/usr/bin/env bash
# Build the OCCUPANCY RPG for DLsite: Windows + Linux (one -pc.zip, like the VN's) and macOS
# (-mac.zip), full and trial, into build/dist/. No dist.txt. Refuses to package on a script
# error (boot + parse every script), a failed export or a missing binary.
#   tools/package.sh [version=1.0.0]
set -euo pipefail
cd "$(dirname "$0")/.."
V="${1:-1.0.0}"
G="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
python3 tools/import_art.py >/dev/null
"$G" --headless --path . --import >/dev/null 2>&1 || true
boot=$(timeout 120 "$G" --headless --path . --quit-after 200 2>&1 || true)
if printf '%s' "$boot" | grep -qiE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"; then
  printf '%s\n' "$boot" | grep -iE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load" >&2; echo "!! script error: not packaging" >&2; exit 1; fi
cp ../../ops/godot_parse_all.gd .parse_all.gd
po=$(timeout 300 "$G" --headless --path . -s res://.parse_all.gd 2>&1 || true); rm -f .parse_all.gd .parse_all.gd.uid
printf '%s' "$po" | grep -q "PARSE_ALL .* bad=0" || { printf '%s\n' "$po" | grep -E "PARSE_|ERROR" | head >&2; echo "!! parse_all failed" >&2; exit 1; }
rm -rf build && mkdir -p build/dist
for t in "" "-trial"; do
  for p in Windows Linux macOS; do
    mkdir -p "build/$(echo $p | tr A-Z a-z | sed 's/windows/win/;s/macos/mac/')$t"
    "$G" --headless --path . --export-release "$p$t" >"build/export_$p$t.log" 2>&1 || { tail -20 "build/export_$p$t.log"; echo "!! export $p$t failed"; exit 1; }
  done
  test -s "build/win$t/Occupancy.pck" && test -s "build/win$t/Occupancy.exe" && test -s "build/linux$t/Occupancy.x86_64" && test -s "build/mac$t/Occupancy.zip" \
    || { echo "!! missing export output for '$t'"; exit 1; }
  name="occupancy-rpg${t}-v$V"
  rm -rf "build/stage" && mkdir -p "build/stage/$name-pc"
  # one shared .pck next to both launchers (same basename), like the VN's single archive
  cmp -s "build/win$t/Occupancy.pck" "build/linux$t/Occupancy.pck" || echo "note: win/linux pck differ in bytes; shipping the Windows one"
  cp "build/win$t/Occupancy.exe" "build/win$t/Occupancy.pck" "build/linux$t/Occupancy.x86_64" "build/stage/$name-pc/"
  chmod +x "build/stage/$name-pc/Occupancy.x86_64"
  (cd build/stage && zip -qr "../dist/$name-pc.zip" "$name-pc")
  mkdir -p "build/stage/$name-mac" && (cd "build/stage/$name-mac" && unzip -q "../../mac$t/Occupancy.zip")
  (cd build/stage && zip -qry "../dist/$name-mac.zip" "$name-mac")
done
rm -rf build/stage
ls -la build/dist; (cd build/dist && sha256sum *.zip > SHA256SUMS.txt && cat SHA256SUMS.txt)

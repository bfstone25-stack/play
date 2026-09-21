#!/usr/bin/env bash
# Build both tracks: sync the rendered plates in (they live under ops/, not in the project),
# then the shared exporter — Gate autoload, Web/Linux/Windows exports, gate.js + telemetry
# stamp, and ops/board_inject.py so board.js ships and the page loads it.
#   ./build.sh [price]      -> ../../build/godot/ghost-channel/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
python3 "$HERE/tools/sync_art.py"

# Boot the project headless and fail the build on a script error. 2026-09-21: a GDScript
# PARSE error in play_screen.gd took main.gd down with it (main.gd depends on it), the
# scene's root script never loaded, the title screen still drew because its own script is
# fine -- and every button on it did nothing, for ever. Nothing in the loop caught it: the
# conformance tests do not load main.gd, the export succeeds, the page reports no errors,
# and the only trace is a line in the browser console. This costs four seconds and is the
# check that would have caught it. Worth promoting into ops/godot_build.sh for all 26.
GODOT="${GODOT:-$HOME/bin/godot/Godot_v4.7-stable_linux.x86_64}"
if [ -x "$GODOT" ]; then
  boot=$("$GODOT" --headless --path "$HERE" --quit-after 120 2>&1 || true)
  if printf '%s' "$boot" | grep -qiE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"; then
    echo "== ghost-channel: headless boot reported a script error; not building" >&2
    printf '%s\n' "$boot" | grep -iE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|at: " >&2
    exit 1
  fi
  echo "== ghost-channel: headless boot clean"
fi
exec "$HERE/../../ops/godot_build.sh" "$HERE" ghost-channel "${1:-\$2.99}"

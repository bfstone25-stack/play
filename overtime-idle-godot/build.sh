#!/usr/bin/env bash
# Build both tracks: sync the parent's art in (nothing committed), then the shared
# exporter — Gate autoload, Web/Linux/Windows exports, gate.js + telemetry stamp, and
# ops/board_inject.py so board.js ships and the page loads it.
#   ./build.sh [price]      -> ../../build/godot/overtime-idle/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
python3 "$HERE/tools/sync_art.py"
exec "$HERE/../../ops/godot_build.sh" "$HERE" overtime-idle "${1:-\$4.99}"

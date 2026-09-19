#!/usr/bin/env bash
# Build both tracks: sync the rendered plates in (they live under ops/, not in the project),
# then the shared exporter — Gate autoload, Web/Linux/Windows exports, gate.js + telemetry
# stamp, and ops/board_inject.py so board.js ships and the page loads it.
#   ./build.sh [price]      -> ../../build/godot/ghost-channel/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
python3 "$HERE/tools/sync_art.py"
exec "$HERE/../../ops/godot_build.sh" "$HERE" ghost-channel "${1:-\$2.99}"

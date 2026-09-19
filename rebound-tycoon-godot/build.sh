#!/usr/bin/env bash
# Build both tracks through the shared exporter — Gate autoload, Web/Linux/Windows
# exports, gate.js + the telemetry stamp, and ops/board_inject.py so board.js ships and
# the page loads it.
#   ./build.sh [price]      -> ../../build/godot/rebound-tycoon/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
exec "$HERE/../../ops/godot_build.sh" "$HERE" rebound-tycoon "${1:-\$2.99}"

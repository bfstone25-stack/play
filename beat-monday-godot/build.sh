#!/usr/bin/env bash
# The shared exporter — Gate autoload, Web/Linux/Windows exports, gate.js + telemetry
# stamp, board.js injection.   ./build.sh [price]  -> ../../build/godot/beat-monday/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
exec "$HERE/../../ops/godot_build.sh" "$HERE" beat-monday "${1:-\$1.99}"

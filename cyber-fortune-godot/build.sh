#!/usr/bin/env bash
# Rebuild the pools and the CJK subset, then the shared exporter — Gate autoload, Web /
# Linux / Windows exports, gate.js + telemetry stamp, board.js injected.
#   ./build.sh [price]      -> ../../build/godot/cyber-fortune/{web,linux,windows}
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
python3 "$HERE/tools/build_pool.py"
exec "$HERE/../../ops/godot_build.sh" "$HERE" cyber-fortune "${1:-\$2.99}"

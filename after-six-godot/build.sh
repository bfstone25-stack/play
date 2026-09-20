#!/usr/bin/env bash
# After Six is an adult title: two web tracks (itch, ads on *.flat404.workers.dev), the
# 18+ Adsterra unit on the ads track only, downloads with no third-party call. Not the
# mainstream exporter.   ./build.sh [price] -> ../../build/godot/after-six/{web,linux,windows}
#                                              ../../build/godot-ads/after-six/
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
exec "$HERE/../../ops/aftersix_build.sh" "$HERE" "${1:-\$3.99}"

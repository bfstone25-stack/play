#!/usr/bin/env bash
# SILVERTONGUE: AFTER HOURS — cards. Backend + static frontend on one port, no model.
#   ./run.sh              -> http://127.0.0.1:8929/
#   PORT=9000 ./run.sh
set -euo pipefail
cd "$(dirname "$0")"
PY="${PY:-$HOME/miniconda3/envs/hsm_lcr/bin/python}"
[ -x "$PY" ] || PY=python3
exec "$PY" -m uvicorn backend.app:app --host 127.0.0.1 --port "${PORT:-8929}"

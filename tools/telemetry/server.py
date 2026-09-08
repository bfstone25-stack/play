#!/usr/bin/env python3
"""Standalone telemetry ingest for Elena / other Ren'Py or HTML5 games.

  python3 tools/telemetry/server.py
  # -> http://127.0.0.1:27100/tel_batch
  # -> http://127.0.0.1:27100/telemetry/dashboard?app=elena
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import uvicorn

if __name__ == "__main__":
    host = os.environ.get("TELEMETRY_HOST", "127.0.0.1")
    port = int(os.environ.get("TELEMETRY_PORT", "27100"))
    uvicorn.run("shared.telemetry:app", host=host, port=port, reload=False)

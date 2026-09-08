#!/usr/bin/env python3
"""Smoke-test shared telemetry ingest + Elena funnel."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

BASE = os.environ.get("TELEMETRY_SMOKE_URL", "http://127.0.0.1:27100")


def _get(path: str):
    with urllib.request.urlopen(BASE + path, timeout=5) as r:
        return json.loads(r.read().decode())


def _post(path: str, payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(
        BASE + path,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.loads(r.read().decode())


def main() -> int:
    health = _get("/health")
    assert health.get("ok"), health
    assert "elena" in health.get("funnels", []), health

    sid = f"smoke-{int(time.time())}"
    pid = "smoke-player"
    steps = [
        "session_start",
        "game_start",
        "vault_enter",
        "choice_1",
        "confrontation",
        "branch_choice",
        "climax_cg",
        "dawn_resolution",
        "end_cta",
    ]
    batch = [
        {
            "pid": pid,
            "sid": sid,
            "etype": "custom",
            "name": name,
            "value": json.dumps({"smoke": True, "step": i}),
        }
        for i, name in enumerate(steps)
    ]
    # Also mimic tell HTML SDK: bare list, etype pageview/click, string value
    batch.append(
        {
            "pid": pid,
            "sid": sid,
            "etype": "click",
            "name": "cta_click",
            "value": json.dumps({"dest": "itch"}),
        }
    )

    res = _post("/tel_batch?app=elena", batch)
    assert res.get("ok") and res.get("inserted") == len(batch), res

    # Alias route + wrapped body
    res2 = _post(
        "/telemetry/batch",
        {
            "app": "elena",
            "events": [
                {
                    "pid": "drop-player",
                    "sid": "drop-sid",
                    "name": "session_start",
                },
                {
                    "pid": "drop-player",
                    "sid": "drop-sid",
                    "name": "game_start",
                },
            ],
        },
    )
    assert res2.get("ok"), res2

    funnel = _get("/telemetry/funnel?app=elena&hours=1")
    assert funnel.get("app") == "elena", funnel
    by_step = {s["step"]: s["sessions"] for s in funnel.get("steps", [])}
    for name in steps:
        assert by_step.get(name, 0) >= 1, (name, funnel)

    # Drop-off session should appear at early steps only
    assert by_step["session_start"] >= by_step["end_cta"]

    summary = _get("/tel_summary?app=elena&hours=1")
    assert summary.get("events", 0) >= len(batch), summary

    print(json.dumps({"ok": True, "health": health, "funnel": funnel, "summary": summary}, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.URLError as e:
        print("Server not reachable at", BASE, "— start tools/telemetry/server.py first.", file=sys.stderr)
        print(e, file=sys.stderr)
        raise SystemExit(2)

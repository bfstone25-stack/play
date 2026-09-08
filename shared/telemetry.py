"""
Shared telemetry API — FastAPI endpoints for anonymous player funnel events.

Mount into an existing app (matches tell / silvertongue / flutter callers):
    from shared.telemetry import mount_telemetry
    mount_telemetry(app, "tell")

Or run standalone:
    python3 tools/telemetry/server.py
    # -> http://127.0.0.1:27100/tel_batch
    # -> http://127.0.0.1:27100/telemetry/dashboard?app=elena
"""

from __future__ import annotations

import json
import os
import sqlite3
import time
from pathlib import Path
from typing import Any, Optional

from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from pydantic import BaseModel, Field

DEFAULT_DB = Path(os.path.expanduser("~/Products/data/telemetry.db"))

# Funnel step order used by /tel_funnel, /telemetry/funnel, and the dashboard.
FUNNELS: dict[str, list[str]] = {
    "elena": [
        "session_start",
        "game_start",
        "vault_enter",
        "choice_1",
        "confrontation",
        "branch_choice",
        "climax_cg",
        "dawn_resolution",
        "end_cta",
    ],
}


def _db_path() -> Path:
    return Path(os.environ.get("TELEMETRY_DB", str(DEFAULT_DB)))


def _conn() -> sqlite3.Connection:
    path = _db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(str(path), timeout=30)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA journal_mode=WAL")
    c.execute(
        """
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts REAL NOT NULL,
            app TEXT NOT NULL,
            pid TEXT,
            sid TEXT,
            etype TEXT,
            name TEXT,
            value REAL,
            dur REAL,
            meta TEXT
        )
        """
    )
    c.execute(
        "CREATE INDEX IF NOT EXISTS idx_events_app_ts ON events(app, ts)"
    )
    c.execute(
        "CREATE INDEX IF NOT EXISTS idx_events_app_name ON events(app, name)"
    )
    c.execute(
        "CREATE INDEX IF NOT EXISTS idx_events_app_etype ON events(app, etype)"
    )
    c.execute(
        "CREATE INDEX IF NOT EXISTS idx_events_sid ON events(sid)"
    )
    return c


class TelemetryEvent(BaseModel):
    """One client event. HTML SDKs send etype+name; Ren'Py often sends name only."""

    pid: Optional[str] = None
    sid: Optional[str] = None
    etype: Optional[str] = None
    name: Optional[str] = None
    # JS SDKs stringify objects into `value`; Ren'Py may send dict/number/string.
    value: Optional[Any] = None
    dur: Optional[float] = None
    meta: Optional[Any] = None
    ts: Optional[float] = None


class TelemetryBatch(BaseModel):
    events: list[TelemetryEvent] = Field(default_factory=list)
    app: Optional[str] = None


def _normalize_value_meta(ev: TelemetryEvent) -> tuple[Optional[float], Optional[str]]:
    """Map flexible client `value`/`meta` into (numeric value, meta JSON string)."""
    meta_obj: Any = ev.meta
    num: Optional[float] = None
    raw = ev.value

    if isinstance(raw, bool):
        # bool is int subclass; keep as meta flag instead of 0/1 noise
        if meta_obj is None:
            meta_obj = {"value": raw}
        elif isinstance(meta_obj, dict):
            meta_obj = {**meta_obj, "value": raw}
        else:
            meta_obj = {"meta": meta_obj, "value": raw}
    elif isinstance(raw, (int, float)):
        num = float(raw)
    elif isinstance(raw, str):
        # Prefer parsing numeric strings; otherwise stash under meta.value
        try:
            num = float(raw)
        except ValueError:
            if meta_obj is None:
                # Common JS pattern: value is already JSON text
                try:
                    parsed = json.loads(raw)
                    meta_obj = parsed if isinstance(parsed, dict) else {"value": parsed}
                except Exception:
                    meta_obj = {"value": raw}
            elif isinstance(meta_obj, dict):
                meta_obj = {**meta_obj, "client_value": raw}
            else:
                meta_obj = {"meta": meta_obj, "client_value": raw}
    elif raw is not None:
        if meta_obj is None:
            meta_obj = raw if isinstance(raw, dict) else {"value": raw}
        elif isinstance(meta_obj, dict) and isinstance(raw, dict):
            meta_obj = {**meta_obj, **raw}
        else:
            meta_obj = {"meta": meta_obj, "value": raw}

    meta_s: Optional[str] = None
    if meta_obj is not None:
        if isinstance(meta_obj, str):
            meta_s = meta_obj
        else:
            try:
                meta_s = json.dumps(meta_obj, ensure_ascii=False)
            except Exception:
                meta_s = str(meta_obj)
    return num, meta_s


def _parse_batch(payload: Any) -> TelemetryBatch:
    if isinstance(payload, list):
        return TelemetryBatch(events=[TelemetryEvent(**e) for e in payload])
    if isinstance(payload, dict):
        if "events" in payload:
            return TelemetryBatch(**payload)
        return TelemetryBatch(events=[TelemetryEvent(**payload)])
    raise ValueError("payload must be object or list")


def _insert_batch(app_name: str, batch: TelemetryBatch) -> int:
    now = time.time()
    rows = []
    for ev in batch.events:
        etype = (ev.etype or "custom").strip() or "custom"
        name = (ev.name or etype or "unknown").strip() or "unknown"
        num, meta_s = _normalize_value_meta(ev)
        rows.append(
            (
                float(ev.ts) if ev.ts is not None else now,
                app_name,
                ev.pid,
                ev.sid,
                etype,
                name,
                num,
                float(ev.dur) if ev.dur is not None else None,
                meta_s,
            )
        )
    if not rows:
        return 0
    with _conn() as c:
        c.executemany(
            """
            INSERT INTO events (ts, app, pid, sid, etype, name, value, dur, meta)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            rows,
        )
        c.commit()
    return len(rows)


def _hours_from_days(days: Optional[float], hours: Optional[float]) -> float:
    if hours is not None:
        return float(hours)
    if days is not None:
        return float(days) * 24.0
    return 168.0  # 7d


def _summary(app_name: str, since_hours: float = 168.0) -> dict[str, Any]:
    since = time.time() - since_hours * 3600
    with _conn() as c:
        total = c.execute(
            "SELECT COUNT(*) FROM events WHERE app=? AND ts>=?",
            (app_name, since),
        ).fetchone()[0]
        players = c.execute(
            "SELECT COUNT(DISTINCT pid) FROM events WHERE app=? AND ts>=? AND pid IS NOT NULL AND pid!=''",
            (app_name, since),
        ).fetchone()[0]
        sessions = c.execute(
            "SELECT COUNT(DISTINCT sid) FROM events WHERE app=? AND ts>=? AND sid IS NOT NULL AND sid!=''",
            (app_name, since),
        ).fetchone()[0]
        top = c.execute(
            """
            SELECT name AS n, COUNT(*) AS c
            FROM events
            WHERE app=? AND ts>=? AND name IS NOT NULL AND name!=''
            GROUP BY n
            ORDER BY c DESC
            LIMIT 40
            """,
            (app_name, since),
        ).fetchall()
        by_etype = c.execute(
            """
            SELECT etype AS e, COUNT(*) AS c
            FROM events
            WHERE app=? AND ts>=?
            GROUP BY e
            ORDER BY c DESC
            LIMIT 20
            """,
            (app_name, since),
        ).fetchall()
    return {
        "app": app_name,
        "since_hours": since_hours,
        "events": total,
        "players": players,
        "sessions": sessions,
        "top_events": [{"name": r["n"], "count": r["c"]} for r in top],
        "by_etype": [{"etype": r["e"], "count": r["c"]} for r in by_etype],
    }


def _funnel(app_name: str, since_hours: float = 168.0) -> dict[str, Any]:
    steps = FUNNELS.get(app_name, [])
    since = time.time() - since_hours * 3600
    if not steps:
        return {
            "app": app_name,
            "since_hours": since_hours,
            "steps": [],
            "note": "No funnel defined for this app. Add it to FUNNELS in shared/telemetry.py.",
        }

    with _conn() as c:
        rows = c.execute(
            """
            SELECT sid, pid, name
            FROM events
            WHERE app=? AND ts>=?
            """,
            (app_name, since),
        ).fetchall()

    by_key: dict[str, set[str]] = {}
    for r in rows:
        key = r["sid"] or r["pid"]
        if not key or not r["name"]:
            continue
        by_key.setdefault(key, set()).add(r["name"])

    counts = []
    prev = None
    for step in steps:
        n = sum(1 for seen in by_key.values() if step in seen)
        drop = None if prev is None else max(0, prev - n)
        rate = None if not prev else round(100.0 * n / prev, 1)
        counts.append(
            {
                "step": step,
                "sessions": n,
                "drop_from_prev": drop,
                "conversion_from_prev_pct": rate,
            }
        )
        prev = n

    return {
        "app": app_name,
        "since_hours": since_hours,
        "unique_keys": len(by_key),
        "steps": counts,
    }


def _dashboard_html(app_name: str, since_hours: float = 168.0) -> str:
    summary = _summary(app_name, since_hours)
    funnel = _funnel(app_name, since_hours)
    rows = "".join(
        f"<tr><td>{s['step']}</td><td>{s['sessions']}</td>"
        f"<td>{s['drop_from_prev'] if s['drop_from_prev'] is not None else '—'}</td>"
        f"<td>{s['conversion_from_prev_pct'] if s['conversion_from_prev_pct'] is not None else '—'}%</td></tr>"
        for s in funnel.get("steps", [])
    )
    tops = "".join(
        f"<li><code>{t['name']}</code> — {t['count']}</li>"
        for t in summary.get("top_events", [])
    )
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Telemetry — {app_name}</title>
<style>
body{{font-family:system-ui,sans-serif;background:#0b0b0f;color:#eee;margin:2rem}}
table{{border-collapse:collapse;width:100%;max-width:720px}}
td,th{{border:1px solid #333;padding:.5rem .75rem;text-align:left}}
th{{background:#1a1a22}}
code{{background:#1a1a22;padding:.1rem .35rem;border-radius:4px}}
a{{color:#9cf}}
</style></head><body>
<h1>Telemetry — {app_name}</h1>
<p>Events: <b>{summary['events']}</b> · Players: <b>{summary['players']}</b> · Sessions: <b>{summary['sessions']}</b>
(last {summary['since_hours']}h)</p>
<h2>Funnel</h2>
<table><tr><th>Step</th><th>Sessions</th><th>Drop</th><th>Conv%</th></tr>{rows or '<tr><td colspan=4>no funnel steps / no data</td></tr>'}</table>
<h2>Top events</h2><ul>{tops or '<li>none yet</li>'}</ul>
<p><a href="/tel_summary?app={app_name}">JSON summary</a> ·
<a href="/tel_funnel?app={app_name}">JSON funnel</a> ·
<a href="/telemetry/summary?app={app_name}&days=7">/telemetry/summary</a></p>
</body></html>"""


def mount_telemetry(
    app: FastAPI,
    default_app: str = "unknown",
    prefix: str = "",
) -> None:
    """Attach telemetry routes to an existing FastAPI app.

    Positional `default_app` matches existing callers:
        mount_telemetry(app, "tell")
    """

    def _resolve_app(query_app: Optional[str], batch_app: Optional[str] = None) -> str:
        return (query_app or batch_app or default_app or "unknown").strip() or "unknown"

    async def _ingest(request: Request, query_app: Optional[str] = None):
        try:
            payload = await request.json()
        except Exception:
            return JSONResponse({"ok": False, "error": "invalid json"}, status_code=400)
        try:
            batch = _parse_batch(payload)
        except Exception as e:
            return JSONResponse({"ok": False, "error": str(e)}, status_code=400)
        app_name = _resolve_app(query_app, batch.app)
        n = _insert_batch(app_name, batch)
        return {"ok": True, "inserted": n, "app": app_name}

    @app.post(f"{prefix}/tel_batch")
    async def tel_batch(
        request: Request,
        app_name: Optional[str] = Query(None, alias="app"),
    ):
        return await _ingest(request, app_name)

    @app.post(f"{prefix}/telemetry/batch")
    async def telemetry_batch(
        request: Request,
        app_name: Optional[str] = Query(None, alias="app"),
    ):
        return await _ingest(request, app_name)

    @app.get(f"{prefix}/tel_summary")
    @app.get(f"{prefix}/telemetry/summary")
    def tel_summary(
        app_name: Optional[str] = Query(None, alias="app"),
        days: Optional[float] = Query(None),
        hours: Optional[float] = Query(None),
    ):
        return _summary(_resolve_app(app_name), _hours_from_days(days, hours))

    @app.get(f"{prefix}/tel_funnel")
    @app.get(f"{prefix}/telemetry/funnel")
    def tel_funnel(
        app_name: Optional[str] = Query(None, alias="app"),
        days: Optional[float] = Query(None),
        hours: Optional[float] = Query(None),
    ):
        return _funnel(_resolve_app(app_name), _hours_from_days(days, hours))

    @app.get(f"{prefix}/tel")
    @app.get(f"{prefix}/telemetry/dashboard")
    def tel_dash(
        app_name: Optional[str] = Query(None, alias="app"),
        days: Optional[float] = Query(None),
        hours: Optional[float] = Query(None),
    ):
        return HTMLResponse(
            _dashboard_html(_resolve_app(app_name), _hours_from_days(days, hours))
        )

    @app.get(f"{prefix}/tel_health")
    @app.get(f"{prefix}/health")
    def tel_health():
        return {
            "ok": True,
            "db": str(_db_path()),
            "default_app": default_app,
            "funnels": list(FUNNELS.keys()),
        }

    # Convenience redirect so /telemetry lands on the dashboard.
    @app.get(f"{prefix}/telemetry")
    def tel_root():
        return RedirectResponse(url=f"{prefix}/telemetry/dashboard?app={default_app}")


def create_app(default_app: str = "elena") -> FastAPI:
    application = FastAPI(title="Shared Telemetry", version="1.0.0")
    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    mount_telemetry(application, default_app)
    return application


# Uvicorn target: shared.telemetry:app
app = create_app("elena")

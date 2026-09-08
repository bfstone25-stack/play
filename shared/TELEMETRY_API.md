# Shared Telemetry API (for humans + other AI sessions)

## Why this exists
Multiple prior sessions tried to add analytics and bounced because `shared.telemetry`
was imported but missing. This module is the real implementation.

**Canonical files**
- Server module: `shared/telemetry.py`
- Standalone launcher: `tools/telemetry/server.py`
- Elena Ren'Py client: `elena-suspense/game/scripts/04_telemetry.rpy`
- Elena game notes: `elena-suspense/TELEMETRY.md`

Do **not** invent a second telemetry stack.

## Quick start
```bash
# from repo root
python3 tools/telemetry/server.py
# health
curl -s http://127.0.0.1:27100/health
# dashboard
curl -s 'http://127.0.0.1:27100/telemetry/dashboard?app=elena' | head
```

Default DB: `~/Products/data/telemetry.db` (override with `TELEMETRY_DB`).
Default listen: `127.0.0.1:27100` (`TELEMETRY_HOST` / `TELEMETRY_PORT`).

## Mount into an existing FastAPI app
Matches existing callers in `tell`, `silvertongue`, `flutter`:

```python
from shared.telemetry import mount_telemetry
mount_telemetry(app, "tell")  # default app slug when ?app= is omitted
```

### Routes
| Method | Path | Notes |
| --- | --- | --- |
| POST | `/tel_batch` | primary ingest (HTML SDKs) |
| POST | `/telemetry/batch` | alias |
| GET | `/tel_summary` | JSON summary |
| GET | `/telemetry/summary` | alias; supports `days` or `hours` |
| GET | `/tel_funnel` | JSON funnel drop-off |
| GET | `/telemetry/funnel` | alias |
| GET | `/tel` | HTML dashboard |
| GET | `/telemetry/dashboard` | alias |
| GET | `/health` | health + configured funnels |
| GET | `/tel_health` | alias |

Query params: `app` (slug), `days` (float), `hours` (float). Default window = 7 days.

## Event batch schema
`POST /tel_batch?app=elena` body = JSON **list** (preferred by HTML SDKs) **or**
`{ "app": "elena", "events": [ ... ] }`.

Each event:
```json
{
  "pid": "anonymous-player-id",
  "sid": "session-id",
  "etype": "custom",
  "name": "game_start",
  "value": "{\"platform\":\"renpy\"}",
  "dur": 0,
  "ts": 1788820000.0
}
```

| field | required | notes |
| --- | --- | --- |
| `pid` | yes* | anonymous durable player id (*recommended) |
| `sid` | yes* | per-launch session id (*recommended; funnel prefers sid) |
| `etype` | no | default `custom` (`pageview` / `click` / `custom` / `event` ok) |
| `name` | yes | funnel step / event name |
| `value` | no | number, string, or JSON-encoded object (JS SDKs stringify) |
| `dur` | no | seconds |
| `ts` | no | unix seconds; server time if omitted |
| `meta` | no | object/string stored as JSON text |

SQLite table: `events(ts, app, pid, sid, etype, name, value, dur, meta)`.

## Elena funnel names
Ordered drop-off steps (`FUNNELS["elena"]` in `shared/telemetry.py`):

1. `session_start`
2. `game_start`
3. `vault_enter`
4. `choice_1`
5. `confrontation`
6. `branch_choice`
7. `climax_cg`
8. `dawn_resolution`
9. `end_cta`

Extra (not in funnel table, still useful): `cta_click` with `value.dest` = `itch` / `dlsite` / `f95`.

Read drop-off:
```bash
curl -s 'http://127.0.0.1:27100/telemetry/funnel?app=elena&days=30' | python3 -m json.tool
```

## Ren'Py client
File: `elena-suspense/game/scripts/04_telemetry.rpy`

- Endpoint: `persistent.telemetry_endpoint` or env `ELENA_TELEMETRY_URL`
- Default: `http://127.0.0.1:27100/tel_batch`
- Offline queue: `telemetry_queue.jsonl` under Ren'Py save dir
- Toggle: `persistent.telemetry_enabled` (default True when endpoint set)

Helper:
```renpy
$ tel_track("choice_1", {"choice": "ask_folder"})
$ tel_flush(True)
```

## Privacy
- No names / emails / PayPal / account ids
- Anonymous `pid` only
- Player can disable via `persistent.telemetry_enabled = False`
- Do not log raw dialogue content

## Adding another game
1. Append funnel step list to `FUNNELS` in `shared/telemetry.py`.
2. Reuse `/tel_batch` + the same event schema.
3. Mount with `mount_telemetry(app, "your_app_slug")` or POST with `?app=your_app_slug`.

## Smoke test
```bash
python3 tools/telemetry/server.py &
curl -s http://127.0.0.1:27100/health
curl -s -X POST 'http://127.0.0.1:27100/tel_batch?app=elena' \
  -H 'Content-Type: application/json' \
  -d '[{"pid":"p1","sid":"s1","etype":"custom","name":"session_start"},
       {"pid":"p1","sid":"s1","etype":"custom","name":"game_start"},
       {"pid":"p1","sid":"s1","etype":"custom","name":"vault_enter"}]'
curl -s 'http://127.0.0.1:27100/telemetry/funnel?app=elena&hours=1' | python3 -m json.tool
```

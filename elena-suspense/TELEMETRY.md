# Elena telemetry (player funnel)

This game posts anonymous stage events so we can see **where players stop**.

## Files
| Path | Role |
| --- | --- |
| `game/scripts/04_telemetry.rpy` | Client (`tel_track` / `tel_flush`) |
| `game/scripts/02_script_ch1.rpy` | Funnel instrumentation |
| `game/scripts/03_endscreen.rpy` | `end_cta` + CTA click tracking |
| `../shared/telemetry.py` | Ingest + funnel API |
| `../shared/TELEMETRY_API.md` | **Canonical API docs for other AI sessions** |
| `../tools/telemetry/server.py` | Standalone server on `:27100` |

## Local ingest
```bash
python3 tools/telemetry/server.py
# dashboard
curl -s 'http://127.0.0.1:27100/telemetry/dashboard?app=elena' | head
# funnel JSON
curl -s 'http://127.0.0.1:27100/telemetry/funnel?app=elena&days=7' | python3 -m json.tool
```

Point a build at a reachable host:
```renpy
$ persistent.telemetry_endpoint = "https://YOUR_HOST/tel_batch"
$ persistent.telemetry_enabled = True
```
Or env: `ELENA_TELEMETRY_URL`.

## Funnel steps (in order)
`session_start` → `game_start` → `vault_enter` → `choice_1` → `confrontation` → `branch_choice` → `climax_cg` → `dawn_resolution` → `end_cta`

CTA buttons also emit `cta_click` with `dest` = `itch` / `dlsite` / `f95`.

## Privacy
Anonymous `pid`/`sid` only. No dialogue text. Disable with `persistent.telemetry_enabled = False`.

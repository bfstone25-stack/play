# AFTER SIX — Godot 4.7 (prototype, 2026-09-19)

Beat the Monday's adult night twin: the same building, the same cast, the same engines,
one extra rule — **by day you survive them, after six you get even** — a crime thriller
where **intimacy is power's consequence, never its instrument**
(`ops/adult_forks/beat_monday_map.md` §2, `TWO_WORLDS.md`, studio rules 2026-09-18).

A fork of `play/beat-monday-godot/` (copy, then diverge). The graph (`bm_map.gd`), the
triage (`bm_triage.gd`), the tactics engine (`bm_persuasion.gd`, untouched) and the
reflex core (`bm_core.gd`, conformance-tested) are the day game's. What differs is what a
node *means*, and the light.

| node | by day | after six | engine |
|---|---|---|---|
| standup | the Monday circle | **the security round** — stay out of the torch beam | `bm_core.gd` DAYS[0] |
| inbox | the buried desk | **her desk — the case**: search it for evidence (BAG / SHRED / HAND OFF / LATER), assemble leverage | `bm_triage.gd` |
| review | the raise conversation | **the confrontation**: the same `advance()` engine, same RULES row, the lines re-written for exposure; threats and bribes end it for good — you would just be them | `bm_review.gd` on `bm_persuasion.gd` |
| — | — | **the offer scene** (§2.2): she offers herself for silence; REFUSE (aim it at the CFO) or PUT IT DOWN keep the line, TAKE THE DEAL is the transaction: no scene, node lost | `main.gd show_offer` |
| — | — | **the return**: 23:40, she comes down on her own — the tier-3 slot `cg_return_x`, behind `as_cg.gd` | `as_cg.gd` + `web/aftersix_gate.js` |
| map | the building, lit | the same cells relit: a window is on only where someone is still in the building, and the tag says who | `map_screen.gd` |
| clear | Saturday | **the night is yours** — and the adult board | `main.gd show_clear` |

The test for every scene: *would she still come if you had nothing on her?* The return
happens only after the leverage is refused or put down (`AsCg.EARN`), never after the deal.

## Run

```
GODOT=~/bin/godot/Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import          # once, and after new files
ops/on_game_monitor.sh $GODOT --path .       # desktop, on the game monitor (never the document one)
bash tests/run.sh                            # 196 checks (the day game's suite, on the night's cards)
./build.sh                                   # -> build/godot/after-six/{web,linux,windows} + build/godot-ads/after-six
python3 tests/night_web.py                   # plays the five steps against the ads page, shots -> shots/
```

To play it in a browser:

```
cd build/godot-ads/after-six && python3 -c "
import http.server,socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(s): s.send_header('Cross-Origin-Opener-Policy','same-origin'); s.send_header('Cross-Origin-Embedder-Policy','require-corp'); super().end_headers()
socketserver.TCPServer.allow_reuse_address=True; socketserver.TCPServer(('127.0.0.1',8871),H).serve_forever()"
# then http://127.0.0.1:8871/
```

## Tracks and rules

- Built by `ops/aftersix_build.sh` (not the mainstream exporter): itch page, ads page
  (`DIST=ads_web`, `ops/adult_ads_config.js` = the 18+ Adsterra unit, this page only),
  desktop downloads with no third-party call (audited). No portal package, ever.
- The adult build lives only on `*.flat404.workers.dev`. `ops/check_adsense_isolation.py`
  must stay green.
- The CG gate is the fixed family: `web/aftersix_gate.js` is Floor 13 X's gate renamed —
  no rendered creative ⇒ `unavailable` ⇒ the plate stays censored. `tests/night_web.py`
  proves it on localhost (QA path, no creative served, status `unavailable`).
- The open tier-3 plate goes in `assets/cg_open/` and is excluded from every web pack
  (`export_presets.cfg`; the build audits the .pck).

## What is placeholder (honest list, 2026-09-19)

1. ~~Every plate is the day plate relit~~ **Done 2026-09-19.** Every gameplay screen now
   draws After Six's own rendered night interior (`plate_as_room_*`), not a day plate
   pushed two stops down by `tools/night_tint.py`. The stopgap is kept only as the
   `FALLBACK` map in `map_screen.gd`, so a room whose render has not landed degrades to
   the day plate instead of disappearing. `night_title` and `night_tue` in the day
   generator are now unused by this game and can go when the title pass lands.
2. **`cg_return_x` — the render pipeline exists; the plate is still a placeholder.**
   The blocker named here is gone: the fork has its own generator
   (`ops/after_six_art/after_six_gen.py`, queued as `after_six`) with Mira's cast bible, a
   tier-3 slot whose negative bans the genitals rather than the whole of `nude`, and a
   tier-2 `cg_return_x_locked` to replace the labelled PIL card. Until a candidate has been
   picked *at native resolution* into `ref/mira.png` and `assets/cg_open/`, the censored
   placeholder is what draws — which is the honest state, not a silent one.
3. ~~Web delivery of the open plate is not wired~~ **Wired 2026-09-19.**
   `scripts/as_unlock.gd` is the port of Floor 13 X's `unlock.gd`: a ticket is taken when
   the gate opens, the bytes are fetched when it clears, and they land in `user://unlocked/`.
   `AsCg.is_unlocked()` on the web now means *those bytes are on this machine* — never that
   a boolean was set — and `AsCg.plate_texture()` is what callers must use, because a
   delivered plate is a `user://` file that `load()` will not open. The honest "unavailable"
   answer survives unchanged: a gate that clears with nothing staged still draws censored.
   `tests/unlock_web.py` proves the positive in a real browser against a local stub gateway
   (nothing is deployed), and it fails unless the *frame pixels actually change* — a
   flipped boolean is not a reveal. It needs real open bytes and refuses to invent them, so
   it is skipped until item 2's render lands.
4. **Sprites**: the actor sprites are the day game's rendered office workers; the reflex
   arena's foes and the triage cards' actors fall back to the day game's vector rigs where
   no render exists (the same code-drawn fallback the day game has; the triage cards' icon
   was dropped rather than drawn).
5. **Title screen**: a plain title over the relit plate — no logotype, no key visual, no
   motion (`TITLE_SCREENS.md` not yet applied). 18+ line is a Label.
6. **The seventh floor** (`review` node), **the last train** (`allhands`), **the server room
   at 2am** (`deploy`) and the corridors are re-labelled, not re-designed: same play.
7. **No sound pass**; SFX are the day game's.
8. **zh-Hans** copy is written but not proofread by a native reader.

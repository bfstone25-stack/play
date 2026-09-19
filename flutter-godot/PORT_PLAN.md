# Porting Flutter 怦然 to Godot 4.7 — the plan, and what it actually costs

Written 2026-09-19, with the title screen built and nothing else. **Blaze decides whether
any of the rest happens.** Nothing below step 0 has been started.

## The engine, and why

Godot 4.7, not Ren'Py.

`ops/adult_forks/TITLE_SCREENS.md` says Ren'Py is a game engine and the right one for
visual novels, and Flutter is an otome — so Ren'Py is the obvious guess. It is the wrong
one, for one reason that decides it:

**Flutter has no script.** Elena, Room 704 and Confession Room are written: a `.rpy` file
holds the lines, the branches and the endings, and Ren'Py's whole value is being the best
language in the world for writing exactly that. Flutter holds nine *premises*
(`backend/stories/*.json`: a scene, a goal, an opening, and beats that fire on a turn
count and an affection floor) and generates every line at runtime from a local LLM. The
authored content is about 5% of what the player reads.

So the things the game actually needs from an engine are:

| what Flutter needs | Godot 4.7 | Ren'Py |
| --- | --- | --- |
| a streaming HTTP response rendered token by token | `HTTPClient` chunked, or `HTTPRequest`; normal | threads + a custom displayable, fighting rollback |
| free-text player input | `LineEdit` | not a thing the engine does; `renpy.input` is a modal box |
| server-authoritative state (affection, memories, attachment) | plain | fights `rollback`, which exists to rewind state |
| a web export people install as a PWA | first-class | `renpy-web` is heavy and poor at networking |
| five market editions from one build | `locale/include_text_server_data` | fine |
| the dual track (itch paid / ad-funded) | `shared/godot/gate.gd`, already written | nothing |

Ren'Py's rollback is not a minor obstacle — it is the feature that makes it a VN engine,
and it is incoherent with a game whose state lives on a server and whose dialogue cannot
be regenerated identically. Godot is also already the house engine for the other three
mainstream parents, and `ops/godot_build.sh` builds both tracks off one source tree today.

## Step 0 — the title screen (DONE, this is what exists)

`scenes/main.tscn` + `scripts/title_screen.gd`. Key visual with drift, swell and pointer
parallax; a baked lamp glow that breathes; two dust sheets at different speeds; the baked
overlay plate; the Parisienne mark settling in; a four-item menu rail with hover, press and
sound; the studio mark; a title sting. Landscape and portrait both captured and read.

Cost: done. The four menu items emit `chose(action)` and land on `push_warning` — the seam
every step below plugs into.

## What breaks, and what it costs

Ordered so that each step is shippable on its own and nothing is a big-bang rewrite. The
estimates are working days for one agent, and they assume the FastAPI backend is **not**
touched — which is the single biggest decision in this plan and the reason it is cheap.

### The backend does not move

`backend/app.py` (758 lines) plus `reasoning_engine`, `attachment` and `story_engine` keep
running exactly as they are. Godot talks to the same `/routes`, `/say`, `/say_stream`
endpoints over HTTP. Rewriting the reasoning engine in GDScript would be weeks and would
buy nothing; the LLM is behind an HTTP call either way.

The consequence is that **Flutter stays an online game.** It is one today, so this is not a
regression — but it does mean the itch desktop download still needs the backend reachable,
and that is worth saying out loud before anyone promises an offline build.

### 1. The chat loop — 3 days

The game proper: portrait, name, streaming reply, the affection bar, the mood and
attachment badges, the chat log, the input row, the quick-action chips.

The hard part is **streaming**. `/say_stream` returns a chunked body; `HTTPRequest` wants
the whole response. This needs `HTTPClient` driven from `_process` with
`poll()` / `read_response_body_chunk()`, decoding partial UTF-8 across chunk boundaries
(a multi-byte character split across two chunks is the bug that will happen), and pushing
into a `RichTextLabel`. Budget a day for that alone; it is the piece with no library.

### 2. Route select and the nine cards — 1 day

Straight port of `#cards`. Needs the route portraits as textures — they exist under
`ops/flutter_art/out/plates/`, so this is layout, not art.

### 3. Editions, en/zh/ja/es/pt-BR — 2 days

`frontend/editions.js` is not a language file. Each edition carries its own palette,
typography, title and tagline — it re-skins the game. In Godot that is a `Theme` per
edition plus a translation CSV.

**This is where a port most easily goes wrong**, and the rule is: the strings come out of
the existing source and into `.csv` once, mechanically. A second hand-typed copy of five
languages in GDScript is how the two tracks drift. The CJK fallback is already wired in
`title_screen.gd` and the `.ttc` is already in the export preset — but see
`godot-web-font-fallback`: it must be verified **on the web build**, not the desktop run.

### 4. The ad gate — 1 day

`shared/godot/gate.gd` already exists and already does this, so the code is nearly free.
What is not free is the **Adsterra unit**. Units are domain-locked. The Godot web build
served from a different origin than the PWA is a different domain, which means either it
is served from the same origin or a new unit is registered — and the wrong unit is zero
revenue plus a policy risk (`ad-gate-rules`, `f95-ban-direct-link-ads`). Decide the
hosting origin **before** writing this step, not after.

Also: `ops/check_adsense_isolation.py` must stay green, and the Godot build must never
carry the adult unit or any Flat 404 reference.

### 5. Telemetry — 1 day

`ops/godot_build.sh` already stamps the telemetry SDK into the exported page, so the web
track is mostly wiring. The risk is the one in `itch-telemetry-blind-spots`: an event
renamed or dropped in the port does not look like a failure, it looks like a number going
down. **Both builds must emit the same event names**, and the port must be verified by
comparing a day of events from each — a check that has to be made to fail once before it
is trusted (`verification-that-lies`).

### 6. The memory archive and the opening — 1.5 days

`#archiveOv` and `opening.js`. Self-contained; safe to do last.

### 7. The promo board and cross-promo — 0.5 days

`play/_shared/board.js` is JavaScript and decides adult-vs-SFW promotion **by hostname**,
which is the safety property. A Godot port either calls out to the page's board through
`JavaScriptBridge` (keeping that property, and breaking on desktop) or reimplements it in
GDScript (and has to re-earn the property). Prefer the bridge on web, nothing on desktop.

### 8. PWA install, service worker, offline shell — 0.5 days, or cut

The Godot web export is not a PWA by default and the preset above has it switched off. The
current build is installable and some players have installed it. Either turn on Godot's PWA
support or accept the regression; this is a product call, not a technical one.

## Total

**10.5 working days**, plus QA, plus the two decisions that gate it (the hosting origin for
the ad unit, and whether the PWA install survives). Call it **three weeks of evenings** at
the rate this repo actually moves.

## What I would cut if it has to be cheaper

Steps 1, 2 and 3 are the game. Steps 6, 7 and 8 are 2.5 days for things almost nobody
touches. A Godot Flutter that is the title screen, the route select, the chat loop and the
five editions — and which links back to the existing PWA for the archive — is **6 days**
and is the version worth asking for first.

## What does NOT change

- The backend, the database, the memory and affection model, the nine stories.
- The adult fork (`play/flutter-after-hours/`), which is a separate build and a separate
  decision. Nothing here touches it.
- The web PWA, which keeps shipping until the Godot build is actually better. Both read
  the same key visual today — see the `also` entry in `ops/install_keyvisual.py`.

# The Other Side

The adult night twin of *Across the Hall* — a derivative under `ops/adult_forks/TWO_WORLDS.md`.
Study: `ops/adult_forks/across-the-hall.md` (verdict overruled by Blaze, 2026-09-19).

**The rule.** In Across the Hall there was never anyone across the hall. Here the bathroom
mirror shows the neighbour, and the neighbour is you as you would be if you claimed what you
want — a rendered adult — and the game is walking toward them. Cut the figure and the rule has
no payoff; that is TWO_WORLDS' test.

## The four beats (prototype, playable end to end)

1. Wake in 401 on the night palette (`ops/adult_forks/UI_DIRECTION.md`). The 401 bathroom
   mirror (`scripts/mirror.gd`) is a mirror-shaped surface carrying a rendered plate; the
   figure moves only while you stand still.
2. Cross the hall. 402 is closed and opens when you knock (it was the other way round in the
   parent). 402 is 401 mirrored (`world_builder.gd`, already built in x-mirror); one real thing
   per room — a framed rendered print in the front room, black glass in the bathroom.
3. The tenant (`scripts/tenant.gd`) resolves from the capsule into a rendered person on a
   billboard as you approach, then stops hunting and faces you. Four lines through the
   click-to-advance panel (`hud.show_dialogue`), then a choice: `1` keep him, `2` refuse.
4. The choice decides whether the 401 mirror keeps its image. Clear state, then the adult
   cross-promotion board (`Gate.board_offer_more("adult")`).

## Gating

- `assets/plates_x/cg_mirror.png` is the uncensored mirror plate. It is export-excluded
  from the Web preset (`export_presets.cfg`), and `ops/other_side_build.sh` audits the pack.
- The web build ships `assets/plates/cg_mirror_locked.png`. Looking in the mirror a second
  time on the web runs `Gate.require(..., "cg")` (gate.js: no rendered sponsor creative, no
  unlock) and then the `/unlock/start` + `/unlock/fetch` ticket (`scripts/unlock.gd`, copied
  from Overnight Clause, `APP := "the-other-side"`). No bytes, no plate.
- Adult build only on `*.flat404.workers.dev`; 18+ unit from `ops/adult_ads_config.js`.
  `ops/check_adsense_isolation.py` must stay green.

## Play it locally

    ops/other_side_build.sh
    python3 play/the-other-side-godot/scripts/serve_web.py --port 8061 --dir build/godot-ads/the-other-side
    # then http://localhost:8061/ in a WebGL2 browser

Desktop window: `ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path play/the-other-side-godot`.

Web drive hook (test only): `window.__cmd = "goto x z yaw" | "use" | "look dx" | "state"`.

## Placeholders (honest list)

Rendered and installed (2026-09-19):

- `assets/plates_x/cg_mirror.png` — Ray in the 401 mirror, the real plate. Picked from
  eight candidates read at native 832x1216; `ops/other_side_art/ref/ray.png` is ray_04.
- `assets/plates/cg_mirror_locked.png` — the censored partner. Same face, same framing,
  clothed; a real render, not a blur of the uncensored one.
- `assets/plates/tenant.png` — the tenant, cut to an RGBA sprite by
  `ops/other_side_art/cut_sprite.py`.

Still placeholder:

- `assets/plates/obj_402.png` is still an Overnight Clause room plate.
- `splash.png` is still the parent's splash. There is no key visual and no logotype
  (TITLE_SCREENS.md items 1 and 2 are both open); the title card in-game is a drawn plate,
  not a designed mark.
- No sound of its own beyond the parent's synthesised drone and clicks.
- No downloads, no itch page, not deployed.

## What is verified on camera, and what is not

`tests/walkthrough.gd` drives the real game and photographs it — see below. Fifteen frames
in `ops/adult_forks/shots/other-side/`, all read at full size and again at 390 px.

Verified: beat 1 (the mirror in a bathroom you can see you are standing in, the plate
seated in the bezel under the room's own light), beat 2 (401 opens, 402 knocks open, the
mirrored flat), beat 3 (the tenant resolving from capsule to rendered person in 402's
bathroom doorway, the four-line exchange, the choice), beat 4 (the choice keeping the
image in the glass, the clear state).

NOT verified on camera: the adult cross-promotion board. `Gate.board_offer_more("adult")`
is drawn by `play/_shared/board.js` on the page, so it does not exist in a desktop run at
all; the ending frame shows the clear state and nothing else. Verifying it needs the web
build served and driven in a browser.

## Capturing the frames

    ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
      --path play/the-other-side-godot res://tests/walkthrough.tscn

Run it as a SCENE. `--script` mode does not build the autoload list, so every script that
mentions `Gate` fails to compile and the capture photographs an empty viewport while
reporting success. After replacing any plate, run `--headless --import` first: the game
loads the cached `.ctex`, so a new PNG on disk with a new hash will still render as the old
image until it is re-imported.

Frames are checked two ways and both must be run by looking:

    ops/check_brightness.py ops/adult_forks/shots/other-side/*.png

12 of 15 frames sit inside the shelf band (UI_DIRECTION.md, 2026-09-19). `01_wake` (0.44),
`09_402_print` (0.44) and `15_end` (0.39) flag against the 0.45 floor. The first two are a
hair under and are the two frames the opening note panel covers a third of; the ending is
deliberately the darkest beat in the game. All three are open, not resolved.

The palette here is a genuine tension and it is Blaze's call, not settled by this pass:
UI_DIRECTION's 2026-09-19 numbers (0.63 brightness / 0.38 saturation, from the Nutaku
top-100) and a first-person horror game set at 02:17 pull in opposite directions. Hitting
the shelf floor took the flats from plum-night to a warm lit interior. The frames read as
rooms and pass the check; they do not read as a night palette with hot accents, which is
what the same document asks for higher up.

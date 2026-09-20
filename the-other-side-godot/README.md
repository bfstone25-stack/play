# The Other Side

The adult night twin of *Across the Hall* — a derivative under `ops/adult_forks/TWO_WORLDS.md`.
Study: `ops/adult_forks/across-the-hall.md` (verdict overruled by Blaze, 2026-09-19).

**The rule.** In Across the Hall there was never anyone across the hall. Here there was
never anyone, and then there was.

> Across the hall is a woman. She is what is on the other side of the door you never
> opened — the life you did not claim, standing in it. The mirror shows her because at
> 02:17 the glass stops showing you what you settled for.

The game is walking toward her. Cut the figure and the rule has no payoff; that is
TWO_WORLDS' test.

*Recast 2026-09-19 (Blaze).* The neighbour was your own face rested — a man — and the
payoff was therefore a half-dressed man in a doorway, on shelves (DLsite, Nutaku) whose
payers are men. Changing the premise's gender cost the premise nothing and pointed the
payoff where the buyers are. Every line of prose was rewritten rather than
pronoun-swapped, because she is a different person from the player and not a copy of him.
The cast is one woman, **Iris, 33**; the player stays a first-person camera with no body,
which the parent already required.

## The four beats (prototype, playable end to end)

1. Wake in 401 on the night palette (`ops/adult_forks/UI_DIRECTION.md`). The 401 bathroom
   mirror (`scripts/mirror.gd`) is a mirror-shaped surface carrying a rendered plate; the
   figure moves only while you stand still.
2. Cross the hall. 402 is closed and opens when you knock (it was the other way round in the
   parent). 402 is 401 mirrored (`world_builder.gd`, already built in x-mirror); one real thing
   per room — a framed rendered print in the front room, black glass in the bathroom.
3. The neighbour (`scripts/tenant.gd`) resolves from the capsule into a rendered person
   on a billboard as you approach, then stops hunting and faces you. Four lines through the
   click-to-advance panel (`hud.show_dialogue`), then a choice: `1` keep her, `2` refuse.
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

Desktop window: `SHOW_GAME=1 ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64
--path play/the-other-side-godot` — and only when Blaze has asked to watch. Without
`SHOW_GAME=1` the wrapper refuses and `ops/keep_windows_off_docs.sh` kills the window
anyway: this game is first-person and calls `MOUSE_MODE_CAPTURED`, which locks his pointer
to it.

Web drive hook (test only): `window.__cmd = "goto x z yaw [pitch]" | "use" | "look dx" |
`"state"`. `state` reports the neighbour's position as well as the player's.

## Placeholders (honest list)

Rendered and installed (2026-09-20, all of it re-rendered for the recast — the previous
pass's plates were a man and none of them survive):

- `assets/plates_x/cg_mirror.png` — Iris in the 401 mirror, the real plate, tier 3.
  Picked from six candidates read at native 832x1216; the pick is the one with her palm
  raised against the glass, because that is what `NOTES["kept"]` describes.
  `ops/other_side_art/ref/iris.png` is iris_03 of eight.
- `assets/plates/cg_mirror_locked.png` — the censored partner. Same face, same bathroom,
  same bulb, oversized shirt; a real render, not a blur of the uncensored one.
- `assets/plates/tenant.png` — cut to an RGBA sprite by `ops/other_side_art/cut_sprite.py`
  (kept 20.2% of the frame). The slot is lit flat on white specifically so it keys.
- `splash.png` — the key visual: her in 402's open doorway, the corridor the colour of a
  bruise. Graded up to the SHELF floor by `ops/other_side_art/grade_keyvisual.py`, which
  re-runs `check_brightness.py` on what it wrote. The render measured 0.59/0.24 — bright
  but *washed*, the checker's other failure mode — and the graded file is 0.64/0.35.

Still placeholder:

- **There is still no logotype.** `splash.png` is a key visual, not a designed mark;
  TITLE_SCREENS.md item 2 is open. The in-game title card is type on a drawn plate.
- `assets/plates/obj_402.png` is still an Overnight Clause room plate — the one figure-free
  slot, and the only plate in the game that is still another title's.
- `PLATES["cg_doorway"]` (the ending plate, rear nudity) is written and NOT rendered.
- No sound of its own beyond the parent's synthesised drone and clicks.
- No downloads, no itch page, not deployed.
- The DESKTOP build's palette is unverified. Everything below is measured on the web
  build, because the desktop renderer cannot be photographed on this machine at all.

## What is verified on camera, and what is not

**The desktop renderer cannot be photographed on this machine any more, and that is not a
workaround problem — it is a wall.** `ops/on_game_monitor.sh` refuses to open a visible
game window without `SHOW_GAME=1` and `ops/keep_windows_off_docs.sh` kills one that
appears anyway, because this game calls `MOUSE_MODE_CAPTURED` and takes Blaze's pointer.
The obvious answer, `--headless`, does not work: Godot's headless display server forces
the *dummy* rendering driver. Tested both ways —

    godot --headless --path . res://tests/walkthrough.tscn
    godot --display-driver headless --rendering-driver vulkan --path . res://tests/walkthrough.tscn

— and both run the whole walkthrough green to `WALKTHROUGH_OK` while every
`get_texture().get_image()` returns null and every frame is silently not written. A
capture script that passes while photographing nothing is the exact failure this
directory's notes keep warning about, so it is written down rather than rediscovered.
There is no Xvfb on this box.

So the frames now come from `tests/web_walkthrough.py`: the shipping web build, served
locally and driven in headless Chromium through the game's own `window.__cmd` hook and
real Playwright key events. **These are web frames** — GL compatibility, the web
environment tweaks in `game.gd`, and `world_builder._compat_trim()`. They are what a
browser player sees on the ads track. They are not the desktop paid build, and the
desktop build is currently unphotographable.

**Verified (2026-09-20, sixteen frames in `ops/adult_forks/shots/other-side/`):** beat 1
(a bathroom you can see you are standing in, the plate seated in the bezel under the
room's own light), beat 2 (401 opens, 402 knocks open, the mirrored flat), beat 3 (she
resolves from capsule to rendered person in 402's bathroom doorway, the four-line
exchange, the choice), beat 4 (the choice keeping the image in the glass, the clear
state) — and, for the first time, **the adult cross-promotion board**: two tiles, Elena
and Room 704, on `*.flat404.workers.dev` with `?src=the-other-side`.

Getting there found a bug that had nothing to do with this game.
`Gate.board_offer_more()` drew nothing, in every title, at the end of every run.
`?warp=board` isolated it: `second: 1` (the break board draws) against `more: 0, tiles: 0`,
while calling `BOARD.offerMore("adult")` straight from the page on the same build drew it
in under five seconds. The bridge worked and board.js worked; only gate.gd's compound
`window.BOARD && BOARD.offerMore && BOARD.offerMore(k)` form did not. Fixed in
`shared/godot/gate.gd` to the guard-then-call shape `board_offer_break()` already used.
It only surfaced because someone RAN the hook: the call was wired, the script shipped,
the host allowed it, and nothing appeared.

Two frames sit on the floor rather than above it (`01_wake` and `09_402_print`, both
0.22) and `15_end` measures anywhere from 0.09 to 0.26 depending on where the shot lands
relative to `_dim_hall(0.35)` — the ending is deliberately the darkest beat, and that is
the one number worth watching rather than chasing.

## Capturing the frames

    ops/on_game_monitor.sh ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
      --path play/the-other-side-godot res://tests/walkthrough.tscn

Run it as a SCENE. `--script` mode does not build the autoload list, so every script that
mentions `Gate` fails to compile and the capture photographs an empty viewport while
reporting success. After replacing any plate, run `--headless --import` first: the game
loads the cached `.ctex`, so a new PNG on disk with a new hash will still render as the old
image until it is re-imported.

Frames are checked two ways and both must be run by looking:

    ops/check_brightness.py --scene ops/adult_forks/shots/other-side/*.png   # in-game
    ops/check_brightness.py ops/adult_forks/shots/other-side/00-title.png    # the shelf

**The two floors are not the same floor, and applying the wrong one wrecked this game
once already.** Blaze, 2026-09-19: the 0.45/0.30 floor is for store art and title screens,
which compete as thumbnails on a shelf next to ninety-nine others. An in-game frame
answers to legibility instead — `--scene`, 0.22/0.18. The previous pass applied the shelf
floor to all fifteen captures, and hitting it took the flats from 02:17 to a warm lit
interior: a first-person horror game at two in the morning with the big light on. The
README note recording that tension was the right response and the rule has since been
split in the checker itself.

So this pass takes the flats back: plum-black grounds, one light source, the doorway
spill doing the work (`world_builder.gd`, the palette note at the top; and
`_compat_trim()` for what the web renderer does to the same numbers). The title screen
stays at the shelf floor, because that is the picture that has to sell.

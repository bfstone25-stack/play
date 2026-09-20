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

- Every plate. `cg_mirror.png` / `tenant.png` are the Overnight Clause *Dane* reference
  render (a rendered adult man, not Ray); `obj_402.png` is an Overnight Clause room plate;
  `cg_mirror_locked.png` is a blurred copy, not a `censor.py` plate. Real plates come from
  `ops/other_side_art/other_side_gen.py` via `ops/render_queue.py add other_side refs|plates`.
- `splash.png` is the parent's splash; no key visual or logotype yet (TITLE_SCREENS.md).
- The tenant cut-out is a colour-key of a flat-grey studio render; edges are rough.
- No sound of its own beyond the parent's synthesised drone/clicks.
- No downloads, no itch page, not deployed.

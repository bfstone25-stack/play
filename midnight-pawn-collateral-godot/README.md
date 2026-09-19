# Midnight Pawn: Collateral (Godot)

The adult (18+) fork of *Midnight Pawn & Crypt*, as a **Godot 4.7 2D pixel game** — which
is what the base game is, and what a fork of it has to be.

Nara Quill appraises by touch: a hand on an object shows you its last use. Five clients,
five objects, one descent into the Ossuary Market, three endings. ~9,300 words, five choice
clusters, deterministic integer economy, six readings of which five are gated.

## Why this directory exists

There is a Ren'Py version of this fork at [`../midnight-pawn-collateral/`](../midnight-pawn-collateral/).
It was built first, and building it in Ren'Py was the wrong call. The reasoning recorded in
its README is all about tooling — `09_dist.rpy` is 564 lines and has shipped twice,
`gate.gd` is 71 lines and never has — and every word of that is true and none of it is a
product argument. Blaze's rule is that **an adult fork keeps the original's form**: its
engine, its genre, its dimensionality, its feel. Midnight Pawn is a Godot pixel game. Its
fork is now a Godot pixel game.

The Ren'Py version is still on disk and is not deleted. The prose is the expensive part,
and it was not thrown away to prove a point — it was moved, and the move is verified
below before anything gets removed.

## What came across, and from where

| from | what |
|---|---|
| `../midnight-pawn-collateral/game/scripts/*.rpy` | all 9,300 words, five appraisals, the descent, three endings → `scripts/story.gd` |
| `../midnight-pawn-collateral/game/python-packages/collateral_core.py` | the whole rules module, line for line → `scripts/collateral_core.gd` |
| `../overnight-clause/scripts/unlock.gd` | the server-gated art model, third product to use it → `scripts/unlock.gd` |
| `../overnight-clause/scripts/plates.gd` | the plate layer and gallery → `scripts/plates.gd` |
| `~/midnight-pawn-src/scripts/gate.gd` (Blaze Ubuntu) | the base game's own chapter gate, **verbatim** → `scripts/gate.gd` |
| `~/midnight-pawn-src/scripts/pixel_stage.gd` | the 300x240 scene window, minus the dungeon half → `scripts/pixel_stage.gd` |
| `~/midnight-pawn-src/assets/` | the shop, the Ossuary Market and the dawn scenes, the character sheet, both bitmap fonts — the same PNGs, not copies of them |

`project.godot`'s `[display]` block is byte-identical to the base game's: 640x360, integer
stretch, nearest filtering. It is the same canvas.

## The cast: the base game's, not the design doc's

The doc invented **Tamsin Bell**, **Ivo Lask** and **Widow Merrow** while the Godot source
was believed lost. The source is not lost, and its customers are **Tamsin Reed** and **Ivo
Glass** and its widow is **Mara Voss** (`game_state.gd:18-23`). The Ren'Py fork chose the
doc's cast, on the grounds that `ops/midnight_pawn_art/midnight_pawn_gen.py` was built
around it.

This port chooses the **base game's cast**, and the art generator has been changed to match
rather than the other way round. The reason is the same reason this directory exists: when
the fork and the original disagree, the original is the thing that shipped and the fork is
the thing that moves. The given names were already right; only three surnames and one first
name changed, and no sentence of the writing depends on them.

`ops/midnight_pawn_art/midnight_pawn_gen.py` now reads `MARA` / `"mara"` throughout, and
`NEG_EXTRA` with it. The prose and the art list agree for the first time.

## The six readings, and what earns each

No CG unlocks from playtime. Every condition is a pure function of run state, they all live
in one table (`CollateralCore.cg_conditions`), and `tests/rules.gd` asserts each one
individually — including that an untouched run unlocks nothing no matter how long it took.

| slot | gated | earned when |
|---|---|---|
| `cg_tamsin` | no | read the finial **and** priced it FAIR |
| `cg_finial` | yes | read the finial **and** priced it HIGH — the same vision, further in |
| `cg_ring` | yes | took the ring's reading **after Ivo asked you not to** |
| `cg_veil` | yes | read the veil **and** offered Mara more than it is worth |
| `cg_market` | yes | carried ≥ 2 client readings down to Calder |
| `cg_collateral` | yes | the last appraisal — unrefusable, no condition |

`cg_tamsin` and `cg_finial` are mutually exclusive in one run (FAIR vs HIGH), so a single
playthrough tops out at five of six. The Ledger is per-save and completion takes more than
one night.

### A bug the port found, by being looked at

The Ren'Py version showed `cg_finial` at the moment of the first reading, because
`reading_show(item)` picked the plate by item name. `cg_finial` is **gated**. So on the free
track, the first plate a browser player ever saw was a silhouette — which is precisely the
bait screen `09_dist.rpy:17` blames for Room 704's 75 browser plays and zero purchase
clicks, written into the one scene that exists to prevent it.

The opening reading now shows `cg_tamsin`, the one ungated plate, and `cg_finial` arrives
later in the HIGH branch as mercy's reward, against lines that were already there — no new
prose. `tests/plates.gd` asserts the opening plate is ungated so it cannot come back.

This was found by rendering four frames and looking at them, not by reading the code.

## The reading fee, and the second-paywall problem

Both of the things the Ren'Py build found by *running* are here, and both are tested:

1. **The fee is refunded when the art does not arrive.** `Collateral.delivered()` asks
   whether the uncensored plate actually landed; if it did not, `Story.reading_take()` puts
   the money back and says so in two lines of dialogue. Charging shop cash for a silhouette
   is what the failure actually feels like, and it is impossible.
   `tests/plates.gd` runs the free-track path and asserts the till ends where it started
   **and** that the refund is spoken aloud rather than done silently.
2. **Nobody is asked for the same money twice.** The Ren'Py simulator caught the first draft
   asking for the fee in the scene menu and then again on the next screen. `reading_take()`
   is separate from any offer for exactly that reason, and every scene that asks in its own
   voice calls it directly. A fee prompt after the player has already said yes is the
   precise texture of a nag paywall.
3. **Every fee is affordable on an honest run.** Price everything FAIR, pay all three fees,
   and you clear the debt with 35 to spare. `tests/rules.gd` asserts the number, and
   `tests/playthrough.gd` plays the route to it.
4. **The two vocabularies never mix.** The fee menu is the shop's own voice and never
   mentions money that is not shop money. The demo cut screen is the only thing in the game
   that mentions a price.
5. **The Reading Ledger is shown before the final appraisal**, greyed slots visible, while
   there is still an appraisal left. Refusal is a decision made, not an accident found.

## The gate is honest, and here is the proof

The uncensored plates are not censored in the free build. They are **not in it**.
`assets/plates_x/*` is excluded from both Web presets, so editing a save, a URL or the scene
tree gets you a censored plate, because that is the only plate in the download.

```
$ tools/pack_audit.sh /path/to/Godot_v4.7-stable_linux.x86_64
   380K  build/web/index.pck
   OK: no reference to assets/plates_x/ anywhere in the free web pack
   OK: all 5 censored stand-ins are in the free web pack
   496K  build/linux/midnight-pawn-collateral.pck
   OK: cg_collateral is in the paid pack        (…and the other four)
PACK_AUDIT_OK  free=380K paid=496K
```

It exports both builds and greps the packs. It checks the paid side too, because a gate that
leaves paying customers with silhouettes is the other way to get this wrong.

## Verify

```bash
GODOT=/path/to/Godot_v4.7-stable_linux.x86_64
$GODOT --headless --path . --import                  # once
$GODOT --headless --path . -s res://tests/rules.gd        # RULES_OK
$GODOT --headless --path . -s res://tests/plates.gd       # PLATES_OK
$GODOT --headless --path . -s res://tests/playthrough.gd  # PLAYTHROUGH_OK — 5 routes
./tools/pack_audit.sh $GODOT                              # PACK_AUDIT_OK
$GODOT --path . --resolution 1280x720 -s res://tests/shots.gd   # writes PNGs to user://
python3 tools/make_placeholders.py                        # regenerate the placeholder plates
```

`tests/playthrough.gd` is the port of the Ren'Py `tools/simulate.py`, which existed only
because there was no SDK to lint with. Here there is an engine, so the "interpreter" is the
game: every label entered, every line rendered. The five routes land on the same numbers the
Ren'Py fork reported, which is the strongest evidence the writing came across intact:

```
  mercy      ending=collateral  lines=393  net=242  cgs=[collateral finial market ring veil]
  ruthless   ending=solvent     lines=278  net=324  cgs=[collateral]
  honest     ending=collateral  lines=391  net=290  fees paid+refunded=55
  factor     ending=factor      lines=381  net=414  sold=veil
  demo       ending=DEMO        stops at the chapter-2 gate, two appraisals in
  free-web   ending=collateral  lines=393  net=242  fees refunded=55
```

The mercy net moved from 187 to 242 and it is not a rules change: `cg_ring` and `cg_veil`
have no art yet, so the refund rule hands those two fees back on **every** track, paid
included. That is the rule working. When the two plates land the numbers walk back down on
their own, which is why `tests/playthrough.gd` now asserts
`fees_paid + fees_refunded == 55` rather than a number that depends on which PNGs are in
the checkout on the day.

## What is waiting on art, and what happens while it waits

Nine of the thirteen slots hold real renders. The four that do not — `cg_tamsin`,
`cg_ring`, `cg_veil`, `cg_veil_locked` — **have no file at all**, and that is deliberate.
They used to hold PIL placeholder cards, which is how a file-size survey came to report
every one of the six forks as fully illustrated when none of them had a single real plate
(`ops/adult_forks/STATUS.md`). A placeholder that a survey counts is worse than an absence.

So the plate layer degrades instead, permanently, in three steps
(`scripts/plates.gd::pick`):

1. the uncensored plate, if this package has it or the gateway delivered it;
2. the `_locked` censored stand-in;
3. **the pixel floor** — the item's curio sprite at 4x over the darkened shop, built in
   code out of `assets/pixel/`, captioned *"The object goes quiet in her hand."*

Step 3 cannot fail, because there is no file to be missing: it is drawn. A slot with no
art is never a broken texture, never a black rectangle, and never an empty frame, and a
floored slot is not written into the Reading Ledger as seen — the player did not see it.
`tests/plates.gd` walks every slot in the table and asserts all three steps.

`cg_veil` and `cg_veil_locked` are blocked on a Mara reference only Blaze can pick, so this
is not a state that clears on its own.

`ops/midnight_pawn_art/midnight_pawn_gen.py` now covers all of it: the six plates (including
`cg_finial`, which the gating counted and the art list never had a prompt for) and one
censored stand-in per **gated** slot. The stand-in previously called `cg_tamsin_locked` was
wrong twice over — `cg_tamsin` is ungated on every track and needs no stand-in, and the
composition described is the finial's — so it is now `cg_finial_locked`, and `cg_ring_locked`
and `cg_market_locked` have been added.

**`cg_collateral` must not be the store thumbnail.** It is Nara topless at her own counter at
night, and it crops down into something that looks exactly like Room 704's key art — the
overlap this whole fork was designed to avoid. Use `cg_veil` or `cg_market` for the itch
thumbnail and the forum OPs. The warning is now also a comment above the prompt itself.

## Did the psychometry frame keep it off Room 704?

Reviewed again after the port, because `scripts/story.gd` is the file that could break it.

- **Five clients, each named, each seen once.** Tamsin Reed, Ivo Glass, Mara Voss, Calder,
  and Nara herself. No one recurs.
- **Every vision is somewhere else, some other time, someone else's.** The observer is fixed
  four feet up and behind, cannot speak, touch or intervene, and readings carry no sound —
  stated in the text three times.
- **Nara is in one erotic scene, the last**, alone, looking at her own reflection.
- **The player act is a price, not an intimacy.** LOW/FAIR/HIGH and whether to look. There
  is no affection term anywhere in `ending_of()`.
- **Room 704's opening beat is inverted on purpose.** Its woman pushes cash across a counter
  to stay out of the book. Here the clients are desperate to be *in* the book — that is what
  a pawn ticket is — and the person who ends up written into it is the broker.

## What did not come across

One line. `08_reading.rpy`'s generic `reading_offer` menu had two decline lines, and that
menu was **unreachable in the Ren'Py build too**: the finial's fee is 0 so it went straight
to `reading_take`, and the ring and veil scenes ask in their own voice and call
`reading_take` directly. Nara's half of it — *"Some nights you want the whole story. Some
nights the story is a cost."* — has been given a real home in the finial's blind-pricing
branch. The narration line that went with it duplicated a sentence already in that branch
and was dropped.

Not carried across, and deliberately: the Ren'Py telemetry wrappers (`tel_track`). The
page carries the telemetry SDK (`ops/godot_build.sh` injects it) but no GDScript call site
posts an event, so this title reports nothing to the closed loop yet. That is the next job.

The ad track and the cross-promo screen *are* wired now — see below.

## The reveal, which was never connected

`scripts/unlock.gd` shipped with this project from the port, with a `start()` and a
`redeem()` that **nothing in the game ever called**. A browser player who cleared a gate
got the censored plate every time; the fork's entire paid proposition was unreachable code.
Two further faults were underneath it, and both only show up if you actually fetch:

1. **The gateway serves webp; the client wrote png.** `gateway/app.py:309` returns
   `image/webp`, and Godot picks its decoder from the file extension. The delivered bytes
   landed at `user://unlocked/<id>.png`, cleared the 1024-byte "it arrived" test, suppressed
   the refund, and could not be decoded by anything. The extension now comes from the
   bytes, and a body that is not an image at all (a JSON error page) is refused rather than
   stored.
2. **The refund was decided before the fetch.** `reading_take()` asked
   `Collateral.delivered()` while building the beat list — before the plate beat, therefore
   before any ticket existed. It emits a `settle` beat instead, and `game.gd` resolves it
   after the fetch has happened or failed.

The order is: `/unlock/start` for the ticket (so the server's clock starts with the gate,
not with the redeem), then `Gate.require()` hands the page its gate — the sponsor clip on
the ad track, whose length is the gateway's 18-second wait — then `/unlock/fetch` spends the
ticket. Off the web, `start()` returns false before making any request: a desktop download
still asks the network for nothing.

`tests/unlock_live.gd` runs that against the **live gateway**, through the shipping client:

```
$GODOT --headless -s res://tests/unlock_live.gd
  ticket issued for midnight-pawn-collateral/cg_finial
  immediate redeem refused          # 425, the wait is real
  delivered cg_finial.webp  1152x768
  plate layer resolves cg_finial uncensored
  ticket reuse refused              # 403, single-use
UNLOCK_LIVE_OK
```

It was made to fail first: restoring the `.png` extension turns the delivery into
`ERR_FILE_CORRUPT`, which is exactly what the shipped build was doing silently.

Only `cg_finial`, `cg_market` and `cg_collateral` are staged on the gateway, because
`ops/export_gated.py` stages picks and the other two slots have none. Asking for an
unstaged key returns 404 at `/unlock/start`, `start()` returns false, no gate is shown, and
the fee is refunded — the same path as an offline player.

## The 2026-09-18 visual re-do

Blaze's note: *一个完全不同于普通版本的、比较惊艳的像素风格的 NSFW 游戏 — 一看就是成人的感觉，
但非常 stylish、有品味，不是那种偏低龄的普通版本游戏.* Two things have to be true at once —
unmistakably adult, and stylish — and there are two ditches either side of the road: the
8-bit nostalgia look (the palette-starved NES thing that says the hardware could not do
better) and the cheap-porn look. The target is boutique: Katana Zero, Eastward, Sea of
Stars sprite craft, pointed at an adult title. The market reference is DLsite, where the
top two adult action games by a wide margin are both pixel art — pixel sells there, cheap
pixel does not.

What changed, in order of how much it matters:

**1. The stage is the canvas.** It was a 300x240 picture in a panel with a form beside it;
it is now the whole 640x360 frame, drawn 1:1 and integer-scaled 2x to the window, with the
words in a translucent ink slab across the bottom. Nothing is resampled — the grid is
exactly as honest as it was — there is 2.9x more of it, and the game stops looking like a
spreadsheet with art stapled on. The action buttons and the footer moved *inside* the slab,
which is worth about sixty rows of room.

**2. One fixed palette**, `ops/palettes/midnight-pawn.json`, 64 colours, built by
`ops/palettes/build_midnight_pawn.py` out of the title's own light — oil-lamp amber,
violet-black ink, cold blue night — plus ramps for the things the game is made of (wood and
brass, skin, ossuary teal, mourning violet, warm stone). Every asset quantises onto it, so
the rooms and the cast agree about what black is. Before this, each image ran its own
median-cut and the colours drifted between scenes.

**3. Rooms rendered high and converted down** (`ops/pixelize.py`, driven by
`ops/midnight_pawn_art/build_pixel_assets.py`). The candidate that becomes each asset is
recorded in `pixel_picks.json`, with the vertical crop anchor, so a rebuild is reproducible.

**4. 72x108 actors**, from mid-thigh up, on a 576x540 sheet. The old sheet was 32x48, which
is a ten-pixel head, which is no face at all.

**5. Animation by layered deformation** rather than by frames — see below.

### The three prompt failures this pass went through, so nobody re-derives them

Each one is recorded in `ops/midnight_pawn_art/midnight_pawn_gen.py` next to the code it
broke, and all three were found by looking at a contact sheet, not by a check passing:

- **Rooms, first try:** the fix for the 320px noise trial was written as `minimalist, flat
  color, limited palette, bold shapes` and produced four flat vector posters — a bank's
  landing page, no lamp, no depth. The real finding from the trial was narrower: the
  painting was right and the *prop count* was wrong. `SIMPLE` now constrains density only,
  and the negatives ban the vector ditch as hard as the cluttered one.
- **Dawn:** asking for a counter and a window without the shop's own furniture got three
  modern lobbies and a chapel. With the lamp out of the prompt nothing left in it said
  *this room*. Dawn is now the shop's tags with the light changed.
- **Sprites, twice:** the first pass inherited `NEG_REF`, which bans `full body` — while
  the positive prompt asked for `(full body:1.4)`. Four renders of white fog with a face
  suggested in it. The second pass fixed that and still fogged, because the bespoke
  `SPRITE_STYLE` had piled up `soft even lighting, no harsh shadows, flat color, chroma
  key, green background:1.5` into a prompt with no contrast left to draw. What works is
  `STYLE_CHAR` — the same block the reference portraits use, which was known good — plus
  three tags. A negative list is not reusable furniture; it belongs to the shot.

### Does it move?

Yes, and none of it is a second frame of authored art.

`scripts/pixel_stage.gd` draws each actor as four horizontal bands of one sprite, offset
by whole pixels on sines of different periods: hair drags behind the torso, the chest rises
and falls, the hips take half the chest's offset so the body bends instead of hopping, the
hem sways out of phase. Two clients in a room run on different phases so they are not one
metronome. Around them the lamp breathes on two periods (1.7s and 0.43s, so the flicker
never settles into a beat you can count), rain falls down the window in 1x5 streaks, and
dust drifts up through the lamp cone one pixel at a time.

`scripts/plates.gd` does the same idea in UV: the plate wavers by whole canvas pixels —
`floor()`ed, so a painted vision never blurs — the amber multiply flickers on the room's
own beat, and one soft band travels up the frame every eleven seconds, which is the element
that makes a plate read as *a reading happening now* rather than as a CG.

`tests/motion.gd` captures eight frames spaced in real time, writes a filmstrip to
`user://motion/`, and **fails if nothing moved**. A one-pixel breath and a 5% flicker are
precisely the things a typo can switch off while every other test still passes.

Honestly, in motion: the room reads as alive — the lamp and the dust do most of that work,
and the rain is the part you notice last. The actor deformation reads as breathing at the
counter, and it does *not* read as walking or gesturing; it is presence, not performance.
The plate's waver and read-band read as a vision. What is still missing is any authored
second frame — a blink, a hand moving to the object — and that is the next thing worth
buying, not more shader.

## Hosting: why this is not on free.blazecore.dev

The four mainstream Godot titles are proxied there by
`ops/pages/flat404-play.worker.js`. This one is adult, and `play/_shared/board.js` treats
every `*.blazecore.dev` host as the AdSense candidate domain and forces `BOARD_ADULT_OK = 0`
— a veto a page cannot lift. Run against board.js directly:

```
midnight-pawn-collateral.flat404.workers.dev -> BOARD_ADULT_OK = 1, fetches catalog-adult.json
free.blazecore.dev                           -> BOARD_ADULT_OK = 0, fetches catalog.json
```

So on free.blazecore.dev the end-of-run board this build is required to offer would have
drawn nothing, silently — and an 18+ title would be sitting on the one domain
`ops/check_adsense_isolation.py` exists to keep clean. The build still lives exactly where
the Godot ad builds live (`build/godot-ads/<slug>`, served by the gateway as
`/free-<slug>/`); only the public hostname differs, and it is the same
`*.flat404.workers.dev` the other adult titles already use.

**Live: https://midnight-pawn-collateral.flat404.workers.dev**

# Midnight Pawn: Collateral

The adult (18+) fork of *Midnight Pawn & Crypt* (Flat 404), built to
[`ops/adult_forks/midnight-pawn.md`](../../ops/adult_forks/midnight-pawn.md). Everything
except the art is here. **Nothing has been rendered** — the plates in `game/images/` are PIL
placeholders that print their own slot name and unlock condition.

Nara Quill appraises by touch: a hand on an object shows you its last use. Five clients, five
objects, one descent into the Ossuary Market, three endings. ~9,300 words, five choice
clusters, deterministic integer economy.

## Where the source came from

The Godot source **does** exist — `~/midnight-pawn-src` on Blaze Ubuntu
(`bfs@100.121.195.19`), 50 MB, Godot 4.7, reachable over Tailscale. The design doc predates
that being found and assumed it was gone.

It was read for canon and then not forked. The reasons, in order:

1. `scripts/gate.gd` is 71 lines and has never shipped a fork. `play/room-704/game/scripts/09_dist.rpy`
   is 564 lines, has shipped twice, and is what the brief asks the CGs to be gated through.
2. The brief specifies `GATED_CGS` / `cg_pick` / `cg_gate`, which are Ren'Py names.
3. The base game is a pixel-art dungeon crawler with combat. The fork keeps one of its four
   crypt rooms and none of its combat; it is a different game that shares a shop.

What the source *did* give, and what is now canon in the fork: the deterministic integer
economy, the Black Ledger being **owned by Nara Quill with the due date tomorrow** (verbatim
out of `game_state.gd`'s `CURIO_DEFS`), the Heart of the Crypt, the Ossuary Market as a real
room, and the shape of the LOW/FAIR/HIGH pricing verb.

One divergence worth knowing: the base game's day-2 customers are **Tamsin Reed** (a veteran)
and **Ivo Glass** (an occultist), and its widow is **Mara Voss**. The design doc invented
Tamsin Bell, Ivo Lask and Widow Merrow before the source was found, and the art pipeline in
`ops/midnight_pawn_art/midnight_pawn_gen.py` is built around those characters. The fork uses
the doc's cast. If continuity with the SFW game matters more than the art bible, the surnames
are a one-line change in `00_init.rpy`; the given names already match.

## Layout

| file | what it is |
|---|---|
| `game/python-packages/collateral_core.py` | **the rules**: item values, reading fees, CG unlock conditions, ending resolution. Pure Python, no Ren'Py, so it can be tested directly. |
| `game/scripts/00_init.rpy` | cast, art declarations, state, business rules |
| `game/scripts/01_shop.rpy` | cold open + Appraisal 1 (Tamsin, the finial) |
| `game/scripts/02_ring.rpy` | Appraisal 2 (Ivo, the ring) + the interlude |
| `game/scripts/03_veil.rpy` | Appraisal 3 (Widow Merrow, the veil) |
| `game/scripts/04_market.rpy` | the descent — the Receipt Stair and the Ossuary Market |
| `game/scripts/05_collateral.rpy` | Appraisal 5 (the Black Ledger) |
| `game/scripts/06_dawn.rpy` | three endings |
| `game/scripts/07_paywall.rpy` | the itch web track's cut point |
| `game/scripts/08_reading.rpy` | **the reading gate** and the Reading Ledger screen |
| `game/scripts/09_dist.rpy` | dual-track distribution, copied from room-704 |

## The six CGs, and what earns each

No CG unlocks from playtime. Every condition is a pure function of run state, they all live
in one table (`collateral_core.cg_conditions`), and `tools/playthrough.py` asserts it.

| slot | gated | earned when |
|---|---|---|
| `cg_tamsin` | no | read the finial **and** priced it FAIR |
| `cg_finial` | yes | read the finial **and** priced it HIGH — the same vision, further in |
| `cg_ring` | yes | took the ring's reading **after Ivo asked you not to** |
| `cg_veil` | yes | read the veil **and** offered Merrow more than it is worth |
| `cg_market` | yes | carried ≥ 2 client readings down to Calder |
| `cg_collateral` | yes | the last appraisal — unrefusable, no condition |

`GATED_CGS = ("finial", "ring", "veil", "market", "collateral")`, exactly as the design's §4
first bullet specifies, with `cg_tamsin` ungated on every track.

`cg_tamsin` and `cg_finial` are mutually exclusive in a single run (FAIR vs HIGH). That is
deliberate — the ledger is per-save and completion takes more than one night — but it means a
single playthrough tops out at five of six.

## The reading gate, and the second-paywall problem

The design names this the riskiest mechanic: asking for in-fiction currency for a CG can read
as a second paywall stacked on the real one. Five things were done about it.

1. **The fee is refunded when the art does not arrive.** `reading_delivered()` asks whether
   the uncensored plate actually landed. A free-track player who pays the shop fee and then
   declines the distribution gate gets the money back, in-fiction, with two lines of dialogue
   that say so. Charging shop cash for a silhouette is what the failure actually feels like,
   and it is now impossible. Verified: simulator route 5 ends `fees paid=0 refunded=55`.
2. **Nobody is asked for the same money twice.** The simulator caught the first draft doing
   exactly that — the scene menu said "take the reading anyway (35 out of the till)" and then
   `reading_offer` asked for the fee again on the next screen. A fee prompt after the player
   has already said yes is the precise texture of a nag paywall. `reading_take` was split out;
   scenes that ask in their own voice call it directly.
3. **The two vocabularies never mix.** The fee menu is the shop's own voice and never mentions
   money that is not shop money. `07_paywall.rpy` and `cg_buy_screen` are the only things in
   the game that print a dollar sign, and there is no path from the fee menu to a purchase.
   Shop cash is not convertible and is never offered for sale.
4. **Every fee is affordable on an honest run.** Price everything FAIR and you can pay all
   three optional fees and still clear the debt with 35 to spare. `tools/playthrough.py`
   check 1 asserts it, so it cannot drift.
5. **The Reading Ledger is shown before the final appraisal**, greyed slots visible, while
   there is still an appraisal left. Refusal is a decision made, not an accident discovered.

The tension the design asks for is intact and measured: the mercy route ends on
**net 187 against a debt of 200** with five CGs; the ruthless route ends on **net 324** with
one. Kind and broke, or rich and blind.

## Verification

**Run in the real engine.** A Ren'Py 8.3.7 SDK is on this machine — under another session's
scratchpad in `/tmp`, which is why a first, depth-limited search missed it, and which means
the path is not stable; find it with `find /tmp/claude-1000 -name renpy.sh`.

```
export DISPLAY=:0 SDL_AUDIODRIVER=dummy RENPY_PERFORMANCE_TEST=0
"$SDK/renpy.sh" /home/frankstone/Products/play/midnight-pawn-collateral lint
```

`lint` is clean — the only remaining warning is `10_i18n.rpy:29 init priority (1500)`, which
is inherited verbatim from room-704 and present there too. Lint counts **512 dialogue blocks,
9,087 words**, independently confirming the design's 9,000–11,000 band.

The game was then played to completion in the engine, twice, with an auto-pilot injected into
a throwaway copy (patching `renpy.exports.menu`/`say`/`call_screen` and overriding
`label main_menu` so it starts itself; the window needs a real display — SDL's `dummy` and
`offscreen` drivers both fail the GL setup, and there is no Xvfb):

- **paid track** — 417 lines, every choice, ending **Collateral**, till 90 / net 187 against a
  debt of 200, and **five CGs unlocked and written to the persistent gallery**. Numbers match
  `tools/simulate.py` route 1 exactly.
- **demo track** (`game/dist.txt` = `demo`) — `chapter_gate` fires, the story reaches
  `demo_paywall_screen`, and **the refund fires in the engine**: `fees paid=0 refunded=35`,
  with the in-fiction lines printed. No exceptions.

**This found a real shipping bug.** `09_dist.rpy:376` still referenced `route`, room-704's
branch variable, which does not exist here — so `chapter_gate` raised `NameError` and *every
non-paid track died at appraisal 3*, the first gate any free player reaches. The static pass
had missed it because `ast.parse()` is perfectly happy with an undefined name.
`tools/check_rpy.py` now resolves names against everything the project defines, and re-adding
the bug makes it fail, so it cannot come back.

Three fast harnesses also pass, and are the loop to use while writing:

```
python3 tools/check_rpy.py     # static: labels, images, python blocks, GATED_CGS, plate files
python3 tools/playthrough.py   # the rules module: endings, CG conditions, affordability, refund
python3 tools/simulate.py      # executes the actual .rpy story files through 5 routes
python3 tools/simulate.py --transcript 2      # print a full playthrough's text
python3 tools/make_placeholders.py            # regenerate the placeholder plates
```

`tools/simulate.py` is a small interpreter for the Ren'Py subset the story uses
(label/jump/call/return/menu with conditional options/if-elif-else/`$`/`python:`/say). It
reads the real files off disk, runs in a second, and needs no display. It found two crash bugs
a static pass missed, before the engine ever saw them: a multi-line `$` statement (illegal in
Ren'Py) and the double fee prompt above.

## What is waiting on art

Everything visual. `ops/midnight_pawn_art/midnight_pawn_gen.py` was not modified.

- The eleven slots that script already covers: `cg_tamsin`, `cg_ring`, `cg_veil`, `cg_market`,
  `cg_collateral`, the three `*_locked` plates, `bg_shop`, `bg_market`, plus the four cast refs.
- **One gap: `cg_finial` has no prompt in the generator.** The design's §4 gates five CGs by
  name (`finial`, `ring`, `veil`, `market`, `collateral`) and calls it "six CGs, five of them
  gated", but §3 and the art list only describe five plates in total. `cg_finial` is the sixth
  the count requires — the same Tamsin vision, further in, earned by overpaying her. It needs
  one entry added to `PLATES`, which is the art owner's call, not this session's.
- The gated slots also need `cg_<name>_x.webp` in the paid package: `cg_pick()` looks for that
  exact filename and silently falls back to the censored plate without it. The placeholder
  script writes them so the failure is visible now rather than after a build.

Also not built (out of scope here): store copy, the LewdCorner/ULMF OPs, and the web build
(`ops/renpy_web_build.sh` with `APP=collateral DIST_VAR=COLLATERAL_DIST ADS_JS=collateral_ads.js`).

## Did the psychometry frame keep it off Room 704?

Reviewed against the table in the design's §1, which asks for the draft to be killed if it
drifted back. It did not.

- **Five clients, each named, each seen once.** Tamsin Bell, Ivo Lask, Widow Merrow, Calder,
  and Nara herself. No one recurs.
- **Nara is not in any erotic scene except the last**, and in that one she is looking at her
  own reflection with no second person present. Nobody seduces anybody across the counter.
- **Every vision is somewhere else, some other time, someone else's.** Tamsin's flat on a
  morning months ago; Ivo's ring on a nightstand in another city; Merrow's mirror the night
  before a funeral; two strangers in a plate Calder bought off a different broker. The
  observer is fixed four feet up and behind, and cannot speak, touch or intervene — stated in
  the text three times.
- **The player act is a price, not an intimacy.** The choices are LOW/FAIR/HIGH and whether to
  look; there is no affection meter and no romance term anywhere in `ending_of()`.
- **Room 704's opening beat is inverted on purpose.** Its woman pushes cash across a counter
  to stay out of the book. Here the clients are *desperate to be in the book* — that is what a
  pawn ticket is — and the person who ends up written into it is the broker.

One thing to watch at art time: `cg_collateral` is Nara, topless, at her own counter at night.
That is the single frame that could be cropped into something that looks exactly like Room
704's key art. It should not be the store thumbnail; `cg_veil` or `cg_market` should be.

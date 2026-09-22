# VESPER — the adult fork of Flutter (Flat 404)

18+ otome VN. **Six routes**, five chapters each, three endings each, eighteen event CGs.
It is a *derivative* of `play/flutter/`, not a second game: every chapter, beat, trigger,
choice, flag, affection value and ending is the parent's, copied through unchanged.
Design: [`ops/adult_forks/flutter.md`](../../ops/adult_forks/flutter.md). House art rule:
[`ops/adult_forks/ART_DIRECTION.md`](../../ops/adult_forks/ART_DIRECTION.md).

Everyone depicted is an adult, is stated as one in-scene, and is written as one.
Consensual only; no minors, no violence, no non-consent.

`play/flutter/` is untouched. This directory is a fork, not a branch of it: the
heavy shared assets (`portraits/`, `audio/`, `openings/`) are symlinks back into
the parent so the fork costs a few hundred KB rather than 219 MB.

## What is different from the parent

| | parent (`play/flutter`) | this fork |
|---|---|---|
| dialogue | a live Qwen call per turn (`_chat`, GPU) | authored prose, looked up (`static_story.py`) |
| stories | `backend/stories/` | `backend/stories_x/` — the same files, derived: same schema plus the added fields |
| judge pass | LLM grades the chapter goal | disabled; exit = affection + the chapter-end choice |
| branching | stage + persona prompts | the same, plus **attachment lanes** in the prose itself |
| CGs | none (text rewards only) | nine, each earned by game state |
| price / gate | $2.99, directLink ad | $8.99, **no directLink** (see `f95-ban-direct-link-ads`) |

A static route never calls a model, never claims the GPU, and works offline —
which is the point: per-player GPU time on erotic generation is a cost and a
liability, and a downloaded build cannot do it at all.

## The spine — derived, not written

`backend/stories_x/*.json` is **generated** by `tools/derive_from_parent.py` from
`play/flutter/backend/stories/*.json`. Do not hand-edit the output; edit the
deriver and re-run it. The deriver refuses to write if a single parent string
failed to survive into the fork.

Routes: `ethan, luxingye, guyan, liam, adrian, fushen` — the six the parent has at
full length (5 chapters, 12 beats, 3 endings each). `ren`, `mateo` and `caio` are
left out: they are the parent's short language-pack routes (3 chapters, 6 beats, 2
endings, written in ja/es/pt), so there is not enough parent content to derive from
and they would need the thing this fork exists to avoid — new writing.

What the derivation adds, and nothing else:

| addition | size |
|---|---|
| `beat.text_en` — his spoken line, written once from the parent's own `inject` stage direction (the parent had a model say this; a static route cannot) | 72 lines |
| `beat.lane{}` — an authored attachment-lane opener in front of the **kept** base line, on the last parent beat of each chapter | 12 openers → 60 variants |
| the adult turn — 2 new beats per route, in ch4 and ch5, where the parent's own beats already build to it | 12 beats |
| an explicit decline on each escalation chapter, `flag: slow_ch4/slow_ch5`, `aff: +3` | 12 options |
| `hold_en[]`, `cast_note_en` + an in-scene age line on ch1, `cg_heat` / `chapter.cg` / `ending.cg`, one adult coda sentence per ending | small |
| English for ethan's choice replies, which the parent left `reply_zh`-only | 15 lines |

Measured the way the correction measured the first attempt:

    parent beats 72  ->  fork beats 84   (+12, all of them the adult turn)
    477 / 477 parent strings present verbatim in the fork
    9,839 words kept from the parent   5,560 words newly written

The previous from-scratch build was 35 beats per route with **zero** text overlap
and ~14k words per route still owed. This one owes nothing.

Content pack is English (`*_en`) only; `_field()` falls back to `_en`, so a zh/ja
pack is additive — and for the five zh-origin routes the parent already ships
`*_zh` on every kept string, so that pack is mostly a matter of deriving it.

## The CG hooks — nothing unlocks from playtime

| # | earned by | server | client |
|---|---|---|---|
| 1 | clearing a chapter that has a `cg` (ch2 on every route) | `/choose` → `chapter_clear.reward.cg` | `showChapterClear()` |
| 2 | affection **crossing** 60 | `/say` and `/choose` → `cg` | `showCgMoment()` |
| 3 | the ending you matched | `/choose` → `ending.cg` | `showEnding()` |

Both entry points matter for #2: a chapter-end choice carries its own affection
delta, and on two of three routes the first playthrough crossed 60 *there* rather
than in a chat turn. Watching only `/say` loses the plate silently. The parent's
`new_aff in (10,30,60,100)` test has the same hole — a +5 turn jumps the mark —
so the fork tests the crossing instead.

Unlocking reuses the Gate that is already live for chapters
(`Gate.require("cg:"+slot)`), so the paid and ad tracks stay comparable with no
new telemetry.

## Placeholder art

`tools/gen_placeholder_cg.py` writes 18 covered plates, 18 thumbnails and 18
"uncensored" stand-ins with PIL — **no GPU, no renders**. The real plates come from
`ops/flutter_art/flutter_gen.py`. Layout is the shipping rule:

    frontend/cg/<slot>_locked.webp    covered — every build
    frontend/cg/<slot>_thumb.webp     gallery thumbnail
    frontend/cg/full/<slot>.webp      uncensored — PAID PACKAGE ONLY

`tools/build_free.sh` builds the free package and **fails** if anything from
`cg/full/` reaches it.

## Run it

`python3` on this box has no uvicorn; the interpreter that does is the conda env
every other backend service here uses.

    PY=~/miniconda3/envs/hsm_lcr/bin/python
    $PY tools/derive_from_parent.py --report               # rebuild stories_x
    $PY tests/test_static_story.py                         # 18 offline tests
    systemctl --user status flutter-after-hours            # the service, :8931
    $PY tests/http_playthrough.py --route ethan --lane anxious --pick 1
    $PY tests/http_playthrough.py --base https://apps.blazecore.dev/flutter-after-hours \
        --route guyan                                      # play the DEPLOYED backend

In production the backend runs as `flutter-after-hours.service` on :8931 and the
gateway proxies `/flutter-after-hours/*` to it — **API only**: the gateway will
not serve this game's pages, because apps.blazecore.dev is the AdSense candidate
domain and an 18+ page does not belong on it (`API_ONLY` in `gateway/app.py`).
The page is served from Cloudflare instead.

Locally the frontend needs `/flutter-after-hours/*` proxied to :8931 and
`/unlock/*` proxied to apps.blazecore.dev. Any small dev proxy does, but it must
send a browser User-Agent: Cloudflare 403s the default `Python-urllib` one
(error 1010), and that failure looks exactly like a broken unlock endpoint.

## Build and deploy

    tools/build_free.sh [outdir] [itch_web|ads_web]

`ads_web` stamps `window.DIST` and copies the **adult** Adsterra unit. Both are
load-bearing: `gate.js` only auto-detects `*.pages.dev`, so an unstamped build on
workers.dev shows the $8.99 buy paywall where the free track should be, and the
mainstream ad unit is both domain-locked to free.blazecore.dev and a policy
violation on an 18+ page. The script fails the build on either mistake, and on a
`directLink:` in an adult package.

    tools/build_free.sh $PWD/dist/ads ads_web
    rsync -a --delete dist/ads/ ../../build/pages/flutter-after-hours/
    ops/pages_deploy.sh flutter-after-hours

Live: **https://flutter-after-hours.flat404.workers.dev**

## Voice barks

`ops/barks/lines.json` carries a `flutter-after-hours` set: 21 lines across the
nine slots STANDARD.md names, on seed `f_low_controlled` — **not** the parent's
`f_young_warm`. One voice per game, and an adult fork does not share its parent's:
the all-ages read is "warm and bright, young, gently amused" and this one is the
same woman lower and closer.

`ops/bark_wire.py` could not be used — it appends a GDScript layer to a Godot
`Sfx` autoload and this game is the web PWA — so `frontend/barks.js` re-states its
three rules in JS (rotate without repeating; never overlap, drop the second; ride
the player's own mute switch) and the triggers hang off moments `index.html`
already fires: `startRoute` → greet, a tier crossing → stage, `heartGain` → win /
fail / streak, `showChapterClear` → unlock, `showEnding` → win_big, and a 40-second
clock for idle, which is the one slot with no event of its own.

**The audio is not rendered yet.** `render_barks.py --only flutter-after-hours`
wants the local card, and the two Flutter llama-servers hold 9.4 of its 12 GB, so
it would fall back to CPU across every core of Blaze's desktop — the thing
STANDARD.md's last section exists to prevent. `barks.js` fetches
`voice/barks.json` and stays silent when it is absent, so the build ships correct
and lights up the moment the render lands. No manifest is checked in ahead of the
audio on purpose: that would report "wired" while every `play()` 404s.

## Known gaps

- **The adult turn fades at the door.** The two added beats per route establish
  consent explicitly, name both adults, and then close the scene. If the channel
  turns out to want the explicit version, it is two beats per route to extend —
  which is the point of deriving rather than authoring.
- ~~**The server-gated CG fetch is a stub.**~~ **Wired and verified 2026-09-18.**
  `cg.js` now does the Room 704 ticket flow against the gateway root
  (`/unlock/start` + `/unlock/fetch`, app `flutter-after-hours`), with the bytes
  staged in `ops/gated_assets/flutter-after-hours/`. Verified against the live
  gateway rather than read off the source: 425 before the 18-second minimum,
  then 200 with ~59-91 KB of real WEBP, then 403 on any reuse of the ticket.
  Three things that flow needs which reading the code would not give you: the
  ticket is taken **when the sponsor clip starts**, so its 18 seconds run under
  the 30 the player is already watching instead of after them; the bytes are
  cached as an object URL, because the ticket is single-use and a re-opened plate
  must never ask again; and every failure degrades to the covered plate.
- ~~**Only three of the six routes are offered.**~~ **All six, 2026-09-21.** The
  nine adrian/liam/fushen plates were rendered, judged by eye at native
  resolution, picked and installed (`ops/flutter_art/out/plates/JUDGED.md` has the
  per-slot verdicts), and `chars.json` now has every route at `art: "installed"`.
  `/routes` returns 6 in en and 4 in zh.

  Two things that came out of doing it, both worse than the thing it fixed:

  **`cg_ethan_heat` was fog.** Not one of the nine — already picked, already
  installed, already on the gateway, on a route the game was already OFFERING,
  behind the affection-60 gate. A pink and blue smear with a face suggested in it:
  4,833 distinct colours in a 1024x576 frame, fewer than the placeholder card it
  replaced. `check_shelf_floor` had been saying "flat, spread 0.07" the whole time.
  Re-rendered and replaced.

  **The covered plates were debug assets.** `tools/gen_placeholder_cg.py` builds
  the locked plate and the gallery thumb out of the same PIL card as the full
  plate, which was right before any art existed — but once real renders land in
  `cg/full/` nothing regenerates the covers, so fifteen of eighteen `_locked.webp`
  in the tree were 5-7 KB grey cards reading "not final art", including all nine
  slots of the three routes that were live. That is what every player saw the
  moment the gallery opened. `tools/cover_plates.py` now builds the cover from the
  installed plate (blur + band), skipping the three slots that have their own
  separately rendered `_locked` teaser, and `--check` fails if a cover is stale.

- **Every CG is under its bucket's saturation floor.** Measured across all
  eighteen: brightness is fine or high (0.61-0.88), saturation is 0.14-0.31
  against a 0.41 floor for slice-of-life. Bright but bleached, which is
  `bright-is-what-sells` read backwards. Weighting the colour in `STYLE_X` was
  tested at n=3 on four slots and is **not** the general fix: it rescued
  `cg_ethan_heat` outright and got `cg_fushen_heat` to 0.80/0.42 (the only plate
  in the set that clears), did nothing for `cg_guyan_heat`, and made
  `cg_luxingye_end` worse (0.95/0.15, spread 0.07 — a whiteout). It tracks the
  slot, not the style block, which points at the IP-Adapter reference. Needs an
  art call, not more re-rolls.
- ~~**English only.**~~ **en + zh, 2026-09-21.** The Chinese hole was never the
  UI strings or the palette — both were inherited from the parent — it was that
  every one of the fork's OWN additions (`beat.text`, the adult turn, the lane
  openers, the holds, the declines, the cast note, the coda) had been written in
  English only. `_field()` falls back to `_en`, so a Chinese player would have met
  an English paragraph at every beat while the game looked fine.
  `tools/derive_zh.py` is that missing pack, authored in Chinese rather than
  machine-translated, and the deriver emits it. Measured after re-deriving:
  ethan/guyan/luxingye/fushen are 100% real Chinese on every localized field.

  **liam and adrian are NOT offered in zh, and that is the parent's fault, not an
  oversight.** Their `_zh` fields in `play/flutter` hold ENGLISH — liam's
  `title_zh` is the literal string "the firefighter next door", and 25 of its 123
  localized fields contain no CJK at all. Offering them would be Floor 13's
  ja/ko/es failure with the languages swapped, so `chars.json` gates zh to the
  four routes whose base prose is genuinely Chinese. **The parent needs repairing
  before those two can join** — that is a `play/flutter` job.

  `ops/check_flutter_languages.py --game flutter-after-hours` now covers this
  game, and it was taught to READ a field rather than only count it: a `_zh` key
  holding English used to pass, which is exactly how liam and adrian got this far.
  Proved by making it fail — adding liam to the zh list reports 62 wrong-script
  fields and exits 1.
- **No ad unit of its own.** The build ships the shared adult Adsterra unit
  (Elena / Room 704 / Confession Room). Adsterra units are domain-locked, so this
  needs its own approved entry for `flutter-after-hours.flat404.workers.dev`
  before the ad track earns anything — the banner does render there today.
- **Channel risk, which is still the biggest thing here and is unchanged.** This
  is otome, and the channel for it is DLsite 女性向け, which is not validated:
  no submission has gone through it, and the ratio work that picked LewdCorner
  and ULMF for the other forks does not transfer — those are male-audience
  boards. See `ops/adult_forks/flutter.md` §1. What the derivation changes is the
  size of the bet, not the risk: the writing owed dropped from ~42k words to
  zero, so the fork is now cheap enough to hold finished while the channel is
  tested, instead of being a reason to spend 55 hours ahead of the answer.

# Flutter: After Hours — the adult fork of Flutter (Flat 404)

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
- **Only three of the six routes are offered.** All six derive and play to an
  ending, but `ops/flutter_art/picks.json` holds 12 picks — ethan, luxingye and
  guyan. fushen, liam and adrian still have the PIL stand-ins from
  `tools/gen_placeholder_cg.py` in all three of their slots, so they are held
  back by `art: "placeholder"` in `chars.json`; `FLUTTER_SHOW_UNFINISHED=1` shows
  them for art QA. Flip the tag when the plates land; nothing else changes.
- **English only.** The picker used to offer zh/ja/es/pt and every one of them
  returned an empty route list from `/routes` — a dead end with no way back.
  `editions.js` now clamps to what the content pack has. The zh pack is mostly a
  matter of deriving the parent's `*_zh`, which is already written.
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

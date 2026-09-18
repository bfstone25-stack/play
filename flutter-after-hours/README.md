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

    python3 tools/derive_from_parent.py --report             # rebuild stories_x
    python3 -m uvicorn backend.app:app --port 8931           # from this directory
    python3 tests/test_static_story.py                       # 18 offline tests
    python3 tests/http_playthrough.py --route ethan --lane anxious --pick 1

The frontend needs `/flutter-after-hours/*` proxied to that backend (the gateway
does this in production; any small dev proxy does locally).

## Known gaps

- **The adult turn fades at the door.** The two added beats per route establish
  consent explicitly, name both adults, and then close the scene. If the channel
  turns out to want the explicit version, it is two beats per route to extend —
  which is the point of deriving rather than authoring.
- **The server-gated CG fetch is a stub.** `cg.js:cgSource()` implements the paid
  path (bytes in the package) and the ticket call, but the
  `apps.blazecore.dev` endpoint for it does not exist yet, so the web tracks fall
  back to the covered plate rather than 404-ing. Set `window.GATED_CG_URL` when it
  lands; nothing else changes.
- **Channel risk, which is still the biggest thing here and is unchanged.** This
  is otome, and the channel for it is DLsite 女性向け, which is not validated:
  no submission has gone through it, and the ratio work that picked LewdCorner
  and ULMF for the other forks does not transfer — those are male-audience
  boards. See `ops/adult_forks/flutter.md` §1. What the derivation changes is the
  size of the bet, not the risk: the writing owed dropped from ~42k words to
  zero, so the fork is now cheap enough to hold finished while the channel is
  tested, instead of being a reason to spend 55 hours ahead of the answer.

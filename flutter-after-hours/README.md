# Flutter: After Hours — the adult fork of Flutter (Flat 404)

18+ otome VN. Three routes, five chapters each, three endings each, nine event CGs.
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
| stories | `backend/stories/` | `backend/stories_x/` — same schema, four added fields |
| judge pass | LLM grades the chapter goal | disabled; exit = affection + the chapter-end choice |
| branching | stage + persona prompts | the same, plus **attachment lanes** in the prose itself |
| CGs | none (text rewards only) | nine, each earned by game state |
| price / gate | $2.99, directLink ad | $8.99, **no directLink** (see `f95-ban-direct-link-ads`) |

A static route never calls a model, never claims the GPU, and works offline —
which is the point: per-player GPU time on erotic generation is a cost and a
liability, and a downloaded build cannot do it at all.

## The spine

`backend/stories_x/{ethan,luxingye,guyan}.json` — 3 routes × 5 chapters × (7 beats
+ 1 chapter-end choice) + 3 endings each. One of the seven beats per chapter is a
**lane beat**, authored three times and keyed on `attachment.detect()`:
`secure` / `anxious` / `avoidant`, with `unknown` falling back to `secure`. That is
45 lane variants across the fork, and it is free — the detector is a keyword and
behaviour heuristic with no model behind it.

**Chapter 1 of every route is finished prose. Chapters 2–5 are structured stubs**
(marked `"stub": true`, prose prefixed `[STUB]`), with flags, choices, aff gates,
CG slots and endings fully wired, so the spine is complete and playable end to end
and the prose can be dropped in beat by beat without touching any code.

Content pack is English (`*_en`) only so far; `_field()` falls back to `_en`, so a
zh/ja pack is additive.

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

`tools/gen_placeholder_cg.py` writes 9 covered plates, 9 thumbnails and 9
"uncensored" stand-ins with PIL — **no GPU, no renders**. The real plates come from
`ops/flutter_art/flutter_gen.py`. Layout is the shipping rule:

    frontend/cg/<slot>_locked.webp    covered — every build
    frontend/cg/<slot>_thumb.webp     gallery thumbnail
    frontend/cg/full/<slot>.webp      uncensored — PAID PACKAGE ONLY

`tools/build_free.sh` builds the free package and **fails** if anything from
`cg/full/` reaches it.

## Run it

    python3 -m uvicorn backend.app:app --port 8931          # from this directory
    python3 tests/test_static_story.py                       # 15 offline tests
    python3 tests/http_playthrough.py --route ethan --lane anxious --pick 1

The frontend needs `/flutter-after-hours/*` proxied to that backend (the gateway
does this in production; any small dev proxy does locally).

## Known gaps

- **Chapters 2–5 are stubs.** ~14k words per route still to write.
- **The server-gated CG fetch is a stub.** `cg.js:cgSource()` implements the paid
  path (bytes in the package) and the ticket call, but the
  `apps.blazecore.dev` endpoint for it does not exist yet, so the web tracks fall
  back to the covered plate rather than 404-ing. Set `window.GATED_CG_URL` when it
  lands; nothing else changes.
- **Channel risk, which is bigger than either.** This is otome. See the top of
  `ops/adult_forks/flutter.md` §1 and the README in that directory: validate the
  DLsite 女性向け submission path before the 55 writing hours are spent.

# Overnight agent contract — catharsis series

You are continuing blazeCore Play micro-games. Blaze is asleep. Do not ask questions.

## First actions every session

1. Read `play/catharsis/PLAN.md`, this file, and `play/catharsis/STATUS.md`.
2. Do the slice named `Next` in `STATUS.md`. If that slice is blocked, take the next unblocked slice in the same wave, then the next wave.
3. Update `STATUS.md` before you stop: what shipped, what broke, what is `Next`.

## Hard defaults (never re-ask)

- Vanilla JS + Canvas 2D. No React, Vue, Unity, Matter.js, Box2D, or new backends.
- Portrait 420×640. Core buttons live in the lower half of the screen.
- StarDust is the only currency. Gacha is cosmetic / flavor. Core loop is free.
- Copy lives in i18n JSON. Ship zh-Hans + EN in the same slice; other shrine locales can trail by one slice.
- Commerce is `kernel/commerce.js` stubs. Never add live ad / store SDK keys.
- First packet under 15 MB. Procedural Canvas / Web Audio, not big assets.
- Static hosting only. Register new slugs in `gateway/app.py` `STATIC_ONLY` + `APP_META`.
- Keep `play/null-shrine` playable. Extract physics by copy-then-rewire; do not delete shrine files until a smoke test imports the kernel and still passes.
- Work on branch `play/catharsis-series` if it exists; otherwise create it from current HEAD. Commit after a green slice. Do not push. Do not amend. Do not `--no-verify`. Do not commit `.env`, keys, or `*.bak*`.
- User-visible strings: dry, specific, no filler. Match shrine tone for seed cabinet; workplace beige for 1–3; ink/neon metaphysics for 4–5; grim humor for 6; bright classroom for 7.

## Slice recipe

1. Write or extend a Node smoke test (`*-smoke.cjs`) that fails first.
2. Implement the smallest loop that makes the test pass.
3. Manual shape: `index.html` must boot with no network besides same-origin files.
4. `node <smoke>.cjs` exit 0.
5. Hub link works if the title is meant to be public in this wave.
6. Commit with a one-sentence why. Update `STATUS.md`.

## If something is ambiguous

Pick the option that (a) reuses shrine physics or kernel code, (b) keeps the first packet small, (c) can be played one-thumbed. Write the choice in `STATUS.md` under Decisions. Continue.

## Never do

- Pause for product opinions, color palettes, or monetization debates.
- Add accounts, leaderboards that need a server, or real payments.
- Replace shrine’s custom physics with a library.
- Touch `play/flutter`, `play/tell`, MingXi, or other paid apps except gateway route tables.
- Force-push, skip hooks, or commit secrets.

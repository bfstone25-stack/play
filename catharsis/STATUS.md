# Catharsis series — live status

Updated: 2026-08-21 (matrix complete; shrine rewire skipped)

## Next

Idle. Do not add an eighth title. Optional only: EN strings on the newest cabinets, or reload apps-gateway.

## Blocked

Shrine kernel rewire. `play/null-shrine/frontend/js/physics.js` now references `window.__NS_LOWFX`, so `flipper-smoke.cjs` fails in Node. Kernel smoke still passes on the extracted copy. Keep shrine on its own file until that smoke is Node-safe.

## Done

- Waves 0–5. Seven titles + shrine seed on `play/catharsis-series`.
- Dual-smoke gate for shrine→kernel: failed; local shrine physics kept.

## Decisions log

- Kernel at `play/catharsis/kernel/`. Titles at `play/<slug>/frontend`.
- Commits on `play/catharsis-series`; no push.
- Do not point shrine at `/kernel/physics.js` while shrine physics has drifted.

## Notes

Reload apps-gateway for live slugs. Loop may keep ticking; if Next is Idle, do not invent scope.

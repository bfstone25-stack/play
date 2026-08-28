# Catharsis series — live status

Updated: 2026-08-28 (Beat Monday product exit)

## Next

Idle on remaining cabinet H5 work. Do not add an eighth title.

**Beat Monday (cabinet 03) pivoted out of Catharsis** → standalone Godot 2D pixel horror VN at `play/beat-monday/` (*Floor 13: Night Shift*; see `beat-monday/PIVOT.md`). Do not extend the H5 fighter loop as the shipping surface. Crazy Rant is handled by a sibling agent/PR. Null-shrine still awaits Blaze’s brief.

Optional only for other cabinets: EN strings, or reload apps-gateway.

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

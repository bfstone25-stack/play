# Catharsis series — live status

Updated: 2026-08-28 (Crazy Rant product exit)

## Next

Idle on remaining cabinet H5 work. Do not add an eighth title.

**Crazy Rant (cabinet 06) pivoted out of Catharsis** → standalone Godot 3D Horror VN at `play/late-inspection/` (see `late-inspection/PIVOT.md`). Do not extend the H5 rant loop. Beat Monday / Null-shrine await separate briefs; do not invent pivots for them.

Optional only for other cabinets: EN strings, or reload apps-gateway.

## Blocked

Shrine kernel rewire. `play/null-shrine/frontend/js/physics.js` now references `window.__NS_LOWFX`, so `flipper-smoke.cjs` fails in Node. Kernel smoke still passes on the extracted copy. Keep shrine on its own file until that smoke is Node-safe.

## Done

- Waves 0–5. Seven titles + shrine seed on `play/catharsis-series`.
- Dual-smoke gate for shrine→kernel: failed; local shrine physics kept.
- 2026-08-28: Crazy Rant marked exited; new work lives under `late-inspection/`.

## Decisions log

- Kernel at `play/catharsis/kernel/`. Titles at `play/<slug>/frontend`.
- Commits on `play/catharsis-series`; no push.
- Do not point shrine at `/kernel/physics.js` while shrine physics has drifted.
- Crazy Rant intentional product exit from Catharsis “no new engines” H5 contract into standalone Godot VN.

## Notes

Reload apps-gateway for live slugs. Loop may keep ticking; if Next is Idle, do not invent scope.

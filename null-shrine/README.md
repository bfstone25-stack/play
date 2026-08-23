# NULL//SHRINE

Skill-led shrine arcade for blazeCore Play. The board is not a Galton grid:
moving gates, vortices, rails and paired portals change the shot after launch.

## Play

1. Focus cools fast. Overdrive pays 2× and can purge the chain.
2. Hold to charge, release to fire. One phase bend per shot (A/D or paddles).
3. Wake three mechanism cores to reverse the central well.
4. Six-step chain multiplies Φ. A miss or overheated Overdrive breaks it.

Open `play/index.html` locally, or mount the folder as the static app `null-shrine`.

v0.4 presents the board as a 2.5D cabinet: perspective floor, camera punch, and glass HUD. Physics is unchanged.

## Verify

```bash
node physics-smoke.cjs
```

## Versioning

See `/VERSION` and `/CHANGELOG.md`. Tags follow `vMAJOR.MINOR.PATCH`.

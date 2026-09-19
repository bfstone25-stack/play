# Beat Monday · 打爆周一

A work week RPG. Five days, five antagonists — the standup, the inbox, the all-hands,
the performance review, the Friday deploy. One-thumb survivor-like combat with RPG
scaffolding: levels, stats, office-object equipment, a skill choice on level-up, and
colleagues who join your loadout. Wednesday is the breakdown: the 发疯文学 rant phrases
absorbed from CRAZY RANT become your weapon, fired as projectiles.

Part of 情绪解药 / Emotional Catharsis (`play/catharsis/PLAN.md`). Mainstream / SFW.

Design note: `DESIGN.md` (including where content gets added later).

- Play: https://apps.blazecore.dev/beat-monday/
- itch: https://bfstone25-stack.itch.io/beat-monday

Run locally:

```
python3 -m http.server 8765 --directory frontend
```

Tests:

```
node rpg-smoke.cjs      # plays the whole week headlessly + kernel-copy drift check
node monday-smoke.cjs   # kernel pool/collision
node frontend/game.test.js   # the older 2D fighter, still served at /arcade.html
```

The kernel is single-source at `play/catharsis/kernel/`; `./sync-kernel.sh` vendors the
files a shipped per-slug build needs into `frontend/kernel/`. Never edit those copies.

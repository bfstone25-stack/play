# blazeCore Play · Emotional Catharsis Series

Locked product + engineering plan. Overnight agents execute this without asking.
Source of truth for decisions: `play/catharsis/AGENTS.md`. Live slice: `STATUS.md`.

## Why this series exists

NULL//SHRINE (`play/null-shrine`) is already a skill-led pachinko / flipper cabinet on `play.blazecore.dev`. The matrix is seven lipstick-effect micro-games that share that **ball physics feel** and a **gacha / StarDust economy**, then fork into four audience tracks.

Do **not** rewrite shrine in Matter.js / Box2D. Extract its custom 2D engine into a shared kernel, then skin and fork loops.

## Locked product decisions

| Decision | Locked value | Do not reopen |
| --- | --- | --- |
| Brand | blazeCore Play · 情绪解药 / Emotional Catharsis | No new umbrella name |
| Hub | `play.blazecore.dev` becomes a cabinet selector; shrine stays Cabinet 01 | Do not unship shrine |
| Soft currency | StarDust (already in shrine copy) | No second currency |
| Hard currency | none in v1; IAP grants StarDust or cosmetics | No paid power that skips skill |
| Platform | Vanilla JS + Canvas 2D, static H5, PWA-ready | No React, no Unity, no backend |
| Physics | Extract shrine `physics.js`; no Matter.js / Box2D | Shrine stay playable if extract fails |
| Layout | Portrait 420×640, thumbs in lower half | No landscape core loop |
| First packet | < 15 MB per title (kernel + one title) | No heavy portraits / BGM in v1 |
| Locales | zh-Hans first, then EN, zh-Hant, ja, es, fr (shrine set) | Copy in JSON, never hardcoded UI strings |
| Persistence | `localStorage` only | No accounts, no server save |
| Ads / IAP | Interface in `kernel/commerce.js`; live SDKs off | Stub grants the reward locally |
| Gacha | 10-pull pity, 4 rarities, cosmetic / flavor only | Never gate the core loop behind a pull |
| Git | Branch `play/catharsis-series`; commit after each green slice; never push | No force, no amend, no `--no-verify` |
| Asking Blaze | Never, unless a secret / paid SDK key is required | Log blockers in `STATUS.md` and continue |

## Four tracks, seven titles

| # | Slug | Title | Track | Loop | Physics reuse |
| --- | --- | --- | --- | --- | --- |
| 01 | `null-shrine` | NULL//SHRINE | Seed cabinet | Skill pachinko + flippers | Source engine |
| 1 | `slacker-ball` | 摸鱼大暴弹 / Slacker Ball | Workplace | Peglin-like pegs + smash blocks | High — skin + breakables |
| 2 | `office-landlord` | 职场大赢家 / Office Landlord | Workplace | 5×4 symbol builder | None — grid sim |
| 3 | `beat-monday` | 击溃星期一 / Beat the Monday | Workplace | One-thumb survivor-like | Low — circle vs circle |
| 4 | `cyber-merit` | 赛博木鱼 / Cyber Merit | Z-Gen emptiness | Clicker + ASMR | None |
| 5 | `crazy-rant` | 发疯文学 / Crazy Rant | Z-Gen metaphysics | Phrase auto-battler | None — particles |
| 6 | `rebound-tycoon` | 老王逆袭记 / Rebound Tycoon | Midlife / gig | Idle tycoon | None |
| 7 | `word-pop` | 单词弹珠英雄 / Word Pop Quest | Edutainment | Quiz-charged pegs | High — shrine physics + quiz overlay |

Z-Gen titles are a **separate visual language** (ink, lotus, rant typography). They still mount the same kernel (shell, StarDust, gacha, commerce, i18n).

## Shared kernel vs unique loops

```
play/catharsis/
  kernel/          # data-driven, no title names
    physics.js     # balls, pegs, walls, flippers, fields (from shrine)
    economy.js     # StarDust, tickets, run rewards
    gacha.js       # pity, rarity, inventory
    commerce.js    # rewarded / interstitial / IAP stubs
    audio.js       # Web Audio context, one-shot SFX
    i18n.js        # locale loader
    shell.css      # portrait chrome, lower-thumb zone
    save.js        # localStorage schema v1
  hub/frontend/    # cabinet selector on play.blazecore.dev
  titles/<slug>/   # only loop, art direction, JSON formulas
play/null-shrine/  # stays; later rewired to import kernel physics
```

Each title is JSON formulas + a loop script + a thin `index.html`. Presentation (Canvas) never owns numbers.

## Wave plan (build this order)

Effort is relative engineering days for one agent, not calendar days.

| Wave | Goal | Slice definition of done |
| --- | --- | --- |
| 0 | Kernel + hub | Physics smoke still passes; hub lists 8 cabinets; commerce stub grants; gacha pity unit-tested; shrine still serves at `/` |
| 1 | Slacker Ball | One-thumb launch, peg bounce, smash “urgent request” blocks, 3 ball skins via gacha, rewarded ammo stub, zh-Hans + EN |
| 2 | Z-Gen pair | Cyber Merit clicker with lotus VFX + share card; Crazy Rant phrase combinator that fires a barrage; both on hub |
| 3 | Workplace pair | Office Landlord 5×4 adjacent settle; Beat the Monday object-pooled horde, one-thumb drag |
| 4 | Rebound Tycoon | Offline earnings with timestamp clamp; IAA double stub; 8h away math documented |
| 5 | Word Pop Quest | Quiz charges a shrine-like shot; no ads; fake parent report share card; last because of COPPA-adjacent copy |

Stop a wave when the hub link plays a 60-second session on a phone-width viewport. Polish after all seven loops exist.

## Monetization (lipstick, not pay-to-win)

- Rewarded video stub: restore ammo / 2× run / revive. Always skippable via “grant anyway (dev)” in non-prod.
- $0.99 analog: cosmetic blind box or audio pack. Grants inventory locally.
- Word Pop: subscription UI mock only; no charge; copy promises no hostile ads.
- Share cards (persona / 功德 / 战报) are the growth loop, not ads.

## Gateway

- Keep `STATIC_ONLY` growth: add each new slug next to `fold` and `null-shrine`.
- `play.blazecore.dev` `/` → hub. Deep links: `/null-shrine/`, `/slacker-ball/`, …
- `apps.blazecore.dev/<slug>/` remains the apps-suite alias.
- Do not touch paid app backends (mingxi, flutter, tell, …).

## What “autonomous overnight” means

Read `AGENTS.md`. Execute the next `STATUS.md` slice. If blocked, write the blocker and start the next unblocked slice. Never idle waiting for Blaze.

Do not start Matter.js, Unity, a Node game server, AdMob live keys, or user accounts.

# itch storefront audit — second-pass candidates

Scope: every bfstone25-stack project except **Across the Hall** (flagship,
do not touch) and the three relaunched titles. Data: itch API + repo survey,
2026-08-29. Nothing below has been modified; actions are proposals only.

## Relaunched this pass (reference standard)

| Page | id | Model | Price |
|---|---|---|---|
| Late Inspection: Flat 404 | 4951380 | paid + free slice embed | $2.99 |
| Floor 13: Night Shift | 4951384 | paid + free slice embed | $2.99 |
| Midnight Pawn & Crypt | 4951385 | paid + free slice embed | $1.99 |

## Retired this pass (replaced products)

| Page | id | Was | Action taken |
|---|---|---|---|
| crazy-rant | 4922055 | Catharsis 06 H5 bullet-hell | restricted (unlisted) |
| beat-monday | 4922058 | H5 office fighter | restricted (unlisted) |
| null-shrine | 4922023 | H5 pixel RPG | restricted (unlisted) |

## Already at the paid+free-embed standard

| Page | id | Price | Notes |
|---|---|---|---|
| Tell [Free Web Playable] | 4922065 | $2.99 | 破绽 detective; repo `tell/` |
| SilverTongue [Free Web Playable] | 4922064 | $2.99 | Persuasion RPG; repo `silvertongue/` |
| GHOST CHANNEL [Free Web Playable] | 4928255 | $1.99 | mimic-voice deduction |

These three already follow the paid + free-web-embed model. Second pass =
restyle check only (cover/screenshots/theme vs. the new bar); keep paid.

## Free cabinet titles (H5 era) — restyle candidates

| Page | id | Identity (repo) | Proposed second-pass action |
|---|---|---|---|
| Flutter | 4922085 | `flutter/` — "He remembers you" narrative | Confirm content; likely stays free; restyle page |
| Fold | 4922063 | `fold/` — geometric puzzle | Confirm; stays free; restyle |
| Cyber Merit | 4922053 | `cyber-merit/` — cyber-Buddhist mokugyo clicker | Confirm; stays free; restyle |
| Office Landlord | 4922056 | `office-landlord/` — 职场大赢家 sim | Confirm; stays free; restyle |
| Rebound Tycoon | 4922060 | `rebound-tycoon/` — 回弹大亨 breakout tycoon | Confirm; stays free; restyle |
| Slacker Ball | (unlisted?) | `slacker-ball/` — 摸鱼大暴弹 | Not on account list — confirm if it exists |
| Word Pop | (unlisted?) | `word-pop/` — 单词弹珠英雄 | Not on account list — confirm if it exists |
| Catharsis | (hub) | `catharsis/` — cabinet hub 情绪解药 | Confirm whether hub page exists |

## Tools/marketing pages (pop-os `Products/.itch-tools`)

| Page | id | Notes |
|---|---|---|
| AppealPro | 4925166 | Not in cloud repo — inspect before any change |
| Logos | 4925167 | Not in cloud repo — inspect |
| MediKin | 4925168 | Not in cloud repo — inspect |
| MingXi · 明析 | 4925169 | Not in cloud repo — inspect |
| ReplyGuard | 4925170 | Not in cloud repo — inspect |
| ShiFu · 找师傅 | 4925171 | Not in cloud repo — inspect |
| VisaCheck | 4925173 | Not in cloud repo — inspect |

## Rules for the second pass

1. Do not change price/model on any game without confirming what it is.
2. Free cabinet games stay free unless there is a full, polished build to sell.
3. Restyle = cover, in-game screenshots, embed BG, theme, tags, AI disclosure,
  English-primary copy with tidy locale blocks.
4. jam16 has no itch page (repo-only jam folder) — no action.

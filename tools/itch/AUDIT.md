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


## Second pass results (2026-08-30)

Subtitles live on the three relaunched pages (short_text leads with
"Free to Play Online"; price and download structure unchanged):
Late Inspection, Floor 13, Midnight Pawn.

Restyled to the relaunch standard (copy, tags=10, screenshots, theme,
AI disclosure, 1280x720 frame embed):

| Page | id | Model | Notes |
|---|---|---|---|
| Flutter | 4922085 | free | "Free to Play Online"; 3 shots; romance/otome tags replace generic ones |
| Cyber Merit | 4922053 | free | NOT broken — full cyber-Buddhist clicker (28 KB is just efficient); 3 shots |
| GHOST CHANNEL | 4928255 | $1.99 | 0 -> 10 tags; first screenshots; neon theme |
| SilverTongue | 4922064 | $2.99 | 0 -> 10 tags; 3 shots; genre rpg |
| Tell | 4922065 | $2.99 | 0 -> 10 tags; 3 shots incl. live interrogation |
| Rebound Tycoon | 4922060 | free | 5 -> 10 tags; pinball-tycoon copy |
| Office Landlord | 4922056 | free | new copy from in-game text; 2 shots |
| Fold | 4922063 | free | new copy; 2 shots; suggested $2 donation kept |
| ShiFu | 4925171 | free tool | subtitle + screenshot + cream theme; see size note below |

### Package size investigations

- flutter-html5.zip (226 MB): LOADS FINE — itch serves HTML5 files
  individually from the CDN; title renders in ~12 s headless. The weight is
  196 MB of BGM in 3 formats (mp3 91 MB + ogg 39 MB + opus 55 MB + cues).
  Slim export possible (mp3-only ~115 MB, or EN-only slice ~40 MB) but not
  required; embed kept as-is. Instructions note the large first load.
- sh<ifux>-html5.zip (451 MB): LOADS FINE (landing renders in <10 s).
  432 MB is 324 editorial 1024x1024 PNGs (~1.3 MB each) loaded on demand.
  PNG -> WebP would take it to ~40 MB but needs a rebuild + re-upload from
  the pop-os source (Products/.itch-tools); page works without it.
- cyber-merit (28 KB): verified working, not a placeholder.

Remaining audit items: slacker / word-pop (not on account), catharsis hub,
and the tools pages (appealpro, logos, medikin, mingxi, replyguard,
visacheck) — inspect-before-change per first-pass rules.

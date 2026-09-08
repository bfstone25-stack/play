# Elena — Platform & Monetization Plan

## What players get for free (itch web)
- **Chapters 1–5** playable in browser on itch (this repo, `v0.5.0`).
- F95zone remains the discovery / discussion funnel (already ~3K card views).

## Where money should come from (priority)
1. **itch.io Adult tag + paid deluxe** — tip jar / paid DRM-free zip for uncensored CG pack + desktop builds. Enable NSFW listing properly.
2. **DLsite (Maniax)** — JP/EN adult storefront; better paid conversion for VN/ASMR-adjacent.
3. **Patreon _or_ SubscribeStar Adult** — update-cadence model (monthly chapter polish, voice, Live2D). Pick **one** primary; cross-link the other later.
   - Patreon: easier Google OAuth; stricter adult rules.
   - SubscribeStar Adult: friendlier for explicit; age-gate UX is rough.

## Account status on this VM (2026-09-08)
| Platform | Logged in? | Notes |
|---|---|---|
| Google | **No** | Chrome shows “Not signed in”. Cannot OAuth Patreon/etc. until you sign in. |
| itch.io | **No** | Login page only (GitHub OAuth available, **no Google**). Game page still shows **$2.99** for offline; web Ch.1 was free. Need dashboard to set **$0** / PWYW. |
| Patreon | **No** | Google button present — blocked until Google session exists. |
| SubscribeStar Adult | Age gate buggy | Date picker malformed in automation; needs manual pass. |
| DLsite Maniax | **No** | Registration/login available after age confirm. |

## What you need to do once (5 minutes)
1. In this VM’s Chrome, sign into **Google** (your usual account).
2. Tell the agent “Google is signed in” — we can then:
   - Create/link **Patreon** (or SubscribeStar).
   - Set itch project to **$0 / PWYW**, add **Adult** community tag, update description for 5-chapter free web.
   - Start **DLsite** circle registration (identity docs may still need you).

## itch copy change (when logged in)
- Price: **Free** (or PWYW min $0).
- Title note: `Elena: Crimson Archives (Ch.1–5 Free Web)`.
- Tags: add adult/NSFW community visibility.
- Description: Chapter 1–5 free in browser; supporter packs on Patreon/DLsite.

## Repo docs
- Game scripts: `game/scripts/05_script_ch2.rpy` … `08_script_ch5.rpy`
- End CTA links: itch / Patreon / SubscribeStar / DLsite / F95

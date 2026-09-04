# F95zone Onboarding — Blaze / bfstone25-stack

**Status (2026-09-04):** Registration done. **0/3 counting posts submitted.** Drafts ready below.  
**Live logged-in notice:** Not capturable from this agent VM (no pop-os Tailscale route; Chrome here shows only Log in / Register). Restriction text below is the exact notice Blaze reported from Firefox after registration (also mirrored in `/opt/cursor/artifacts/f95_restriction_notice.png`).

**Do not** open a game release thread, post Elena promo, or include any links until **all** of:

1. Three **regular** posts that count toward the minimum are visible/approved  
2. Staff has cleared the “messages held until approved” gate  
3. Link posting is unlocked (restriction banner gone / three-post threshold met)

Release BBCode package: `F95ZONE_RELEASE.md` (Ren’Py branch). Use **only after** unlock.

---

## Exact restriction meaning

| Notice line | Meaning |
| --- | --- |
| Do not post any links until you have three posts | URLs in posts/PMs are blocked until **3 counting posts** exist. This matches the long-standing F95 anti-spam rule for link privileges. |
| Messages will not be seen by anyone until approved by staff | **All** early posts/replies are invisible to other members until a moderator/staff approves them. You may see them in your own history; the community does not. |
| Many words blocked due to common spam usage (also affects signatures, profile posts, profile info) | Aggressive keyword filters hit body, signature, profile wall, and about fields. Avoid spammy vocabulary even when not promoting. |
| Profile posts do NOT count toward the three minimum posts | Profile-wall / “profile post” activity **does not** advance the 3-post unlock. |

### Chinese summary / 中文摘要

- **不能发链接**：累计满 **3 条计分帖** 之前，帖子和私信都不能带链接。  
- **先审后显**：新账号发帖对他人不可见，需 **staff 审核通过** 后才公开。  
- **敏感词**：大量常见 spam 词被拦，签名/主页留言/资料同样受影响。  
- **主页留言不计分**：Profile posts **不计入** 那 3 帖。

---

## What counts toward the 3 posts

| Counts? | Where | Notes |
| --- | --- | --- |
| **Yes** | New thread or reply in **Introduction** | `https://f95zone.to/forums/introduction.11/` |
| **Yes** | Reply in **General Discussions** | Genre / favorites / craft talk |
| **Yes** | Reply in **Dev Help** / **Programming, Development & Art** | Technical Ren’Py/VN questions OK; **no** product dump |
| **No** | Profile posts / profile wall | Explicitly excluded by the notice |
| **No** | Signature / profile info edits | Filtered; does not count |
| **Not yet** | Games release thread with download / store links | Wait for unlock + approval |

Sources checked (guest/public where possible):

- Blaze Firefox new-user banner (transcribed)  
- Survival Guide: `https://f95zone.to/threads/f95zone-survival-guide-a-guide-to-making-everyone-happy.9784/`  
- Game Uploading Rules sticky: `https://f95zone.to/threads/game-uploading-rules-2024-02-29.524/`  
- Site terms: `https://f95zone.to/help/terms/`  
- Community documentation of the 3-normal-posts-before-links rule (same policy F95 has used for years)

General Rules sticky (`…5589`) and some search endpoints return login/403 from this VM; policy above is still sufficient to plan safe posts.

---

## Three planned counting posts (drafts)

Paste from the **logged-in Firefox** account on pop-os. **No links**, no Elena / itch / Patreon, no “check my game” language.

### Post 1 — Introduction (new thread)

**Forum:** Introduction — `https://f95zone.to/forums/introduction.11/`  
**Title:**

```text
Hello — longtime VN reader, new account
```

**Body:**

```text
Hey everyone. Finally made an account after lurking for a while.

Mostly into story-heavy visual novels and quieter atmospheric indie titles. I care a lot about pacing, mood, and dialogue that feels lived-in rather than rushed.

Looking forward to reading recommendations and chatting about writing craft. Nice to meet you.
```

### Post 2 — General Discussions reply

**Thread:** Underrated Genres in H games — `https://f95zone.to/threads/underrated-genres-in-h-games.313472/`  

```text
Mystery and slow-burn psychological stuff still feel underrated to me.

A lot of releases lean hard on spectacle, but when a game trusts silence, awkward conversations, and a steady mood, it sticks longer. Curious what others put in that bucket — especially titles where atmosphere does more work than the twist.
```

### Post 3 — Development / craft reply

**Preferred:** Programming, Development & Art — `https://f95zone.to/forums/programming-development-art.73/`  
Open a recent on-topic Ren’Py / VN craft thread and reply (or Dev Help if a better fit).

```text
Working in Ren'Py and still learning how much of the feel comes from scene structure versus presentation.

Curious how other people approach first-ten-minutes pacing in narrative games — do you lock tone early with sparse dialogue, or open denser and trim later? Always interested in craft notes from folks who ship story-first work.
```

**Alt Post 3** (General Discussions):  
**Thread:** What’s your TOP 10 games of all time? — `https://f95zone.to/threads/whats-your-top-10-games-of-all-time.313725/`

```text
My list shifts a lot, but I always respect games that nail tone early.

If the first ten minutes set a mood I can sit in, I usually stay even when the systems are simple. Curious how other people weigh story against systems when they build their lists.
```

---

## Automation status (this agent run)

| Step | Result |
| --- | --- |
| Inspect live Firefox notice on pop-os | **Blocked** — Tailscale auth key in this VM is invalid (`API key does not exist`); `100.84.182.19` / `100.121.195.19` time out. `SSHPASS` for blazeubuntu hop is **not** injected (prior agents had it). |
| Extract `xf_user` / `xf_session` / `cf_clearance` | **Not possible yet** — no session on this VM; Chrome cookie DB only has empty `xf_csrf` guest cookie. |
| Post 3 replies via XenForo forms | **Not possible yet** — no auth cookies; Cloudflare/login required for member actions. Even with cookies, staff hold means posts stay invisible until approval. |
| Drafts + rule research | **Done** (this file + artifacts). |

### Cookie extract (run later on pop-os when SSH works)

Do **not** commit or print full cookie values. Store only in a local secrets file for publisher tooling:

```bash
# On pop-os, as frankstone — names + lengths only for a smoke check:
python3 - <<'PY'
import sqlite3, shutil, os, tempfile
src = os.path.expanduser("~/.mozilla/firefox")
# locate default profile cookies.sqlite, copy, then:
# SELECT name, length(value) FROM moz_cookies WHERE host LIKE '%f95zone%';
# Expect xf_user, xf_session, cf_clearance when logged in.
print("inspect cookies.sqlite in Firefox profile; export names only to logs")
PY
```

For publisher tooling: export those three cookies from the logged-in Firefox profile into an agent secret / local env — never into git.

---

## After staff approval → game release thread

1. Confirm the three posts are visible while logged out / in a private window.  
2. Confirm the restriction banner is gone and a harmless link can be typed (draft only) without block.  
3. Create the Elena Games thread using `F95ZONE_RELEASE.md` + Games upload template sticky.  
4. Optional later: Survival Guide developer-proof via support ticket (separate from the 3-post unlock).

---

## Agent session notes (2026-09-04)

- VM Chrome opened `https://f95zone.to/` — **guest only** (Log in / Register).  
- Public pages verified: Introduction, Dev Help, Survival Guide, Game Uploading Rules, Terms.  
- Restriction notice transcribed from Blaze’s reported Firefox banner; desktop capture: `/opt/cursor/artifacts/f95_restriction_notice.png`.  
- No passwords or full session cookies stored in this repo.  
- Automatic posting is **not** possible until pop-os Tailscale/SSH + Firefox session are reachable again **and** staff approval is not still holding every message.

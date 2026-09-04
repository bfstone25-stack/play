# F95zone Onboarding — Blaze / bfstone25-stack

**Status (2026-09-04):** Registration done. Blaze reports the **3 counting posts were already submitted manually**. Next gate: staff approval + link unlock, then automated Elena release via `tools/f95zone/publisher.py`.

**Do not** open a game release thread with links until:

1. Three **regular** counting posts exist and are staff-visible  
2. Restriction banner / link lock is gone  
3. Session cookies are available to the publisher (`F95ZONE_COOKIES_FILE`)

Release BBCode: `F95ZONE_RELEASE.md` and `f95_posts/release_elena_body.txt`.

---

## Automation: why “XenForo API” is not enough by itself

F95zone runs XenForo’s REST API (`GET https://f95zone.to/api/` → JSON error `no_api_key_in_request`). That API **requires an admin-issued `XF-Api-Key`** from the forum ACP. Normal members cannot mint a key. OAuth clients are also admin-gated.

So for a one-person studio the **real** automation surface is the same pattern we already use for itch page edits:

1. Log in once in Firefox (human, Cloudflare passes).  
2. Export session cookies (`xf_user`, `xf_session`, `cf_clearance`, …).  
3. Script scrapes `data-csrf` / `_xfToken` and POSTs `/threads/{id}/add-reply` or `/forums/{id}/post-thread`.

Tooling lives in **`tools/f95zone/`** — see that README.

```bash
# On the machine with logged-in Firefox:
python3 tools/f95zone/export_firefox_cookies.py --out ~/.config/f95zone/cookies.json
export F95ZONE_COOKIES_FILE=~/.config/f95zone/cookies.json

python3 tools/f95zone/publisher.py whoami
python3 tools/f95zone/publisher.py self-test-guest   # proves API key wall + CSRF scrape
python3 tools/f95zone/publisher.py run-job \
  --job elena-suspense/f95_posts/jobs/release_elena.yaml --dry-run
```

**One-time cookie export ≠ hand-posting forever.** Export once (or when the session expires); every later reply/thread/update is a CLI/job.

Never commit cookie values. `.gitignore` already excludes `**/cookies.json` and `.secrets/`.

---

## Exact restriction meaning

| Notice line | Meaning |
| --- | --- |
| Do not post any links until you have three posts | URLs blocked until **3 counting posts** |
| Messages will not be seen by anyone until approved by staff | Early posts invisible until moderator approval |
| Many words blocked due to common spam usage | Aggressive filters on body / signature / profile |
| Profile posts do NOT count toward the three minimum posts | Profile wall does **not** unlock links |

### Chinese summary / 中文摘要

- **不能发链接**：满 **3 条计分帖** 前不能带 URL。  
- **先审后显**：新帖需 staff 审核后才公开。  
- **敏感词**：签名/主页/资料同样过滤。  
- **主页留言不计分**。  
- **自动化**：公开 REST API 需要管理员 API Key（拿不到）；用 Firefox cookie + `_xfToken` 发帖脚本。

---

## What counts toward the 3 posts

| Counts? | Where |
| --- | --- |
| **Yes** | Introduction / General Discussions / Dev forum threads & replies |
| **No** | Profile posts, signatures, profile info |
| **Not yet** | Games release with download/store links |

Draft text files (also used by the publisher job): `elena-suspense/f95_posts/`.

---

## After staff approval → automated game release

1. Confirm the three posts are visible while logged out.  
2. Confirm the restriction banner is gone.  
3. Export cookies → `whoami` succeeds from the agent machine.  
4. Confirm `f95_posts/release_elena_body.txt` matches the latest `F95ZONE_RELEASE.md`.  
5. Set the correct Games forum id in `f95_posts/jobs/release_elena.yaml`.  
6. `publisher.py run-job --job …/release_elena.yaml` (dry-run first).

---

## Agent session notes

- Live `/api/` returns `no_api_key_in_request` / `api_key_not_found` — API exists, member key does not.  
- Guest thread pages expose `data-csrf` for form automation once cookies are present.  
- pop-os Tailscale/SSH was unreachable from the cloud VM at last check; cookie file can be copied into the agent secret store when connectivity returns.  
- No passwords or full session cookies are stored in this repo.

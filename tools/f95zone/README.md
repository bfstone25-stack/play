# F95zone publisher (automation)

Automate F95zone posts the same way we automate itch page edits: **reuse a logged-in browser session**, then POST XenForo forms with `_xfToken`.

## Why not “the XenForo API”?

F95zone **does** run XenForo’s REST API (`https://f95zone.to/api/` returns JSON and `XF-Latest-Api-Version`).

That API is **not usable by normal members**:

| Credential | Who can create it | Usable for posting as Blaze? |
| --- | --- | --- |
| `XF-Api-Key` (user / super-user) | **Forum admins only** (ACP) | No — F95 will not issue this to indie accounts |
| OAuth2 client | **Forum admins only** | No — same ACP gate |
| Session cookies (`xf_user`, `xf_session`, `cf_clearance`) + page `_xfToken` | **You**, via Firefox login | **Yes** — this is the automation path |

Probe yourself:

```bash
curl -sS https://f95zone.to/api/
# -> {"errors":[{"code":"no_api_key_in_request",...}]}

curl -sS -H 'XF-Api-Key: anything' https://f95zone.to/api/me
# -> {"errors":[{"code":"api_key_not_found",...}]}
```

So “XenForo has an API” is true. “Your account can call it” is false until F95 staff hand you a key (they won’t for regular publishers). Cookie + form automation is the squeeze-every-automation path.

## One-time setup (human, ~2 minutes, then reusable)

1. Stay logged into F95zone in Firefox (the account that already made the 3 posts).
2. Export cookies (names + values) into a **local secrets file outside git**:

```bash
# On the machine with the logged-in Firefox profile:
python3 tools/f95zone/export_firefox_cookies.py \
  --out ~/.config/f95zone/cookies.json
```

Or copy cookies from a cookie-manager extension into the same JSON shape (see `cookies.example.json`).

3. Point the publisher at that file:

```bash
export F95ZONE_COOKIES_FILE="$HOME/.config/f95zone/cookies.json"
# optional override:
# export F95ZONE_BASE_URL=https://f95zone.to
```

**Never commit cookies, passwords, or full `xf_user` values.**

## Commands

```bash
# Prove session works (prints username / user id; never prints cookie values)
python3 tools/f95zone/publisher.py whoami

# Dry-run a reply (fetches CSRF, builds POST, does not send)
python3 tools/f95zone/publisher.py reply \
  --thread-id 313472 \
  --message-file elena-suspense/f95_posts/02_underrated_genres.txt \
  --dry-run

# Actually post a reply
python3 tools/f95zone/publisher.py reply \
  --thread-id 313472 \
  --message-file path/to/body.txt

# Create a thread (Games / Introduction / etc.)
python3 tools/f95zone/publisher.py create-thread \
  --forum-id 11 \
  --title-file path/to/title.txt \
  --message-file path/to/body.txt

# Run a job file (YAML) — onboarding drafts or Elena release
python3 tools/f95zone/publisher.py run-job \
  --job elena-suspense/f95_posts/jobs/release_elena.yaml \
  --dry-run
```

## Cloudflare note

F95 sits behind Cloudflare. Cookie export from a **real browser that already passed CF** (including `cf_clearance`) is more reliable than password login from a headless/cloud IP. Prefer cookies over `login` whenever possible.

## After the 3-post unlock

1. Confirm restriction banner is gone.
2. `whoami` succeeds from the agent/CI machine using exported cookies.
3. `run-job` the Elena release YAML (links allowed only after unlock).
4. Re-export cookies when the session expires (periodic, still far less labor than hand-posting every thread).

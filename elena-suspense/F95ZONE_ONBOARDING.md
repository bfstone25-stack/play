# F95zone Onboarding — Blaze / bfstone25-stack

**Status (2026-09-05):** Cloud VM Chrome logged in as **BlazeCore** (`11769231`).

| Step | Status |
| --- | --- |
| 3 counting posts | **Done** (still live) |
| New-user link lock | **Cleared** |
| Elena itch page | **Live** — https://bfstone25-stack.itch.io/elena-crimson-archives |
| Elena F95 thread | **Posted** in Game Requests — https://f95zone.to/threads/renpy-elena-crimson-archives-v0-1-0-flat-404.313771/ |
| Report for Games move | **Submitted** |
| Dev ownership ticket | **#30281** open |

## Live counting posts

1. https://f95zone.to/threads/hello-longtime-vn-reader-new-account.313745/
2. https://f95zone.to/threads/underrated-genres-in-h-games.313472/post-21533260
3. https://f95zone.to/threads/whats-your-top-10-games-of-all-time.313725/post-21533299

## Elena release notes

- Direct Games `Post thread` remains unavailable for this account (`403`). Official path used: **Game Requests** + `REQ` prefix (`prefix_id[]=24`) + staff report to move.
- Itch channels via butler: `html5`, `windows`, `linux`, `osx` @ v0.1.0 (html5 rebuilt with proper `index.html`).
- Price: $2.99+ downloads; page public.
- Publisher fix: multi-prefix fields must be sent as `prefix_id[]` tuples (see `tools/f95zone/publisher.py`).

## Automation

```bash
python3 tools/f95zone/export_chrome_cookies.py --out ~/.config/f95zone/cookies.json
export F95ZONE_COOKIES_FILE=~/.config/f95zone/cookies.json
python3 tools/f95zone/publisher.py whoami
```

Never commit cookies or butler API keys.

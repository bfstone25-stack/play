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

## Staff review update (2026-09-07)

- Not moved to Games yet (still `REQ` in Game Requests).
- Report was rejected: staff asked to follow https://f95zone.to/threads/how-to-post-a-new-game.159990/
- Ticket #30281 staff reply: use that template, then tell them when fixed.
- We rewrote the OP to the official template and added approved Gofile mirrors for Win/Linux/Mac.
- Re-reported the thread and notified staff on the ticket.

## Staff review update (2026-09-07 evening)

- New staff rejection: images broken / redo step 5 (upload cover+previews to F95 attachment server).
- Fixed: uploaded attachments and rewrote OP to use `[ATTACH]` / `[ATTACH=full]`.
- Notified ticket #30281 and re-reported the thread.
- Still waiting for Games move.

## Background watcher (running)

```bash
tools/f95zone/watch_elena.sh status
cat ~/.local/share/f95zone/elena_watch_state.json
tail ~/.local/share/f95zone/elena_watch_events.jsonl
cat ~/.local/share/f95zone/elena_approved_snapshot.json  # appears after Games move
```

Polls every 30 minutes in tmux session `f95-elena-watch`. No agent tokens used while idle.
On approval it auto-writes `elena_approved_snapshot.json` (final URL, tags, download/media links).
A low-frequency agent timer also wakes every few hours to act only if staff asked for fixes or the thread was approved.

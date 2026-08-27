# itch.io page kit — Across the Hall

**Live:** https://bfstone25-stack.itch.io/across-the-hall  
Game id `4944030`. Butler channel `html5`.

The page was created from **pop-os** (`frankstone@100.84.182.19`) using the already-logged-in Firefox cookies, hop:

```
blazeubuntu (bfs) -> ssh -i ~/.ssh/id_pop frankstone@pop-os
```

That is the repeatable path. Itch has no create/edit API. Butler only pushes files.

## After a new web export

On this cloud VM (or blazeubuntu):

```
export BUTLER_API_KEY=...   # itch API key, never commit
butler push /path/to/build/web bfstone25-stack/across-the-hall:html5 --userversion X.Y.Z
```

Exclude `*.pem` certs from the web folder.

## After copy changes

Re-POST https://itch.io/game/edit/4944030 from pop with a CookieJar that **keeps `itchio_token` from the GET**. CSRF alone is not enough (`mismatched token`).

Required fields that have bitten us:

- `game[published]` = `published` | `draft` | `restricted` (not `1`)
- `game[payment_mode]` = `free`
- `game[min_price]` = `0`
- `game[community_type]` = `none`
- do **not** send `game[genre]=horror` (not in their genre enum; horror is a tag)

## Listing copy (what is live)

**Title:** Across the Hall

**Short:** The clock will not leave 02:17. 401 is locked. 402 is open. The vacancy form is signed with your name.

**Kind:** HTML · **Embed:** 1280×720 fullscreen · **Price:** free · **Visibility:** public

**Tags:** horror, psychological-horror, 3d, first-person, short, godot, walking-simulator, atmospheric, ai-generated

**AI disclosure:** yes — text + code (not graphics pack / not licensed soundtrack)

Details HTML is the long English night/controls/jam/AI block in this file’s previous revision; keep player-facing English.

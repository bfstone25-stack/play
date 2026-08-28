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
- `game[community_type]` = `topic` (comments enabled; valid values also include `none` and `category`)
- do **not** send `game[genre]=horror` (not in their genre enum; horror is a tag)

## Listing copy (what is live)

**Title:** Across the Hall

**Short:** The clock will not leave 02:17. 401 is locked. 402 is open. The vacancy form is signed with your name.

**Kind:** HTML · **Embed:** 1280×720 fullscreen · **Price:** free · **Visibility:** public

**Tags:** horror, psychological-horror, 3d, first-person, short, atmospheric, spooky, walking-simulator, ai-generated, time-travel

**AI disclosure:** yes — text + code + listing graphics (not licensed soundtrack)

Cover, four in-game screenshots, html5 `0.1.6`, Embed BG, and a first devlog are live.

Jam: [Themed Horror Game Jam #25](https://itch.io/jam/themed-horror-game-jam-25) — theme **Time Travel**. Entry: Across the Hall.

Devlog: https://bfstone25-stack.itch.io/across-the-hall/devlog/1642952/the-hallway-is-open

**Product position:** the current complete short is **Episode I: The Fourth Floor**.
It remains free permanently. Later paid episodes use separate itch projects,
because itch does not provide native DLC ownership for a free HTML5 project.
See `EPISODES.md`.

**Cross-promo:** the page and Episode I ending point to:

- GHOST CHANNEL: https://bfstone25-stack.itch.io/ghost-channel
- Tell: https://bfstone25-stack.itch.io/tell

**Embed BG** (the hallway still behind **Run game**): theme editor field `layout[embed_background_image][image_id]`. Upload via `POST /dashboard/upload-image?game_id=4944030` (`action=prepare` → GCS → `action=success`), then POST the theme form to `https://bfstone25-stack.itch.io/across-the-hall/edit` with CSRF + `itchio_token` from GET. Live image id `29577643`. Screenshots use `POST /game/edit/4944030/upload/prepare` with `kind=image` `type=screenshot`, then `screenshot[id][position]` on the edit save.

#!/usr/bin/env python3
"""The "More from Flat 404" matrix: cover thumbnails + text for our other games.

Reads ops/seo/games.json (the landing-page catalogue) and writes
  more/<slug>.webp          480x270 cover crops (committed; small)
  data/more_games.json      {"studio", "adult": [...], "regular": [...]}: slug, name, hook, cover
NO URL is written anywhere: the DLsite build must carry none (help article 4408257160345,
他サイトへの誘導). The web edition's page maps a slug to its page at click time.
Regular-game tiles only ever use that game's own (all-ages) key visual.
"""
import json, re
from pathlib import Path
from PIL import Image
HERE = Path(__file__).resolve().parent.parent
ROOT = HERE.parent.parent
G = json.loads((ROOT / "ops/seo/games.json").read_text())
ADULT = ["room704", "confession", "floor-13-retention", "midnight-pawn-collateral", "flutter-after-hours", "overnight-clause"]
REGULAR = ["rebound-tycoon", "ghost-channel", "fold", "tell", "silvertongue", "flutter", "across-the-hall",
           "floor-13", "late-inspection", "midnight-pawn"]
BAN = re.compile(r"https?:|itch|blazecore|flat404|workers\.dev|dlsite|nutaku|steam", re.I)
out = {"studio": "Flat 404", "adult": [], "regular": []}
(HERE / "more").mkdir(exist_ok=True)
for world, keys in (("adult", ADULT), ("regular", REGULAR)):
    for k in keys:
        g = G[k]
        if (g.get("world") == "adult") != (world == "adult"):
            raise SystemExit(f"{k}: world {g.get('world')} filed under {world}")
        src = ROOT / g["media"]["hero"]
        im = Image.open(src).convert("RGB")
        w, h = im.size; tw = min(w, int(h * 16 / 9)); th = int(tw * 9 / 16)
        im = im.crop(((w - tw) // 2, (h - th) // 2, (w - tw) // 2 + tw, (h - th) // 2 + th)).resize((480, 270), Image.LANCZOS)
        slug = g["slug"]
        im.save(HERE / "more" / f"{slug}.webp", quality=82)
        name = g["name"]; hook = g.get("hook", "")
        for t in (name, hook):
            if BAN.search(t):
                raise SystemExit(f"{k}: store/URL word in text: {t}")
        out[world].append({"slug": slug, "name": name, "hook": hook, "cover": f"res://more/{slug}.webp"})
(HERE / "data/more_games.json").write_text(json.dumps(out, indent=1, ensure_ascii=False))
print(len(out["adult"]), "adult +", len(out["regular"]), "regular tiles")

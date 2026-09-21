#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Make each slot's covered plate and gallery thumb out of its REAL plate.

The shipping split has not changed (tools/gen_placeholder_cg.py documents it):

    frontend/cg/<slot>_locked.webp   the covered plate — ships in every build
    frontend/cg/<slot>_thumb.webp    gallery thumbnail of the covered plate
    frontend/cg/full/<slot>.webp     the uncensored plate — never in a free package

What changed is where the covered plate comes from. `gen_placeholder_cg.py` builds
BOTH halves out of the same PIL placeholder card, which was right in July when no
art existed — but it means that once `ops/install_plates.py` puts real renders in
`cg/full/`, the covered plates everyone actually sees are still grey cards reading
"not final art". Measured 2026-09-21: fifteen of the eighteen `_locked.webp` in
the tree were 5-7 KB placeholder cards, including all nine slots of the three
routes the game already OFFERS. So a player who had not unlocked a plate — which
is every player, at the moment the gallery first opens — saw a debug asset.

This covers the real plate instead: blur it, band it, label it. The point of a
covered plate is to show the shape of what is missing, and a blurred render does
that while a grey card does not.

It refuses to run on a slot whose `full/` file is still the placeholder, because
covering a placeholder just produces a blurrier placeholder and would quietly
undo the point. It decides that by regenerating the card and comparing — see
`is_placeholder`, and the false positive that made a heuristic unacceptable here.

    tools/cover_plates.py               # every slot with real art installed
    tools/cover_plates.py --only cg_fushen_heat
    tools/cover_plates.py --check       # non-zero if a covered plate is stale
"""
import argparse
import hashlib
import json
import io
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CG = os.path.join(HERE, "frontend", "cg")
FULL = os.path.join(CG, "full")
W, H = 1024, 576
THUMB = (320, 180)
FONT_DIR = "/usr/share/fonts/truetype/dejavu"

sys.path.insert(0, os.path.join(HERE, "tools"))
from gen_placeholder_cg import SLOTS  # noqa: E402  (slot -> route, how, note)


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(os.path.join(FONT_DIR, name), size)
    except OSError:
        return ImageFont.load_default()


def is_placeholder(slot, path):
    """A PIL card, not a render -- decided by REGENERATING the card and comparing.

    The first version of this counted distinct colours and called anything under
    12,000 a placeholder, on the grounds that the cards sit near 6,000 and renders
    near 50,000. That threshold immediately produced a false positive: the installed
    cg_ethan_heat was a genuine render at 4,833 colours, because the render itself
    had failed into a near-monochrome smear. A heuristic that cannot tell "placeholder"
    from "broken art" is worse than none -- it would have silently skipped the one
    slot that most needed looking at (ops memory, `verification-that-lies`).

    So this asks the question exactly: build the placeholder for this slot with the
    tool that writes them and see whether that is what is on disk. Re-encoding through
    WEBP is lossy, so the comparison is a mean absolute pixel difference with a small
    tolerance rather than a hash.
    """
    import numpy as np
    from gen_placeholder_cg import plate
    with Image.open(path) as im:
        cur = np.asarray(im.convert("RGB").resize((W, H), Image.LANCZOS)).astype(int)
    card = np.asarray(plate(slot, locked=False).convert("RGB")).astype(int)
    return abs(cur - card).mean() < 6.0


def cover(src):
    """Blur, band, label. Same visual grammar as the placeholder's locked half, so
    the gallery does not change shape when a slot gains real art."""
    im = Image.open(src).convert("RGB")
    if im.size != (W, H):
        scale = max(W / im.width, H / im.height)
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        left, top = (im.width - W) // 2, (im.height - H) // 2
        im = im.crop((left, top, left + W, top + H))
    im = im.filter(ImageFilter.GaussianBlur(18))
    d = ImageDraw.Draw(im)
    d.rectangle([0, H * 0.42, W, H * 0.58], fill=(12, 10, 16))
    d.text((W / 2, H * 0.50), "LOCKED", font=font(46, True), fill=(232, 122, 168), anchor="mm")
    return im


def encode(im, size, quality):
    buf = io.BytesIO()
    (im if size is None else im.resize(size, Image.LANCZOS)).save(buf, "WEBP", quality=quality)
    return buf.getvalue()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    # Three slots do NOT want a blur: ethan/luxingye/guyan's heat plates each have a
    # SEPARATELY RENDERED teaser, `<slot>_locked`, which is its own entry in
    # flutter_gen.PLATES with its own prompt and its own pick -- a softer composition of
    # the same moment, not a covered version of the explicit one. Blurring over those
    # threw away a rendered plate and replaced it with a smear, and
    # `ops/install_plates.py --check` caught it immediately: "cg_guyan_heat_locked: game
    # file is not the pick". Two tools writing one file; the renderer wins.
    own_teaser = set()
    try:
        picks = json.loads(open(os.path.join(
            HERE, "..", "..", "ops", "flutter_art", "picks.json"), encoding="utf-8").read())
        own_teaser = {k[:-len("_locked")] for k in picks if k.endswith("_locked")}
    except Exception as e:
        print("  !! could not read picks.json (%s); not skipping any teaser slots" % e)

    names = [a.only] if a.only else list(SLOTS)
    stale, skipped, wrote = [], [], 0
    for s in names:
        if s not in SLOTS:
            raise SystemExit("unknown slot %s" % s)
        if s in own_teaser:
            # Leave the rendered teaser alone -- but its THUMB still has to be made, and
            # made from the teaser. An earlier pass built these thumbs from the explicit
            # plate, so the gallery tile was a blur of the uncensored art sitting next to
            # a locked plate that was the soft teaser: two different pictures for one
            # slot, and the wrong one in the smaller, more public tile.
            teaser = os.path.join(CG, "%s_locked.webp" % s)
            dst = os.path.join(CG, "%s_thumb.webp" % s)
            if not os.path.isfile(teaser):
                skipped.append("%s: teaser slot with no _locked file" % s)
                continue
            with Image.open(teaser) as t:
                data = encode(t.convert("RGB"), THUMB, 80)
            if a.check:
                cur = open(dst, "rb").read() if os.path.isfile(dst) else b""
                if hashlib.sha256(cur).hexdigest() != hashlib.sha256(data).hexdigest():
                    stale.append("%s_thumb" % s)
            else:
                with open(dst, "wb") as f:
                    f.write(data)
                wrote += 1
            skipped.append("%s: rendered _locked teaser kept; thumb made from it" % s)
            continue
        src = os.path.join(FULL, "%s.webp" % s)
        if not os.path.isfile(src):
            skipped.append("%s: no plate in cg/full" % s)
            continue
        if is_placeholder(s, src):
            skipped.append("%s: cg/full is still the placeholder card" % s)
            continue
        im = cover(src)
        for suffix, size, q in (("_locked", None, 86), ("_thumb", THUMB, 80)):
            dst = os.path.join(CG, "%s%s.webp" % (s, suffix))
            data = encode(im, size, q)
            if a.check:
                cur = open(dst, "rb").read() if os.path.isfile(dst) else b""
                if hashlib.sha256(cur).hexdigest() != hashlib.sha256(data).hexdigest():
                    stale.append("%s%s" % (s, suffix))
            else:
                with open(dst, "wb") as f:
                    f.write(data)
                wrote += 1

    for line in skipped:
        print("  skip  " + line)
    if a.check:
        for n in stale:
            print("  !! %s is not the cover of the installed plate" % n)
        print("%d stale, %d slot(s) without real art" % (len(stale), len(skipped)))
        return 1 if stale else 0
    print("wrote %d file(s); %d slot(s) still on the placeholder" % (wrote, len(skipped)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

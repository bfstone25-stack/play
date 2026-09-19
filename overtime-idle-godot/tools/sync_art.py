#!/usr/bin/env python3
"""Import step: pull the parent's installed plates into assets/art/ for the Godot import.

    python3 tools/sync_art.py

Nothing is committed from here — assets/art/ is gitignored. The art lives in
play/office-landlord-x/frontend/assets/ (the parent), and this copies it by path at build
time so the Godot package can carry it. Art ceiling 3, reuse installed plates only: this
script never renders anything, it only copies what is already there.
"""
import pathlib, shutil, sys
HERE = pathlib.Path(__file__).resolve().parent.parent
SRC = HERE.parent / "office-landlord-x" / "frontend" / "assets"
DST = HERE / "assets" / "art"
DST.mkdir(parents=True, exist_ok=True)
n = 0
for f in list(SRC.glob("*.webp")) + list((SRC / "cg").glob("*.webp")):
    out = DST / f.name
    if not out.exists() or out.stat().st_mtime < f.stat().st_mtime:
        shutil.copy2(f, out); n += 1
print("sync_art: %d copied, %d present in %s" % (n, len(list(DST.glob("*.webp"))), DST))
if not (DST / "cg_mirei_lease.webp").exists():
    sys.exit("sync_art: parent art missing at %s" % SRC)

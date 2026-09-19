#!/usr/bin/env python3
"""Import step: cut the character faces out of the parent's installed tier-1 plates.

    python3 tools/sync_art.py

Art ceiling 3: this renders nothing. It reads play/silvertongue-x/frontend/assets/cg/cg1_<scenario>.png
(the installed, on-model plates), crops the rects recorded in tools/face_crops.json, and writes

    assets/faces/<who>.webp      360x240   card picture panel, affection row
    assets/portraits/<who>.webp  520x650   duel portrait, Home roster
    assets/art_sources.json      provenance: every output and the plate it was cut from

The outputs are committed (the Godot build needs them without running this), but nothing
is copied by hand: re-run the tool and they regenerate. The early ref renders in
ops/silvertongue_art/ref carry a hair halo and neck artefacts and are never a source.
"""
import json, pathlib, sys
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
PROJ = HERE.parent
PLATES = PROJ.parent / "silvertongue-x" / "frontend" / "assets" / "cg"
FACES = PROJ / "assets" / "faces"
PORTRAITS = PROJ / "assets" / "portraits"
SIZES = {"face": (360, 240), "bust": (520, 650)}
OUT = {"face": FACES, "bust": PORTRAITS}


def main() -> int:
    crops = json.loads((HERE / "face_crops.json").read_text())
    crops.pop("_", None)
    sources = {}
    for who, spec in crops.items():
        plate = PLATES / ("cg1_%s.png" % spec["scenario"])
        if not plate.is_file():
            sys.exit("sync_art: plate missing: %s" % plate)
        im = Image.open(plate).convert("RGB")
        for kind, folder in OUT.items():
            folder.mkdir(parents=True, exist_ok=True)
            box = spec[kind]
            w, h = SIZES[kind]
            out = folder / (who + ".webp")
            im.crop(box).resize((w, h), Image.LANCZOS).save(out, "WEBP", quality=88, method=6)
            rel = "play/silvertongue-x/frontend/assets/cg/" + plate.name
            sources[str(out.relative_to(PROJ))] = {"source": rel, "crop": box}
            print("  %-32s <- %s %s" % (out.relative_to(PROJ), plate.name, box))
    (PROJ / "assets" / "art_sources.json").write_text(json.dumps(sources, indent=1, sort_keys=True) + "\n")
    print("sync_art: %d files from %d plates" % (len(sources), len(crops)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Fail if any *_zh field in chars.json holds no CJK text.

Verification-that-lies lesson: a check that always reports "fine" is worse
than no check. This one is proven to fail — run it against the pre-fix
chars.json (git show HEAD~1:flutter/backend/chars.json) and it flags
routes[3..5]'s name_zh/title_zh/tag_zh/scene_zh as English.
"""
import json
import re
import sys
from pathlib import Path

CJK = re.compile(r"[一-鿿]")
PATH = Path(__file__).parent / "chars.json"


def walk(obj, path=""):
    bad = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            key_path = f"{path}.{k}" if path else k
            if k.endswith("_zh") and isinstance(v, str):
                if not CJK.search(v):
                    bad.append((key_path, v))
            bad.extend(walk(v, key_path))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            bad.extend(walk(v, f"{path}[{i}]"))
    return bad


def main():
    data = json.loads(PATH.read_text())
    bad = walk(data)
    if bad:
        print(f"FAIL: {len(bad)} _zh field(s) with no CJK characters in {PATH}:")
        for path, val in bad:
            print(f"  {path} = {val!r}")
        return 1
    print(f"OK: every _zh field in {PATH} contains CJK text.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

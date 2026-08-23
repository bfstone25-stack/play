#!/usr/bin/env python3
"""Generate an original grand theme version of 走向我."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

from generate_zh_walk_to_me import LYRICS

JOB = {
    "language": "zh",
    "bpm": 78,
    "key": "Eb major",
    "timesignature": "4",
    "duration": 145.0,
    "lyrics": LYRICS,
    "tags": (
        "original grand Mandarin television-romance main theme for a premium women-oriented game, entirely original "
        "melody harmony and arrangement, emotionally commanding adult female Mandarin lead vocal with clear diction, "
        "the singer begins close and almost alone as if admitting a secret she has held for years, sparse piano and "
        "low cello in the verse, each pre-chorus adds suspended harmony and rising inner voices while withholding the "
        "tonic, then the chorus opens into a majestic unforgettable melodic call on 走向我, broad live drums, deep bass, "
        "full cinematic string orchestra and layered female backing-vocal harmonies answering the title, rich thirds "
        "and sixths around the lead with a high countermelody in the final chorus, powerful harmonic lift and genuine "
        "scale without trailer bombast, a tasteful whole-step final-chorus modulation that feels earned, huge emotional "
        "release after long restraint, melody remains singable and human rather than virtuosic, iconic prestige Chinese "
        "romance drama production, no cute pop, no K-pop, no gospel choir, no musical theatre, no generic power-ballad "
        "cliché, no imitation or quotation of any existing song, singer, composer, chord sequence or arrangement"
    ),
}


def main():
    result = base.post("/prompt", {"prompt": base.workflow("zh-walk-to-me-grand", JOB)})
    prompt_id = result["prompt_id"]
    print(f"queued {prompt_id}", flush=True)
    while True:
        history = base.get("/history/" + prompt_id)
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            if status.get("completed"):
                print("complete", flush=True)
                return
            if status.get("status_str") == "error":
                raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
        time.sleep(5)


if __name__ == "__main__":
    main()

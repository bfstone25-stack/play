#!/usr/bin/env python3
"""Render five original, hummable regional love themes for Flutter."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

COMMON = (
    "original instrumental love theme for the moment two people finally choose each other, "
    "written as a complete timeless pop song without vocals, not ambient underscore, an immediately "
    "hummable eight-bar lead melody with a clear verse-like opening and an unforgettable chorus-like "
    "emotional arrival, simple enough to sing from memory after one listen but harmonically elegant, "
    "warm sweet belonging and the certainty of having found your person, recurring restrained four-note "
    "Flutter identity motif transformed into the first phrase of a larger original melody, dynamic arc "
    "from private closeness to radiant emotional release, premium organic recording, usable later as piano, "
    "music-box, acoustic and bittersweet story variations, seamless loop, no vocals, no chiptune, no 8-bit, "
    "no EDM, no generic stock romance, no quotation or imitation of any existing song"
)

EDITIONS = {
    "en-my-moment": {
        "bpm": 78, "key": "D major",
        "tags": (
            "modern English-language prestige romance theme, intimate piano opening, warm Rhodes, melodic "
            "electric bass, restrained live drums, cello and luminous strings, adult tenderness with a subtle "
            "neo-soul pocket, broad soaring chorus melody without bombast, sunrise after a long slow-burn love"
        ),
    },
    "zh-my-moment": {
        "bpm": 72, "key": "A major",
        "tags": (
            "contemporary Chinese and Taiwanese urban romance drama love theme, clear lyrical piano melody, "
            "delicate acoustic guitar, warm bass, live brushed drums and sweeping strings, sweet cared-for "
            "feeling, emotionally direct Mandopop ballad architecture, a chorus that feels instantly familiar "
            "yet completely original, the relief of finally being openly cherished"
        ),
    },
    "ja-my-moment": {
        "bpm": 80, "key": "E major",
        "tags": (
            "premium Japanese women-oriented romance drama and otome love theme, memorable singing piano motif, "
            "melodic bass, clean guitar, live drums and expressive chamber strings, Japanese pop-drama harmonic "
            "color with add9 warmth and elegant secondary dominants, controlled verse followed by a heart-opening "
            "chorus, unmistakably Japanese emotional storytelling, rain ending as two hands finally meet"
        ),
    },
    "es-my-moment": {
        "bpm": 88, "key": "G major",
        "tags": (
            "contemporary Spanish romantic drama love theme, close nylon guitar stating a bold singable melody, "
            "warm piano, upright bass, delicate cajón brushes and cinematic strings, Mediterranean candor and "
            "equal chemistry, affectionate rhythmic lift rather than dance music, a glowing chorus made for "
            "walking toward each other without hesitation"
        ),
    },
    "pt-BR-my-moment": {
        "bpm": 84, "key": "E major",
        "tags": (
            "contemporary Brazilian love theme with sophisticated MPB-pop harmony, unforgettable nylon-guitar "
            "and piano melody, Rhodes, mellow electric bass, featherlight pandeiro brushes and warm strings, "
            "natural sunlit intimacy and gentle syncopation, emotionally open chorus without carnival cliché, "
            "the sound of choosing an ordinary shared life and knowing it is extraordinary"
        ),
    },
}


def main():
    for name, item in EDITIONS.items():
        job = {"bpm": item["bpm"], "key": item["key"], "tags": COMMON + ", " + item["tags"]}
        result = base.post("/prompt", {"prompt": base.workflow(name, job)})
        prompt_id = result["prompt_id"]
        print(f"{name}: queued {prompt_id}", flush=True)
        while True:
            history = base.get("/history/" + prompt_id)
            if prompt_id in history:
                status = history[prompt_id].get("status", {})
                if status.get("completed"):
                    print(f"{name}: complete", flush=True)
                    break
                if status.get("status_str") == "error":
                    raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
            time.sleep(5)


if __name__ == "__main__":
    main()

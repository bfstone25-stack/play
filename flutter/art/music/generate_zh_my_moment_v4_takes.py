#!/usr/bin/env python3
"""Create three melody-first commercial takes for Mandarin My Moment."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

from generate_zh_my_moment_v3 import LYRICS

COMMON = (
    "original premium commercial Mandarin pop love song for a contemporary Chinese women-oriented romance game, "
    "bright warm adult female Mandarin vocal with flawless clear diction, title hook in the opening and on beat one "
    "of every chorus, melody is the absolute priority: instantly beautiful on first listen, emotionally inevitable, "
    "compact and easy to sing from memory, verses stay low and conversational, pre-chorus creates real melodic tension, "
    "chorus opens into a clear four-syllable hook on 刚好是你 followed by a short pentatonic answer phrase, the second "
    "刚好是你 varies upward rather than mechanically repeating, strong contrast between sections, no meandering melody, "
    "no overlong notes, no vocal acrobatics, premium modern production, not K-pop idol dance, not Western adult "
    "contemporary, not rustic internet pop, no imitation or quotation of any existing song"
)

TAKES = {
    "a": {
        "bpm": 86, "key": "Bb major",
        "style": (
            "first-listen radiant C-pop hit, chorus begins with a confident upward melodic leap then resolves through "
            "a tender descending pentatonic phrase, crisp R&B-pop drums, warm bass, electric piano, muted guitar and "
            "luminous strings, immediate butterflies and joyful recognition, concise radio-ready arrangement"
        ),
    },
    "b": {
        "bpm": 82, "key": "Db major",
        "style": (
            "silky contemporary Mandarin neo-soul love song, sensual but innocent melodic pocket, syncopated verse "
            "giving way to a simple sustained chorus hook, Rhodes, rounded bass, rim-click drums, clean guitar and "
            "restrained chamber strings, sophisticated feminine warmth with an unforgettable melodic payoff"
        ),
    },
    "c": {
        "bpm": 80, "key": "G major",
        "style": (
            "timeless Taiwanese and Mandarin romance-drama melodic instinct reimagined with 2026 production, a direct "
            "heart-catching chorus that feels emotionally familiar but is fully original, acoustic guitar, piano, "
            "melodic bass, live drums and modern airy strings, youthful sincerity without retro sonic nostalgia"
        ),
    },
}


def main():
    for take, item in TAKES.items():
        job = {
            "language": "zh", "bpm": item["bpm"], "key": item["key"],
            "timesignature": "4", "duration": 126.0, "lyrics": LYRICS,
            "tags": COMMON + ", " + item["style"],
        }
        name = f"zh-my-moment-vocal-v4{take}"
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

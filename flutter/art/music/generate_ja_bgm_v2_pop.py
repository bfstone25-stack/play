#!/usr/bin/env python3
"""Render five stronger Japanese-romance V2 auditions without replacing V1."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

IDENTITY = (
    "instrumental soundtrack for a premium Japanese women-oriented romance drama and otome game, "
    "unmistakably contemporary Japanese emotional storytelling, a memorable singable four-note Flutter "
    "leitmotif, lyrical melody rather than ambient wallpaper, Japanese pop-drama harmonic language with "
    "bittersweet IV-V-iii-vi motion, add9 and suspended colors, tasteful secondary dominants, piano and "
    "expressive chamber strings, beautifully recorded organic instruments, cinematic dynamic arc, "
    "emotionally restrained but capable of a sudden swell, seamless game loop, no vocals, no chiptune, "
    "no 8-bit, no EDM, no lo-fi study beat, no tourist shamisen or shakuhachi cliché, no generic corporate music"
)

SCENES = {
    "main": {
        "bpm": 78, "key": "E major",
        "tags": (
            "prestige Japanese romance opening theme, immediate elegant piano motif, forward-moving live "
            "drum kit with delicate hi-hat, melodic bass, soaring but controlled strings, rain clearing over "
            "Tokyo at first light, anticipation of a life-changing encounter, emotionally irresistible title music"
        ),
    },
    "conversation": {
        "bpm": 72, "key": "A major",
        "tags": (
            "Japanese romantic television dialogue underscore, warm piano, clean acoustic guitar, pizzicato "
            "strings and soft brushed kit, intelligent gentle momentum, tiny melodic replies that feel like "
            "two people noticing each other, playful restraint, plenty of space under speech"
        ),
    },
    "intimate": {
        "bpm": 62, "key": "D major",
        "tags": (
            "late-night Japanese confession scene, close felt piano and breathing cello, violin harmonics and "
            "soft string bloom, rubato opening that settles into a quiet heartbeat, tender melody held back until "
            "the emotional release, intimacy conveyed through pauses and one unfinished phrase"
        ),
    },
    "tension": {
        "bpm": 84, "key": "F minor",
        "tags": (
            "inner romantic dilemma at the decisive choice, not an argument and not action suspense, irregular "
            "heartbeat piano ostinato, alternating relative-major hope and minor-key retreat, rising string line "
            "that repeatedly stops before resolving, breathless pauses, approach then withdrawal, the feeling of "
            "wanting to send a message and deleting it, fluttering uncertainty and emotional vertigo"
        ),
    },
    "melancholy": {
        "bpm": 58, "key": "B minor",
        "tags": (
            "Japanese romantic drama ending after the last train, rain-muted piano, solo cello and distant "
            "strings, a clear nostalgic melody with elegant Japanese harmonic turns, private sadness rather than "
            "despair, memory returning in waves, final phrase left gently unresolved"
        ),
    },
}


def main():
    for scene, item in SCENES.items():
        job = {"bpm": item["bpm"], "key": item["key"], "tags": IDENTITY + ", " + item["tags"]}
        name = f"ja-v2-{scene}"
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

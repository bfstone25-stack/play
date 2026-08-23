#!/usr/bin/env python3
"""Render the regional × dramatic-scene BGM matrix with Pop ACE-Step 1.5."""
import copy
import importlib.util
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

SCENES = {
    "main": {
        "suffix": (
            "confident opening theme, immediate identity in the first five seconds, "
            "forward motion, elegant hook, suitable behind a title screen and route selection"
        ),
        "bpm": 6,
    },
    "conversation": {
        "suffix": (
            "light conversational underscore, playful human rhythm, room for dialogue, "
            "subtle anticipation, no dominant melody, comfortable long-session game loop"
        ),
        "bpm": 2,
    },
    "intimate": {
        "suffix": (
            "close late-night intimacy, slower breathing, tactile acoustic detail, "
            "emotional warmth without sentimentality, restrained romantic payoff"
        ),
        "bpm": -4,
    },
    "tension": {
        "suffix": (
            "romantic conflict and difficult choice, controlled pulse, unresolved harmony, "
            "desire under pressure, cinematic tension without action-trailer drums"
        ),
        "bpm": 10,
    },
}

# Strengthen instantly recognizable market identity without reducing a culture
# to souvenir instruments.
REGIONAL = {
    "en": (
        "modern London-New York prestige romance, dry live drums, tasteful neo-soul pocket, "
        "warm Rhodes and electric bass, adult confidence and sly humor"
    ),
    "zh": (
        "contemporary Shanghai-Chengdu urban romance, polished Mandopop film-score language, "
        "felt piano, acoustic guitar and warm strings, attentive everyday tenderness"
    ),
    "ja": (
        "contemporary Tokyo indie romance, Japanese minimalism, prepared felt piano, "
        "vibraphone and muted upright bass, rain-lit negative space and meaningful pauses"
    ),
    "es": (
        "contemporary Madrid romance, close-miked nylon guitar, cajón brushes and upright bass, "
        "verbal chemistry, heat and sophisticated rhythmic push-pull"
    ),
    "pt-BR": (
        "contemporary Rio-São Paulo romance, modern MPB harmonic language, nylon guitar, "
        "Rhodes, mellow bass and pandeiro brushes, golden-hour ease and spontaneous warmth"
    ),
}


def build_jobs():
    jobs = {}
    for edition, edition_spec in base.EDITIONS.items():
        for scene, scene_spec in SCENES.items():
            item = copy.deepcopy(edition_spec)
            item["bpm"] = max(48, min(104, item["bpm"] + scene_spec["bpm"]))
            item["tags"] = (
                REGIONAL[edition] + ", " + scene_spec["suffix"] +
                ", recurring restrained four-note Flutter identity motif, instrumental, "
                "premium cinematic recording, organic instruments, seamless game loop, "
                "no vocals, no chiptune, no 8-bit, no generic corporate music, no festival EDM"
            )
            jobs[f"{edition}-{scene}"] = item
    return jobs


def main():
    original = base.EDITIONS
    try:
        base.EDITIONS = build_jobs()
        base.main()
    finally:
        base.EDITIONS = original


if __name__ == "__main__":
    main()

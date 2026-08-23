#!/usr/bin/env python3
"""Generate Flutter's five instrumental edition themes with Pop's ComfyUI ACE-Step 1.5."""
import json
import random
import time
import urllib.request

COMFY = "http://127.0.0.1:8188"
SECONDS = 72.0

EDITIONS = {
    "en": {
        "bpm": 66, "key": "D minor",
        "tags": (
            "instrumental cinematic neo-soul romance, intimate felt piano, warm cello, "
            "soft brushed drums, subtle electric bass, wine-bar elegance at dawn, mature "
            "slow-burn attraction, spacious expensive production, memorable restrained "
            "four-note motif, seamless game soundtrack loop, no vocals, no chiptune, "
            "no 8-bit, no EDM lead, no bright synth arpeggio"
        ),
    },
    "zh": {
        "bpm": 62, "key": "A major",
        "tags": (
            "instrumental contemporary Chinese urban romance soundtrack, warm felt piano, "
            "delicate acoustic guitar harmonics, soft cello, distant night-city ambience, "
            "tender cared-for feeling after a long day, sweet but tasteful, intimate and "
            "cinematic, memorable restrained four-note motif, seamless game soundtrack loop, "
            "no vocals, no guzheng cliché, no chiptune, no 8-bit, no EDM"
        ),
    },
    "ja": {
        "bpm": 54, "key": "E minor",
        "tags": (
            "instrumental modern Japanese romantic film score, rain at the last train, "
            "sparse felt piano, bowed vibraphone, muted upright bass, subtle field-recording "
            "texture, long silences and unresolved tenderness, minimal Tokyo art-house mood, "
            "memorable restrained four-note motif, seamless game soundtrack loop, no vocals, "
            "no anime opening, no chiptune, no 8-bit, no bright synthesizer"
        ),
    },
    "es": {
        "bpm": 86, "key": "G minor",
        "tags": (
            "instrumental contemporary Madrid romantic drama, nylon guitar played close to "
            "the microphone, hand percussion, warm upright bass, sharp flirtatious pauses, "
            "midnight heat and witty tension, cinematic not tourist flamenco, memorable "
            "restrained four-note motif, seamless game soundtrack loop, no vocals, no "
            "chiptune, no 8-bit, no festival EDM"
        ),
    },
    "pt-BR": {
        "bpm": 78, "key": "E major",
        "tags": (
            "instrumental contemporary Brazilian romance, intimate nylon guitar, soft "
            "pandeiro brushes, warm electric piano and mellow bass, golden-hour street life, "
            "natural laughter and relaxed closeness, modern tasteful MPB influence without "
            "carnival cliché, memorable restrained four-note motif, seamless game soundtrack "
            "loop, no vocals, no chiptune, no 8-bit, no EDM"
        ),
    },
}


def node(class_type, **inputs):
    return {"class_type": class_type, "inputs": inputs}


def workflow(edition, spec):
    seed = random.randrange(2**48)
    duration = spec.get("duration", SECONDS)
    return {
        "1": node("UNETLoader", unet_name="acestep_v1.5_turbo.safetensors", weight_dtype="default"),
        "2": node("DualCLIPLoader", clip_name1="qwen_0.6b_ace15.safetensors",
                  clip_name2="qwen_4b_ace15.safetensors", type="ace", device="default"),
        "3": node("VAELoader", vae_name="ace_1.5_vae.safetensors"),
        "4": node("TextEncodeAceStepAudio1.5", clip=["2", 0], tags=spec["tags"],
                  lyrics=spec.get("lyrics", "[Instrumental]"), seed=seed, bpm=spec["bpm"],
                  duration=duration, timesignature=spec.get("timesignature", "4"),
                  language=spec.get("language", "en"),
                  keyscale=spec["key"],
                  # Detailed human-authored briefs make the 4B audio-code
                  # planner unnecessary here; disabling it avoids hours of CPU
                  # sampling while preserving the actual diffusion music model.
                  generate_audio_codes=False, cfg_scale=2.0, temperature=.82,
                  top_p=.9, top_k=0, min_p=0),
        "5": node("ConditioningZeroOut", conditioning=["4", 0]),
        "6": node("EmptyAceStep1.5LatentAudio", seconds=duration, batch_size=1),
        "7": node("ModelSamplingAuraFlow", model=["1", 0], shift=3),
        "8": node("KSampler", model=["7", 0], positive=["4", 0], negative=["5", 0],
                  latent_image=["6", 0], seed=seed, steps=8, cfg=1,
                  sampler_name="euler", scheduler="simple", denoise=1),
        "9": node("VAEDecodeAudio", samples=["8", 0], vae=["3", 0]),
        "10": node("SaveAudioOpus", audio=["9", 0],
                   filename_prefix=f"flutter_bgm/{edition}", quality="192k"),
    }


def post(path, payload):
    req = urllib.request.Request(
        COMFY + path,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


def get(path):
    with urllib.request.urlopen(COMFY + path, timeout=30) as response:
        return json.load(response)


def main():
    for edition, spec in EDITIONS.items():
        result = post("/prompt", {"prompt": workflow(edition, spec)})
        prompt_id = result["prompt_id"]
        print(f"{edition}: queued {prompt_id}", flush=True)
        while True:
            history = get("/history/" + prompt_id)
            if prompt_id in history:
                status = history[prompt_id].get("status", {})
                if status.get("completed"):
                    print(f"{edition}: complete", flush=True)
                    break
                if status.get("status_str") == "error":
                    raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
            time.sleep(5)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate only the restrained low-octave verse for the chorus-first master."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

JOB = {
    "language": "zh",
    "bpm": 82,
    "key": "F major",
    "timesignature": "4",
    "duration": 42.0,
    "lyrics": """[LOW VERSE — ADULT FEMALE CHEST VOICE]
我把心事　藏进灯火
等一句话　穿过夜色
每次靠近　又怕惊动
那个不敢　承认的我

[LOW PRE-CHORUS — GRADUALLY RISING]
如果你的沉默
也在等一个结果
别再让这一秒
从我们指间滑落""",
    "tags": (
        "middle section of an original Mandarin female lyrical-rock song, verse and pre-chorus only, mature adult "
        "female singer in a dark low chest register exactly one octave below a later rock chorus, intimate controlled "
        "delivery with clear Mandarin diction and restrained ache, no belting in the verse, sparse low piano, muted "
        "electric guitar, warm bass and cello, brushed kick entering gradually, harmonic tension slowly rising in the "
        "last four lines without reaching the chorus, same 82 BPM F-major live-band prestige romance production, "
        "vocals begin immediately with 我把心事, no instrumental intro, no chorus, no repeated 走向我 hook, no high "
        "female voice, no cute breathy girl, no K-pop, no full orchestral climax"
    ),
}


def main():
    workflow = base.workflow("zh-low-verse-v2-planned", JOB)
    # The fast path frequently treats section/lyric instructions as optional
    # and returned an instrumental first take. Enable ACE-Step's audio-code
    # planner here so the sung Mandarin verse is structurally mandatory.
    workflow["4"]["inputs"]["generate_audio_codes"] = True
    workflow["4"]["inputs"]["cfg_scale"] = 1.0
    workflow["4"]["inputs"]["temperature"] = 1.0
    # Pop only has ~4 GB free while the Mingxi service is resident. The 8.38 GB
    # Qwen-4B planner is therefore forced onto CPU. This simple, tightly
    # specified verse can use the 0.6B planner in both ACE text-encoder slots,
    # keeping planning on GPU without disrupting the live LLM service.
    workflow["2"]["inputs"]["clip_name2"] = "qwen_0.6b_ace15.safetensors"
    result = base.post("/prompt", {"prompt": workflow})
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

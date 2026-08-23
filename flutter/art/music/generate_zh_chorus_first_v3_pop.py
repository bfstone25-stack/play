#!/usr/bin/env python3
"""Render the Mandarin theme with a non-negotiable full-force opening chorus."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

# Keep the first token singable: no prose or intro section before the chorus.
LYRICS = """[CHORUS — FIRST SOUND OF THE RECORDING — HIGH OCTAVE ROCK BELT]
走向我——
走向我——
就现在　走向我
穿过人海　穿过沉默
如果你也曾　为我停留
别让我们　只剩错过
走向我——
像我一直　走向你

[VERSE — SUDDEN DROP ONE OCTAVE — RESTRAINED]
我把心事　藏进灯火
等一句话　穿过夜色
每次靠近　又怕惊动
那个不敢　承认的我

[PRE-CHORUS — RISING]
如果你的沉默
也在等一个结果
别再让这一秒
从我们指间滑落

[FINAL CHORUS — HIGH OCTAVE — BIGGER FEMALE CHOIR]
走向我——
（走向我）
就现在　走向我
穿过人海　穿过沉默
如果你也曾　为我停留
别让我们　只剩错过
走向我——
（我走向你）
像我一直　走向你
不用永远　不用承诺
这一刻请你　选择我

[FINAL SHOUT AND CHOIR]
走向我——
（我正走向你）"""

JOB = {
    "language": "zh",
    "bpm": 82,
    "key": "F major",
    "timesignature": "4",
    "duration": 105.0,
    "lyrics": LYRICS,
    "tags": (
        "MANDARIN FEMALE-LED LYRICAL ROCK SONG; ABSOLUTELY NO INTRO, NO PRELUDE, NO PIANO OPENING, NO INSTRUMENTAL "
        "BARS BEFORE THE VOCAL; at timestamp 0:00 the first audible event is an adult female rock singer belting "
        "走向我 in a high octave over the entire band already at full power; chorus-first reverse song form; opening "
        "chorus is the emotional and dynamic peak, huge live rock drums from beat one, crashing cymbals, driving "
        "melodic bass, wide overdriven electric guitars, grand orchestra and an unmistakable wall of real female "
        "backing vocals; mature Chinese rock diva timbre, dark grainy chest resonance, strong mixed-voice belt, raw "
        "rasp and near-breaking emotional urgency, fierce and cathartic but still accurately pitched; NOT a sweet "
        "soft breathy girl, NOT delicate, NOT whispery, NOT cute; after the complete opening chorus the arrangement "
        "drops suddenly and the same singer descends a full octave into a slow restrained intimate verse with sparse "
        "bass, low piano and cello; tension rebuilds into a final chorus even higher and larger than the first, with "
        "three-part female harmonies, octave doubles, shouted responses and soaring countermelody; catchy broad "
        "Mandarin title hook, premium live-band Chinese television-romance production, vocals dominant in the mix; "
        "no instrumental intro, no ballad prelude, no verse-first form, no gentle female vocal, no K-pop, no metal, "
        "no trailer score, no imitation or quotation of any existing song or singer"
    ),
}


def main():
    result = base.post(
        "/prompt",
        {"prompt": base.workflow("zh-chorus-first-v3", JOB)},
    )
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

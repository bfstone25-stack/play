#!/usr/bin/env python3
"""Generate a genuinely sung, chorus-first Mandarin lyrical-rock theme."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Chorus - Starts Immediately, Female Lead and Audible Female Backing Vocals]
走向我
（走向我）
就现在 走向我
穿过人海 穿过沉默
如果你也曾 为我停留
别让我们 只剩错过

[Verse - Solo Female Lead]
我把心事 藏进灯火
等一句话 穿过夜色
每次靠近 又怕惊动
那个不敢 承认的我

[Pre-Chorus - Harmonies Enter and Rise]
如果你的沉默
也在等一个结果
别再让这一秒
从我们指间滑落

[Final Chorus - Full Lead, Three-Part Female Harmonies and Choir]
走向我
（走向我）
就现在 走向我
穿过人海 穿过沉默
如果你也曾 为我停留
别让我们 只剩错过

走向我
（我走向你）
像我一直 走向你
不用永远 不用承诺
这一刻请你 选择我

[Final Vocal Tag - A Cappella Harmony]
走向我
（我正走向你）"""

JOB = {
    "language": "zh",
    "bpm": 76,
    "key": "D major",
    "timesignature": "4",
    "duration": 112.0,
    "lyrics": LYRICS,
    "tags": (
        "original premium Mandarin lyrical-rock love theme, SONG WITH REAL SUNG VOCALS, zero instrumental intro, "
        "an expressive adult female Mandarin lead sings the title 走向我 in the very first second, chorus-first form, "
        "clear intelligible lyrics, immediately memorable broad rising title hook followed by a tender descending "
        "pentatonic answer, distinctly audible human female backing singers answering every parenthetical phrase, "
        "three-part female harmonies in thirds and sixths, low-octave vocal support, soaring high female "
        "countermelody and a real massed female vocal chorus in the final refrain, intimate piano-led verse, then "
        "majestic live drums, melodic bass, wide lyrical electric guitars, grand piano and cinematic strings, "
        "emotional Chinese television-romance scale, powerful cathartic release, polished radio mix with lead and "
        "backing vocals clearly louder than the instruments, singable and heartfelt rather than virtuosic, no "
        "instrumental-only output, no wordless choir pad, no whisper singing, no metal, no trailer music, no K-pop, "
        "no imitation or quotation of any existing song or singer"
    ),
}


def main():
    for suffix in ("a", "b"):
        result = base.post(
            "/prompt",
            {"prompt": base.workflow(f"zh-chorus-vocal-v2{suffix}", JOB)},
        )
        prompt_id = result["prompt_id"]
        print(f"{suffix}: queued {prompt_id}", flush=True)
        while True:
            history = base.get("/history/" + prompt_id)
            if prompt_id in history:
                status = history[prompt_id].get("status", {})
                if status.get("completed"):
                    print(f"{suffix}: complete", flush=True)
                    break
                if status.get("status_str") == "error":
                    raise RuntimeError(json.dumps(history[prompt_id], ensure_ascii=False))
            time.sleep(5)


if __name__ == "__main__":
    main()

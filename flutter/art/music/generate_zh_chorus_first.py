#!/usr/bin/env python3
"""Generate chorus-first Mandarin theme candidates with explicit vocal harmony."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Opening Chorus - Full Lead and Layered Harmonies]
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

[Instrumental Drop]

[Verse 1 - Solo]
我学会把想念
说成一句 你还好吗
学会在人群里面
看见你却不说话
那些差一点的拥抱
差一点留下的话
我都收好
假装已经放下

[Pre-Chorus - Harmony Enters]
可是你一回头
（一回头）
我练习好的告别
全都哑了

[Chorus - Lead with Harmony Answers]
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

[Verse 2 - Solo]
我不是没想过
从你的世界里离开
只是每一条远路
最后都绕回你窗外
你记得我的沉默
也看懂我的逞强
为什么还要
把真心藏起来

[Pre-Chorus - Rising Harmony]
如果你也害怕
（别害怕）
就带着害怕过来
不要回答

[Bridge - Lead and Distant Answer]
一步就好
（一步就好）
剩下的路
我们一起走

[Final Chorus - Octave Lead, Full Harmony Choir]
走向我
（终于你走向我）
就现在 走向我
穿过人海 穿过沉默
所有等待 所有错过
终于换来 你选择我
走向我
（我走向你）
这一次都别再躲
不必永远 不必承诺
你的手握住我
就已经足够

[Outro Harmony]
走向我
（我正走向你）"""

COMMON = (
    "entirely original premium Mandarin television-romance main theme, must begin immediately with the complete "
    "chorus hook at full emotional scale before any verse, no atmospheric intro and no slow verse opening, first "
    "audible sung words are 走向我, unmistakably beautiful highly singable title melody in the first two seconds, "
    "adult female Mandarin lead vocal plus clearly audible arranged female backing vocals from the opening chorus, "
    "parenthetical lyric lines are sung by harmony voices as answers, real three-part vocal harmony in thirds and "
    "sixths rather than doubled unison, opening chorus already powerful then arrangement drops dramatically to solo "
    "verse, every return grows, final chorus adds octave lead and soaring independent upper countermelody, full live "
    "drums with tom fills and cymbal lift, deep bass, grand piano, full cinematic strings and restrained brass warmth, "
    "majestic emotional scale earned through harmonic tension and release, memorable human melody for ordinary people "
    "to sing, Chinese lyric stresses respected, no cute jingle, no whisper-pop, no K-pop, no generic Western power "
    "ballad, no imitation or quotation of any existing song melody harmony progression arrangement singer or composer"
)

TAKES = {
    "a": {
        "bpm": 76, "key": "C major",
        "style": (
            "title hook begins with a bold ascending fourth on 走向我 and lands on a long open vowel, answer phrase "
            "descends in a graceful pentatonic arc, broad timeless Chinese drama melody, orchestral pop with modern depth"
        ),
    },
    "b": {
        "bpm": 80, "key": "Eb major",
        "style": (
            "title hook begins on a strong high scale degree and repeats with a higher answering phrase, immediate "
            "goosebumps and dignified urgency, contemporary Chinese cinematic soul with rhythmic piano and vast strings"
        ),
    },
}


def main():
    for take, item in TAKES.items():
        job = {
            "language": "zh", "bpm": item["bpm"], "key": item["key"], "timesignature": "4",
            "duration": 142.0, "lyrics": LYRICS, "tags": COMMON + ", " + item["style"],
        }
        name = f"zh-chorus-first-{take}"
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

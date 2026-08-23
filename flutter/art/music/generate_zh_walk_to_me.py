#!/usr/bin/env python3
"""Generate two original melody takes for 走向我, a new Mandarin love theme."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Verse 1]
我学会把想念
说成一句 你还好吗
学会在人群里面
看见你却不说话
那些差一点的拥抱
差一点留下的话
我都收好 假装已经放下

[Pre-Chorus]
可是你一回头
我练习好的告别 全都哑了

[Chorus]
走向我 现在就走向我
别让爱只剩擦肩而过
我没有要你 许诺什么
只要这一刻 你真的选择我
走向我 慢一点走向我
让我看清 你眼里的我
多少次转身 多少次错过
都为了今天 你走向我

[Verse 2]
我不是没想过
从你的世界里离开
只是每一条远路
最后都绕回你窗外
你记得我的沉默
也看懂我的逞强
为什么还要 把真心藏起来

[Pre-Chorus]
如果你也害怕
就带着害怕过来 不要回答

[Chorus]
走向我 现在就走向我
别让爱只剩擦肩而过
我没有要你 许诺什么
只要这一刻 你真的选择我
走向我 慢一点走向我
让我看清 你眼里的我
多少次转身 多少次错过
都为了今天 你走向我

[Bridge]
时间没有停下
可我不想再把爱 留给想象
一步就好
剩下的路 我们一起走吧

[Final Chorus]
走向我 终于你走向我
穿过人海 穿过所有沉默
不必说永远 永远是什么
你的手握住我 就已经足够
走向我 像我走向你
这一次我们都没有躲
多少次等待 多少次错过
终于换来此刻 你走向我

[Outro]
走向我
我也正走向你"""

COMMON = (
    "original emotionally irresistible Mandarin television-romance theme song for a premium women-oriented game, "
    "a specific adult woman finally saying the one thing she can no longer leave unsaid, intimate natural female "
    "Mandarin vocal with clear diction and emotional authority, restrained almost-spoken verses, a pre-chorus that "
    "suspends time, then a chorus that feels like the heart breaking open, the three-syllable title 走向我 is the "
    "unforgettable melodic call and returns with increasing meaning, melody must be beautiful and inevitable on first "
    "listen yet easy for ordinary listeners to sing, genuine dramatic yearning followed by mutual choice in the final "
    "chorus, sophisticated contemporary production that preserves Chinese lyrical space, no cute commercial jingle, "
    "no K-pop, no douyin novelty hook, no Western adult-contemporary template, no imitation or quotation of any "
    "existing song, composer, singer, soundtrack, melody, harmony or arrangement"
)

TAKES = {
    "a": {
        "bpm": 76, "key": "D major",
        "style": (
            "timeless Mandarin drama-song architecture with 2026 sonic detail, piano-led intro, low warm cello, acoustic "
            "guitar, melodic bass and live drums entering gradually, chorus title rises a perfect fourth like a human "
            "plea then answers downward, strings bloom only after the second title call, powerful without shouting"
        ),
    },
    "b": {
        "bpm": 72, "key": "F major",
        "style": (
            "spacious modern Chinese chamber-pop ballad, heartbeat piano and restrained electric bass, brushed drums, "
            "subtle ruan-like plucked overtones and cinematic strings, title melody begins on a held note then falls "
            "through a memorable pentatonic curve, more vulnerable and intimate before a luminous final release"
        ),
    },
}


def main():
    for take, item in TAKES.items():
        job = {
            "language": "zh", "bpm": item["bpm"], "key": item["key"], "timesignature": "4",
            "duration": 138.0, "lyrics": LYRICS, "tags": COMMON + ", " + item["style"],
        }
        name = f"zh-walk-to-me-{take}"
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

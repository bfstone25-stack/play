#!/usr/bin/env python3
"""Regenerate the Mandarin My Moment with a distinct modern Chinese identity."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Verse 1]
城市熄了灯以后
我还习惯一个人走
把没说出口的温柔
藏进每一次问候

[Pre-Chorus]
你却记得我的沉默
比我记得还要清楚
原来有人不问理由
也愿意陪我停留

[Chorus]
我的心终于有了归期
绕过多少人海 刚好是你
不用把永远 一次说尽
只要睁开眼 你还在这里
我的心终于有了归期
所有小心翼翼 都被你抱紧
明天会怎样 我不再逃避
因为走到最后 刚好是你

[Verse 2]
你把寻常的日子
变成我舍不得的故事
不是烟火多么华丽
是你看见真实的自己

[Pre-Chorus]
如果夜忘了天明
如果路忘了姓名
我会循着你的呼吸
回到最安心的风景

[Chorus]
我的心终于有了归期
绕过多少人海 刚好是你
不用把永远 一次说尽
只要睁开眼 你还在这里
我的心终于有了归期
所有小心翼翼 都被你抱紧
明天会怎样 我不再逃避
因为走到最后 刚好是你

[Bridge]
没有完美对白
只有你的手 向我伸来

[Final Chorus]
我的心终于有了归期
这一次我愿意 相信欢喜
世界再拥挤 我也认得你
因为走到最后 刚好是你"""

JOB = {
    "language": "zh",
    "bpm": 68,
    "key": "F# major",
    "timesignature": "6",
    "duration": 132.0,
    "lyrics": LYRICS,
    "tags": (
        "original premium 2026 Mandarin love song for a contemporary Chinese women-oriented urban romance, "
        "distinct from Western adult contemporary and distinct from K-pop, modern Chinese neo-soul meeting "
        "new-Chinese chamber pop, graceful lilting six-eight pulse, memorable pentatonic-leaning vocal melody "
        "shaped naturally around Mandarin tones, intimate expressive adult female Mandarin singer with clear "
        "diction and restrained emotion, conversational low-register verse, pre-chorus that gathers breath, "
        "a concise instantly singable chorus whose title hook feels inevitable, warm electric piano, modern "
        "subtle R&B bass and drums, sparse ruan or pipa-like plucked harmonics as a contemporary texture, cello "
        "and silk-like chamber strings blooming only at the chorus, sweet certainty of being remembered and "
        "chosen, culturally recognizable without costume-drama cliché, no four-on-the-floor beat, no arena "
        "ballad, no English-pop chord-and-melody contour, no K-pop idol production, no douyin novelty hook, "
        "no rustic internet-pop cliché, no vocal acrobatics, no imitation or quotation of any existing song"
    ),
}


def main():
    result = base.post("/prompt", {"prompt": base.workflow("zh-my-moment-vocal-v2", JOB)})
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

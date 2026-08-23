#!/usr/bin/env python3
"""Generate a commercial, hook-first Mandarin My Moment while retaining taste."""
import importlib.util
import json
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

LYRICS = """[Intro Hook]
刚好是你
刚好是你

[Verse 1]
我把晚安写了又删
你却问我 今天累不累
城市那么多人来往
只有你记得 我的口味

[Pre-Chorus]
不用猜 不用追
你在身边 心就慢慢归位

[Chorus]
刚好是你 刚好是你
人海里一眼就认出你
不是奇迹 是每个朝夕
把我的小心翼翼 都抱紧
刚好是你 还是你
让我开始期待明天来临
不用说永远 不用证明
这一刻我愿意 走向你

[Post-Chorus]
刚好是你
心终于有了归期

[Verse 2]
你把伞往我这边移
自己半边肩淋着雨
原来最浪漫的事情
是平凡都被你放在心里

[Pre-Chorus]
不躲开 不后退
你一伸手 世界慢慢归位

[Chorus]
刚好是你 刚好是你
人海里一眼就认出你
不是奇迹 是每个朝夕
把我的小心翼翼 都抱紧
刚好是你 还是你
让我开始期待明天来临
不用说永远 不用证明
这一刻我愿意 走向你

[Bridge]
如果爱有声音
一定是你叫我的姓名

[Final Chorus]
刚好是你 刚好是你
绕了那么远还是遇见你
世界再拥挤 我也认得你
我的心从此有了归期

[Outro]
刚好是你
刚好是你"""

JOB = {
    "language": "zh",
    "bpm": 84,
    "key": "Bb major",
    "timesignature": "4",
    "duration": 126.0,
    "lyrics": LYRICS,
    "tags": (
        "original premium commercial Mandarin pop love song for a contemporary Chinese women-oriented romance "
        "game, hook-first modern C-pop with tasteful R&B pocket and subtle new-Chinese melodic identity, a bright "
        "warm adult female Mandarin vocal with flawless clear diction and natural intimacy, title hook appears in "
        "the opening and at the very first beat of the chorus, extremely memorable compact five-note pentatonic-leaning "
        "chorus motif, short phrases with breathing space, immediate sing-along quality after one listen, post-chorus "
        "repeats the title, emotionally satisfying upward lift without arena-ballad shouting, crisp modern drums, "
        "warm rounded bass, electric piano, muted guitar, tiny contemporary ruan-like plucked accents, luminous strings "
        "only at the final chorus, polished expensive radio and drama-OST production, commercially irresistible but "
        "not childish, not rustic, not novelty music, not K-pop idol dance, not Western adult contemporary, no long "
        "melismatic runs, no dense poetic lines, no vocal acrobatics, no imitation or quotation of any existing song"
    ),
}


def main():
    result = base.post("/prompt", {"prompt": base.workflow("zh-my-moment-vocal-v3", JOB)})
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

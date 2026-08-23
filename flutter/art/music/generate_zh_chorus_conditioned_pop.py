#!/usr/bin/env python3
"""Repaint the approved chorus guide as female lead, vocal choir, and lyrical rock."""
import importlib.util
import json
import random
import time
from pathlib import Path

base_path = Path(__file__).with_name("generate_bgm_pop.py")
spec = importlib.util.spec_from_file_location("flutter_bgm_base", base_path)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

DURATION = 47.368
LYRICS = """[Chorus - Full Lead and Three-Part Female Harmonies]
走向我
（走向我）
就现在 走向我
穿过人海 穿过沉默
如果你也曾 为我停留
别让我们 只剩错过

[Chorus Lift - Lead, Low Octave and High Countermelody]
走向我
（我走向你）
像我一直 走向你
不用永远 不用承诺
这一刻请你 选择我

[Final Harmony Tag]
走向我
（我正走向你）"""

TAGS = (
    "original Mandarin lyrical-rock romance chorus, exact melodic contour and staged harmony movement follow the "
    "reference guide audio, powerful expressive adult female Mandarin lead, clearly audible real human backing-vocal "
    "ensemble singing every parenthetical response, three-part female vocal harmony in thirds and sixths, low octave "
    "support and an independent soaring high countermelody in the second half, full emotional release from the first "
    "sung title, huge live rock drums, melodic electric bass, grand piano, wide electric guitars and full cinematic "
    "strings, majestic and heartfelt rather than aggressive, lead vocal always intelligible above the band, no "
    "instrument pretending to be vocal harmony, no whisper singing, no choir pad, no metal, no trailer music, no K-pop"
)


def node(class_type, **inputs):
    return {"class_type": class_type, "inputs": inputs}


def workflow(name, denoise):
    seed = random.randrange(2**48)
    return {
        "1": node("UNETLoader", unet_name="acestep_v1.5_turbo.safetensors", weight_dtype="default"),
        "2": node("DualCLIPLoader", clip_name1="qwen_0.6b_ace15.safetensors",
                  clip_name2="qwen_4b_ace15.safetensors", type="ace", device="default"),
        "3": node("VAELoader", vae_name="ace_1.5_vae.safetensors"),
        "4": node("TextEncodeAceStepAudio1.5", clip=["2",0], tags=TAGS, lyrics=LYRICS, seed=seed,
                  bpm=76, duration=DURATION, timesignature="4", language="zh", keyscale="D major",
                  generate_audio_codes=False, cfg_scale=2.0, temperature=.8, top_p=.9, top_k=0, min_p=0),
        "5": node("ConditioningZeroOut", conditioning=["4",0]),
        "6": node("LoadAudio", audio="zh-walk-to-me-chorus-guide.wav"),
        "7": node("VAEEncodeAudio", audio=["6",0], vae=["3",0]),
        "8": node("ReferenceTimbreAudio", conditioning=["4",0], latent=["7",0]),
        "9": node("ModelSamplingAuraFlow", model=["1",0], shift=3),
        "10": node("KSampler", model=["9",0], positive=["8",0], negative=["5",0],
                   latent_image=["7",0], seed=seed, steps=12, cfg=1.15,
                   sampler_name="euler", scheduler="simple", denoise=denoise),
        "11": node("VAEDecodeAudio", samples=["10",0], vae=["3",0]),
        "12": node("SaveAudioOpus", audio=["11",0], filename_prefix=f"flutter_bgm/{name}", quality="192k"),
    }


def main():
    for suffix, denoise in (("faithful", .52), ("grand", .68)):
        name=f"zh-chorus-conditioned-{suffix}"
        result=base.post("/prompt",{"prompt":workflow(name,denoise)})
        pid=result["prompt_id"];print(f"{name}: queued {pid}",flush=True)
        while True:
            history=base.get("/history/"+pid)
            if pid in history:
                status=history[pid].get("status",{})
                if status.get("completed"):print(f"{name}: complete",flush=True);break
                if status.get("status_str")=="error":raise RuntimeError(json.dumps(history[pid],ensure_ascii=False))
            time.sleep(5)


if __name__=="__main__":
    main()

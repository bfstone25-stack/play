"""Flutter EN版立绘 — 3位西方型男(欧美女性审美: 硬朗/宽肩/胡茬/男人味).
dreamshaper-8, 1660Ti fp32(绕16xx黑图bug)。⚠️训练期禁跑,mingxi完成后执行。
用法: python gen_portraits_en.py [char_id]  (无参=全部);表情版: --expr
输出: frontend/portraits/<id>.jpg + <id>_{smile,blush,love}.jpg
"""
import os, sys, torch
torch.backends.cudnn.enabled = False
from diffusers import StableDiffusionPipeline

OUT = os.path.expanduser("~/Play/flutter/frontend/portraits")
os.makedirs(OUT, exist_ok=True)

COMMON_NEG = ("lowres, bad anatomy, bad hands, extra fingers, missing fingers, deformed, mutated, "
              "ugly, disfigured, blurry, watermark, signature, text, logo, child, old man, elderly, "
              "woman, female, feminine, androgynous, delicate, skinny, breasts, cropped head, "
              "out of frame, worst quality, jpeg artifacts, asian")

MASC = ("rugged masculine features, strong jawline, broad shoulders, athletic build, "
        "confident gaze, ultra detailed face, masterpiece, best quality, 8k, "
        "upper body portrait, looking at viewer, cinematic lighting")

CHARS = {
    "ethan": {
        "seed": 20260717,
        "prompt": ("portrait of a handsome caucasian billionaire CEO man, mid 30s, dark brown hair swept back, "
                   "five o'clock shadow stubble, piercing steel-blue eyes, tailored charcoal suit with loosened tie, "
                   "sleeves rolled up showing strong forearms, standing at a rooftop bar at night, "
                   "city skyline bokeh, whiskey glass in hand, commanding presence, " + MASC),
    },
    "liam": {
        "seed": 20260718,
        "prompt": ("portrait of a handsome caucasian firefighter man, early 30s, short sandy-blond hair, "
                   "warm hazel eyes, easy charming grin, light stubble, navy firefighter t-shirt with suspenders down, "
                   "muscular arms crossed, golden-hour sunset light, pickup truck and firehouse bokeh background, "
                   "friendly protective aura, " + MASC),
    },
    "adrian": {
        "seed": 20260719,
        "prompt": ("portrait of a handsome caucasian rockstar man, late 20s, tousled black hair, "
                   "intense dark green eyes, sharp cheekbones with stubble, black leather jacket over band tee, "
                   "tattoo sleeve on one arm, electric guitar slung on back, empty stage single spotlight, "
                   "smoke haze, dangerous magnetic aura, slight smirk, " + MASC),
    },
}
EXPR = {
    "smile": "warm genuine smile, soft affectionate eyes",
    "blush": "slight blush on cheeks, caught off guard, shy sincere expression",
    "love": "deeply in love gaze, tender intense eye contact, soft smile",
}

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    do_expr = "--expr" in sys.argv
    ids = args or list(CHARS)
    pipe = StableDiffusionPipeline.from_pretrained(
        "Lykon/dreamshaper-8", torch_dtype=torch.float32, safety_checker=None).to("cuda")
    for cid in ids:
        c = CHARS[cid]
        jobs = [("", c["prompt"])]
        if do_expr:
            jobs += [(f"_{k}", c["prompt"] + ", " + v) for k, v in EXPR.items()]
        for suffix, prompt in jobs:
            g = torch.Generator("cuda").manual_seed(c["seed"] + hash(suffix) % 1000)
            img = pipe(prompt, negative_prompt=COMMON_NEG, width=512, height=768,
                       num_inference_steps=32, guidance_scale=7.0, generator=g).images[0]
            path = f"{OUT}/{cid}{suffix}.jpg"
            img.convert("RGB").save(path, quality=92)
            print("saved", path)
    print("PORTRAITS-EN-DONE")

if __name__ == "__main__":
    main()

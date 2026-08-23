"""Flutter立绘生成 — dreamshaper-8, 1660Ti(fp32绕过16xx黑图bug).
三位攻略对象各一张英雄立绘(固定seed保一致性), 竖版半身.
用法: python gen_portraits.py [char_id]  (无参=全部)
输出: ~/Play/flutter/portraits/<id>.png
"""
import os, sys, torch
torch.backends.cudnn.enabled = False
from diffusers import StableDiffusionPipeline

OUT = os.path.expanduser("~/Play/flutter/portraits")
os.makedirs(OUT, exist_ok=True)

COMMON_NEG = ("lowres, bad anatomy, bad hands, extra fingers, missing fingers, deformed, mutated, "
              "ugly, disfigured, blurry, watermark, signature, text, logo, child, old man, elderly, "
              "woman, female, feminine, breasts, cropped head, out of frame, worst quality, jpeg artifacts")

CHARS = {
    "guyan": {
        "seed": 20240711,
        "prompt": ("portrait of a gentle handsome young east asian man, late 20s, soft warm eyes, "
                   "slight tender smile, tousled dark hair, wearing a cozy beige cardigan over a shirt, "
                   "standing in a warm cozy secondhand bookshop at dusk, golden lamplight, shelves of books "
                   "bokeh background, soft cinematic lighting, refined literary gentle aura, "
                   "upper body, looking at viewer, ultra detailed face, masterpiece, best quality, 8k"),
    },
    "luxingye": {
        "seed": 20240712,
        "prompt": ("portrait of a dazzling handsome young east asian idol man, early 20s, sharp charming eyes, "
                   "playful confident smirk, stylish layered hair with subtle highlights, fashionable stage outfit "
                   "with a loosened collar, backstage with glowing neon signs bokeh, dramatic colorful rim lighting, "
                   "charismatic star aura, upper body, looking at viewer, ultra detailed face, masterpiece, best quality, 8k"),
    },
    "fushen": {
        "seed": 20240713,
        "prompt": ("portrait of an aloof handsome young east asian man, early 30s, cold composed expression, "
                   "sharp refined features, neat dark hair, wearing an impeccable tailored dark suit, "
                   "standing by floor-to-ceiling windows of a luxurious penthouse at night, glittering city lights "
                   "bokeh behind, cool cinematic blue lighting, elegant wealthy reserved aura, "
                   "upper body, looking at viewer, ultra detailed face, masterpiece, best quality, 8k"),
    },
}

def build():
    pipe = StableDiffusionPipeline.from_pretrained("Lykon/dreamshaper-8", torch_dtype=torch.float32,
                                                   safety_checker=None, requires_safety_checker=False)
    pipe = pipe.to("cuda")
    return pipe

def gen(pipe, cid):
    c = CHARS[cid]
    g = torch.Generator("cuda").manual_seed(c["seed"])
    img = pipe(c["prompt"], negative_prompt=COMMON_NEG, num_inference_steps=30,
               guidance_scale=7.5, width=512, height=768, generator=g).images[0]
    p = f"{OUT}/{cid}.png"
    img.save(p)
    print(f"GEN {cid} -> {p}", flush=True)

if __name__ == "__main__":
    pipe = build()
    ids = sys.argv[1:] or list(CHARS)
    for cid in ids:
        gen(pipe, cid)
    print("PORTRAITS_DONE", flush=True)

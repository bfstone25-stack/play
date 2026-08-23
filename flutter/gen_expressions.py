"""Flutter表情立绘批量: 3角色 x 3表情(smile/blush/lovestruck), 同seed保角色一致性."""
import os, sys, torch
sys.path.insert(0, os.path.expanduser("~/Products/play/flutter"))
from gen_portraits import CHARS, COMMON_NEG, build

EXPR = {
    "smile": "warm gentle smile, soft eyes",
    "blush": "shy blushing face, flustered expression, looking slightly away, pink cheeks",
    "love": "lovestruck tender gaze, faint blush, soft affectionate smile, sparkling eyes",
}
OUT = os.path.expanduser("~/Products/play/flutter/portraits")
pipe = build()
for cid, c in CHARS.items():
    base = c["prompt"]
    for ename, edesc in EXPR.items():
        p = base.replace("looking at viewer", edesc + ", looking at viewer")
        g = torch.Generator("cuda").manual_seed(c["seed"])
        img = pipe(p, negative_prompt=COMMON_NEG, num_inference_steps=30,
                   guidance_scale=7.5, width=512, height=768, generator=g).images[0]
        img.save(f"{OUT}/{cid}_{ename}.png")
        print(f"GEN {cid}_{ename}", flush=True)
print("EXPRESSIONS_DONE", flush=True)

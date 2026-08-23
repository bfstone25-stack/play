"""表情立绘v3(img2img保脸): 基础立绘作底图+低强度+加权表情词 -> 同脸不同表情.
3角色 x 3表情. 产出直接覆盖 portraits/<id>_<expr>.png"""
import os, torch
from diffusers import StableDiffusionImg2ImgPipeline
from PIL import Image
torch.backends.cudnn.enabled = False

OUT = os.path.expanduser("~/Products/play/flutter/portraits")
NEG = "lowres, bad anatomy, deformed, ugly, blurry, watermark, text, child, woman, feminine, extra fingers"
EXPR = {
    "smile": "(bright warm smile:1.35), soft happy eyes",
    "blush": "(deep blush:1.5), (flustered shy face:1.4), (rosy red cheeks:1.45), averted bashful eyes",
    "love": "(lovestruck tender gaze:1.45), (soft blush:1.25), affectionate half-lidded eyes, loving smile",
}
CHAR_STYLE = {
    "guyan": "handsome gentle young east asian man, tousled dark hair, beige cardigan, warm bookshop light",
    "luxingye": "dazzling handsome young east asian idol, stylish hair, stage outfit, neon backstage light",
    "fushen": "aloof handsome young east asian man, neat dark hair, tailored dark suit, penthouse night light",
}

pipe = StableDiffusionImg2ImgPipeline.from_pretrained("Lykon/dreamshaper-8", torch_dtype=torch.float32,
                                                      safety_checker=None, requires_safety_checker=False).to("cuda")
for cid, style in CHAR_STYLE.items():
    base = Image.open(f"{OUT}/{cid}.png").convert("RGB")
    for e, edesc in EXPR.items():
        g = torch.Generator("cuda").manual_seed(hash(cid+e) % 100000)
        img = pipe(prompt=f"portrait of {style}, {edesc}, ultra detailed face, masterpiece, best quality",
                   negative_prompt=NEG, image=base, strength=0.38, guidance_scale=8.0,
                   num_inference_steps=34, generator=g).images[0]
        img.save(f"{OUT}/{cid}_{e}.png")
        img.convert("RGB").save(f"{OUT}/{cid}_{e}.jpg", quality=85, optimize=True)
        print(f"GEN {cid}_{e}", flush=True)
print("EXPR_V3_DONE", flush=True)

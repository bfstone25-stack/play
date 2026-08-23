"""表情立绘v2: 表情词前置加权+随机seed(放开构图)+精确负面. 先验证顾言三表情差异够不够."""
import os, sys, torch
sys.path.insert(0, os.path.expanduser("~/Products/play/flutter"))
from gen_portraits import CHARS, build
OUT=os.path.expanduser("~/Products/play/flutter/portraits")
EXPR={
 "smile":("(gentle warm smile:1.3), soft eyes, relaxed", "crying, angry, blush, open mouth"),
 "blush":("(heavy blush:1.5), (shy flustered face:1.4), (rosy red cheeks:1.4), looking away bashfully, embarrassed", "neutral, calm, confident, angry"),
 "love":("(lovestruck expression:1.4), (tender loving gaze:1.4), (soft blush:1.2), half-lidded affectionate eyes, gentle smile", "neutral, angry, sad, wide eyes"),
}
NEG_BASE="lowres, bad anatomy, bad hands, extra fingers, deformed, ugly, blurry, watermark, text, child, woman, feminine"
c=CHARS["guyan"]; base=c["prompt"]
pipe=build()
seeds={"smile":111,"blush":222,"love":333}
for e,(edesc,eneg) in EXPR.items():
    # 表情词前置, 角色描述简化跟在后
    p=f"portrait of a handsome young east asian man, {edesc}, tousled dark hair, cozy beige cardigan, warm bookshop, soft cinematic lighting, upper body, ultra detailed face, masterpiece, best quality"
    g=torch.Generator("cuda").manual_seed(seeds[e])
    img=pipe(p, negative_prompt=NEG_BASE+", "+eneg, num_inference_steps=32, guidance_scale=8.5, width=512, height=768, generator=g).images[0]
    img.save(f"{OUT}/guyan_{e}.png"); print(f"GEN guyan_{e}",flush=True)
print("V2_DONE",flush=True)

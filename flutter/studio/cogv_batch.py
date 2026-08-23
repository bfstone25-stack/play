import torch, os, sys
from diffusers import CogVideoXPipeline
from diffusers.utils import export_to_video

pipe = CogVideoXPipeline.from_pretrained("THUDM/CogVideoX-2b", torch_dtype=torch.float16)
pipe.enable_model_cpu_offload()
pipe.vae.enable_tiling(); pipe.vae.enable_slicing()

STYLE = ("black and white line art animation, hand-drawn 2d anime style, clean ink outlines on white background, "
         "minimal shading, cartoon, ")
NEG = "color, photo, realistic, 3d render, blurry, text, watermark"

SHOTS = {
  "s1_leak":    "interior wall with a water pipe, a single drop of water dripping from the pipe joint, quiet room, static camera slowly zooming in",
  "s2_panic":   "a small cute round blob monster with big eyes looking up at a leaking water pipe, worried expression, water dripping on its head, medium shot",
  "s3_book":    "a small cute round blob monster flipping through a big thick repair manual book, pages turning, confused, close shot",
  "s4_entrance":"a huge burly fat workman with mustache and overalls standing proudly with a sledgehammer over his shoulder, small round monster looking up at him amazed, wide shot",
  "s5_smash":   "a burly workman swinging a large sledgehammer smashing a water pipe on the wall, water bursting and spraying everywhere, a small round monster watching in shock, dynamic action, wide shot",
  "s6_petrify": "a small cute round blob monster frozen stiff with shocked wide eyes, jaw dropped, standing still like a statue, burly workman standing calmly beside it, medium shot",
  "s7_flood":   "a room slowly flooding with water on the floor, a burly workman and a small round monster standing in rising water, deadpan, wide shot",
}

mode = sys.argv[1] if len(sys.argv) > 1 else "test"   # test=1秒试片(9帧), full=全长49帧
FRAMES = {"s1_leak":33,"s2_panic":49,"s3_book":33,"s4_entrance":49,"s5_smash":49,"s6_petrify":33,"s7_flood":33}
frames = 9
steps = 20 if mode == "test" else 25
outdir = os.path.expanduser("~/cogv_shots/" + ("test" if mode == "test" else "full"))
os.makedirs(outdir, exist_ok=True)

only = sys.argv[2].split(",") if len(sys.argv) > 2 else list(SHOTS.keys())
for name in only:
    out = f"{outdir}/{name}.mp4"
    if os.path.exists(out):
        print("skip", name); continue
    g = torch.Generator("cuda").manual_seed(42)
    video = pipe(prompt=STYLE+SHOTS[name], negative_prompt=NEG, num_frames=(9 if mode=="test" else FRAMES[name]),
                 num_inference_steps=steps, guidance_scale=6.0, generator=g).frames[0]
    export_to_video(video, out, fps=8)
    print("DONE", name, mode)
print("BATCH_COMPLETE", mode)

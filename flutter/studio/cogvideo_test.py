import torch, sys, os
from diffusers import CogVideoXPipeline
from diffusers.utils import export_to_video

NAME = sys.argv[1]
PROMPT = sys.argv[2]
OUT = os.path.expanduser("~/cogvideo_out")
os.makedirs(OUT, exist_ok=True)

# CogVideoX-2B: 12GB可跑. fp16 + CPU offload + VAE tiling 省显存
pipe = CogVideoXPipeline.from_pretrained("THUDM/CogVideoX-2b", torch_dtype=torch.float16)
pipe.enable_model_cpu_offload()          # 关键: 分层offload,12GB够
pipe.vae.enable_tiling()                 # VAE分块,省大头显存
pipe.vae.enable_slicing()

video = pipe(
    prompt=PROMPT,
    num_videos_per_prompt=1,
    num_inference_steps=30,
    num_frames=49,                        # ~6秒@8fps
    guidance_scale=6.0,
    generator=torch.Generator(device="cuda").manual_seed(42),
).frames[0]

path = os.path.join(OUT, f"{NAME}.mp4")
export_to_video(video, path, fps=8)
print("SAVED", path)

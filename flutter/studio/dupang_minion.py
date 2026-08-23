import torch, os
from diffusers import StableDiffusionPipeline
torch.backends.cudnn.enabled = False
OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/casting2')
os.makedirs(OUT, exist_ok=True)
pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')

# 小黄人式蠢萌: 胶囊身+大护目镜眼+龅牙傻笑+亮黄,笨拙滑稽
BASE = 'a silly goofy cartoon mascot, tall capsule pill-shaped body, bright yellow, big round goggle eyes with metal rim, wide dumb toothy grin, tiny stubby arms and legs, blue overall straps, derpy funny expression, thick bold black outlines, flat vector cartoon style, clean cream background, full body, centered, character design'
NEG = 'human, realistic, photo, 3d, scary, detailed background, text, watermark, multiple characters, cute round pet, fluffy animal, cat, dog, bear'

for seed in [5, 33, 88, 140, 202, 314]:
    g = torch.Generator('cuda').manual_seed(seed)
    img = pipe(BASE, negative_prompt=NEG, num_inference_steps=30, guidance_scale=8.5, width=448, height=640, generator=g).images[0]
    img.save(f'{OUT}/m_{seed}.png'); print('saved', seed)
print('DONE')

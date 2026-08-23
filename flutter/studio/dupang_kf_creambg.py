import torch, os
from diffusers import StableDiffusionPipeline
from diffusers.utils import load_image
torch.backends.cudnn.enabled = False
OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/keyframes')
HERO = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/HERO_dupang.png')
pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')
pipe.load_ip_adapter('h94/IP-Adapter', subfolder='models', weight_name='ip-adapter-plus_sd15.bin')
ref = load_image(HERO)
# 强制纯米白背景(和场景#F7F6F0一致),矢量化后背景融进场景隐形
BASE = 'goofy yellow capsule mascot, blue helmet head, big goggle eyes, buck-tooth grin, thick black outlines, flat vector cartoon, isolated on plain solid off-white cream background, no background details, full body, centered'
NEG = 'human, realistic, photo, 3d, grey background, blue background, gradient background, detailed background, shadow, text, watermark, multiple characters'
jobs = [
  ('state_smug', 0.6, BASE + ', very smug cocky pose, one hand on hip, eyes half closed arrogant grin'),
  ('state_panic',0.55,BASE + ', extreme panic, both arms up flailing, mouth wide screaming, wide terrified eyes'),
  ('state_idle', 0.7, BASE + ', standing neutral relaxed, arms at sides'),
  ('state_petrified',0.4,'a grey stone statue of a capsule mascot, solid grey stone cracked petrified, monochrome grey, thick black outlines, isolated on plain solid off-white cream background, full body, centered'),
]
for name, sc, prompt in jobs:
    pipe.set_ip_adapter_scale(sc)
    g = torch.Generator('cuda').manual_seed(5)
    img = pipe(prompt, negative_prompt=NEG, ip_adapter_image=ref, num_inference_steps=30, guidance_scale=7.5, width=448, height=640, generator=g).images[0]
    img.save(f'{OUT}/{name}_cream.png'); print('saved', name)
print('DONE')

import torch, os
from diffusers import StableDiffusionPipeline
from diffusers.utils import load_image
torch.backends.cudnn.enabled = False
OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/keyframes')
HERO = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/HERO_dupang.png')
pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')
pipe.load_ip_adapter('h94/IP-Adapter', subfolder='models', weight_name='ip-adapter-plus_sd15.bin')
ref = load_image(HERO)
BASE = 'goofy yellow capsule mascot, blue helmet head, big goggle eyes, buck-tooth grin, thick black outlines, flat vector cartoon, clean cream background, full body, centered'
NEG = 'human, realistic, photo, 3d, detailed background, text, watermark, multiple characters'
# 降scale给姿态/状态自由度;石化态scale最低(要大幅偏离参考)
jobs = [
  ('state_smug', 0.6, BASE + ', very smug cocky pose, leaning back, one hand on hip other pointing, eyes half closed arrogant grin'),
  ('state_panic',0.55,BASE + ', extreme panic, both arms flailing up in air, mouth wide open screaming, wide terrified eyes, sweat flying, body leaning back'),
  ('state_petrified',0.4,'a grey stone statue of a capsule mascot, solid grey stone, cracked and petrified, cracks all over, monochrome grey, thick black outlines, cream background, full body, centered'),
]
for name, sc, prompt in jobs:
    pipe.set_ip_adapter_scale(sc)
    g = torch.Generator('cuda').manual_seed(5)
    img = pipe(prompt, negative_prompt=NEG, ip_adapter_image=ref, num_inference_steps=30, guidance_scale=7.5, width=448, height=640, generator=g).images[0]
    img.save(f'{OUT}/{name}_v2.png'); print('saved', name, sc)
print('DONE')

import torch, os
from diffusers import StableDiffusionPipeline
from diffusers.utils import load_image
torch.backends.cudnn.enabled = False

OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/keyframes')
os.makedirs(OUT, exist_ok=True)
HERO = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/HERO_dupang.png')

pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')
# 挂IP-Adapter(已下好的权重)
pipe.load_ip_adapter('h94/IP-Adapter', subfolder='models', weight_name='ip-adapter-plus_sd15.bin')
pipe.set_ip_adapter_scale(0.75)  # 0.75:强锁角色又留姿态自由度

ref = load_image(HERO)
BASE = 'goofy yellow capsule mascot character, blue helmet head, big goggle eyes, buck-tooth grin, thick black outlines, flat vector cartoon, clean cream background, full body, centered'
NEG = 'human, realistic, photo, 3d, detailed background, text, watermark, multiple characters, extra limbs'

# 4个关键帧(同一角色不同状态)
shots = {
  'state_idle':      BASE + ', standing neutral, arms at sides',
  'state_smug':      BASE + ', smug confident grin, one hand on hip, eyes half closed cocky',
  'state_panic':     BASE + ', panic terrified, wide shocked eyes, arms up flailing, sweat drops',
  'state_petrified': BASE + ', grey stone statue, petrified cracked, turned to stone, grey color, shocked',
}
for name, prompt in shots.items():
    g = torch.Generator('cuda').manual_seed(5)
    img = pipe(prompt, negative_prompt=NEG, ip_adapter_image=ref,
               num_inference_steps=30, guidance_scale=7.5, width=448, height=640, generator=g).images[0]
    img.save(f'{OUT}/{name}.png'); print('saved', name)
print('DONE')

import torch, os
from diffusers import StableDiffusionPipeline
torch.backends.cudnn.enabled = False
OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang/casting')
os.makedirs(OUT, exist_ok=True)
pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')

# 目标: 中性无年龄萌物(Tom&Jerry/大盗贼级IP),不是人类。压制成人特征
BASE = 'simple cute cartoon mascot character, big round bald head, small round bean-shaped body, tiny stubby arms and legs, two big dot eyes, retro rubber hose animation style, thick bold black ink outlines, vintage 1930s american cartoon, flat solid colors, cream background, minimalist, full body, centered, character sheet'
NEG = 'human, woman, man, girl, boy, hair, breasts, cleavage, dress, clothing, realistic, photo, 3d, sexy, adult, fingers, shoes, high heels, complex, background scene, text, watermark, multiple'

# 6个候选(不同seed),挑最'萌物'的当定妆
for seed in [11, 23, 42, 77, 108, 256]:
    g = torch.Generator('cuda').manual_seed(seed)
    img = pipe(BASE, negative_prompt=NEG, num_inference_steps=30, guidance_scale=8.0, width=512, height=576, generator=g).images[0]
    img.save(f'{OUT}/cast_{seed}.png'); print('saved', seed)
print('DONE')

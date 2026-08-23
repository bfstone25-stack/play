import torch, os
from diffusers import StableDiffusionPipeline
torch.backends.cudnn.enabled = False
OUT = os.path.expanduser('~/Projects/AI_OUTPUT/images/dupang')
os.makedirs(OUT, exist_ok=True)
pipe = StableDiffusionPipeline.from_pretrained('Lykon/dreamshaper-8', torch_dtype=torch.float32, safety_checker=None).to('cuda')
CHAR = 'a cute chubby cartoon character, big round head, round plump body, vintage american hand-drawn cartoon style, thick clean black outlines, flat cream background, minimal, retro rubber-hose animation, full body, centered'
NEG = 'realistic, photo, 3d, complex background, text, watermark, multiple characters, cropped'
SEED = 77
shots = {
  'state_smug': CHAR + ', smug confident grin, one hand on hip, eyes closed happily',
  'state_petrified': CHAR + ', turned to grey stone statue, cracked petrified, grey stone texture',
}
for name, prompt in shots.items():
    g = torch.Generator('cuda').manual_seed(SEED)
    img = pipe(prompt, negative_prompt=NEG, num_inference_steps=28, guidance_scale=7.5, width=512, height=640, generator=g).images[0]
    img.save(f'{OUT}/{name}.png'); print('saved', name)
print('DONE')

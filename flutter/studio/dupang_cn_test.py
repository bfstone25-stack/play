import json, urllib.request, uuid
FRAMES=48
STYLE="black and white line art, clean ink linework, manga style, monochrome, no color, high contrast"
NEG="color, colorful, realistic, photo, 3d, ugly, blurry, deformed, text, watermark, multiple characters"
BODY="a cute goofy capsule mascot, big goggle eyes, buck-tooth grin"
FULL='"0": "'+BODY+', shocked terrified, water pipe bursting, '+STYLE+'"'
# 无FreeInit(排除冲突) + lineart控制图(黑底白线) + v2 apply
W={
 "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"DreamShaper_8_pruned.safetensors"}},
 "3":{"class_type":"ADE_StandardUniformContextOptions","inputs":{"context_length":16,"context_stride":1,"context_overlap":6}},
 "2":{"class_type":"ADE_AnimateDiffLoaderGen1","inputs":{"model":["1",0],"model_name":"mm_sd_v15_v2.ckpt","beta_schedule":"sqrt_linear (AnimateDiff)","context_options":["3",0]}},
 "16":{"class_type":"ControlNetLoaderAdvanced","inputs":{"control_net_name":"control_v11p_sd15_lineart.pth"}},
 "17":{"class_type":"VHS_LoadImages","inputs":{"directory":"ep01_line","image_load_cap":FRAMES,"skip_first_images":0,"select_every_nth":1}},
 "8":{"class_type":"BatchPromptSchedule","inputs":{"text":FULL,"clip":["1",1],"max_frames":FRAMES,"print_output":False,"start_frame":0,"end_frame":0}},
 "9":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["1",1]}},
 "18":{"class_type":"ACN_AdvancedControlNetApply_v2","inputs":{"positive":["8",0],"negative":["9",0],"control_net":["16",0],"image":["17",0],"strength":0.7,"start_percent":0.0,"end_percent":0.7}},
 "10":{"class_type":"EmptyLatentImage","inputs":{"width":384,"height":512,"batch_size":FRAMES}},
 "11":{"class_type":"KSampler","inputs":{"model":["2",0],"seed":5,"steps":18,"cfg":8.0,"sampler_name":"euler","scheduler":"normal","positive":["18",0],"negative":["18",1],"latent_image":["10",0],"denoise":1.0}},
 "12":{"class_type":"VAEDecode","inputs":{"samples":["11",0],"vae":["1",2]}},
 "13":{"class_type":"VHS_VideoCombine","inputs":{"images":["12",0],"frame_rate":24,"loop_count":0,"filename_prefix":"cntest","format":"video/h264-mp4","pingpong":False,"save_output":True}},
}
req={"prompt":W,"client_id":str(uuid.uuid4())}
r=urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:8188/prompt",data=json.dumps(req).encode(),headers={"Content-Type":"application/json"}))
print(json.load(r)["prompt_id"])

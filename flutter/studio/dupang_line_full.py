import json, urllib.request, uuid
FRAMES=360; FI_ITER=1  # 15秒@24fps, FreeInit 1(省时)
STYLE="black and white line art, clean ink linework, manga style, speed lines, monochrome, no color, high contrast, dynamic"
NEG="color, colorful, painting, realistic, photo, 3d, grey shading, ugly, blurry, deformed, mutated, text, watermark, multiple characters"
BODY="a cute goofy capsule mascot, big goggle eyes, buck-tooth grin, round belly, thin legs"
# 4段剧情Prompt Travel: 爆管惊恐→掏金书得意→被锤砸压扁石化→石尘复原
PT=('"0": "'+BODY+', shocked terrified as water pipe bursts, water spraying, arms flailing, '+STYLE+'",\n'
    '"90": "'+BODY+', smug confident grin holding a glowing book, one hand on hip, hopeful, '+STYLE+'",\n'
    '"180": "'+BODY+', smashed by a huge hammer, body squished flat, petrified cracking stone, crushed, '+STYLE+'",\n'
    '"270": "'+BODY+', reforming from stone dust, dizzy, holding the book, silly face, '+STYLE+'"')
W={
 "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"DreamShaper_8_pruned.safetensors"}},
 "3":{"class_type":"ADE_StandardUniformContextOptions","inputs":{"context_length":16,"context_stride":1,"context_overlap":6}},
 "14":{"class_type":"ADE_IterationOptsFreeInit","inputs":{"iterations":FI_ITER,"filter":"gaussian","d_s":0.25,"d_t":0.25,"n_butterworth":4,"sigma_step":999,"apply_to_1st_iter":False,"init_type":"FreeInit [sampler sigma]"}},
 "15":{"class_type":"ADE_AnimateDiffSamplingSettings","inputs":{"batch_offset":0,"noise_type":"FreeNoise","seed_gen":"comfy","seed_offset":0,"iteration_opts":["14",0]}},
 "2":{"class_type":"ADE_AnimateDiffLoaderGen1","inputs":{"model":["1",0],"model_name":"mm_sd_v15_v2.ckpt","beta_schedule":"sqrt_linear (AnimateDiff)","context_options":["3",0],"sample_settings":["15",0]}},
 "8":{"class_type":"BatchPromptSchedule","inputs":{"text":PT,"clip":["1",1],"max_frames":FRAMES,"print_output":False,"start_frame":0,"end_frame":0}},
 "9":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["1",1]}},
 "10":{"class_type":"EmptyLatentImage","inputs":{"width":384,"height":512,"batch_size":FRAMES}},
 "11":{"class_type":"KSampler","inputs":{"model":["2",0],"seed":5,"steps":18,"cfg":8.0,"sampler_name":"euler","scheduler":"normal","positive":["8",0],"negative":["9",0],"latent_image":["10",0],"denoise":1.0}},
 "12":{"class_type":"VAEDecode","inputs":{"samples":["11",0],"vae":["1",2]}},
 "13":{"class_type":"VHS_VideoCombine","inputs":{"images":["12",0],"frame_rate":24,"loop_count":0,"filename_prefix":"line_full","format":"video/h264-mp4","pingpong":False,"save_output":True}},
}
req={"prompt":W,"client_id":str(uuid.uuid4())}
r=urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:8188/prompt",data=json.dumps(req).encode(),headers={"Content-Type":"application/json"}))
print(json.load(r)["prompt_id"])

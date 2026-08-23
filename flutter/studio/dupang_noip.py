import json, urllib.request, uuid, sys
SEG=sys.argv[1]; ACTION=sys.argv[2]
FRAMES=48; FI_ITER=1
STYLE="black and white line art, clean ink linework, minimalist monochrome, no color, white background"
NEG="color, colorful, painting, realistic, photo, 3d, ugly, blurry, deformed, mutated, text, watermark, multiple characters"
BODY="a cute goofy capsule mascot, big goggle eyes, buck-tooth grin, round belly, thin legs"
FULL='"0": "'+BODY+', '+ACTION+', '+STYLE+'"'
W={
 "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"DreamShaper_8_pruned.safetensors"}},
 "3":{"class_type":"ADE_StandardUniformContextOptions","inputs":{"context_length":16,"context_stride":1,"context_overlap":6}},
 "14":{"class_type":"ADE_IterationOptsFreeInit","inputs":{"iterations":FI_ITER,"filter":"gaussian","d_s":0.25,"d_t":0.25,"n_butterworth":4,"sigma_step":999,"apply_to_1st_iter":False,"init_type":"FreeInit [sampler sigma]"}},
 "15":{"class_type":"ADE_AnimateDiffSamplingSettings","inputs":{"batch_offset":0,"noise_type":"FreeNoise","seed_gen":"comfy","seed_offset":0,"iteration_opts":["14",0]}},
 "2":{"class_type":"ADE_AnimateDiffLoaderGen1","inputs":{"model":["1",0],"model_name":"mm_sd_v15_v2.ckpt","beta_schedule":"sqrt_linear (AnimateDiff)","context_options":["3",0],"sample_settings":["15",0]}},
 "8":{"class_type":"BatchPromptSchedule","inputs":{"text":FULL,"clip":["1",1],"max_frames":FRAMES,"print_output":False,"start_frame":0,"end_frame":0}},
 "9":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["1",1]}},
 "10":{"class_type":"EmptyLatentImage","inputs":{"width":384,"height":512,"batch_size":FRAMES}},
 "11":{"class_type":"KSampler","inputs":{"model":["2",0],"seed":5,"steps":18,"cfg":8.0,"sampler_name":"euler","scheduler":"normal","positive":["8",0],"negative":["9",0],"latent_image":["10",0],"denoise":1.0}},
 "12":{"class_type":"VAEDecode","inputs":{"samples":["11",0],"vae":["1",2]}},
 "13":{"class_type":"VHS_VideoCombine","inputs":{"images":["12",0],"frame_rate":24,"loop_count":0,"filename_prefix":"noip_"+SEG,"format":"video/h264-mp4","pingpong":False,"save_output":True}},
}
req={"prompt":W,"client_id":str(uuid.uuid4())}
r=urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:8188/prompt",data=json.dumps(req).encode(),headers={"Content-Type":"application/json"}))
print(SEG, json.load(r)["prompt_id"])

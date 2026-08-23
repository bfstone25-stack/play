import json, urllib.request, uuid

NEG = 'human, realistic, photo, 3d, ugly, blurry, deformed, extra limbs, text, watermark, low quality, multiple characters'
# FizzNodes BatchPromptSchedule格式: 帧号:"prompt" 逗号分隔,不要外层大括号
PROMPT_TRAVEL = '"0": "a cute funny cartoon monster with blue helmet, yellow round belly, red long legs, shocked terrified face, arms flailing up, cream background",\n"24": "a cute funny cartoon monster with blue helmet, yellow round belly, red long legs, smug confident grin, one hand on hip, cream background"'

W = {
 '1': {'class_type':'CheckpointLoaderSimple','inputs':{'ckpt_name':'DreamShaper_8_pruned.safetensors'}},
 '3': {'class_type':'ADE_StandardUniformContextOptions','inputs':{'context_length':16,'context_stride':1,'context_overlap':6}},
 '2': {'class_type':'ADE_AnimateDiffLoaderGen1','inputs':{'model':['1',0],'model_name':'mm_sd_v15_v2.ckpt','beta_schedule':'sqrt_linear (AnimateDiff)','context_options':['3',0]}},
 '4': {'class_type':'IPAdapterModelLoader','inputs':{'ipadapter_file':'ip-adapter-plus_sd15.bin'}},
 '5': {'class_type':'CLIPVisionLoader','inputs':{'clip_name':'model.safetensors'}},
 '6': {'class_type':'LoadImage','inputs':{'image':'HERO_dupang.png'}},
 '7': {'class_type':'IPAdapterAdvanced','inputs':{'model':['2',0],'ipadapter':['4',0],'image':['6',0],'clip_vision':['5',0],'weight':0.85,'weight_type':'linear','combine_embeds':'concat','start_at':0.0,'end_at':1.0,'embeds_scaling':'V only'}},
 '8': {'class_type':'BatchPromptSchedule','inputs':{'text':PROMPT_TRAVEL,'clip':['1',1],'max_frames':48,'print_output':False,'start_frame':0,'end_frame':0}},
 '9': {'class_type':'CLIPTextEncode','inputs':{'text':NEG,'clip':['1',1]}},
 '10':{'class_type':'EmptyLatentImage','inputs':{'width':384,'height':512,'batch_size':48}},
 '11':{'class_type':'KSampler','inputs':{'model':['7',0],'seed':5,'steps':20,'cfg':8.0,'sampler_name':'euler','scheduler':'normal','positive':['8',0],'negative':['9',0],'latent_image':['10',0],'denoise':1.0}},
 '12':{'class_type':'VAEDecode','inputs':{'samples':['11',0],'vae':['1',2]}},
 '13':{'class_type':'VHS_VideoCombine','inputs':{'images':['12',0],'frame_rate':16,'loop_count':0,'filename_prefix':'dupang_3sec','format':'video/h264-mp4','pingpong':False,'save_output':True}},
}
req={'prompt':W,'client_id':str(uuid.uuid4())}
r=urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8188/prompt',data=json.dumps(req).encode(),headers={'Content-Type':'application/json'}))
print(json.load(r))

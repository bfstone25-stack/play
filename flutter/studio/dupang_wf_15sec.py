import json, urllib.request, uuid, sys
FRAMES=360  # 15秒@24fps
FI_ITER=2

NEG='human, realistic, photo, 3d, ugly, blurry, deformed, extra limbs, mutated, inflating body, morphing, text, watermark, low quality, multiple characters'
BODY='a cute funny cartoon monster, consistent body shape, blue helmet, round yellow belly, thin red legs, black shoes'
# 4段剧情Prompt Travel(默片喜剧反转): 爆管惊恐→掏宝典得意→被锤砸压扁石化→晕乎复原
PT = (f'"0": "{BODY}, eating noodles happily, then shocked terrified face as water pipe bursts, arms up",\n'
      f'"90": "{BODY}, looking terrified then hopeful, holding a glowing golden book, hopeful expression",\n'
      f'"180": "{BODY}, getting smashed by huge hammer, body squished flat, petrified gray stone, crushed",\n'
      f'"270": "{BODY}, reforming from stone dust, dizzy, holding the golden book, silly funny face"')

W={
 '1':{'class_type':'CheckpointLoaderSimple','inputs':{'ckpt_name':'DreamShaper_8_pruned.safetensors'}},
 '3':{'class_type':'ADE_StandardUniformContextOptions','inputs':{'context_length':16,'context_stride':1,'context_overlap':6}},
 '14':{'class_type':'ADE_IterationOptsFreeInit','inputs':{'iterations':FI_ITER,'filter':'gaussian','d_s':0.25,'d_t':0.25,'n_butterworth':4,'sigma_step':999,'apply_to_1st_iter':False,'init_type':'FreeInit [sampler sigma]'}},
 '15':{'class_type':'ADE_AnimateDiffSamplingSettings','inputs':{'batch_offset':0,'noise_type':'FreeNoise','seed_gen':'comfy','seed_offset':0,'iteration_opts':['14',0]}},
 '2':{'class_type':'ADE_AnimateDiffLoaderGen1','inputs':{'model':['1',0],'model_name':'mm_sd_v15_v2.ckpt','beta_schedule':'sqrt_linear (AnimateDiff)','context_options':['3',0],'sample_settings':['15',0]}},
 '4':{'class_type':'IPAdapterModelLoader','inputs':{'ipadapter_file':'ip-adapter-plus_sd15.bin'}},
 '5':{'class_type':'CLIPVisionLoader','inputs':{'clip_name':'model.safetensors'}},
 '6':{'class_type':'LoadImage','inputs':{'image':'HERO_dupang.png'}},
 '7':{'class_type':'IPAdapterAdvanced','inputs':{'model':['2',0],'ipadapter':['4',0],'image':['6',0],'clip_vision':['5',0],'weight':0.7,'weight_type':'linear','combine_embeds':'concat','start_at':0.0,'end_at':0.7,'embeds_scaling':'V only'}},
 '8':{'class_type':'BatchPromptSchedule','inputs':{'text':PT,'clip':['1',1],'max_frames':FRAMES,'print_output':False,'start_frame':0,'end_frame':0}},
 '9':{'class_type':'CLIPTextEncode','inputs':{'text':NEG,'clip':['1',1]}},
 '10':{'class_type':'EmptyLatentImage','inputs':{'width':384,'height':512,'batch_size':FRAMES}},
 '11':{'class_type':'KSampler','inputs':{'model':['7',0],'seed':5,'steps':18,'cfg':8.0,'sampler_name':'euler','scheduler':'normal','positive':['8',0],'negative':['9',0],'latent_image':['10',0],'denoise':1.0}},
 '12':{'class_type':'VAEDecode','inputs':{'samples':['11',0],'vae':['1',2]}},
 '13':{'class_type':'VHS_VideoCombine','inputs':{'images':['12',0],'frame_rate':24,'loop_count':0,'filename_prefix':'dupang_15sec','format':'video/h264-mp4','pingpong':False,'save_output':True}},
}
req={'prompt':W,'client_id':str(uuid.uuid4())}
r=urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8188/prompt',data=json.dumps(req).encode(),headers={'Content-Type':'application/json'}))
print(json.load(r))

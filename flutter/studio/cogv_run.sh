#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh && conda activate cogvideo
python ~/cogv_batch.py test s5_smash && python ~/cogv_batch.py full
rm -f ~/.gpu_full_claim

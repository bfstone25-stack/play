#!/usr/bin/env bash
set -euo pipefail
ROOT=/root/flutter-core-v2
TRAIN=/root/train_unsloth.py
LLAMA=/root/.cache/huggingface/hub/models--unsloth--llama-3-8b-Instruct-bnb-4bit/snapshots/fd5a4dc328319c1cfe9489eccfb9c6406bdfd469
QWEN=/root/.cache/huggingface/hub/models--unsloth--Qwen2.5-7B-Instruct-bnb-4bit/snapshots/bdd404162d94997f390efbfa660eb3f21cbbc81d
cd "$ROOT"
test -s training/ready/west-train.jsonl
test -s training/ready/zh-train.jsonl
test -s training/ready/ja-train.jsonl
run() {
  local project=$1 data=$2 base=$3 system=$4
  while [[ -e /mnt/c/gpu-interactive.lock ]]; do sleep 30; done
  TRAIN_MAX_SEQ=1024 TRAIN_BATCH=1 TRAIN_GRAD_ACCUM=8 \
    /root/miniconda3/envs/unsloth/bin/python "$TRAIN" --project "$project" \
    --data "$data" --base "$base" --system-file "$system" --epochs 3 --gguf || {
      code=$?; [[ $code == 75 ]] && return 75; return "$code";
    }
}
run flutter-west-psyche-v1 training/ready/west-train.jsonl "$LLAMA" training/system-west.txt
run flutter-zh-psyche-v1 training/ready/zh-train.jsonl "$QWEN" training/system-zh.txt
run flutter-ja-psyche-v1 training/ready/ja-train.jsonl "$QWEN" training/system-ja.txt

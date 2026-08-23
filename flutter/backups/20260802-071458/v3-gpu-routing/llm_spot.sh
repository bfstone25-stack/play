#!/bin/bash
# Demand-driven Pop dGPU scheduler. An in-flight request has priority over
# background leases so another app cannot take the card midway through a call.
set -u
exec 9>/tmp/llm_spot.lock
flock -n 9 || exit 0
FULL_CLAIM=$HOME/.gpu_full_claim
OWNER=/tmp/llm_spot.gpu_owner
LOG=$HOME/.llm_spot.log
TTL=720
BUDGET_MIB=11600
VK=/home/frankstone/llama.cpp/vulkan/llama-b9911/llama-server
CPU=/home/frankstone/llama.cpp/cpu/llama-b9911/llama-server
GEMMA="%h/llama.cpp/models/gemma2-9b-it-q4.gguf"
LLAMA="%h/llama.cpp/models/llama3-8b-it-q4.gguf"
QWEN="%h/llama.cpp/models/qwen2.5-7b-it-q4.gguf"
PHI_MED="%h/llama.cpp/models/phi3-medium-q4.gguf"
PHI_MINI="%h/llama.cpp/models/phi3-mini-q4.gguf"
LANES=(logos mingxi shifu flutter tell appealpro medikin games spec)
unit_for(){ case "$1" in logos) echo llamacpp-logos;; mingxi) echo llamacpp-mingxi;; shifu) echo llamacpp-shifu;; flutter) echo llamacpp-flutter;; tell) echo llamacpp-tell;; appealpro) echo llamacpp-appealpro;; medikin) echo llamacpp-medikin;; games) echo llamacpp-gemma;; spec) echo llamacpp-spec;; esac; }
cost_for(){ case "$1" in logos|mingxi|shifu|games) echo 7000;; flutter|appealpro|medikin) echo 5100;; tell) echo 4600;; spec) echo 10500;; esac; }
exec_for(){ case "$1:$2" in
logos:GPU) echo "$VK -m $GEMMA --lora %h/models/lora/logos-v11.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8802";; logos:CPU) echo "$CPU -m $GEMMA --lora %h/models/lora/logos-v11.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8802";;
mingxi:GPU) echo "$VK -m $GEMMA --lora %h/models/lora/mingxi-v4-150-lora.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8805";; mingxi:CPU) echo "$CPU -m $GEMMA --lora %h/models/lora/mingxi-v4-150-lora.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8805";;
shifu:GPU) echo "$VK -m $GEMMA --lora %h/models/lora/shifu-zh-gemma-lora.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8810";; shifu:CPU) echo "$CPU -m $GEMMA --lora %h/models/lora/shifu-zh-gemma-lora.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8810";;
flutter:GPU) echo "$VK -m $LLAMA --lora %h/models/lora/flutter-en-night1.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8807";; flutter:CPU) echo "$CPU -m $LLAMA --lora %h/models/lora/flutter-en-night1.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8807";;
tell:GPU) echo "$VK -m $QWEN --lora %h/models/lora/tell-zh-night1.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8809";; tell:CPU) echo "$CPU -m $QWEN --lora %h/models/lora/tell-zh-night1.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8809";;
appealpro:GPU) echo "$VK -m $LLAMA --lora %h/models/lora/appealpro-night2.gguf -c 4096 --fit on --fit-target 1024 --device Vulkan1 -t 4 --host 127.0.0.1 --port 8806";; appealpro:CPU) echo "$CPU -m $LLAMA --lora %h/models/lora/appealpro-night2.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8806";;
medikin:GPU) echo "$VK -m $LLAMA --lora %h/models/lora/medikin-night2.gguf -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8808";; medikin:CPU) echo "$CPU -m $LLAMA --lora %h/models/lora/medikin-night2.gguf -c 4096 -t 10 --host 127.0.0.1 --port 8808";;
games:GPU) echo "$VK -m $GEMMA -c 4096 -ngl 99 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8903";; games:CPU) echo "$CPU -m $GEMMA -c 4096 -t 10 --host 127.0.0.1 --port 8903";;
spec:GPU) echo "$VK -m $PHI_MED -md $PHI_MINI --spec-draft-n-max 6 -c 4096 -ngl 99 -ngld 0 --fit on --fit-target 1024 --device Vulkan1 -t 2 --host 127.0.0.1 --port 8901";; spec:CPU) echo "$CPU -m $PHI_MED -md $PHI_MINI --spec-draft-n-max 6 -c 4096 -t 10 --host 127.0.0.1 --port 8901";; esac; }
mode_of(){ local f="$HOME/.config/systemd/user/$1.service.d/override.conf"; if [ ! -f "$f" ]; then echo NONE; elif grep -q '/vulkan/' "$f"; then echo GPU; else echo CPU; fi; }
set_mode(){ local lane=$1 mode=$2 unit file cmd; unit=$(unit_for "$lane"); [ "$(mode_of "$unit")" = "$mode" ] && systemctl --user is-active --quiet "$unit" && return 0; file="$HOME/.config/systemd/user/$unit.service.d/override.conf"; cmd=$(exec_for "$lane" "$mode"); mkdir -p "$(dirname "$file")"; printf "# llm_spot managed: %s @ %s\n[Service]\nExecStart=\nExecStart=%s\n" "$mode" "$(date +%F_%T)" "$cmd" > "$file"; systemctl --user daemon-reload; systemctl --user restart "$unit"; echo "[llm_spot] $(date +%F_%T) $lane -> $mode" >> "$LOG"; }
claim_fresh(){ local f="$1" now modified; [ -f "$f" ] || return 1; now=$(date +%s); modified=$(stat -c %Y "$f" 2>/dev/null || echo 0); [ $((now-modified)) -lt "$TTL" ]; }
selected=()
if [ ! -f "$FULL_CLAIM" ]; then
  mapfile -t requested < <(for lane in "${LANES[@]}"; do if claim_fresh "$HOME/.gpu_${lane}_inflight"; then printf "2 %s %s\n" "$(stat -c %Y "$HOME/.gpu_${lane}_inflight")" "$lane"; elif claim_fresh "$HOME/.gpu_${lane}_active"; then printf "1 %s %s\n" "$(stat -c %Y "$HOME/.gpu_${lane}_active")" "$lane"; fi; done | sort -k1,1nr -k2,2nr -k3,3 | awk '{print $3}')
  [ ${#requested[@]} -gt 0 ] || requested=(mingxi)
  used=0; for lane in "${requested[@]}"; do cost=$(cost_for "$lane"); if [ $((used+cost)) -le "$BUDGET_MIB" ]; then selected+=("$lane"); used=$((used+cost)); fi; done
fi
is_selected(){ local wanted=$1 item; for item in "${selected[@]}"; do [ "$item" = "$wanted" ] && return 0; done; return 1; }
for lane in "${LANES[@]}"; do is_selected "$lane" || set_mode "$lane" CPU; done
for lane in "${selected[@]}"; do set_mode "$lane" GPU; done
if [ -f "$FULL_CLAIM" ]; then echo CLAIMED > "$OWNER"; else (IFS=+; echo "${selected[*]}") > "$OWNER"; fi

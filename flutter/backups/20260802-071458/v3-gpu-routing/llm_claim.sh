#!/bin/bash
# Claim a lane and return only when its real running process is the Vulkan unit.
set -eu
lane=${1:?lane required}; port=${2:?port required}
case "$lane" in logos|mingxi|shifu|flutter|tell|appealpro|medikin|games|spec) ;; *) exit 64;; esac
if [ "$lane" = appealpro ]; then
  touch "$HOME/.gpu_appealpro_active" "$HOME/.gpu_appealpro_inflight"
  "$HOME/bin/llm_spot.sh"
  for _ in $(seq 1 120); do
    curl -fsS --max-time 1 "http://127.0.0.1:${port}/health" >/dev/null 2>&1 && exit 0
    sleep .5
  done
  exit 1
fi
touch "$HOME/.gpu_${lane}_active"
unit="llamacpp-${lane}"; [ "$lane" = games ] && unit=llamacpp-gemma
for _ in $(seq 1 240); do
  "$HOME/bin/llm_spot.sh"
  owner=$(cat /tmp/llm_spot.gpu_owner 2>/dev/null || true)
  pid=$(systemctl --user show -p MainPID --value "$unit" 2>/dev/null || echo 0)
  if [[ "+$owner+" == *"+$lane+"* ]] && [ "$pid" != 0 ] && tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q '/vulkan/' && curl -fsS --max-time 1 "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then exit 0; fi
  sleep .5
done
exit 1

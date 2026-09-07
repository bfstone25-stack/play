#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COOKIES="${F95ZONE_COOKIES_FILE:-$HOME/.config/f95zone/cookies.json}"
LOG_DIR="$HOME/.local/share/f95zone"
INTERVAL="${F95_WATCH_INTERVAL_SEC:-1800}"
mkdir -p "$LOG_DIR"
export F95ZONE_COOKIES_FILE="$COOKIES"
exec python3 "$ROOT/tools/f95zone/watch_elena_approval.py" \
  --cookies "$COOKIES" \
  --interval-sec "$INTERVAL" \
  --log "$LOG_DIR/elena_watch.jsonl" \
  --state "$LOG_DIR/elena_watch_state.json" \
  --events "$LOG_DIR/elena_watch_events.jsonl" \
  --export-script "$ROOT/tools/f95zone/export_chrome_cookies.py" \
  2>&1 | tee -a "$LOG_DIR/elena_watch.tmux.log"

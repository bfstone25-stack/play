#!/usr/bin/env bash
set -euo pipefail
SESSION="f95-elena-watch"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="$HOME/.local/share/f95zone"
TMUXC=(-f /exec-daemon/tmux.portal.conf)
mkdir -p "$LOG_DIR"

usage() { echo "Usage: $0 {start|stop|status|once|tail}"; }

case "${1:-}" in
  start)
    if tmux "${TMUXC[@]}" has-session -t "=$SESSION" 2>/dev/null; then
      echo "already running: $SESSION"; exit 0
    fi
    tmux "${TMUXC[@]}" new-session -d -s "$SESSION" -c "$ROOT" -- "$ROOT/tools/f95zone/run_elena_watch.sh"
    echo "started tmux session $SESSION"
    echo "state: $LOG_DIR/elena_watch_state.json"
    echo "events: $LOG_DIR/elena_watch_events.jsonl"
    ;;
  stop)
    tmux "${TMUXC[@]}" kill-session -t "=$SESSION" 2>/dev/null || true
    echo "stopped $SESSION"
    ;;
  status)
    if tmux "${TMUXC[@]}" has-session -t "=$SESSION" 2>/dev/null; then echo running; else echo "not running"; fi
    [[ -f "$LOG_DIR/elena_watch_state.json" ]] && python3 -c "import json;print(json.dumps(json.load(open('$LOG_DIR/elena_watch_state.json')),indent=2)[:2000])"
    ;;
  once)
    python3 "$ROOT/tools/f95zone/watch_elena_approval.py" --once \
      --cookies "${F95ZONE_COOKIES_FILE:-$HOME/.config/f95zone/cookies.json}" \
      --log "$LOG_DIR/elena_watch.jsonl" \
      --state "$LOG_DIR/elena_watch_state.json" \
      --events "$LOG_DIR/elena_watch_events.jsonl"
    ;;
  tail)
    touch "$LOG_DIR/elena_watch.tmux.log"
    tail -n 50 -f "$LOG_DIR/elena_watch.tmux.log"
    ;;
  *) usage; exit 2 ;;
esac

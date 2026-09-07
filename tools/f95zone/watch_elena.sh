#!/usr/bin/env bash
# Start/stop the Elena F95 approval watcher in a detached tmux session.
set -euo pipefail
SESSION="f95-elena-watch"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COOKIES="${F95ZONE_COOKIES_FILE:-$HOME/.config/f95zone/cookies.json}"
LOG_DIR="$HOME/.local/share/f95zone"
INTERVAL="${F95_WATCH_INTERVAL_SEC:-1800}" # 30 min

mkdir -p "$LOG_DIR"
export F95ZONE_COOKIES_FILE="$COOKIES"

cmd=(
  python3 "$ROOT/tools/f95zone/watch_elena_approval.py"
  --cookies "$COOKIES"
  --interval-sec "$INTERVAL"
  --log "$LOG_DIR/elena_watch.jsonl"
  --state "$LOG_DIR/elena_watch_state.json"
  --events "$LOG_DIR/elena_watch_events.jsonl"
  --export-script "$ROOT/tools/f95zone/export_chrome_cookies.py"
)

usage() {
  echo "Usage: $0 {start|stop|status|once|tail}"
}

case "${1:-}" in
  start)
    if tmux -f /exec-daemon/tmux.portal.conf has-session -t "=$SESSION" 2>/dev/null; then
      echo "already running: $SESSION"
      exit 0
    fi
    tmux -f /exec-daemon/tmux.portal.conf new-session -d -s "$SESSION" -c "$ROOT" -- \
      "${SHELL:-bash}" -lc "\"${cmd[*]}\" 2>&1 | tee -a \"$LOG_DIR/elena_watch.tmux.log\""
    echo "started tmux session $SESSION (interval ${INTERVAL}s)"
    echo "state: $LOG_DIR/elena_watch_state.json"
    echo "events: $LOG_DIR/elena_watch_events.jsonl"
    ;;
  stop)
    tmux -f /exec-daemon/tmux.portal.conf kill-session -t "=$SESSION" 2>/dev/null || true
    echo "stopped $SESSION"
    ;;
  status)
    if tmux -f /exec-daemon/tmux.portal.conf has-session -t "=$SESSION" 2>/dev/null; then
      echo "running"
    else
      echo "not running"
    fi
    if [[ -f "$LOG_DIR/elena_watch_state.json" ]]; then
      python3 - <<PY
import json
p="$LOG_DIR/elena_watch_state.json"
print(json.dumps(json.load(open(p)), indent=2)[:2000])
PY
    fi
    ;;
  once)
    "${cmd[@]}" --once
    ;;
  tail)
    touch "$LOG_DIR/elena_watch.tmux.log"
    tail -n 50 -f "$LOG_DIR/elena_watch.tmux.log"
    ;;
  *)
    usage
    exit 2
    ;;
esac

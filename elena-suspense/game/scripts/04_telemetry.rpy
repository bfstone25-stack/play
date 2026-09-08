## 04_telemetry.rpy — Anonymous funnel telemetry client for Elena
##
## Docs for other AI sessions: ../../TELEMETRY.md and ../../../shared/TELEMETRY_API.md
## Events POST as a JSON list to /tel_batch (same shape as tell/silvertongue HTML SDKs).

init -1 python:
    import json
    import os
    import threading
    import time
    import uuid

    try:
        from urllib import request as _urlrequest
        from urllib.error import URLError as _URLError
    except Exception:
        _urlrequest = None
        _URLError = Exception

    # ---- config -------------------------------------------------------------
    # Prefer persistent override, then env, then local standalone server.
    _DEFAULT_TEL_URL = "https://apps.blazecore.dev/tel_batch?app=elena"
    _TEL_APP = "elena"
    _TEL_FLUSH_AT = 6
    _TEL_TIMEOUT_S = 4.0

    # Builds before 0.1.2 persisted a localhost dev endpoint; migrate those to the live host.
    if persistent.telemetry_endpoint is None or "127.0.0.1:27100" in (persistent.telemetry_endpoint or ""):
        persistent.telemetry_endpoint = os.environ.get("ELENA_TELEMETRY_URL", _DEFAULT_TEL_URL)

    if persistent.telemetry_enabled is None:
        # On by default when an endpoint is configured; player may disable in prefs.
        persistent.telemetry_enabled = bool(persistent.telemetry_endpoint)

    if persistent.telemetry_pid is None:
        persistent.telemetry_pid = "e" + uuid.uuid4().hex[:12]

    # Per-launch session id (not persisted across restarts).
    if not hasattr(store, "_tel_sid") or not store._tel_sid:
        store._tel_sid = "s" + uuid.uuid4().hex[:12]

    store._tel_queue = []
    store._tel_lock = threading.Lock()
    store._tel_session_started = False

    def _tel_endpoint():
        return (persistent.telemetry_endpoint or "").strip()

    def _tel_queue_path():
        try:
            return os.path.join(config.savedir, "telemetry_queue.jsonl")
        except Exception:
            return os.path.join(".", "telemetry_queue.jsonl")

    def _tel_persist_line(event):
        """Append one event to offline queue (best-effort)."""
        try:
            path = _tel_queue_path()
            parent = os.path.dirname(path)
            if parent and not os.path.isdir(parent):
                os.makedirs(parent)
            with open(path, "a", encoding="utf-8") as f:
                f.write(json.dumps(event, ensure_ascii=False) + "\n")
        except Exception:
            pass

    def _tel_load_offline():
        path = _tel_queue_path()
        if not os.path.isfile(path):
            return []
        out = []
        try:
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        out.append(json.loads(line))
                    except Exception:
                        continue
            # Truncate after load; failed resend will re-append.
            open(path, "w", encoding="utf-8").close()
        except Exception:
            return out
        return out

    def _tel_post(batch):
        endpoint = _tel_endpoint()
        if not endpoint or not batch or (_urlrequest is None and not getattr(renpy, "emscripten", False)):
            return False
        # Allow either full /tel_batch URL or base host.
        url = endpoint
        if url.rstrip("/").endswith(":27100"):
            url = url.rstrip("/") + "/tel_batch"
        if "app=" not in url:
            url = url + ("&" if "?" in url else "?") + "app=" + _TEL_APP
        body = json.dumps(batch).encode("utf-8")
        # Web build: sockets do not exist under emscripten; Ren'Py's fetch goes through the browser.
        if getattr(renpy, "emscripten", False):
            try:
                renpy.fetch(url, method="POST", data=body, content_type="application/json",
                            timeout=_TEL_TIMEOUT_S, result="text")
                return True
            except Exception:
                return False
        req = _urlrequest.Request(
            url,
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with _urlrequest.urlopen(req, timeout=_TEL_TIMEOUT_S) as resp:
                return 200 <= getattr(resp, "status", 200) < 300
        except Exception:
            return False

    def _tel_flush_worker(batch):
        ok = _tel_post(batch)
        if not ok:
            for ev in batch:
                _tel_persist_line(ev)

    def tel_flush(force=False):
        """Flush in-memory queue (+ any offline file) to the server."""
        if not persistent.telemetry_enabled:
            return
        with store._tel_lock:
            batch = list(store._tel_queue)
            store._tel_queue = []
        offline = _tel_load_offline()
        if offline:
            batch = offline + batch
        if not batch:
            return
        if not force and len(batch) < 1:
            return
        if getattr(renpy, "emscripten", False):
            # No worker threads in the browser; fetch is short and the batch is small.
            _tel_flush_worker(batch)
        else:
            threading.Thread(target=_tel_flush_worker, args=(batch,), daemon=True).start()

    def tel_track(name, value=None, etype="custom", dur=0):
        """Queue one anonymous funnel / analytics event.

        Example:
            $ tel_track("choice_1", {"choice": "ask_folder"})
        """
        if not persistent.telemetry_enabled:
            return
        if not name:
            return
        ev = {
            "pid": persistent.telemetry_pid,
            "sid": store._tel_sid,
            "etype": etype or "custom",
            "name": str(name)[:120],
            "dur": float(dur or 0),
            "ts": time.time(),
        }
        if value is not None:
            if isinstance(value, (dict, list)):
                ev["value"] = json.dumps(value, ensure_ascii=False)
            else:
                ev["value"] = value
        with store._tel_lock:
            store._tel_queue.append(ev)
            n = len(store._tel_queue)
        if n >= _TEL_FLUSH_AT:
            tel_flush(force=True)

    def tel_ensure_session():
        if store._tel_session_started:
            return
        store._tel_session_started = True
        tel_track(
            "session_start",
            {
                "platform": getattr(renpy, "version_string", "renpy"),
                "version": getattr(config, "version", ""),
            },
        )
        tel_flush(force=True)

    def tel_cta_click(dest):
        tel_track("cta_click", {"dest": dest}, etype="click")
        tel_flush(force=True)
        return True

label tel_boot:
    $ tel_ensure_session()
    return

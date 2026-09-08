/* Canonical itch/play telemetry SDK.
 * Copy into each game folder (itch zips are per-slug). Keep copies in sync.
 *
 * Writes:
 *   1) GET  {API}/scout/api/visit  — live today (funnel breadcrumbs on Pop scout)
 *   2) POST {API}/tel/batch        — full events once gateway mounts shared/play_tel.py
 *
 * Not collected: keystrokes, chat, IP, emails, precise GPS.
 */
(function (root) {
  "use strict";

  var VISIT_NAMES = {
    boot: 1, title: 1, how: 1, credits: 1, ops: 1, play: 1, naming: 1,
    win: 1, lose: 1, bounce: 1, session_end: 1, game_started: 1,
    intro_shown: 1, intro_closed: 1, level_completed: 1, context: 1,
    first_input: 1, screen: 1
  };

  function visitSrc(name, value) {
    var v = value && typeof value === "object" ? value : {};
    var src;
    if (name === "context") {
      src = "ctx." + (v.embed || "x") + "." + ((v.w || 0) < 700 ? "m" : "d");
    } else if (name === "play" || name === "naming" || name === "win") {
      src = name + ".op" + (v.op || 0);
    } else if (name === "lose") {
      src = "lose." + (v.reason || "x") + ".op" + (v.op || 0);
    } else if (name === "session_end") {
      src = "end." + (v.last || "x") + "." + Math.min(9999, v.dur | 0) + "s";
    } else if (name === "screen") {
      src = "sc." + (v.screen || "x");
    } else if (name === "level_completed") {
      src = "lv." + (v.level || 0);
    } else if (name === "first_input") {
      src = "in." + Math.min(999, (v.ms / 1000) | 0) + "s";
    } else {
      src = String(name || "x");
    }
    return String(src).toLowerCase().replace(/[^a-z0-9._-]+/g, ".").replace(/^\.+|\.+$/g, "").slice(0, 80);
  }

  function detectEmbed() {
    var host = "";
    try { host = String(root.location && root.location.hostname || ""); } catch (e) { host = ""; }
    var ref = "";
    try { ref = String(root.document && root.document.referrer || ""); } catch (e2) { ref = ""; }
    if (/itch\.io|itch\.zone/i.test(host) || /itch\.io|itch\.zone/i.test(ref)) return "itch";
    try {
      if (root.parent && root.parent !== root) return "embed";
    } catch (e3) {
      return "itch";
    }
    if (/jam/i.test(ref)) return "jam";
    return "direct";
  }

  function createTel(opts) {
    opts = opts || {};
    var API = String(opts.api || (root.TEL_API || root.API || "https://apps.blazecore.dev")).replace(/\/+$/, "");
    var APP = String(opts.app || root.TEL_APP || "unknown").slice(0, 40);
    var fetchFn = opts.fetch || (typeof fetch === "function" ? fetch.bind(root) : null);
    var store = opts.storage;
    if (!store) {
      try { store = root.localStorage; } catch (e) { store = null; }
    }
    var pid = "u" + Math.random().toString(36).slice(2, 10);
    var returning = false;
    try {
      if (store) {
        var existing = store.getItem("tel_pid");
        returning = !!existing;
        pid = existing || pid;
        store.setItem("tel_pid", pid);
      }
    } catch (e2) {}
    var sid = "s" + Math.random().toString(36).slice(2, 10);
    var t0 = Date.now();
    var queue = [];
    var visitCount = 0;
    var played = false;
    var lastScreen = "boot";
    var firstInputSent = false;

    function push(etype, name, value, dur) {
      var payload = value;
      if (payload && typeof payload !== "string") {
        try { payload = JSON.stringify(payload); } catch (e) { payload = ""; }
      }
      queue.push({
        app: APP,
        pid: pid,
        sid: sid,
        etype: String(etype || "custom").slice(0, 24),
        name: String(name || "").slice(0, 120),
        value: String(payload || "").slice(0, 2000),
        dur: dur || 0
      });
      if (queue.length >= 8) flush(false);
    }

    function visit(name, value) {
      if (!VISIT_NAMES[name] || visitCount >= 12 || !API) return;
      visitCount += 1;
      var src = visitSrc(name, value);
      var url = API + "/scout/api/visit?app=" + encodeURIComponent(APP) +
        "&app_=" + encodeURIComponent(APP) +
        "&src=" + encodeURIComponent(src) +
        "&ref=" + encodeURIComponent((detectEmbed() + "/" + APP).slice(0, 120));
      if (opts.visit) {
        opts.visit(url);
        return;
      }
      try {
        if (root.navigator && root.navigator.sendBeacon) {
          root.navigator.sendBeacon(url);
        } else if (fetchFn) {
          fetchFn(url, { method: "GET", mode: "no-cors", keepalive: true }).catch(function () {});
        }
      } catch (e) {}
    }

    function flush(useBeacon) {
      if (!queue.length || !API) {
        queue = [];
        return;
      }
      var batch = queue.splice(0, 50);
      var body = JSON.stringify(batch);
      var url = API + "/tel/batch";
      if (opts.batch) {
        opts.batch(url, batch);
        return;
      }
      try {
        if (useBeacon && root.navigator && root.navigator.sendBeacon) {
          root.navigator.sendBeacon(url, new Blob([body], { type: "application/json" }));
        } else if (fetchFn) {
          fetchFn(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: body,
            keepalive: true,
            mode: "cors"
          }).catch(function () {});
        }
      } catch (e) {}
    }

    function ev(name, value) {
      if (name === "play" || name === "game_started" || name === "level_opened") played = true;
      if (name === "screen" && value && value.screen) lastScreen = value.screen;
      if (name === "title" || name === "how" || name === "ops" || name === "play" || name === "debrief") {
        lastScreen = name;
      }
      push("custom", name, value || {}, 0);
      visit(name, value || {});
    }

    function context() {
      var w = 0, h = 0, dpr = 1;
      try {
        w = root.innerWidth | 0;
        h = root.innerHeight | 0;
        dpr = root.devicePixelRatio || 1;
      } catch (e) {}
      var ctx = {
        embed: detectEmbed(),
        w: w,
        h: h,
        dpr: Math.round(dpr * 100) / 100,
        lang: (root.document && root.document.documentElement && root.document.documentElement.lang) || "",
        returning: returning,
        standalone: !!(root.matchMedia && root.matchMedia("(display-mode: standalone)").matches)
      };
      ev("context", ctx);
      return ctx;
    }

    function onFirstInput() {
      if (firstInputSent) return;
      firstInputSent = true;
      ev("first_input", { ms: Date.now() - t0, last: lastScreen });
    }

    if (root.document && root.document.addEventListener) {
      root.document.addEventListener("click", onFirstInput, true);
      root.document.addEventListener("keydown", onFirstInput, true);
      root.document.addEventListener("pointerdown", onFirstInput, true);
      root.document.addEventListener("visibilitychange", function () {
        if (root.document.hidden) flush(true);
      });
    }
    if (root.addEventListener) {
      root.addEventListener("beforeunload", function () {
        var dur = Math.round((Date.now() - t0) / 1000);
        if (!played) ev("bounce", { last: lastScreen, dur: dur });
        ev("session_end", { last: lastScreen, dur: dur, played: played });
        flush(true);
      });
    }
    if (typeof setInterval === "function") {
      var iv = setInterval(function () { flush(false); }, 20000);
      if (iv && typeof iv.unref === "function") iv.unref();
    }

    push("pageview", "boot", { path: (root.location && root.location.pathname) || "/", title: (root.document && root.document.title) || "" }, 0);
    visit("boot", {});
    context();

    return {
      ev: ev,
      funnel: ev,
      flush: flush,
      visitSrc: visitSrc,
      pid: pid,
      sid: sid,
      app: APP
    };
  }

  if (typeof window !== "undefined") {
    var api = createTel({});
    window.TEL = {
      ev: api.ev,
      funnel: api.ev,
      feedback: function (score, note) { api.ev("feedback", { score: score, note: String(note || "").slice(0, 500) }); },
      chat: function (u, r) { api.ev("chat", { u: String(u || "").slice(0, 200), r: String(r || "").slice(0, 200) }); },
      flush: api.flush,
      pid: api.pid,
      sid: api.sid
    };
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = { createTel: createTel, visitSrc: visitSrc, VISIT_NAMES: VISIT_NAMES };
  }
})(typeof window !== "undefined" ? window : globalThis);

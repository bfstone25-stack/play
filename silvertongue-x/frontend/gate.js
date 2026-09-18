/* gate.js — the dual-track unlock gate every product shares (ops/DUAL_TRACK.md).
 *
 * Two tracks, decided at runtime:
 *   itch_web  (itch.io, apps.blazecore.dev)  a locked thing shows a price; "Not now" keeps playing the free part.
 *   ads_web   (*.pages.dev, or window.DIST="ads_web")  a locked thing unlocks after one timed sponsor clip.
 *
 * Usage, in the game, at the cut point:
 *   Gate.require("op2", {title: "Operation 2", kind: "level"}).then(function (r) {
 *     if (r === "unlocked") startOp(2);      // paid track never gets here for a locked key; ads track does after the clip
 *   });
 * Config, once per page:  window.GATE_CONFIG = {price: "$1.99", buyUrl: "https://....itch.io/...", seconds: 30}
 * The sponsor creative is window.AD_HTML (Adsterra snippet from ads_config.js); empty = plain placeholder.
 *
 * Every decision is telemetry: paywall_seen / paywall_decision(buy_click|dismiss, dwell) on the paid track,
 * ad_prompt_shown / ad_watched / ad_completed / ad_quit on the ad track. No popunders, ever.
 */
(function () {
  if (window.Gate) return;
  var KEY = "gate_unlocks";
  // Our own test runs must never request a real ad: repeated loads from one browser are
  // what ad networks flag as invalid traffic, and they bill it back.
  function isBot(){ try { return !!navigator.webdriver || / HeadlessChrome\//.test(navigator.userAgent || ""); } catch (e) { return false; } }

  function cfg() { return window.GATE_CONFIG || {}; }
  function dist() {
    try { var q = new URLSearchParams(location.search).get("dist"); if (q === "ads_web" || q === "itch_web") return q; } catch (e) {}  // testing
    if (window.DIST === "ads_web" || window.DIST === "itch_web" || window.DIST === "paid") return window.DIST;
    return /\.pages\.dev$/.test(location.hostname) ? "ads_web" : "itch_web";
  }
  function unlocks() { try { return JSON.parse(localStorage.getItem(KEY) || "{}") || {}; } catch (e) { return {}; } }
  function remember(key) { var u = unlocks(); u[key] = Date.now(); try { localStorage.setItem(KEY, JSON.stringify(u)); } catch (e) {} }
  function tel(name, value, dur) { try { if (window.TEL) window.TEL.ev(name, value || {}); if (dur && window.TEL && window.TEL.flush) window.TEL.flush(); } catch (e) {} }
  function css(el, s) { for (var k in s) el.style[k] = s[k]; return el; }
  function el(tag, style, text) { var e = css(document.createElement(tag), style || {}); if (text) e.textContent = text; return e; }
  var overlayStyle = {position: "fixed", inset: "0", zIndex: "99999", background: "rgba(8,6,12,0.96)", display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center", fontFamily: "system-ui, sans-serif", color: "#eee", textAlign: "center", padding: "16px"};
  var primary = {marginTop: "14px", padding: "12px 28px", fontSize: "18px", background: "#d95a43", color: "#fff", border: "0", borderRadius: "6px", cursor: "pointer"};
  var quiet = {marginTop: "10px", background: "none", border: "0", color: "#998", textDecoration: "underline", cursor: "pointer", fontSize: "14px"};

  function adGate(key, opts) {
    return new Promise(function (resolve) {
      var seconds = cfg().seconds || 30, box = el("div", overlayStyle), t0 = Date.now(), timer = null;
      box.appendChild(el("div", {fontSize: "22px", color: "#d99b66", marginBottom: "12px"}, (opts.title || "This part") + " unlocks after one sponsor clip"));
      var slot = el("div", {width: "min(90vw, 728px)", minHeight: "250px", background: "#151020", border: "1px solid #3a2a44", display: "flex", alignItems: "center", justifyContent: "center", color: "#665"});
      slot.setAttribute("data-tel-ad", "gate");
      if (window.AD_HTML && !isBot()) { var f = document.createElement("iframe"); f.width = "300"; f.height = "250"; f.style.border = "0"; f.style.background = "#000";
        f.setAttribute("scrolling", "no"); f.srcdoc = '<body style="margin:0;background:#000">' + window.AD_HTML + "</body>"; slot.appendChild(f); } else slot.textContent = "Sponsor slot";
      var count = el("div", {fontSize: "18px", marginTop: "14px", color: "#c8b8b0"}, seconds + "s");
      var btn = el("button", primary, "Continue"); btn.disabled = true; css(btn, {background: "#3a2a44", color: "#887", cursor: "not-allowed"});
      var quit = el("button", quiet, "Not now");
      box.appendChild(slot); box.appendChild(count); box.appendChild(btn); box.appendChild(quit);
      document.body.appendChild(box);
      tel("ad_prompt_shown", {key: key, kind: opts.kind || "", dist: "ads_web"});
      var left = seconds;
      timer = setInterval(function () {
        if (document.hidden) return;                       // the clock only runs while they are looking
        left--; count.textContent = left > 0 ? left + "s" : "Unlocked";
        if (left <= 0) { clearInterval(timer); btn.disabled = false; css(btn, primary); tel("ad_watched", {key: key, s: Math.round((Date.now() - t0) / 1000)}); }
      }, 1000);
      function close(r) { clearInterval(timer); box.remove(); resolve(r); }
      btn.onclick = function () { remember(key); tel("ad_completed", {key: key, kind: opts.kind || "", s: Math.round((Date.now() - t0) / 1000)}, true); close("unlocked"); };
      quit.onclick = function () { tel("ad_quit", {key: key, kind: opts.kind || "", s: Math.round((Date.now() - t0) / 1000)}, true); close("closed"); };
    });
  }

  // Adsterra Direct Link: the ad is served on Adsterra's own page, so this works from
  // html-classic.itch.zone and any other host we do not own. Opened only by a deliberate
  // click, one per key, never automatically.
  function directLinkGate(key, opts) {
    return new Promise(function (resolve) {
      var url = cfg().directLink, secs = cfg().directLinkSeconds || 20;
      var box = el("div", overlayStyle), left = secs, t0 = Date.now();
      box.appendChild(el("div", {fontSize: "24px", color: "#70c080", marginBottom: "8px"},
        (opts.title || "This part") + " unlocks after the sponsor page"));
      box.appendChild(el("div", {fontSize: "16px", color: "#c8b8b0", maxWidth: "540px"},
        "The sponsor page opens in a new tab. Come back here when you are done."));
      var count = el("div", {fontSize: "20px", marginTop: "14px", color: "#ffdfa0"}, left + "s");
      var go = el("button", primary, "Unlock"); go.disabled = true;
      css(go, {background: "#2a3a2e", color: "#889", cursor: "not-allowed"});
      var quit = el("button", quiet, "Not now");
      box.appendChild(count); box.appendChild(go); box.appendChild(quit);
      document.body.appendChild(box);
      tel("directlink_open", {key: key, kind: opts.kind || ""});
      if (!isBot()) window.open(url, "_blank");
      var timer = setInterval(function () {
        left--; count.textContent = left > 0 ? left + "s" : "Ready";
        if (left <= 0) { clearInterval(timer); go.disabled = false; css(go, {background: "#3a7a4a", color: "#fff", cursor: "pointer"}); }
      }, 1000);
      function close(r) { clearInterval(timer); box.remove(); resolve(r); }
      go.onclick = function () { remember(key); tel("directlink_returned", {key: key, s: Math.round((Date.now() - t0) / 1000)}, true); close("unlocked"); };
      quit.onclick = function () { tel("directlink_quit", {key: key, s: Math.round((Date.now() - t0) / 1000)}, true); close("closed"); };
    });
  }

  function buyGate(key, opts) {
    return new Promise(function (resolve) {
      var box = el("div", overlayStyle), t0 = Date.now(), price = cfg().price || "", url = cfg().buyUrl || "";
      box.appendChild(el("div", {fontSize: "24px", color: "#ffdfa0", marginBottom: "8px"}, (opts.title || "This part") + " is in the full game"));
      if (opts.blurb) box.appendChild(el("div", {fontSize: "16px", color: "#c8b8b0", maxWidth: "560px"}, opts.blurb));
      var buy = el("button", primary, "Unlock everything" + (price ? " — " + price : ""));
      var free = cfg().directLink ? el("button", {marginTop: "12px", padding: "11px 24px", fontSize: "17px",
        background: "#1a2a1e", color: "#70c080", border: "0", borderRadius: "6px", cursor: "pointer"},
        "▶ Unlock free — open sponsor") : null;
      var later = el("button", quiet, opts.skipLabel || "Not now");
      box.appendChild(buy); if (free) box.appendChild(free); box.appendChild(later); document.body.appendChild(box);
      if (free) free.onclick = function () {
        tel("paywall_decision", {key: key, what: "directlink_click", dwell_s: Math.round((Date.now() - t0) / 1000)}, true);
        box.remove(); directLinkGate(key, opts).then(resolve);
      };
      tel("paywall_seen", {key: key, kind: opts.kind || "", dist: "itch_web"});
      function decide(what, r) {
        tel("paywall_decision", {key: key, what: what, dwell_s: Math.round((Date.now() - t0) / 1000)}, true);
        box.remove(); resolve(r);
      }
      buy.onclick = function () { decide("buy_click", "closed"); if (url) window.open(url, "_blank"); };
      later.onclick = function () { decide("dismiss", "closed"); };
    });
  }

  // ---- portal track -------------------------------------------------------
  // On CrazyGames / Poki / GameDistribution our own ads and paywalls are forbidden and the
  // platform pays a revenue share instead. The cut points we already chose (next level,
  // next chapter, next night) are exactly where a midgame ad belongs, so on a portal
  // Gate.require plays *their* ad and then always continues.
  var lastAd = 0;
  function portal() { return window.PORTAL_PLATFORM || ""; }
  function portalAd(key) {
    var gap = (Date.now() - lastAd) / 1000;
    if (lastAd && gap < (window.PORTAL_AD_GAP_S || 150)) return Promise.resolve("unlocked");
    lastAd = Date.now();
    tel("portal_ad_requested", {key: key, platform: portal()});
    return new Promise(function (resolve) {
      var done = function (how) { tel("portal_ad_" + how, {key: key, platform: portal()}); resolve("unlocked"); };
      var timer = setTimeout(function () { done("timeout"); }, 45000);
      var finish = function (how) { clearTimeout(timer); done(how); };
      try {
        if (portal() === "crazygames" && window.CrazyGames) {
          window.CrazyGames.SDK.ad.requestAd("midgame", {
            adFinished: function () { finish("finished"); },
            adError: function () { finish("error"); },
          });
        } else if (portal() === "poki" && window.PokiSDK) {
          window.PokiSDK.commercialBreak().then(function () { finish("finished"); }, function () { finish("error"); });
        } else if (portal() === "gamedistribution" && window.gdsdk) {
          window.gdsdk.showAd().then(function () { finish("finished"); }, function () { finish("error"); });
        } else {
          finish("unavailable");
        }
      } catch (e) { finish("error"); }
    });
  }

  window.Gate = {
    dist: dist,
    has: function (key) { return !!unlocks()[key]; },
    // AFTER HOURS: CG keys are granted by the server's symbolic engine rather than by a
    // gate the player passes, so the fork needs a public way to record one. Namespaced
    // `cg_*` by the caller, so a duel unlock and its art stay separate keys.
    unlock: remember,
    require: function (key, opts) {
      opts = opts || {};
      if (portal()) return portalAd(key);
      if (dist() === "paid" || window.Gate.has(key)) return Promise.resolve("unlocked");
      return dist() === "ads_web" ? adGate(key, opts) : buyGate(key, opts);
    }
  };
})();

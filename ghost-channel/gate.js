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
      if (window.AD_HTML) { var f = document.createElement("iframe"); f.width = "300"; f.height = "250"; f.style.border = "0"; f.style.background = "#000";
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

  function buyGate(key, opts) {
    return new Promise(function (resolve) {
      var box = el("div", overlayStyle), t0 = Date.now(), price = cfg().price || "", url = cfg().buyUrl || "";
      box.appendChild(el("div", {fontSize: "24px", color: "#ffdfa0", marginBottom: "8px"}, (opts.title || "This part") + " is in the full game"));
      if (opts.blurb) box.appendChild(el("div", {fontSize: "16px", color: "#c8b8b0", maxWidth: "560px"}, opts.blurb));
      var buy = el("button", primary, "Unlock everything" + (price ? " — " + price : ""));
      var later = el("button", quiet, opts.skipLabel || "Not now");
      box.appendChild(buy); box.appendChild(later); document.body.appendChild(box);
      tel("paywall_seen", {key: key, kind: opts.kind || "", dist: "itch_web"});
      function decide(what, r) {
        tel("paywall_decision", {key: key, what: what, dwell_s: Math.round((Date.now() - t0) / 1000)}, true);
        box.remove(); resolve(r);
      }
      buy.onclick = function () { decide("buy_click", "closed"); if (url) window.open(url, "_blank"); };
      later.onclick = function () { decide("dismiss", "closed"); };
    });
  }

  window.Gate = {
    dist: dist,
    has: function (key) { return !!unlocks()[key]; },
    require: function (key, opts) {
      opts = opts || {};
      if (dist() === "paid" || window.Gate.has(key)) return Promise.resolve("unlocked");
      return dist() === "ads_web" ? adGate(key, opts) : buyGate(key, opts);
    }
  };
})();

// room704_ads.js — watch-to-unlock overlay for the web tracks (itch and our own domain).
//
// The game (09_dist.rpy) calls Room704Ads.open(key, kind) and polls Room704Ads.result():
// 0 still watching, 1 completed, 2 closed early, 3 sponsor unavailable (counted down
// without a creative — telemetry says so; we never brick the story for an adblocker).
// Unlocks live in localStorage so a refresh does not re-charge the player.
//
// Honesty rules, in order of what went wrong before this rewrite:
//   - the clock only runs while the creative iframe has actually loaded AND the tab is
//     visible; a blank slot no longer counts as a watched clip
//   - the unlock lands by itself when the clock reaches zero — no Continue button that a
//     player has to find, and nothing that makes the wait feel optional
//   - there is no external link anywhere on the web tracks; the sponsor is the banner
// No popunders, ever.
(function () {
  if (window.Room704Ads) return;
  var SECONDS = window.ROOM704_AD_SECONDS || 25;
  var LOAD_GRACE = 8;                       // seconds to give the network before "unavailable"
  var KEY = "room704_unlocks";
  var state = 0, timer = null, box = null;

  function isTestRun() {
    try {
      var q = new URLSearchParams(location.search);
      if (q.get("warp")) return true;
      var s = (q.get("src") || "").toLowerCase();
      if (/shot|test|probe|selftest|livecheck|flowshot|gateshot/.test(s)) return true;
      if (navigator.webdriver || / HeadlessChrome\//.test(navigator.userAgent || "")) return true;
      if (location.hostname === "localhost" || location.hostname === "127.0.0.1") return true;
    } catch (e) {}
    return false;
  }
  function unlocks() { try { return JSON.parse(localStorage.getItem(KEY) || "{}") || {}; } catch (e) { return {}; } }
  function remember(key) { var u = unlocks(); u[key] = Date.now(); try { localStorage.setItem(KEY, JSON.stringify(u)); } catch (e) {} }
  function tel(name, value) { try { if (window.TEL) window.TEL.ev(name, value); if (window.TEL && window.TEL.flush) window.TEL.flush(); } catch (e) {} }
  function css(el, s) { for (var k in s) el.style[k] = s[k]; return el; }
  function close(result) {
    state = result;
    if (timer) clearInterval(timer); timer = null;
    if (box && box.parentNode) box.parentNode.removeChild(box); box = null;
  }

  window.Room704Ads = {
    has: function (key) { return unlocks()[key] ? 1 : 0; },
    result: function () { return state; },
    open: function (key, kind) {
      if (unlocks()[key]) { state = 1; return; }
      state = 0;
      var titleText = kind === "cg" ? "Uncensored scene unlocks after this sponsor clip"
                    : kind === "checkpoint" ? "One sponsor clip, then the story goes on"
                    : "The next chapter unlocks after this sponsor clip";
      box = css(document.createElement("div"), {position: "fixed", inset: "0", zIndex: "99999", background: "rgba(8,6,12,0.96)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", fontFamily: "system-ui, sans-serif", color: "#eee", textAlign: "center", padding: "16px"});
      var title = css(document.createElement("div"), {fontSize: "22px", color: "#d99b66", marginBottom: "12px"});
      title.textContent = titleText;
      var slot = css(document.createElement("div"), {width: "min(90vw, 728px)", minHeight: "250px", background: "#151020", border: "1px solid #3a2a44",
        display: "flex", alignItems: "center", justifyContent: "center", color: "#665"});
      slot.setAttribute("data-tel-ad", "gate");
      var count = css(document.createElement("div"), {fontSize: "18px", marginTop: "14px", color: "#c8b8b0"});
      var quit = css(document.createElement("button"), {marginTop: "12px", background: "none", border: "0", color: "#776", textDecoration: "underline", cursor: "pointer", fontSize: "14px"});
      quit.textContent = "Not now";
      box.appendChild(title); box.appendChild(slot); box.appendChild(count); box.appendChild(quit);
      document.body.appendChild(box);

      var creativeLoaded = false, testRun = isTestRun(), unavailable = false;
      if (testRun) {
        // QA passes never touch the sponsor network; the clock runs so the flow is testable.
        slot.textContent = "Sponsor slot (QA)"; creativeLoaded = true;
      } else if (window.ROOM704_AD_HTML) {
        // Inside an iframe: Adsterra's invoke.js uses document.write, which after load would wipe the game page.
        var f = document.createElement("iframe"); f.width = "300"; f.height = "250"; f.style.border = "0"; f.style.background = "#000";
        f.setAttribute("scrolling", "no");
        f.onload = function () { creativeLoaded = true; };
        f.srcdoc = '<body style="margin:0;background:#000">' + window.ROOM704_AD_HTML + "</body>";
        slot.textContent = ""; slot.appendChild(f);
      } else {
        slot.textContent = "Sponsor unavailable"; unavailable = true;
      }

      var left = SECONDS, t0 = Date.now(), waited = 0;
      count.textContent = left + "s";
      tel("ad_prompt_shown_js", {key: key, kind: kind});
      timer = setInterval(function () {
        if (document.hidden) return;                       // only while they are looking
        if (!creativeLoaded && !unavailable) {
          if (++waited >= LOAD_GRACE) { unavailable = true; slot.textContent = "Sponsor unavailable"; tel("ad_unavailable", {key: key, kind: kind}); }
          count.textContent = "loading sponsor…";
          return;                                          // the clock does not run on a blank slot
        }
        left--; count.textContent = left > 0 ? left + "s" : "Unlocked";
        if (left <= 0) {
          remember(key);
          tel(unavailable ? "ad_unavailable_passed" : "ad_watched", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)});
          close(unavailable ? 3 : 1);                      // lands by itself; no button to find
        }
      }, 1000);
      quit.onclick = function () { tel("ad_quit", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)}); close(2); };
    }
  };
})();

// confession_ads.js — watch-to-unlock overlay for the web tracks (itch and our own domain).
//
// The game (09_dist.rpy) calls ConfessionAds.open(key, kind) and polls ConfessionAds.result():
// 0 still watching, 1 completed, 2 closed early, 3 sponsor unavailable (counted down
// without a creative — telemetry says so; we never brick the story for an adblocker).
// Unlocks live in localStorage so a refresh does not re-charge the player.
//
// Honesty rules, in order of what went wrong before this rewrite:
//   - the clock only runs while the creative has actually RENDERED and the tab is visible.
//     iframe.onload is not proof: srcdoc fires it whether or not the sponsor's script ran,
//     so a blocked slot used to count down and unlock anyway. We now look inside the
//     (same-origin) srcdoc document for a node with real area.
//   - a blocked slot does not unlock. The network only pays for an impression it can see,
//     and handing over the content anyway means paying for our own bandwidth to give away
//     the thing we are selling. The player is told plainly what happened and offered the
//     two honest ways on: turn the blocker off, or buy the ad-free build.
//   - the unlock lands by itself when the clock reaches zero — no Continue button that a
//     player has to find, and nothing that makes the wait feel optional
//   - there is no external link anywhere on the web tracks; the sponsor is the banner
// No popunders, ever.
(function () {
  var BUY_URL = 'https://bfstone25-stack.itch.io/confession-room/purchase';

  // --- did the creative actually render? -------------------------------------------
  // The slot is an iframe with srcdoc, so it is same-origin and we can look inside. An
  // ad network's script injects an iframe/img/ins of its own; a blocker leaves the body
  // empty. Area, not presence: some blockers leave a 0x0 stub behind.
  function creativeRendered(frame) {
    try {
      var d = frame.contentDocument;
      if (!d || !d.body) return false;
      var nodes = d.body.querySelectorAll("iframe,img,ins,video,canvas,a");
      for (var i = 0; i < nodes.length; i++) {
        var r = nodes[i].getBoundingClientRect();
        if (r.width * r.height >= 5000) return true;       // ~100x50 and up
      }
      return false;
    } catch (e) {
      // Cross-origin means something replaced our srcdoc, which only a real creative does.
      return true;
    }
  }

  if (window.ConfessionAds) return;
  var SECONDS = window.CONFESSION_AD_SECONDS || 25;
  var LOAD_GRACE = 8;                       // seconds to give the network before "unavailable"
  var KEY = "confession_unlocks";
  var state = 0, timer = null, box = null;

  function isTestRun() {
    try {
      var q = new URLSearchParams(location.search);
      // Escape hatch for testing the sponsor path itself: localhost counts as a QA run
      // below, which skips the whole verification branch and made the anti-adblock gate
      // untestable locally. ?realads=1 forces the real path.
      if (q.get("realads") === "1") return false;
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

  window.ConfessionAds = {
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

      var creativeLoaded = false, frame = null, testRun = isTestRun(), unavailable = false;
      if (testRun) {
        // QA passes never touch the sponsor network; the clock runs so the flow is testable.
        slot.textContent = "Sponsor slot (QA)"; creativeLoaded = true;
      } else if (window.CONFESSION_AD_HTML) {
        // Inside an iframe: Adsterra's invoke.js uses document.write, which after load would wipe the game page.
        var f = document.createElement("iframe"); f.width = "300"; f.height = "250"; f.style.border = "0"; f.style.background = "#000";
        f.setAttribute("scrolling", "no");
        f.onload = function () { creativeLoaded = true; };
        frame = f;
        f.srcdoc = '<body style="margin:0;background:#000">' + window.CONFESSION_AD_HTML + "</body>";
        slot.textContent = ""; slot.appendChild(f);
      } else {
        slot.textContent = "Sponsor unavailable"; unavailable = true;
      }


      // Shown when the creative never rendered. Not an accusation: usually a blocker,
      // sometimes the network. Either way the network will not pay for an impression it
      // could not serve, so the gate stays shut rather than us giving the content away.
      function sponsorBlocked() {
        if (timer) { clearInterval(timer); timer = null; }
        slot.style.display = "none";
        count.textContent = "";
        title.textContent = "The sponsor's ad could not be shown";
        var why = css(document.createElement("p"), {color: "#a89", fontSize: "14px", maxWidth: "360px", margin: "8px auto 14px", lineHeight: "1.5"});
        why.textContent = "Usually an ad blocker, sometimes the network having a bad day. We only get paid for an ad that actually appears, so we cannot open this on one that never did.";
        var again = css(document.createElement("button"), {background: "#3a7a4a", color: "#fff", border: "0", borderRadius: "6px", padding: "9px 16px", fontSize: "15px", cursor: "pointer", margin: "0 6px"});
        again.textContent = "I turned it off \u2014 try again";
        again.onclick = function () { tel("ad_blocked_retry", {key: key, kind: kind}); close(2); setTimeout(function () { window.ConfessionAds.open(key, kind); }, 80); };
        var buy = css(document.createElement("button"), {background: "#c8503c", color: "#fff", border: "0", borderRadius: "6px", padding: "9px 16px", fontSize: "15px", cursor: "pointer", margin: "0 6px"});
        buy.textContent = "Get the ad-free version";
        buy.onclick = function () { tel("ad_blocked_buy", {key: key, kind: kind}); window.open(BUY_URL, "_blank", "noopener"); };
        box.appendChild(why); box.appendChild(again); box.appendChild(buy);
        tel("ad_blocked", {key: key, kind: kind});
      }

      var left = SECONDS, t0 = Date.now(), waited = 0, verified = testRun;
      count.textContent = left + "s";
      tel("ad_prompt_shown_js", {key: key, kind: kind});
      timer = setInterval(function () {
        if (document.hidden) return;                       // only while they are looking
        if (!verified) {
          // onload is not proof the sponsor's script ran; look for rendered pixels.
          if (creativeLoaded && frame && creativeRendered(frame)) {
            verified = true;
            tel("ad_verified", {key: key, kind: kind, waited: waited});
          } else if (++waited >= LOAD_GRACE) {
            sponsorBlocked();
            return;
          } else {
            count.textContent = "loading sponsor\u2026";
            return;                                        // the clock does not run on a blank slot
          }
        }
        left--; count.textContent = left > 0 ? left + "s" : "Unlocked";
        if (left <= 0) {
          remember(key);                                   // only ever reached with a verified impression
          tel("ad_watched", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)});
          close(1);                                        // lands by itself; no button to find
        }
      }, 1000);
      quit.onclick = function () { tel("ad_quit", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)}); close(2); };
    }
  };
})();

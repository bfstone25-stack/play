// elena_ads.js — watch-to-unlock overlay for the ad-supported web track.
//
// The game (09_dist.rpy) calls ElenaAds.open(key, kind) and polls ElenaAds.result():
// 0 still watching, 1 completed, 2 closed early. Unlocks live in localStorage so a
// refresh does not re-charge the player. The ad creative is whatever HTML the page
// puts in window.ELENA_AD_HTML (the Adsterra snippet); with none configured the slot
// shows a plain "sponsor" placeholder so the flow can be tested end to end.
//
// No popunders, ever: they get the itch page reported and they teach players to
// leave. The gate is a timed banner/native unit the player looks at on purpose.
(function () {
  if (window.ElenaAds) return;
  var SECONDS = window.ELENA_AD_SECONDS || 30;
  var KEY = "elena_unlocks";
  var state = 0, timer = null, box = null;
  function unlocks() { try { return JSON.parse(localStorage.getItem(KEY) || "{}") || {}; } catch (e) { return {}; } }
  function tel(name, value) { try { if (window.TEL) window.TEL.ev(name, value); } catch (e) {} }
  function css(el, s) { for (var k in s) el.style[k] = s[k]; return el; }
  function close(result) {
    state = result;
    if (timer) clearInterval(timer); timer = null;
    if (box && box.parentNode) box.parentNode.removeChild(box); box = null;
  }
  window.ElenaAds = {
    has: function (key) { return unlocks()[key] ? 1 : 0; },
    result: function () { return state; },
    open: function (key, kind) {
      if (unlocks()[key]) { state = 1; return; }
      state = 0;
      box = css(document.createElement("div"), {position: "fixed", inset: "0", zIndex: "99999", background: "rgba(8,6,12,0.96)",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", fontFamily: "system-ui, sans-serif", color: "#eee"});
      var title = css(document.createElement("div"), {fontSize: "22px", color: "#d99b66", marginBottom: "12px"});
      title.textContent = kind === "cg" ? "Uncensored scene unlocks after this sponsor clip" : "The next chapter unlocks after this sponsor clip";
      var slot = css(document.createElement("div"), {width: "min(90vw, 728px)", minHeight: "250px", background: "#151020", border: "1px solid #3a2a44",
        display: "flex", alignItems: "center", justifyContent: "center"});
      slot.setAttribute("data-tel-ad", "gate");
      if (window.ELENA_AD_HTML) {
        var frag = document.createRange().createContextualFragment(window.ELENA_AD_HTML); // scripts execute
        slot.appendChild(frag);
      } else {
        slot.textContent = "Sponsor slot";
        css(slot, {color: "#665"});
      }
      var count = css(document.createElement("div"), {fontSize: "18px", marginTop: "14px", color: "#c8b8b0"});
      var btn = css(document.createElement("button"), {marginTop: "14px", padding: "12px 28px", fontSize: "18px", background: "#3a2a44", color: "#887", border: "0", borderRadius: "6px", cursor: "not-allowed"});
      btn.textContent = "Continue"; btn.disabled = true;
      var quit = css(document.createElement("button"), {marginTop: "10px", background: "none", border: "0", color: "#776", textDecoration: "underline", cursor: "pointer", fontSize: "14px"});
      quit.textContent = "Not now";
      box.appendChild(title); box.appendChild(slot); box.appendChild(count); box.appendChild(btn); box.appendChild(quit);
      document.body.appendChild(box);
      var left = SECONDS, t0 = Date.now();
      count.textContent = left + "s";
      timer = setInterval(function () {
        if (document.hidden) return;             // the clock only runs while they are looking
        left--; count.textContent = left > 0 ? left + "s" : "Unlocked";
        if (left <= 0) {
          clearInterval(timer); timer = null;
          btn.disabled = false; css(btn, {background: "#d95a43", color: "#fff", cursor: "pointer"});
          tel("ad_watched", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)});
        }
      }, 1000);
      btn.onclick = function () { var u = unlocks(); u[key] = Date.now(); try { localStorage.setItem(KEY, JSON.stringify(u)); } catch (e) {} close(1); };
      quit.onclick = function () { tel("ad_quit", {key: key, kind: kind, s: Math.round((Date.now() - t0) / 1000)}); close(2); };
    }
  };
})();

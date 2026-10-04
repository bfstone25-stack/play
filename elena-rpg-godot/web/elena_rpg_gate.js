/* elena_rpg_gate.js — the free web edition's gates (Elena: Crimson Archives RPG).
 *
 * Ships ONLY in the ad-supported web build on our own domain (ops/elena_rpg_web_build.sh).
 * The DLsite download has no page and loads none of this.
 *
 * Blaze's rules (2026-10-03), stricter than shared/gate.js:
 *   - an 18+ gate before anything;
 *   - an unskippable ~20 s sponsor slot at the start and at every night boundary;
 *   - the countdown runs only while the creative has actually painted AND the tab is visible;
 *   - no pop-ups, pop-unders or redirects: one in-page Adsterra banner (ads_config.js);
 *   - if the sponsor cannot load (ad blocker, failure), the game does NOT continue: a plain
 *     wall asks the player to disable the blocker for this site and press Retry. There is no
 *     "unlock anyway", no "Not now", no pass-on-unavailable (unlike shared/gate.js, which lets
 *     a chapter through when the ad is down — memory ad-gate-caller-not-library).
 *
 * Contract with scripts/web_gate.gd (two evals, never a Promise through the bridge):
 *   ElenaGate.start(key) -> 1     ElenaGate.result(key) -> "" | "ok"
 * Page boot: ElenaGate.boot() runs the age gate, then the start slot, over the canvas.
 *
 * QA: automation (navigator.webdriver / HeadlessChrome) never requests a real ad — a
 * "Sponsor slot (QA)" placeholder counts instead — unless the URL has ?realads=1 (used once
 * for the live acceptance test). ?seconds=N shortens the slot for QA.
 */
(function () {
  if (window.ElenaGate) return;
  var q = new URLSearchParams(location.search);
  var SECONDS = Math.max(3, parseInt(q.get("seconds") || "20", 10) || 20);
  // creative must paint within this, or the wall. 8 s was too tight: the live test saw a
  // real creative paint at 7.6 s; an ad blocker fails at once either way.
  var GRACE_MS = 15000;
  var REPEAT_WITHIN_MS = 120000;    // a night that starts right after a completed slot does not get a second one
  var realAds = q.get("realads") === "1";
  function isBot() { try { return !!navigator.webdriver || / HeadlessChrome\//.test(navigator.userAgent || ""); } catch (e) { return false; } }
  var qa = isBot() && !realAds;
  function tel(name, v, flush) { try { if (window.TEL) { window.TEL.ev(name, v || {}); if (flush && window.TEL.flush) window.TEL.flush(); } } catch (e) {} }
  function el(tag, style, text) { var e = document.createElement(tag); for (var k in (style || {})) e.style[k] = style[k]; if (text) e.textContent = text; return e; }
  var OVER = {position: "fixed", inset: "0", zIndex: "99999", background: "rgba(10,7,12,0.97)", display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center", fontFamily: "Georgia, 'Times New Roman', serif", color: "#eadfce", textAlign: "center", padding: "16px"};
  var BTN = {marginTop: "16px", padding: "12px 30px", fontSize: "18px", background: "#8e2433", color: "#fff", border: "1px solid #c9a46a", borderRadius: "4px", cursor: "pointer"};

  var results = {}, lastOk = 0, busy = false, queue = [];

  // Is a creative actually drawing? (same test as shared/gate.js: a blocked invoke.js leaves
  // its <script> tag in the frame, so "has children" would say yes to a dead slot.)
  function painted(f) {
    try {
      var d = f.contentDocument;
      if (!d || !d.body) return false;
      var kids = d.body.querySelectorAll("iframe,img,ins,div,a,canvas,video");
      for (var i = 0; i < kids.length; i++) {
        var r = kids[i].getBoundingClientRect();
        if (r.width >= 50 && r.height >= 50) return true;
      }
      return false;
    } catch (e) { return true; }   // cross-origin body: it loaded something we may not inspect
  }

  function slotRun(title, key, done) {
    var box = el("div", OVER), t0 = Date.now(), attempt = 0;
    box.setAttribute("data-elena-gate", key);
    box.appendChild(el("div", {fontSize: "24px", color: "#c9a46a", marginBottom: "6px"}, title));
    box.appendChild(el("div", {fontSize: "15px", color: "#b9ab9a", marginBottom: "14px", maxWidth: "560px"},
      "This edition is free because of one short sponsor slot at the start and between nights. Thank you for keeping Elena free."));
    var slot = el("div", {width: "300px", height: "250px", background: "#151018", border: "1px solid #3a2a34", display: "flex", alignItems: "center", justifyContent: "center", color: "#776"});
    slot.setAttribute("data-tel-ad", "gate");
    var count = el("div", {fontSize: "18px", marginTop: "14px", color: "#d8c8b4"}, "");
    var wall = el("div", {display: "none", maxWidth: "560px", fontSize: "17px", lineHeight: "1.5"});
    box.appendChild(slot); box.appendChild(count); box.appendChild(wall);
    document.body.appendChild(box);
    tel("ad_prompt_shown", {key: key, kind: "sponsor_slot", dist: "ads_web"});
    var tick = null, grace = null, poll = null, frame = null, ready = false, left = SECONDS;

    function stop() { clearInterval(tick); clearTimeout(grace); clearInterval(poll); }
    function showWall(why) {
      stop();
      slot.style.display = "none"; count.style.display = "none";
      wall.style.display = "block"; wall.innerHTML = "";
      wall.appendChild(el("div", {fontSize: "22px", color: "#e0a080", marginBottom: "10px"}, "The sponsor could not load"));
      wall.appendChild(el("p", {}, "This free edition only continues after its sponsor slot has been shown. It looks like an ad blocker (or a network problem) stopped it."));
      wall.appendChild(el("p", {}, "Please disable your ad blocker for this site (" + location.hostname + "), then press Retry. Your progress is kept."));
      var r = el("button", BTN, "Retry");
      r.setAttribute("data-elena-retry", "1");
      r.onclick = function () { tel("ad_retry", {key: key, attempt: attempt}, true); begin(); };
      wall.appendChild(r);
      tel("ad_blocked", {key: key, why: why, attempt: attempt, s: Math.round((Date.now() - t0) / 1000)}, true);
    }
    function begin() {
      attempt++; ready = false; left = SECONDS;
      wall.style.display = "none"; slot.style.display = "flex"; count.style.display = "block";
      slot.innerHTML = ""; count.textContent = "Loading sponsor…";
      if (qa) {
        slot.textContent = "Sponsor slot (QA)"; ready = true;
      } else if (!window.AD_HTML) {
        // the sponsor script itself was blocked (ads_config.js never ran): nothing can paint
        grace = setTimeout(function () { showWall("no_snippet"); }, 1500);
      } else {
        frame = document.createElement("iframe");
        frame.width = "300"; frame.height = "250"; frame.style.border = "0"; frame.setAttribute("scrolling", "no");
        frame.srcdoc = '<body style="margin:0;background:#000">' + window.AD_HTML + "</body>";
        slot.appendChild(frame);
        poll = setInterval(function () { if (!ready && painted(frame)) { ready = true; tel("ad_shown", {key: key}); } }, 250);
        grace = setTimeout(function () { if (!ready) showWall("not_painted"); }, GRACE_MS);
      }
      tick = setInterval(function () {
        if (document.hidden || !ready) return;                    // only while it is there and looked at
        if (!qa && frame && !painted(frame)) { ready = false; return; }   // creative removed mid-slot: clock stops
        clearTimeout(grace);
        left--; count.textContent = left > 0 ? "The game continues in " + left + " s" : "Thank you";
        if (left <= 0) {
          stop();
          tel("ad_completed", {key: key, kind: "sponsor_slot", s: Math.round((Date.now() - t0) / 1000), attempt: attempt}, true);
          setTimeout(function () { box.remove(); lastOk = Date.now(); done(); }, 500);
        }
      }, 1000);
    }
    begin();
  }

  function start(key) {
    if (results[key] === "ok") return 1;
    if (Date.now() - lastOk < REPEAT_WITHIN_MS) { results[key] = "ok"; return 1; }
    results[key] = "";
    var run = function () { busy = true; slotRun("A word from our sponsor", key, function () { results[key] = "ok"; busy = false; var n = queue.shift(); if (n) n(); }); };
    if (busy) queue.push(run); else run();
    return 1;
  }

  function ageGate(next) {
    try { if (localStorage.getItem("elena_age_ok") === "1") return next(); } catch (e) {}
    var box = el("div", OVER);
    box.setAttribute("data-elena-age", "1");
    box.appendChild(el("div", {fontSize: "30px", color: "#c9a46a", marginBottom: "10px"}, "Elena: Crimson Archives"));
    box.appendChild(el("p", {fontSize: "18px", maxWidth: "560px"}, "This game is for adults only (18+). It contains sexual content. Everyone depicted is an adult."));
    box.appendChild(el("p", {fontSize: "16px", color: "#b9ab9a"}, "Are you 18 or older, and is viewing adult content legal where you are?"));
    var yes = el("button", BTN, "I am 18 or older — enter");
    var no = el("button", {marginTop: "10px", background: "none", border: "0", color: "#998", textDecoration: "underline", cursor: "pointer", fontSize: "15px"}, "No — leave");
    yes.onclick = function () { try { localStorage.setItem("elena_age_ok", "1"); } catch (e) {} tel("age_gate", {ok: 1}); box.remove(); next(); };
    no.onclick = function () { tel("age_gate", {ok: 0}, true); box.innerHTML = ""; box.appendChild(el("p", {fontSize: "20px"}, "This page is for adults only. You can close this tab.")); };
    box.appendChild(yes); box.appendChild(no);
    document.body.appendChild(box);
  }

  window.ElenaGate = {
    start: start,
    result: function (key) { return results[key] || ""; },
    boot: function () { ageGate(function () { start("start"); }); },
    qa: qa, seconds: SECONDS
  };

  // The matrix's links. Built here, on our page, so no URL ever exists inside the .pck.
  // Adult titles -> the adult hub; regular titles -> free.blazecore.dev (whose tiles in the
  // game use each title's own all-ages key visual).
  window.ElenaMore = {
    open: function (slug, world) {
      if (!/^[a-z0-9-]+$/.test(slug)) return;
      var url = (world === "adult" ? "https://afterdark.flat404.workers.dev/" : "https://free.blazecore.dev/") + slug + "/";
      tel("cross_promo_click", {to: slug, world: world, from: "elena-rpg"}, true);
      var w = null;
      try { w = window.open(url, "_blank"); if (w) w.opener = null; } catch (e) {}
      if (!w) location.href = url;   // tab refused: same tab (saves persist in the browser)
    }
  };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", window.ElenaGate.boot);
  else window.ElenaGate.boot();
})();

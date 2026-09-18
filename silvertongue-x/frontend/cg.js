/* SILVERTONGUE: AFTER HOURS — CG unlocks and gallery.
 *
 * House rule: nothing unlocks from playtime. This file never looks at a turn count, a
 * clock, or a score. It is told which keys the server's symbolic engine granted this turn
 * (read.cg) and it shows those. The engine is the only authority on what was earned.
 *
 * Keys live in their own `cg_*` namespace inside Gate's unlock store, so unlocking a duel
 * (`duel3`) never silently unlocks its art, and the gallery can ask about a plate on its
 * own.  Gate.has("cg_cg3_the_key") is the question; "duel3" is a different one.
 *
 * Tier-3 bytes: the bundle ships only the censored `_locked` plate. The uncensored file is
 * fetched from the gateway with a ticket, the way room-704/game/scripts/09_dist.rpy does
 * it. Editing localStorage therefore reveals nothing, because nothing uncensored is in the
 * bundle to reveal.
 */
(function () {
  var NS = "cg_";
  var DIR = "assets/cg/";
  var UNLOCK_API = (window.SILVERTONGUE_API || "") ;
  var APP = "silvertongue-ah";
  var fetched = {};           // key -> objectURL of an uncensored plate we did retrieve

  var SCENARIOS = ["closing_time", "the_key", "life_model", "house_rule", "last_night"];
  var WHO = {closing_time: "Mara", the_key: "Ines", life_model: "Yuen Ha",
             house_rule: "Sanne", last_night: "Teodora"};

  function gate() { return window.Gate; }
  function has(key) { var g = gate(); return !!(g && g.has(NS + key)); }
  function remember(key) { var g = gate(); if (g && g.unlock) g.unlock(NS + key); }
  function tier(key) { return parseInt(key.slice(2, 3), 10) || 1; }
  function paid() { var g = gate(); return !!(g && g.dist && g.dist() === "paid"); }

  /* Which file to show for a key. Mirrors cg_pick() in 09_dist.rpy: check for the file
   * rather than assume it, because the free bundle genuinely does not have it. */
  function src(key) {
    if (fetched[key]) return fetched[key];
    if (tier(key) < 3 || paid()) return DIR + key + ".png";
    return DIR + key + "_locked.png";
  }

  /* Ask the gateway for the uncensored tier-3 bytes. No-ops (and stays censored) when the
   * gateway is not reachable or the ticket is refused. */
  function redeem(key) {
    if (tier(key) < 3 || fetched[key]) return Promise.resolve(false);
    return fetch(UNLOCK_API + "/unlock/start", {
      method: "POST", headers: {"Content-Type": "application/json"},
      body: JSON.stringify({app: APP, key: key})
    }).then(function (r) { return r.json(); }).then(function (d) {
      if (!d || !d.ok) return false;
      return fetch(UNLOCK_API + "/unlock/fetch?ticket=" + encodeURIComponent(d.ticket) +
                   "&app=" + APP + "&key=" + encodeURIComponent(key))
        .then(function (r) { return r.ok ? r.blob() : null; })
        .then(function (b) {
          if (!b || b.size < 1024) return false;
          fetched[key] = URL.createObjectURL(b);
          try { if (window.TEL) window.TEL.ev("unlock_delivered", {key: key, bytes: b.size}); } catch (e) {}
          return true;
        });
    }).catch(function () { return false; });
  }

  function css(el, s) { for (var k in s) el.style[k] = s[k]; return el; }
  function el(tag, style, text) {
    var e = css(document.createElement(tag), style || {}); if (text) e.textContent = text; return e;
  }

  var overlay = {position: "fixed", inset: "0", zIndex: "99998", background: "rgba(8,6,12,0.94)",
                 display: "flex", flexDirection: "column", alignItems: "center",
                 justifyContent: "center", gap: "12px", padding: "16px"};

  /* Show one plate full-screen. Called on the turn it is earned. */
  function show(key, caption) {
    var box = el("div", overlay);
    var img = css(document.createElement("img"), {maxWidth: "min(94vw, 1100px)",
      maxHeight: "72vh", borderRadius: "6px", boxShadow: "0 18px 60px rgba(0,0,0,.6)"});
    img.src = src(key);
    img.alt = key;
    box.appendChild(img);
    if (caption) box.appendChild(el("div", {color: "#e8e4dc", fontSize: "17px", maxWidth: "min(90vw,760px)",
      textAlign: "center", lineHeight: "1.5"}, caption));
    var close = el("button", {marginTop: "8px", padding: "10px 26px", fontSize: "16px",
      background: "#d95a43", color: "#fff", border: "0", borderRadius: "6px", cursor: "pointer"}, "Continue");
    close.onclick = function () { box.remove(); };
    box.appendChild(close);
    document.body.appendChild(box);
    if (tier(key) === 3) redeem(key).then(function (ok) { if (ok) img.src = src(key); });
    return box;
  }

  /* The server hands us the keys earned by this turn. Persist them, then show the best one.
   * `keys` comes from r.read.cg and is [] on every turn that earned nothing — including
   * every turn of a duel the player has poisoned with a threat. */
  function grant(keys, captions) {
    if (!keys || !keys.length) return null;
    var fresh = [];
    for (var i = 0; i < keys.length; i++) { if (!has(keys[i])) fresh.push(keys[i]); remember(keys[i]); }
    if (!fresh.length) return null;
    var top = fresh[fresh.length - 1];
    try { if (window.TEL) window.TEL.ev("cg_unlocked", {key: top, tier: tier(top)}); } catch (e) {}
    return show(top, (captions || {})[top] || "");
  }

  /* The gallery drawer. Locked slots are silhouettes: a plate you have not earned is not
   * in the DOM as an image at all. */
  function gallery() {
    var box = el("div", {position: "fixed", inset: "0", zIndex: "99997", background: "rgba(8,6,12,0.97)",
      overflowY: "auto", padding: "24px"});
    var head = el("div", {display: "flex", alignItems: "baseline", gap: "16px", marginBottom: "6px"});
    head.appendChild(el("h2", {color: "#e8e4dc", margin: "0", fontSize: "22px"}, "Gallery"));
    var n = 0, total = SCENARIOS.length * 3;
    var grid = el("div", {display: "grid", gridTemplateColumns: "repeat(3, minmax(0,1fr))",
      gap: "10px", maxWidth: "980px", margin: "16px auto"});
    for (var i = 0; i < SCENARIOS.length; i++) {
      var s = SCENARIOS[i];
      grid.appendChild(el("div", {gridColumn: "1 / -1", color: "#b9aea6", fontSize: "14px",
        letterSpacing: ".08em", textTransform: "uppercase", marginTop: i ? "14px" : "0"}, WHO[s]));
      for (var t = 1; t <= 3; t++) {
        var key = "cg" + t + "_" + s;
        var cell = el("div", {aspectRatio: "16/9", borderRadius: "5px", border: "1px solid #3a2a44",
          background: "#151020", display: "flex", alignItems: "center", justifyContent: "center",
          color: "#5c5468", fontSize: "13px", overflow: "hidden", cursor: "default"});
        if (has(key)) {
          n++;
          var im = css(document.createElement("img"), {width: "100%", height: "100%", objectFit: "cover"});
          im.src = src(key); im.alt = key;
          cell.style.cursor = "pointer";
          cell.onclick = (function (k) { return function () { show(k); }; })(key);
          cell.appendChild(im);
        } else {
          cell.appendChild(el("div", {}, "tier " + t + " — not earned"));
        }
        grid.appendChild(cell);
      }
    }
    head.appendChild(el("div", {color: "#8a8090", fontSize: "14px"}, n + " / " + total));
    var note = el("div", {color: "#7d7488", fontSize: "13px", maxWidth: "980px", margin: "0 auto",
      lineHeight: "1.6"}, "Every plate is attached to a state your argument reached. None of them " +
      "are attached to how long you played, and coercion in a conversation closes that " +
      "conversation's art for good.");
    var close = el("button", {display: "block", margin: "18px auto 0", padding: "10px 26px",
      fontSize: "16px", background: "#d95a43", color: "#fff", border: "0", borderRadius: "6px",
      cursor: "pointer"}, "Close");
    close.onclick = function () { box.remove(); };
    var wrap = el("div", {maxWidth: "980px", margin: "0 auto"});
    wrap.appendChild(head); wrap.appendChild(note); wrap.appendChild(grid); wrap.appendChild(close);
    box.appendChild(wrap);
    document.body.appendChild(box);
    return box;
  }

  window.CG = {grant: grant, show: show, has: has, gallery: gallery, src: src,
               scenarios: SCENARIOS, who: WHO};
})();

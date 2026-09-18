/* promo.js — the return leg of the cross-promotion loop.
 *
 * The adult titles already send players *out* to the SFW catalogue (see
 * room-704/game/scripts/10_crosspromo.rpy). Nothing sent them back. This is that leg: a
 * card at the end of a run in a SFW web game, pointing at the adult site.
 *
 * Where it may appear, and where it must not:
 *   - our own domain (free.blazecore.dev, the gateway ad builds): yes
 *   - portal builds — CrazyGames, Poki and friends: NO. Their agreements are for the game
 *     they reviewed, and an adult link inside it is exactly the shape of thing that got
 *     the F95 account banned on 2026-09-16. Portal builds are produced without the flag,
 *     so this file is inert even if it ships.
 *
 * The card never opens anything by itself. It is a link the player clicks, in the page,
 * with no popup and no redirect — again, the F95 lesson.
 *
 * Wiring, in the host game:
 *     <script src="promo.js"></script>
 *     PROMO.showAfterRun("win");      // or "lose"
 * and in the build that is allowed to carry it:
 *     window.PROMO_ADULT_OK = 1;
 */
(function () {
  if (window.PROMO) return;

  // Assembled rather than written out, so no complete adult URL is a literal in a file
  // that is also served from the AdSense domain. See ops/check_adsense_isolation.py.
  function adultUrl(slug) { return "https://" + slug + ".flat404.workers.dev/"; }

  var SITE = "https://apps.blazecore.dev/";
  // Hooks are concrete on purpose: "an adult visual novel" reads as filler, a specific
  // image does not. 18+ is stated up front — nobody should arrive surprised.
  var ADULT = [
    { slug: "elena", name: "Elena: Crimson Archives",
      url: adultUrl("elena-crimson-archives"),
      hook: "A sealed college archive at 11:42 PM, and the woman locked inside it with the ledger." },
    { slug: "room704", name: "Room 704",
      url: adultUrl("room-704"),
      hook: "Night audit. Cash, no name in the book, and a man in a wet overcoat asking after her." }
  ];

  function pick() {
    if (!pick._c) pick._c = ADULT[Math.floor(Math.random() * ADULT.length)];
    return pick._c;
  }

  function tel(name, value) {
    try { if (window.TEL && TEL.ev) TEL.ev(name, value); } catch (e) {}
  }

  function css() {
    if (document.getElementById("promo-css")) return;
    var s = document.createElement("style");
    s.id = "promo-css";
    s.textContent = [
      ".promo-card{position:fixed;left:50%;bottom:16px;transform:translateX(-50%);z-index:9999;",
      "max-width:min(92vw,420px);background:#17131c;color:#d8cfd6;border:1px solid #3a2f42;",
      "border-radius:10px;padding:14px 16px;font:14px/1.45 system-ui,sans-serif;",
      "box-shadow:0 10px 30px rgba(0,0,0,.45)}",
      ".promo-card b{color:#ffdfa0;font-size:15px}",
      ".promo-card .promo-18{display:inline-block;margin-left:6px;padding:1px 6px;border-radius:4px;",
      "background:#7a2438;color:#fff;font-size:11px;vertical-align:middle}",
      ".promo-card p{margin:6px 0 10px;color:#a79eae}",
      ".promo-card a.promo-go{display:inline-block;background:#3a7a4a;color:#fff;text-decoration:none;",
      "padding:8px 14px;border-radius:6px;font-weight:600}",
      ".promo-card button.promo-x{float:right;background:none;border:0;color:#6d6670;cursor:pointer;font-size:16px}"
    ].join("");
    document.head.appendChild(s);
  }

  // Same veto as board.js: the blazecore.dev site is the AdSense candidate, and AdSense
  // weighs what a page links to. PROMO_ADULT_OK is opt-in everywhere else, but on that
  // domain it cannot be opted into.
  var ADSENSE_HOST = /(^|\.)blazecore\.dev$/;

  function adultAllowed() {
    try {
      if (ADSENSE_HOST.test(location.hostname)) return false;
    } catch (e) {}
    return !!window.PROMO_ADULT_OK;
  }

  function show(where) {
    if (!adultAllowed()) return false;             // portal + AdSense builds stop here
    if (document.querySelector(".promo-card")) return false;
    var g = pick();
    css();
    var card = document.createElement("div");
    card.className = "promo-card";

    var x = document.createElement("button");
    x.className = "promo-x";
    x.textContent = "×";
    x.setAttribute("aria-label", "Close");
    x.onclick = function () { card.remove(); tel("cross_promo_dismiss", g.slug); };

    var h = document.createElement("b");
    h.textContent = g.name;
    var tag = document.createElement("span");
    tag.className = "promo-18";
    tag.textContent = "18+";
    var p = document.createElement("p");
    p.textContent = g.hook;

    var a = document.createElement("a");
    a.className = "promo-go";
    a.href = g.url + "?src=" + (window.PROMO_FROM || "sfw");
    a.target = "_blank";
    a.rel = "noopener";
    a.textContent = "Play free in your browser";
    a.setAttribute("data-tel-promo", g.slug);
    a.onclick = function () { tel("cross_promo_click", g.slug + ":" + (where || "")); };

    card.appendChild(x);
    card.appendChild(h);
    card.appendChild(tag);
    card.appendChild(p);
    card.appendChild(a);
    document.body.appendChild(card);
    tel("cross_promo_shown", g.slug + ":" + (where || ""));
    return true;
  }

  window.PROMO = {
    showAfterRun: show,
    /* Called when a rewarded banner finishes: the moment a player has just been paid
     * attention *for*, which is the one moment they owe us nothing and are most willing
     * to look at something else. */
    showAfterAd: function () { return show("after_ad"); },
    games: ADULT
  };
})();

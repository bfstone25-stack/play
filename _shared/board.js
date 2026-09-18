/* board.js — the two-sided catalogue board, and the character who offers it.
 *
 * Blaze's read, and I think it is right: arousal fatigues. A player forty minutes into an
 * adult title is not necessarily done playing, they are done with *that*. Offering a
 * casual game at that moment is not a distraction from the funnel, it is the funnel —
 * they come back to the adult titles later, from our own catalogue, for free.
 *
 * So there are two boards and the player picks:
 *   - "Take a break?"  -> the casual board  (offered inside an adult title, between chapters)
 *   - "Want more?"     -> the adult board   (offered at the end of a casual game, or at the
 *                                            end of an adult one for the next title)
 * The answer is always the player's. Nothing opens by itself; every tile is a link they
 * click, in the page. No popups, ever — that is what cost us the F95 account.
 *
 * Tiles move, because a still grid reads as a list of links. Short silent mp4 loops over
 * a poster, built by ops/build_board_tiles.py.
 *
 * Gating: window.BOARD_ADULT_OK decides whether the *adult* board may be drawn at all, and
 * board.js sets it from the hostname unless the host page already did. The casual board is
 * safe everywhere. See promo.js for the same reasoning.
 *
 *   <script src="board.js"></script>
 *   BOARD.offerBreak();          // adult title, between chapters
 *   BOARD.offerMore();           // end of a run
 */
(function () {
  if (window.BOARD) return;

  // Media and catalogue live on free.blazecore.dev, which every one of our own pages can
  // reach. A host page may override the base (the local harness serves its own copy).
  var MEDIA_BASE = (typeof window.BOARD_BASE === "string") ? window.BOARD_BASE : "https://free.blazecore.dev/";
  var CATALOG_URL = MEDIA_BASE + "catalog.json";

  // Where the adult board may be drawn. This is deliberately NOT "our own hosts": the
  // blazecore.dev site is the one we intend to put Google AdSense on, and AdSense judges
  // a site by what it links to as well as what it shows. One adult tile in a board on
  // that domain is the shape of thing that gets an AdSense account terminated, and that
  // termination is not appealable in practice. So the adult board lives on the game hosts
  // (*.workers.dev) and on local QA, and nowhere else.
  var ADULT_HOST = /(^|\.)workers\.dev$|^127\.0\.0\.1$|^localhost$/;

  // Hosts that must never render an adult link, whatever the page asks for. This is a veto,
  // not a default — a host page setting BOARD_ADULT_OK = 1 cannot lift it. The rule is
  // enforced here rather than remembered at each call site, because the failure is silent
  // and expensive.
  var ADSENSE_HOST = /(^|\.)blazecore\.dev$/;

  if (ADSENSE_HOST.test(location.hostname)) {
    window.BOARD_ADULT_OK = 0;
  } else if (typeof window.BOARD_ADULT_OK === "undefined") {
    window.BOARD_ADULT_OK = ADULT_HOST.test(location.hostname) ? 1 : 0;
  }

  // Baked-in fallback so a board still opens if the fetch fails — an empty grid after the
  // player said yes is worse than not asking.
  var FALLBACK = {
    casual: [
      { slug: "fold", name: "Fold", hook: "Fold space until the tiles become one.", url: "https://free.blazecore.dev/fold/" },
      { slug: "ghost-channel", name: "Ghost Channel", hook: "Five voices on a dead station. One is lying.", url: "https://free.blazecore.dev/ghost-channel/" },
      { slug: "office-landlord", name: "Office Landlord", hook: "Place staff, build chains, pay the landlord.", url: "https://free.blazecore.dev/office-landlord/" }
    ],
    // Assembled from the host rather than written out, so that no complete adult URL
    // appears as a literal in a file that also gets served from the AdSense domain. The
    // fallback only ever runs where the adult board is allowed in the first place.
    adult: [
      { slug: "elena", name: "Elena: Crimson Archives", hook: "A sealed archive at 11:42 PM.", url: adultUrl("elena-crimson-archives") },
      { slug: "room704", name: "Room 704", hook: "Night audit. Cash, no name in the book.", url: adultUrl("room-704") }
    ]
  };

  var catalog = null;
  var adultCatalog = null;

  function tel(name, value) {
    try { if (window.TEL && TEL.ev) TEL.ev(name, value); } catch (e) {}
  }

  /* The adult catalogue is fetched from the game host, not from blazecore.dev, because
   * the file listing adult titles must not exist on the AdSense candidate domain. A host
   * page may override the base. */
  function adultBase() {
    return (typeof window.BOARD_ADULT_BASE === "string")
      ? window.BOARD_ADULT_BASE
      : adultUrl("free");
  }

  function adultUrl(slug) {
    return "https://" + slug + ".flat404.workers.dev/";
  }

  /* `want` is "casual" or "adult". The casual catalogue comes from the SFW host and is
   * safe anywhere; the adult one is only ever fetched where the adult board is allowed,
   * so an AdSense-domain page never requests it and never receives those URLs. */
  function load(want) {
    if (want === "adult") {
      if (!window.BOARD_ADULT_OK) return Promise.resolve({ casual: [], adult: [] });
      if (adultCatalog) return Promise.resolve(adultCatalog);
      return fetch(adultBase() + "catalog-adult.json", { mode: "cors" })
        .then(function (r) { return r.json(); })
        .then(function (j) { adultCatalog = j; return j; })
        .catch(function () { adultCatalog = FALLBACK; return adultCatalog; });
    }
    if (catalog) return Promise.resolve(catalog);
    return fetch(CATALOG_URL, { mode: "cors" })
      .then(function (r) { return r.json(); })
      .then(function (j) { catalog = j; return j; })
      .catch(function () { catalog = { casual: FALLBACK.casual, adult: [] }; return catalog; });
  }

  function css() {
    if (document.getElementById("board-css")) return;
    var s = document.createElement("style");
    s.id = "board-css";
    s.textContent = [
      ".bd-wrap{position:fixed;inset:0;z-index:100000;background:rgba(6,4,10,.86);",
      "display:flex;align-items:center;justify-content:center;padding:20px;",
      "font:15px/1.5 system-ui,-apple-system,sans-serif;color:#e6dfe8}",
      ".bd-box{background:#17131c;border:1px solid #3a2f42;border-radius:14px;max-width:960px;",
      "width:100%;max-height:88vh;overflow:auto;padding:22px 24px;box-shadow:0 20px 60px rgba(0,0,0,.6)}",
      ".bd-head{display:flex;gap:14px;align-items:flex-start;margin-bottom:6px}",
      ".bd-face{width:56px;height:56px;border-radius:50%;flex:0 0 56px;",
      "background:radial-gradient(circle at 35% 30%,#ffd9c0,#e8a887 60%,#c98b6e);position:relative}",
      ".bd-face:before,.bd-face:after{content:'';position:absolute;top:22px;width:7px;height:9px;",
      "border-radius:50%;background:#2b1d22}",
      ".bd-face:before{left:15px}.bd-face:after{right:15px}",
      ".bd-smile{position:absolute;left:19px;top:34px;width:18px;height:9px;border-bottom:2.5px solid #2b1d22;border-radius:0 0 18px 18px}",
      ".bd-say{flex:1}",
      ".bd-say b{display:block;color:#ffdfa0;font-size:18px;margin-bottom:2px}",
      ".bd-say p{margin:0;color:#a79eae}",
      ".bd-btns{display:flex;gap:10px;margin:16px 0 4px;flex-wrap:wrap}",
      ".bd-btn{border:0;border-radius:8px;padding:10px 18px;font:600 15px system-ui;cursor:pointer}",
      ".bd-yes{background:#3a7a4a;color:#fff}.bd-no{background:#2a2233;color:#bdb3c2}",
      ".bd-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:14px;margin-top:16px}",
      ".bd-tile{display:block;text-decoration:none;color:inherit;background:#100d15;border:1px solid #302639;",
      "border-radius:10px;overflow:hidden;transition:transform .12s,border-color .12s}",
      ".bd-tile:hover{transform:translateY(-2px);border-color:#d99b66}",
      ".bd-media{position:relative;aspect-ratio:1/1;background:#0b0810}",
      ".bd-media img,.bd-media video{width:100%;height:100%;object-fit:cover;display:block}",
      ".bd-media video{position:absolute;inset:0;opacity:0;transition:opacity .25s}",
      ".bd-tile:hover .bd-media video,.bd-media video.on{opacity:1}",
      ".bd-t{padding:9px 11px 12px}.bd-t b{display:block;font-size:14px;color:#ffdfa0}",
      ".bd-t span{display:block;font-size:12px;color:#948c9c;margin-top:3px}",
      ".bd-x{float:right;background:none;border:0;color:#6d6670;font-size:20px;cursor:pointer;line-height:1}",
      "@media (max-width:520px){.bd-grid{grid-template-columns:repeat(auto-fill,minmax(140px,1fr))}}"
    ].join("");
    document.head.appendChild(s);
  }

  function close(wrap, why, tag) {
    if (!wrap || !wrap.parentNode) return;
    wrap.remove();
    tel("board_close", (tag || "") + ":" + why);
  }

  function tile(g) {
    var a = document.createElement("a");
    a.className = "bd-tile";
    a.href = g.url + (g.url.indexOf("?") < 0 ? "?" : "&") + "src=" + (window.BOARD_FROM || "board");
    a.target = "_blank";
    a.rel = "noopener";
    a.setAttribute("data-tel-promo", g.slug);

    var m = document.createElement("div");
    m.className = "bd-media";
    if (g.poster) {
      var img = document.createElement("img");
      img.loading = "lazy";
      img.alt = "";
      img.src = MEDIA_BASE + g.poster;
      m.appendChild(img);
    }
    if (g.clip) {
      // Autoplay only works muted, and only muted is acceptable anyway: eight tiles
      // talking at once is how a player finds the close button.
      var v = document.createElement("video");
      v.muted = true; v.loop = true; v.playsInline = true; v.preload = "none";
      v.src = MEDIA_BASE + g.clip;
      m.appendChild(v);
      a.addEventListener("mouseenter", function () { try { v.play(); } catch (e) {} });
      a.addEventListener("mouseleave", function () { try { v.pause(); } catch (e) {} });
      // Touch has no hover: play the clips that are actually on screen.
      if ("IntersectionObserver" in window && matchMedia("(hover:none)").matches) {
        new IntersectionObserver(function (es) {
          es.forEach(function (e) {
            if (e.isIntersecting) { v.classList.add("on"); try { v.play(); } catch (x) {} }
            else { v.classList.remove("on"); v.pause(); }
          });
        }, { threshold: 0.6 }).observe(a);
      }
    }

    var t = document.createElement("div");
    t.className = "bd-t";
    var b = document.createElement("b"); b.textContent = g.name;
    var s = document.createElement("span"); s.textContent = g.hook;
    t.appendChild(b); t.appendChild(s);

    a.appendChild(m); a.appendChild(t);
    a.addEventListener("click", function () { tel("cross_promo_click", g.slug); });
    return a;
  }

  function panel(opts) {
    css();
    var wrap = document.createElement("div");
    wrap.className = "bd-wrap";
    var box = document.createElement("div");
    box.className = "bd-box";

    var x = document.createElement("button");
    x.className = "bd-x"; x.textContent = "×"; x.setAttribute("aria-label", "Close");
    x.onclick = function () { close(wrap, "x", opts.tag); };
    box.appendChild(x);

    var head = document.createElement("div");
    head.className = "bd-head";
    var face = document.createElement("div");
    face.className = "bd-face";
    var smile = document.createElement("div");
    smile.className = "bd-smile";
    face.appendChild(smile);
    var say = document.createElement("div");
    say.className = "bd-say";
    var title = document.createElement("b"); title.textContent = opts.title;
    var line = document.createElement("p"); line.textContent = opts.line;
    say.appendChild(title); say.appendChild(line);
    head.appendChild(face); head.appendChild(say);
    box.appendChild(head);

    wrap.appendChild(box);
    document.body.appendChild(wrap);
    wrap.addEventListener("click", function (e) { if (e.target === wrap) close(wrap, "backdrop", opts.tag); });
    return { wrap: wrap, box: box };
  }

  function grid(box, games, tag) {
    var g = document.createElement("div");
    g.className = "bd-grid";
    games.forEach(function (x) { g.appendChild(tile(x)); });
    box.appendChild(g);
    tel("board_shown", tag + ":" + games.length);
  }

  /* Offered between chapters of an adult title. The player is asked, not moved. */
  function offerBreak() {
    return load("casual").then(function (cat) {
      var p = panel({
        tag: "break",
        title: "Need a breather?",
        line: "No rush — the chapter will still be here. We make a few small games you can mess about with for ten minutes."
      });
      var btns = document.createElement("div");
      btns.className = "bd-btns";
      var yes = document.createElement("button");
      yes.className = "bd-btn bd-yes";
      yes.textContent = "Go on then, show me";
      var no = document.createElement("button");
      no.className = "bd-btn bd-no";
      no.textContent = "No, keep reading";
      btns.appendChild(yes); btns.appendChild(no);
      p.box.appendChild(btns);

      yes.onclick = function () {
        tel("board_break", "yes");
        btns.remove();
        grid(p.box, cat.casual || FALLBACK.casual, "casual");
      };
      no.onclick = function () { tel("board_break", "no"); close(p.wrap, "no", "break"); };
      tel("board_offer", "break");
      return true;
    });
  }

  /* Offered at the end of a run. On a casual game this is the adult board; inside an
   * adult title it is the rest of the adult catalogue. */
  function offerMore(kind) {
    var want = kind || "adult";
    if (want === "adult" && !window.BOARD_ADULT_OK) return Promise.resolve(false);
    return load(want).then(function (cat) {
      var adult = want === "adult";
      var p = panel({
        tag: want,
        title: adult ? "Still got energy?" : "Something lighter?",
        line: adult
          ? "We write adult visual novels too — full stories, free in your browser, 18+."
          : "A few small games, free in your browser. No account, no install."
      });
      var games = (adult ? cat.adult : cat.casual) || FALLBACK[adult ? "adult" : "casual"];
      if (adult && !window.BOARD_ADULT_OK) games = [];   // belt and braces: never render
      grid(p.box, games, want);
      return true;
    });
  }

  window.BOARD = {
    offerBreak: offerBreak,
    offerMore: offerMore,
    load: load,
    adultAllowed: function () { return !!window.BOARD_ADULT_OK; }
  };
})();

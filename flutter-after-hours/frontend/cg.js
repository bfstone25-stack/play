/* cg.js — the event-CG layer for Flutter: After Hours.
 *
 * Nine plates, three per route. Every one of them is earned by game state and
 * none of them by playtime:
 *
 *   chapter clear      reward.cg          from app.py /choose  (hook 1 of 3)
 *   affection past 60  say().cg           from _static_say()   (hook 2 of 3)
 *   ending screen      ending.cg          from app.py /choose  (hook 3 of 3)
 *
 * The unlock uses the Gate that is already live in this client for chapters
 * (continueChapter(), index.html) — no second paywall, no second telemetry
 * scheme: gate.js already emits paywall_seen / paywall_decision / ad_watched,
 * so the paid and ad tracks stay comparable.
 *
 * SHIPPING RULE (copied from play/room-704/game/scripts/09_dist.rpy):
 * a free build contains only <slot>_locked.webp. Clearing the gate fetches the
 * uncensored bytes; forging a localStorage flag reveals nothing, because on a
 * free build the uncensored file is not on the device.
 */
(function () {
  var LOCKED = "cg/";            // covered plates + thumbs — in every build
  var FULL = "cg/full/";         // uncensored — paid package only
  var KEY = "fah_cg_unlocked";
  var APP = window.GATED_CG_APP || "flutter-after-hours";
  var fetched = {};              // slot -> objectURL of bytes we actually retrieved
  var probed = {};               // slot -> does FULL+slot exist in THIS package?

  function unlocked() {
    try { return JSON.parse(localStorage.getItem(KEY) || "{}") || {}; } catch (e) { return {}; }
  }
  function remember(slot) {
    var u = unlocked(); u[slot] = Date.now();
    try { localStorage.setItem(KEY, JSON.stringify(u)); } catch (e) {}
  }
  function isPaid() { return window.Gate && window.Gate.dist() === "paid"; }
  function has(slot) { return isPaid() || !!unlocked()[slot]; }

  function lockedSrc(slot) { return LOCKED + slot + "_locked.webp"; }
  function thumbSrc(slot) { return LOCKED + slot + "_thumb.webp"; }

  /* Does this package actually carry the uncensored file?
   *
   * `dist() === "paid"` is a FLAG, and the bytes are a FACT, and they came
   * apart: tools/build_free.sh strips cg/full/ from the package, so a free
   * package opened with the paid flag set (a local run, a mislabelled build)
   * pointed every plate at a file that was not there and drew three broken
   * images — found by reading naturalWidth after a scripted playthrough, which
   * is the only way this shows up: the img tag looks perfectly correct in the
   * DOM. So ask the file, do not trust the flag. */
  function probe(slot) {
    if (slot in probed) return Promise.resolve(probed[slot]);
    return new Promise(function (resolve) {
      var im = new Image();
      im.onload = function () { probed[slot] = true; resolve(true); };
      im.onerror = function () { probed[slot] = false; resolve(false); };
      im.src = FULL + slot + ".webp";
    });
  }

  /* The gated fetch, as play/silvertongue-x/frontend/cg.js does it and as
   * gateway/app.py serves it:
   *
   *   POST /unlock/start  {app, key}      -> {ok, ticket, wait}
   *   GET  /unlock/fetch  ?ticket&app&key -> the webp bytes
   *
   * Three properties of that endpoint this code has to respect, all verified
   * against the live gateway rather than read off the source:
   *   - the ticket is refused with 425 for `wait` seconds after it is issued
   *     (_MIN_WAIT = 18), so a client that fetches immediately gets nothing;
   *   - it is single-use, so the bytes must be cached here (`fetched`) and a
   *     re-open must never call /unlock/fetch again;
   *   - it 403s an unknown/none ticket, so a failure has to degrade to the
   *     covered plate rather than to a broken image.
   *
   * UNLOCK_API is the gateway ROOT. /unlock/* is declared above the catch-all
   * /{name}/{path} proxy in gateway/app.py, so putting the app slug in the
   * base URL sends the call into the proxy and gets "unknown app" instead. */
  function unlockBase() { return window.UNLOCK_API || ""; }

  /* Ask for the ticket EARLY — at the moment the gate opens, not after it
   * closes. The gateway's 18-second minimum exists to stop a client that never
   * watched anything; a player who is watching a 30-second clip has already
   * served it. Starting the ticket when the clip starts means the wait runs
   * underneath the thing the player is already doing and the plate is ready the
   * instant they click Continue. Starting it afterwards would make every reveal
   * sit on a covered plate for a further 19 seconds, which reads as "broken",
   * not as "loading". */
  var pending = {};      // slot -> Promise<{ticket, ready_at} | null>
  function startTicket(slot) {
    if (fetched[slot]) return Promise.resolve(null);
    if (pending[slot]) return pending[slot];
    var base = unlockBase();
    if (!base) return Promise.resolve(null);
    pending[slot] = fetch(base + "/unlock/start", {
      method: "POST", headers: {"Content-Type": "application/json"},
      body: JSON.stringify({app: APP, key: slot})
    }).then(function (r) { return r.json(); }).then(function (d) {
      if (!d || !d.ok || !d.ticket) return null;
      var wait = (typeof d.wait === "number" ? d.wait : 18);
      return {ticket: d.ticket, ready_at: Date.now() + wait * 1000 + 600};
    }).catch(function () { return null; });
    return pending[slot];
  }

  /* Redeem it. Single-use: the bytes are cached in `fetched` and the ticket is
   * dropped, so re-opening a plate never calls /unlock/fetch a second time —
   * which the gateway would refuse with 403 anyway. */
  function redeem(slot) {
    if (fetched[slot]) return Promise.resolve(true);
    var base = unlockBase();
    if (!base) return Promise.resolve(false);
    return startTicket(slot).then(function (t) {
      if (!t) return false;
      var url = base + "/unlock/fetch?ticket=" + encodeURIComponent(t.ticket) +
                "&app=" + encodeURIComponent(APP) + "&key=" + encodeURIComponent(slot);
      return new Promise(function (res) { setTimeout(res, Math.max(0, t.ready_at - Date.now())); })
        .then(function () { return fetch(url); })
        .then(function (r) {
          if (r.status === 425) {            // clock skew: one retry, then give up
            return new Promise(function (res) { setTimeout(res, 4000); })
              .then(function () { return fetch(url); });
          }
          return r;
        })
        .then(function (r) { return r && r.ok ? r.blob() : null; })
        .then(function (b) {
          delete pending[slot];              // spent either way
          if (!b || b.size < 1024) return false;
          fetched[slot] = URL.createObjectURL(b);
          if (window.TEL) { try { TEL.ev("unlock_delivered", {slot: slot, bytes: b.size}); } catch (e) {} }
          return true;
        });
    }).catch(function () { delete pending[slot]; return false; });
  }

  /* Where the bytes for a revealed plate come from, in order of cheapness.
   * Never returns a path this package might not have. */
  async function cgSource(slot) {
    if (fetched[slot]) return fetched[slot];
    if (isPaid() && await probe(slot)) return FULL + slot + ".webp";
    if (await redeem(slot)) return fetched[slot];
    return lockedSrc(slot);
  }

  /* One tap on a covered plate. Same Gate call shape as continueChapter(). */
  async function reveal(slot, imgEl) {
    if (!has(slot)) {
      if (!window.Gate) return false;
      // Fire the ticket request first so its 18-second minimum runs underneath
      // the sponsor clip instead of after it. Deliberately not awaited.
      if (!isPaid()) { try { startTicket(slot); } catch (e) {} }
      var r = await window.Gate.require("cg:" + slot, {title: "This memory", kind: "cg"});
      if (r !== "unlocked") return false;
      remember(slot);
    }
    var src = await cgSource(slot);
    if (imgEl) { imgEl.src = src; imgEl.dataset.revealed = "1"; }
    if (window.TEL) { try { TEL.ev("cg_revealed", {slot: slot}); } catch (e) {} }
    return true;
  }

  /* The markup a chapter-clear card / ending card embeds.
   *
   * Always renders the covered plate, which is the one file every build is
   * guaranteed to carry, and upgrades it afterwards if this package really does
   * have the uncensored bytes. The previous version picked the path from
   * dist()==="paid" alone and drew a broken image on every free package opened
   * with that flag — three of them per playthrough, silently, because a broken
   * <img> and a correct one look identical in the DOM. */
  function plateHtml(slot, caption) {
    if (!slot) return "";
    var id = "cgp" + Math.random().toString(36).slice(2, 9);
    if (has(slot)) {
      setTimeout(function () {
        cgSource(slot).then(function (src) {
          var im = document.getElementById(id);
          if (im && src !== lockedSrc(slot)) { im.src = src; im.dataset.revealed = "1"; }
        });
      }, 0);
    }
    return '<div class="cgPlate" data-slot="' + slot + '">' +
      '<img class="cgImg" id="' + id + '" alt="" src="' + lockedSrc(slot) +
      '" onerror="this.style.opacity=.25" onclick="FAH_CG.tap(this)">' +
      '<div class="cgCap">' + (caption || "") + '</div></div>';
  }

  /* Called by the onclick above; resolves the enclosing plate's slot. */
  function tap(img) {
    var box = img.closest(".cgPlate");
    if (!box) return;
    var slot = box.dataset.slot;
    if (img.dataset.revealed === "1") { lightbox(slot); return; }
    reveal(slot, img).then(function (ok) { if (ok) lightbox(slot); });
  }

  function lightbox(slot) {
    cgSource(slot).then(function (src) {
      var ov = document.createElement("div");
      ov.className = "cgLightbox";
      ov.innerHTML = '<img src="' + src + '" alt=""><button class="cgClose">CLOSE</button>';
      ov.onclick = function () { ov.remove(); };
      document.body.appendChild(ov);
    });
  }

  /* The gallery grid. Locked slots are shown, so the player can see the shape
   * of what is missing — but nothing in here unlocks anything. */
  async function galleryHtml(routeId) {
    var slots = [];
    try {
      var r = await fetch(window.FLUTTER_API + "/cg/" + routeId);
      slots = (await r.json()).slots || [];
    } catch (e) {}
    if (!slots.length) return "";
    return '<div class="cgGrid">' + slots.map(function (s) {
      var got = has(s.slot);
      return '<div class="cgCell' + (got ? " got" : "") + '" data-slot="' + s.slot + '"' +
        (got ? ' onclick="FAH_CG.lightbox(\'' + s.slot + '\')"' : "") + '>' +
        '<img src="' + thumbSrc(s.slot) + '" alt="">' +
        '<span>' + (got ? s.slot : "◆ " + (s.how === "affection" ? "affection 60"
          : s.how === "ending" ? "an ending" : s.chapter + " clear")) + '</span></div>';
    }).join("") + "</div>";
  }

  window.FAH_CG = {has: has, reveal: reveal, tap: tap, lightbox: lightbox,
                   plateHtml: plateHtml, galleryHtml: galleryHtml,
                   lockedSrc: lockedSrc, thumbSrc: thumbSrc};
})();

/* ── 18+ interstitial and the AI disclosure ────────────────────────────────
 * Shown once per device before anything else. Adult forks say both things on
 * the way in (ops/adult_forks/README.md): who this is for, and how the art was
 * made. Declining leaves rather than degrading into a SFW mode that does not
 * exist.
 */
(function () {
  var KEY = "fah_adult_ack";
  window.FAH_ADULT_GATE = function () {
    try { if (localStorage.getItem(KEY)) return; } catch (e) {}
    var ov = document.createElement("div");
    ov.id = "adultOv";
    ov.innerHTML =
      '<div class="adultCard">' +
      '<div class="adultKicker">18+</div>' +
      '<h2>Flutter: After Hours</h2>' +
      '<p>An adult visual novel. Everyone depicted is an adult and is written as one. ' +
      'Consensual only — no minors, no violence, no non-consent.</p>' +
      // 2026-09-21: this said "the writing is human, every line". Blaze retracted that
      // claim everywhere it had been published (commit 8ae5eab) -- our own itch listings
      // carried ai-generated-text at the same time. The house line is now the one below,
      // which overclaims neither half.
      '<p class="adultAi">Made with AI in the loop and a person steering it: the art is ' +
      'generated and then culled, retouched and composited by hand, and the writing and ' +
      'scripting were worked out the same way.</p>' +
      '<button class="adultYes" type="button">I am 18 or older — enter</button>' +
      // Below the primary action, not above it: the decline used to be absolutely
      // positioned in the overlay's corner, and once the card gained a panel it landed
      // on top of the 18+ kicker.
      '<button class="adultNo" type="button">Leave</button></div>';
    document.body.appendChild(ov);
    ov.querySelector(".adultYes").onclick = function () {
      try { localStorage.setItem(KEY, "1"); } catch (e) {}
      if (window.TEL) { try { TEL.ev("adult_ack", {}); } catch (e) {} }
      ov.remove();
    };
    // Declining used to run `location.href = "https://www.google.com"`, which is a
    // destructive, irreversible navigation fired by a single click -- and the button sat
    // directly beneath the primary one, so a stray tap ejected a paying player off the
    // product. It also destroyed every automated play-through: ops/play_driver.py's first
    // click is (640, 500), which landed exactly on this button, and the session was gone
    // before the game had been touched once. Decline now ends in the page, reversibly.
    ov.querySelector(".adultNo").onclick = function () {
      var card = ov.querySelector(".adultCard");
      if (!card) return;
      card.innerHTML =
        '<div class="adultKicker">18+</div>' +
        '<h2>Come back when you are 18.</h2>' +
        '<p>This title is for adults only. Nothing here has loaded.</p>' +
        '<button class="adultBack" type="button">Back</button>';
      card.querySelector(".adultBack").onclick = function () { window.FAH_ADULT_GATE_REOPEN(); };
    };
  };
  window.FAH_ADULT_GATE_REOPEN = function () {
    var old = document.getElementById("adultOv");
    if (old) old.remove();
    window.FAH_ADULT_GATE();
  };
})();

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
 * free build the uncensored file is not on the device. See cgSource() for the
 * one piece of that which is still a stub.
 */
(function () {
  var LOCKED = "cg/";            // covered plates + thumbs — in every build
  var FULL = "cg/full/";         // uncensored — paid package only
  var KEY = "fah_cg_unlocked";

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

  /* Where the uncensored bytes come from once the gate is cleared.
   *
   * paid build  — they are in the package, next to the covered plates.
   * web tracks  — NOT BUILT YET. The design (ops/adult_forks/flutter.md §4.6)
   *   is the Room 704 ticket flow: POST a single-use time-locked ticket to
   *   apps.blazecore.dev, write the bytes locally. That endpoint does not exist
   *   for this client yet, so the web tracks fall back to the covered plate and
   *   say so rather than 404-ing into a broken image. Wire GATED_CG_URL when
   *   the gateway endpoint lands; nothing else here has to change.
   */
  var GATED_CG_URL = window.GATED_CG_URL || "";
  async function cgSource(slot) {
    if (isPaid()) return FULL + slot + ".webp";
    if (!GATED_CG_URL) return lockedSrc(slot);
    try {
      var res = await fetch(GATED_CG_URL + "?slot=" + encodeURIComponent(slot), {method: "POST"});
      var j = await res.json();
      return j && j.url ? j.url : lockedSrc(slot);
    } catch (e) { return lockedSrc(slot); }
  }

  /* One tap on a covered plate. Same Gate call shape as continueChapter(). */
  async function reveal(slot, imgEl) {
    if (!has(slot)) {
      if (!window.Gate) return false;
      var r = await window.Gate.require("cg:" + slot, {title: "This memory", kind: "cg"});
      if (r !== "unlocked") return false;
      remember(slot);
    }
    var src = await cgSource(slot);
    if (imgEl) { imgEl.src = src; imgEl.dataset.revealed = "1"; }
    if (window.TEL) { try { TEL.ev("cg_revealed", {slot: slot}); } catch (e) {} }
    return true;
  }

  /* The markup a chapter-clear card / ending card embeds. */
  function plateHtml(slot, caption) {
    if (!slot) return "";
    var src = has(slot) ? (isPaid() ? FULL + slot + ".webp" : lockedSrc(slot)) : lockedSrc(slot);
    return '<div class="cgPlate" data-slot="' + slot + '">' +
      '<img class="cgImg" alt="" src="' + src + '" onclick="FAH_CG.tap(this)">' +
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
      '<p class="adultAi">Artwork is AI-assisted: directed, culled and retouched by hand. ' +
      'The writing is human, every line.</p>' +
      '<button class="adultYes">I am 18 or older — enter</button>' +
      '<button class="adultNo">Leave</button></div>';
    document.body.appendChild(ov);
    ov.querySelector(".adultYes").onclick = function () {
      try { localStorage.setItem(KEY, "1"); } catch (e) {}
      if (window.TEL) { try { TEL.ev("adult_ack", {}); } catch (e) {} }
      ov.remove();
    };
    ov.querySelector(".adultNo").onclick = function () {
      location.href = "https://www.google.com";
    };
  };
})();

/* aftersix_gate.js — the CG gate for After Six's two *web* tracks. A copy of
 * play/floor-13-x/web/floor13x_gate.js (the fixed shared/gate.js family): no rendered
 * creative => no unlock.
 *
 * Shipped alongside shared/gate.js on the itch web build and the ads-site build, and
 * NOWHERE ELSE. The downloadable builds have no page, load no script, and make no
 * third-party call of any kind: an Adsterra popunder cost the studio its F95 account
 * (memory f95-ban-direct-link-ads), and a downloaded build that phones anywhere is the
 * same mistake with a different filename.
 *
 * Why this exists instead of just calling Gate.require:
 *
 *   shared/gate.js's adGate() runs a countdown and resolves "unlocked" when it finishes —
 *   whether or not window.AD_HTML held a creative, and whether or not the iframe rendered
 *   anything. On a chapter gate that is the right call: never brick the story for someone
 *   running an adblocker. On a CG it is not, because the uncensored plate IS the paid
 *   differentiator, and handing it over for a blank box gives away the only thing being
 *   sold. Ren'Py already learned this — result 3, "sponsor unavailable", at
 *   play/room-704/game/scripts/09_dist.rpy:280-299. This is the same three-state for Godot.
 *
 * Contract with scripts/as_cg.gd:
 *   window.AfterSixGate.require(key, {title, kind}) -> Promise<"unlocked"|"unavailable"|"closed">
 */
(function () {
  if (window.AfterSixGate) return;

  var CREATIVE_GRACE_MS = 8000;   // matches AD_SCRIPT_GRACE in 09_dist.rpy

  function tel(name, value) {
    try { if (window.TEL) { window.TEL.ev(name, value || {}); if (window.TEL.flush) window.TEL.flush(); } } catch (e) {}
  }

  function track() {
    try { return (window.Gate && window.Gate.dist) ? window.Gate.dist() : "itch_web"; } catch (e) { return "itch_web"; }
  }

  /* Did a sponsor creative actually render?
   *
   * Three things all have to be true, because each one of them has been false in the wild:
   * the snippet has to exist at all (blocked script), the slot has to be in the document
   * (overlay torn down early), and the iframe has to have non-zero layout (served, then
   * collapsed to 0x0 by the filter list). Anything less is "unavailable", not "watched". */
  function creativeShown() {
    try {
      if (!window.AD_HTML) return false;
      var slot = document.querySelector('[data-tel-ad="gate"]');
      if (!slot) return false;
      var frame = slot.querySelector("iframe");
      if (!frame) return false;
      var box = frame.getBoundingClientRect();
      return box.width > 0 && box.height > 0;
    } catch (e) { return false; }
  }

  function requireCg(key, opts) {
    opts = opts || {};
    opts.kind = "cg";
    if (!window.Gate) return Promise.resolve("closed");
    if (window.Gate.has(key)) return Promise.resolve("unlocked");

    var isAds = track() === "ads_web";
    var t0 = Date.now();
    /* On the ad track, sample the slot while the clip runs. Checking only at the end
     * misses a creative that rendered and was then removed, which reads as a cheat
     * against the player rather than against us. */
    var sawCreative = false, sampler = null;
    if (isAds) {
      sampler = setInterval(function () { if (creativeShown()) sawCreative = true; }, 500);
      setTimeout(function () { if (creativeShown()) sawCreative = true; }, CREATIVE_GRACE_MS);
    }

    tel("cg_gate_open", {key: key, dist: track()});

    return window.Gate.require(key, opts).then(function (r) {
      if (sampler) clearInterval(sampler);
      var dur = Math.round((Date.now() - t0) / 1000);
      if (r !== "unlocked") {
        tel("cg_gate_declined", {key: key, dist: track(), s: dur});
        return "closed";
      }
      if (isAds && !sawCreative) {
        /* The countdown finished but nothing was served. The player keeps playing — the
         * story is never held hostage to an adblocker — and the plate stays censored.
         * Forgetting the localStorage unlock gate.js just wrote is the whole point: a
         * remembered unlock would make the next load hand over the art for free. */
        try {
          var u = JSON.parse(localStorage.getItem("gate_unlocks") || "{}") || {};
          delete u[key];
          localStorage.setItem("gate_unlocks", JSON.stringify(u));
        } catch (e) {}
        tel("cg_ad_unavailable_censored", {key: key, s: dur});
        return "unavailable";
      }
      tel("cg_gate_unlocked", {key: key, dist: track(), s: dur});
      return "unlocked";
    }, function () {
      if (sampler) clearInterval(sampler);
      return "closed";
    });
  }

  window.AfterSixGate = {require: requireCg, creativeShown: creativeShown};
})();

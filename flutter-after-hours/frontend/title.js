/* title.js — the motion and the sound of the title screen.
 *
 * ops/adult_forks/TITLE_SCREENS.md, item 3 and item 6. The layers and the light live in
 * CSS (index.html, the ".kv-layer / .kv-light / .kv-scrim / .brand-mark" block); this
 * file is the two things CSS cannot do on its own:
 *
 *   1. Parallax. The key visual takes a little of the pointer's position — a few pixels,
 *      slower than the cursor — plus a slow breath of its own, so the screen is never
 *      quite still even when nothing is touched. On a phone there is no pointer, so the
 *      breath carries it alone.
 *   2. Sound. A title sting when the screen first arrives, and a tick on hover and on
 *      press for the route cards and the buttons. Synthesised with WebAudio rather than
 *      shipped as files: TITLE_SCREENS.md allows placeholder synthesis until a house
 *      asset exists, and three more mp3s in the pack is three more things to download
 *      before anyone has chosen anything. The hooks are one function, so a recording
 *      drops in behind `sting()` / `tick()` without touching this file's callers.
 *
 * It never plays anything the player has muted: FLUTTER_AUDIO owns that switch and this
 * asks it every time rather than keeping its own copy. It also never starts an
 * AudioContext before a gesture, which is what browsers require anyway.
 */
(function () {
  "use strict";

  var select = null, kv = null, ctx = null, armed = false, stungFor = "";

  function reduced() {
    return window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  function muted() {
    try {
      var s = window.FLUTTER_AUDIO && window.FLUTTER_AUDIO.getState();
      // `music` is the player's own switch for everything that is not voice.
      return !s || s.music === false;
    } catch (e) { return true; }
  }

  function audio() {
    if (ctx) return ctx;
    var C = window.AudioContext || window.webkitAudioContext;
    if (!C) return null;
    try { ctx = new C(); } catch (e) { return null; }
    return ctx;
  }

  /* A soft two-note figure, gold rather than bright: a fifth, the upper voice arriving
   * late and both decaying together. Two sines and a lowpass is the whole instrument. */
  function sting() {
    if (muted() || !armed) return;
    var a = audio(); if (!a) return;
    var t = a.currentTime, out = a.createGain(), lp = a.createBiquadFilter();
    lp.type = "lowpass"; lp.frequency.value = 1750;
    out.gain.value = 0.0001;
    out.gain.exponentialRampToValueAtTime(0.085, t + 0.18);
    out.gain.exponentialRampToValueAtTime(0.0001, t + 3.4);
    lp.connect(out); out.connect(a.destination);
    [[329.63, 0], [493.88, 0.34], [659.25, 0.62]].forEach(function (pair) {
      var o = a.createOscillator(), g = a.createGain();
      o.type = "sine"; o.frequency.value = pair[0];
      g.gain.value = 0.0001;
      g.gain.setValueAtTime(0.0001, t + pair[1]);
      g.gain.exponentialRampToValueAtTime(0.5, t + pair[1] + 0.12);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 3.2);
      o.connect(g); g.connect(lp);
      o.start(t + pair[1]); o.stop(t + 3.5);
    });
  }

  function tick(kind) {
    if (muted() || !armed) return;
    var a = audio(); if (!a) return;
    var t = a.currentTime, o = a.createOscillator(), g = a.createGain();
    o.type = "sine";
    o.frequency.value = kind === "press" ? 392 : 880;
    g.gain.value = 0.0001;
    g.gain.exponentialRampToValueAtTime(kind === "press" ? 0.05 : 0.026, t + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t + (kind === "press" ? 0.24 : 0.12));
    o.connect(g); g.connect(a.destination);
    o.start(t); o.stop(t + 0.3);
  }

  /* The breath. One rAF while the title is on screen, off the moment it is not. */
  var raf = 0, t0 = 0, px = 0, py = 0, tx = 0, ty = 0;
  function frame(now) {
    if (!select || !select.classList.contains("reveal")) { raf = 0; return; }
    if (!t0) t0 = now;
    var t = (now - t0) / 1000;
    px += (tx - px) * 0.045;
    py += (ty - py) * 0.045;
    var bx = Math.sin(t * 0.17) * 10, by = Math.cos(t * 0.13) * 7;
    var s = 1.06 + 0.012 * Math.sin(t * 0.22);
    kv.style.setProperty("--kvx", (px + bx).toFixed(2) + "px");
    kv.style.setProperty("--kvy", (py + by).toFixed(2) + "px");
    kv.style.setProperty("--kvs", s.toFixed(4));
    raf = requestAnimationFrame(frame);
  }

  function start() {
    if (!kv || reduced()) return;
    kv.style.transition = "none";   // the rAF owns the transform now
    if (!raf) { t0 = 0; raf = requestAnimationFrame(frame); }
  }

  function onPointer(e) {
    if (!select || !select.classList.contains("reveal")) return;
    tx = ((e.clientX / window.innerWidth) - 0.5) * -26;
    ty = ((e.clientY / window.innerHeight) - 0.5) * -16;
  }

  function wire() {
    select = document.getElementById("select");
    kv = document.getElementById("kvLayer");
    if (!select) return;

    window.addEventListener("pointermove", onPointer, { passive: true });

    // The sting fires when the screen actually becomes visible, once per arrival, and
    // only after a gesture has unlocked audio — so it lands on the way in from the gate
    // rather than being swallowed by an autoplay block.
    var seen = new MutationObserver(function () {
      if (select.classList.contains("reveal")) {
        start();
        var id = String(Date.now() - (Date.now() % 4000));
        if (armed && stungFor !== id) { stungFor = id; sting(); }
      } else if (raf) { cancelAnimationFrame(raf); raf = 0; }
    });
    seen.observe(select, { attributes: true, attributeFilter: ["class"] });
    if (select.classList.contains("reveal")) start();

    // Hover and press, delegated: the route cards are built after this file runs.
    select.addEventListener("pointerover", function (e) {
      if (e.target.closest(".card,button")) tick("hover");
    }, { passive: true });
    select.addEventListener("pointerdown", function (e) {
      if (e.target.closest(".card,button")) tick("press");
    }, { passive: true });

    // Arm on the first gesture anywhere, which is also what unlocks the AudioContext.
    var arm = function () {
      armed = true;
      var a = audio();
      if (a && a.state === "suspended") a.resume();
      if (select.classList.contains("reveal") && !stungFor) { stungFor = "first"; sting(); }
    };
    window.addEventListener("pointerdown", arm, { once: true });
    window.addEventListener("keydown", arm, { once: true });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", wire);
  else wire();

  window.FLUTTER_TITLE = { sting: sting, tick: tick };
})();

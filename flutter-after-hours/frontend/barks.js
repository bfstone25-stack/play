/* barks.js — the narrator's voice lines, for the web build.
 *
 * STANDARD.md item 5: greet / stage / near-miss / win / big win / fail / idle / streak /
 * unlock, 18–30 lines, ONE voice per game. The lines and the render live upstream
 * (`ops/barks/lines.json` -> `ops/barks/render_barks.py` -> `frontend/voice/*.ogg` plus a
 * `voice/barks.json` manifest); this file is only the player.
 *
 * `ops/bark_wire.py` cannot be used here — it appends a GDScript layer to a Godot Sfx
 * autoload, and this game is the web PWA. So the three rules it encodes are re-stated in
 * JS rather than re-invented, because each one is the reason a bark set stops being
 * charming:
 *
 *   1. rotate, and never repeat the same line back to back;
 *   2. never overlap a bark with a bark — the second is DROPPED, not queued, because by
 *      the time the first has finished the moment it belonged to is gone;
 *   3. ride the player's own mute switch. FLUTTER_AUDIO owns `music`; this asks it every
 *      time rather than keeping a second copy that can drift out of step.
 *
 * It is also silent by construction when nothing is installed: the manifest is fetched
 * once, and a build with no `voice/` directory simply never gets past that fetch. That is
 * deliberate — the alternative is a manifest checked in ahead of the audio, which reports
 * "wired" while every play() 404s (ops memory, `verification-that-lies`).
 */
(function () {
  "use strict";

  var MANIFEST = "voice/barks.json";
  var map = null, ready = false, player = null, playing = false;
  var last = {};            // slot -> index last used, so a slot never repeats back to back
  var lastAt = 0;

  function muted() {
    try {
      var s = window.FLUTTER_AUDIO && window.FLUTTER_AUDIO.getState();
      return !s || s.music === false;
    } catch (e) { return true; }
  }

  function load() {
    if (ready) return Promise.resolve();
    ready = true;
    return fetch(MANIFEST, {cache: "force-cache"})
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { map = j || null; })
      .catch(function () { map = null; });
  }

  function pick(slot) {
    var list = map && map[slot];
    if (!list || !list.length) return null;
    if (list.length === 1) return list[0];
    var i, prev = last[slot];
    do { i = Math.floor(Math.random() * list.length); } while (i === prev);
    last[slot] = i;
    return list[i];
  }

  /* One <audio> for every bark, reused. A second element per line would let two barks
   * overlap, which rule 2 exists to prevent, and would also leak elements over a session. */
  function play(slot) {
    if (muted()) return;
    load().then(function () {
      if (!map || playing) return;                 // rule 2: dropped, never queued
      if (Date.now() - lastAt < 900) return;       // two triggers on one frame is one bark
      var file = pick(slot);
      if (!file) return;
      if (!player) {
        player = new Audio();
        player.preload = "none";
        player.addEventListener("ended", function () { playing = false; });
        player.addEventListener("error", function () { playing = false; });
      }
      player.src = "voice/" + file;
      player.volume = 0.9;
      playing = true; lastAt = Date.now();
      var p = player.play();
      if (p && p.catch) p.catch(function () { playing = false; });
      // The atmosphere track steps back under a spoken line and comes back after it.
      try { window.FLUTTER_AUDIO && window.FLUTTER_AUDIO.speak && duckFor(player); } catch (e) {}
    });
  }

  function duckFor(el) {
    var A = window.FLUTTER_AUDIO;
    if (!A || !A.setVolume || !A.getState) return;
    var was = A.getState().musicVolume;
    A.setVolume(was * 0.35);
    var back = function () { try { A.setVolume(was); } catch (e) {} };
    el.addEventListener("ended", back, {once: true});
    el.addEventListener("error", back, {once: true});
  }

  window.FAH_BARK = {play: play, loaded: function () { return !!map; }};
})();

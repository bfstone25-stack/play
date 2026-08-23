(function (root) {
  const AudioBus = { ctx: null, sfx: true, music: true, hum: null, _humGain: null, unlocked: false };

  function ctx() {
    if (!AudioBus.ctx) {
      const AC = root.AudioContext || root.webkitAudioContext;
      if (!AC) return null;
      AudioBus.ctx = new AC();
    }
    return AudioBus.ctx;
  }
  function unlock() {
    const c = ctx();
    if (!c) return;
    if (c.state === "suspended") c.resume();
    AudioBus.unlocked = true;
    if (AudioBus.music) startHum();
  }
  function tone(freq, dur, vol, type, delay, slide) {
    const c = ctx();
    if (!c || !AudioBus.sfx) return;
    const t0 = c.currentTime + (delay || 0);
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type || "square";
    o.frequency.setValueAtTime(freq, t0);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(40, slide), t0 + dur);
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(vol, t0 + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g); g.connect(c.destination);
    o.start(t0); o.stop(t0 + dur + 0.02);
  }
  function noise(dur, vol) {
    const c = ctx();
    if (!c || !AudioBus.sfx) return;
    const n = Math.floor(c.sampleRate * dur);
    const buf = c.createBuffer(1, n, c.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
    const src = c.createBufferSource();
    src.buffer = buf;
    const g = c.createGain();
    const f = c.createBiquadFilter();
    f.type = "highpass"; f.frequency.value = 700;
    const t0 = c.currentTime;
    g.gain.setValueAtTime(vol, t0);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(f); f.connect(g); g.connect(c.destination);
    src.start(t0); src.stop(t0 + dur + 0.02);
  }

  function punch() { tone(220, 0.07, 0.05, "square", 0, 90); noise(0.05, 0.04); }
  function kick() { tone(110, 0.1, 0.06, "sawtooth", 0, 55); noise(0.07, 0.05); }
  function special() { tone(392, 0.12, 0.05, "square"); tone(784, 0.16, 0.04, "triangle", 0.04, 400); }
  function superMove() { [196, 262, 330, 392, 523].forEach((f, i) => tone(f, 0.14, 0.045, "square", i * 0.05)); }
  function hit() { tone(160, 0.08, 0.05, "sawtooth", 0, 70); noise(0.06, 0.05); }
  function block() { tone(480, 0.05, 0.03, "triangle"); }
  function ko() { [196, 147, 110, 82].forEach((f, i) => tone(f, 0.28, 0.05, "sawtooth", i * 0.1, f * 0.7)); }
  function fight() { [392, 523, 659].forEach((f, i) => tone(f, 0.16, 0.045, "square", i * 0.08)); }
  function win() { [392, 523, 659, 784, 1046].forEach((f, i) => tone(f, 0.18, 0.04, "triangle", i * 0.08)); }

  function startHum() {
    const c = ctx();
    if (!c || AudioBus.hum || !AudioBus.music) return;
    const o1 = c.createOscillator(), o2 = c.createOscillator(), g = c.createGain();
    o1.type = "sine"; o2.type = "sine";
    o1.frequency.value = 55; o2.frequency.value = 110.3;
    g.gain.value = 0.01;
    o1.connect(g); o2.connect(g); g.connect(c.destination);
    o1.start(); o2.start();
    AudioBus.hum = [o1, o2]; AudioBus._humGain = g;
  }
  function stopHum() {
    if (!AudioBus.hum) return;
    AudioBus.hum.forEach(o => { try { o.stop(); } catch (e) {} });
    AudioBus.hum = null;
  }

  root.BM_AUDIO = {
    bus: AudioBus, unlock,
    setSfx(v) { AudioBus.sfx = v; },
    setMusic(on) { AudioBus.music = on; if (on && AudioBus.unlocked) startHum(); else stopHum(); },
    punch, kick, special, superMove, hit, block, ko, fight, win,
    shot: punch, paper: hit, clock: special, hurt: hit, level: fight, sting: win, boss: superMove, pickup: punch, pulse() {}
  };
})(typeof window !== "undefined" ? window : globalThis);

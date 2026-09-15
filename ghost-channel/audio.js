/* Hand-authored Web Audio: radio bed, melody, and cues. No samples. */
const GCAudio = (() => {
  let ctx = null;
  let master = null;
  let musicGain = null;
  let sfxGain = null;
  let music = null;
  let muted = false;
  let stepTimer = 0;

  function ensure() {
    if (ctx) return ctx;
    const AC = window.AudioContext || window.webkitAudioContext;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.9;
    musicGain = ctx.createGain();
    musicGain.gain.value = 0.16;
    sfxGain = ctx.createGain();
    sfxGain.gain.value = 0.34;
    musicGain.connect(master);
    sfxGain.connect(master);
    master.connect(ctx.destination);
    return ctx;
  }

  function beep(freq, dur, type, gain, dest) {
    if (muted) return;
    const c = ensure();
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type || "square";
    o.frequency.setValueAtTime(freq, c.currentTime);
    g.gain.setValueAtTime(0.0001, c.currentTime);
    g.gain.exponentialRampToValueAtTime(gain || 0.08, c.currentTime + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, c.currentTime + dur);
    o.connect(g);
    g.connect(dest || sfxGain);
    o.start();
    o.stop(c.currentTime + dur + 0.03);
  }

  function noiseBurst(dur, gain, freq) {
    if (muted) return;
    const c = ensure();
    const n = Math.floor(c.sampleRate * dur);
    const buf = c.createBuffer(1, n, c.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < n; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / n);
    const src = c.createBufferSource();
    const g = c.createGain();
    const f = c.createBiquadFilter();
    f.type = "bandpass";
    f.frequency.value = freq || 1400;
    src.buffer = buf;
    g.gain.value = gain || 0.045;
    src.connect(f); f.connect(g); g.connect(sfxGain);
    src.start();
  }

  function callsign(freq) {
    noiseBurst(0.16, 0.05, 1200);
    beep(freq, 0.1, "square", 0.07);
    setTimeout(() => beep(freq * 1.33, 0.08, "square", 0.05), 100);
    setTimeout(() => beep(freq * 0.67, 0.12, "triangle", 0.04), 210);
  }

  function deny() {
    beep(156, 0.12, "sawtooth", 0.07);
    setTimeout(() => beep(110, 0.18, "sawtooth", 0.06), 90);
  }
  function auth() {
    beep(392, 0.07, "triangle", 0.06);
    setTimeout(() => beep(523, 0.08, "triangle", 0.055), 70);
    setTimeout(() => beep(659, 0.12, "triangle", 0.05), 150);
  }
  function warn() {
    beep(82, 0.32, "sawtooth", 0.09);
    noiseBurst(0.28, 0.07, 700);
  }
  function click() { beep(920, 0.03, "square", 0.025); }
  function winSting() {
    [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => beep(f, 0.16, "triangle", 0.06), i * 90));
  }

  function startBed() {
    if (muted) return;
    const c = ensure();
    stopBed();

    const filter = c.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.value = 1400;
    filter.connect(musicGain);

    const pad = c.createOscillator();
    const pad2 = c.createOscillator();
    const padG = c.createGain();
    pad.type = "sine";
    pad2.type = "sine";
    pad.frequency.value = 110;
    pad2.frequency.value = 164.81;
    padG.gain.value = 0.22;
    pad.connect(padG); pad2.connect(padG); padG.connect(filter);
    pad.start(); pad2.start();

    const noise = c.createBufferSource();
    const nbuf = c.createBuffer(1, c.sampleRate * 2, c.sampleRate);
    const nd = nbuf.getChannelData(0);
    for (let i = 0; i < nd.length; i++) nd[i] = (Math.random() * 2 - 1) * 0.18;
    noise.buffer = nbuf; noise.loop = true;
    const ng = c.createGain(); ng.gain.value = 0.03;
    const nf = c.createBiquadFilter(); nf.type = "highpass"; nf.frequency.value = 1800;
    noise.connect(nf); nf.connect(ng); ng.connect(musicGain);
    noise.start();

    const bassNotes = [110, 110, 130.81, 98];
    const leadNotes = [220, 261.63, 246.94, 196, 220, 293.66, 246.94, 174.61];
    let step = 0;
    const tick = () => {
      if (muted || !music) return;
      const bass = bassNotes[step % bassNotes.length];
      const lead = leadNotes[step % leadNotes.length];
      beep(bass, 0.28, "sine", 0.055, musicGain);
      if (step % 2 === 0) beep(lead, 0.22, "triangle", 0.035, musicGain);
      if (step % 8 === 4) beep(lead * 1.5, 0.4, "sine", 0.02, musicGain);
      step += 1;
    };
    tick();
    stepTimer = setInterval(tick, 420);
    music = { pad, pad2, padG, noise, ng, filter };
  }

  function stopBed() {
    clearInterval(stepTimer);
    stepTimer = 0;
    if (!music) return;
    try { music.pad.stop(); music.pad2.stop(); music.noise.stop(); } catch (_) {}
    music = null;
  }

  function pulse() {
    if (muted || !musicGain) return;
    const c = ensure();
    musicGain.gain.cancelScheduledValues(c.currentTime);
    musicGain.gain.setValueAtTime(0.22, c.currentTime);
    musicGain.gain.exponentialRampToValueAtTime(0.16, c.currentTime + 0.45);
  }

  async function unlock() {
    const c = ensure();
    if (c.state === "suspended") await c.resume();
    startBed();
  }

  return { unlock, callsign, deny, auth, warn, click, winSting, pulse, startBed, stopBed, setMuted(v) { muted = v; if (v) stopBed(); else startBed(); } };
})();

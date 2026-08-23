const SFX = (() => {
  let ctx = null, master = null, last = 0;
  const PENTA = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25];

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.58;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function muted() {
    const s = typeof LITURGY !== "undefined" ? LITURGY.snapshot() : null;
    return s && s.settings && s.settings.audio === false;
  }

  function tone({ freq, type = "sine", dur = 0.15, vol = 0.4, glideTo = null, delay = 0 }) {
    if (muted()) return;
    const c = ensure();
    const t0 = c.currentTime + delay;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (glideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(glideTo, 1), t0 + dur);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(vol, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g); g.connect(master);
    osc.start(t0); osc.stop(t0 + dur + 0.05);
  }

  function noise({ dur = 0.08, vol = 0.12, freq = 1800, q = 2 }) {
    if (muted()) return;
    const c = ensure();
    const t0 = c.currentTime;
    const len = Math.floor(c.sampleRate * dur);
    const buf = c.createBuffer(1, len, c.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len);
    const src = c.createBufferSource();
    src.buffer = buf;
    const filter = c.createBiquadFilter();
    filter.type = "bandpass"; filter.frequency.value = freq; filter.Q.value = q;
    const g = c.createGain();
    g.gain.setValueAtTime(vol, t0);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(filter); filter.connect(g); g.connect(master);
    src.start(t0);
  }

  return {
    unlock() { ensure(); },
    strike(combo) {
      const now = performance.now();
      if (now - last < 32) return;
      last = now;
      const n = PENTA[Math.min(combo || 0, PENTA.length - 1)];
      tone({ freq: 180 + combo * 8, type: "triangle", dur: 0.07, vol: 0.2, glideTo: 110 });
      noise({ dur: 0.045, vol: 0.1, freq: 1600, q: 2.4 });
      tone({ freq: n, type: "sine", dur: 0.16, vol: 0.1 + Math.min(0.12, combo * 0.012) });
    },
    perfect(combo) {
      const n = PENTA[Math.min((combo || 1) - 1, PENTA.length - 1)];
      tone({ freq: n * 2, type: "sine", dur: 0.22, vol: 0.1, delay: 0.02 });
    },
    liturgy() {
      [261.63, 329.63, 392.0, 523.25].forEach((f, i) =>
        tone({ freq: f, type: "sine", dur: 0.55, vol: 0.14, delay: i * 0.08 })
      );
      tone({ freq: 98, type: "sine", dur: 1.1, vol: 0.12 });
    },
    upgrade() {
      tone({ freq: 392, type: "sine", dur: 0.22, vol: 0.14 });
      tone({ freq: 523, type: "sine", dur: 0.28, vol: 0.1, delay: 0.08 });
    },
    ofuda() {
      tone({ freq: 196, type: "sine", dur: 0.4, vol: 0.12 });
      noise({ dur: 0.12, vol: 0.06, freq: 420, q: 0.8 });
    },
    click() {
      tone({ freq: 520, type: "triangle", dur: 0.05, vol: 0.08, glideTo: 360 });
    },
  };
})();

const BGM = (() => {
  let ctx = null, master = null, running = false, timer = null, step = 0, rain = null;
  const notes = [130.81, 0, 164.81, 0, 196.0, 0, 174.61, 0];

  function muted() {
    const s = typeof LITURGY !== "undefined" ? LITURGY.snapshot() : null;
    return s && s.settings && s.settings.audio === false;
  }

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.0001;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function pad(freq, dur, vol) {
    if (!freq || muted()) return;
    const c = ensure();
    const t0 = c.currentTime;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(freq, t0);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(vol, t0 + 0.12);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g); g.connect(master);
    osc.start(t0); osc.stop(t0 + dur + 0.04);
  }

  function startRain() {
    if (rain || muted()) return;
    const c = ensure();
    const len = c.sampleRate * 2;
    const buf = c.createBuffer(1, len, c.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * 0.18;
    const src = c.createBufferSource();
    src.buffer = buf; src.loop = true;
    const f = c.createBiquadFilter();
    f.type = "highpass"; f.frequency.value = 900;
    const g = c.createGain();
    g.gain.value = 0.035;
    src.connect(f); f.connect(g); g.connect(master);
    src.start();
    rain = src;
  }

  function tick() {
    if (!running) return;
    if (!muted()) {
      const n = notes[step % notes.length];
      pad(n, 0.7, 0.028);
      if (step % 8 === 3) pad(196, 0.9, 0.018);
    }
    step++;
    timer = setTimeout(tick, 540);
  }

  return {
    start() {
      ensure();
      if (running) return;
      running = true;
      master.gain.setTargetAtTime(muted() ? 0.0001 : 0.4, ctx.currentTime, 0.6);
      startRain();
      tick();
    },
    setOn(on) {
      if (master && ctx) master.gain.setTargetAtTime(on ? 0.4 : 0.0001, ctx.currentTime, 0.25);
    },
    stop() {
      running = false;
      clearTimeout(timer);
      if (master && ctx) master.gain.setTargetAtTime(0.0001, ctx.currentTime, 0.4);
    },
  };
})();

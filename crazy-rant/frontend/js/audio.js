var SFX = (() => {
  let ctx = null, master = null, lastFire = 0, pulse = null;

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.56;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function tone({ freq, type = "square", dur = 0.12, vol = 0.22, glideTo = null, delay = 0 }) {
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
    osc.start(t0); osc.stop(t0 + dur + 0.04);
  }

  function noise({ dur = 0.08, vol = 0.12, freq = 1400, q = 1.1 }) {
    const c = ensure();
    const t0 = c.currentTime;
    const len = Math.floor(c.sampleRate * dur);
    const buf = c.createBuffer(1, len, c.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len);
    const src = c.createBufferSource();
    src.buffer = buf;
    const filter = c.createBiquadFilter();
    filter.type = "bandpass";
    filter.frequency.value = freq;
    filter.Q.value = q;
    const g = c.createGain();
    g.gain.setValueAtTime(vol, t0);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(filter); filter.connect(g); g.connect(master);
    src.start(t0);
  }

  return {
    unlock() { ensure(); },
    fire(pattern) {
      const now = performance.now();
      if (now - lastFire < 40) return;
      lastFire = now;
      const f = pattern === "burst" ? 220 : pattern === "spread" ? 310 : 380;
      tone({ freq: f, type: "square", dur: 0.07, vol: 0.1, glideTo: f * 1.8 });
      noise({ dur: 0.04, vol: 0.05, freq: 1800 });
    },
    hit() {
      tone({ freq: 180, type: "triangle", dur: 0.08, vol: 0.16, glideTo: 90 });
      noise({ dur: 0.05, vol: 0.08, freq: 900, q: 0.7 });
    },
    hurt() {
      tone({ freq: 140, type: "sawtooth", dur: 0.18, vol: 0.14, glideTo: 50 });
      noise({ dur: 0.12, vol: 0.12, freq: 400 });
    },
    phase() {
      [196, 247, 330].forEach((f, i) => tone({ freq: f, type: "square", dur: 0.16, vol: 0.12, delay: i * 0.05 }));
      noise({ dur: 0.16, vol: 0.1, freq: 700 });
    },
    bomb() {
      tone({ freq: 880, type: "sine", dur: 0.08, vol: 0.25, glideTo: 1760 });
      tone({ freq: 110, type: "sawtooth", dur: 0.6, vol: 0.35, glideTo: 30, delay: 0.04 });
      noise({ dur: 0.55, vol: 0.3, freq: 350, q: 0.5, delay: 0.02 });
    },
    relic() {
      [392, 523, 659, 784].forEach((f, i) => tone({ freq: f, type: "sine", dur: 0.18, vol: 0.15, delay: i * 0.06 }));
    },
    grazeCharge() {
      tone({ freq: 520, type: "triangle", dur: 0.06, vol: 0.12, glideTo: 880 });
    },
    win() {
      [262, 330, 392, 523].forEach((f, i) => tone({ freq: f, type: "square", dur: 0.2, vol: 0.14, delay: i * 0.07 }));
    },
    lose() {
      tone({ freq: 180, type: "sawtooth", dur: 0.4, vol: 0.14, glideTo: 60 });
      noise({ dur: 0.3, vol: 0.1, freq: 220 });
    },
    paper() {
      noise({ dur: 0.07, vol: 0.09, freq: 2400, q: 0.6 });
    },
    pulse(on) {
      if (!on) {
        if (pulse) { try { pulse.stop(); } catch (_) {} pulse = null; }
        return;
      }
      const c = ensure();
      if (pulse) return;
      const osc = c.createOscillator();
      const g = c.createGain();
      osc.type = "sine";
      osc.frequency.value = 52;
      g.gain.value = 0.04;
      osc.connect(g); g.connect(master);
      osc.start();
      pulse = osc;
    },
  };
})();

const SFX = (() => {
  let ctx = null, master = null, amb = null, muted = false, chain = 0;

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

  function tone({ freq, type = "sine", dur = 0.14, vol = 0.28, glideTo = null, delay = 0 }) {
    if (muted) return;
    const c = ensure();
    const t0 = c.currentTime + delay;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (glideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(glideTo, 1), t0 + dur);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(vol, t0 + 0.014);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g);
    g.connect(master);
    osc.start(t0);
    osc.stop(t0 + dur + 0.04);
  }

  function noise({ dur = 0.08, vol = 0.1, freq = 1400 }) {
    if (muted) return;
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
    filter.Q.value = 1.1;
    const g = c.createGain();
    g.gain.setValueAtTime(vol, t0);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    src.connect(filter);
    filter.connect(g);
    g.connect(master);
    src.start(t0);
  }

  function startDrone() {
    if (muted || amb) return;
    const c = ensure();
    const osc = c.createOscillator();
    const f = c.createBiquadFilter();
    const g = c.createGain();
    osc.type = "sine";
    osc.frequency.value = 78;
    f.type = "lowpass";
    f.frequency.value = 220;
    g.gain.value = 0.035;
    osc.connect(f);
    f.connect(g);
    g.connect(master);
    osc.start();
    amb = { osc, g };
  }

  function stopDrone() {
    if (!amb) return;
    try { amb.osc.stop(); } catch (_) {}
    amb = null;
  }

  const PENTA = [196, 220, 261.63, 293.66, 329.63, 392];

  return {
    unlock() { ensure(); startDrone(); },
    setMuted(on) {
      muted = !!on;
      if (master) master.gain.value = muted ? 0 : 0.56;
      if (muted) stopDrone();
      else startDrone();
    },
    setChain(n) { chain = Math.max(0, Math.min(5, n | 0)); },
    place() {
      tone({ freq: 420, type: "triangle", dur: 0.07, vol: 0.14, glideTo: 280 });
      noise({ dur: 0.03, vol: 0.05, freq: 2100 });
    },
    reroll() {
      tone({ freq: 180, type: "square", dur: 0.08, vol: 0.08 });
      tone({ freq: 240, type: "triangle", dur: 0.1, vol: 0.1, delay: 0.05 });
    },
    settle(n) {
      const step = Math.min(5, n | 0);
      [261, 329, 392].slice(0, 1 + Math.min(2, step)).forEach((f, i) => {
        tone({ freq: f, type: "triangle", dur: 0.2, vol: 0.14, delay: i * 0.05 });
      });
      noise({ dur: 0.08, vol: 0.07, freq: 900 });
    },
    combo() {
      const f = PENTA[chain];
      tone({ freq: f, type: "sine", dur: 0.16, vol: 0.16, glideTo: f * 1.25 });
    },
    shop() { tone({ freq: 330, type: "triangle", dur: 0.12, vol: 0.12 }); },
    evict() {
      tone({ freq: 140, type: "sawtooth", dur: 0.28, vol: 0.12, glideTo: 70 });
      tone({ freq: 98, type: "sine", dur: 0.36, vol: 0.14, delay: 0.04 });
    },
    win() {
      [261, 329, 392, 523].forEach((f, i) => tone({ freq: f, type: "triangle", dur: 0.2, vol: 0.13, delay: i * 0.07 }));
    },
  };
})();

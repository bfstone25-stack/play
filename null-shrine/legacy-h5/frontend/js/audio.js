/* NULL//SHRINE — Zen ASMR audio: pentatonic crystal / woodblock / singing bowl */
const SFX = (() => {
  let ctx = null;
  let master = null;
  let lastClick = 0;
  let chainStep = 0;
  let pack = "crystal"; // crystal | bowl | bamboo

  // C4 D4 E4 G4 A4 C5 — calm pentatonic ladder
  const PENTA = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25];

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.62;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function tone({ freq, type = "sine", dur = 0.15, vol = 0.4, glideTo = null, delay = 0 }) {
    const c = ensure();
    const t0 = c.currentTime + delay;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t0);
    if (glideTo) osc.frequency.exponentialRampToValueAtTime(Math.max(glideTo, 1), t0 + dur);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(vol, t0 + 0.018);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g); g.connect(master);
    osc.start(t0); osc.stop(t0 + dur + 0.05);
  }

  function partials(freq, dur, vol) {
    tone({ freq, type: "sine", dur, vol });
    tone({ freq: freq * 2.01, type: "sine", dur: dur * 0.8, vol: vol * 0.28, delay: 0.01 });
    tone({ freq: freq * 3.01, type: "triangle", dur: dur * 0.45, vol: vol * 0.1, delay: 0.02 });
  }

  function noise({ dur = 0.25, vol = 0.4, freq = 1200, q = 0.7, delay = 0 }) {
    const c = ensure();
    const t0 = c.currentTime + delay;
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

  function woodblock(freq) {
    tone({ freq, type: "triangle", dur: 0.07, vol: 0.18, glideTo: freq * 0.7 });
    noise({ dur: 0.04, vol: 0.08, freq: 1800, q: 2.2 });
  }

  function bowlHit(freq) {
    partials(freq * 0.5, 0.55, 0.22);
    tone({ freq: freq * 0.75, type: "sine", dur: 0.7, vol: 0.12, delay: 0.02 });
  }

  let chargeOsc = null;
  let chargeGain = null;

  return {
    unlock() { ensure(); },
    setPack(id) { pack = id || "crystal"; },
    setChain(step) { chainStep = Math.max(0, Math.min(8, step | 0)); },
    charge(amount) {
      const c = ensure();
      if (amount <= 0) {
        if (chargeGain && chargeGain._live) {
          chargeGain._live = false;
          chargeGain.gain.setTargetAtTime(0.0001, c.currentTime, 0.05);
        }
        return;
      }
      if (!chargeOsc) {
        chargeOsc = c.createOscillator();
        chargeGain = c.createGain();
        chargeOsc.type = "sine";
        chargeOsc.connect(chargeGain); chargeGain.connect(master);
        chargeGain.gain.value = 0.0001;
        chargeOsc.start();
      }
      chargeGain._live = true;
      // Soft breath-like drone instead of arcade sawtooth
      chargeOsc.frequency.setValueAtTime(72 + amount * 48, c.currentTime);
      chargeGain.gain.setTargetAtTime(0.02 + amount * 0.07, c.currentTime, 0.08);
    },
    impact() {
      partials(110, 0.28, 0.28);
      tone({ freq: 220, type: "sine", dur: 0.2, vol: 0.12, delay: 0.04 });
    },
    flipper() {
      woodblock(180 + Math.random() * 40);
    },
    flipperHit() {
      const f = PENTA[Math.min(chainStep, PENTA.length - 1)];
      if (pack === "bowl") bowlHit(f);
      else {
        partials(f * 0.75, 0.22, 0.28);
        tone({ freq: f * 1.5, type: "sine", dur: 0.16, vol: 0.12, delay: 0.03 });
      }
    },
    peg() {
      const now = performance.now();
      if (now - lastClick < 48) return;
      lastClick = now;
      const idx = Math.min(chainStep, PENTA.length - 1);
      const f = PENTA[idx] * (0.98 + Math.random() * 0.04);
      if (pack === "bowl") {
        bowlHit(f * 0.85);
      } else if (pack === "bamboo") {
        woodblock(f * 1.1);
      } else {
        partials(f, 0.18 + chainStep * 0.02, 0.14 + chainStep * 0.018);
      }
      if (chainStep >= 4) {
        tone({ freq: PENTA[Math.min(idx + 2, PENTA.length - 1)], type: "sine", dur: 0.22, vol: 0.08, delay: 0.05 });
      }
    },
    launch(power) {
      // Soft release — breath out + low chime
      noise({ dur: 0.22, vol: 0.12 + power * 0.12, freq: 320, q: 0.6 });
      partials(196 + power * 80, 0.35, 0.22 + power * 0.12);
      tone({ freq: 392, type: "sine", dur: 0.28, vol: 0.1, delay: 0.06, glideTo: 523 });
    },
    pocket() {
      partials(196, 0.28, 0.24);
      tone({ freq: 294, type: "sine", dur: 0.2, vol: 0.1, delay: 0.05 });
    },
    redZone() {
      [329.63, 392.0, 523.25].forEach((f, i) =>
        tone({ freq: f, type: "sine", dur: 0.24, vol: 0.16, delay: i * 0.07 })
      );
    },
    nearMiss() {
      tone({ freq: 98, type: "sine", dur: 0.16, vol: 0.35 });
      tone({ freq: 98, type: "sine", dur: 0.16, vol: 0.28, delay: 0.18 });
      tone({ freq: 784, type: "sine", dur: 0.12, vol: 0.1, delay: 0.08, glideTo: 523 });
    },
    jackpot() {
      const notes = [261.63, 329.63, 392.0, 523.25, 659.25];
      notes.forEach((f, i) => partials(f, 0.32, 0.16 - i * 0.01));
      notes.forEach((f, i) => tone({ freq: f, type: "sine", dur: 0.35, vol: 0.12, delay: 0.05 + i * 0.09 }));
    },
    fanfare() {
      [261.63, 329.63, 392.0, 523.25, 392.0, 523.25, 659.25].forEach((f, i) =>
        tone({ freq: f, type: "sine", dur: 0.28, vol: 0.16, delay: i * 0.11 })
      );
    },
    conjure() {
      // Temple bell + low resonance — talisman printing from the void
      partials(196.0, 0.85, 0.22);
      tone({ freq: 98.0, type: "sine", dur: 1.1, vol: 0.16 });
      tone({ freq: 392.0, type: "sine", dur: 0.55, vol: 0.12, delay: 0.08 });
      tone({ freq: 784.0, type: "triangle", dur: 0.35, vol: 0.08, delay: 0.16, glideTo: 523 });
      noise({ dur: 0.18, vol: 0.06, freq: 420, q: 0.8 });
    },
    bowlStrike() {
      bowlHit(PENTA[Math.min(chainStep, PENTA.length - 1)] * 0.9);
    },
    cascade() {
      for (let i = 0; i < 8; i++) {
        const f = PENTA[i % PENTA.length];
        tone({ freq: f, type: "sine", dur: 0.12, vol: 0.08, delay: i * 0.06 });
      }
    },
    click() {
      woodblock(520);
    },
    breakthrough() {
      [261.63, 392.0, 523.25].forEach((f, i) =>
        tone({ freq: f, type: "sine", dur: 0.3, vol: 0.18, delay: i * 0.08 })
      );
    },
    phiGain() {
      tone({ freq: 523.25, type: "sine", dur: 0.14, vol: 0.14, glideTo: 659.25 });
    },
    multiball() {
      [261.63, 329.63, 392.0, 523.25].forEach((f, i) =>
        tone({ freq: f, type: "sine", dur: 0.2, vol: 0.14, delay: i * 0.07 })
      );
    },
    boonSelect() {
      tone({ freq: 392, type: "sine", dur: 0.25, vol: 0.18 });
      tone({ freq: 523, type: "sine", dur: 0.3, vol: 0.14, delay: 0.1 });
    },
  };
})();

/* Soft ambient bed — intensity still tracks chain, but stays zen */
const BGM = (() => {
  let ctx = null, master = null, running = false, intensity = 0, timer = null, step = 0;
  const notes = [130.81, 0, 164.81, 0, 196.0, 0, 220.0, 164.81];

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
    if (!freq) return;
    const c = ensure();
    const t0 = c.currentTime;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(freq, t0);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(vol, t0 + 0.08);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(g); g.connect(master);
    osc.start(t0); osc.stop(t0 + dur + 0.05);
  }

  function tick() {
    if (!running) return;
    const n = notes[step % notes.length];
    pad(n, 0.55, 0.03 + intensity * 0.035);
    if (intensity > 0.55 && step % 8 === 4) pad(n * 2, 0.35, 0.02);
    step++;
    timer = setTimeout(tick, 520 - intensity * 80);
  }

  return {
    start() {
      ensure();
      if (running) return;
      running = true;
      master.gain.setTargetAtTime(0.42, ctx.currentTime, 0.6);
      tick();
    },
    setIntensity(v) {
      intensity = Math.max(0, Math.min(1, v));
      if (master && ctx) master.gain.setTargetAtTime(0.28 + intensity * 0.22, ctx.currentTime, 0.3);
    },
    stop() {
      running = false;
      clearTimeout(timer);
      if (master && ctx) master.gain.setTargetAtTime(0.0001, ctx.currentTime, 0.4);
    },
  };
})();

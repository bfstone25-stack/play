window.REBOUND_AUDIO = (() => {
  let ctx = null;
  let master = null;
  let drone = null;
  let enabled = true;
  let engaged = false;

  function ensure() {
    if (!enabled) return null;
    if (ctx) return ctx;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.22;
    master.connect(ctx.destination);
    return ctx;
  }

  function tone(freq, dur, type, gain, at) {
    const ac = ensure();
    if (!ac || !master) return;
    const t0 = at != null ? at : ac.currentTime;
    const o = ac.createOscillator();
    const g = ac.createGain();
    o.type = type || "sine";
    o.frequency.setValueAtTime(freq, t0);
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(gain || 0.08, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g);
    g.connect(master);
    o.start(t0);
    o.stop(t0 + dur + 0.02);
  }

  function noiseBurst(dur, gain, hp) {
    const ac = ensure();
    if (!ac || !master) return;
    const n = ac.createBuffer(1, Math.floor(ac.sampleRate * dur), ac.sampleRate);
    const data = n.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
    const src = ac.createBufferSource();
    src.buffer = n;
    const filter = ac.createBiquadFilter();
    filter.type = "highpass";
    filter.frequency.value = hp || 700;
    const g = ac.createGain();
    g.gain.value = gain || 0.05;
    src.connect(filter);
    filter.connect(g);
    g.connect(master);
    src.start();
  }

  function startDrone(era) {
    const ac = ensure();
    if (!ac || !master || drone) return;
    const o1 = ac.createOscillator();
    const o2 = ac.createOscillator();
    const g = ac.createGain();
    o1.type = "sine";
    o2.type = "triangle";
    const base = era >= 3 ? 92 : era >= 2 ? 78 : 62;
    o1.frequency.value = base;
    o2.frequency.value = base * 1.5;
    g.gain.value = 0.03;
    o1.connect(g);
    o2.connect(g);
    g.connect(master);
    o1.start();
    o2.start();
    drone = { o1, o2, g };
  }

  function stopDrone() {
    if (!drone) return;
    try { drone.o1.stop(); drone.o2.stop(); } catch (_) {}
    drone = null;
  }

  return {
    setEnabled(on) {
      enabled = !!on;
      if (!enabled) {
        stopDrone();
        if (ctx && ctx.state !== "closed") ctx.suspend().catch(() => {});
      } else if (ctx) {
        ctx.resume().catch(() => {});
      }
    },
    engage(era) {
      if (engaged) {
        startDrone(era || 0);
        return;
      }
      engaged = true;
      const ac = ensure();
      if (ac && ac.state === "suspended") ac.resume().catch(() => {});
      startDrone(era || 0);
    },
    setEra(era) {
      if (!drone || !ctx) return;
      const base = era >= 3 ? 92 : era >= 2 ? 78 : 62;
      drone.o1.frequency.setTargetAtTime(base, ctx.currentTime, 0.4);
      drone.o2.frequency.setTargetAtTime(base * 1.5, ctx.currentTime, 0.4);
    },
    intercom() {
      tone(880, 0.09, "square", 0.05);
      tone(620, 0.12, "square", 0.04, ensure() ? ensure().currentTime + 0.1 : 0);
    },
    spray() {
      noiseBurst(0.08, 0.035, 900);
    },
    coin(combo) {
      const ac = ensure();
      if (!ac) return;
      const n = 2 + Math.min(3, combo | 0);
      for (let i = 0; i < n; i++) {
        tone(520 + i * 90, 0.11, "triangle", 0.06, ac.currentTime + i * 0.045);
      }
    },
    buy() {
      tone(240, 0.08, "sine", 0.05);
      tone(360, 0.12, "triangle", 0.05, ensure() ? ensure().currentTime + 0.05 : 0);
    },
    miss() {
      tone(140, 0.18, "sawtooth", 0.04);
    },
    prestige() {
      const ac = ensure();
      if (!ac) return;
      [392, 494, 587, 784].forEach((f, i) => tone(f, 0.22, "triangle", 0.07, ac.currentTime + i * 0.08));
    },
    tap() {
      tone(300, 0.04, "sine", 0.03);
    },
    flip() {
      tone(180, 0.045, "square", 0.035);
    },
    bumper() {
      tone(420, 0.07, "triangle", 0.06);
      noiseBurst(0.04, 0.03, 600);
    },
  };
})();

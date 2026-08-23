/* ===== Web Audio 合成音效引擎（零外部资源） ===== */
const SFX = (() => {
  let ctx = null;
  let master = null;
  let lastClick = 0; // 限制钉子碰撞音频率，防爆音

  function ensure() {
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.7;
      master.connect(ctx.destination);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  // 通用：带包络的振荡器
  function tone({ freq, type = "sine", dur = 0.15, vol = 0.4, glideTo = null, delay = 0 }) {
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

  // 噪声 burst（发射/珠子雨）
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

  let chargeOsc = null;
  let chargeGain = null;

  return {
    unlock() { ensure(); },
    charge(amount) {
      const c = ensure();
      if (amount <= 0) {
        if (chargeGain && chargeGain._live) {
          chargeGain._live = false;
          chargeGain.gain.setTargetAtTime(0.0001, c.currentTime, 0.04);
        }
        return;
      }
      if (!chargeOsc) {
        chargeOsc = c.createOscillator();
        chargeGain = c.createGain();
        chargeOsc.type = "sawtooth";
        chargeOsc.connect(chargeGain); chargeGain.connect(master);
        chargeGain.gain.value = 0.0001;
        chargeOsc.start();
      }
      chargeGain._live = true;
      chargeOsc.frequency.setValueAtTime(48 + amount * 90, c.currentTime);
      chargeGain.gain.setTargetAtTime(0.04 + amount * 0.12, c.currentTime, 0.05);
    },
    impact() {
      tone({ freq: 70, type: "sine", dur: 0.16, vol: 0.55, glideTo: 36 });
      noise({ dur: 0.12, vol: 0.28, freq: 400, q: 0.5 });
    },
    // 钉子碰撞：短促高频 click，音高随机（pachinko 的灵魂：声音密度）
    peg() {
      const now = performance.now();
      if (now - lastClick < 55) return; // 限频
      lastClick = now;
      tone({ freq: 500 + Math.random() * 500, type: "triangle", dur: 0.06, vol: 0.16 + Math.random() * 0.1 });
    },
    // 发射：压缩空气
    launch(power) {
      noise({ dur: 0.28, vol: 0.38 + power * 0.35, freq: 240 + power * 420, q: 0.4 });
      tone({ freq: 90, type: "sawtooth", dur: 0.18, vol: 0.32 + power * 0.2, glideTo: 48 });
      tone({ freq: 420, type: "square", dur: 0.1, vol: 0.16, glideTo: 880 });
    },
    // 普通入槽：低频 thud + 金属声
    pocket() {
      tone({ freq: 130, type: "sine", dur: 0.18, vol: 0.5, glideTo: 70 });
      tone({ freq: 2100, type: "square", dur: 0.05, vol: 0.12 });
    },
    // 红区/大奖槽
    redZone() {
      tone({ freq: 220, type: "sawtooth", dur: 0.25, vol: 0.35, glideTo: 660 });
      tone({ freq: 1320, type: "square", dur: 0.18, vol: 0.2, delay: 0.05 });
    },
    // 近失效应：心跳双响（最强钩子）
    nearMiss() {
      tone({ freq: 90, type: "sine", dur: 0.12, vol: 0.55 });
      tone({ freq: 90, type: "sine", dur: 0.12, vol: 0.5, delay: 0.17 });
      tone({ freq: 1400, type: "sine", dur: 0.08, vol: 0.18, delay: 0.06, glideTo: 700 });
    },
    // JACKPOT 演出：上升琶音 + 蜂鸣
    jackpot() {
      const notes = [523, 659, 784, 1047, 1319];
      notes.forEach((f, i) => tone({ freq: f, type: "square", dur: 0.22, vol: 0.22, delay: i * 0.09 }));
      noise({ dur: 0.9, vol: 0.25, freq: 2500 });
      tone({ freq: 1568, type: "triangle", dur: 0.5, vol: 0.3, delay: 0.5, glideTo: 2093 });
    },
    // 庆祝旋律（每日挑战完成）
    fanfare() {
      const notes = [523, 659, 784, 1047, 784, 1047, 1319];
      notes.forEach((f, i) => tone({ freq: f, type: "triangle", dur: 0.25, vol: 0.25, delay: i * 0.12 }));
    },
    // 珠子雨（演出时背景）
    cascade() {
      noise({ dur: 0.6, vol: 0.2, freq: 3000 });
      for (let i = 0; i < 8; i++) {
        tone({ freq: 300 + Math.random() * 900, type: "triangle", dur: 0.08, vol: 0.12, delay: i * 0.07 });
      }
    },
    click() {
      tone({ freq: 900, type: "square", dur: 0.04, vol: 0.2 });
    }
  };
})();

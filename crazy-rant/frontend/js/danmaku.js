var DANMAKU = (() => {
  const PALETTE = ["ok", "sync", "cc", "own", "group", "loop", "power", "family", "bless", "rush", "knife", "stamp"];

  function W() { return (typeof COMBAT !== "undefined" && COMBAT.W) || 420; }
  function H() { return (typeof COMBAT !== "undefined" && COMBAT.H) || 720; }

  function word(state, opt) {
    const key = opt.key || PALETTE[(opt.seed || 0) % PALETTE.length];
    const lang = state.lang || "en";
    const text = opt.text || PHRASES.pick(lang, key, opt.seed || 0);
    const font = opt.font || (opt.shape === "giant" ? 22 : opt.shape === "needle" ? 12 : 15);
    state.hazards.spawn((h) => {
      h.x = opt.x;
      h.y = opt.y;
      h.vx = opt.vx || 0;
      h.vy = opt.vy || 0;
      h.ax = opt.ax || 0;
      h.ay = opt.ay || 0;
      h.r = opt.hit != null ? opt.hit : (opt.shape === "giant" ? 16 : opt.shape === "needle" ? 7 : 11);
      h.font = font;
      h.text = text;
      h.key = key;
      h.color = opt.color || PHRASES.color(key);
      h.shape = opt.shape || "card";
      h.motion = opt.motion || "linear";
      h.amp = opt.amp || 0;
      h.freq = opt.freq || 2.2;
      h.homing = opt.homing || 0;
      h.life = opt.life || 8;
      h.age = 0;
      h.rot = opt.rot || 0;
      h.spin = opt.spin || 0;
      h.split = opt.split || 0;
      h.splitKey = opt.splitKey || "ok";
      h.phase = opt.phase || 0;
      h.ox = opt.ox != null ? opt.ox : opt.x;
      h.oy = opt.oy != null ? opt.oy : opt.y;
      h.orbitR = opt.orbitR || 0;
      h.orbitA = opt.orbitA || 0;
      h.orbitSpd = opt.orbitSpd || 0;
      h.turn = opt.turn || 0;
      h.cap = opt.cap || 0;
      h.seed = opt.seed || 0;
    });
  }

  function aimed(state, speed) {
    const dx = state.player.x - state.boss.x;
    const dy = state.player.y - (state.boss.y + 40);
    const d = Math.hypot(dx, dy) || 1;
    return { vx: dx / d * speed, vy: dy / d * speed };
  }

  function rankOf(state) {
    return 1 + (state.rank || 0) * 0.18 + state.boss.meeting * 0.08;
  }

  /* --- pattern scripts. Each returns duration seconds. Rank scales count/speed. --- */

  function rain_ok(state) {
    const r = rankOf(state);
    const n = Math.round(5 + r * 2);
    const w = W();
    for (let i = 0; i < n; i++) {
      word(state, {
        x: 28 + i * ((w - 56) / Math.max(1, n - 1)),
        y: -20,
        vy: 70 + r * 18,
        key: i % 2 ? "ok" : "stamp",
        shape: "card",
        seed: (state.time * 9 + i) | 0,
        motion: "sine",
        amp: 26 + r * 4,
        freq: 1.6,
        hit: 10,
      });
    }
    return 0.72 / Math.min(1.6, r);
  }

  function fan_cc(state) {
    const r = rankOf(state);
    const n = Math.round(7 + r);
    const a0 = Math.PI * 0.22;
    const a1 = Math.PI - a0;
    const spd = 95 + r * 16;
    for (let i = 0; i < n; i++) {
      const a = a0 + (a1 - a0) * (n === 1 ? 0.5 : i / (n - 1));
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 36,
        vx: Math.cos(a) * spd,
        vy: Math.sin(a) * spd,
        key: "cc",
        shape: "bar",
        font: 13,
        seed: i,
        rot: a - Math.PI / 2,
        spin: 0,
        hit: 10,
      });
    }
    return 0.95 / Math.min(1.5, r);
  }

  function sine_align(state) {
    const r = rankOf(state);
    const n = Math.round(4 + r);
    for (let i = 0; i < n; i++) {
      word(state, {
        x: 40 + i * 80,
        y: -16,
        vy: 88 + r * 12,
        key: "sync",
        shape: "card",
        motion: "sine",
        amp: 48,
        freq: 2.4,
        phase: i * 0.8,
        seed: i + 3,
        hit: 11,
      });
    }
    return 0.8;
  }

  function spiral_empower(state) {
    const r = rankOf(state);
    const n = Math.round(8 + r * 2);
    const spd = 70 + r * 10;
    for (let i = 0; i < n; i++) {
      const a = state.time * 1.7 + i * ((Math.PI * 2) / n);
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 20,
        vx: Math.cos(a) * spd,
        vy: Math.sin(a) * spd,
        key: "power",
        shape: "stamp",
        motion: "turn",
        turn: 0.55 + r * 0.08,
        seed: i,
        hit: 10,
        font: 13,
      });
    }
    return 0.62;
  }

  function aimed_follow(state) {
    const r = rankOf(state);
    const n = Math.round(2 + r);
    for (let i = 0; i < n; i++) {
      const v = aimed(state, 130 + r * 20);
      const spread = (i - (n - 1) / 2) * 0.18;
      const ca = Math.cos(spread), sa = Math.sin(spread);
      word(state, {
        x: state.boss.x + (i - (n - 1) / 2) * 18,
        y: state.boss.y + 42,
        vx: v.vx * ca - v.vy * sa,
        vy: v.vx * sa + v.vy * ca,
        key: "own",
        shape: "card",
        motion: "homing",
        homing: 28 + r * 6,
        cap: 170,
        seed: i + 11,
        hit: 11,
      });
    }
    return 0.88;
  }

  function boomerang_sync(state) {
    const r = rankOf(state);
    const n = Math.round(5 + r);
    for (let i = 0; i < n; i++) {
      const a = Math.PI * 0.3 + i * 0.22;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 30,
        vx: Math.cos(a) * (140 + r * 10),
        vy: Math.sin(a) * (140 + r * 10),
        key: "sync",
        shape: "card",
        motion: "boomerang",
        seed: i,
        life: 5.5,
        hit: 11,
      });
    }
    return 1.05;
  }

  function splitter_group(state) {
    const r = rankOf(state);
    const n = Math.round(3 + r * 0.6);
    for (let i = 0; i < n; i++) {
      word(state, {
        x: 70 + i * ((W() - 140) / Math.max(1, n - 1)),
        y: state.boss.y + 50,
        vy: 70,
        key: "group",
        shape: "card",
        motion: "split",
        split: 1.15,
        splitKey: "stamp",
        seed: i + 4,
        life: 6,
        font: 16,
        hit: 12,
      });
    }
    return 1.2;
  }

  function ring_family(state) {
    const r = rankOf(state);
    const n = Math.round(10 + r * 2);
    const spd = 78 + r * 10;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2 + state.time;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 8,
        vx: Math.cos(a) * spd,
        vy: Math.sin(a) * spd,
        key: i % 2 ? "family" : "ok",
        shape: "card",
        seed: i,
        hit: 10,
      });
    }
    return 1.1;
  }

  function curtain_ok(state) {
    const r = rankOf(state);
    const cols = Math.round(6 + r);
    const gap = 1 + ((state.time * 3) | 0) % 3;
    for (let i = 0; i < cols; i++) {
      if (i === gap || i === gap + 1) continue;
      word(state, {
        x: 24 + i * ((W() - 48) / (cols - 1)),
        y: -24,
        vy: 95 + r * 10,
        key: "ok",
        shape: "card",
        seed: i + 20,
        hit: 11,
      });
    }
    return 0.55;
  }

  function side_cubicle(state) {
    const r = rankOf(state);
    const n = Math.round(4 + r);
    const fromLeft = ((state.time * 2) | 0) % 2 === 0;
    for (let i = 0; i < n; i++) {
      word(state, {
        x: fromLeft ? -30 : W() + 30,
        y: 180 + i * 70,
        vx: (fromLeft ? 1 : -1) * (110 + r * 14),
        vy: 20,
        key: "knife",
        shape: "bar",
        font: 14,
        seed: i + 7,
        motion: "sine",
        amp: 18,
        freq: 3,
        hit: 10,
      });
    }
    return 0.9;
  }

  function giant_blessing(state) {
    const r = rankOf(state);
    word(state, {
      x: 70 + (state.time * 97) % (W() - 140),
      y: -40,
      vy: 42 + r * 6,
      key: "bless",
      shape: "giant",
      font: 24,
      hit: 18,
      seed: (state.time * 3) | 0,
      life: 12,
    });
    const n = Math.round(3 + r);
    for (let i = 0; i < n; i++) {
      word(state, {
        x: 50 + i * 90,
        y: -10,
        vy: 120 + r * 16,
        key: "rush",
        shape: "needle",
        font: 12,
        seed: i + 30,
        hit: 7,
      });
    }
    return 1.15;
  }

  function flower(state) {
    const r = rankOf(state);
    const arms = 5;
    const n = Math.round(3 + r);
    const spd = 86 + r * 12;
    const rot = state.time * 0.9;
    for (let a = 0; a < arms; a++) {
      for (let k = 0; k < n; k++) {
        const ang = rot + a * ((Math.PI * 2) / arms) + k * 0.08;
        word(state, {
          x: state.boss.x,
          y: state.boss.y + 16,
          vx: Math.cos(ang) * (spd + k * 14),
          vy: Math.sin(ang) * (spd + k * 14),
          key: k % 2 ? "power" : "loop",
          shape: "stamp",
          font: 12,
          seed: a * 10 + k,
          motion: "turn",
          turn: k % 2 ? 0.4 : -0.35,
          hit: 9,
        });
      }
    }
    return 0.85;
  }

  function bounce_loop(state) {
    const r = rankOf(state);
    const n = Math.round(6 + r);
    for (let i = 0; i < n; i++) {
      const a = 0.4 + i * 0.22;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 24,
        vx: Math.cos(a) * (120 + r * 10),
        vy: Math.sin(a) * (90 + r * 8),
        key: "loop",
        shape: "stamp",
        motion: "bounce",
        seed: i,
        life: 7,
        hit: 10,
        font: 13,
      });
    }
    return 1.0;
  }

  function orbit_then_fire(state) {
    const r = rankOf(state);
    const n = Math.round(8 + r);
    for (let i = 0; i < n; i++) {
      word(state, {
        x: state.boss.x,
        y: state.boss.y,
        key: "cc",
        shape: "stamp",
        motion: "orbit",
        ox: state.boss.x,
        oy: state.boss.y,
        orbitR: 54 + (i % 3) * 18,
        orbitA: i * ((Math.PI * 2) / n),
        orbitSpd: 1.4 + r * 0.1,
        life: 2.4,
        split: 2.2,
        splitKey: "own",
        seed: i,
        hit: 9,
        font: 12,
      });
    }
    return 1.35;
  }

  function pip_storm(state) {
    rain_ok(state);
    fan_cc(state);
    const r = rankOf(state);
    const v = aimed(state, 150 + r * 18);
    word(state, {
      x: state.boss.x,
      y: state.boss.y + 40,
      vx: v.vx,
      vy: v.vy,
      key: "rush",
      shape: "giant",
      font: 20,
      hit: 16,
      seed: 99,
    });
    return 0.7;
  }

  function accel_rush(state) {
    const r = rankOf(state);
    const n = Math.round(6 + r);
    for (let i = 0; i < n; i++) {
      const a = Math.PI * 0.28 + i * 0.18;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 28,
        vx: Math.cos(a) * 40,
        vy: Math.sin(a) * 40,
        ay: 90 + r * 20,
        key: "rush",
        shape: "needle",
        motion: "accel",
        seed: i,
        hit: 7,
      });
    }
    return 0.75;
  }

  const CATALOG = {
    rain_ok, fan_cc, sine_align, spiral_empower, aimed_follow,
    boomerang_sync, splitter_group, ring_family, curtain_ok, side_cubicle,
    giant_blessing, flower, bounce_loop, orbit_then_fire, pip_storm, accel_rush,
  };

  const MEETINGS = [
    { id: "standup", hp: 2100, script: ["rain_ok", "fan_cc", "sine_align", "rain_ok", "curtain_ok"] },
    { id: "oneonone", hp: 2400, script: ["aimed_follow", "spiral_empower", "boomerang_sync", "splitter_group"] },
    { id: "allhands", hp: 2700, script: ["ring_family", "side_cubicle", "giant_blessing", "curtain_ok", "flower"] },
    { id: "pip", hp: 3200, script: ["bounce_loop", "orbit_then_fire", "accel_rush", "pip_storm", "flower"] },
  ];

  const ENDLESS = Object.keys(CATALOG);

  function run(name, state) {
    const fn = CATALOG[name];
    if (!fn) return 0.8;
    return fn(state) || 0.8;
  }

  return { CATALOG, MEETINGS, ENDLESS, word, run, rankOf };
})();

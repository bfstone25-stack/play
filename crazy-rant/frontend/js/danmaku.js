var DANMAKU = (() => {
  const PALETTE = ["ok", "sync", "cc", "own", "group", "loop", "power", "family", "bless", "rush", "knife", "stamp"];

  function W() { return (typeof COMBAT !== "undefined" && COMBAT.W) || 420; }
  function H() { return (typeof COMBAT !== "undefined" && COMBAT.H) || 720; }

  /* Spread ofuda across the shrine with a minimum column pitch so the
     6px player hitbox can weave. Extra requested columns are dropped. */
  function columns(n, pitch) {
    const usable = W() - 56;
    const maxN = Math.max(2, Math.floor(usable / pitch) + 1);
    const count = Math.min(n, maxN);
    const span = (count - 1) * pitch;
    const x0 = (W() - span) / 2;
    const xs = [];
    for (let i = 0; i < count; i++) xs.push(x0 + i * pitch);
    return xs;
  }

  function word(state, opt) {
    const key = opt.key || PALETTE[(opt.seed || 0) % PALETTE.length];
    const lang = state.lang || "en";
    const text = opt.text || PHRASES.pick(lang, key, opt.seed || 0);
    const shape = opt.shape || "ofuda";
    const font = opt.font || (shape === "giant" ? 14 : shape === "needle" ? 10 : 11);
    const hit = opt.hit != null ? opt.hit
      : (shape === "giant" ? 14 : shape === "needle" ? 4.5 : shape === "stamp" ? 11 : 6);
    state.hazards.spawn((h) => {
      h.x = opt.x;
      h.y = opt.y;
      h.vx = opt.vx || 0;
      h.vy = opt.vy || 0;
      h.ax = opt.ax || 0;
      h.ay = opt.ay || 0;
      h.r = hit;
      h.font = font;
      h.text = text;
      h.key = key;
      h.color = opt.color || PHRASES.color(key);
      h.shape = shape;
      h.motion = opt.motion || "linear";
      h.amp = opt.amp || 0;
      h.freq = opt.freq || 2.2;
      h.homing = opt.homing || 0;
      h.life = opt.life || 8;
      h.age = 0;
      /* Ofuda stay upright. Never rotate into a horizontal wall. */
      h.rot = 0;
      h.spin = 0;
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
    const xs = columns(4 + Math.min(3, Math.round(r)), 40);
    xs.forEach((x, i) => {
      word(state, {
        x, y: -28,
        vy: 62 + r * 10,
        key: i % 2 ? "ok" : "stamp",
        seed: (state.time * 9 + i) | 0,
        motion: "sine",
        amp: 12 + r * 2,
        freq: 1.4,
        hit: 6,
      });
    });
    return 0.72 / Math.min(1.6, r);
  }

  function fan_cc(state) {
    const r = rankOf(state);
    const n = Math.round(5 + Math.min(2, r));
    const a0 = Math.PI * 0.22;
    const a1 = Math.PI - a0;
    const spd = 80 + r * 12;
    for (let i = 0; i < n; i++) {
      const a = a0 + (a1 - a0) * (n === 1 ? 0.5 : i / (n - 1));
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 36,
        vx: Math.cos(a) * spd,
        vy: Math.sin(a) * spd,
        key: "cc",
        seed: i,
        hit: 6,
      });
    }
    return 0.95 / Math.min(1.5, r);
  }

  function sine_align(state) {
    const r = rankOf(state);
    const xs = columns(3 + Math.min(2, Math.round(r)), 56);
    xs.forEach((x, i) => {
      word(state, {
        x, y: -28,
        vy: 72 + r * 10,
        key: "sync",
        motion: "sine",
        amp: 16,
        freq: 1.6,
        phase: i * 0.8,
        seed: i + 3,
        hit: 5.5,
      });
    });
    return 0.8;
  }

  function spiral_empower(state) {
    const r = rankOf(state);
    const n = Math.round(6 + Math.min(3, r));
    const spd = 62 + r * 8;
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
        hit: 9,
        font: 11,
      });
    }
    return 0.62;
  }

  function aimed_follow(state) {
    const r = rankOf(state);
    const n = Math.round(2 + Math.min(2, r));
    for (let i = 0; i < n; i++) {
      const v = aimed(state, 118 + r * 16);
      const spread = (i - (n - 1) / 2) * 0.22;
      const ca = Math.cos(spread), sa = Math.sin(spread);
      word(state, {
        x: state.boss.x + (i - (n - 1) / 2) * 28,
        y: state.boss.y + 42,
        vx: v.vx * ca - v.vy * sa,
        vy: v.vx * sa + v.vy * ca,
        key: "own",
        motion: "homing",
        homing: 22 + r * 5,
        cap: 150,
        seed: i + 11,
        hit: 6,
      });
    }
    return 0.88;
  }

  function boomerang_sync(state) {
    const r = rankOf(state);
    const n = Math.round(4 + Math.min(2, r));
    for (let i = 0; i < n; i++) {
      const a = Math.PI * 0.3 + i * 0.28;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 30,
        vx: Math.cos(a) * (120 + r * 8),
        vy: Math.sin(a) * (120 + r * 8),
        key: "sync",
        motion: "boomerang",
        seed: i,
        life: 5.5,
        hit: 6,
      });
    }
    return 1.05;
  }

  function splitter_group(state) {
    const r = rankOf(state);
    const xs = columns(Math.round(3 + Math.min(1, r)), 90);
    xs.forEach((x, i) => {
      word(state, {
        x, y: state.boss.y + 50,
        vy: 64,
        key: "group",
        motion: "split",
        split: 1.15,
        splitKey: "stamp",
        seed: i + 4,
        life: 6,
        font: 12,
        hit: 7,
      });
    });
    return 1.2;
  }

  function ring_family(state) {
    const r = rankOf(state);
    const n = Math.round(8 + Math.min(3, r));
    const spd = 70 + r * 8;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2 + state.time;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 8,
        vx: Math.cos(a) * spd,
        vy: Math.sin(a) * spd,
        key: i % 2 ? "family" : "ok",
        seed: i,
        hit: 5.5,
      });
    }
    return 1.1;
  }

  function curtain_ok(state) {
    const r = rankOf(state);
    const cols = 8;
    const gap = 1 + ((state.time * 3) | 0) % 5;
    for (let i = 0; i < cols; i++) {
      if (i === gap || i === gap + 1) continue;
      word(state, {
        x: 36 + i * ((W() - 72) / (cols - 1)),
        y: -28,
        vy: 82 + r * 8,
        key: "ok",
        seed: i + 20,
        hit: 5.5,
      });
    }
    return 0.55;
  }

  function side_cubicle(state) {
    const r = rankOf(state);
    const n = Math.round(3 + Math.min(2, r));
    const fromLeft = ((state.time * 2) | 0) % 2 === 0;
    for (let i = 0; i < n; i++) {
      word(state, {
        x: fromLeft ? -16 : W() + 16,
        y: 200 + i * 90,
        vx: (fromLeft ? 1 : -1) * (90 + r * 10),
        vy: 16,
        key: "knife",
        seed: i + 7,
        motion: "sine",
        amp: 10,
        freq: 2.2,
        hit: 6,
      });
    }
    return 0.9;
  }

  function giant_blessing(state) {
    const r = rankOf(state);
    word(state, {
      x: 70 + (state.time * 97) % (W() - 140),
      y: -40,
      vy: 38 + r * 5,
      key: "bless",
      shape: "giant",
      font: 14,
      hit: 14,
      seed: (state.time * 3) | 0,
      life: 12,
    });
    columns(4 + Math.min(2, Math.round(r)), 52).forEach((x, i) => {
      word(state, {
        x, y: -36,
        vy: 108 + r * 12,
        key: "rush",
        shape: "needle",
        font: 10,
        seed: i + 30,
        hit: 4.5,
      });
    });
    return 1.15;
  }

  function flower(state) {
    const r = rankOf(state);
    const arms = 5;
    const n = Math.round(2 + Math.min(1, r));
    const spd = 78 + r * 10;
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
          font: 11,
          seed: a * 10 + k,
          motion: "turn",
          turn: k % 2 ? 0.4 : -0.35,
          hit: 8,
        });
      }
    }
    return 0.85;
  }

  function bounce_loop(state) {
    const r = rankOf(state);
    const n = Math.round(5 + Math.min(2, r));
    for (let i = 0; i < n; i++) {
      const a = 0.4 + i * 0.28;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 24,
        vx: Math.cos(a) * (108 + r * 8),
        vy: Math.sin(a) * (82 + r * 6),
        key: "loop",
        shape: "stamp",
        motion: "bounce",
        seed: i,
        life: 7,
        hit: 9,
        font: 11,
      });
    }
    return 1.0;
  }

  function orbit_then_fire(state) {
    const r = rankOf(state);
    const n = Math.round(6 + Math.min(2, r));
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
        hit: 8,
        font: 11,
      });
    }
    return 1.35;
  }

  function pip_storm(state) {
    rain_ok(state);
    fan_cc(state);
    const r = rankOf(state);
    const v = aimed(state, 140 + r * 14);
    word(state, {
      x: state.boss.x,
      y: state.boss.y + 40,
      vx: v.vx,
      vy: v.vy,
      key: "rush",
      shape: "giant",
      font: 14,
      hit: 14,
      seed: 99,
    });
    return 0.7;
  }

  function accel_rush(state) {
    const r = rankOf(state);
    const n = Math.round(4 + Math.min(2, r));
    for (let i = 0; i < n; i++) {
      const a = Math.PI * 0.28 + i * 0.22;
      word(state, {
        x: state.boss.x,
        y: state.boss.y + 28,
        vx: Math.cos(a) * 36,
        vy: Math.sin(a) * 36,
        ay: 80 + r * 16,
        key: "rush",
        shape: "needle",
        motion: "accel",
        seed: i,
        hit: 4.5,
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

  return { CATALOG, MEETINGS, ENDLESS, word, run, rankOf, columns };
})();

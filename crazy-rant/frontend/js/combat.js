var COMBAT = (() => {
  const W = 420, H = 720;
  const SPECS = {
    stream: { interval: 0.12, count: 1, spread: 0, speed: 520, font: 10 },
    spread: { interval: 0.16, count: 3, spread: 0.26, speed: 500, font: 10 },
    burst: { interval: 0.36, count: 5, spread: 0.34, speed: 540, font: 10 },
    wave: { interval: 0.14, count: 2, spread: 0.2, speed: 500, font: 10, sine: true },
  };

  function create() {
    return {
      player: { x: W * 0.5, y: H * 0.78, r: 6, hp: 7, maxHp: 7, iFrames: 0, vx: 0 },
      boss: BOSS.create(W, H),
      shots: makePool(() => ({ x: 0, y: 0, vx: 0, vy: 0, r: 10, kind: "ok", seed: 0, life: 1, font: 13, rot: 0, motion: "linear", amp: 0, phase: 0, age: 0 })),
      hazards: makePool(() => ({
        x: 0, y: 0, vx: 0, vy: 0, ax: 0, ay: 0, r: 10, type: "word", life: 1,
        homing: 0, rot: 0, text: "", shape: "ofuda", motion: "linear", amp: 0, freq: 2,
        age: 0, spin: 0, split: 0, splitKey: "ok", phase: 0, ox: 0, oy: 0,
        orbitR: 0, orbitA: 0, orbitSpd: 0, turn: 0, cap: 0, seed: 0, font: 11,
        color: "#eab308", key: "ok", flipped: 0,
      })),
      fx: makePool(() => ({ x: 0, y: 0, life: 1, color: "#eab308" })),
      combo: 0,
      comboT: 0,
      time: 0,
      fireAcc: 0,
      pattern: "stream",
      shotPower: 6,
      loadout: ["ok"],
      outcome: null,
      shake: 0,
      chroma: 0,
      reduced: false,
      keys: { l: false, r: false, u: false, d: false },
      lang: "en",
      graze: 0,
      grazeAcc: 0,
      score: 0,
      rank: 0,
      meetingName: "standup",
    };
  }

  function reset(state, opt) {
    state.player.x = W * 0.5;
    state.player.y = H * 0.78;
    state.player.hp = state.player.maxHp;
    state.player.iFrames = 0;
    state.boss = BOSS.create(W, H);
    if (opt.endless) BOSS.startEndless(state.boss);
    state.shots.live.slice().forEach(s => state.shots.kill(s));
    state.hazards.live.slice().forEach(h => state.hazards.kill(h));
    state.fx.live.slice().forEach(f => state.fx.kill(f));
    state.shots.reap(); state.hazards.reap(); state.fx.reap();
    state.combo = 0;
    state.comboT = 0;
    state.time = 0;
    state.fireAcc = 0;
    state.pattern = opt.pattern || "stream";
    state.shotPower = opt.shotPower || 6;
    state.loadout = opt.loadout && opt.loadout.length ? opt.loadout.slice() : ["ok"];
    state.outcome = null;
    state.shake = 0;
    state.chroma = 0;
    state.reduced = !!opt.reduced;
    state.lang = opt.lang || "en";
    state.graze = 0;
    state.grazeAcc = 0;
    state.score = 0;
    state.rank = opt.rank || 0;
    state.meetingName = DANMAKU.MEETINGS[0].id;
  }

  function aim(state, x, y) {
    const px = Math.max(18, Math.min(W - 18, x));
    const py = Math.max(H * 0.42, Math.min(H - 28, y));
    state.player.vx = px - state.player.x;
    state.player.x = px;
    state.player.y = py;
  }

  function fire(state) {
    const spec = SPECS[state.pattern] || SPECS.stream;
    const n = spec.count;
    for (let i = 0; i < n; i++) {
      const mid = (n - 1) / 2;
      const a = -Math.PI / 2 + (i - mid) * spec.spread;
      const kind = state.loadout[i % state.loadout.length];
      state.shots.spawn(s => {
        s.x = state.player.x;
        s.y = state.player.y - 20;
        s.vx = Math.cos(a) * spec.speed;
        s.vy = Math.sin(a) * spec.speed;
        s.r = 7;
        s.kind = kind;
        s.seed = (state.time * 17 + i * 3) | 0;
        s.life = 2.2;
        s.font = spec.font || 10;
        s.rot = 0;
        s.motion = spec.sine ? "sine" : "linear";
        s.amp = spec.sine ? 40 : 0;
        s.phase = i;
        s.age = 0;
      });
    }
    if (window.SFX) SFX.fire(state.pattern);
  }

  function burst(state, x, y, color) {
    state.fx.spawn(f => { f.x = x; f.y = y; f.life = 1; f.color = color || "#eab308"; });
  }

  function hurt(state, dmg) {
    if (state.player.iFrames > 0 || state.outcome) return;
    state.player.hp -= dmg;
    state.player.iFrames = 0.9;
    state.combo = 0;
    state.shake = state.reduced ? 0 : 10;
    if (window.SFX) SFX.hurt();
    if (state.player.hp <= 0) {
      state.player.hp = 0;
      state.outcome = "lose";
      if (window.SFX) SFX.lose();
    }
  }

  function splitWord(state, h) {
    const n = 4;
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2 + 0.4;
      DANMAKU.word(state, {
        x: h.x, y: h.y,
        vx: Math.cos(a) * 110,
        vy: Math.sin(a) * 110,
        key: h.splitKey || "stamp",
        shape: "stamp",
        font: 12,
        hit: 8,
        seed: (h.seed || 0) + i + 50,
        life: 5,
      });
    }
  }

  function stepHazard(state, h, dt) {
    h.age += dt;
    h.rot = 0;
    if (h.motion === "sine") {
      h.x += h.vx * dt + Math.cos((h.age + h.phase) * h.freq) * h.amp * dt;
      h.y += h.vy * dt;
    } else if (h.motion === "turn") {
      const a = Math.atan2(h.vy, h.vx) + h.turn * dt;
      const sp = Math.hypot(h.vx, h.vy) || 1;
      h.vx = Math.cos(a) * sp;
      h.vy = Math.sin(a) * sp;
      h.x += h.vx * dt;
      h.y += h.vy * dt;
    } else if (h.motion === "homing") {
      const dx = state.player.x - h.x, dy = state.player.y - h.y;
      const d = Math.hypot(dx, dy) || 1;
      h.vx += dx / d * h.homing * dt;
      h.vy += dy / d * h.homing * dt;
      const sp = Math.hypot(h.vx, h.vy) || 1;
      const cap = h.cap || 180;
      if (sp > cap) { h.vx = h.vx / sp * cap; h.vy = h.vy / sp * cap; }
      h.x += h.vx * dt;
      h.y += h.vy * dt;
    } else if (h.motion === "boomerang") {
      if (!h.flipped && h.age > 1.2) {
        h.vx *= -0.9;
        h.vy *= -0.9;
        h.flipped = 1;
      }
      h.x += h.vx * dt;
      h.y += h.vy * dt;
    } else if (h.motion === "bounce") {
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      if (h.x < 18 || h.x > W - 18) { h.vx *= -1; h.x = Math.max(18, Math.min(W - 18, h.x)); }
      if (h.y < 18) { h.vy *= -1; h.y = 18; }
    } else if (h.motion === "orbit") {
      h.ox = state.boss.x;
      h.oy = state.boss.y;
      h.orbitA += (h.orbitSpd || 1.2) * dt;
      h.x = h.ox + Math.cos(h.orbitA) * h.orbitR;
      h.y = h.oy + Math.sin(h.orbitA) * h.orbitR;
    } else if (h.motion === "accel") {
      h.vx += (h.ax || 0) * dt;
      h.vy += (h.ay || 0) * dt;
      h.x += h.vx * dt;
      h.y += h.vy * dt;
    } else if (h.motion === "split") {
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      if (h.split && h.age >= h.split) {
        splitWord(state, h);
        state.hazards.kill(h);
        return;
      }
    } else {
      if (h.homing) {
        const dx = state.player.x - h.x, dy = state.player.y - h.y;
        const d = Math.hypot(dx, dy) || 1;
        h.vx += dx / d * h.homing * dt;
        h.vy += dy / d * h.homing * dt;
      }
      h.x += h.vx * dt;
      h.y += h.vy * dt;
    }

    if (h.motion === "orbit" && h.split && h.age >= h.split) {
      const dx = state.player.x - h.x, dy = state.player.y - h.y;
      const d = Math.hypot(dx, dy) || 1;
      const sp = 140;
      h.vx = dx / d * sp;
      h.vy = dy / d * sp;
      h.motion = "linear";
      h.split = 0;
    }

    h.life -= dt;
    if (h.y > H + 50 || h.x < -70 || h.x > W + 70 || h.y < -80 || h.life <= 0) {
      state.hazards.kill(h);
      return;
    }

    const dist = Math.hypot(h.x - state.player.x, h.y - state.player.y);
    if (dist < (h.r || 10) + state.player.r) {
      state.hazards.kill(h);
      burst(state, h.x, h.y, "#e11d48");
      hurt(state, 1);
      return;
    }
    if (dist < (h.r || 10) + 22 && state.player.iFrames <= 0) {
      state.grazeAcc += dt;
      if (state.grazeAcc >= 0.05) {
        state.grazeAcc = 0;
        state.graze += 1;
        state.score += 10;
        if (state.graze > 0 && state.graze % 36 === 0 && state.player.hp < state.player.maxHp) {
          state.player.hp += 1;
        }
      }
    }
  }

  function update(state, dt) {
    if (state.outcome) {
      state.time += dt;
      state.shake = Math.max(0, state.shake - dt * 28);
      return;
    }
    state.time += dt;
    state.player.iFrames = Math.max(0, state.player.iFrames - dt);
    state.comboT -= dt;
    if (state.comboT <= 0) state.combo = Math.max(0, state.combo - dt * 4);
    state.shake = Math.max(0, state.shake - dt * 28);

    const spd = 230;
    if (state.keys.l) state.player.x -= spd * dt;
    if (state.keys.r) state.player.x += spd * dt;
    if (state.keys.u) state.player.y -= spd * dt;
    if (state.keys.d) state.player.y += spd * dt;
    state.player.x = Math.max(18, Math.min(W - 18, state.player.x));
    state.player.y = Math.max(H * 0.42, Math.min(H - 28, state.player.y));

    const spec = SPECS[state.pattern] || SPECS.stream;
    state.fireAcc += dt;
    if (state.fireAcc >= spec.interval) {
      state.fireAcc = 0;
      fire(state);
    }

    BOSS.update(state, dt);
    state.meetingName = DANMAKU.MEETINGS[state.boss.meeting] ? DANMAKU.MEETINGS[state.boss.meeting].id : "overtime";
    state.chroma = state.reduced ? 0 : (state.boss.meeting >= 3 || state.boss.endless ? 1 : state.boss.meeting >= 1 ? 0.35 : 0);

    state.shots.live.forEach(s => {
      s.age += dt;
      if (s.motion === "sine") s.x += Math.cos((s.age + s.phase) * 8) * 70 * dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
      if (s.y < -30 || s.x < -30 || s.x > W + 30 || s.life <= 0) state.shots.kill(s);
      else if (BOSS.hit(state.boss, s)) {
        state.boss.hp -= state.shotPower;
        state.combo += 1;
        state.comboT = 1.15;
        state.score += 4;
        burst(state, s.x, s.y, (GLYPHS.META[s.kind] || GLYPHS.META.ok).color);
        state.shots.kill(s);
        if (window.SFX) SFX.hit();
        if (state.boss.hp <= 0) BOSS.advance(state);
      }
    });

    state.hazards.live.forEach(h => stepHazard(state, h, dt));

    state.fx.live.forEach(f => {
      f.life -= dt * 2.4;
      if (f.life <= 0) state.fx.kill(f);
    });
    state.shots.reap();
    state.hazards.reap();
    state.fx.reap();
  }

  return { W, H, SPECS, create, reset, update, aim };
})();

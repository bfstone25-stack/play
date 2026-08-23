var COMBAT = (() => {
  const W = 420, H = 720;
  const SPECS = {
    stream: { interval: 0.11, count: 1, spread: 0, speed: 540 },
    spread: { interval: 0.18, count: 3, spread: 0.3, speed: 500 },
    burst: { interval: 0.4, count: 7, spread: 0.52, speed: 560 },
  };

  function create() {
    return {
      player: { x: W * 0.5, y: H * 0.78, r: 13, hp: 5, maxHp: 5, iFrames: 0, vx: 0 },
      boss: BOSS.create(W, H),
      shots: makePool(() => ({ x: 0, y: 0, vx: 0, vy: 0, r: 7, kind: "ok", seed: 0, life: 1 })),
      hazards: makePool(() => ({ x: 0, y: 0, vx: 0, vy: 0, r: 8, type: "sun", life: 1, homing: 0, rot: 0 })),
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
    };
  }

  function reset(state, opt) {
    state.player.x = W * 0.5;
    state.player.y = H * 0.78;
    state.player.hp = 5;
    state.player.iFrames = 0;
    state.boss = BOSS.create(W, H);
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
  }

  function aim(state, x, y) {
    const px = Math.max(18, Math.min(W - 18, x));
    const py = Math.max(H * 0.48, Math.min(H - 28, y));
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
        s.y = state.player.y - 18;
        s.vx = Math.cos(a) * spec.speed;
        s.vy = Math.sin(a) * spec.speed;
        s.r = state.pattern === "burst" ? 9 : 7;
        s.kind = kind;
        s.seed = (state.time * 17 + i * 3) | 0;
        s.life = 2.2;
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
    state.player.iFrames = 0.85;
    state.combo = 0;
    state.shake = state.reduced ? 0 : 10;
    if (window.SFX) SFX.hurt();
    if (state.player.hp <= 0) {
      state.player.hp = 0;
      state.outcome = "lose";
      if (window.SFX) SFX.lose();
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

    const spd = 220;
    if (state.keys.l) state.player.x -= spd * dt;
    if (state.keys.r) state.player.x += spd * dt;
    if (state.keys.u) state.player.y -= spd * dt;
    if (state.keys.d) state.player.y += spd * dt;
    state.player.x = Math.max(18, Math.min(W - 18, state.player.x));
    state.player.y = Math.max(H * 0.48, Math.min(H - 28, state.player.y));

    const spec = SPECS[state.pattern] || SPECS.stream;
    state.fireAcc += dt;
    if (state.fireAcc >= spec.interval) {
      state.fireAcc = 0;
      fire(state);
    }

    const prev = state.boss.phase;
    BOSS.update(state, dt);
    if (state.boss.phase !== prev && window.SFX) SFX.phase();
    state.chroma = state.reduced ? 0 : (state.boss.phase === 2 ? 1 : state.boss.phase === 1 ? 0.35 : 0);

    state.shots.live.forEach(s => {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
      if (s.y < -20 || s.x < -20 || s.x > W + 20 || s.life <= 0) state.shots.kill(s);
      else if (BOSS.hit(state.boss, s)) {
        state.boss.hp -= state.shotPower;
        state.combo += 1;
        state.comboT = 1.15;
        burst(state, s.x, s.y, (GLYPHS.META[s.kind] || GLYPHS.META.ok).color);
        state.shots.kill(s);
        if (window.SFX) SFX.hit();
        if (state.boss.hp <= 0) {
          state.boss.hp = 0;
          state.outcome = "win";
          state.shake = state.reduced ? 0 : 16;
          if (window.SFX) SFX.win();
        }
      }
    });

    state.hazards.live.forEach(h => {
      if (h.homing) {
        const dx = state.player.x - h.x, dy = state.player.y - h.y;
        const d = Math.hypot(dx, dy) || 1;
        h.vx += dx / d * h.homing * dt;
        h.vy += dy / d * h.homing * dt;
        const sp = Math.hypot(h.vx, h.vy) || 1;
        const cap = 180;
        if (sp > cap) { h.vx = h.vx / sp * cap; h.vy = h.vy / sp * cap; }
      }
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      h.rot += dt * 1.4;
      h.life -= dt;
      if (h.y > H + 30 || h.x < -40 || h.x > W + 40 || h.life <= 0) state.hazards.kill(h);
      else if (circleHit(h, state.player)) {
        state.hazards.kill(h);
        burst(state, h.x, h.y, "#e11d48");
        hurt(state, 1);
      }
    });

    state.fx.live.forEach(f => {
      f.life -= dt * 2.4;
      if (f.life <= 0) state.fx.kill(f);
    });
    state.shots.reap();
    state.hazards.reap();
    state.fx.reap();
  }

  return { W, H, create, reset, update, aim };
})();

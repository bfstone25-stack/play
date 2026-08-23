var BOSS = (() => {
  function create(W, H) {
    return {
      x: W * 0.5,
      y: H * 0.22,
      hw: 120,
      hh: 90,
      hp: 2400,
      maxHp: 2400,
      phase: 0,
      t: 0,
      acc: 0,
      smileT: 0,
    };
  }

  function phaseOf(hp, max) {
    const r = hp / max;
    if (r <= 0.1) return 2;
    if (r <= 0.4) return 2;
    if (r <= 0.7) return 1;
    return 0;
  }

  function hit(boss, shot) {
    const dx = shot.x - boss.x;
    const dy = shot.y - boss.y;
    return (dx * dx) / (boss.hw * boss.hw) + (dy * dy) / (boss.hh * boss.hh) < 1;
  }

  function spawnFan(state, count, speed, spread, type, color) {
    const b = state.boss;
    for (let i = 0; i < count; i++) {
      const mid = (count - 1) / 2;
      const a = Math.PI / 2 + (i - mid) * spread;
      state.hazards.spawn(h => {
        h.x = b.x;
        h.y = b.y + b.hh * 0.35;
        h.vx = Math.cos(a) * speed;
        h.vy = Math.sin(a) * speed;
        h.r = type === "poster" ? 12 : 8;
        h.type = type;
        h.color = color;
        h.life = 6;
        h.homing = 0;
        h.rot = a;
      });
    }
  }

  function spawnSmile(state, homing) {
    const b = state.boss;
    state.hazards.spawn(h => {
      h.x = b.x + (Math.random() - 0.5) * 80;
      h.y = b.y + 40;
      h.vx = (Math.random() - 0.5) * 40;
      h.vy = 70 + Math.random() * 40;
      h.r = 10;
      h.type = "smile";
      h.life = 7;
      h.homing = homing;
      h.rot = 0;
    });
  }

  function update(state, dt) {
    const b = state.boss;
    b.t += dt;
    b.acc += dt;
    b.smileT += dt;
    const next = phaseOf(b.hp, b.maxHp);
    if (next !== b.phase) {
      b.phase = next;
      b.acc = 0.8;
      if (!state.reduced) state.shake = 12;
    }
    const sway = Math.sin(b.t * 1.4) * 10;
    b.x = COMBAT.W * 0.5 + sway;

    if (b.phase === 0) {
      if (b.acc > 1.55) {
        b.acc = 0;
        spawnFan(state, 7, 132, 0.22, "sun");
        if (window.SFX) SFX.paper();
      }
      if (b.smileT > 2.4) {
        b.smileT = 0;
        spawnSmile(state, 0);
      }
    } else if (b.phase === 1) {
      if (b.acc > 1.05) {
        b.acc = 0;
        spawnFan(state, 9, 168, 0.2, "shard", "#22d3ee");
        spawnFan(state, 5, 150, 0.28, "poster");
        if (window.SFX) SFX.paper();
      }
      if (b.smileT > 1.6) {
        b.smileT = 0;
        spawnSmile(state, 70);
        spawnSmile(state, 70);
      }
    } else {
      if (b.acc > 0.68) {
        b.acc = 0;
        spawnFan(state, 6, 200, 0.18, "shard", "#e11d48");
        const saved = b.x;
        b.x = COMBAT.W * 0.28;
        spawnFan(state, 5, 190, 0.2, "sun");
        b.x = COMBAT.W * 0.72;
        spawnFan(state, 5, 190, 0.2, "shard", "#22d3ee");
        b.x = saved;
        if (window.SFX) SFX.paper();
      }
      if (b.smileT > 1.1) {
        b.smileT = 0;
        spawnSmile(state, 90);
      }
    }
  }

  function draw(ctx, boss, t, reduced) {
    const cracked = boss.phase >= 1;
    const berserk = boss.phase >= 2;
    const posters = [
      { x: -70, y: -18, w: 78, h: 96, r: -0.18 },
      { x: 64, y: -8, w: 72, h: 88, r: 0.16 },
      { x: -8, y: 10, w: 90, h: 70, r: 0.04 },
      { x: 28, y: -46, w: 64, h: 54, r: -0.1 },
      { x: -40, y: -52, w: 58, h: 50, r: 0.12 },
    ];
    ctx.save();
    ctx.translate(boss.x, boss.y + Math.sin(t * 2) * (reduced ? 0 : 4));
    if (berserk && !reduced) ctx.rotate(Math.sin(t * 8) * 0.03);
    posters.forEach((p, i) => {
      GLYPHS.drawPoster(ctx, p.x, p.y, p.w, p.h, p.r + Math.sin(t * 1.2 + i) * 0.03, cracked);
    });
    GLYPHS.drawSun(ctx, 0, -8, berserk ? 36 : 30, t);
    GLYPHS.drawSmile(ctx, -6, 18, 28, true);
    if (cracked) {
      ctx.strokeStyle = "#e11d48";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(-40, -20);
      ctx.lineTo(8, 6);
      ctx.lineTo(36, -12);
      ctx.stroke();
    }
    ctx.restore();
  }

  return { create, hit, update, draw, phaseOf };
})();

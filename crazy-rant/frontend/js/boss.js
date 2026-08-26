var BOSS = (() => {
  function create(W, H) {
    const first = DANMAKU.MEETINGS[0];
    return {
      x: W * 0.5,
      y: H * 0.2,
      hw: 118,
      hh: 86,
      hp: first.hp,
      maxHp: first.hp,
      phase: 0,
      meeting: 0,
      endless: 0,
      t: 0,
      acc: 0.4,
      scriptI: 0,
      lastPattern: "",
      recent: [],
      flash: 0,
    };
  }

  function startEndless(boss) {
    boss.endless = 1;
    boss.meeting = 4;
    boss.hp = 3600;
    boss.maxHp = 3600;
    boss.scriptI = 0;
    boss.acc = 0.2;
    boss.recent = [];
  }

  function hit(boss, shot) {
    /* Ofuda are tall paper, not points. Treat the shot as a vertical
       charm and the boss as the poster cluster. */
    const hw = (boss.hw || 118) + 36;
    const hh = (boss.hh || 86) + 28;
    const sw = (shot.hw || 10);
    const sh = (shot.hh || 28);
    const dx = Math.abs(shot.x - boss.x) - sw;
    const dy = Math.abs(shot.y - boss.y) - sh;
    const ex = Math.max(0, dx) / hw;
    const ey = Math.max(0, dy) / hh;
    return ex * ex + ey * ey < 1;
  }

  function pickEndless(boss) {
    const pool = DANMAKU.ENDLESS;
    for (let n = 0; n < 8; n++) {
      const name = pool[(Math.random() * pool.length) | 0];
      if (boss.recent.indexOf(name) < 0) return name;
    }
    return pool[boss.t * 3 % pool.length | 0];
  }

  function firePattern(state) {
    const b = state.boss;
    let name;
    if (b.endless) {
      name = pickEndless(b);
      b.recent.push(name);
      if (b.recent.length > 4) b.recent.shift();
      state.rank = Math.min(14, (state.rank || 0) + 0.12);
    } else {
      const meet = DANMAKU.MEETINGS[b.meeting] || DANMAKU.MEETINGS[0];
      name = meet.script[b.scriptI % meet.script.length];
      b.scriptI += 1;
    }
    b.lastPattern = name;
    const wait = DANMAKU.run(name, state);
    b.acc = -Math.max(0.35, wait);
    if (window.SFX) SFX.paper();
  }

  function advance(state) {
    const b = state.boss;
    if (b.endless) {
      b.hp = b.maxHp = Math.floor(b.maxHp * 1.08);
      state.rank = Math.min(14, (state.rank || 0) + 0.45);
      b.scriptI = 0;
      b.acc = 0.15;
      state.shake = state.reduced ? 0 : 14;
      if (window.SFX) SFX.phase();
      return;
    }
    if (b.meeting + 1 < DANMAKU.MEETINGS.length) {
      b.meeting += 1;
      const next = DANMAKU.MEETINGS[b.meeting];
      b.hp = next.hp;
      b.maxHp = next.hp;
      b.scriptI = 0;
      b.acc = 0.35;
      b.phase = Math.min(2, b.meeting);
      state.shake = state.reduced ? 0 : 14;
      state.player.iFrames = Math.max(state.player.iFrames, 0.8);
      if (window.SFX) SFX.phase();
      return;
    }
    state.boss.hp = 0;
    state.outcome = "win";
    state.shake = state.reduced ? 0 : 16;
    if (window.SFX) SFX.win();
  }

  function update(state, dt) {
    const b = state.boss;
    b.t += dt;
    b.acc += dt;
    const sway = Math.sin(b.t * 1.15) * (18 + b.meeting * 4);
    b.x = COMBAT.W * 0.5 + sway;
    b.phase = b.endless ? 2 : Math.min(2, b.meeting);
    if (b.acc >= 0) firePattern(state);
  }

  function draw(ctx, boss, t, reduced) {
    const cracked = boss.phase >= 1 || boss.meeting >= 1;
    const berserk = boss.phase >= 2 || boss.endless;
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
    if (boss.flash > 0) {
      ctx.globalAlpha = Math.min(0.55, boss.flash * 4);
      ctx.fillStyle = "#f8fafc";
      ctx.fillRect(-130, -90, 260, 200);
    }
    ctx.restore();
  }

  return { create, hit, update, draw, advance, startEndless };
})();

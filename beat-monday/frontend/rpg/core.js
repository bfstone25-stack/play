/* Beat Monday RPG core — pure logic, no DOM, no canvas. Node-testable.
 * Depends on kernel globals: makePool, circleHit, moveToward (kernel/pool.js),
 * combinePhrases, rantDamage, rantPattern, rantShotPower (kernel/rant.js).
 */
var BMCore = (() => {
  const W = 420, H = 640;

  function mulberry32(a) {
    a |= 0;
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      let t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  // ---------- profile (persists across days) ----------
  function newProfile() {
    return {
      role: "ic", week: 0, day: 0, level: 1, xp: 0,
      skills: [], owned: [], equipped: { hand: null, desk: null, wear: null },
      party: [], rant: ["ok"], cleared: [],
    };
  }

  function xpNeeded(level) { return 10 + level * 9; }

  function computeStats(profile) {
    const role = BMData.ROLES.find(r => r.id === profile.role) || BMData.ROLES[0];
    const lv = Math.max(1, profile.level | 0);
    const s = {
      hp: role.base.hp + role.growth.hp * (lv - 1),
      atk: role.base.atk + role.growth.atk * (lv - 1),
      rate: role.base.rate,
      spd: role.base.spd,
      flags: {},
    };
    const add = mods => {
      if (!mods) return;
      if (mods.hp) s.hp += mods.hp;
      if (mods.atk) s.atk += mods.atk;
      if (mods.rate) s.rate += mods.rate;
      if (mods.spd) s.spd += mods.spd;
    };
    ["hand", "desk", "wear"].forEach(slot => {
      const id = profile.equipped && profile.equipped[slot];
      const item = BMData.EQUIP.find(e => e.id === id);
      if (item) add(item.mods);
    });
    (profile.skills || []).forEach(id => {
      const sk = BMData.SKILLS.find(x => x.id === id);
      if (!sk) return;
      add(sk.mods);
      if (sk.flag) s.flags[sk.flag] = (s.flags[sk.flag] || 0) + 1;
    });
    s.hp = Math.max(20, Math.round(s.hp));
    s.atk = Math.max(1, +s.atk.toFixed(2));
    s.rate = Math.max(0.4, +s.rate.toFixed(2));
    s.spd = Math.max(40, Math.round(s.spd));
    s.partyDps = (profile.party || []).reduce((n, id) => {
      const p = BMData.PARTY.find(x => x.id === id);
      return n + (p ? p.dps : 0);
    }, 0);
    return s;
  }

  // ---------- run (one day) ----------
  function createRun(profile, dayIndex, seed) {
    const day = BMData.DAYS[dayIndex];
    const week = BMData.WEEKS[Math.min(profile.week | 0, BMData.WEEKS.length - 1)];
    const stats = computeStats(profile);
    return {
      day, dayIndex, week, stats, profile,
      rng: mulberry32(seed == null ? (dayIndex + 1) * 7919 : seed),
      t: 0, spawnT: 0, fireT: 0, phase: "wave", over: null,
      hp: stats.hp, maxHp: stats.hp,
      level: profile.level, xp: profile.xp, pending: null,
      px: W / 2, py: H * 0.72,
      foes: [], shots: [], foeShots: [], picks: [],
      boss: null, kills: 0, rantCombo: (profile.rant || []).slice(),
      lastPattern: "stream", shotsFired: 0, phrasesFired: 0, reward: null,
      hurtCd: 0, elapsedFire: 0,
    };
  }

  function spawnFoe(run) {
    const kinds = run.day.foes;
    const kind = kinds[Math.floor(run.rng() * kinds.length) % kinds.length];
    const base = BMData.FOES[kind];
    const edge = Math.floor(run.rng() * 4);
    let x, y;
    if (edge === 0) { x = run.rng() * W; y = -20; }
    else if (edge === 1) { x = run.rng() * W; y = H + 20; }
    else if (edge === 2) { x = -20; y = run.rng() * H; }
    else { x = W + 20; y = run.rng() * H; }
    const ramp = 1 + run.t / 90;
    run.foes.push({
      kind, x, y, r: base.r, color: base.color,
      hp: base.hp * ramp * run.week.hpMul, spd: base.spd, xp: base.xp,
      dmg: base.dmg * run.week.dmgMul, hit: 0,
    });
  }

  function spawnBoss(run) {
    run.phase = "boss";
    run.boss = {
      x: W / 2, y: 110, r: 34, hp: run.day.bossHp * run.week.hpMul,
      maxHp: run.day.bossHp * run.week.hpMul, dmg: run.day.bossDmg * run.week.dmgMul,
      shotT: 0, shotEvery: run.day.bossShot, dir: 1, hit: 0,
    };
  }

  function nearestFoe(run) {
    let best = null, bd = Infinity;
    const scan = run.foes.concat(run.boss ? [run.boss] : []);
    for (const f of scan) {
      const d = (f.x - run.px) ** 2 + (f.y - run.py) ** 2;
      if (d < bd) { bd = d; best = f; }
    }
    return best;
  }

  function rantCatalog() {
    return BMData.RANT.map(r => ({ id: r.id, power: r.power, text: r.id }));
  }

  function fire(run) {
    const target = nearestFoe(run);
    if (!target) return;
    const ang = Math.atan2(target.y - run.py, target.x - run.px);
    const rant = run.day.mode === "rant";
    let n = 1, spread = 0;
    if (rant) {
      const pattern = rantPattern(run.rantCombo, rantCatalog());
      run.lastPattern = pattern;
      if (pattern === "spread") { n = 3; spread = 0.26; }
      else if (pattern === "burst") { n = 5; spread = 0.34; }
    }
    if (run.stats.flags.multishot) { n += 1; spread = Math.max(spread, 0.18); }
    const combo = run.rantCombo.map(id => id);
    const dmg = rant
      ? run.stats.atk * 0.6 + rantShotPower(combo, rantCatalog())
      : run.stats.atk;
    for (let i = 0; i < n; i++) {
      const a = ang + (n > 1 ? (i - (n - 1) / 2) * spread : 0);
      run.shots.push({
        x: run.px, y: run.py, vx: Math.cos(a) * 420, vy: Math.sin(a) * 420,
        r: rant ? 10 : 5, dmg, life: 1.6, pierce: run.stats.flags.pierce ? 2 : 0,
        text: rant ? phraseFor(run, i) : "",
      });
      run.shotsFired++;
      if (rant) run.phrasesFired++;
    }
  }

  function phraseFor(run, i) {
    if (typeof BMPhrases === "undefined") return "";
    const lang = run.lang || "en";
    const combo = run.rantCombo;
    const id = combo[(run.shotsFired + i) % combo.length] || "ok";
    return BMPhrases.shot(lang, id);
  }

  function gainXp(run, n) {
    run.xp += n;
    while (run.xp >= xpNeeded(run.level)) {
      run.xp -= xpNeeded(run.level);
      run.level += 1;
      if (!run.pending) {
        const c = skillChoices(run);
        run.pending = c.length ? c : null;   // every skill maxed: level still counts
      }
    }
  }

  function skillChoices(run) {
    const pool = BMData.SKILLS.filter(s => {
      const have = (run.profile.skills || []).filter(x => x === s.id).length;
      return s.flag ? have < 1 : have < 5;
    });
    const out = [];
    const bag = pool.slice();
    while (out.length < 3 && bag.length) {
      out.push(bag.splice(Math.floor(run.rng() * bag.length) % bag.length, 1)[0].id);
    }
    return out;
  }

  function applySkill(run, id) {
    if (!run.pending || run.pending.indexOf(id) < 0) return false;
    run.profile.skills.push(id);
    run.pending = null;
    const before = run.maxHp;
    run.stats = computeStats(Object.assign({}, run.profile, { level: run.level }));
    run.maxHp = run.stats.hp;
    run.hp += Math.max(0, run.maxHp - before);
    return true;
  }

  function step(run, dt, target) {
    if (run.over || run.pending) return run;
    run.t += dt;
    run.hurtCd = Math.max(0, run.hurtCd - dt);

    // player follows the thumb
    if (target) {
      const dx = target.x - run.px, dy = target.y - run.py;
      const d = Math.hypot(dx, dy);
      if (d > 1) {
        const m = Math.min(d, run.stats.spd * dt);
        run.px += dx / d * m; run.py += dy / d * m;
      }
    }
    run.px = Math.max(12, Math.min(W - 12, run.px));
    run.py = Math.max(60, Math.min(H - 12, run.py));

    // spawning / boss gate
    if (run.phase === "wave") {
      run.spawnT += dt;
      if (run.spawnT >= run.day.spawnEvery) {
        run.spawnT = 0;
        for (let i = 0; i < run.day.perSpawn; i++) spawnFoe(run);
      }
      if (run.t >= run.day.dur) spawnBoss(run);
    }

    // auto-fire
    run.fireT += dt;
    const period = 1 / run.stats.rate;
    while (run.fireT >= period) { run.fireT -= period; fire(run); }

    // party chip damage
    if (run.stats.partyDps) {
      const t = nearestFoe(run);
      if (t) {
        t.hp -= run.stats.partyDps * dt;
        if (t !== run.boss && t.hp <= 0) killFoe(run, run.foes.indexOf(t));
      }
    }

    const slow = run.stats.flags.slowfoes ? 0.7 : 1;
    // foes
    for (let i = run.foes.length - 1; i >= 0; i--) {
      const f = run.foes[i];
      moveToward(f, run.px, run.py, f.spd * slow, dt);
      f.hit = Math.max(0, f.hit - dt * 4);
      if (circleHit({ x: f.x, y: f.y, r: f.r }, { x: run.px, y: run.py, r: 11 })) {
        damagePlayer(run, f.dmg);
        f.hp -= 1e9;
      }
      if (f.hp <= 0) killFoe(run, i);
    }

    // boss
    if (run.boss) {
      const b = run.boss;
      b.hit = Math.max(0, b.hit - dt * 4);
      b.x += b.dir * 52 * dt;
      if (b.x < 60) { b.x = 60; b.dir = 1; }
      if (b.x > W - 60) { b.x = W - 60; b.dir = -1; }
      b.y += Math.sin(run.t * 1.4) * 14 * dt;
      b.shotT += dt;
      if (b.shotT >= b.shotEvery) {
        b.shotT = 0;
        const n = 5;
        const base = Math.atan2(run.py - b.y, run.px - b.x);
        for (let i = 0; i < n; i++) {
          const a = base + (i - (n - 1) / 2) * 0.22;
          run.foeShots.push({ x: b.x, y: b.y, vx: Math.cos(a) * 150, vy: Math.sin(a) * 150, r: 6, dmg: b.dmg * 0.5, life: 5 });
        }
      }
      if (circleHit(b, { x: run.px, y: run.py, r: 11 })) damagePlayer(run, b.dmg * dt * 2.2);
      if (b.hp <= 0) {
        run.boss = null;
        run.phase = "clear";
        run.over = "clear";
        run.reward = run.day.drop;
      }
    }

    // player shots
    for (let i = run.shots.length - 1; i >= 0; i--) {
      const s = run.shots[i];
      s.x += s.vx * dt; s.y += s.vy * dt; s.life -= dt;
      let dead = s.life <= 0 || s.x < -30 || s.x > W + 30 || s.y < -30 || s.y > H + 30;
      if (!dead) {
        for (let j = run.foes.length - 1; j >= 0; j--) {
          const f = run.foes[j];
          if (!circleHit(s, f)) continue;
          f.hp -= s.dmg; f.hit = 1;
          if (f.hp <= 0) killFoe(run, j);
          if (s.pierce > 0) s.pierce--; else { dead = true; }
          break;
        }
      }
      if (!dead && run.boss && circleHit(s, run.boss)) {
        run.boss.hp -= s.dmg; run.boss.hit = 1;
        if (s.pierce > 0) s.pierce--; else dead = true;
      }
      if (dead) run.shots.splice(i, 1);
    }

    // incoming bullets
    for (let i = run.foeShots.length - 1; i >= 0; i--) {
      const s = run.foeShots[i];
      s.x += s.vx * dt; s.y += s.vy * dt; s.life -= dt;
      if (circleHit(s, { x: run.px, y: run.py, r: 10 })) { damagePlayer(run, s.dmg); run.foeShots.splice(i, 1); continue; }
      if (s.life <= 0 || s.x < -30 || s.x > W + 30 || s.y < -30 || s.y > H + 30) run.foeShots.splice(i, 1);
    }

    // pickups (rant day drops new phrases)
    for (let i = run.picks.length - 1; i >= 0; i--) {
      const p = run.picks[i];
      p.life -= dt;
      if (circleHit({ x: p.x, y: p.y, r: 16 }, { x: run.px, y: run.py, r: 12 })) {
        if (run.rantCombo.indexOf(p.id) < 0) run.rantCombo.push(p.id);
        run.picks.splice(i, 1);
      } else if (p.life <= 0) run.picks.splice(i, 1);
    }
    return run;
  }

  function killFoe(run, idx) {
    const f = run.foes[idx];
    if (!f) return;
    run.foes.splice(idx, 1);
    run.kills += 1;
    gainXp(run, f.xp);
    if (run.day.mode === "rant" && run.rng() < 0.05) {
      const pool = BMData.RANT.filter(r => run.rantCombo.indexOf(r.id) < 0);
      if (pool.length) run.picks.push({ x: f.x, y: f.y, id: pool[Math.floor(run.rng() * pool.length) % pool.length].id, life: 10 });
    }
  }

  function damagePlayer(run, n) {
    if (run.over) return;
    run.hp -= n;
    if (run.hp <= 0) { run.hp = 0; run.over = "dead"; run.phase = "dead"; }
  }

  // ---------- between days ----------
  function commitRun(profile, run) {
    profile.level = run.level;
    profile.xp = run.xp;
    profile.rant = run.rantCombo.slice();
    if (run.over !== "clear") return profile;
    const day = run.day.id;
    if (profile.cleared.indexOf(day) < 0) profile.cleared.push(day);
    if (run.reward && profile.owned.indexOf(run.reward) < 0) {
      profile.owned.push(run.reward);
      const item = BMData.EQUIP.find(e => e.id === run.reward);
      if (item && !profile.equipped[item.slot]) profile.equipped[item.slot] = item.id;
    }
    BMData.PARTY.forEach(p => {
      if (p.after === day && profile.party.indexOf(p.id) < 0) profile.party.push(p.id);
    });
    profile.day = run.dayIndex + 1;
    if (profile.day >= BMData.DAYS.length) { profile.day = 0; profile.week += 1; profile.weekend = true; }
    return profile;
  }

  function equip(profile, id) {
    const item = BMData.EQUIP.find(e => e.id === id);
    if (!item || profile.owned.indexOf(id) < 0) return false;
    profile.equipped[item.slot] = profile.equipped[item.slot] === id ? null : id;
    return true;
  }

  return {
    W, H, mulberry32, newProfile, xpNeeded, computeStats, createRun, step,
    skillChoices, applySkill, commitRun, equip, rantCatalog, nearestFoe,
  };
})();
if (typeof module !== "undefined") module.exports = BMCore;

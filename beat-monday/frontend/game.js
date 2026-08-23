(function (root) {
  const STAGE_W = 1600;
  const GRAVITY = 2600;
  const WALK = 240;
  const JUMP_V = 860;
  const ROUND_TIME = 60;
  const WINS_NEED = 2;
  const LADDER = ["intern", "pm", "hr", "finance", "boss"];
  const RED = "#e23b2f", COBALT = "#1e4cff", YELLOW = "#f5d031", BLACK = "#0a0b10";

  function mulberry32(a) {
    a |= 0;
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      let t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function dateSeed(d) {
    d = d || new Date();
    return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
  }
  function aabb(a, b) {
    return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  }
  function emptyInput() { return { l: 0, r: 0, u: 0, d: 0, p: 0, k: 0, s: 0 }; }

  const KITS = {
    hero: {
      name: "hero", w: 54, h: 168, color: COBALT, hp: 1000,
      punch: { frames: 16, start: 4, active: 4, dmg: 70, stun: 0.18, push: 22, meter: 12, box: { ox: 38, oy: 92, w: 62, h: 28 }, kind: "high" },
      kick: { frames: 22, start: 7, active: 5, dmg: 120, stun: 0.26, push: 34, meter: 18, box: { ox: 28, oy: 36, w: 88, h: 40 }, kind: "low" },
      special: { frames: 28, start: 10, active: 3, dmg: 150, stun: 0.22, push: 18, meter: -28, proj: { vx: 520, w: 36, h: 16, life: 0.7, dmg: 150 } },
      super: { frames: 36, start: 8, active: 6, dmg: 280, stun: 0.4, push: 50, meter: -100, proj: { vx: 640, w: 54, h: 22, life: 0.85, dmg: 280 } }
    },
    intern: {
      name: "intern", w: 50, h: 164, color: "#f4efe2", hp: 900,
      punch: { frames: 14, start: 3, active: 4, dmg: 60, stun: 0.16, push: 18, meter: 10, box: { ox: 34, oy: 88, w: 58, h: 26 }, kind: "high" },
      kick: { frames: 20, start: 6, active: 4, dmg: 100, stun: 0.22, push: 26, meter: 14, box: { ox: 24, oy: 40, w: 80, h: 36 }, kind: "low" },
      special: { frames: 26, start: 9, active: 3, dmg: 130, stun: 0.2, push: 14, meter: -24, proj: { vx: 480, w: 40, h: 28, life: 0.65, dmg: 130 } }
    },
    pm: {
      name: "pm", w: 56, h: 166, color: "#efeade", hp: 980,
      punch: { frames: 15, start: 4, active: 3, dmg: 75, stun: 0.17, push: 20, meter: 12, box: { ox: 40, oy: 86, w: 56, h: 30 }, kind: "high" },
      kick: { frames: 18, start: 5, active: 4, dmg: 115, stun: 0.24, push: 40, meter: 16, box: { ox: 20, oy: 20, w: 96, h: 34 }, kind: "low" },
      special: { frames: 30, start: 12, active: 4, dmg: 140, stun: 0.28, push: 12, meter: -30, proj: { vx: 400, w: 34, h: 34, life: 0.8, dmg: 140 } }
    },
    hr: {
      name: "hr", w: 58, h: 166, color: "#f3eee3", hp: 1080,
      punch: { frames: 18, start: 6, active: 4, dmg: 90, stun: 0.22, push: 28, meter: 14, box: { ox: 36, oy: 80, w: 70, h: 36 }, kind: "high" },
      kick: { frames: 24, start: 9, active: 5, dmg: 140, stun: 0.3, push: 38, meter: 18, box: { ox: 18, oy: 10, w: 100, h: 50 }, kind: "low" },
      special: { frames: 32, start: 12, active: 6, dmg: 170, stun: 0.32, push: 46, meter: -32 }
    },
    finance: {
      name: "finance", w: 56, h: 166, color: "#e8e3d6", hp: 1020,
      punch: { frames: 13, start: 3, active: 3, dmg: 65, stun: 0.15, push: 16, meter: 11, box: { ox: 36, oy: 84, w: 60, h: 24 }, kind: "high" },
      kick: { frames: 18, start: 5, active: 4, dmg: 105, stun: 0.2, push: 30, meter: 15, box: { ox: 40, oy: 30, w: 86, h: 28 }, kind: "low" },
      special: { frames: 24, start: 8, active: 3, dmg: 135, stun: 0.2, push: 16, meter: -26, proj: { vx: 560, w: 42, h: 18, life: 0.6, dmg: 135 } }
    },
    boss: {
      name: "boss", w: 64, h: 176, color: "#1a1d28", hp: 1300,
      punch: { frames: 20, start: 7, active: 5, dmg: 110, stun: 0.24, push: 36, meter: 16, box: { ox: 40, oy: 70, w: 86, h: 44 }, kind: "high" },
      kick: { frames: 26, start: 10, active: 5, dmg: 160, stun: 0.32, push: 48, meter: 20, box: { ox: 20, oy: 8, w: 110, h: 48 }, kind: "low" },
      special: { frames: 34, start: 12, active: 4, dmg: 190, stun: 0.3, push: 20, meter: -28, proj: { vx: 440, w: 60, h: 24, life: 0.9, dmg: 190 } }
    }
  };

  function makeFighter(id, x, face, kitName) {
    const kit = KITS[kitName];
    return {
      id, kit: kitName, x, y: 0, vx: 0, vy: 0, face,
      hp: kit.hp, maxHp: kit.hp, meter: 0,
      w: kit.w, h: kit.h,
      state: "idle", stateT: 0, stun: 0,
      airborne: false, attacking: false, blocking: false, crouch: false,
      move: null, hitOnce: false, combo: 0,
      input: emptyInput(), prev: emptyInput(),
      flash: 0, shake: 0
    };
  }

  function createMatch(opts) {
    opts = opts || {};
    const seed = (opts.seed == null ? dateSeed() : opts.seed) | 0;
    const foe = opts.foe || "intern";
    const p1 = makeFighter("p1", 620, 1, "hero");
    const p2 = makeFighter("p2", 900, -1, foe);
    return {
      seed, rng: mulberry32(seed),
      arcade: !!opts.arcade,
      ladderIndex: opts.ladderIndex || 0,
      foe,
      p1, p2,
      projectiles: [],
      sparks: [],
      mode: "intro",
      introT: 1.35,
      announce: "ROUND",
      announceT: 1.35,
      round: 1,
      wins: { p1: 0, p2: 0 },
      time: ROUND_TIME,
      freeze: 0,
      shake: 0,
      verdict: "fighting",
      headless: !!opts.headless,
      reducedMotion: !!opts.reducedMotion,
      events: []
    };
  }

  function emit(g, name, value) { g.events.push({ name, value: value || {}, t: g.time }); }

  function pressed(f, k) { return f.input[k] && !f.prev[k]; }

  function faceEach(a, b) {
    if (a.state === "hit" || a.state === "ko" || a.state === "attack") return;
    a.face = a.x <= b.x ? 1 : -1;
  }

  function setState(f, st, move) {
    if (f.state === st && !move) {
      f.attacking = st === "attack";
      f.blocking = st === "block";
      f.crouch = st === "crouch";
      return;
    }
    f.state = st;
    f.stateT = 0;
    f.move = move || null;
    f.hitOnce = false;
    f.attacking = st === "attack";
    f.blocking = st === "block";
    f.crouch = st === "crouch";
  }

  function startAttack(g, f, kind) {
    const kit = KITS[f.kit];
    let mv = kit[kind];
    if (kind === "special" && f.meter >= 100 && kit.super) {
      mv = kit.super;
      kind = "super";
    }
    if (!mv) return;
    if (kind === "super" && f.meter < 100) return;
    if (kind === "special" && f.meter < 28) return;
    const hitKind = mv.kind === "low" ? "low" : "high";
    setState(f, "attack", Object.assign({}, mv, { kind, hitKind }));
    if (mv.meter) f.meter = Math.max(0, Math.min(100, f.meter + mv.meter));
    emit(g, kind === "super" ? "super" : kind, { id: f.id });
    if (kind === "super") g.freeze = g.reducedMotion ? 0 : 0.18;
  }

  function hurtBox(f) {
    const crouch = f.state === "crouch" || f.state === "block" && f.input.d;
    const h = crouch ? f.h * 0.62 : f.h;
    return { x: f.x - f.w * 0.45, y: f.y, w: f.w * 0.9, h };
  }

  function hitBox(f) {
    if (f.state !== "attack" || !f.move) return null;
    const fr = Math.floor(f.stateT * 60);
    if (fr < f.move.start || fr >= f.move.start + f.move.active) return null;
    const b = f.move.box;
    if (!b) return null;
    const x = f.face === 1 ? f.x + b.ox : f.x - b.ox - b.w;
    const hitKind = f.move.hitKind || (f.move.kind === "kick" ? "low" : "high");
    return { x, y: f.y + b.oy, w: b.w, h: b.h, dmg: f.move.dmg, stun: f.move.stun, push: f.move.push, kind: hitKind };
  }

  function applyHit(g, atk, def, box, fromProj) {
    if (def.state === "ko") return;
    const crouchBlock = def.blocking && def.input.d;
    const standBlock = def.blocking && !def.input.d;
    const blocked = def.blocking && ((box.kind === "low" && crouchBlock) || (box.kind !== "low" && (standBlock || crouchBlock)));
    if (blocked && !fromProj) {
      def.hp -= Math.floor(box.dmg * 0.12);
      def.x += atk.face * 10;
      atk.x -= atk.face * 8;
      emit(g, "block", { id: def.id });
      return;
    }
    if (blocked && fromProj) {
      def.hp -= Math.floor(box.dmg * 0.2);
      emit(g, "block", { id: def.id });
      return;
    }
    const dmg = Math.floor(box.dmg * (def.combo > 2 ? 0.72 : 1));
    def.hp = Math.max(0, def.hp - dmg);
    def.combo += 1;
    atk.combo = 0;
    atk.meter = Math.min(100, atk.meter + 8);
    def.x += (atk.face || (box.face || 1)) * (box.push || 20);
    def.flash = 0.14;
    setState(def, def.hp <= 0 ? "ko" : "hit");
    def.stun = box.stun || 0.2;
    if (!g.reducedMotion) {
      g.freeze = fromProj ? 0.045 : 0.09;
      g.shake = 14;
    }
    if (def.hp <= 0) {
      def.vy = 420;
      def.vx = (atk.face || 1) * 220;
      emit(g, "ko", { winner: atk.id, loser: def.id });
    } else emit(g, "hit", { id: def.id, dmg });
    if (!g.headless) {
      for (let i = 0; i < 8; i++) {
        g.sparks.push({
          x: def.x + (Math.random() - 0.5) * 36,
          y: def.y + def.h * 0.62 + (Math.random() - 0.5) * 48,
          t: 0.16 + Math.random() * 0.14,
          col: i % 2 ? YELLOW : "#fff",
          vx: (Math.random() - 0.5) * 90
        });
      }
    }
  }

  function spawnProj(g, f, spec) {
    g.projectiles.push({
      x: f.x + f.face * 70,
      y: f.y + f.h * 0.62,
      vx: spec.vx * f.face,
      w: spec.w, h: spec.h, life: spec.life, dmg: spec.dmg,
      owner: f.id, face: f.face, kind: f.kit
    });
  }

  function updateFighter(g, f, foe, dt) {
    const kit = KITS[f.kit];
    f.stateT += dt;
    if (f.flash > 0) f.flash -= dt;
    if (f.stun > 0) f.stun -= dt;

    if (f.state === "ko") {
      f.vy -= GRAVITY * dt;
      f.y += f.vy * dt;
      f.x += f.vx * dt;
      if (f.y <= 0) { f.y = 0; f.vy = 0; f.vx *= 0.8; }
      return;
    }
    if (f.state === "hit") {
      if (f.stun <= 0) setState(f, f.airborne ? "jump" : "idle");
      f.x += f.vx * dt;
      if (f.airborne) {
        f.vy -= GRAVITY * dt;
        f.y += f.vy * dt;
        if (f.y <= 0) { f.y = 0; f.airborne = false; f.vy = 0; }
      }
      return;
    }

    if (f.state === "attack") {
      const fr = Math.floor(f.stateT * 60);
      if (f.move && f.move.proj && fr === f.move.start && !f.hitOnce) {
        spawnProj(g, f, f.move.proj);
        f.hitOnce = true;
      }
      if (!f.airborne && f.move && fr <= (f.move.start || 4) + 2) {
        f.x += f.face * 140 * dt;
      }
      if (f.stateT * 60 >= f.move.frames) setState(f, f.airborne ? "jump" : "idle");
    } else {
      const back = (f.face === 1 && f.input.l) || (f.face === -1 && f.input.r);
      const fwd = (f.face === 1 && f.input.r) || (f.face === -1 && f.input.l);
      if (f.y <= 0) { f.y = 0; f.airborne = false; f.vy = 0; }
      if (!f.airborne && pressed(f, "u")) {
        f.vy = JUMP_V;
        f.airborne = true;
        setState(f, "jump");
      } else if (!f.airborne && f.input.d && back) {
        setState(f, "block");
      } else if (!f.airborne && f.input.d) {
        setState(f, "crouch");
      } else if (!f.airborne && back && !fwd) {
        setState(f, "block");
      } else if (!f.airborne && (fwd || f.input.l || f.input.r)) {
        setState(f, "walk");
      } else if (!f.airborne) setState(f, "idle");

      if (!f.airborne && f.state !== "block") {
        if (pressed(f, "p")) startAttack(g, f, "punch");
        else if (pressed(f, "k")) startAttack(g, f, "kick");
        else if (pressed(f, "s")) startAttack(g, f, f.meter >= 100 && kit.super ? "special" : "special");
      }
    }

    if (f.airborne || f.state === "jump") {
      f.vy -= GRAVITY * dt;
      f.y += f.vy * dt;
      f.x += ((f.input.r ? 1 : 0) - (f.input.l ? 1 : 0)) * WALK * 0.7 * dt;
      if (f.y <= 0) { f.y = 0; f.airborne = false; f.vy = 0; if (f.state === "jump") setState(f, "idle"); }
    } else if (f.state === "walk") {
      const dir = (f.input.r ? 1 : 0) - (f.input.l ? 1 : 0);
      f.x += dir * WALK * dt;
    } else if (f.state === "block" && !f.input.d) {
      const dir = (f.input.r ? 1 : 0) - (f.input.l ? 1 : 0);
      f.x += dir * WALK * 0.35 * dt;
    }

    f.x = Math.max(80, Math.min(STAGE_W - 80, f.x));
    if (Math.abs(f.x - foe.x) < (f.w + foe.w) * 0.68 && Math.abs(f.y - foe.y) < 28) {
      const push = f.x < foe.x ? -1 : 1;
      f.x += push * 14;
    }
  }

  function thinkAI(g, f, foe) {
    const rng = g.rng;
    const dist = Math.abs(f.x - foe.x);
    const next = emptyInput();
    if (f.state === "hit" || f.state === "ko" || f.state === "attack") {
      f.input = next;
      return;
    }
    const toward = foe.x > f.x ? "r" : "l";
    const away = toward === "r" ? "l" : "r";
    const incoming = g.projectiles.some(p => p.owner !== f.id && Math.abs(p.x - f.x) < 180);
    if ((foe.attacking && dist < 170) || incoming) {
      next[away] = 1;
      if (rng() < 0.45) next.d = 1;
    } else if (dist > 300) {
      next[toward] = 1;
      if (rng() < 0.08) next.s = 1;
    } else if (dist > 160) {
      next[toward] = 1;
      if (rng() < 0.12) next.s = 1;
      if (rng() < 0.08) next.u = 1;
    } else {
      if (rng() < 0.22) next.p = 1;
      else if (rng() < 0.18) next.k = 1;
      else if (rng() < 0.1) next.s = 1;
      else next[toward] = 1;
    }
    if (g.foe === "boss" && rng() < 0.04) next.s = 1;
    f.input = next;
  }

  function updateProjectiles(g, dt) {
    for (let i = g.projectiles.length - 1; i >= 0; i--) {
      const p = g.projectiles[i];
      p.x += p.vx * dt;
      p.life -= dt;
      if (p.life <= 0 || p.x < 0 || p.x > STAGE_W) { g.projectiles.splice(i, 1); continue; }
      const foe = p.owner === "p1" ? g.p2 : g.p1;
      const hb = hurtBox(foe);
      const pb = { x: p.x - p.w / 2, y: p.y - p.h / 2, w: p.w, h: p.h };
      if (aabb(pb, hb)) {
        applyHit(g, p.owner === "p1" ? g.p1 : g.p2, foe, { dmg: p.dmg, stun: 0.22, push: 24, kind: "high", face: p.face }, true);
        g.projectiles.splice(i, 1);
      }
    }
  }

  function resolveHits(g) {
    [["p1", "p2"], ["p2", "p1"]].forEach(([a, b]) => {
      const atk = g[a], def = g[b];
      const box = hitBox(atk);
      if (!box || atk.hitOnce) return;
      if (aabb(box, hurtBox(def))) {
        atk.hitOnce = true;
        applyHit(g, atk, def, box, false);
      }
    });
  }

  function endRound(g, winner) {
    if (winner) g.wins[winner] += 1;
    else {
      if (g.p1.hp === g.p2.hp) { g.wins.p1 += 1; g.wins.p2 += 1; }
      else g.wins[g.p1.hp > g.p2.hp ? "p1" : "p2"] += 1;
    }
    g.mode = "roundEnd";
    g.announce = winner ? "KO" : "TIME";
    g.announceT = 1.6;
    emit(g, "round_end", { wins: Object.assign({}, g.wins), winner: winner || "time" });
  }

  function resetRound(g) {
    const foe = g.foe;
    g.p1 = makeFighter("p1", 620, 1, "hero");
    g.p2 = makeFighter("p2", 900, -1, foe);
    g.projectiles = [];
    g.time = ROUND_TIME;
    g.mode = "intro";
    g.introT = 1.2;
    g.announce = "ROUND";
    g.announceT = 1.2;
    g.round += 1;
  }

  function update(g, dt) {
    dt = Math.min(0.033, dt);
    if (g.mode === "pause" || g.verdict !== "fighting" && g.mode !== "intro" && g.mode !== "fight" && g.mode !== "roundEnd") return g;
    if (g.freeze > 0) { g.freeze -= dt; return g; }

    if (g.mode === "intro") {
      g.introT -= dt;
      g.announceT -= dt;
      if (g.introT <= 0.45) g.announce = "FIGHT";
      if (g.introT <= 0) { g.mode = "fight"; g.announce = ""; emit(g, "fight", { round: g.round }); }
      return g;
    }

    if (g.mode === "roundEnd") {
      g.announceT -= dt;
      if (g.announceT <= 0) {
        if (g.wins.p1 >= WINS_NEED || g.wins.p2 >= WINS_NEED) {
          g.verdict = g.wins.p1 > g.wins.p2 ? "heroic" : "death";
          g.mode = "results";
          emit(g, "match_over", summarize(g));
        } else resetRound(g);
      }
      return g;
    }

    if (g.mode !== "fight") return g;

    g.time = Math.max(0, g.time - dt);
    faceEach(g.p1, g.p2);
    faceEach(g.p2, g.p1);
    if (!g.headless || true) thinkAI(g, g.p2, g.p1);
    updateFighter(g, g.p1, g.p2, dt);
    updateFighter(g, g.p2, g.p1, dt);
    resolveHits(g);
    updateProjectiles(g, dt);
    for (let i = g.sparks.length - 1; i >= 0; i--) {
      g.sparks[i].t -= dt;
      if (g.sparks[i].t <= 0) g.sparks.splice(i, 1);
    }
    g.p1.prev = Object.assign({}, g.p1.input);
    g.p2.prev = Object.assign({}, g.p2.input);

    if (g.shake) {
      g.shake *= 0.8;
      if (g.shake < 0.35) g.shake = 0;
    }
    if (g.p1.hp <= 0 || g.p2.hp <= 0) {
      if (g.p1.state === "ko" && g.p1.stateT > 0.55) endRound(g, "p2");
      else if (g.p2.state === "ko" && g.p2.stateT > 0.55) endRound(g, "p1");
    } else if (g.time <= 0) endRound(g, null);
    return g;
  }

  function summarize(g) {
    return {
      verdict: g.verdict,
      foe: g.foe,
      arcade: g.arcade,
      ladderIndex: g.ladderIndex,
      rounds: g.wins.p1 + "-" + g.wins.p2,
      p1hp: g.p1.hp,
      p2hp: g.p2.hp,
      seed: g.seed
    };
  }

  function simulateMatch(opts) {
    const g = createMatch(Object.assign({ headless: true }, opts));
    let steps = 0;
    const dt = 1 / 60;
    while (g.verdict === "fighting" && steps++ < 60 * 320) {
      g.p1.input = emptyInput();
      if (steps % 18 === 0) g.p1.input.p = 1;
      if (steps % 31 === 0) g.p1.input.k = 1;
      if (steps % 47 === 0) g.p1.input.r = 1;
      if (steps % 53 === 0) g.p1.input.s = 1;
      update(g, dt);
      g.p1.prev = Object.assign({}, g.p1.input);
    }
    return summarize(g);
  }

  const SPRITES = {};
  const SPRITE_POSES = ["idle", "walk", "punch", "kick", "hit"];
  function loadSprites(done) {
    const ids = ["hero", "intern", "pm", "hr", "finance", "boss"];
    let left = ids.length * (SPRITE_POSES.length + 1) + 1;
    const tick = () => { if (--left <= 0 && done) done(); };
    ids.forEach(id => {
      const portrait = new Image();
      portrait.onload = portrait.onerror = tick;
      portrait.src = "assets/fighters/" + id + ".webp";
      SPRITES[id] = portrait;
      SPRITE_POSES.forEach(pose => {
        const im = new Image();
        im.onload = im.onerror = tick;
        im.src = "assets/sprites/" + id + "-" + pose + ".webp";
        SPRITES[id + "-" + pose] = im;
      });
    });
    const stage = new Image();
    stage.onload = stage.onerror = tick;
    stage.src = "assets/sprites/stage-office.webp";
    SPRITES.stage = stage;
  }

  function boot() {
    const I = root.BM_I18N, A = root.BM_AUDIO;
    const canvas = document.getElementById("game");
    const ctx = canvas.getContext("2d", { alpha: false });
    loadSprites();
    let lang = localStorage.getItem("bm_lang") || "en";
    if (I.LANGS.indexOf(lang) < 0) lang = "en";
    const settings = {
      sfx: localStorage.getItem("bm_sfx") !== "0",
      music: localStorage.getItem("bm_music") !== "0",
      haptics: localStorage.getItem("bm_haptics") !== "0",
      motion: localStorage.getItem("bm_motion") !== "0"
    };
    const reducedPref = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let g = null, last = 0, raf = 0, view = { w: 800, h: 480, dpr: 1 };
    let keys = {}, pad = { l: 0, r: 0, u: 0, d: 0, p: 0, k: 0, s: 0 };
    let versusIdx = 0;
    let camX = STAGE_W / 2;

    function t() { return I.tr(lang); }
    function tel(name, value) { if (root.TEL) root.TEL.ev(name, Object.assign({ language: lang }, value || {})); }
    function show(id, on) { const el = document.getElementById(id); if (el) el.classList.toggle("show", !!on); }

    function syncLang() {
      document.documentElement.lang = lang === "zh" ? "zh-CN" : lang === "pt" ? "pt-BR" : lang;
      const tr = t();
      document.title = tr.local + " — BEAT MONDAY";
      document.getElementById("wordLocal").textContent = tr.local;
      document.getElementById("wordEn").textContent = (lang === "zh" || lang === "ja") ? "BEAT MONDAY" : "";
      document.getElementById("homeTag").textContent = tr.tag;
      document.getElementById("homeQuote").textContent = tr.quote;
      document.getElementById("btnDaily").textContent = tr.playDaily;
      document.getElementById("btnPractice").textContent = tr.playPractice;
      document.getElementById("btnHow").textContent = tr.how;
      document.getElementById("btnSettings").textContent = tr.settings;
      document.getElementById("btnDebrief").textContent = tr.debrief;
      document.getElementById("homeFoot").textContent = tr.support;
      document.getElementById("howTitle").textContent = tr.how;
      document.getElementById("howBody").innerHTML = tr.howBody.map(s => "<div>" + s + "</div>").join("");
      document.getElementById("howGo").textContent = tr.howGo;
      document.getElementById("setTitle").textContent = tr.settings;
      document.getElementById("pauseTitle").textContent = tr.pause;
      document.getElementById("btnResume").textContent = tr.resume;
      document.getElementById("btnQuit").textContent = tr.quit;
      document.getElementById("btnP").textContent = tr.punch;
      document.getElementById("btnK").textContent = tr.kick;
      document.getElementById("btnS").textContent = tr.special;
      document.getElementById("langDock").innerHTML = I.LANGS.map(l =>
        '<button class="' + (l === lang ? "on" : "") + '" data-lang="' + l + '">' + I.LANG_LABEL[l] + "</button>"
      ).join("");
      syncSettings();
    }
    function syncSettings() {
      const tr = t();
      const rows = [["sfx", tr.sfx, settings.sfx], ["music", tr.music, settings.music], ["haptics", tr.haptics, settings.haptics], ["motion", tr.motion, settings.motion]];
      document.getElementById("setRows").innerHTML = rows.map(([id, label, on]) =>
        '<button class="setRow" data-set="' + id + '"><span>' + label + "</span><b>" + (on ? tr.on : tr.off) + "</b></button>"
      ).join("");
      if (A) { A.setSfx(settings.sfx); A.setMusic(settings.music); }
    }

    function resize() {
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const w = Math.min(window.innerWidth, 1100);
      const h = window.innerHeight;
      view.w = w; view.h = h; view.dpr = dpr;
      canvas.style.width = w + "px";
      canvas.style.height = h + "px";
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }

    let pendingChapter = 0;
    function fillStory(chapter) {
      const tr = t();
      const ch = (tr.story || [])[chapter] || tr.story[0];
      const foe = ch.foe || LADDER[Math.min(chapter, LADDER.length - 1)];
      document.getElementById("storyKicker").textContent = ch.kicker;
      document.getElementById("storyTitle").textContent = ch.title;
      document.getElementById("storyBody").textContent = ch.body;
      document.getElementById("storyGo").textContent = ch.go || tr.next;
      const img = document.getElementById("storyArt");
      img.src = "assets/fighters/" + (ch.ending ? "hero" : foe) + ".webp";
      img.alt = tr.fighters[foe] || tr.p1;
    }
    function openStory(chapter) {
      pendingChapter = chapter;
      fillStory(chapter);
      show("homeOv", false);
      show("resultsOv", false);
      show("storyOv", true);
    }
    function startArcade() {
      if (A) A.unlock();
      openStory(0);
    }
    function startChapterFight(index) {
      g = createMatch({ arcade: true, ladderIndex: index, foe: LADDER[index], seed: dateSeed() + index, reducedMotion: reducedPref || !settings.motion });
      afterStart();
      tel("game_started", { mode: "campaign", foe: g.foe, chapter: index });
    }
    function startVersus() {
      if (A) A.unlock();
      g = createMatch({ arcade: false, foe: LADDER[versusIdx], seed: Date.now() & 0x7fffffff, reducedMotion: reducedPref || !settings.motion });
      versusIdx = (versusIdx + 1) % LADDER.length;
      afterStart();
      tel("game_started", { mode: "versus", foe: g.foe });
    }
    function afterStart() {
      camX = STAGE_W / 2;
      show("homeOv", false); show("resultsOv", false); show("pauseOv", false);
      document.getElementById("hud").classList.add("on");
      last = performance.now();
      if (!raf) loop(last);
    }

    function readP1() {
      const i = emptyInput();
      if (keys.ArrowLeft || keys.KeyA || pad.l) i.l = 1;
      if (keys.ArrowRight || keys.KeyD || pad.r) i.r = 1;
      if (keys.ArrowUp || keys.KeyW || pad.u) i.u = 1;
      if (keys.ArrowDown || keys.KeyS || pad.d) i.d = 1;
      if (keys.KeyJ || keys.KeyZ || pad.p) i.p = 1;
      if (keys.KeyK || keys.KeyX || pad.k) i.k = 1;
      if (keys.KeyL || keys.KeyC || pad.s) i.s = 1;
      return i;
    }

    function loop(now) {
      raf = requestAnimationFrame(loop);
      const dt = Math.min(0.033, (now - last) / 1000);
      last = now;
      if (document.hidden || !g) return;
      if (g.mode === "fight" || g.mode === "intro") g.p1.input = readP1();
      const before = g.events.length;
      const prevMode = g.mode;
      if (g.mode !== "pause") update(g, dt);
      drain(before);
      if (g.mode === "results" && prevMode !== "results") {
        if (g.arcade && g.verdict === "heroic" && g.ladderIndex < LADDER.length - 1) {
          document.getElementById("hud").classList.remove("on");
          openStory(g.ladderIndex + 1);
        } else if (g.arcade && g.verdict === "heroic") {
          document.getElementById("hud").classList.remove("on");
          openStory(LADDER.length);
        } else endToResults();
      }
      draw();
      paintHud();
    }

    function drain(from) {
      for (let i = from; i < g.events.length; i++) {
        const ev = g.events[i];
        if (!A) continue;
        if (ev.name === "punch") A.punch();
        else if (ev.name === "kick") A.kick();
        else if (ev.name === "special") A.special();
        else if (ev.name === "super") A.superMove();
        else if (ev.name === "hit") { A.hit(); if (settings.haptics && navigator.vibrate) navigator.vibrate(16); }
        else if (ev.name === "block") A.block();
        else if (ev.name === "ko") A.ko();
        else if (ev.name === "fight") A.fight();
        else if (ev.name === "match_over") tel("run_over", ev.value);
      }
      if (g.events.length > 60) g.events.splice(0, g.events.length - 20);
    }

    function endToResults() {
      const tr = t();
      const s = summarize(g);
      const title = s.verdict === "heroic" ? tr.resultsHeroic : tr.resultsDeath;
      document.getElementById("resTitle").textContent = title;
      document.getElementById("resTitle").dataset.v = s.verdict;
      document.getElementById("resStats").innerHTML =
        "<div><i>" + tr.level + "</i><b>" + tr.fighters[s.foe] + "</b></div>" +
        "<div><i>" + tr.kills + "</i><b>" + s.rounds + "</b></div>" +
        "<div><i>" + tr.time + "</i><b>" + (s.verdict === "heroic" ? "KO" : "KO") + "</b></div>";
      document.getElementById("btnShare").textContent = tr.share;
      document.getElementById("btnAgain").textContent = tr.again;
      document.getElementById("btnHome").textContent = tr.home;
      show("resultsOv", true);
      if (A) { if (s.verdict === "heroic") A.win(); else A.ko(); }
      tel("run_over", s);
    }

    function paintHud() {
      if (!g) return;
      const tr = t();
      document.getElementById("p1Name").textContent = tr.p1;
      document.getElementById("p2Name").textContent = tr.fighters[g.foe] + (tr.titles[g.foe] ? " · " + tr.titles[g.foe] : "");
      document.getElementById("p1Hp").style.width = (100 * g.p1.hp / g.p1.maxHp) + "%";
      document.getElementById("p2Hp").style.width = (100 * g.p2.hp / g.p2.maxHp) + "%";
      document.getElementById("p1Meter").style.width = g.p1.meter + "%";
      document.getElementById("p2Meter").style.width = g.p2.meter + "%";
      document.getElementById("hudTimer").textContent = String(Math.ceil(g.time)).padStart(2, "0");
      document.getElementById("hudRounds").textContent = "●".repeat(g.wins.p1) + "○".repeat(Math.max(0, WINS_NEED - g.wins.p1)) + "  " + "○".repeat(Math.max(0, WINS_NEED - g.wins.p2)) + "●".repeat(g.wins.p2);
      const ann = document.getElementById("hudAnnounce");
      if (g.announce === "ROUND") ann.textContent = tr.round + " " + g.round;
      else if (g.announce === "FIGHT") ann.textContent = tr.fight;
      else if (g.announce === "KO") ann.textContent = tr.ko;
      else if (g.announce === "TIME") ann.textContent = tr.timeUp;
      else ann.textContent = "";
      ann.classList.toggle("show", !!g.announce);
    }

    function worldX(x) { return (x - camX) * scale() + view.w / 2; }
    function scale() {
      if (!g) return 1.4;
      const dist = Math.abs(g.p1.x - g.p2.x);
      const sH = (view.h * 0.5) / 168;
      const sW = view.w / Math.max(260, dist + 200);
      return Math.max(1.25, Math.min(sH, sW * 1.05, 2.8));
    }
    function groundY() { return view.h * 0.72; }

    function draw() {
      const w = view.w, h = view.h;
      ctx.fillStyle = BLACK;
      ctx.fillRect(0, 0, w, h);
      if (!g) return;
      const mid = (g.p1.x + g.p2.x) / 2;
      camX += (mid - camX) * 0.16;
      const vis = view.w / (2 * scale());
      camX = Math.max(vis + 40, Math.min(STAGE_W - vis - 40, camX));
      ctx.save();
      if (g.shake) ctx.translate((Math.random() - 0.5) * g.shake, (Math.random() - 0.5) * g.shake * 0.6);
      drawStage();
      drawFighter(g.p2);
      drawFighter(g.p1);
      g.projectiles.forEach(drawProj);
      g.sparks.forEach(sp => {
        ctx.fillStyle = sp.col;
        ctx.globalAlpha = Math.max(0, sp.t * 5);
        const sx = worldX(sp.x + (sp.vx || 0) * (0.2 - sp.t));
        const sy = groundY() - sp.y * scale() - 70 * scale();
        ctx.beginPath();
        ctx.arc(sx, sy, (4 + (0.2 - sp.t) * 28) * scale(), 0, 6.28);
        ctx.fill();
        ctx.globalAlpha = 1;
      });
      ctx.restore();
    }

    function drawStage() {
      const gy = groundY();
      const img = SPRITES.stage;
      if (img && img.complete && img.naturalWidth) {
        const parallax = (camX - STAGE_W / 2) * 0.22;
        const destH = view.h;
        const destW = destH * (img.naturalWidth / img.naturalHeight) * 1.12;
        ctx.drawImage(img, view.w / 2 - destW / 2 - parallax, 0, destW, destH);
        ctx.fillStyle = "rgba(10,11,16,0.16)";
        ctx.fillRect(0, 0, view.w, view.h);
      } else {
        const s = scale();
        ctx.fillStyle = "#10141e";
        ctx.fillRect(0, 0, view.w, gy);
        ctx.fillStyle = "#0e1016";
        ctx.fillRect(0, gy, view.w, view.h - gy);
      }
      ctx.fillStyle = "rgba(245,208,49,0.2)";
      ctx.fillRect(0, gy, view.w, 3);
    }

    function atkPhase(f) {
      if (!f.move) return { wind: 0, hit: 0 };
      const fr = f.stateT * 60;
      const a = Math.max(1, f.move.start);
      const b = f.move.start + f.move.active;
      const tot = f.move.frames;
      if (fr < a) return { wind: fr / a, hit: 0 };
      if (fr < b) return { wind: 0, hit: 1 };
      return { wind: 0, hit: Math.max(0, 1 - (fr - b) / Math.max(1, tot - b)) };
    }
    function poseKey(f) {
      if (f.state === "ko" || f.state === "hit") return "hit";
      if (f.state === "walk" || f.state === "jump" || f.airborne) return "walk";
      if (f.state === "attack" && f.move) {
        const ph = atkPhase(f);
        if (ph.wind > 0.62) return "idle";
        if (f.move.kind === "kick") return "kick";
        return "punch";
      }
      return "idle";
    }
    function poseImg(f) {
      const key = poseKey(f);
      const a = SPRITES[f.kit + "-" + key];
      if (a && a.complete && a.naturalWidth) return a;
      const b = SPRITES[f.kit + "-idle"];
      if (b && b.complete && b.naturalWidth) return b;
      return SPRITES[f.kit];
    }

    function drawFighter(f) {
      const s = scale();
      const img = poseImg(f);
      const x = worldX(f.x);
      const feetY = groundY() - f.y * s;
      const ph = atkPhase(f);
      let lunge = 0;
      if (f.state === "attack") lunge = 4 + ph.hit * 16;
      if (f.state === "hit") lunge = -12;
      if (f.state === "ko") lunge = -6;
      const bob = f.state === "idle" ? Math.sin(f.stateT * 6) * 2 * s
        : f.state === "walk" ? Math.abs(Math.sin(f.stateT * 10)) * 3.5 * s : 0;
      const h = f.h * s * 1.48;
      const ready = img && img.complete && img.naturalWidth;
      const w = ready ? h * (img.naturalWidth / img.naturalHeight) : 56 * s;
      ctx.save();
      ctx.translate(x + f.face * lunge * s, feetY);
      ctx.scale(f.face, 1);
      ctx.fillStyle = "rgba(0,0,0,0.42)";
      ctx.beginPath(); ctx.ellipse(0, 5 * s, Math.min(48 * s, w * 0.28), 9 * s, 0, 0, 6.28); ctx.fill();
      if (f.state === "attack" && ph.hit > 0.25 && ready) {
        ctx.globalAlpha = 0.26;
        ctx.drawImage(img, -w * 0.44 - 16 * s, -h - bob, w, h);
        ctx.globalAlpha = 1;
      }
      if (f.flash > 0) ctx.filter = "brightness(2.2) saturate(0.25)";
      if (f.state === "ko") ctx.rotate(0.48);
      else if (f.state === "crouch" || (f.state === "block" && f.input.d)) ctx.translate(0, 14 * s);
      if (ready) ctx.drawImage(img, -w * 0.42, -h - bob, w, h);
      else {
        ctx.fillStyle = KITS[f.kit].color;
        ctx.fillRect(-28 * s, -h, 56 * s, h);
      }
      if (f.state === "block") {
        ctx.fillStyle = "rgba(30,76,255,0.16)";
        ctx.beginPath();
        ctx.ellipse(0, -h * 0.48, w * 0.34, h * 0.5, 0, 0, 6.28);
        ctx.fill();
      }
      ctx.filter = "none";
      ctx.restore();
    }

    function drawProj(p) {
      const s = scale();
      const x = worldX(p.x);
      const y = groundY() - (p.y) * s + 40 * s;
      ctx.save();
      ctx.translate(x, y);
      ctx.fillStyle = YELLOW;
      ctx.shadowColor = COBALT;
      ctx.shadowBlur = 12;
      if (p.kind === "clock") { ctx.beginPath(); ctx.arc(0, 0, 14 * s, 0, 6.28); ctx.fill(); }
      else ctx.fillRect(-p.w * 0.4 * s, -p.h * 0.4 * s, p.w * 0.8 * s, p.h * 0.8 * s);
      ctx.restore();
      ctx.shadowBlur = 0;
    }

    function bindPad(id, key) {
      const el = document.getElementById(id);
      const down = e => { e.preventDefault(); pad[key] = 1; if (A) A.unlock(); };
      const up = e => { e.preventDefault(); pad[key] = 0; };
      el.addEventListener("pointerdown", down);
      el.addEventListener("pointerup", up);
      el.addEventListener("pointerleave", up);
      el.addEventListener("pointercancel", up);
    }
    ["padL:l", "padR:r", "padU:u", "padD:d", "btnP:p", "btnK:k", "btnS:s"].forEach(pair => {
      const [id, key] = pair.split(":");
      bindPad(id, key);
    });

    window.addEventListener("keydown", e => {
      keys[e.code] = true;
      if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space"].indexOf(e.code) >= 0) e.preventDefault();
      if (e.code === "Escape" && g && g.mode === "fight") { g.mode = "pause"; show("pauseOv", true); }
    });
    window.addEventListener("keyup", e => { keys[e.code] = false; });

    document.getElementById("langDock").addEventListener("click", e => {
      const b = e.target.closest("[data-lang]");
      if (!b) return;
      lang = b.getAttribute("data-lang");
      localStorage.setItem("bm_lang", lang);
      syncLang();
      tel("language_selected", { language: lang });
    });
    document.getElementById("btnDaily").onclick = startArcade;
    document.getElementById("btnPractice").onclick = startVersus;
    document.getElementById("storyGo").onclick = () => {
      show("storyOv", false);
      const ch = (t().story || [])[pendingChapter] || {};
      if (ch.ending) {
        if (g) endToResults();
        else show("homeOv", true);
      } else startChapterFight(Math.min(pendingChapter, LADDER.length - 1));
    };
    document.getElementById("btnHow").onclick = () => show("howOv", true);
    document.getElementById("howGo").onclick = () => show("howOv", false);
    document.getElementById("howOv").addEventListener("click", e => { if (e.target.id === "howOv") show("howOv", false); });
    document.getElementById("btnSettings").onclick = () => { syncSettings(); show("setOv", true); };
    document.getElementById("setClose").onclick = () => show("setOv", false);
    document.getElementById("setRows").addEventListener("click", e => {
      const b = e.target.closest("[data-set]");
      if (!b) return;
      const id = b.getAttribute("data-set");
      settings[id] = !settings[id];
      localStorage.setItem("bm_" + id, settings[id] ? "1" : "0");
      if (A) { A.setSfx(settings.sfx); A.setMusic(settings.music); }
      if (g && id === "motion") g.reducedMotion = reducedPref || !settings.motion;
      syncSettings();
    });
    document.getElementById("btnPause").onclick = () => { if (g && g.mode === "fight") { g.mode = "pause"; show("pauseOv", true); } };
    document.getElementById("btnResume").onclick = () => { if (g) { g.mode = "fight"; show("pauseOv", false); last = performance.now(); } };
    document.getElementById("btnQuit").onclick = () => {
      if (!g) return;
      g.verdict = "death"; g.mode = "results"; show("pauseOv", false); endToResults();
    };
    document.getElementById("btnShare").onclick = () => {
      const tr = t(); const s = summarize(g);
      const fn = s.verdict === "heroic" ? tr.shareHeroic : tr.shareDeath;
      const txt = fn(tr.fighters[s.foe], s.rounds);
      if (navigator.share) navigator.share({ text: txt }).catch(() => {});
      else { navigator.clipboard.writeText(txt).catch(() => {}); alert(tr.copied); }
      tel("result_shared", s);
    };
    document.getElementById("btnAgain").onclick = () => { if (g && g.arcade) startArcade(); else startVersus(); };
    document.getElementById("btnHome").onclick = () => {
      show("resultsOv", false); show("homeOv", true);
      document.getElementById("hud").classList.remove("on");
      g = null;
    };

    let fbScore = 0;
    document.getElementById("btnDebrief").onclick = () => {
      const tr = t();
      fbScore = 0;
      document.getElementById("fbQ").textContent = tr.debriefQ;
      document.getElementById("fbNote").placeholder = tr.debriefPh;
      document.getElementById("fbNote").value = "";
      document.getElementById("fbSend").textContent = tr.debriefSend;
      document.getElementById("fbSend").disabled = true;
      document.getElementById("fbEmos").innerHTML = [["😍", 3], ["😐", 2], ["😫", 1]].map(([e, s]) => '<button class="emo" data-s="' + s + '">' + e + "</button>").join("");
      show("fbOv", true);
    };
    document.getElementById("fbClose").onclick = () => show("fbOv", false);
    document.getElementById("fbEmos").addEventListener("click", e => {
      const b = e.target.closest("[data-s]"); if (!b) return;
      fbScore = +b.getAttribute("data-s");
      document.querySelectorAll("#fbEmos .emo").forEach(el => el.classList.toggle("on", el === b));
      document.getElementById("fbSend").disabled = false;
    });
    document.getElementById("fbSend").onclick = () => {
      if (root.TEL) root.TEL.feedback(fbScore, document.getElementById("fbNote").value);
      document.getElementById("fbQ").textContent = t().debriefDone;
      setTimeout(() => show("fbOv", false), 1100);
    };

    window.addEventListener("resize", resize);
    resize();
    syncLang();
    show("homeOv", true);
    if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
  }

  const BM = {
    LADDER, KITS, STAGE_W, ROUND_TIME,
    mulberry32, dateSeed, aabb, createMatch, update, simulateMatch, summarize,
    hurtBox, hitBox, makeFighter, boot
  };
  root.BM = BM;
  if (typeof module !== "undefined" && module.exports) module.exports = BM;
})(typeof window !== "undefined" ? window : globalThis);

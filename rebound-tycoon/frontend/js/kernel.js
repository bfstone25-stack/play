(function (root) {
  "use strict";

  const REBOUND = {
    SAVE_VERSION: 2,
    GRAVITY: 1.35,
    DAMP: 0.996,
    MAX_SPEED: 2.6,
    BALL_R: 0.017,
    FLIP_LEN: 0.155,
    FLIP_R: 0.016,
    BALLS: 3,
    COMBO_WINDOW_S: 2.2,
    COMBO_CAP: 8,
    COMBO_STEP: 0.12,
    PRESTIGE_MIN_ERA: 1,
    PRESTIGE_COIN_DIV: 4000,
    SUBSTEPS: 4,
  };

  const TABLE = {
    left: 0.075,
    right: 0.855,
    top: 0.055,
    bottom: 0.965,
    laneL: 0.875,
    laneR: 0.955,
    drainL: 0.40,
    drainR: 0.60,
  };

  const LEFT_PIVOT = { x: 0.255, y: 0.865 };
  const RIGHT_PIVOT = { x: 0.675, y: 0.865 };
  const LEFT_REST = 0.42;
  const LEFT_UP = -0.70;
  const RIGHT_REST = Math.PI - 0.42;
  const RIGHT_UP = Math.PI + 0.70;

  const BUMPERS = [
    { id: "courier", x: 0.34, y: 0.30, r: 0.048, score: 90 },
    { id: "party", x: 0.58, y: 0.30, r: 0.048, score: 90 },
    { id: "raccoon", x: 0.46, y: 0.44, r: 0.052, score: 120 },
  ];

  const TARGETS = [
    { id: "booth", x: 0.28, y: 0.155, w: 0.07, h: 0.028, score: 180 },
    { id: "lobby", x: 0.46, y: 0.125, w: 0.07, h: 0.028, score: 180 },
    { id: "tower", x: 0.64, y: 0.155, w: 0.07, h: 0.028, score: 180 },
  ];

  const SAUCER = { x: 0.46, y: 0.58, r: 0.028, score: 500 };

  const WALLS = [
    [0.075, 0.16, 0.075, 0.78],
    [0.075, 0.16, 0.38, 0.055],
    [0.38, 0.055, 0.70, 0.055],
    [0.70, 0.055, 0.82, 0.12],
    [0.855, 0.28, 0.855, 0.70],
    [0.075, 0.78, 0.230, 0.875],
    [0.700, 0.875, 0.855, 0.70],
    [0.875, 0.30, 0.875, 0.90],
    [0.955, 0.05, 0.955, 0.90],
    [0.855, 0.90, 0.955, 0.90],
    [0.82, 0.12, 0.70, 0.055],
    [0.18, 0.62, 0.075, 0.52],
    [0.75, 0.62, 0.855, 0.52],
  ];

  const SLINGS = [
    { ax: 0.16, ay: 0.70, bx: 0.27, by: 0.80, kick: 1.15 },
    { ax: 0.77, ay: 0.70, bx: 0.66, by: 0.80, kick: 1.15 },
  ];

  const ERAS = [
    { id: "booth", minScore: 0, mult: 1 },
    { id: "lobby", minScore: 4, mult: 1.15 },
    { id: "towers", minScore: 14, mult: 1.35 },
    { id: "neon", minScore: 32, mult: 1.6 },
  ];

  const UPGRADES = [
    { id: "springs", group: "table", baseCost: 40, growth: 1.22, skyline: 0 },
    { id: "flippers", group: "table", baseCost: 55, growth: 1.24, skyline: 0 },
    { id: "bumpers", group: "table", baseCost: 70, growth: 1.23, skyline: 0 },
    { id: "slings", group: "table", baseCost: 45, growth: 1.22, skyline: 0 },
    { id: "doorman", group: "staff", baseCost: 80, growth: 1.2, skyline: 0 },
    { id: "concierge", group: "staff", baseCost: 110, growth: 1.22, skyline: 0 },
    { id: "manager", group: "staff", baseCost: 160, growth: 1.25, skyline: 1 },
    { id: "studio", group: "property", baseCost: 90, growth: 1.18, skyline: 2 },
    { id: "loft", group: "property", baseCost: 180, growth: 1.2, skyline: 4 },
    { id: "penthouse", group: "property", baseCost: 320, growth: 1.22, skyline: 8 },
    { id: "cannon", group: "table", baseCost: 140, growth: 1.26, skyline: 1 },
    { id: "neon", group: "amenity", baseCost: 240, growth: 1.24, skyline: 3 },
  ];

  const PERKS = [
    { id: "uniform", tokenBase: 1, tokenGrowth: 1.6, income: 0.08 },
    { id: "legend", tokenBase: 1, tokenGrowth: 1.7, cannon: 0.12 },
    { id: "switchboard", tokenBase: 1, tokenGrowth: 1.65, spawn: 0.08 },
    { id: "empire", tokenBase: 1, tokenGrowth: 1.75, idle: 0.12 },
  ];

  const byId = (list) => {
    const map = {};
    list.forEach((item) => { map[item.id] = item; });
    return map;
  };
  const UPGRADE_BY_ID = byId(UPGRADES);
  const PERK_BY_ID = byId(PERKS);

  function emptyOwned() {
    const owned = {};
    UPGRADES.forEach((u) => { owned[u.id] = 0; });
    return owned;
  }
  function emptyPerks() {
    const perks = {};
    PERKS.forEach((p) => { perks[p.id] = 0; });
    return perks;
  }
  function clone(obj) {
    return JSON.parse(JSON.stringify(obj));
  }

  function freshBall() {
    return {
      x: 0.915,
      y: 0.82,
      vx: 0,
      vy: 0,
    };
  }

  function newState() {
    return {
      version: REBOUND.SAVE_VERSION,
      coins: 0,
      score: 0,
      owned: emptyOwned(),
      perks: emptyPerks(),
      tokens: 0,
      combo: 0,
      comboLeft: 0,
      balls: REBOUND.BALLS,
      night: 1,
      prestiges: 0,
      lifetime: 0,
      runCoins: 0,
      rebounds: 0,
      buys: 0,
      mode: "plunge",
      plunge: 0,
      flipL: LEFT_REST,
      flipR: RIGHT_REST,
      flipLv: 0,
      flipRv: 0,
      ball: freshBall(),
      bumperFlash: [0, 0, 0],
      targetDown: [false, false, false],
      saucerHold: 0,
      ballSave: 0,
      inPlay: false,
      savedAt: 0,
    };
  }

  function hydrate(raw) {
    const state = newState();
    if (!raw || typeof raw !== "object" || (raw.version | 0) !== REBOUND.SAVE_VERSION) return state;
    state.coins = Math.max(0, Number(raw.coins) || 0);
    state.score = Math.max(0, Number(raw.score) || 0);
    state.tokens = Math.max(0, Number(raw.tokens) || 0);
    state.combo = Math.max(0, Number(raw.combo) || 0);
    state.comboLeft = Math.max(0, Number(raw.comboLeft) || 0);
    state.balls = Math.max(0, Number(raw.balls) || 0);
    state.night = Math.max(1, Number(raw.night) || 1);
    state.prestiges = Math.max(0, Number(raw.prestiges) || 0);
    state.lifetime = Math.max(0, Number(raw.lifetime) || 0);
    state.runCoins = Math.max(0, Number(raw.runCoins) || 0);
    state.rebounds = Math.max(0, Number(raw.rebounds) || 0);
    state.buys = Math.max(0, Number(raw.buys) || 0);
    state.mode = raw.mode === "live" || raw.mode === "nightover" ? raw.mode : "plunge";
    state.plunge = Math.min(1, Math.max(0, Number(raw.plunge) || 0));
    state.inPlay = !!raw.inPlay;
    UPGRADES.forEach((u) => { state.owned[u.id] = Math.max(0, (raw.owned && raw.owned[u.id]) | 0); });
    PERKS.forEach((p) => { state.perks[p.id] = Math.max(0, (raw.perks && raw.perks[p.id]) | 0); });
    if (raw.ball) {
      state.ball = {
        x: Number(raw.ball.x) || 0.915,
        y: Number(raw.ball.y) || 0.82,
        vx: Number(raw.ball.vx) || 0,
        vy: Number(raw.ball.vy) || 0,
      };
    }
    if (state.mode === "live" && state.ball && !state.inPlay && state.ball.x > 0.86) {
      state.mode = "plunge";
      state.plunge = 0;
      state.ball = freshBall();
    }
    if (state.mode === "nightover") state.ball = null;
    return state;
  }

  function snapshot(state) {
    const out = clone(state);
    out.version = REBOUND.SAVE_VERSION;
    out.savedAt = Date.now();
    return out;
  }

  function levelOf(state, id) { return (state && state.owned && state.owned[id]) | 0; }
  function perkOf(state, id) { return (state && state.perks && state.perks[id]) | 0; }
  function upgradeById(id) { return UPGRADE_BY_ID[id] || null; }
  function perkById(id) { return PERK_BY_ID[id] || null; }
  function scaleCost(base, growth, level) { return Math.floor(base * Math.pow(growth, Math.max(0, level | 0))); }
  function upgradeCost(id, level) {
    const u = UPGRADE_BY_ID[id];
    return u ? scaleCost(u.baseCost, u.growth, level) : Infinity;
  }
  function perkCost(id, level) {
    const p = PERK_BY_ID[id];
    return p ? Math.max(1, Math.floor(p.tokenBase * Math.pow(p.tokenGrowth, Math.max(0, level | 0)))) : Infinity;
  }
  function skylineScore(state) {
    let score = 0;
    UPGRADES.forEach((u) => { score += levelOf(state, u.id) * (u.skyline || 0); });
    return score;
  }
  function eraIndex(state) {
    const score = skylineScore(state);
    let idx = 0;
    for (let i = 0; i < ERAS.length; i++) if (score >= ERAS[i].minScore) idx = i;
    return idx;
  }
  function eraId(state) { return ERAS[eraIndex(state)].id; }
  function eraMult(state) { return ERAS[eraIndex(state)].mult; }
  function prestigeMult(state) { return 1 + perkOf(state, "uniform") * 0.08 + perkOf(state, "empire") * 0.12; }
  function scoreMult(state) {
    const studio = 1 + levelOf(state, "studio") * 0.08;
    const loft = 1 + levelOf(state, "loft") * 0.1;
    const pent = 1 + levelOf(state, "penthouse") * 0.12;
    const neon = 1 + levelOf(state, "neon") * 0.1;
    const concierge = 1 + levelOf(state, "concierge") * 0.06;
    return studio * loft * pent * neon * concierge * eraMult(state) * prestigeMult(state);
  }
  function comboMult(combo) { return 1 + Math.min(REBOUND.COMBO_CAP, Math.max(0, combo | 0)) * REBOUND.COMBO_STEP; }
  function flipPower(state) { return 10 + levelOf(state, "flippers") * 2.2; }
  function bumperKick(state) { return 0.55 + levelOf(state, "bumpers") * 0.12; }
  function slingKick(state) { return 0.85 + levelOf(state, "slings") * 0.15; }
  function plungePower(state) { return 1.7 + levelOf(state, "springs") * 0.22; }
  function cannonKick(state) { return 1.5 + levelOf(state, "cannon") * 0.25 + perkOf(state, "legend") * 0.2; }
  function startBalls(state) { return REBOUND.BALLS + (levelOf(state, "manager") > 0 ? 1 : 0); }
  function saveTime(state) { return levelOf(state, "doorman") * 1.4; }

  function award(state, base) {
    const pts = Math.floor(base * scoreMult(state) * comboMult(state.combo));
    state.score += pts;
    const coins = Math.max(1, Math.floor(pts / 12));
    state.coins += coins;
    state.lifetime += coins;
    state.runCoins += coins;
    state.combo = Math.min(REBOUND.COMBO_CAP, state.combo + 1);
    state.comboLeft = REBOUND.COMBO_WINDOW_S;
    state.rebounds += 1;
    return pts;
  }

  function clampBall(ball) {
    const sp = Math.hypot(ball.vx, ball.vy);
    if (sp > REBOUND.MAX_SPEED) {
      ball.vx *= REBOUND.MAX_SPEED / sp;
      ball.vy *= REBOUND.MAX_SPEED / sp;
    }
  }

  function hitWall(ball, ax, ay, bx, by, bounce) {
    const abx = bx - ax, aby = by - ay;
    const apx = ball.x - ax, apy = ball.y - ay;
    const ab2 = abx * abx + aby * aby || 1;
    let t = (apx * abx + apy * aby) / ab2;
    t = Math.max(0, Math.min(1, t));
    const cx = ax + abx * t, cy = ay + aby * t;
    const dx = ball.x - cx, dy = ball.y - cy;
    const dist = Math.hypot(dx, dy);
    if (dist >= REBOUND.BALL_R || dist < 1e-8) return false;
    const nx = dx / dist, ny = dy / dist;
    ball.x = cx + nx * REBOUND.BALL_R;
    ball.y = cy + ny * REBOUND.BALL_R;
    const vn = ball.vx * nx + ball.vy * ny;
    if (vn < 0) {
      ball.vx -= (1 + bounce) * vn * nx;
      ball.vy -= (1 + bounce) * vn * ny;
    }
    return true;
  }

  function hitCircle(ball, cx, cy, cr, kick) {
    const dx = ball.x - cx, dy = ball.y - cy;
    const dist = Math.hypot(dx, dy);
    const min = REBOUND.BALL_R + cr;
    if (dist >= min) return false;
    const nx = dist < 1e-8 ? 0 : dx / dist;
    const ny = dist < 1e-8 ? -1 : dy / dist;
    ball.x = cx + nx * min;
    ball.y = cy + ny * min;
    const vn = ball.vx * nx + ball.vy * ny;
    if (vn < 0) {
      ball.vx -= 1.85 * vn * nx;
      ball.vy -= 1.85 * vn * ny;
    }
    ball.vx += nx * kick;
    ball.vy += ny * kick;
    return true;
  }

  function flipperEnd(pivot, angle) {
    return {
      x: pivot.x + Math.cos(angle) * REBOUND.FLIP_LEN,
      y: pivot.y + Math.sin(angle) * REBOUND.FLIP_LEN,
    };
  }

  function hitFlipper(ball, pivot, angle, omega, power) {
    const tip = flipperEnd(pivot, angle);
    const hit = hitWall(ball, pivot.x, pivot.y, tip.x, tip.y, 0.25);
    if (!hit) return false;
    const rx = ball.x - pivot.x, ry = ball.y - pivot.y;
    const fx = -omega * ry, fy = omega * rx;
    ball.vx += fx * 0.35 + Math.cos(angle - Math.PI / 2) * Math.max(0, omega) * power * 0.012;
    ball.vy += fy * 0.35 + Math.sin(angle - Math.PI / 2) * Math.max(0, -omega) * power * 0.012;
    if (omega !== 0) {
      const nx = Math.cos(angle - Math.PI / 2), ny = Math.sin(angle - Math.PI / 2);
      const sign = pivot === LEFT_PIVOT || pivot.x < 0.5 ? -1 : 1;
      ball.vx += nx * Math.abs(omega) * 0.08 * sign;
      ball.vy += ny * Math.abs(omega) * 0.08;
    }
    return true;
  }

  function hitTarget(ball, t) {
    const x = Math.max(t.x, Math.min(t.x + t.w, ball.x));
    const y = Math.max(t.y, Math.min(t.y + t.h, ball.y));
    return Math.hypot(ball.x - x, ball.y - y) < REBOUND.BALL_R;
  }

  function launchBall(state, chargeOverride) {
    if (state.mode !== "plunge" || !state.ball) return 0;
    const charge = Math.max(0.55, chargeOverride != null ? chargeOverride : state.plunge);
    // Gravity is 1.35. A weak shot peaks before the lane exit at y≈0.36 and
    // dies in the hose, after which Space does nothing because mode is live.
    const minVy = 1.48;
    state.ball.x = 0.915;
    state.ball.y = 0.78;
    state.ball.vx = 0.04;
    state.ball.vy = -Math.max(minVy, plungePower(state) * charge);
    state.mode = "live";
    state.plunge = 0;
    state.inPlay = false;
    state.ballSave = saveTime(state);
    return charge;
  }

  function drainBall(state) {
    if (state.ballSave > 0 && state.ball) {
      state.ball.x = 0.46;
      state.ball.y = 0.72;
      state.ball.vx = 0;
      state.ball.vy = -0.9;
      state.ballSave = 0;
      return "save";
    }
    state.balls -= 1;
    state.combo = 0;
    state.comboLeft = 0;
    state.targetDown = [false, false, false];
    if (state.balls <= 0) {
      state.mode = "nightover";
      state.ball = null;
      return "nightover";
    }
    state.mode = "plunge";
    state.ball = freshBall();
    state.plunge = 0;
    state.inPlay = false;
    return "drain";
  }

  function newNight(state) {
    const next = clone(state);
    next.mode = "plunge";
    next.balls = startBalls(next);
    next.score = 0;
    next.combo = 0;
    next.comboLeft = 0;
    next.plunge = 0;
    next.ball = freshBall();
    next.inPlay = false;
    next.targetDown = [false, false, false];
    next.saucerHold = 0;
    next.night += 1;
    return next;
  }

  function step(state, input, dt) {
    const next = clone(state);
    const events = [];
    const seconds = Math.max(0, Math.min(0.05, Number(dt) || 0));
    if (next.comboLeft > 0) {
      next.comboLeft = Math.max(0, next.comboLeft - seconds);
      if (!next.comboLeft) next.combo = 0;
    }
    next.bumperFlash = next.bumperFlash.map((v) => Math.max(0, v - seconds * 4));
    if (next.ballSave > 0) next.ballSave = Math.max(0, next.ballSave - seconds);

    const speed = flipPower(next);
    const targetL = input.left ? LEFT_UP : LEFT_REST;
    const targetR = input.right ? RIGHT_UP : RIGHT_REST;
    const prevL = next.flipL, prevR = next.flipR;
    next.flipL += (targetL - next.flipL) * Math.min(1, seconds * speed);
    next.flipR += (targetR - next.flipR) * Math.min(1, seconds * speed);
    next.flipLv = seconds ? (next.flipL - prevL) / seconds : 0;
    next.flipRv = seconds ? (next.flipR - prevR) / seconds : 0;

    if (next.mode === "plunge") {
      if (!next.ball) next.ball = freshBall();
      next.ball.x = 0.915;
      next.ball.y = 0.82 - next.plunge * 0.08;
      next.ball.vx = 0;
      next.ball.vy = 0;
      if (input.fire) {
        const charge = launchBall(next, Math.max(next.plunge, 0.78));
        events.push({ type: "launch", charge });
        return { state: next, events };
      }
      if (input.plunge) {
        next.plunge = Math.min(1, next.plunge + seconds * 2.4);
        if (next.plunge >= 1) {
          events.push({ type: "launch", charge: launchBall(next, 1) });
        }
      } else if (next.plunge > 0.08) {
        events.push({ type: "launch", charge: launchBall(next) });
      } else next.plunge = 0;
      return { state: next, events };
    }

    if (next.mode !== "live" || !next.ball) return { state: next, events };

    if (next.saucerHold > 0) {
      next.saucerHold = Math.max(0, next.saucerHold - seconds);
      next.ball.x = SAUCER.x;
      next.ball.y = SAUCER.y;
      next.ball.vx = 0;
      next.ball.vy = 0;
      if (next.saucerHold === 0) {
        next.ball.vy = -cannonKick(next);
        next.ball.vx = (Math.random() - 0.5) * 0.3;
        events.push({ type: "cannon" });
      }
      return { state: next, events };
    }

    const h = seconds / REBOUND.SUBSTEPS;
    for (let i = 0; i < REBOUND.SUBSTEPS; i++) {
      next.ball.vy += REBOUND.GRAVITY * h;
      next.ball.vx *= Math.pow(REBOUND.DAMP, h * 60);
      next.ball.vy *= Math.pow(REBOUND.DAMP, h * 60);
      next.ball.x += next.ball.vx * h;
      next.ball.y += next.ball.vy * h;
      if (!next.inPlay && next.ball.x > 0.86 && next.ball.y < 0.40) {
        next.ball.vx = -1.7;
        next.ball.vy = Math.min(next.ball.vy, -0.2);
      }
      if (!next.inPlay && next.ball.x < 0.84 && next.ball.y < 0.50) {
        next.inPlay = true;
        next.ball.vx = Math.min(next.ball.vx, -0.85);
        if (next.ball.vy > 0.7) next.ball.vy = 0.55;
      }
      if (!next.inPlay && next.ball.x > 0.86 && next.ball.y > 0.86 && next.ball.vy >= 0) {
        next.mode = "plunge";
        next.plunge = 0;
        next.ball = freshBall();
        events.push({ type: "reload" });
        break;
      }
      if (next.inPlay) hitWall(next.ball, 0.86, 0.05, 0.86, 0.32, 0.2);
      clampBall(next.ball);

      WALLS.forEach((w) => hitWall(next.ball, w[0], w[1], w[2], w[3], 0.42));

      BUMPERS.forEach((b, idx) => {
        if (hitCircle(next.ball, b.x, b.y, b.r, bumperKick(next))) {
          next.bumperFlash[idx] = 1;
          const pts = award(next, b.score);
          events.push({ type: "bumper", i: idx, id: b.id, pts });
        }
      });

      SLINGS.forEach((s) => {
        if (hitWall(next.ball, s.ax, s.ay, s.bx, s.by, 0.1)) {
          const nx = s.bx - s.ax, ny = s.by - s.ay;
          const len = Math.hypot(nx, ny) || 1;
          const px = -ny / len, py = nx / len;
          const kick = slingKick(next);
          next.ball.vx += px * kick * (s.ax < 0.5 ? 1 : -1);
          next.ball.vy -= kick * 0.35;
          const pts = award(next, 25);
          events.push({ type: "sling", pts });
        }
      });

      TARGETS.forEach((t, idx) => {
        if (!next.targetDown[idx] && hitTarget(next.ball, t)) {
          next.targetDown[idx] = true;
          next.ball.vy = Math.abs(next.ball.vy) * 0.4 + 0.2;
          const pts = award(next, t.score);
          events.push({ type: "target", i: idx, id: t.id, pts });
        }
      });
      if (next.targetDown.every(Boolean)) {
        next.targetDown = [false, false, false];
        const pts = award(next, 800);
        events.push({ type: "gate", pts });
      }

      if (hitCircle(next.ball, SAUCER.x, SAUCER.y, SAUCER.r, 0) && Math.hypot(next.ball.vx, next.ball.vy) < 1.4) {
        next.saucerHold = 0.35;
        const pts = award(next, SAUCER.score);
        events.push({ type: "saucer", pts });
      }

      hitFlipper(next.ball, LEFT_PIVOT, next.flipL, next.flipLv, flipPower(next));
      hitFlipper(next.ball, RIGHT_PIVOT, next.flipR, next.flipRv, flipPower(next));

      if (next.ball.y > TABLE.bottom && next.ball.x > TABLE.drainL && next.ball.x < TABLE.drainR) {
        const kind = drainBall(next);
        events.push({ type: kind });
        break;
      }
      if (next.ball.y > 1.08 || next.ball.x < -0.05 || next.ball.x > 1.05) {
        const kind = drainBall(next);
        events.push({ type: kind });
        break;
      }
    }

    return { state: next, events };
  }

  function canBuy(state, id) {
    return !!UPGRADE_BY_ID[id] && state.coins + 1e-9 >= upgradeCost(id, levelOf(state, id));
  }
  function buy(state, id) {
    if (!canBuy(state, id)) return { ok: false, state: clone(state), spent: 0 };
    const cost = upgradeCost(id, levelOf(state, id));
    const next = clone(state);
    next.coins -= cost;
    next.owned[id] = levelOf(state, id) + 1;
    next.buys += 1;
    return { ok: true, state: next, spent: cost };
  }
  function canBuyPerk(state, id) {
    return !!PERK_BY_ID[id] && state.tokens >= perkCost(id, perkOf(state, id));
  }
  function buyPerk(state, id) {
    if (!canBuyPerk(state, id)) return { ok: false, state: clone(state), spent: 0 };
    const cost = perkCost(id, perkOf(state, id));
    const next = clone(state);
    next.tokens -= cost;
    next.perks[id] = perkOf(state, id) + 1;
    return { ok: true, state: next, spent: cost };
  }
  function prestigeTokensFor(state) {
    if (eraIndex(state) < REBOUND.PRESTIGE_MIN_ERA) return 0;
    return Math.floor(Math.sqrt(Math.max(0, state.runCoins) / REBOUND.PRESTIGE_COIN_DIV));
  }
  function canPrestige(state) { return prestigeTokensFor(state) >= 1; }
  function doPrestige(state) {
    const tokens = prestigeTokensFor(state);
    if (tokens < 1) return { ok: false, state: clone(state), tokens: 0 };
    const next = newState();
    next.perks = clone(state.perks);
    next.tokens = (state.tokens | 0) + tokens;
    next.prestiges = (state.prestiges | 0) + 1;
    next.lifetime = state.lifetime;
    next.night = (state.night | 0) + 1;
    next.rebounds = state.rebounds;
    next.buys = state.buys;
    next.balls = startBalls(next);
    return { ok: true, state: next, tokens };
  }
  function formatCoins(n) {
    const v = Number(n) || 0;
    if (v >= 1e9) return (v / 1e9).toFixed(2) + "B";
    if (v >= 1e6) return (v / 1e6).toFixed(2) + "M";
    if (v >= 10000) return (v / 1000).toFixed(1) + "K";
    return Math.floor(v).toString();
  }

  const api = {
    REBOUND, TABLE, ERAS, UPGRADES, PERKS, BUMPERS, TARGETS, SAUCER, WALLS, SLINGS,
    LEFT_PIVOT, RIGHT_PIVOT, LEFT_REST, LEFT_UP, RIGHT_REST, RIGHT_UP,
    newState, hydrate, snapshot, clone, freshBall,
    levelOf, perkOf, upgradeById, perkById, upgradeCost, perkCost,
    skylineScore, eraIndex, eraId, eraMult, prestigeMult, scoreMult, comboMult,
    flipPower, bumperKick, plungePower, startBalls,
    launchBall, drainBall, newNight, step, award, flipperEnd, hitCircle, hitWall,
    canBuy, buy, canBuyPerk, buyPerk, prestigeTokensFor, canPrestige, doPrestige,
    formatCoins,
  };

  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else Object.assign(root, api);
})(typeof globalThis !== "undefined" ? globalThis : this);

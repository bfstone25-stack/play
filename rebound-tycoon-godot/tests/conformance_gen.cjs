// JS side of the JS<->GDScript conformance test.
//
//   node tests/conformance_gen.cjs        -> tests/conformance.json
//
// It requires the SHIPPED kernel — play/rebound-tycoon/frontend/js/kernel.js, untouched —
// and records what it does, so tests/run_tests.gd can run scripts/kernel.gd over the same
// inputs and assert every number, every string and every event is identical.
//
// Three blocks:
//   economy   280 seeded states (random owned levels, perks, coins, tokens, run coins):
//             every cost, multiplier, era, award, buy, perk buy, prestige, and the
//             formatted coin string. The strings matter: JS toFixed rounds ties away from
//             zero and C's "%.Nf" rounds to even, which is the trap the sibling documented
//             (play/overtime-idle-godot/tests/run_tests.gd).
//   physics   72 seeded runs: a fixed dt, a scripted input timeline recorded frame by
//             frame, Math.random replaced by the same LCG the GDScript side uses, and the
//             whole event sequence plus the ball's state after every frame.
//   offline   the gate's away math (play/catharsis/kernel/idle.js), over the same states.
const fs = require("fs");
const path = require("path");

const K = require("../../rebound-tycoon/frontend/js/kernel.js");
const IDLE_SRC = fs.readFileSync(path.join(__dirname, "../../catharsis/kernel/idle.js"), "utf8");
const IDLE = {};
new Function("exports", IDLE_SRC + "\n;exports.idleRate=idleRate;exports.offlineSeconds=offlineSeconds;exports.offlineEarn=offlineEarn;")(IDLE);

// The one shared RNG. GDScript reimplements exactly this in tests/run_tests.gd.
function lcg(seed) {
  let s = seed >>> 0;
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
}

const UPG = K.UPGRADES.map((u) => u.id);
const PERK = K.PERKS.map((p) => p.id);

// ---- block 1: the economy ------------------------------------------------------------
const economy = [];
for (let i = 0; i < 280; i++) {
  const r = lcg(9000 + i);
  const st = K.newState();
  UPG.forEach((id) => { if (r() < 0.65) st.owned[id] = Math.floor(r() * 14); });
  PERK.forEach((id) => { if (r() < 0.5) st.perks[id] = Math.floor(r() * 7); });
  st.coins = Math.floor(r() * 2_000_000);
  st.tokens = Math.floor(r() * 40);
  st.runCoins = Math.floor(r() * 900_000);
  st.combo = Math.floor(r() * 11);
  st.lifetime = Math.floor(r() * 5_000_000_000);

  const costs = {}, perkCosts = {};
  UPG.forEach((id) => { costs[id] = K.upgradeCost(id, K.levelOf(st, id)); });
  PERK.forEach((id) => { perkCosts[id] = K.perkCost(id, K.perkOf(st, id)); });

  const buyId = UPG[Math.floor(r() * UPG.length)];
  const bought = K.buy(st, buyId);
  const perkId = PERK[Math.floor(r() * PERK.length)];
  const perkBought = K.buyPerk(st, perkId);

  const awarded = K.clone(st);
  const awardBase = [25, 90, 120, 180, 500, 800][Math.floor(r() * 6)];
  const pts = K.award(awarded, awardBase);

  const pres = K.doPrestige(st);

  economy.push({
    owned: st.owned, perks: st.perks, coins: st.coins, tokens: st.tokens,
    runCoins: st.runCoins, combo: st.combo, lifetime: st.lifetime,
    costs, perkCosts,
    skyline: K.skylineScore(st), eraIndex: K.eraIndex(st), eraId: K.eraId(st),
    eraMult: K.eraMult(st), prestigeMult: K.prestigeMult(st), scoreMult: K.scoreMult(st),
    comboMult: K.comboMult(st.combo),
    flipPower: K.flipPower(st), bumperKick: K.bumperKick(st), plungePower: K.plungePower(st),
    startBalls: K.startBalls(st),
    buyId, buyOk: bought.ok, buySpent: bought.spent,
    buyCoins: bought.state.coins, buyLevel: bought.state.owned[buyId],
    perkId, perkOk: perkBought.ok, perkSpent: perkBought.spent,
    perkTokens: perkBought.state.tokens, perkLevel: perkBought.state.perks[perkId],
    awardBase, awardPts: pts, awardCoins: awarded.coins, awardScore: awarded.score, awardCombo: awarded.combo,
    prestigeTokens: K.prestigeTokensFor(st), canPrestige: K.canPrestige(st),
    prestigeOk: pres.ok, prestigeNight: pres.state.night, prestigeTokensAfter: pres.state.tokens,
    fmtCoins: K.formatCoins(st.coins), fmtLifetime: K.formatCoins(st.lifetime),
    fmtRun: K.formatCoins(st.runCoins),
  });
}

// ---- block 2: the physics ------------------------------------------------------------
// The kernel draws Math.random() exactly once, when the saucer spits the ball back out.
// Replace it for the whole block so both sides make the same draw in the same order.
const physics = [];
for (let i = 0; i < 72; i++) {
  const r = lcg(400 + i);
  const rand = lcg(77_000 + i);
  Math.random = rand;

  const st = K.newState();
  UPG.forEach((id) => { if (r() < 0.55) st.owned[id] = Math.floor(r() * 9); });
  PERK.forEach((id) => { if (r() < 0.4) st.perks[id] = Math.floor(r() * 4); });

  const dt = [1 / 60, 1 / 50, 1 / 30, 0.02][i % 4];
  const frames = 900;
  // A scripted thumb: hold the plunger for a bit, release, then flip on a rhythm that
  // varies per seed. Recorded literally, so the GDScript side replays the same timeline
  // rather than re-deriving it.
  // Packed one hex nibble per frame (bit 0 left, 1 right, 2 plunge, 3 fire) so the file
  // stays small; run_tests.gd unpacks the same way.
  const timeline = [];
  const holdFor = 6 + Math.floor(r() * 30);
  const lp = 7 + Math.floor(r() * 22);
  const rp = 7 + Math.floor(r() * 22);
  for (let f = 0; f < frames; f++) {
    timeline.push({
      left: f > holdFor + 2 && f % lp < Math.max(2, lp >> 2),
      right: f > holdFor + 2 && (f + (lp >> 1)) % rp < Math.max(2, rp >> 2),
      plunge: f < holdFor,
      fire: f === holdFor,
    });
  }

  let s = st;
  const events = [];
  const trace = [];
  for (let f = 0; f < frames; f++) {
    const out = K.step(s, timeline[f], dt);
    s = out.state;
    out.events.forEach((e) => events.push({ f, ...e }));
    // every 25th frame, the full physical state — enough to localise a divergence
    if (f % 25 === 0) {
      trace.push(s.ball
        ? { f, x: s.ball.x, y: s.ball.y, vx: s.ball.vx, vy: s.ball.vy, fl: s.flipL, fr: s.flipR,
            mode: s.mode, coins: s.coins, score: s.score, combo: s.combo, balls: s.balls, inPlay: s.inPlay }
        : { f, x: null, y: null, vx: null, vy: null, fl: s.flipL, fr: s.flipR,
            mode: s.mode, coins: s.coins, score: s.score, combo: s.combo, balls: s.balls, inPlay: s.inPlay });
    }
  }
  const packed = timeline.map((k) =>
    ((k.left ? 1 : 0) | (k.right ? 2 : 0) | (k.plunge ? 4 : 0) | (k.fire ? 8 : 0)).toString(16)).join("");
  physics.push({
    seed: 400 + i, randSeed: 77_000 + i, dt, frames, timeline: packed,
    owned: st.owned, perks: st.perks,
    events, trace,
    end: { mode: s.mode, coins: s.coins, score: s.score, balls: s.balls, night: s.night,
      combo: s.combo, rebounds: s.rebounds, lifetime: s.lifetime, runCoins: s.runCoins,
      ball: s.ball ? { x: s.ball.x, y: s.ball.y, vx: s.ball.vx, vy: s.ball.vy } : null,
      flipL: s.flipL, flipR: s.flipR, targetDown: s.targetDown, saucerHold: s.saucerHold,
      ballSave: s.ballSave, inPlay: s.inPlay },
  });
}

// ---- block 3: the offline gate ---------------------------------------------------------
// The Godot build adds what PLAN.md wave 4 asks for and the JS never got. The *math* is
// play/catharsis/kernel/idle.js, so the numbers are pinned against that file, using the
// same mapping scripts/idle.gd documents: level = era index + 1, and the property
// upgrades as buildings at a tenth of their score multiplier.
const BUILDING_RATE = { studio: 0.8, loft: 1.0, penthouse: 1.2, neon: 1.0 };
const offline = [];
for (let i = 0; i < 160; i++) {
  const r = lcg(31_000 + i);
  const st = K.newState();
  UPG.forEach((id) => { if (r() < 0.6) st.owned[id] = Math.floor(r() * 12); });
  PERK.forEach((id) => { if (r() < 0.5) st.perks[id] = Math.floor(r() * 6); });
  const buildings = Object.keys(BUILDING_RATE).map((id) => ({ count: st.owned[id], rate: BUILDING_RATE[id] }));
  const base = IDLE.idleRate(K.eraIndex(st) + 1, buildings);
  const rate = base * (1 + K.perkOf(st, "empire") * 0.12);
  const last = 1_800_000_000_000 + Math.floor(r() * 1e9);
  const away = [0, 1000, 59_000, 3_600_000, 8 * 3600e3 - 1, 8 * 3600e3, 30 * 3600e3][i % 7];
  const now = last + away;
  offline.push({
    owned: st.owned, perks: st.perks, eraIndex: K.eraIndex(st),
    base, rate, last, now, away,
    seconds: IDLE.offlineSeconds(last, now, 8),
    earn: IDLE.offlineEarn(last, now, rate, 8),
    backwards: IDLE.offlineEarn(now, last, rate, 8),
    coldStart: IDLE.offlineEarn(0, now, rate, 8),
  });
}

// ---- block 4: the constants themselves ---------------------------------------------------
// Every number the kernel is BUILT from, not only the ones it computes. This block exists
// because two of the three real bugs in the port were constants, not code: Godot's
// Vector2 holds 32-bit floats (the flipper pivots quietly lost nine digits), and Godot's
// decimal parser is not correctly rounded. A table that is a quarter of a micron off is a
// game that plays almost the same, which is the kind of wrong nothing else catches.
const constants = {
  GRAVITY: K.REBOUND.GRAVITY, DAMP: K.REBOUND.DAMP, MAX_SPEED: K.REBOUND.MAX_SPEED,
  BALL_R: K.REBOUND.BALL_R, FLIP_LEN: K.REBOUND.FLIP_LEN, FLIP_R: K.REBOUND.FLIP_R,
  COMBO_WINDOW_S: K.REBOUND.COMBO_WINDOW_S, COMBO_STEP: K.REBOUND.COMBO_STEP,
  LEFT_REST: K.LEFT_REST, LEFT_UP: K.LEFT_UP, RIGHT_REST: K.RIGHT_REST, RIGHT_UP: K.RIGHT_UP,
  "LEFT_PIVOT.x": K.LEFT_PIVOT.x, "LEFT_PIVOT.y": K.LEFT_PIVOT.y,
  "RIGHT_PIVOT.x": K.RIGHT_PIVOT.x, "RIGHT_PIVOT.y": K.RIGHT_PIVOT.y,
  PI: Math.PI,
};
for (const k in K.TABLE) constants["TABLE." + k] = K.TABLE[k];
K.BUMPERS.forEach((b, i) => ["x", "y", "r"].forEach((k) => { constants[`BUMPERS.${i}.${k}`] = b[k]; }));
K.TARGETS.forEach((t, i) => ["x", "y", "w", "h"].forEach((k) => { constants[`TARGETS.${i}.${k}`] = t[k]; }));
["x", "y", "r"].forEach((k) => { constants["SAUCER." + k] = K.SAUCER[k]; });
K.WALLS.forEach((w, i) => w.forEach((v, j) => { constants[`WALLS.${i}.${j}`] = v; }));
K.SLINGS.forEach((s, i) => ["ax", "ay", "bx", "by", "kick"].forEach((k) => { constants[`SLINGS.${i}.${k}`] = s[k]; }));
K.ERAS.forEach((e, i) => { constants[`ERAS.${i}.mult`] = e.mult; });
K.UPGRADES.forEach((u, i) => { constants[`UPGRADES.${i}.growth`] = u.growth; });
K.PERKS.forEach((pk, i) => { constants[`PERKS.${i}.tokenGrowth`] = pk.tokenGrowth; });

// ---- transport --------------------------------------------------------------------------
// Godot's JSON number parser is NOT correctly rounded: it reads "19.349999999999998" as
// 19.350000000000001421, one ulp off, and String.to_float does the same. A conformance
// test that compares doubles exactly would then fail on the transport rather than on the
// port — and, worse, a test written with an epsilon would have passed while hiding it.
// So every non-integer double crosses as its IEEE-754 bit pattern ("f" + 8 bytes LE hex),
// which run_tests.gd decodes with PackedByteArray.decode_double. Integers stay integers.
function f64(x) { const b = Buffer.alloc(8); b.writeDoubleLE(x); return "f" + b.toString("hex"); }
function pack(v) {
  if (typeof v === "number") return Number.isInteger(v) ? v : f64(v);
  if (Array.isArray(v)) return v.map(pack);
  if (v && typeof v === "object") { const o = {}; for (const k of Object.keys(v)) o[k] = pack(v[k]); return o; }
  return v;
}

const out = pack({ economy, physics, offline, constants });
fs.writeFileSync(path.join(__dirname, "conformance.json"), JSON.stringify(out));
console.log("conformance.json: %d economy, %d physics runs (%d events), %d offline, %d constants",
  economy.length, physics.length, physics.reduce((n, p) => n + p.events.length, 0), offline.length,
  Object.keys(constants).length);

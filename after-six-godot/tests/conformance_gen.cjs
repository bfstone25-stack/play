// JS side of the JS<->GDScript conformance test.
//
//   node tests/conformance_gen.cjs        -> tests/conformance.json
//
// Runs the HTML spec's core (play/beat-monday/frontend/rpg/core.js + kernel) over seeded
// inputs and records what it produced; tests/run_tests.gd runs the GDScript port over the
// same inputs and asserts the same numbers.
//
//   stats   60 random profiles -> computeStats()
//   runs    8 seeds x 5 days, stepped at 1/60 s with a deterministic kiting thumb and
//           pending[0] skill picks, snapshot every 30 steps (position, hp, level, xp,
//           kills, counts, pattern, boss hp, rng draws so far) + the committed profile
//   rant    pattern / shot power over loadouts; phrase text per lang
//
// One deliberate arithmetic alignment: V8's Math.hypot is a scaled Kahan sum, which is not
// bit-identical to sqrt(dx*dx+dy*dy); the harness installs the latter as Math.hypot before
// the core loads, and the GDScript side computes the same expression. Everything else
// (mulberry32, toFixed, sin/cos/atan2) is the engines' own arithmetic.
const fs = require("fs"), vm = require("vm"), path = require("path");
const SPEC = path.join(__dirname, "../../beat-monday");
const M = Object.assign(Object.create(null), Object.getOwnPropertyNames(Math).reduce((o, k) => (o[k] = Math[k], o), {}));
M.hypot = (a, b) => Math.sqrt(a * a + b * b);
const ctx = { console, Math: M };
vm.createContext(ctx);
const load = p => vm.runInContext(fs.readFileSync(path.join(SPEC, p), "utf8"), ctx, { filename: p });
load("frontend/kernel/pool.js");
load("frontend/kernel/rant.js");
load("frontend/rpg/phrases.js");
load("frontend/rpg/data.js");
load("frontend/rpg/core.js");
vm.runInContext("globalThis.api={BMCore,BMData,BMPhrases,rantPattern,rantShotPower,rantDamage}", ctx);
const { BMCore, BMData, BMPhrases, rantPattern, rantShotPower } = ctx.api;

function lcg(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
const pick = (r, arr) => arr[Math.floor(r() * arr.length)];

function randomProfile(r, rich) {
  const p = BMCore.newProfile();
  p.level = 1 + Math.floor(r() * (rich ? 20 : 6));
  p.xp = Math.floor(r() * 30);
  const nsk = Math.floor(r() * (rich ? 9 : 3));
  for (let i = 0; i < nsk; i++) p.skills.push(pick(r, BMData.SKILLS).id);
  BMData.EQUIP.forEach(e => { if (r() < (rich ? 0.6 : 0.25)) p.owned.push(e.id); });
  p.owned.forEach(id => { const e = BMData.EQUIP.find(x => x.id === id); if (r() < 0.7) p.equipped[e.slot] = id; });
  BMData.PARTY.forEach(x => { if (r() < (rich ? 0.6 : 0.2)) p.party.push(x.id); });
  if (r() < 0.5) p.rant = ["ok", "lie"]; if (r() < 0.25) p.rant.push("teach"); if (r() < 0.15) p.rant.push("legend");
  p.week = Math.floor(r() * 3);
  return p;
}

const out = { stats: [], runs: [], rant: [], phrases: [] };

// ---- stats ----
{
  const r = lcg(77);
  for (let i = 0; i < 60; i++) {
    const p = randomProfile(r, i % 2 === 0);
    out.stats.push({ profile: p, stats: BMCore.computeStats(p) });
  }
}

// ---- runs ----
function kite(run) {
  const n = BMCore.nearestFoe(run);
  let tx = BMCore.W / 2, ty = BMCore.H * 0.8;
  if (n) {
    const dx = run.px - n.x, dy = run.py - n.y, m = Math.hypot(dx, dy) || 1;
    tx = Math.max(20, Math.min(BMCore.W - 20, run.px + dx / m * 120));
    ty = Math.max(70, Math.min(BMCore.H - 20, run.py + dy / m * 120));
  }
  return { x: tx, y: ty };
}
function snap(run, draws) {
  return {
    t: run.t, px: run.px, py: run.py, hp: run.hp, maxHp: run.maxHp, level: run.level, xp: run.xp, kills: run.kills,
    foes: run.foes.length, shots: run.shots.length, foeShots: run.foeShots.length, picks: run.picks.length,
    shotsFired: run.shotsFired, phrasesFired: run.phrasesFired, lastPattern: run.lastPattern, phase: run.phase,
    over: run.over, bossHp: run.boss ? run.boss.hp : null, rantCombo: run.rantCombo.slice(), draws,
    foeHpSum: run.foes.reduce((s, f) => s + f.hp, 0), pierce: run.shots.reduce((s, x) => s + x.pierce, 0),
    skills: run.profile.skills.slice(),
  };
}
{
  const r = lcg(2026);
  for (let seed = 1; seed <= 8; seed++) {
    for (let d = 0; d < 5; d++) {
      const profile = seed <= 3 ? BMCore.newProfile() : randomProfile(r, seed >= 6);
      const before = JSON.parse(JSON.stringify(profile));   // applySkill mutates profile.skills
      const run = BMCore.createRun(profile, d, seed * 7919 + d);
      run.lang = ["en", "zh", "ja"][seed % 3];
      let draws = 0;
      const orig = run.rng;
      run.rng = () => { draws++; return orig(); };
      const snaps = [], picks = [], texts = [];
      const maxSteps = 75 * 60;
      let step = 0;
      while (!run.over && step < maxSteps) {
        if (run.pending) { picks.push(run.pending.slice()); BMCore.applySkill(run, run.pending[0]); continue; }
        BMCore.step(run, 1 / 60, kite(run));
        step++;
        if (step % 30 === 0) snaps.push(snap(run, draws));
        if (run.day.mode === "rant" && texts.length < 40) run.shots.forEach(s => { if (s.text && texts.length < 40 && texts[texts.length - 1] !== s.text) texts.push(s.text); });
      }
      const after = BMCore.commitRun(JSON.parse(JSON.stringify(profile)), run);
      out.runs.push({ seed: seed * 7919 + d, day: d, lang: run.lang, profile: before, steps: step, snaps, picks, texts,
        final: snap(run, draws), reward: run.reward, committed: after });
    }
  }
}

// ---- rant ----
{
  const cat = BMCore.rantCatalog();
  const loads = [[], ["ok"], ["ok", "lie"], ["ok", "lie", "teach"], ["quit"], ["legend"], ["ok", "quit"], ["lie", "teach", "quit"], ["ok", "lie", "teach", "quit", "legend"], ["nope"]];
  loads.forEach(l => out.rant.push({ combo: l, pattern: rantPattern(l, cat), power: rantShotPower(l, cat) }));
  ["en", "zh", "ja", "fr"].forEach(lang => ["ok", "lie", "teach", "quit", "legend", "zzz"].forEach(k => out.phrases.push({ lang, kind: k, text: BMPhrases.shot(lang, k) })));
}

fs.writeFileSync(path.join(__dirname, "conformance.json"), JSON.stringify(out));
console.log("conformance.json:", out.stats.length, "stats,", out.runs.length, "runs,", out.runs.reduce((s, r) => s + r.snaps.length, 0), "snapshots,", out.rant.length, "rant cases");

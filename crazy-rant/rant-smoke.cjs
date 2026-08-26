const fs = require("fs");
const vm = require("vm");
const path = require("path");
const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync(path.join(__dirname, "frontend/js/rant.js"), "utf8") +
    "\nglobalThis.testApi={combinePhrases,rantDamage,parseLoadout,rantPattern,rantShotPower};",
  ctx,
);
const { combinePhrases, rantDamage, parseLoadout, rantPattern, rantShotPower } = ctx.testApi;
const cat = [
  { id: "quit", text: "我不干了", power: 40 },
  { id: "teach", text: "你在教我做事", power: 25 },
  { id: "ok", text: "好的好的", power: 5 },
  { id: "legend", text: "你们不要再劝我努力了", power: 80 },
];
const combo = combinePhrases(["我不干了", "你在教我做事"]);
if (combo !== "我不干了，你在教我做事") throw new Error(combo);
const dmg = rantDamage(combo, cat);
if (dmg < 65) throw new Error("combo too weak " + dmg);
const load = parseLoadout(["quit", "teach"], cat);
if (load.length !== 2) throw new Error("loadout");
if (rantPattern(["ok"], cat) !== "stream") throw new Error("ok should stream");
if (rantPattern(["quit", "teach"], cat) !== "spread") throw new Error("mid power should spread");
if (rantPattern(["quit", "teach", "ok"], cat) !== "spread") throw new Error("three cards should spread");
if (rantPattern(["legend"], cat) !== "burst") throw new Error("legend should burst");
if (rantPattern(["teach", "ok"], cat) !== "wave") throw new Error("teach pair should wave");
if (rantShotPower(combo, cat) < 2.2) throw new Error("shot power");
if (rantPattern([], cat) !== "stream") throw new Error("empty loadout");

const combatCtx = { console, Math, performance: { now: Date.now } };
combatCtx.window = combatCtx;
combatCtx.SFX = { unlock(){}, fire(){}, hit(){}, hurt(){}, phase(){}, win(){}, lose(){}, paper(){}, pulse(){} };
combatCtx.GLYPHS = { META: { ok: { color: "#eab308" }, quit: { color: "#e11d48" }, teach: { color: "#06b6d4" } } };
vm.createContext(combatCtx);
for (const file of ["pool.js", "phrases.js", "danmaku.js", "combat.js", "boss.js"]) {
  vm.runInContext(fs.readFileSync(path.join(__dirname, "frontend/js", file), "utf8"), combatCtx);
}
const names = Object.keys(combatCtx.DANMAKU.CATALOG);
if (names.length < 12) throw new Error("not enough patterns " + names.length);
const motions = new Set();
const texts = new Set();
for (const name of names) {
  const state = combatCtx.COMBAT.create();
  combatCtx.COMBAT.reset(state, { pattern: "spread", shotPower: 12, loadout: ["quit", "teach"], reduced: true, lang: "ja" });
  combatCtx.DANMAKU.run(name, state);
  if (state.hazards.live.length < 1) throw new Error(name + " spawned nothing");
  state.hazards.live.forEach((h) => {
    if (!h.text) throw new Error(name + " bullet has no text");
    if (h.text.length > 4) throw new Error(name + " ofuda too long: " + h.text);
    if (h.rot) throw new Error(name + " ofuda rotated " + h.rot);
    if (h.shape !== "giant" && h.shape !== "stamp" && (h.r || 0) > 8) {
      throw new Error(name + " fat hitbox " + h.r + " " + h.shape);
    }
    texts.add(h.text);
    motions.add(h.motion);
  });
}
if (texts.size < 8) throw new Error("phrase pool too thin " + texts.size);
if (motions.size < 5) throw new Error("motion variety too thin " + [...motions]);

function minPitch(state) {
  const xs = state.hazards.live.map((h) => h.x).sort((a, b) => a - b);
  let min = Infinity;
  for (let i = 1; i < xs.length; i++) min = Math.min(min, xs[i] - xs[i - 1]);
  return min;
}
const rain = combatCtx.COMBAT.create();
combatCtx.COMBAT.reset(rain, { pattern: "spread", shotPower: 12, loadout: ["quit"], reduced: true, lang: "zh" });
rain.rank = 14;
rain.boss.meeting = 3;
combatCtx.DANMAKU.run("rain_ok", rain);
if (minPitch(rain) < 36) throw new Error("rain columns too tight " + minPitch(rain));
const curtain = combatCtx.COMBAT.create();
combatCtx.COMBAT.reset(curtain, { pattern: "spread", shotPower: 12, loadout: ["quit"], reduced: true, lang: "en" });
curtain.rank = 14;
curtain.boss.meeting = 3;
combatCtx.DANMAKU.run("curtain_ok", curtain);
if (minPitch(curtain) < 36) throw new Error("curtain columns too tight " + minPitch(curtain));
const jaWord = combatCtx.PHRASES.pick("ja", "ok", 0);
if (!jaWord || jaWord.length < 2) throw new Error("ja bank empty");

const state = combatCtx.COMBAT.create();
combatCtx.COMBAT.reset(state, { pattern: "spread", shotPower: 12, loadout: ["quit", "teach"], reduced: true, lang: "en" });
for (let i = 0; i < 240; i++) combatCtx.COMBAT.update(state, 1 / 60);
if (state.boss.hp >= state.boss.maxHp) throw new Error("boss never damaged");
if (state.hazards.live.length < 1 && state.outcome !== "win") throw new Error("boss never attacked");
if (state.shots.live.length < 1 && !state.outcome) throw new Error("player never fired");
const readable = state.hazards.live.filter((h) => h.text && h.text.length >= 2);
if (readable.length < 1 && state.outcome !== "win") throw new Error("no readable bullets");

const aim = combatCtx.COMBAT.create();
combatCtx.COMBAT.reset(aim, { pattern: "stream", shotPower: 12, loadout: ["ok"], reduced: true, lang: "en" });
aim.player.x = 80;
aim.player.y = 560;
const sideShot = { x: 80, y: aim.boss.y, hw: 10, hh: 30 };
if (!combatCtx.BOSS.hit(aim.boss, sideShot)) throw new Error("boss still ignores ofuda at the side");

// Test Bomb Trigger
combatCtx.DANMAKU.run("rain_ok", state);
const prevCount = state.hazards.live.length;
if (prevCount === 0) throw new Error("no hazards for bomb test");
const bombSuccess = combatCtx.COMBAT.triggerBomb(state);
if (!bombSuccess) throw new Error("bomb trigger failed");
if (state.hazards.live.length !== 0) throw new Error("bomb did not clear screen hazards");

console.log("crazy rant combinator ok", {
  combo, dmg,
  pattern: rantPattern(["quit", "teach"], cat),
  boss: Math.round(state.boss.hp),
  meeting: state.boss.meeting,
  patterns: names.length,
  motions: [...motions],
  phrases: texts.size,
});

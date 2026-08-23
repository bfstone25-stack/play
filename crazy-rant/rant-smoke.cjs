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
if (rantShotPower(combo, cat) < 3) throw new Error("shot power");
if (rantPattern([], cat) !== "stream") throw new Error("empty loadout");

const combatCtx = { console, Math, performance: { now: Date.now } };
combatCtx.window = combatCtx;
combatCtx.SFX = { unlock(){}, fire(){}, hit(){}, hurt(){}, phase(){}, win(){}, lose(){}, paper(){}, pulse(){} };
combatCtx.GLYPHS = { META: { ok: { color: "#eab308" }, quit: { color: "#e11d48" }, teach: { color: "#06b6d4" } } };
vm.createContext(combatCtx);
vm.runInContext(fs.readFileSync(path.join(__dirname, "frontend/js/pool.js"), "utf8"), combatCtx);
vm.runInContext(fs.readFileSync(path.join(__dirname, "frontend/js/boss.js"), "utf8"), combatCtx);
vm.runInContext(fs.readFileSync(path.join(__dirname, "frontend/js/combat.js"), "utf8"), combatCtx);
const state = combatCtx.COMBAT.create();
combatCtx.COMBAT.reset(state, { pattern: "spread", shotPower: 12, loadout: ["quit", "teach"], reduced: true });
for (let i = 0; i < 240; i++) combatCtx.COMBAT.update(state, 1 / 60);
if (state.boss.hp >= state.boss.maxHp) throw new Error("boss never damaged");
if (state.hazards.live.length < 1 && state.outcome !== "win") throw new Error("boss never attacked");
if (state.shots.live.length < 1 && !state.outcome) throw new Error("player never fired");
console.log("crazy rant combinator ok", { combo, dmg, pattern: rantPattern(["quit", "teach"], cat), boss: Math.round(state.boss.hp), phase: state.boss.phase });

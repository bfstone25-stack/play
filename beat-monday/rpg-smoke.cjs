/* Plays the whole work week headlessly: five days, level-ups, equipment, party,
 * and the Wednesday rant level firing phrase projectiles. Fails loudly. */
const fs = require("fs"), vm = require("vm"), path = require("path");
const ctx = { console, Math };
vm.createContext(ctx);
const load = p => vm.runInContext(fs.readFileSync(path.join(__dirname, p), "utf8"), ctx, { filename: p });
load("../catharsis/kernel/pool.js");
load("../catharsis/kernel/rant.js");
load("frontend/rpg/phrases.js");
load("frontend/rpg/data.js");
load("frontend/rpg/core.js");
vm.runInContext("globalThis.api={BMCore,BMData,BMPhrases,rantPattern,rantDamage}", ctx);
const { BMCore, BMData } = ctx.api;

function fail(m) { throw new Error("SMOKE FAIL: " + m); }

const profile = BMCore.newProfile();
const report = [];
let levelUps = 0, phraseShots = 0;

for (let d = 0; d < BMData.DAYS.length; d++) {
  let run = null, cleared = false, attempts = 0;
  while (!cleared && attempts < 40) {
    attempts++;
    run = BMCore.createRun(profile, d, 1234 + d * 31 + attempts);
    run.lang = "en";
    // difficulty assist for the harness only: it plays badly, so give it dodging.
    let t = 0;
    while (!run.over && t < 400) {
      if (run.pending) {
        const pick = run.pending[0];
        if (!BMCore.applySkill(run, pick)) fail("applySkill rejected " + pick);
        levelUps++;
        continue;
      }
      // kite: run away from the nearest threat, stay in bounds
      const n = BMCore.nearestFoe(run);
      let tx = BMCore.W / 2, ty = BMCore.H * 0.8;
      if (n) {
        const dx = run.px - n.x, dy = run.py - n.y, m = Math.hypot(dx, dy) || 1;
        tx = Math.max(20, Math.min(BMCore.W - 20, run.px + dx / m * 120));
        ty = Math.max(70, Math.min(BMCore.H - 20, run.py + dy / m * 120));
      }
      BMCore.step(run, 1 / 60, { x: tx, y: ty });
      if (run.day.mode === "rant") phraseShots += run.shots.filter(s => s.text).length ? 0 : 0;
      t += 1 / 60;
    }
    cleared = run.over === "clear";
  }
  if (!cleared) fail("day " + BMData.DAYS[d].id + " never cleared in " + attempts + " attempts");
  if (d === 2) {
    if (run.day.mode !== "rant") fail("wednesday is not the rant level");
    if (run.phrasesFired < 50) fail("rant level fired only " + run.phrasesFired + " phrase projectiles");
    phraseShots = run.phrasesFired;
    if (["stream", "spread", "burst"].indexOf(run.lastPattern) < 0) fail("bad rant pattern " + run.lastPattern);
  }
  const before = JSON.parse(JSON.stringify(profile));
  BMCore.commitRun(profile, run);
  report.push({
    day: run.day.id, tries: attempts, kills: run.kills, level: profile.level,
    owned: profile.owned.slice(), party: profile.party.slice(), pattern: run.lastPattern,
  });
  if (profile.level < before.level) fail("level went backwards");
}

// equipment actually changes the numbers
const bare = BMCore.computeStats(Object.assign({}, profile, { equipped: { hand: null, desk: null, wear: null } }));
const kitted = BMCore.computeStats(profile);
if (!(kitted.hp > bare.hp || kitted.atk > bare.atk || kitted.rate > bare.rate || kitted.spd > bare.spd))
  fail("equipment changed nothing: " + JSON.stringify([bare, kitted]));
if (!BMCore.equip(profile, "stapler")) fail("equip() refused an owned item");

if (profile.level < 5) fail("only reached level " + profile.level + " across a week");
if (levelUps < 5) fail("only " + levelUps + " level-up choices offered");
if (profile.owned.length < 5) fail("only " + profile.owned.length + " equipment drops");
if (profile.party.length < 3) fail("party never filled: " + profile.party);
if (profile.week !== 1 || profile.day !== 0) fail("week did not roll over: " + profile.week + "/" + profile.day);
if (phraseShots < 50) fail("no phrase projectiles recorded");

console.log("beat-monday rpg ok");
console.table(report);
console.log({ level: profile.level, levelUps, phraseShots, equipped: profile.equipped, stats: kitted });

// vendored kernel must be byte-identical to play/catharsis/kernel (no forking)
["pool.js", "rant.js", "economy.js", "gacha.js", "commerce.js", "i18n.js", "save.js"].forEach(f => {
  const a = fs.readFileSync(path.join(__dirname, "../catharsis/kernel/", f));
  const b = fs.readFileSync(path.join(__dirname, "frontend/kernel/", f));
  if (!a.equals(b)) fail("vendored kernel drifted: " + f + " (run ./sync-kernel.sh)");
});
console.log("kernel copies match");

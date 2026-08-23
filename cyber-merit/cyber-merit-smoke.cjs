const fs = require("fs");
const vm = require("vm");
const path = require("path");

const context = {
  console,
  Math,
  Date,
  Object,
  Number,
  String,
  Array,
  JSON,
  globalThis: null,
};
context.globalThis = context;
vm.createContext(context);

const src = ["frontend/js/koans.js", "frontend/js/save.js", "frontend/js/liturgy.js"]
  .map((rel) => fs.readFileSync(path.join(__dirname, rel), "utf8"))
  .join("\n") + "\nglobalThis.KOANS=KOANS;globalThis.LITURGY=LITURGY;globalThis.Save=Save;";
vm.runInContext(src, context);

const { KOANS, LITURGY, Save } = context;

if (KOANS.PACK.length < 40) throw new Error("need 40 koans, got " + KOANS.PACK.length);
const a = KOANS.today("zh-Hans", "2026-08-23");
const b = KOANS.today("zh-Hans", "2026-08-23");
if (a.text !== b.text) throw new Error("daily koan must be stable");
if (!KOANS.today("en", "2026-08-23").text) throw new Error("en koan");

Save.useMemory();
LITURGY.load({ merit: 0, clicks: 0, upgrades: { fish: 0, hand: 0, altar: 0, city: 0, mandala: 0 } });
const first = LITURGY.strike();
if (first.gain < 1) throw new Error("base strike");

LITURGY.load({ merit: 0, clicks: 0, upgrades: { fish: 3, hand: 2, altar: 0, city: 0, mandala: 0 } });
const rich = LITURGY.clickGain();
LITURGY.load({ merit: 0, clicks: 0, upgrades: { fish: 0, hand: 0, altar: 0, city: 0, mandala: 0 } });
if (rich <= LITURGY.clickGain()) throw new Error("higher fish must pay more");

const c0 = LITURGY.cost("fish", 0);
if (c0 !== 40) throw new Error("fish cost " + c0);
LITURGY.load({ merit: 200, upgrades: {} });
if (!LITURGY.tryUpgrade("fish")) throw new Error("upgrade should succeed");
if (LITURGY.snapshot().upgrades.fish !== 1) throw new Error("fish level");

LITURGY.load({ merit: 0, upgrades: { hand: 4, fish: 2 } });
if (LITURGY.autoRate() <= 0) throw new Error("auto sangha should idle");
const t = LITURGY.tick(2);
if (t <= 0) throw new Error("tick");

LITURGY.load({ merit: 500, fill: 0, liturgyCount: 0, upgrades: { mandala: 0 } });
let done = false;
for (let i = 0; i < 80; i++) {
  const r = LITURGY.strike();
  if (r.complete) { done = true; break; }
}
if (!done) throw new Error("liturgy should complete");

Save.useMemory();
Save.persist(LITURGY.persistable());
const loaded = Save.load();
if (loaded.schema !== 1) throw new Error("save schema");

console.log("cyber-merit smoke ok", {
  koans: KOANS.PACK.length,
  snap: LITURGY.snapshot(),
  first: first.gain,
  rich,
});

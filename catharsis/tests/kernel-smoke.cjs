const fs = require("fs");
const vm = require("vm");
const path = require("path");

function loadKernel() {
  const context = { console, Math };
  vm.createContext(context);
  const files = ["economy.js", "gacha.js", "commerce.js", "save.js", "breakables.js", "i18n.js"];
  let src = "";
  for (const f of files) {
    src += fs.readFileSync(path.join(__dirname, "../kernel", f), "utf8") + "\n";
  }
  src += "\nglobalThis.testApi={Economy,Gacha,Commerce,Save,hitBreakables,I18N};";
  vm.runInContext(src, context);
  return context.testApi;
}

const { Economy, Gacha, Commerce, Save, hitBreakables, I18N } = loadKernel();

Economy.load({ stardust: 0, tickets: 20 });
if (!Economy.consumeTicket()) throw new Error("ticket consume failed");
if (Economy.snapshot().tickets !== 19) throw new Error("ticket count");
Economy.grant(120);
if (!Economy.spend(50) || Economy.snapshot().stardust !== 70) throw new Error("stardust spend");
if (Economy.spend(999)) throw new Error("overspend allowed");

Gacha.load({ pity: 0, pulls: 0, inventory: [] });
const pool = [
  { id: "cat", rarity: "N" },
  { id: "coffee", rarity: "SR" },
  { id: "boss", rarity: "SSR" },
];
let high = 0;
for (let i = 0; i < 10; i++) {
  const got = Gacha.pull(pool, () => 0);
  if (got.rarity === "SR" || got.rarity === "SSR") high++;
}
if (high < 1) throw new Error("10-pull pity never fired");
if (Gacha.snapshot().inventory.length !== 10) throw new Error("inventory length");

const ticketsBefore = Economy.snapshot().tickets;
Commerce.rewarded("ammo");
if (Economy.snapshot().tickets !== ticketsBefore + 5) throw new Error("rewarded ammo stub");
const buy = Commerce.purchase("ammo.099");
if (!buy.ok || !buy.stub) throw new Error("iap stub");
if (Commerce.purchase("nope").ok) throw new Error("unknown sku");

Save.useMemory();
Save.persist({ title: "test" });
const loaded = Save.load();
if (loaded.schema !== 1) throw new Error("schema");
if (loaded.economy.stardust !== Economy.snapshot().stardust) throw new Error("save roundtrip");

const ball = { x: 20, y: 20, r: 8, vx: 40, vy: 80 };
const blocks = [{ id: "urgent", x: 10, y: 18, w: 40, h: 20, hp: 1 }];
const smashed = hitBreakables(ball, blocks);
if (!smashed || blocks[0].hp !== 0) throw new Error("breakable smash");

I18N.register({
  en: { "ui.launch": "Launch" },
  "zh-Hans": { "ui.launch": "发射" },
});
I18N.setLang("zh-Hans");
if (I18N.t("ui.launch") !== "发射") throw new Error("i18n zh");
I18N.setLang("en");
if (I18N.t("ui.launch") !== "Launch") throw new Error("i18n en");

console.log("kernel economy/gacha/commerce/save/breakables ok");

const fs = require("fs");
const vm = require("vm");
const path = require("path");
const context = { console, Math };
vm.createContext(context);
vm.runInContext(
  fs.readFileSync(path.join(__dirname, "../catharsis/kernel/merit.js"), "utf8") +
    "\nglobalThis.testApi={Merit};",
  context,
);
const { Merit } = context.testApi;
Merit.load({ merit: 0, clicks: 0, level: 1, auto: 0 });
let first = Merit.click();
if (first !== 1) throw new Error("base click");
for (let i = 0; i < 40; i++) Merit.click();
if (!Merit.tryUpgrade()) throw new Error("upgrade should succeed after clicks");
const a = Merit.click();
Merit.load({ merit: 0, clicks: 0, level: 8, auto: 0 });
const b = Merit.click();
if (b <= a) throw new Error("higher level must pay more");
Merit.load({ merit: 0, clicks: 0, level: 6, auto: 4 });
const t = Merit.tick(10);
if (t <= 0) throw new Error("auto tick");
console.log("cyber merit formula ok", Merit.snapshot(), { a, b, t });

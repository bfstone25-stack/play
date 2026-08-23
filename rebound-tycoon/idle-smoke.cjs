const fs = require("fs");
const vm = require("vm");
const path = require("path");
const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync(path.join(__dirname, "../catharsis/kernel/idle.js"), "utf8") +
    "\nglobalThis.testApi={IDLE,idleRate,upgradeCost,offlineSeconds,offlineEarn};",
  ctx,
);
const { IDLE, idleRate, offlineSeconds, offlineEarn } = ctx.testApi;
if (IDLE.CAP_HOURS !== 8) throw new Error("cap hours");
const t0 = 1_700_000_000_000;
if (offlineSeconds(t0, t0 - 5000) !== 0) throw new Error("future clock must earn 0");
if (offlineSeconds(t0, t0 + 1000) !== 1) throw new Error("1s window");
const nineH = t0 + 9 * 3600 * 1000;
if (offlineSeconds(t0, nineH) !== 8 * 3600) throw new Error("cap 8h");
const rate = idleRate(3, [{ count: 2, rate: 4 }]);
if (rate < 8) throw new Error("rate " + rate);
const pay = offlineEarn(t0, t0 + 10_000, 2);
if (pay !== 20) throw new Error("pay " + pay);
console.log("rebound tycoon idle ok", { rate, pay });

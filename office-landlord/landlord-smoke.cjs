const fs = require("fs");
const vm = require("vm");
const path = require("path");
const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync(path.join(__dirname, "../catharsis/kernel/landlord.js"), "utf8") +
    "\nglobalThis.testApi={LANDLORD,neighborsOf,settleGrid,place,idx};",
  ctx,
);
const { LANDLORD, neighborsOf, settleGrid, place } = ctx.testApi;
if (LANDLORD.SIZE !== 20) throw new Error("size");
if (neighborsOf(0).length !== 2) throw new Error("corner neighbors");
if (neighborsOf(6).length !== 4) throw new Error("center neighbors");
const cat = [
  { id: "coffee", payout: 2 },
  { id: "dev", payout: 3 },
];
const cells = new Array(20).fill(null);
cells[0] = "coffee";
cells[1] = "dev";
const r = settleGrid(cells, cat);
if (r.payout < 8) throw new Error("combo payout " + r.payout);
if (!r.events.includes("coffee-dev")) throw new Error("combo event");
let g = new Array(20).fill(null);
g = place(g, "coffee");
if (g[0] !== "coffee") throw new Error("place");
console.log("office landlord settle ok", r);

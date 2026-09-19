// Loads the browser-global game modules into one vm context with a fake localStorage and
// an injectable clock, so the ticker, the gacha and the economy can be driven from node.
const fs = require("fs"), path = require("path"), vm = require("vm");
const FE = path.join(__dirname, "..", "frontend", "js");

function memStorage() {
  const m = new Map();
  return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, String(v)), removeItem: (k) => m.delete(k), clear: () => m.clear(), _m: m };
}

function load(opts) {
  opts = opts || {};
  const ctx = { console, Math, JSON, Date, localStorage: opts.storage || memStorage(), window: {} };
  ctx.window = ctx;
  vm.createContext(ctx);
  ["landlord.js", "roster.js", "economy.js", "idle.js"].forEach((f) => {
    vm.runInContext(fs.readFileSync(path.join(FE, f), "utf8") + "\n", ctx, { filename: f });
  });
  vm.runInContext("globalThis.__api = { LANDLORD, LANDLORD_CATALOG, LANDLORD_STARTER, LANDLORD_CAST, settleGrid, rentForFloor, neighborsOf, " +
    "IDLE_ROSTER, IDLE_CATALOG, IDLE_STAFF, IDLE_OBJECTS, IDLE_PITY, rosterBy, rosterPool, CHAIN_K, chainOf, chainMult, dupeBonus, settleIdle, Economy, Idle };", ctx);
  const api = ctx.__api;
  api.ctx = ctx;
  api.settleIdleK = (cells, relics, dupes, K) => {
    const r = api.settleIdle(cells, relics, dupes);
    r.mult = 1 + K * r.chain;
    r.shift = Math.round(r.payout * r.mult);
    return r;
  };
  return api;
}
module.exports = { load, memStorage };

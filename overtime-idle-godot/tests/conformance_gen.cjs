// JS side of the JS<->GDScript conformance test.
//
//   node tests/conformance_gen.cjs        -> tests/conformance.json
//
// 200 seeded random boards (random pieces from the full catalogue, random relic sets,
// random dupe maps), each settled by the prototype's settleIdle(); plus, for every board,
// a ticker run — a fresh building carrying that board, ticked to a handful of clock points
// with a 8 h cap — recording shifts, bank, rent paid, evictions, solvent days; plus 20
// seeded gacha sequences. tests/run_tests.gd ("conformance") loads this file, runs the
// GDScript port over the same inputs and asserts every number and event list is identical.
const fs = require("fs"), path = require("path");
const { load } = require("../../overtime-idle/tests/harness.cjs");
const A = load();
const H = 3600e3, M = 60e3;
const T0 = 1_800_000_000_000 - (1_800_000_000_000 % 86400e3) + 6 * H;
const IDS = ["coffee", "dan", "priya", "wes", "mute", "printer", "mara", "corner", "nia", "sol"];
const RELICS = ["severance", "quiet", "pto", "glass", "badge", "army"];

function lcg(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

const boards = [];
for (let b = 0; b < 200; b++) {
  const r = lcg(1000 + b);
  const n = 3 + Math.floor(r() * 16);
  const cells = new Array(20).fill(null);
  for (let k = 0; k < n; k++) cells[Math.floor(r() * 20)] = IDS[Math.floor(r() * IDS.length)];
  const relics = RELICS.filter(() => r() < 0.25);
  const dupes = {};
  ["dan", "priya", "mara", "wes", "nia", "sol"].forEach((id) => { if (r() < 0.4) dupes[id] = Math.floor(r() * 14); });
  const res = A.settleIdle(cells, relics, dupes);
  const plain = A.settleIdle(cells, relics, null);
  // ticker: the board on floor 1 of a fresh building, ticked through several clock points
  const s = A.Idle.fresh(T0);
  s.floors[0].cells = cells.slice();
  s.relics = relics.slice();
  if (r() < 0.3) { s.bank = 10000; A.Idle.buildFloor(s, T0); s.floors[1].cells[7] = "priya"; }
  const points = [T0 + 9 * M, T0 + 10 * M, T0 + 3 * H + 5 * M, T0 + 20 * H, T0 + 44 * H + 1000, T0 + 5 * 24 * H];
  const ticks = [];
  const shiftsByStaff = {};
  points.forEach((t) => {
    const rep = A.Idle.tick(s, t, { capMs: 8 * H, dupes, onShift: (id) => { shiftsByStaff[id] = (shiftsByStaff[id] || 0) + 1; } });
    ticks.push({ at: t, shifts: rep.shifts, rent: rep.rent, evictions: rep.evictions, rentPaid: rep.rentPaid, capped: rep.capped, frozenMs: rep.frozenMs, days: rep.days,
      bank: s.bank, nextShift: s.nextShift, lastDay: s.lastDay, solventDays: s.solventDays, totalShifts: s.totalShifts, perFloor: rep.perFloor });
  });
  boards.push({ cells, relics, dupes,
    settle: { payout: res.payout, events: res.events, cellScore: res.cellScore, links: res.links, chain: res.chain, mult: res.mult, shift: res.shift, dupeExtra: res.dupeExtra },
    plain: { shift: plain.shift, payout: plain.payout },
    rate: A.Idle.ratePerHour(s, dupes),
    ticks, shiftsByStaff, floors: s.floors.map((f) => ({ n: f.n, cells: f.cells, evictions: f.evictions, shifts: f.shifts, best: f.best, earnedToday: f.earnedToday, builtAt: f.builtAt })) });
}

const gacha = [];
for (let g = 0; g < 20; g++) {
  const B = load();
  B.Economy.devAddGold(100000);
  for (let i = 0; i < 4; i++) B.Economy.buy("pull_10");
  const res = B.Economy.pull(40, lcg(500 + g)).results;
  gacha.push({ seed: 500 + g, ids: res.map((x) => x.id), rarities: res.map((x) => x.rarity), dupes: res.map((x) => x.dupes), sinceEpic: B.Economy.sinceEpic() });
}

const rent = []; for (let f = 1; f <= 9; f++) rent.push([A.rentForFloor(f, []), A.rentForFloor(f, ["glass"]), A.Idle.floorCost(f)]);
let m = 1; const prestige = []; for (let i = 0; i < 12; i++) { m = +(m * 1.5).toFixed(3); prestige.push(m); }

const out = { T0, boards, gacha, rent, prestige };
fs.writeFileSync(path.join(__dirname, "conformance.json"), JSON.stringify(out));
console.log("conformance.json: " + boards.length + " boards, " + gacha.length + " gacha runs");

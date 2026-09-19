// Unit tests for the shift ticker (mocked clock), the gacha pity, and the SKU ledger.
//   node tests/idle.test.cjs
const { load } = require("./harness.cjs");
const H = 3600e3, M = 60e3;
let passed = 0;
const ok = (c, m) => { if (!c) { console.error("  FAIL " + m); process.exitCode = 1; } else { passed += 1; console.log("  ok   " + m); } };
const eq = (a, b, m) => ok(a === b, m + " (got " + JSON.stringify(a) + ", want " + JSON.stringify(b) + ")");

function chainFloor(A, f) {           // the parent's cg_quiet_floor reference board: coffee/dan/coffee + mute/dan/mara
  [[0, "coffee"], [1, "dan"], [2, "coffee"], [5, "mute"], [6, "dan"], [7, "mara"]].forEach(([i, id]) => { f.cells[i] = id; });
  return f;
}
const T0 = 1_800_000_000_000 - (1_800_000_000_000 % 86400e3) + 6 * H;   // 06:00 on a day boundary-aligned clock

console.log("shift ticker");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  const per = A.Idle.floorShift(s, s.floors[0]).pay;
  ok(per > 0, "a built floor pays per shift: " + per);
  let rep = A.Idle.tick(s, T0 + 9 * M);
  eq(rep.shifts, 0, "nothing fires before the first 10 minutes");
  rep = A.Idle.tick(s, T0 + 10 * M);
  eq(rep.shifts, 1, "one shift at 10 minutes");
  eq(s.bank, per, "the shift landed in the bank");
  rep = A.Idle.tick(s, T0 + 60 * M);
  eq(rep.shifts, 5, "five more by the hour");
  eq(A.Idle.ratePerHour(s), per * 6, "HUD rent/hour is six shifts of the board");
}

console.log("offline accrual is capped at 8 h");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  const rep = A.Idle.tick(s, T0 + 20 * H, { capMs: A.Idle.OFFLINE_CAP_MS });
  eq(rep.shifts, 48, "20 h away pays 8 h = 48 shifts");
  ok(rep.capped && rep.frozenMs === 12 * H, "report says the building froze for 12 h");
  const s2 = A.Idle.fresh(T0);
  chainFloor(A, s2.floors[0]);
  const rep2 = A.Idle.tick(s2, T0 + 20 * H, { capMs: 24 * H });
  eq(rep2.shifts, 120, "offline_cap_24h raises it: 20 h away pays 120 shifts");
  ok(!rep2.capped, "and is not capped");
  // after a capped return the clock keeps its phase: next shift is 10 min out, not immediate
  const rep3 = A.Idle.tick(s, T0 + 20 * H + 9 * M);
  eq(rep3.shifts, 0, "no catch-up burst after the cap");
  eq(A.Idle.tick(s, T0 + 20 * H + 10 * M).shifts, 1, "shift resumes on the 10-minute clock");
}

console.log("the cap SKU is wired through the economy");
{
  const A = load();
  eq(A.Economy.offlineCapMs(), 8 * H, "default cap 8 h");
  A.Economy.devAddGold(500);
  ok(A.Economy.buy("offline_cap_24h").ok, "buy offline_cap_24h");
  eq(A.Economy.offlineCapMs(), 24 * H, "cap now 24 h");
  eq(A.Economy.buy("offline_cap_24h").why, "already_owned", "one-time SKU cannot be bought twice");
}

console.log("daily rent check evicts and refunds staff");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  const ok1 = A.Idle.buildFloor(s, T0);
  eq(ok1.why, "bank", "floor 2 costs rent the bank does not have yet");
  s.bank = 10000;
  ok(A.Idle.buildFloor(s, T0).ok, "floor 2 built");
  s.floors[1].cells[7] = "priya";                 // a lone Priya: 1/shift, cannot cover floor 2's daily rent
  const dayEnd = (A.Idle.dayIndex(T0) + 1) * 86400e3;
  const evicted = [];
  const rep = A.Idle.tick(s, dayEnd + 5 * M, { capMs: 48 * H, onEvict: (f) => evicted.push(f.n) });
  eq(rep.days, 1, "one daily check ran");
  eq(rep.evictions.join(), "2", "floor 2 evicted, floor 1 (chain board) solvent");
  eq(evicted.join(), "2", "onEvict hook fired for floor 2");
  ok(s.floors[1].cells.every((c) => !c), "evicted floor is cleared");
  ok(s.floors[0].cells[1] === "dan", "solvent floor keeps its board");
  eq(s.floors[1].evictions, 1, "eviction counted");
  eq(s.solventDays, 0, "solvent-day streak reset by the eviction");
  // staff placed = count in cells, so a cleared floor returns them: Priya is placeable again
  const placed = s.floors.reduce((n, f) => n + f.cells.filter((c) => c === "priya").length, 0);
  eq(placed, 0, "Priya is back in the roster");
  // rent is prorated on the day a floor is built
  const s3 = A.Idle.fresh(dayEnd - 6 * H);
  eq(A.Idle.rentDue(s3.floors[0], [], dayEnd), Math.ceil(A.Idle.dailyRent(s3.floors[0], []) * 0.25), "first-day rent prorated to the quarter day");
}

console.log("frozen days: one check for the day the window closed in, the rest skipped");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  const rep = A.Idle.tick(s, T0 + 3 * 24 * H, { capMs: 8 * H });
  eq(rep.shifts, 48, "8 h of shifts");
  eq(rep.days, 1, "exactly one rent check for a three-day absence");
  eq(s.lastDay, A.Idle.dayIndex(T0 + 3 * 24 * H), "later frozen days skipped, not queued for the next tick");
  eq(A.Idle.tick(s, T0 + 3 * 24 * H + 1000).days, 0, "and the next tick runs no check");
  const s2 = A.Idle.fresh(T0);                     // an empty floor, 3 days away: evicted once, not thrice
  s2.floors[0].cells[7] = "priya";
  const rep2 = A.Idle.tick(s2, T0 + 3 * 24 * H, { capMs: 8 * H });
  eq(rep2.evictions.length, 1, "an insolvent floor is evicted once");
  eq(s2.floors[0].evictions, 1, "eviction count 1");
}

console.log("rent shield skips one eviction");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  s.floors[0].cells[7] = "priya";
  const dayEnd = (A.Idle.dayIndex(T0) + 1) * 86400e3;
  A.Economy.devAddGold(100);
  ok(A.Economy.buy("rent_shield").ok, "buy rent_shield");
  const rep = A.Idle.tick(s, dayEnd + M, { capMs: 48 * H, shields: () => A.Economy.useShield() });
  eq(rep.evictions.length, 0, "no eviction");
  eq(rep.shielded, 1, "shield consumed");
  eq(A.Economy.shields(), 0, "no shields left");
}

console.log("solvent streak and prestige");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  let t = T0;
  for (let d = 0; d < 7; d++) { t += 12 * H; A.Idle.tick(s, t, { capMs: 8 * H }); t += 12 * H; A.Idle.tick(s, t, { capMs: 8 * H }); }
  eq(s.solventDays, 7, "seven solvent days, visiting twice a day");
  ok(A.Idle.canPrestige(s), "prestige unlocked");
  A.Idle.prestige(s, t);
  eq(s.building, 2, "second building");
  eq(s.mult, 1.5, "rent multiplier 1.5");
  chainFloor(A, s.floors[0]);
  const A2 = load(); const s2 = A2.Idle.fresh(T0); chainFloor(A2, s2.floors[0]);
  eq(A.Idle.floorShift(s, s.floors[0]).pay, Math.round(A2.Idle.floorShift(s2, s2.floors[0]).pay * 1.5), "same board pays 1.5x in building 2");
}

console.log("dupes raise the shift bonus, capped");
{
  const A = load();
  const cells = A.Idle.emptyCells(); cells[1] = "dan"; cells[0] = "coffee";
  const base = A.settleIdle(cells, [], null).shift;
  const d3 = A.settleIdle(cells, [], { dan: 3 }).shift;
  const d10 = A.settleIdle(cells, [], { dan: 10 }).shift;
  const d40 = A.settleIdle(cells, [], { dan: 40 }).shift;
  ok(d3 > base, "3 dupes pay more than none (" + base + " -> " + d3 + ")");
  eq(A.dupeBonus(3), 1.15, "+5% per dupe");
  eq(d10, d40, "bonus caps at 10 dupes");
  eq(A.dupeBonus(99), 1.5, "cap is +50%");
}

console.log("gacha: weights and pity");
{
  const A = load();
  A.Economy.devAddGold(100000);
  let seed = 7; const rng = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  const counts = { common: 0, rare: 0, epic: 0 };
  for (let i = 0; i < 300; i++) { A.Economy.buy("pull_10"); A.Economy.pull(10, rng).results.forEach((r) => { counts[r.rarity] += 1; }); }
  const pct = (k) => counts[k] / 30;
  ok(pct("common") > 62 && pct("common") < 78, "common ~70%: " + pct("common").toFixed(1));
  ok(pct("rare") > 18 && pct("rare") < 32, "rare ~25%: " + pct("rare").toFixed(1));
  ok(pct("epic") > 3 && pct("epic") < 9, "epic ~5% (+pity): " + pct("epic").toFixed(1));
  // pity: an rng that never rolls an epic still gets one by pull 30
  const B = load();
  B.Economy.devAddGold(10000);
  B.Economy.buy("pull_10"); B.Economy.buy("pull_10"); B.Economy.buy("pull_10");
  const never = () => 0.99;
  const res = B.Economy.pull(30, never).results;
  eq(res.slice(0, 29).filter((r) => r.rarity === "epic").length, 0, "no epic in 29 unlucky pulls");
  eq(res[29].rarity, "epic", "pull 30 is the pity epic");
  eq(B.Economy.sinceEpic(), 0, "pity counter reset");
  ok(res[29].id === "sol", "the epic is Sol (the only epic in the pool)");
  eq(B.Economy.owned("sol"), 1, "Sol is now owned");
  eq(B.Economy.pull(1, never).why, "tickets", "no tickets left: pull refused");
}

console.log("SKU grants are idempotent");
{
  const A = load();
  const g1 = A.Economy.purchase("gold_m", "nutaku-tx-1");
  ok(g1.ok && A.Economy.gold() === 600, "gold_m grants 600");
  const g2 = A.Economy.purchase("gold_m", "nutaku-tx-1");
  ok(!g2.ok && g2.why === "duplicate", "same transaction id again is refused");
  eq(A.Economy.gold(), 600, "and grants nothing");
  ok(A.Economy.purchase("gold_m", "nutaku-tx-2").ok && A.Economy.gold() === 1200, "a new transaction id grants again");
  eq(A.Economy.grant("nope", "x").why, "unknown_sku", "unknown SKU refused");
  ok(A.Economy.buy("pull_1").ok && A.Economy.tickets() === 1 && A.Economy.gold() === 1170, "pull_1 costs 30 gold, grants a ticket");
  ok(A.Economy.buy("scene_skip_dan").ok, "scene_skip_<name> matched by prefix");
  eq(A.Economy.buy("scene_skip_dan").why, "already_owned", "scene skip once per character");
  eq(A.Economy.buy("gold_s").why, "iap_only", "IAP SKUs are not buyable with Gold");
  // the ledger survives a reload (same storage, new context)
  const B = load({ storage: A.ctx.localStorage });
  eq(B.Economy.gold(), 1090, "gold persisted across reload");
  ok(!B.Economy.purchase("gold_m", "nutaku-tx-1").ok, "duplicate detection persisted too");
}

console.log("timeskip collects four hours now without moving the real clock");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  A.Idle.tick(s, T0 + 5 * M);
  const rep = A.Idle.timeskip(s, T0 + 5 * M, 4 * H);
  eq(rep.shifts, 24, "24 shifts collected");
  eq(A.Idle.tick(s, T0 + 10 * M).shifts, 1, "the real 10-minute shift still lands on time");
}

console.log("affection counts shifts on a solvent floor");
{
  const A = load();
  const s = A.Idle.fresh(T0);
  chainFloor(A, s.floors[0]);
  const aff = {};
  A.Idle.tick(s, T0 + 200 * M, { onShift: (id) => { aff[id] = (aff[id] || 0) + 1; } });
  eq(aff.dan, 40, "two Dans x 20 shifts = 40 shift-credits");
  eq(aff.mara, 20, "Mara: 20");
  ok(aff.coffee == null, "objects have no affection");
  A.Economy.addShifts("dan", 60);
  eq(A.Economy.affectionTier("dan"), 2, "60 shifts = tier 2 (cg2)");
  A.Economy.addShifts("dan", 90);
  eq(A.Economy.affectionTier("dan"), 3, "150 = tier 3");
  ok(!A.Economy.canSeeScene("dan"), "tier-4 scene not yet");
  A.Economy.devAddGold(80); A.Economy.buy("scene_skip_dan");
  ok(A.Economy.canSeeScene("dan"), "scene_skip_dan opens it at 150");
}

console.log("\n" + passed + " checks passed" + (process.exitCode ? ", with failures" : ""));

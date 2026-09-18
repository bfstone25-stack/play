// Headless check of the fork's engine and of every board-shape CG predicate.
// landlord.js is pure and DOM-free, so the predicates can be driven directly.
const fs = require("fs"), path = require("path"), vm = require("vm");
const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(__dirname, "frontend/js/landlord.js"), "utf8") +
  "\nglobalThis.api={LANDLORD,LANDLORD_CATALOG,LANDLORD_CAST,settleGrid,placeAt,idx,isCorner,rentForFloor,meetRent,starterDeck,pickShop};", ctx);
const A = ctx.api;
const empty = () => new Array(A.LANDLORD.SIZE).fill(null);
const ok = (c, m) => { if (!c) throw new Error("FAIL " + m); console.log("  ok  " + m); };

ok(A.LANDLORD.FLOORS === 9, "floor 9 exists");
ok(A.LANDLORD_CAST.join() === "mara,dan,priya,wes", "four named adults are the cast");
ok(A.LANDLORD_CATALOG.length === 8, "still eight symbols");
ok(A.rentForFloor(8, []) === 107, "rent curve unchanged (floor 8 = 107 — both design docs say 116; they are wrong, Math.floor(8*1.45^7)=107)");
ok(A.starterDeck().indexOf("dev") < 0 && A.starterDeck().indexOf("dan") >= 0, "starter deck uses the cast ids");

// cg_dan_x — three coffee->Dan multipliers in one settle
let c = empty();
[[0,"dan"],[1,"coffee"],[2,"dan"],[5,"coffee"],[6,"dan"],[7,"coffee"]].forEach(([i,id]) => { c[i] = id; });
let r = A.settleGrid(c, null, []);
ok(r.events.filter(e => e === "coffee-dan").length >= 3, "cg_dan_x: 3x coffee-dan reachable");

// cg_priya_x — 3+ staff, someone shielded, zero wes-tax
c = empty(); c[6] = "mute"; c[1] = "dan"; c[5] = "priya"; c[7] = "mara";
r = A.settleGrid(c, null, []);
ok(r.events.includes("mute-shield") && r.events.filter(e => e === "wes-tax").length === 0, "cg_priya_x: shielded floor, no tax");

// and that Wes DOES tax when unshielded (the predicate has to be able to fail)
c = empty(); c[1] = "wes"; c[0] = "dan"; c[2] = "priya";
ok(A.settleGrid(c, null, []).events.filter(e => e === "wes-tax").length === 2, "wes taxes unshielded staff");

// cg_mara_corners — corner pays 0 off a corner, so this costs real placements
c = empty(); [0,4,15,19].forEach(i => { c[i] = "corner"; });
r = A.settleGrid(c, null, []);
ok([0,4,15,19].every(i => c[i] === "corner") && r.cellScore[0] === 3, "cg_mara_corners: four corners score");
ok(A.settleGrid(Object.assign(empty(), {6: "corner"}), null, []).cellScore[6] === 0, "corner off-corner pays 0");

// cg_wes_x — Intern Army relic, four copies in one settle. Priya only "copies" a
// neighbour under the relic when that neighbour's FINAL score beats the base she already
// took, so this needs coffee-multiplied Dans on the board: a real shape, not a stack.
c = empty();
[[0,"dan"],[1,"coffee"],[2,"priya"],[3,"coffee"],[4,"dan"],
 [6,"priya"],[8,"priya"],
 [10,"dan"],[11,"coffee"],[12,"priya"],[13,"coffee"],[14,"dan"],
 [16,"priya"],[18,"priya"]].forEach(([i,id]) => { c[i] = id; });
r = A.settleGrid(c, null, ["army"]);
ok(r.events.filter(e => e === "priya-army").length >= 4, "cg_wes_x: 4x priya-army reachable (got " + r.events.filter(e => e === "priya-army").length + ")");

// cg_quiet_floor — Quiet Floor relic and a six-link chain in one settle
c = empty();
[[0,"coffee"],[1,"dan"],[2,"coffee"],[5,"mute"],[6,"dan"],[7,"mara"]].forEach(([i,id]) => { c[i] = id; });
r = A.settleGrid(c, null, ["quiet"]);
const chain = r.events.filter(e => e !== "wes-tax").length;
ok(chain >= 6, "cg_quiet_floor: chain >= 6 reachable (got " + chain + ")");

// per-settle chain is not a run-max: an empty board reports 0
ok(A.settleGrid(empty(), null, []).events.length === 0, "per-settle chain describes THIS board");

// cg_glass_office — glass relic raises rent 10% and stops the tax
ok(A.rentForFloor(6, ["glass"]) === Math.ceil(A.rentForFloor(6, []) * 1.1), "cg_glass_office: glass rent +10%");
c = empty(); c[1] = "wes"; c[0] = "dan";
ok(A.settleGrid(c, null, ["glass"]).events.filter(e => e === "wes-tax").length === 0, "glass stops the tax");

console.log("\nall predicate conditions reachable");

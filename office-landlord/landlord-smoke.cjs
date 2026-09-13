const fs = require("fs");
const path = require("path");
const vm = require("vm");

const kernelPath = path.join(__dirname, "../catharsis/kernel/landlord.js");
const frontPath = path.join(__dirname, "frontend/js/landlord.js");
if (fs.readFileSync(kernelPath, "utf8") !== fs.readFileSync(frontPath, "utf8")) {
  throw new Error("frontend landlord.js drifted from kernel");
}

const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync(kernelPath, "utf8") +
    "\nglobalThis.testApi={LANDLORD,LANDLORD_CATALOG,LANDLORD_RELICS,neighborsOf,neighborsAll,settleGrid,place,placeAt,idx,isCorner,rentForFloor,meetRent,starterDeck,shopPool,pickShop,rawBase};",
  ctx,
);

const {
  LANDLORD,
  LANDLORD_CATALOG,
  neighborsOf,
  settleGrid,
  place,
  placeAt,
  isCorner,
  rentForFloor,
  meetRent,
  starterDeck,
  shopPool,
} = ctx.testApi;

function empty() {
  return new Array(LANDLORD.SIZE).fill(null);
}

if (LANDLORD.SIZE !== 20) throw new Error("size");
if (neighborsOf(0).length !== 2) throw new Error("corner neighbors");
if (neighborsOf(6).length !== 4) throw new Error("center neighbors");
if (!isCorner(0) || isCorner(6)) throw new Error("corner test");

const cat = LANDLORD_CATALOG;
let cells = empty();
cells[0] = "coffee";
cells[1] = "dev";
const combo = settleGrid(cells, cat);
if (combo.payout < 8) throw new Error("combo payout " + combo.payout);
if (!combo.events.includes("coffee-dev")) throw new Error("combo event");
if (!combo.links.some((l) => l.kind === "coffee-dev")) throw new Error("combo link");
if (!combo.cellMult || combo.cellMult[0] < 3) throw new Error("cellMult");

let g = empty();
g = place(g, "coffee");
if (!g || g[0] !== "coffee") throw new Error("place");
const placed = placeAt(empty(), "mute", 7);
if (!placed || placed[7] !== "mute") throw new Error("placeAt");
if (placeAt(placed, "dev", 7) !== null) throw new Error("placeAt occupied");
if (placeAt(empty(), "dev", 99) !== null) throw new Error("placeAt oob");

const intern = empty();
intern[0] = "intern";
intern[1] = "coffee";
const copied = settleGrid(intern, cat);
if (copied.payout !== 4) throw new Error("intern copy " + copied.payout);
if (!copied.events.includes("intern-copy")) throw new Error("intern-copy event");

const taxed = empty();
taxed[0] = "meeting";
taxed[1] = "intern";
const tax = settleGrid(taxed, cat);
if (tax.payout !== 3) throw new Error("meeting tax " + tax.payout);
if (!tax.events.includes("meeting-tax")) throw new Error("tax event");

const shielded = empty();
shielded[0] = "meeting";
shielded[1] = "intern";
shielded[2] = "mute";
const shield = settleGrid(shielded, cat);
if (shield.cellScore[1] <= tax.cellScore[1]) throw new Error("mute shield");
if (!shield.events.includes("mute-shield")) throw new Error("shield event");

const armyBoard = empty();
armyBoard[0] = "coffee";
armyBoard[1] = "dev";
armyBoard[5] = "intern";
const noArmy = settleGrid(armyBoard, cat, []);
const army = settleGrid(armyBoard, cat, ["army"]);
if (army.cellScore[5] <= noArmy.cellScore[5]) throw new Error("intern army " + army.cellScore[5] + " vs " + noArmy.cellScore[5]);
if (!army.events.includes("intern-army")) throw new Error("army event");

const vacant = settleGrid(empty(), cat, ["severance"]);
if (vacant.payout !== LANDLORD.SIZE) throw new Error("severance " + vacant.payout);

if (rentForFloor(1) !== 8) throw new Error("rent 1 " + rentForFloor(1));
if (rentForFloor(2) !== 11) throw new Error("rent 2 " + rentForFloor(2));
if (rentForFloor(1, ["glass"]) !== 9) throw new Error("glass rent " + rentForFloor(1, ["glass"]));
if (meetRent(7, 8)) throw new Error("rent fail should lose");
if (!meetRent(8, 8)) throw new Error("rent meet");

const deck = starterDeck();
if (deck.length < 8) throw new Error("starter deck");
if (shopPool(["severance"]).some((c) => c.kind === "relic" && c.id === "severance")) {
  throw new Error("owned relic still in shop");
}
const shop = ctx.testApi.pickShop([], LANDLORD_CATALOG, 3);
if (shop.length !== 3) throw new Error("shop size");
if (!shop.some((c) => c.kind === "relic")) throw new Error("shop missing relic");
const shopEmptyRelics = ctx.testApi.pickShop(["severance", "quiet", "pto", "glass", "badge", "army"], LANDLORD_CATALOG, 3);
if (shopEmptyRelics.some((c) => c.kind === "relic")) throw new Error("spent relics still offered");

const deadCorner = empty();
deadCorner[6] = "corner";
const dead = settleGrid(deadCorner, cat);
if (dead.payout !== 0) throw new Error("open-plan corner " + dead.payout);
const liveCorner = empty();
liveCorner[0] = "corner";
if (settleGrid(liveCorner, cat).payout !== 3) throw new Error("corner office");

console.log("office landlord settle ok", combo.payout);

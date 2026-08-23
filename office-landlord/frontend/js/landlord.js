const LANDLORD = {
  COLS: 5,
  ROWS: 4,
  SIZE: 20,
  FLOORS: 8,
  START_RENT: 8,
  RENT_GROWTH: 1.45,
};

const LANDLORD_CATALOG = [
  { id: "coffee", payout: 2, tag: "fuel" },
  { id: "dev", payout: 3, tag: "staff" },
  { id: "intern", payout: 1, tag: "staff" },
  { id: "meeting", payout: 2, tag: "noise" },
  { id: "mute", payout: 4, tag: "noise" },
  { id: "printer", payout: 2, tag: "infra" },
  { id: "standup", payout: 1, tag: "staff" },
  { id: "corner", payout: 3, tag: "infra" },
];

const LANDLORD_RELICS = [
  { id: "severance" },
  { id: "quiet" },
  { id: "pto" },
  { id: "glass" },
  { id: "badge" },
  { id: "army" },
];

const LANDLORD_STARTER = [
  "coffee", "coffee", "dev", "dev",
  "intern", "intern", "intern",
  "meeting", "mute", "printer",
];

function idx(x, y) {
  return y * LANDLORD.COLS + x;
}

function xyOf(i) {
  return { x: i % LANDLORD.COLS, y: Math.floor(i / LANDLORD.COLS) };
}

function isCorner(i) {
  const { x, y } = xyOf(i);
  return (x === 0 || x === LANDLORD.COLS - 1) && (y === 0 || y === LANDLORD.ROWS - 1);
}

function inBounds(x, y) {
  return x >= 0 && x < LANDLORD.COLS && y >= 0 && y < LANDLORD.ROWS;
}

function neighborsOf(i) {
  const { x, y } = xyOf(i);
  const out = [];
  [[1, 0], [-1, 0], [0, 1], [0, -1]].forEach(([dx, dy]) => {
    const nx = x + dx, ny = y + dy;
    if (inBounds(nx, ny)) out.push(idx(nx, ny));
  });
  return out;
}

function neighborsAll(i) {
  const { x, y } = xyOf(i);
  const out = [];
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      if (!dx && !dy) continue;
      const nx = x + dx, ny = y + dy;
      if (inBounds(nx, ny)) out.push(idx(nx, ny));
    }
  }
  return out;
}

function catalogById(catalog) {
  const byId = {};
  (catalog || LANDLORD_CATALOG).forEach((s) => { byId[s.id] = s; });
  return byId;
}

function rawBase(id, i, byId) {
  const s = byId[id];
  if (!s) return 1;
  if (id === "corner" && !isCorner(i)) return 0;
  return s.payout || 1;
}

function settleGrid(cells, catalog, relics) {
  const byId = catalogById(catalog);
  const relicSet = new Set(relics || []);
  const has = (id) => relicSet.has(id);
  const events = [];
  const links = [];
  const cellBase = new Array(LANDLORD.SIZE).fill(0);
  const cellAdd = new Array(LANDLORD.SIZE).fill(0);
  const cellMult = new Array(LANDLORD.SIZE).fill(1);
  const cellTax = new Array(LANDLORD.SIZE).fill(0);
  const shielded = new Array(LANDLORD.SIZE).fill(false);
  const staff = new Set(["dev", "intern", "standup"]);

  function note(kind, a, b) {
    events.push(kind);
    if (a != null && b != null) links.push({ a, b, kind });
  }

  cells.forEach((id, i) => {
    if (id !== "mute") return;
    const ring = has("quiet") ? neighborsAll(i) : neighborsOf(i);
    ring.forEach((n) => {
      const oid = cells[n];
      if (staff.has(oid)) {
        shielded[n] = true;
        note("mute-shield", i, n);
      }
    });
  });

  cells.forEach((id, i) => {
    if (!id) return;
    const s = byId[id] || { payout: 1, tags: [] };
    let base = rawBase(id, i, byId);
    if (id === "intern") {
      let best = s.payout || 1;
      let from = -1;
      neighborsOf(i).forEach((n) => {
        const oid = cells[n];
        if (!oid || oid === "intern") return;
        const ob = rawBase(oid, n, byId);
        if (ob > best) { best = ob; from = n; }
      });
      base = best;
      if (from >= 0) note("intern-copy", i, from);
    }
    if (id === "printer") {
      const y = Math.floor(i / LANDLORD.COLS);
      let extras = 0;
      for (let x = 0; x < LANDLORD.COLS; x++) {
        const j = idx(x, y);
        if (j !== i && cells[j]) extras += 1;
      }
      base += extras;
      if (extras) note("print-job", i, i);
    }
    cellBase[i] = base;
  });

  cells.forEach((id, i) => {
    if (!id) return;
    const s = byId[id];
    neighborsOf(i).forEach((n) => {
      const oid = cells[n];
      const other = byId[oid];
      if (!other) return;
      if (id === "coffee" && oid === "dev") {
        cellMult[i] *= 3;
        note("coffee-dev", i, n);
      }
      if (id === "dev" && oid === "coffee") {
        cellMult[i] *= 1;
      }
      if (id === "dev" && oid === "mute") {
        cellAdd[i] += 2;
        note("dev-mute", i, n);
      }
      if (s && s.tag && other.tag && s.tag === other.tag) {
        cellMult[i] *= 1.2;
        note("tag-" + s.tag, i, n);
      }
    });
    if (id === "standup") {
      neighborsOf(i).forEach((n) => {
        if (cells[n]) {
          cellAdd[n] += 1;
          note("standup-boost", i, n);
        }
      });
    }
  });

  if (!has("glass")) {
    cells.forEach((id, i) => {
      if (id !== "meeting") return;
      neighborsOf(i).forEach((n) => {
        const oid = cells[n];
        if ((oid === "intern" || oid === "dev") && !shielded[n]) {
          cellTax[n] += 1;
          note("meeting-tax", i, n);
        }
      });
    });
  }

  const cellScore = new Array(LANDLORD.SIZE).fill(0);
  cells.forEach((id, i) => {
    if (!id) {
      if (has("severance")) cellScore[i] = 1;
      return;
    }
    cellScore[i] = Math.floor(cellBase[i] * cellMult[i]) + cellAdd[i] - cellTax[i];
  });

  if (has("army")) {
    const pre = cellScore.slice();
    cells.forEach((id, i) => {
      if (id !== "intern") return;
      let best = pre[i];
      let from = -1;
      neighborsOf(i).forEach((n) => {
        if (cells[n] && cells[n] !== "intern" && pre[n] > best) {
          best = pre[n];
          from = n;
        }
      });
      cellScore[i] = best;
      if (from >= 0) note("intern-army", i, from);
    });
  }

  let payout = cellScore.reduce((a, b) => a + b, 0);
  if (has("badge")) {
    const chain = events.filter((e) => e !== "meeting-tax").length;
    payout += chain;
  }

  return { payout, events, cellScore, cellMult, cellBase, links };
}

function place(cells, id) {
  const empty = cells.findIndex((c) => !c);
  if (empty < 0) return null;
  return placeAt(cells, id, empty);
}

function placeAt(cells, id, index) {
  const i = index | 0;
  if (!id || i < 0 || i >= LANDLORD.SIZE) return null;
  if (cells[i]) return null;
  const next = cells.slice();
  next[i] = id;
  return next;
}

function rentForFloor(floor, relics) {
  const f = Math.max(1, floor | 0);
  let rent = Math.floor(LANDLORD.START_RENT * Math.pow(LANDLORD.RENT_GROWTH, f - 1));
  if ((relics || []).indexOf("glass") >= 0) rent = Math.ceil(rent * 1.1);
  return rent;
}

function meetRent(payout, rent) {
  return (payout | 0) >= (rent | 0);
}

function starterDeck() {
  return LANDLORD_STARTER.slice();
}

function rollFrom(deck, n) {
  const src = deck && deck.length ? deck : LANDLORD_STARTER;
  const out = [];
  const count = Math.max(1, n | 0);
  for (let i = 0; i < count; i++) {
    out.push(src[Math.floor(Math.random() * src.length)]);
  }
  return out;
}

function shopPool(ownedRelics, catalog) {
  const have = new Set(ownedRelics || []);
  const relics = LANDLORD_RELICS.filter((r) => !have.has(r.id)).map((r) => ({ kind: "relic", id: r.id }));
  const symbols = (catalog || LANDLORD_CATALOG).map((s) => ({ kind: "symbol", id: s.id }));
  return relics.concat(symbols);
}

function pickShop(ownedRelics, catalog, count) {
  const n = Math.max(1, count | 0);
  const relics = LANDLORD_RELICS
    .filter((r) => (ownedRelics || []).indexOf(r.id) < 0)
    .map((r) => ({ kind: "relic", id: r.id }));
  const symbols = (catalog || LANDLORD_CATALOG).map((s) => ({ kind: "symbol", id: s.id }));
  const out = [];
  if (relics.length) {
    const pick = relics[Math.floor(Math.random() * relics.length)];
    out.push(pick);
  }
  const bag = relics.concat(symbols).filter((c) => !out.some((o) => o.kind === c.kind && o.id === c.id));
  while (out.length < n && bag.length) {
    const i = Math.floor(Math.random() * bag.length);
    out.push(bag.splice(i, 1)[0]);
  }
  return out;
}

// Kill condition, design §8: "if a player with a random layout earns within 20% of a player
// with a six-link chain, the skill layer is decoration." This measures it.
//
//   node tests/kill_condition.cjs            report at the shipped CHAIN_K
//   node tests/kill_condition.cjs --sweep    the same table for a range of CHAIN_K
//
// Random layout: N pieces (N ~ 6..12) drawn from the parent's starter deck, dropped on random
// cells, no relics — what a player who does not read the rules ends up with. The chain
// board: the best six-plus-link board a hill-climb finds with the same starter deck and the
// same piece budget (launch catalogue only, no gacha, no relics), so the gap is the board.
const { load } = require("./harness.cjs");
const A = load();
const SIZE = A.LANDLORD.SIZE;
const DECK = A.LANDLORD_STARTER;

function rng(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function randomLayout(r, n) {
  const cells = new Array(SIZE).fill(null);
  const idxs = Array.from({ length: SIZE }, (_, i) => i).sort(() => r() - 0.5).slice(0, n);
  idxs.forEach((i) => { cells[i] = DECK[Math.floor(r() * DECK.length)]; });
  return cells;
}
function score(cells, K) { return A.settleIdleK(cells, [], null, K); }

// Hill-climb for the best chain board under a piece budget.
function bestChain(r, budget, K, iters) {
  let cells = randomLayout(r, budget), best = score(cells, K);
  for (let k = 0; k < iters; k++) {
    const next = cells.slice();
    const i = Math.floor(r() * SIZE);
    const op = r();
    if (op < 0.4) next[i] = DECK[Math.floor(r() * DECK.length)];
    else if (op < 0.7) { const j = Math.floor(r() * SIZE); const t = next[i]; next[i] = next[j]; next[j] = t; }
    else next[i] = null;
    if (next.filter(Boolean).length > budget) continue;
    const s = score(next, K);
    if (s.shift >= best.shift) { cells = next; best = s; }
  }
  return { cells, r: best };
}

// The design's literal bar: a SIX-link chain. Same budget for both sides (6 pieces), so the
// only difference between the two players is where they put them.
function sixLink(K) {
  const r = rng(99);
  let top = null;
  for (let s = 0; s < 8; s++) {
    let cells = randomLayout(r, 6), best = score(cells, K);
    for (let k = 0; k < 4000; k++) {
      const next = cells.slice(); const i = Math.floor(r() * SIZE); const op = r();
      if (op < 0.4) next[i] = DECK[Math.floor(r() * DECK.length)];
      else if (op < 0.7) { const j = Math.floor(r() * SIZE); const t = next[i]; next[i] = next[j]; next[j] = t; }
      else next[i] = null;
      if (next.filter(Boolean).length > 6) continue;
      const sc = score(next, K);
      const okChain = sc.chain >= 6 && sc.chain <= 7;
      if ((okChain && (!(best.chain >= 6 && best.chain <= 7) || sc.shift >= best.shift)) || (!okChain && !(best.chain >= 6 && best.chain <= 7) && sc.chain >= best.chain)) { cells = next; best = sc; }
    }
    if (best.chain >= 6 && (!top || best.shift > top.r.shift)) top = { cells, r: best };
  }
  const rand = [];
  for (let i = 0; i < 500; i++) rand.push(score(randomLayout(r, 6), K).shift);
  rand.sort((a, b) => a - b);
  const mean = rand.reduce((a, b) => a + b, 0) / rand.length;
  return { cells: top.cells, chain: top.r.chain, shift: top.r.shift, payout: top.r.payout, randMean: +mean.toFixed(1), randP90: rand[450], ratioMean: +(mean / top.r.shift).toFixed(3), ratioP90: +(rand[450] / top.r.shift).toFixed(3) };
}

function run(K, quiet) {
  const r = rng(20260918);
  const rand = [];
  for (let i = 0; i < 500; i++) {
    const n = 6 + Math.floor(r() * 7);
    rand.push(score(randomLayout(r, n), K).shift);
  }
  rand.sort((a, b) => a - b);
  const mean = rand.reduce((a, b) => a + b, 0) / rand.length;
  const p50 = rand[250], p90 = rand[450], max = rand[499];
  let top = null;
  for (let s = 0; s < 6; s++) {
    const c = bestChain(rng(7 + s), 10, K, 6000);
    if (!top || c.r.shift > top.r.shift) top = c;
  }
  const chainShift = top.r.shift;
  const out = { K, chain: top.r.chain, chainShift, randMean: +mean.toFixed(1), randP50: p50, randP90: p90, randMax: max,
    ratioMean: +(mean / chainShift).toFixed(3), ratioP90: +(p90 / chainShift).toFixed(3), ratioMax: +(max / chainShift).toFixed(3) };
  const six = sixLink(K);
  Object.assign(out, { six: six.shift, sixChain: six.chain, sixRatioMean: six.ratioMean, sixRatioP90: six.ratioP90 });
  if (!quiet) {
    console.log("six-link chain board (" + six.chain + " links, payout " + six.payout + " -> " + six.shift + "/shift, " + six.shift * 6 + "/h) vs random six-piece layouts: mean " + six.randMean + " (" + Math.round(six.ratioMean * 100) + "%), p90 " + six.randP90 + " (" + Math.round(six.ratioP90 * 100) + "%)");
    for (let y = 0; y < 4; y++) console.log("   " + six.cells.slice(y * 5, y * 5 + 5).map((c) => (c || "·").padEnd(8)).join(""));
    console.log("best chain board (" + top.r.chain + " links, payout " + top.r.payout + " x" + top.r.mult.toFixed(2) + " = " + chainShift + "/shift, " + chainShift * 6 + "/h):");
    for (let y = 0; y < 4; y++) console.log("   " + top.cells.slice(y * 5, y * 5 + 5).map((c) => (c || "·").padEnd(8)).join(""));
  }
  return out;
}

if (process.argv.includes("--sweep")) {
  console.log("K      chain  chain/shift  rand mean  rand p90  rand max  mean/chain  p90/chain  max/chain | six-link/shift  rand6 mean%  rand6 p90%");
  [0, 0.1, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5].forEach((K) => {
    const o = run(K, true);
    console.log(String(K).padEnd(7) + String(o.chain).padEnd(7) + String(o.chainShift).padEnd(13) + String(o.randMean).padEnd(11) + String(o.randP90).padEnd(10) + String(o.randMax).padEnd(10) + String(o.ratioMean).padEnd(12) + String(o.ratioP90).padEnd(11) + String(o.ratioMax).padEnd(10) + "| " + String(o.six).padEnd(16) + String(Math.round(o.sixRatioMean * 100)).padEnd(13) + Math.round(o.sixRatioP90 * 100));
  });
} else {
  const o = run(A.CHAIN_K, false);
  console.log(JSON.stringify(o));
  const pass = o.ratioMean < 0.8 && o.ratioP90 < 0.8 && o.sixRatioMean < 0.8 && o.sixRatioP90 < 0.8;
  console.log(pass ? "KILL CONDITION CLEARED: random layouts earn " + Math.round(o.ratioMean * 100) + "% (mean) / " + Math.round(o.ratioP90 * 100) + "% (p90) of the chain board"
                   : "KILL CONDITION FAILED: random layouts earn " + Math.round(o.ratioMean * 100) + "% (mean) / " + Math.round(o.ratioP90 * 100) + "% (p90) of the chain board");
  process.exit(pass ? 0 : 1);
}

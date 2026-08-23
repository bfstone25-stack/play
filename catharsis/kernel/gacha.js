/* Cosmetic / flavor pulls. Pity 10. Core loop must remain free. */
const Gacha = (() => {
  const RARITIES = ["N", "R", "SR", "SSR"];
  const WEIGHTS = { N: 70, R: 22, SR: 7, SSR: 1 };
  const PITY = 10;
  const PULL_COST = 50;

  const inventory = [];
  let pity = 0;
  let pulls = 0;

  function rollRarity(rng, forceHigh) {
    if (forceHigh) return pity % 30 === 0 && pity > 0 ? "SSR" : "SR";
    const n = rng();
    let acc = 0;
    const total = WEIGHTS.N + WEIGHTS.R + WEIGHTS.SR + WEIGHTS.SSR;
    const thresholds = [
      ["N", WEIGHTS.N],
      ["R", WEIGHTS.R],
      ["SR", WEIGHTS.SR],
      ["SSR", WEIGHTS.SSR],
    ];
    for (const [name, w] of thresholds) {
      acc += w / total;
      if (n < acc) return name;
    }
    return "N";
  }

  function pull(pool, rng) {
    rng = rng || Math.random;
    pool = pool && pool.length ? pool : [{ id: "default", rarity: "N" }];
    pity += 1;
    pulls += 1;
    const force = pity >= PITY;
    const rarity = rollRarity(rng, force);
    const candidates = pool.filter(p => p.rarity === rarity);
    const fallback = pool.filter(p => RARITIES.indexOf(p.rarity) <= RARITIES.indexOf(rarity));
    const bag = candidates.length ? candidates : (fallback.length ? fallback : pool);
    const item = bag[Math.floor(rng() * bag.length) % bag.length];
    const got = { ...item, rarity: item.rarity || rarity, at: pulls };
    if (got.rarity === "SR" || got.rarity === "SSR" || force) pity = 0;
    inventory.push(got);
    return got;
  }

  function snapshot() {
    return { pity, pulls, inventory: inventory.slice() };
  }

  function load(data) {
    pity = Math.max(0, Math.floor((data && data.pity) || 0));
    pulls = Math.max(0, Math.floor((data && data.pulls) || 0));
    inventory.length = 0;
    if (data && Array.isArray(data.inventory)) {
      data.inventory.forEach(x => inventory.push(x));
    }
    return snapshot();
  }

  return { pull, snapshot, load, PITY, PULL_COST, RARITIES, WEIGHTS };
})();

/* economy.js — Gold ledger, gacha with pity, affection counters, idempotent SKU grants.
 *
 * // swap for shared/economy.py
 * This is the client-side stand-in for the server-side economy a sibling agent owns
 * (shared/economy.py: Gold / energy / gacha / affection with idempotent SKU grants keyed by
 * transaction id). The interface below is the one the game code calls; when the server
 * lands, every method here becomes a fetch to the same-named endpoint and the localStorage
 * blob goes away. Nothing in game.js should reach into `state` directly — go through the
 * methods, so the swap is a transport change and not a rewrite.
 *
 * An idle game with Gold in it cannot trust the client's clock or bank (design §7); this
 * prototype does, on purpose, and says so here.
 */
const Economy = (() => {
  const KEY = "overtime-idle.economy.v1";
  const H = 3600e3;

  // SKUs from ops/adult_forks/overtime_idle.md §5. `gold` is the price in Gold; `iap` SKUs
  // are bought with money and *grant* Gold. `scene_skip_<name>` is matched by prefix.
  const SKUS = {
    timeskip_4h:     { gold: 40,  en: "Collect four hours of shifts now",   zh: "立刻收取四小时的班次",       effect: (s) => { s.timeskipMs += 4 * H; } },
    offline_cap_24h: { gold: 120, en: "Offline earnings cap 8h → 24h, forever", zh: "离线收益上限 8→24 小时，永久", once: true, effect: (s) => { s.offlineCap24 = true; } },
    pull_1:          { gold: 30,  en: "One pull",                          zh: "单抽",                        effect: (s) => { s.tickets += 1; } },
    pull_10:         { gold: 270, en: "Ten pulls",                         zh: "十连",                        effect: (s) => { s.tickets += 10; } },
    rent_shield:     { gold: 50,  en: "Skip one eviction",                  zh: "免除一次清退",                 effect: (s) => { s.shields += 1; } },
    gold_s:          { iap: "$0.99", grants: 100,  en: "100 Gold",  zh: "100 金币",  effect: (s) => { s.gold += 100; } },
    gold_m:          { iap: "$4.99", grants: 600,  en: "600 Gold",  zh: "600 金币",  effect: (s) => { s.gold += 600; } },
    gold_l:          { iap: "$19.99", grants: 3000, en: "3000 Gold", zh: "3000 金币", effect: (s) => { s.gold += 3000; } },
  };
  const SCENE_SKIP_GOLD = 80;

  function fresh() {
    const owned = {}, dupes = {}, affection = {};
    IDLE_ROSTER.forEach((p) => { owned[p.id] = p.launch ? 1 : 0; dupes[p.id] = 0; affection[p.id] = 0; });
    return { gold: 0, tickets: 0, pulls: 0, sinceEpic: 0, owned, dupes, affection, shields: 0, offlineCap24: false,
             timeskipMs: 0, grants: {}, sceneSkips: {}, txn: 0, ledger: [] };
  }
  let state = fresh();
  try { Object.assign(state, JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (_) {}
  // new roster rows since the save was written
  IDLE_ROSTER.forEach((p) => { if (state.owned[p.id] == null) { state.owned[p.id] = p.launch ? 1 : 0; state.dupes[p.id] = 0; state.affection[p.id] = 0; } });

  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (_) {} }
  function log(kind, meta) { state.ledger.push(Object.assign({ t: Date.now(), kind }, meta)); if (state.ledger.length > 200) state.ledger.shift(); }

  function skuOf(sku) {
    if (SKUS[sku]) return SKUS[sku];
    if (/^scene_skip_/.test(sku)) {
      const who = sku.slice("scene_skip_".length);
      return { gold: SCENE_SKIP_GOLD, en: "See the scene now", zh: "现在看这场戏", once: true, effect: (s) => { s.sceneSkips[who] = true; } };
    }
    return null;
  }

  /* grant(sku, txId): apply a SKU's effect exactly once per transaction id. This is the call
   * the GPHS PUT (gateway/nutaku.py) will make server-side; the same txId twice is a no-op. */
  function grant(sku, txId) {
    const def = skuOf(sku);
    if (!def) return { ok: false, why: "unknown_sku" };
    if (txId && state.grants[txId]) return { ok: false, why: "duplicate", sku: state.grants[txId] };
    if (def.once && isOwned(sku)) return { ok: false, why: "already_owned" };
    def.effect(state);
    if (txId) state.grants[txId] = sku;
    log("grant", { sku, txId });
    save();
    return { ok: true, sku };
  }
  function isOwned(sku) {
    if (sku === "offline_cap_24h") return !!state.offlineCap24;
    if (/^scene_skip_/.test(sku)) return !!state.sceneSkips[sku.slice("scene_skip_".length)];
    return false;
  }
  /* buy(sku): spend Gold on a Gold-priced SKU. IAP SKUs go through the store, not here. */
  function buy(sku) {
    const def = skuOf(sku);
    if (!def) return { ok: false, why: "unknown_sku" };
    if (def.iap) return { ok: false, why: "iap_only" };
    if (def.once && isOwned(sku)) return { ok: false, why: "already_owned" };
    if (state.gold < def.gold) return { ok: false, why: "gold", need: def.gold - state.gold };
    state.gold -= def.gold;
    state.txn += 1;
    const r = grant(sku, "local-" + state.txn);
    if (!r.ok) { state.gold += def.gold; save(); }
    return r;
  }
  /* Store purchase of an IAP SKU. The prototype's dev button and the mocked store call
   * this; on Nutaku the GPHS PUT calls grant() with the platform's transaction id. */
  function purchase(sku, txId) {
    const def = skuOf(sku);
    if (!def || !def.iap) return { ok: false, why: "not_iap" };
    return grant(sku, txId || ("iap-" + (++state.txn)));
  }

  // ---- gacha -------------------------------------------------------------------------
  function rollRarity(rng) {
    if (state.sinceEpic >= IDLE_PITY - 1) return "epic";
    const x = rng() * 100;
    if (x < IDLE_RARITY.epic) return "epic";
    if (x < IDLE_RARITY.epic + IDLE_RARITY.rare) return "rare";
    return "common";
  }
  /* pull(n, rng): consumes n tickets; returns [{id, rarity, dupe, dupes}]. */
  function pull(n, rng) {
    rng = rng || Math.random;
    n = Math.max(1, n | 0);
    if (state.tickets < n) return { ok: false, why: "tickets", need: n - state.tickets };
    state.tickets -= n;
    const out = [];
    for (let i = 0; i < n; i++) {
      const rarity = rollRarity(rng);
      const pool = rosterPool(rarity);
      const id = pool[Math.floor(rng() * pool.length)];
      state.pulls += 1;
      state.sinceEpic = rarity === "epic" ? 0 : state.sinceEpic + 1;
      const dupe = state.owned[id] > 0;
      state.owned[id] += 1;
      if (dupe) state.dupes[id] += 1;
      out.push({ id, rarity, dupe, dupes: state.dupes[id] });
    }
    log("pull", { n, ids: out.map((o) => o.id) });
    save();
    return { ok: true, results: out };
  }

  // ---- affection ---------------------------------------------------------------------
  const AFF_TIERS = [20, 60, 150, 300];
  function addShifts(id, n) { if (state.affection[id] == null) state.affection[id] = 0; state.affection[id] += n; }
  function affectionTier(id) { const a = state.affection[id] || 0; let t = 0; AFF_TIERS.forEach((x) => { if (a >= x) t += 1; }); return t; }
  function canSeeScene(id) { return affectionTier(id) >= 4 || (affectionTier(id) >= 3 && !!state.sceneSkips[id]); }

  return {
    SKUS, AFF_TIERS, skuOf, grant, buy, purchase, pull, isOwned,
    gold: () => state.gold, tickets: () => state.tickets, pulls: () => state.pulls, sinceEpic: () => state.sinceEpic,
    owned: (id) => state.owned[id] | 0, dupes: (id) => state.dupes[id] | 0, dupeMap: () => Object.assign({}, state.dupes),
    affection: (id) => state.affection[id] | 0, affectionTier, canSeeScene, addShifts,
    shields: () => state.shields, useShield: () => { if (state.shields <= 0) return false; state.shields -= 1; log("shield", {}); save(); return true; },
    offlineCapMs: () => (state.offlineCap24 ? 24 : 8) * H,
    takeTimeskip: () => { const ms = state.timeskipMs; state.timeskipMs = 0; save(); return ms; },
    devAddGold: (n) => { state.gold += n | 0; log("dev_gold", { n }); save(); },
    save, reset: () => { state = fresh(); save(); }, ledger: () => state.ledger.slice(),
    _state: () => state,
  };
})();
if (typeof module !== "undefined") module.exports = Economy;

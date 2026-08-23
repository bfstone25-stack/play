/* localStorage schema v1. Node tests inject a memory store. */
const Save = (() => {
  const KEY = "blazecore.catharsis.v1";
  let memory = null;

  function store() {
    if (memory) return memory;
    try {
      if (typeof localStorage !== "undefined") return localStorage;
    } catch (e) { /* private mode */ }
    memory = {
      _d: {},
      getItem(k) { return this._d[k] || null; },
      setItem(k, v) { this._d[k] = String(v); },
    };
    return memory;
  }

  function load() {
    try {
      const raw = store().getItem(KEY);
      if (!raw) return { schema: 1 };
      const data = JSON.parse(raw);
      if (data.economy) Economy.load(data.economy);
      if (data.gacha) Gacha.load(data.gacha);
      return data;
    } catch (e) {
      return { schema: 1 };
    }
  }

  function persist(extra) {
    const data = {
      schema: 1,
      economy: Economy.snapshot(),
      gacha: Gacha.snapshot(),
      commerce: Commerce.snapshot(),
      ...(extra || {}),
    };
    store().setItem(KEY, JSON.stringify(data));
    return data;
  }

  function useMemory(map) {
    memory = map || {
      _d: {},
      getItem(k) { return this._d[k] || null; },
      setItem(k, v) { this._d[k] = String(v); },
    };
  }

  return { load, persist, useMemory, KEY };
})();

const Save = (() => {
  const KEY = "blazecore.cybermerit.v1";
  const OLD = "blazecore.catharsis.v1";
  let memory = null;

  function store() {
    if (memory) return memory;
    try {
      if (typeof localStorage !== "undefined") return localStorage;
    } catch (e) { /* private */ }
    memory = {
      _d: {},
      getItem(k) { return this._d[k] || null; },
      setItem(k, v) { this._d[k] = String(v); },
    };
    return memory;
  }

  function useMemory(map) {
    memory = map || {
      _d: {},
      getItem(k) { return this._d[k] || null; },
      setItem(k, v) { this._d[k] = String(v); },
    };
  }

  function parse(raw) {
    try { return raw ? JSON.parse(raw) : null; } catch (e) { return null; }
  }

  function migrate() {
    const cur = parse(store().getItem(KEY));
    if (cur && cur.schema === 1) return cur;
    const old = parse(store().getItem(OLD));
    const merit = old && old.merit ? old.merit : null;
    return {
      schema: 1,
      merit: merit ? {
        merit: merit.merit || 0,
        clicks: merit.clicks || 0,
        level: merit.level || 1,
      } : null,
    };
  }

  function load() {
    return migrate() || { schema: 1 };
  }

  function persist(data) {
    const next = { schema: 1, ...(data || {}) };
    store().setItem(KEY, JSON.stringify(next));
    return next;
  }

  return { load, persist, useMemory, KEY, OLD };
})();

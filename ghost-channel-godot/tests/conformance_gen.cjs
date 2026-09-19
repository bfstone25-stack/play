// JS side of the JS<->GDScript conformance test.
//
//   node tests/conformance_gen.cjs        -> tests/conformance.json
//
// Runs the prototype's real game.js (play/ghost-channel/) — not a copy of its rules —
// under a stub DOM, with Math.random replaced by a seeded LCG, and drives 300 seeded
// games through the same buttons a player presses (op card, A / D / Q, the naming
// buttons) with a policy drawn from a second, independent LCG. Between actions the
// one-second ticker is advanced by hand. Every action is recorded with the full state
// after it (book, agents, the request on the air with its tells and phrase, score, time,
// stats, the log, the telemetry payloads). tests/run_tests.gd replays the same actions
// through the GDScript port and asserts every snapshot is identical.
const fs = require("fs"), path = require("path"), vm = require("vm");
const PROTO = path.join(__dirname, "../../ghost-channel");

const VIEW_ONLY = new Set(["screen", "layout", "lang", "hotstart"]);

function lcg(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

function makeDom() {
  const ctx = new Proxy({}, { get: (_, k) => (k === "canvas" ? {} : () => {}), set: () => true });
  const els = new Proxy({}, { get: (t, k) => (typeof k === "string" ? (t[k] || (t[k] = el(k))) : t[k]) });
  function el(id) {
    const e = {
      id, attrs: {}, children: [], _cls: new Set(), textContent: "", _html: "", style: {}, dataset: {}, hidden: false, disabled: false,
      onclick: null, width: 0, height: 0,
      classList: { add: (c) => e._cls.add(c), remove: (c) => e._cls.delete(c), toggle: (c, v) => { if (v === undefined) v = !e._cls.has(c); v ? e._cls.add(c) : e._cls.delete(c); }, contains: (c) => e._cls.has(c) },
      appendChild: (c) => { e.children.push(c); return c; }, prepend: (c) => { e.children.unshift(c); return c; },
      querySelector: () => el("__canvas"), getContext: () => ctx, addEventListener: () => {}, getAttribute: (n) => e.attrs[n] || (n === "data-back" ? e.dataset.back : null),
      setAttribute: (n, v) => { e.attrs[n] = v; },
    };
    Object.defineProperty(e, "innerHTML", { get: () => e._html, set: (v) => { e._html = v; e.children = []; } });
    Object.defineProperty(e, "className", { get: () => [...e._cls].join(" "), set: (v) => { e._cls = new Set(String(v).split(/\s+/).filter(Boolean)); } });
    return e;
  }
  const document = {
    getElementById: (id) => els[id] || (els[id] = el(id)),
    createElement: (tag) => el("<" + tag + ">"),
    querySelector: (sel) => (els[sel] || (els[sel] = el(sel))),
    querySelectorAll: () => [],
    documentElement: { lang: "en" }, title: "",
  };
  const timers = { intervals: [], timeouts: [] };
  const store = {};
  const tel = [];
  const window = {
    innerWidth: 1280, innerHeight: 800,
    addEventListener: () => {},
    // The view's own telemetry ("screen", "layout", "lang", "hotstart") is emitted by
    // whatever is drawing — the DOM page there, the Godot scenes here — and is not part
    // of the rules under test. The rules' own events (play / q / radio / naming /
    // win / lose) are compared verbatim, payload by payload.
    TEL: { ev: (n, v) => { if (!VIEW_ONLY.has(n)) tel.push({ name: n, value: v }); } },
    localStorage: { getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: (k) => { delete store[k]; } },
    setInterval: (fn) => { timers.intervals.push(fn); return timers.intervals.length; },
    clearInterval: (id) => { if (id) timers.intervals[id - 1] = null; },
    setTimeout: (fn, ms) => { timers.timeouts.push({ fn, ms }); return timers.timeouts.length; },
    clearTimeout: () => {},
    requestAnimationFrame: () => 1, cancelAnimationFrame: () => {},
    navigator: { language: "en" },
  };
  window.window = window;
  window.document = document;
  window.localStorage = window.localStorage;
  return { window, document, els, timers, tel };
}

function boot(seed) {
  const dom = makeDom();
  const sandbox = Object.assign(Object.create(null), dom.window, {
    document: dom.document, localStorage: dom.window.localStorage, navigator: dom.window.navigator,
    console, Math: Object.create(Math),
  });
  sandbox.window = sandbox;
  sandbox.Math.random = lcg(seed);
  sandbox.GCAudio = new Proxy({}, { get: () => () => {} });
  vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(PROTO, "i18n.js"), "utf8"), sandbox);
  vm.runInContext(fs.readFileSync(path.join(PROTO, "game.js"), "utf8"), sandbox);
  return { dom, sandbox };
}

// The prototype keeps its state in a closure; the stub DOM is the window onto it. What the
// player would see on the HUD, the incoming panel and the log is what gets compared.
function strip(h) { return String(h).replace(/<[^>]+>/g, ""); }
function snapshot(dom) {
  const els = dom.els;
  const inc = els["incoming"];
  const roster = els["roster"].children.map((b) => {
    const nm = /class="nm"[^>]*>([^<]*)</.exec(b._html), st = /class="st">([^<]*)</.exec(b._html);
    return [b.className, nm ? nm[1] : "", st ? st[1] : ""];
  });
  const stats = [];
  els["end-stats"]._html.replace(/<div>([^<]*)<b>([^<]*)<\/b><\/div>/g, (_, k, v) => { stats.push([k, v]); return ""; });
  return {
    who: els["inc-who"].textContent, type: els["inc-type"].textContent, body: els["inc-body"].textContent, extra: els["inc-extra"].textContent,
    locked: inc._cls.has("locked"), naming: inc._cls.has("naming"),
    nameBtns: els["name-acts"].hidden ? [] : els["name-acts"].children.map((b) => [b.textContent, b.disabled]),
    time: els["hud-time"].textContent, ff: els["hud-ff"].textContent, score: els["hud-score"].textContent,
    codebook: els["codebook"].textContent, note: els["code-note"].textContent,
    opName: els["op-name"].textContent,
    log: els["log"].children.map((r) => [r.className.replace("log-row", "").trim(), strip(r._html)]),
    roster,
    end: els["end-title"].textContent ? { title: els["end-title"].textContent, lead: els["end-lead"].textContent, stats } : null,
    tel: dom.tel.length,
  };
}

function play(seed, opIndex, policySeed) {
  const dom0 = makeDom();
  const store = { "gc-wins": opIndex > 0 ? "3" : "0", "gc-best": opIndex > 0 ? JSON.stringify({ op1: 100, op2: 100, op3: 0 }) : "{}" };
  const sandbox = Object.assign(Object.create(null), dom0.window, {
    document: dom0.document, navigator: dom0.window.navigator, console, Math: Object.create(Math),
    localStorage: { getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: (k) => { delete store[k]; } },
  });
  sandbox.window = sandbox;
  sandbox.Math.random = lcg(seed);
  sandbox.GCAudio = new Proxy({}, { get: () => () => {} });
  vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(PROTO, "i18n.js"), "utf8"), sandbox);
  vm.runInContext(fs.readFileSync(path.join(PROTO, "game.js"), "utf8"), sandbox);
  const els = dom0.els, dom = dom0, pr = lcg(policySeed);
  const flush = () => { dom.timers.timeouts.splice(0).forEach((x) => { if (x.ms === 650) x.fn(); }); };
  const tick = (n) => { for (let i = 0; i < n; i++) dom.timers.intervals.forEach((fn) => fn && fn()); };
  const actions = [], snaps = [];
  const rec = (a) => { actions.push(a); snaps.push(snapshot(dom)); };
  dom.timers.timeouts.splice(0);
  els["btn-start"].onclick();
  if (opIndex > 0) {
    // returning player: the ops screen; press the card
    const card = els["op-list"].children[opIndex];
    if (card.disabled) throw new Error("op " + (opIndex + 1) + " locked");
    card.onclick();
  }
  flush();
  rec({ a: "start", op: opIndex + 1 });
  let guard = 0;
  while (!els["end-title"].textContent && guard++ < 200) {
    const naming = els["incoming"]._cls.has("naming");
    const r = pr();
    const n = r < 0.03 ? 400 : Math.floor(pr() * 7);
    if (n) { tick(n); rec({ a: "tick", n }); }
    if (els["end-title"].textContent) break;
    if (naming) {
      const btns = els["name-acts"].children.filter((b) => !b.disabled);
      const ghostBtn = btns[Math.floor(pr() * btns.length)];
      const idx = els["name-acts"].children.indexOf(ghostBtn);
      ghostBtn.onclick();
      rec({ a: "name", idx });
      continue;
    }
    const c = pr();
    if (c < 0.28) { els["btn-q"].onclick(); rec({ a: "q" }); if (pr() < 0.15) { els["btn-q"].onclick(); rec({ a: "q" }); } }
    const d = pr();
    if (d < 0.55) els["btn-auth"].onclick(); else els["btn-deny"].onclick();
    flush();
    rec({ a: d < 0.55 ? "auth" : "deny" });
  }
  return { seed, op: opIndex + 1, actions, snaps, tel: dom.tel, save: { wins: store["gc-wins"], best: JSON.parse(store["gc-best"]) } };
}

const games = [];
for (let g = 0; g < 300; g++) games.push(play(1000 + g, g % 3, 5000 + g));
const wins = games.filter((x) => x.tel.some((e) => e.name === "win")).length;
const reasons = {};
games.forEach((x) => { const e = x.tel.find((t) => t.name === "win" || t.name === "lose"); const k = e ? e.name + ":" + e.value.reason : "none"; reasons[k] = (reasons[k] || 0) + 1; });
fs.writeFileSync(path.join(__dirname, "conformance.json"), JSON.stringify({ games }));
console.log("conformance.json: " + games.length + " games, " + wins + " wins; " + JSON.stringify(reasons));

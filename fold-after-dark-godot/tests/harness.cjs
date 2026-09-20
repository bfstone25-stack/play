/* harness.cjs — run the SHIPPED FOLD JavaScript, unmodified, in Node.
 *
 * The rule for a conformance test is that the JS side must be the real thing, not a
 * paraphrase of it. FOLD has no module: its rules live in one inline <script> inside
 * play/fold/frontend/index.html (the live build — the one at free.blazecore.dev/fold/,
 * not the older play/fold/index.html beside it). So this file lifts that exact script
 * block out of the page by text, stubs the browser around it, and evaluates it.
 *
 * Nothing in the block is edited. Everything it reaches for — document, localStorage,
 * fetch, AudioContext, navigator, TEL, Gate, BOARD — is stubbed here, so if a future
 * edit to the page starts touching something new the harness throws instead of quietly
 * diverging.
 *
 *   const { load } = require("./harness.cjs");
 *   const A = load();            // fresh sandbox, levels.json loaded
 *   A.loadLevel(0); A.move(0, 1); A.state();
 */
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const GAME = path.join(__dirname, "../../fold/frontend");

function scriptBlock(html) {
  // the game block is the inline <script> that declares LEVELS
  const re = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;
  let m;
  while ((m = re.exec(html))) {
    if (/let LEVELS\s*=/.test(m[1])) return m[1];
  }
  throw new Error("harness: no inline <script> in index.html declares LEVELS");
}

/* A DOM element stub wide enough for the block: it sets textContent/innerHTML, reads
 * clientWidth, appends children, queries for .tile, and toggles classes. None of that
 * affects a rule, but all of it has to not throw. */
function el() {
  const e = {
    style: { cssText: "", display: "", transition: "", transform: "", color: "",
             setProperty() {}, removeProperty() {} },
    dataset: {},
    textContent: "",
    innerHTML: "",
    clientWidth: 420,
    open: false,
    children: [],
    classList: { add() {}, remove() {}, toggle() {}, contains: () => false },
    appendChild(c) { e.children.push(c); return c; },
    remove() {},
    addEventListener() {},
    setAttribute() {},
    querySelectorAll: () => [],
    closest: () => null,
  };
  return e;
}

function sandbox() {
  const store = Object.create(null);
  const nodes = Object.create(null);
  const doc = {
    documentElement: { lang: "en" },
    title: "",
    getElementById(id) { return (nodes[id] = nodes[id] || el()); },
    querySelector: () => null,
    querySelectorAll: () => [],
    createElement: () => el(),
    addEventListener() {},
    body: el(),
    head: el(),
    hidden: false,
  };
  const audioNode = () => ({
    gain: { value: 0, setValueAtTime() {}, exponentialRampToValueAtTime() {} },
    frequency: { value: 0, setValueAtTime() {}, exponentialRampToValueAtTime() {} },
    type: "", Q: { value: 0 },
    connect() {}, disconnect() {}, start() {}, stop() {},
  });
  const ctx = {
    currentTime: 0, state: "running", destination: {},
    createGain: audioNode, createOscillator: audioNode, createBiquadFilter: audioNode,
    resume() {}, suspend() {},
  };
  const win = {
    APP_API: "", TEL: null, Gate: null, BOARD: null, PROMO: null,
    AudioContext: function () { return ctx; },
    localStorage: {
      getItem: (k) => (k in store ? store[k] : null),
      setItem: (k, v) => { store[k] = String(v); },
      removeItem: (k) => { delete store[k]; },
    },
    navigator: { language: "en-US" },
    location: { hostname: "127.0.0.1" },
    document: doc,
    addEventListener() {},
    requestAnimationFrame(f) { f(); },
    setTimeout: (f) => { void f; return 0; },     // never fires: no async in a rule check
    clearTimeout() {},
    setInterval: () => 0,
    clearInterval() {},
    // the page fetches coach_tips.json and levels.json; serve them from disk
    fetch(url) {
      const p = path.join(GAME, String(url));
      if (fs.existsSync(p)) {
        const text = fs.readFileSync(p, "utf8");
        return Promise.resolve({ json: () => Promise.resolve(JSON.parse(text)) });
      }
      return Promise.reject(new Error("no such file " + url));
    },
    Math, JSON, Date, Promise, Set, Map, Array, Object, String, Number, console,
  };
  win.window = win;
  win.self = win;
  win.globalThis = win;
  return win;
}

/** Evaluate the shipped block and hand back a small façade over its own state. */
function load() {
  const html = fs.readFileSync(path.join(GAME, "index.html"), "utf8");
  const src = scriptBlock(html);
  const win = sandbox();
  const ctx = vm.createContext(win);
  // `let LEVELS` at block scope is not reachable from outside, so the block is wrapped
  // and the names it declares are exported by the tail. The block itself is verbatim.
  const tail = `
    ;globalThis.__fold = {
      loadLevel: load, move, undo, LEVELS: () => LEVELS, setLevels: (d) => { LEVELS = d; },
      state: () => ({ level: L, moves, done, target: LEVELS[L].target, par: LEVELS[L].par,
        tiles: tiles.map(t => ({ id: t.id, r: t.r, c: t.c, v: t.v }))
                    .sort((a,b) => a.r - b.r || a.c - b.c || a.id - b.id) }),
      stars: () => (moves <= LEVELS[L].par ? 3 : moves <= LEVELS[L].par + 2 ? 2 : 1),
      won: () => tiles.length === 1 && tiles[0].v === LEVELS[L].target,
    };
  `;
  vm.runInContext(src + tail, ctx, { filename: "fold/frontend/index.html#game" });
  const A = win.__fold;
  // the page's own tail calls load(...) inside a .finally on the levels.json fetch; run
  // the same fetch synchronously here so the harness holds the shipped 201 levels.
  A.setLevels(JSON.parse(fs.readFileSync(path.join(GAME, "levels.json"), "utf8")));
  A.loadLevel(0);
  return A;
}

module.exports = { load, scriptBlock };

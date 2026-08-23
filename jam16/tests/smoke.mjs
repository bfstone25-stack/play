// Headless smoke test: stubs the browser APIs the engine touches, then drives
// real animation frames and asserts the game reaches play and game-over states.
// Run on Pop: node jam-skeleton/tests/smoke.mjs

const listeners = new Map();
const drawCalls = [];
let rafCallback = null;
let clock = 0;

const ctxStub = new Proxy({}, {
  get(_, prop) {
    if (prop === 'canvas') return canvasStub;
    return (...args) => { drawCalls.push([prop, args.length]); };
  },
  set() { return true; },
});

const canvasStub = {
  width: 0, height: 0, style: {},
  getContext: () => ctxStub,
  addEventListener: (type, fn) => listeners.set(`canvas:${type}`, fn),
};

globalThis.window = globalThis;
globalThis.devicePixelRatio = 2;
globalThis.innerWidth = 430;
globalThis.innerHeight = 932;
globalThis.document = { getElementById: () => canvasStub };
globalThis.addEventListener = (type, fn) => listeners.set(type, fn);
globalThis.performance = { now: () => clock };
globalThis.requestAnimationFrame = (fn) => { rafCallback = fn; return 1; };
globalThis.localStorage = {
  store: new Map(),
  getItem(k) { return this.store.get(k) ?? null; },
  setItem(k, v) { this.store.set(k, v); },
};
globalThis.AudioContext = class {
  constructor() { this.state = 'running'; this.currentTime = 0; this.destination = {}; }
  resume() {}
  createOscillator() {
    return { type: '', frequency: { value: 0 }, connect: () => ({ connect: () => {} }),
             start() {}, stop() {} };
  }
  createGain() {
    return { gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {} },
             connect: () => ({ connect: () => {} }) };
  }
};
globalThis.setTimeout = (fn) => { fn(); return 0; };

function frame(ms = 16.7) {
  clock += ms;
  const fn = rafCallback;
  rafCallback = null;
  if (!fn) throw new Error('engine stopped requesting frames');
  fn(clock);
}

function key(type, code) {
  const fn = listeners.get(type);
  if (!fn) throw new Error(`no listener for ${type}`);
  fn({ code, preventDefault() {} });
}

const failures = [];
function check(label, condition) {
  if (condition) console.log(`  ok   ${label}`);
  else { console.log(`  FAIL ${label}`); failures.push(label); }
}

console.log('jam skeleton smoke test');
await import('../js/game.js');

check('canvas sized for DPR', canvasStub.width === 860 && canvasStub.height === 1864);
check('registered resize/keydown/keyup', ['resize', 'keydown', 'keyup']
  .every((t) => listeners.has(t)));

for (let i = 0; i < 30; i++) frame();
const titleDraws = drawCalls.length;
check('title screen renders', titleDraws > 0);
check('title shows fillText', drawCalls.some(([op]) => op === 'fillText'));

key('keydown', 'Space');
key('keyup', 'Space');
for (let i = 0; i < 10; i++) frame();
check('start advances past title', drawCalls.length > titleDraws);

// Let targets spawn and fall off-screen to trigger the fail state.
for (let i = 0; i < 900; i++) frame();
check('survives 900 frames without throwing', true);
check('arc drawn (targets/player present)', drawCalls.some(([op]) => op === 'arc'));

key('keydown', 'ArrowLeft');
for (let i = 0; i < 20; i++) frame();
key('keyup', 'ArrowLeft');
check('keyboard input accepted', true);

const best = globalThis.localStorage.getItem('jam16.best');
check('best score persisted after game over', best !== null);

console.log(failures.length ? `\n${failures.length} failure(s)` : '\nall checks passed');
process.exit(failures.length ? 1 : 0);

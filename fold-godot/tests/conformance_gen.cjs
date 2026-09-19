/* JS side of the JS <-> GDScript conformance test.
 *
 *   node tests/conformance_gen.cjs        -> tests/conformance.json
 *
 * Every one of the 201 shipped levels (play/fold/frontend/levels.json), each driven by a
 * seeded pseudo-random sequence of up to 60 swipes, with the full tile set recorded after
 * every single move — not just the end state. A port that gets the final answer right by
 * luck while sliding tiles in the wrong order fails on move 3 instead of passing.
 *
 * What is pinned, per move:
 *   - moved / not moved (the JS distinguishes them: a no-op move must not increment the
 *     counter, must not push history, and plays the "invalid" cue instead)
 *   - the move counter
 *   - every surviving tile's id, row, column and value, in a canonical order. Ids matter:
 *     which of two equal tiles survives a merge is decided by the traversal order, and
 *     that is exactly the kind of thing a port gets subtly wrong.
 *   - win / stars, evaluated by the shipped star formula
 * and per level: the initial layout the loader produces from the grid, and an undo run.
 *
 * The seeded sequence is generated here and stored, so the GDScript side replays the
 * identical direction list rather than trying to reproduce a JS PRNG — the one thing in
 * a cross-language test that is guaranteed to diverge.
 */
const fs = require("fs");
const path = require("path");
const { load } = require("./harness.cjs");

const DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1]];

/* Numerical Recipes LCG on uint32, which behaves identically in JS and GDScript when the
 * multiply is kept inside 32 bits. Only used to pick directions; the sequence it produces
 * is written into the JSON anyway, so the GDScript never has to run it. */
function lcg(seed) {
  let s = seed >>> 0;
  return () => { s = (Math.imul(s, 1664525) + 1013904223) >>> 0; return s / 4294967296; };
}

/* Tiles are written as flat [id, r, c, v] arrays rather than objects. The same fixture
 * with named keys is 3.1 MB, which is a lot of generated JSON to keep in git for a test
 * that regenerates it on every run anyway; this is about a third of that and the
 * GDScript side reads it with the same four indices. */
const pack = (tiles) => tiles.map((t) => [t.id, t.r, t.c, t.v]);

const A = load();
const LEVELS = A.LEVELS();
const levels = [];

for (let i = 0; i < LEVELS.length; i++) {
  const r = lcg(9000 + i * 31);
  A.loadLevel(i);
  const initial = A.state();
  const dirs = [];
  const steps = [];
  for (let k = 0; k < 60; k++) {
    const d = DIRS[Math.floor(r() * 4)];
    const before = A.state();
    A.move(d[0], d[1]);
    const after = A.state();
    dirs.push(d);
    steps.push({
      dir: d,
      moved: after.moves !== before.moves,
      moves: after.moves,
      tiles: pack(after.tiles),
      done: after.done,
      won: A.won(),
      stars: A.won() ? A.stars() : 0,
    });
    if (after.done) break;          // the shipped move() refuses to act once done
  }
  // undo run: replay the same directions on a fresh board, then unwind them all
  A.loadLevel(i);
  for (const d of dirs) A.move(d[0], d[1]);
  const beforeUndo = A.state();
  const undos = [];
  for (let k = 0; k < dirs.length + 3; k++) {
    A.undo();
    undos.push(A.state());
  }
  levels.push({
    index: i, name: LEVELS[i].name, target: LEVELS[i].target, par: LEVELS[i].par,
    grid: LEVELS[i].grid,
    initial: { tiles: pack(initial.tiles) }, dirs, steps,
    undo: { from: { tiles: pack(beforeUndo.tiles) },
            states: undos.map((s) => ({ moves: s.moves, tiles: pack(s.tiles) })) },
  });
}

const out = {
  generated: new Date().toISOString(),
  source: "play/fold/frontend/index.html (inline game script) + levels.json",
  levelCount: LEVELS.length,
  levels,
};
fs.writeFileSync(path.join(__dirname, "conformance.json"), JSON.stringify(out));
const moves = levels.reduce((n, l) => n + l.steps.length, 0);
console.log(`conformance.json: ${levels.length} levels, ${moves} recorded moves`);

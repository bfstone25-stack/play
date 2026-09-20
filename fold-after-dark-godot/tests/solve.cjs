/* Solve levels with the shipped JavaScript, so the browser driver can play real
 * solutions instead of mashing arrow keys.
 *
 *   node tests/solve.cjs 0 1 2 3 4 5      -> {"0": [[0,1]], "1": [[1,0],[0,1]], ...}
 *
 * Breadth-first over the real rules (tests/harness.cjs runs the page's own move()), so a
 * solution printed here is a solution in the game — and because tests/run_tests.gd has
 * already proved the GDScript agrees with that JavaScript move for move, playing these
 * keys in the Godot build is a second, independent check of the same claim: the same
 * sequence must win the same level in the same number of moves and score the same stars.
 *
 * Breadth-first also means the solution is the shortest one, which is par or better, so
 * the driver gets to assert three stars rather than "some stars".
 */
const { load } = require("./harness.cjs");

const DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1]];
const A = load();

function keyOf(s) {
  return s.tiles.map((t) => `${t.r},${t.c},${t.v}`).join("|");
}

/** Replay a path from the level's start and return the resulting state. */
function replay(level, path) {
  A.loadLevel(level);
  for (const d of path) A.move(d[0], d[1]);
  return A.state();
}

function solve(level, maxDepth = 16) {
  A.loadLevel(level);
  const start = A.state();
  if (A.won()) return [];
  let frontier = [[]];
  const seen = new Set([keyOf(start)]);
  for (let depth = 0; depth < maxDepth; depth++) {
    const next = [];
    for (const path of frontier) {
      for (const d of DIRS) {
        const s = replay(level, path.concat([d]));
        if (A.won()) return path.concat([d]);
        const k = keyOf(s);
        if (seen.has(k)) continue;
        seen.add(k);
        next.push(path.concat([d]));
      }
    }
    if (!next.length) return null;
    frontier = next;
    if (frontier.length > 40000) return null;      // give up rather than thrash
  }
  return null;
}

const want = process.argv.slice(2).map(Number);
const out = {};
for (const i of want) {
  const path = solve(i);
  if (path === null) {
    out[i] = null;
    continue;
  }
  const s = replay(i, path);
  out[i] = { dirs: path, moves: s.moves, par: s.par, stars: A.stars(), target: s.target };
}
console.log(JSON.stringify(out));

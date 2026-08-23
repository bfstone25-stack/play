const fs = require("fs");
const vm = require("vm");
const path = require("path");
const ctx = { console, Math };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync(path.join(__dirname, "../catharsis/kernel/pool.js"), "utf8") +
    "\nglobalThis.testApi={makePool,circleHit,moveToward};",
  ctx,
);
const { makePool, circleHit, moveToward } = ctx.testApi;
let created = 0;
const pool = makePool(() => { created += 1; return { x: 0, y: 0, r: 8 }; });
for (let wave = 0; wave < 4; wave++) {
  for (let i = 0; i < 50; i++) pool.spawn(o => { o.x = i; o.y = wave; o.r = 8; });
  pool.live.forEach(o => pool.kill(o));
  pool.reap();
}
if (created > 60) throw new Error("pool leaked allocations " + created);
let hits = 0;
for (let i = 0; i < 200; i++) {
  if (circleHit({ x: i, y: 0, r: 6 }, { x: i + 4, y: 0, r: 6 })) hits += 1;
}
if (hits !== 200) throw new Error("collisions " + hits);
const e = { x: 0, y: 0 };
moveToward(e, 10, 0, 10, 1);
if (Math.abs(e.x - 10) > 0.01) throw new Error("move");
console.log("beat-monday pool ok", { created, hits });

// Regenerate tests/merit_conformance.json from the kernel's merit.js: a fixed script of
// clicks, ticks and upgrades, with the snapshot after each step, so tests/run_tests.gd can
// assert the GDScript port on the same inputs.   node tests/merit_conformance_gen.cjs
const fs = require("fs");
const path = require("path");
const src = fs.readFileSync(path.join(__dirname, "../../catharsis/kernel/merit.js"), "utf8");
const Merit = new Function(src + "; return Merit;")();

const steps = [];
const ops = [];
// 40 clicks, then loops of: upgrade when affordable, click x7, tick 0.5 s
for (let i = 0; i < 40; i++) ops.push(["click"]);
for (let round = 0; round < 60; round++) {
  ops.push(["upgrade"]);
  for (let i = 0; i < 7; i++) ops.push(["click"]);
  ops.push(["tick", 0.5]);
  ops.push(["tick", 1.25]);
}
// a load with junk, then clicks
ops.push(["load", { merit: 123.9, clicks: -4, level: 7.2, auto: 2 }]);
for (let i = 0; i < 5; i++) ops.push(["click"]);
ops.push(["tick", 3.0]);
ops.push(["load", null]);

for (const op of ops) {
  let ret;
  if (op[0] === "click") ret = Merit.click();
  else if (op[0] === "tick") ret = Merit.tick(op[1]);
  else if (op[0] === "upgrade") ret = Merit.tryUpgrade();
  else if (op[0] === "load") ret = Merit.load(op[1]);
  steps.push({ op, ret, snap: Merit.snapshot() });
}
fs.writeFileSync(path.join(__dirname, "merit_conformance.json"), JSON.stringify(steps));
console.log(steps.length + " steps, final", Merit.snapshot());

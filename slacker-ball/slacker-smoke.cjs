const fs = require("fs");
const vm = require("vm");
const path = require("path");

const context = { console, Math, performance: { now: () => 0 } };
vm.createContext(context);
const kernel = path.join(__dirname, "../catharsis/kernel");
let src = "";
for (const f of ["sfx.js", "economy.js", "breakables.js", "physics.js"]) {
  src += fs.readFileSync(path.join(kernel, f), "utf8") + "\n";
}
src += "\nglobalThis.testApi={WORLD,LAYOUT,launch,updatePhysics,settleBalls,hitBreakables,Economy};";
vm.runInContext(src, context);
const { WORLD, launch, updatePhysics, settleBalls, hitBreakables, Economy } = context.testApi;

Economy.load({ stardust: 0, tickets: 30 });
const blocks = [{ id: "kpi", x: 180, y: 200, w: 60, h: 30, hp: 3 }];
let smashed = 0;
for (let i = 0; i < 12; i++) {
  if (!Economy.consumeTicket()) throw new Error("ammo");
  WORLD.balls.length = 0;
  WORLD.balls.push({ x: 210, y: 210, vx: 20, vy: 40, r: 8, state: "flying", enteredField: true, trail: [], charge: 0, portalLock: 0 });
  for (let f = 0; f < 8; f++) {
    updatePhysics(1 / 120);
    for (const b of WORLD.balls) {
      if (b.state !== "flying") continue;
      if (hitBreakables(b, blocks)) smashed += 1;
    }
  }
}
if (blocks[0].hp > 0 && smashed === 0) throw new Error("slacker ball never damaged a block");
console.log(`slacker smash ok: hpLeft=${blocks[0].hp} smashedEvents=${smashed}`);

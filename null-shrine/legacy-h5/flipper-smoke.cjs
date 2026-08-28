const fs = require("fs");
const vm = require("vm");

const context = {
  console,
  Math,
  SFX: {
    peg() {},
    launch() {},
    redZone() {},
    flipperHit() {},
  },
};
vm.createContext(context);
const physicsPath = fs.existsSync(__dirname + "/frontend/js/physics.js")
  ? __dirname + "/frontend/js/physics.js"
  : __dirname + "/js/physics.js";
vm.runInContext(
  fs.readFileSync(physicsPath, "utf8") +
    "\nglobalThis.testApi={WORLD,LAYOUT,launch,addBall,updatePhysics,settleBalls,setFlipper,updateParticles};",
  context,
);

const { WORLD, LAYOUT, launch, updatePhysics, settleBalls, setFlipper, updateParticles } = context.testApi;

function runShot(power, useArms) {
  let result = null;
  launch(power);
  let contacts = 0;
  let maxVyAfterHit = 0;
  let holdLeft = 0;
  let holdRight = 0;
  for (let frame = 0; frame < 3000 && WORLD.balls.length; frame++) {
    const b = WORLD.balls[0];
    if (b && useArms) {
      const before = b.flipperHits || 0;
      const inSaveZone = b.y > 455 && b.y < 530 && b.vy > 120;
      if (inSaveZone && b.x < 232 && holdLeft <= 0) holdLeft = 10;
      if (inSaveZone && b.x >= 188 && holdRight <= 0) holdRight = 10;
      setFlipper("left", holdLeft > 0);
      setFlipper("right", holdRight > 0);
      if (holdLeft > 0) holdLeft--;
      if (holdRight > 0) holdRight--;
      updatePhysics(1 / 120);
      contacts = Math.max(contacts, b.flipperHits || 0);
      if ((b.flipperHits || 0) > before) maxVyAfterHit = Math.min(maxVyAfterHit, b.vy);
    } else {
      updatePhysics(1 / 120);
    }
    updateParticles(1 / 120);
    settleBalls((ball, pocket) => { result = pocket ? pocket.kind : "lost"; });
  }
  setFlipper("left", false);
  setFlipper("right", false);
  if (WORLD.balls.length) {
    WORLD.balls.length = 0;
    return { result: "lost", contacts, maxVyAfterHit };
  }
  return { result, contacts, maxVyAfterHit };
}

let unpressedHits = 0;
let jackpots = 0;
const results = {};
for (let shot = 0; shot < 90; shot++) {
  const r = runShot(0.22 + (shot % 15) * 0.055, false);
  unpressedHits += r.contacts;
  if (r.result === "jackpot") jackpots++;
  results[r.result] = (results[r.result] || 0) + 1;
}

if (unpressedHits !== 0) throw new Error(`resting arms intercepted ${unpressedHits} launches`);
if (!results.normal) throw new Error(`drain never paid out: ${JSON.stringify(results)}`);
// Arcade rule: free-fall jackpots must stay rare. Center is the drain.
if ((results.jackpot || 0) > 18) throw new Error(`jackpot too free on idle drops: ${JSON.stringify(results)}`);
if ((results.normal || 0) < 40) throw new Error(`center drain too weak: ${JSON.stringify(results)}`);

let rallyContacts = 0;
let saves = 0;
for (let shot = 0; shot < 90; shot++) {
  const r = runShot(0.18 + (shot % 15) * 0.06, true);
  rallyContacts += r.contacts;
  if (r.contacts > 0 && r.maxVyAfterHit < -260) saves++;
}

if (rallyContacts < 6) throw new Error(`skilled arms rarely mattered: ${rallyContacts}`);
if (saves < 3) throw new Error(`skilled arms failed to send balls back up: ${saves}`);
console.log(`flipper layout ok: unpressed=${unpressedHits}, spread=${JSON.stringify(results)}, skillHits=${rallyContacts}, saves=${saves}`);

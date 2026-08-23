const fs = require("fs");
const vm = require("vm");
const path = require("path");
const ctx = {
  console, Math,
  SFX: { peg() {}, launch() {}, redZone() {}, flipperHit() {} },
};
vm.createContext(ctx);
const kernel = path.join(__dirname, "../catharsis/kernel");
let src = "";
for (const f of ["sfx.js", "quiz.js", "physics.js"]) {
  src += fs.readFileSync(path.join(kernel, f), "utf8") + "\n";
}
src += "\nglobalThis.testApi={checkQuiz,chargeShot,parentReport,pickQuiz,QUIZ_BANK,launch,WORLD,updatePhysics,settleBalls};";
vm.runInContext(src, ctx);
const { checkQuiz, chargeShot, parentReport, pickQuiz, QUIZ_BANK, launch, WORLD, updatePhysics, settleBalls } = ctx.testApi;
const q = QUIZ_BANK.find(x => x.id === "add");
if (!checkQuiz(q, "12")) throw new Error("math");
if (checkQuiz(q, "13")) throw new Error("wrong accepted");
let c = 0;
c = chargeShot(c, true);
c = chargeShot(c, true);
c = chargeShot(c, true);
if (c < 0.99) throw new Error("charge " + c);
launch(c);
if (!WORLD.balls.length) throw new Error("no ball");
for (let i = 0; i < 40; i++) updatePhysics(1 / 120);
settleBalls(() => {});
const r = parentReport({ attempts: 10, correct: 8 });
if (r.pct !== 80 || r.lines.length !== 3) throw new Error("report");
if (!pickQuiz(QUIZ_BANK, () => 0)) throw new Error("pick");
console.log("word-pop quiz+physics ok", { charge: c, balls: WORLD.balls.length, pct: r.pct });

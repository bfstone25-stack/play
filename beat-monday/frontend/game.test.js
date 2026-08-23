const assert = require("assert");
const BM = require("./game.js");

function testAabb() {
  assert.ok(BM.aabb({ x: 0, y: 0, w: 10, h: 10 }, { x: 8, y: 8, w: 10, h: 10 }));
  assert.ok(!BM.aabb({ x: 0, y: 0, w: 10, h: 10 }, { x: 20, y: 20, w: 4, h: 4 }));
}

function testClockSeed() {
  const a = BM.dateSeed(new Date("2026-08-22T10:00:00Z"));
  const b = BM.dateSeed(new Date("2026-08-22T23:00:00Z"));
  assert.strictEqual(a, b);
}

function testMatch() {
  const g = BM.createMatch({ seed: 7, foe: "intern", headless: true });
  assert.strictEqual(g.p1.kit, "hero");
  assert.strictEqual(g.p2.kit, "intern");
  assert.ok(g.p1.hp > 0 && g.p2.hp > 0);
  assert.ok(BM.hurtBox(g.p1).w > 0);
}

function testPunchConnects() {
  const g = BM.createMatch({ seed: 1, foe: "intern", headless: true });
  g.mode = "fight";
  g.p1.x = 500; g.p2.x = 560;
  g.p1.face = 1; g.p2.face = -1;
  g.p1.input = { l: 0, r: 0, u: 0, d: 0, p: 1, k: 0, s: 0 };
  g.p1.prev = { l: 0, r: 0, u: 0, d: 0, p: 0, k: 0, s: 0 };
  BM.update(g, 1 / 60);
  assert.strictEqual(g.p1.state, "attack");
  assert.strictEqual(g.p1.move.kind, "punch");
  assert.strictEqual(g.p1.move.hitKind, "high");
  for (let i = 0; i < 10; i++) {
    g.p1.input = { l: 0, r: 0, u: 0, d: 0, p: 0, k: 0, s: 0 };
    BM.update(g, 1 / 60);
  }
  assert.ok(g.p2.hp < g.p2.maxHp || g.p2.state === "hit" || g.p2.state === "block" || g.p2.state === "ko");
}

function testKickKind() {
  const g = BM.createMatch({ seed: 2, foe: "intern", headless: true });
  g.mode = "fight";
  g.p1.input = { l: 0, r: 0, u: 0, d: 0, p: 0, k: 1, s: 0 };
  g.p1.prev = { l: 0, r: 0, u: 0, d: 0, p: 0, k: 0, s: 0 };
  BM.update(g, 1 / 60);
  assert.strictEqual(g.p1.state, "attack");
  assert.strictEqual(g.p1.move.kind, "kick");
  assert.strictEqual(g.p1.move.hitKind, "low");
}

function testSim() {
  const r = BM.simulateMatch({ seed: 99, foe: "intern" });
  assert.ok(["heroic", "death"].includes(r.verdict));
  assert.ok(r.rounds);
  console.log("sim", r.verdict, r.rounds, r.foe);
}

function testLadder() {
  assert.deepStrictEqual(BM.LADDER, ["intern", "pm", "hr", "finance", "boss"]);
  assert.ok(BM.KITS.hero.super);
  assert.ok(BM.KITS.boss.punch.dmg > BM.KITS.intern.punch.dmg);
}

testAabb();
testClockSeed();
testMatch();
testPunchConnects();
testKickKind();
testLadder();
testSim();
console.log("beatmonday fighter tests ok");

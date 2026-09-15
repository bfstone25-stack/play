#!/usr/bin/env node
// Fairness invariants for request planning (mirrors game.js).
const AGENTS = ["viper", "moth", "hex", "raven", "quill"];

function pick(arr) { return arr[(Math.random() * arr.length) | 0]; }

function planRequests(s) {
  const types = ["fire", "extract", "resupply", "move", "codebook", "accuse"];
  const queue = [];
  const ids = s.agents;
  const friendlies = ids.filter((id) => id !== s.mimicId);
  queue.push({ speaker: friendlies[0], type: "resupply", forceClean: true });
  queue.push({ speaker: friendlies[1 % friendlies.length], type: "move", forceClean: true });
  const rest = s.op.requests - 2;
  let mimicLeft = 2 + (s.op.id > 1 ? 1 : 0);
  for (let i = 0; i < rest; i++) {
    const useMimic = mimicLeft > 0 && (i === rest - 1 || Math.random() < 0.38);
    const speaker = useMimic ? s.mimicId : pick(friendlies);
    if (useMimic) mimicLeft--;
    queue.push({ speaker, type: pick(types), forceClean: false });
  }
  return queue;
}

let fails = 0;
function assert(cond, msg) {
  if (!cond) { fails += 1; console.error("FAIL", msg); }
}

for (let n = 0; n < 40; n++) {
  const mimicId = pick(AGENTS);
  const op = { id: 1 + (n % 3), requests: [7, 9, 10][n % 3] };
  const q = planRequests({ op, mimicId, agents: AGENTS });
  assert(q.length === op.requests, "length " + q.length);
  assert(q[0].speaker !== mimicId, "first request must be friendly");
  assert(q[1].speaker !== mimicId, "second request must be friendly");
  assert(q.some((r) => r.speaker === mimicId), "at least one mimic request");
  assert(q.every((r) => AGENTS.includes(r.speaker)), "known speakers");
}

if (fails) {
  console.error(fails + " failures");
  process.exit(1);
}
console.log("fairness ok");

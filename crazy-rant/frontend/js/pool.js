function makePool(factory) {
  const dead = [];
  const live = [];
  function spawn(init) {
    const o = dead.pop() || factory();
    o.alive = true;
    if (init) init(o);
    live.push(o);
    return o;
  }
  function kill(o) {
    if (!o || !o.alive) return;
    o.alive = false;
    dead.push(o);
  }
  function reap() {
    for (let i = live.length - 1; i >= 0; i--) {
      if (!live[i].alive) live.splice(i, 1);
    }
  }
  return { spawn, kill, reap, live, dead };
}

function circleHit(a, b) {
  const dx = a.x - b.x, dy = a.y - b.y;
  const r = (a.r || 0) + (b.r || 0);
  return dx * dx + dy * dy < r * r;
}

function moveToward(e, tx, ty, speed, dt) {
  const dx = tx - e.x, dy = ty - e.y;
  const d = Math.hypot(dx, dy) || 1;
  e.x += dx / d * speed * dt;
  e.y += dy / d * speed * dt;
}

/* Circle vs AABB blocks. Used by Slacker Ball urgent-request cubes. */
function hitBreakables(ball, blocks) {
  let smashed = null;
  for (const b of blocks) {
    if (b.hp <= 0) continue;
    const nx = Math.max(b.x, Math.min(ball.x, b.x + b.w));
    const ny = Math.max(b.y, Math.min(ball.y, b.y + b.h));
    const dx = ball.x - nx;
    const dy = ball.y - ny;
    let d = Math.hypot(dx, dy);
    const inside = ball.x > b.x && ball.x < b.x + b.w && ball.y > b.y && ball.y < b.y + b.h;
    if (!inside && d >= ball.r) continue;
    let ux, uy;
    if (inside || d === 0) {
      const left = ball.x - b.x, right = b.x + b.w - ball.x;
      const top = ball.y - b.y, bottom = b.y + b.h - ball.y;
      const m = Math.min(left, right, top, bottom);
      if (m === left) { ux = -1; uy = 0; }
      else if (m === right) { ux = 1; uy = 0; }
      else if (m === top) { ux = 0; uy = -1; }
      else { ux = 0; uy = 1; }
      d = ball.r * 0.5;
    } else {
      ux = dx / d;
      uy = dy / d;
    }
    ball.x = nx + ux * ball.r;
    ball.y = ny + uy * ball.r;
    const vn = ball.vx * ux + ball.vy * uy;
    if (vn < 0) {
      ball.vx -= (1 + 0.55) * vn * ux;
      ball.vy -= (1 + 0.55) * vn * uy;
    }
    b.hp -= 1;
    if (typeof SFX !== "undefined" && SFX.peg) SFX.peg();
    if (b.hp <= 0) smashed = b;
  }
  return smashed;
}

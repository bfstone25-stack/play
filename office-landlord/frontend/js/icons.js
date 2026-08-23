const ICONS = (() => {
  const C = {
    ink: "#e8efe8",
    amber: "#e0a14a",
    emerald: "#1f8a64",
    steel: "#4a6d8c",
    dim: "#9aa8a8",
  };

  function stroke(ctx, fn, color, width) {
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.beginPath();
    fn();
    ctx.stroke();
    ctx.restore();
  }

  function fill(ctx, fn, color) {
    ctx.save();
    ctx.fillStyle = color;
    ctx.beginPath();
    fn();
    ctx.fill();
    ctx.restore();
  }

  const draw = {
    coffee(ctx, s) {
      fill(ctx, () => { ctx.roundRect(-s * 0.22, -s * 0.08, s * 0.44, s * 0.38, s * 0.06); }, C.steel);
      stroke(ctx, () => { ctx.arc(s * 0.26, 0.04 * s, s * 0.12, -0.7, 0.7); }, C.amber, s * 0.06);
      fill(ctx, () => { ctx.roundRect(-s * 0.16, -s * 0.28, s * 0.32, s * 0.16, s * 0.04); }, C.emerald);
      stroke(ctx, () => {
        ctx.moveTo(-s * 0.06, -s * 0.34);
        ctx.quadraticCurveTo(0, -s * 0.48, s * 0.08, -s * 0.34);
      }, C.amber, s * 0.05);
    },
    dev(ctx, s) {
      fill(ctx, () => { ctx.roundRect(-s * 0.32, -s * 0.3, s * 0.64, s * 0.4, 4); }, C.steel);
      fill(ctx, () => { ctx.roundRect(-s * 0.26, -s * 0.24, s * 0.52, s * 0.28, 2); }, "#0f161b");
      stroke(ctx, () => {
        ctx.moveTo(-s * 0.14, -s * 0.08);
        ctx.lineTo(-s * 0.04, 0);
        ctx.lineTo(-s * 0.14, s * 0.08);
        ctx.moveTo(s * 0.14, -s * 0.08);
        ctx.lineTo(s * 0.04, 0);
        ctx.lineTo(s * 0.14, s * 0.08);
      }, C.amber, s * 0.055);
      fill(ctx, () => { ctx.roundRect(-s * 0.36, s * 0.14, s * 0.72, s * 0.12, 3); }, C.dim);
    },
    intern(ctx, s) {
      fill(ctx, () => { ctx.arc(0, -s * 0.16, s * 0.14, 0, Math.PI * 2); }, C.ink);
      fill(ctx, () => {
        ctx.moveTo(-s * 0.2, s * 0.28);
        ctx.quadraticCurveTo(-s * 0.22, 0, 0, 0);
        ctx.quadraticCurveTo(s * 0.22, 0, s * 0.2, s * 0.28);
      }, C.steel);
      fill(ctx, () => { ctx.roundRect(-s * 0.08, s * 0.02, s * 0.16, s * 0.08, 2); }, C.amber);
    },
    meeting(ctx, s) {
      fill(ctx, () => { ctx.roundRect(-s * 0.3, -s * 0.28, s * 0.6, s * 0.56, s * 0.06); }, C.steel);
      stroke(ctx, () => {
        ctx.moveTo(-s * 0.18, -s * 0.08);
        ctx.lineTo(s * 0.18, -s * 0.08);
        ctx.moveTo(-s * 0.18, s * 0.06);
        ctx.lineTo(s * 0.1, s * 0.06);
      }, C.amber, s * 0.055);
      fill(ctx, () => { ctx.arc(s * 0.16, s * 0.16, s * 0.06, 0, Math.PI * 2); }, C.emerald);
    },
    mute(ctx, s) {
      stroke(ctx, () => {
        ctx.arc(-s * 0.18, 0, s * 0.14, 0.4, Math.PI * 2 - 0.4);
        ctx.moveTo(-s * 0.08, -s * 0.12);
        ctx.lineTo(s * 0.08, -s * 0.12);
        ctx.arc(s * 0.18, 0, s * 0.14, Math.PI + 0.4, Math.PI - 0.4, true);
        ctx.moveTo(-s * 0.08, s * 0.12);
        ctx.lineTo(s * 0.08, s * 0.12);
      }, C.amber, s * 0.07);
      stroke(ctx, () => {
        ctx.moveTo(0, -s * 0.12);
        ctx.lineTo(0, s * 0.12);
      }, C.steel, s * 0.05);
    },
    printer(ctx, s) {
      fill(ctx, () => { ctx.roundRect(-s * 0.3, -s * 0.04, s * 0.6, s * 0.3, 4); }, C.steel);
      fill(ctx, () => { ctx.roundRect(-s * 0.2, -s * 0.28, s * 0.4, s * 0.24, 3); }, C.ink);
      fill(ctx, () => { ctx.roundRect(-s * 0.16, s * 0.08, s * 0.2, s * 0.08, 2); }, C.amber);
    },
    standup(ctx, s) {
      fill(ctx, () => { ctx.roundRect(-s * 0.22, -s * 0.22, s * 0.28, s * 0.28, 3); }, C.amber);
      fill(ctx, () => { ctx.roundRect(-s * 0.04, -s * 0.04, s * 0.28, s * 0.28, 3); }, C.emerald);
      stroke(ctx, () => {
        ctx.moveTo(-s * 0.14, -s * 0.1);
        ctx.lineTo(-s * 0.02, -s * 0.1);
        ctx.moveTo(0.04 * s, 0.1 * s);
        ctx.lineTo(0.16 * s, 0.1 * s);
      }, "#12161c", s * 0.05);
    },
    corner(ctx, s) {
      stroke(ctx, () => {
        ctx.moveTo(-s * 0.28, s * 0.2);
        ctx.lineTo(-s * 0.28, -s * 0.2);
        ctx.lineTo(s * 0.12, -s * 0.2);
        ctx.lineTo(s * 0.28, -s * 0.04);
        ctx.lineTo(s * 0.28, s * 0.2);
      }, C.steel, s * 0.07);
      fill(ctx, () => {
        ctx.moveTo(-s * 0.2, s * 0.2);
        ctx.lineTo(-s * 0.2, 0);
        ctx.lineTo(s * 0.08, 0);
        ctx.lineTo(s * 0.2, s * 0.12);
        ctx.lineTo(s * 0.2, s * 0.2);
      }, C.emerald);
    },
  };

  function paint(ctx, id, x, y, size) {
    ctx.save();
    ctx.translate(x, y);
    const fn = draw[id] || draw.intern;
    fn(ctx, size);
    ctx.restore();
  }

  function badge(id, px) {
    const c = document.createElement("canvas");
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = px * dpr;
    c.height = px * dpr;
    const ctx = c.getContext("2d");
    ctx.scale(dpr, dpr);
    paint(ctx, id, px / 2, px / 2, px * 0.72);
    return c;
  }

  return { paint, badge };
})();

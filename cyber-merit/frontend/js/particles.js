const FX = (() => {
  const particles = [];
  const smoke = [];
  const rain = [];
  let cap = 140;

  function setCap(n) { cap = n; }

  function spawn(p) {
    if (particles.length >= cap) particles.shift();
    particles.push(p);
  }

  function spiral(x, y, n, color, combo) {
    const count = Math.min(n, cap - particles.length + 8);
    for (let i = 0; i < count; i++) {
      const a = (Math.PI * 2 * i) / count + Math.random() * 0.4;
      spawn({
        kind: "merit",
        x, y,
        vx: Math.cos(a) * (18 + Math.random() * 28),
        vy: -40 - Math.random() * 50,
        a,
        spin: 2.8 + combo * 0.15,
        life: 1.15,
        max: 1.15,
        r: 2.2 + Math.random() * 2.4,
        color: color || (combo >= 4 ? "#ff2d95" : combo >= 2 ? "#3dba8a" : "#ffe08a"),
      });
    }
  }

  function petals(x, y, n) {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2;
      spawn({
        kind: "petal",
        x, y,
        vx: Math.cos(a) * (30 + Math.random() * 70),
        vy: Math.sin(a) * (20 + Math.random() * 40) - 20,
        life: 1.1,
        max: 1.1,
        rot: Math.random() * Math.PI,
        color: i % 2 ? "#ff8ac8" : "#ffe08a",
      });
    }
  }

  function bloom(x, y) {
    petals(x, y, 28);
    for (let i = 0; i < 16; i++) {
      const a = (Math.PI * 2 * i) / 16;
      spawn({
        kind: "spark",
        x, y,
        vx: Math.cos(a) * 90,
        vy: Math.sin(a) * 90,
        life: 0.7,
        max: 0.7,
        color: "#3dba8a",
      });
    }
  }

  function puff(x, y) {
    smoke.push({
      x: x + (Math.random() - 0.5) * 6,
      y,
      vy: -12 - Math.random() * 10,
      vx: (Math.random() - 0.5) * 8,
      life: 1.6,
      r: 4 + Math.random() * 5,
    });
    if (smoke.length > 40) smoke.shift();
  }

  function seedRain(w, h, n) {
    rain.length = 0;
    for (let i = 0; i < n; i++) {
      rain.push({
        x: Math.random() * w,
        y: Math.random() * h,
        len: 8 + Math.random() * 12,
        spd: 180 + Math.random() * 160,
      });
    }
  }

  function update(dt, W, H) {
    for (const p of particles) {
      p.life -= dt;
      if (p.kind === "merit") {
        p.a += p.spin * dt;
        p.x += Math.cos(p.a) * 26 * dt + p.vx * dt * 0.15;
        p.y += p.vy * dt;
        p.vy -= 18 * dt;
      } else {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 30 * dt;
        if (p.kind === "petal") p.rot += dt * 3;
      }
    }
    for (let i = particles.length - 1; i >= 0; i--) {
      if (particles[i].life <= 0) particles.splice(i, 1);
    }
    for (const s of smoke) {
      s.life -= dt * 0.55;
      s.y += s.vy * dt;
      s.x += s.vx * dt;
      s.r += 6 * dt;
    }
    for (let i = smoke.length - 1; i >= 0; i--) {
      if (smoke[i].life <= 0) smoke.splice(i, 1);
    }
    for (const r of rain) {
      r.y += r.spd * dt;
      r.x -= r.spd * 0.18 * dt;
      if (r.y > H) { r.y = -10; r.x = Math.random() * W; }
    }
  }

  function draw(ctx) {
    for (const r of rain) {
      ctx.strokeStyle = "rgba(180, 210, 255, .18)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(r.x, r.y);
      ctx.lineTo(r.x - 2, r.y + r.len);
      ctx.stroke();
    }
    for (const s of smoke) {
      ctx.globalAlpha = Math.max(0, s.life) * 0.22;
      ctx.fillStyle = "#c9b8a0";
      ctx.beginPath();
      ctx.ellipse(s.x, s.y, s.r, s.r * 1.3, 0, 0, Math.PI * 2);
      ctx.fill();
    }
    for (const p of particles) {
      const a = Math.max(0, p.life / p.max);
      ctx.globalAlpha = a;
      if (p.kind === "petal") {
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot);
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.ellipse(0, 0, 7, 3, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      } else {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r || 2, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
  }

  return { spiral, petals, bloom, puff, seedRain, update, draw, setCap, list: particles };
})();

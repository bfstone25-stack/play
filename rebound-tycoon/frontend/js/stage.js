window.REBOUND_STAGE = (() => {
  const fx = { sparks: [], coins: [], drops: [], floats: [], t: 0 };

  function spark(x, y, color) {
    for (let i = 0; i < 8; i++) {
      fx.sparks.push({
        x, y,
        vx: (Math.random() - 0.5) * 180,
        vy: (Math.random() - 0.5) * 180,
        life: 0.28,
        age: 0,
        color,
      });
    }
  }
  function burstCoins(x, y, n) {
    for (let i = 0; i < n; i++) {
      fx.coins.push({
        x, y,
        vx: (Math.random() - 0.4) * 80,
        vy: -30 - Math.random() * 60,
        life: 0.55,
        age: 0,
      });
    }
  }
  function spray(x, y, n) {
    for (let i = 0; i < n; i++) {
      fx.drops.push({
        x, y,
        vx: (Math.random() - 0.5) * 220,
        vy: -20 - Math.random() * 140,
        life: 0.35,
        age: 0,
      });
    }
  }
  function floatText(x, y, text) {
    fx.floats.push({ x, y, text, life: 0.9, age: 0 });
  }
  function tickFx(dt, reduce) {
    fx.t += dt;
    if (reduce) { fx.sparks.length = 0; fx.coins.length = 0; fx.drops.length = 0; fx.floats.length = 0; return; }
    [fx.sparks, fx.coins, fx.drops].forEach((list) => {
      for (let i = list.length - 1; i >= 0; i--) {
        const p = list[i];
        p.age += dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 120 * dt;
        if (p.age >= p.life) list.splice(i, 1);
      }
    });
    for (let i = fx.floats.length - 1; i >= 0; i--) {
      const p = fx.floats[i];
      p.age += dt;
      p.y -= 28 * dt;
      if (p.age >= p.life) fx.floats.splice(i, 1);
    }
  }

  function px(v, w) { return v * w; }
  function py(v, h) { return v * h; }

  function metal(g, era) {
    return era >= 2 ? "#e8c36a" : "#2ee0d4";
  }

  function drawBuilding(g, x, y, w, h, era, neon) {
    const grad = g.createLinearGradient(x, y, x + w, y + h);
    grad.addColorStop(0, era >= 3 ? "#1a4d58" : "#122830");
    grad.addColorStop(1, "#071014");
    g.fillStyle = grad;
    g.fillRect(x, y, w, h);
    g.fillStyle = metal(g, era);
    g.globalAlpha = 0.35;
    g.fillRect(x, y, 2, h);
    g.globalAlpha = 1;
    const cols = Math.max(2, Math.floor(w / 10));
    const rows = Math.max(2, Math.floor(h / 12));
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        if ((r + c) % 3 === 0) continue;
        g.fillStyle = neon && (c + r) % 5 === 0 ? "#f4d78a" : "rgba(170,230,220,.45)";
        g.fillRect(x + 3 + c * (w - 5) / cols, y + 4 + r * (h - 6) / rows, 4, 5);
      }
    }
  }

  function resize(canvas) {
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const w = canvas.clientWidth || 1;
    const h = canvas.clientHeight || 1;
    const pw = Math.floor(w * dpr), ph = Math.floor(h * dpr);
    if (canvas.width !== pw || canvas.height !== ph) {
      canvas.width = pw;
      canvas.height = ph;
    }
    return { w, h, dpr };
  }

  function draw(canvas, state, opts) {
    const { reduce, dt } = opts;
    const { w, h, dpr } = resize(canvas);
    const g = canvas.getContext("2d");
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    tickFx(dt, reduce);
    const era = eraIndex(state);

    const wood = g.createLinearGradient(0, 0, w, 0);
    wood.addColorStop(0, "#0a1416");
    wood.addColorStop(0.5, "#102226");
    wood.addColorStop(1, "#0a1416");
    g.fillStyle = wood;
    g.fillRect(0, 0, w, h);

    const play = g.createLinearGradient(0, 0, 0, h);
    play.addColorStop(0, era >= 3 ? "#08323c" : "#07161c");
    play.addColorStop(1, "#050c10");
    g.fillStyle = play;
    g.beginPath();
    g.rect(px(TABLE.left - 0.02, w), py(TABLE.top - 0.02, h), px(TABLE.right - TABLE.left + 0.04, w), py(0.93, h));
    g.fill();

    g.fillStyle = "#f3e7c0";
    for (let i = 0; i < 40; i++) {
      g.globalAlpha = 0.15 + (i % 4) * 0.08;
      g.fillRect(((i * 73) % 1000) / 1000 * w, ((i * 41) % 380) / 1000 * h, 1.4, 1.4);
    }
    g.globalAlpha = 1;
    g.fillStyle = "rgba(243,230,184,.22)";
    g.beginPath();
    g.arc(w * 0.78, h * 0.1, 16, 0, Math.PI * 2);
    g.fill();

    const ground = py(0.78, h);
    const studio = levelOf(state, "studio");
    const loft = levelOf(state, "loft");
    const pent = levelOf(state, "penthouse");
    const neon = levelOf(state, "neon");
    let lotX = px(0.12, w);
    for (let i = 0; i < studio; i++) {
      drawBuilding(g, lotX, ground - 46 - i * 4, 18, 46 + i * 4, era, false);
      lotX += 22;
    }
    for (let i = 0; i < loft; i++) {
      drawBuilding(g, lotX, ground - 72 - i * 6, 22, 72 + i * 6, era, neon > 0);
      lotX += 26;
    }
    for (let i = 0; i < pent; i++) {
      drawBuilding(g, lotX, ground - 110 - i * 8, 26, 110 + i * 8, era, true);
      lotX += 30;
    }

    g.strokeStyle = metal(g, era);
    g.lineWidth = 4;
    g.lineCap = "round";
    WALLS.forEach((wall) => {
      g.beginPath();
      g.moveTo(px(wall[0], w), py(wall[1], h));
      g.lineTo(px(wall[2], w), py(wall[3], h));
      g.stroke();
    });

    const labels = { booth: "1F", lobby: "LOB", tower: "PH", courier: "✉", party: "♪", raccoon: "🦝" };
    TARGETS.forEach((t, i) => {
      g.fillStyle = state.targetDown[i] ? "#163038" : (era >= 2 ? "#e8c36a" : "#1ec8c0");
      g.fillRect(px(t.x, w), py(t.y, h), px(t.w, w), py(t.h, h));
      g.fillStyle = "#061018";
      g.font = "700 9px ui-sans-serif, system-ui";
      g.textAlign = "center";
      g.fillText(labels[t.id] || "", px(t.x + t.w / 2, w), py(t.y + t.h * 0.72, h));
    });

    BUMPERS.forEach((b, i) => {
      const flash = state.bumperFlash[i] || 0;
      const cx = px(b.x, w), cy = py(b.y, h), r = px(b.r, w);
      g.fillStyle = flash > 0 ? "#f4d78a" : (era >= 3 ? "#1ec8c0" : "#12727a");
      g.beginPath();
      g.arc(cx, cy, r, 0, Math.PI * 2);
      g.fill();
      g.strokeStyle = metal(g, era);
      g.lineWidth = 3;
      g.stroke();
      g.fillStyle = flash > 0 ? "#2a1c04" : "#eef6f4";
      g.font = "700 " + Math.max(10, r * 0.7) + "px ui-sans-serif";
      g.textAlign = "center";
      g.textBaseline = "middle";
      g.fillText(labels[b.id] || "", cx, cy);
    });

    const sx = px(SAUCER.x, w), sy = py(SAUCER.y, h);
    g.fillStyle = era >= 2 ? "rgba(232,195,106,.4)" : "rgba(30,200,192,.32)";
    g.beginPath();
    g.arc(sx, sy, px(SAUCER.r * 1.35, w), 0, Math.PI * 2);
    g.fill();
    g.strokeStyle = metal(g, era);
    g.lineWidth = 3;
    g.beginPath();
    g.arc(sx, sy, px(SAUCER.r, w), 0, Math.PI * 2);
    g.stroke();
    g.fillStyle = "#f4d78a";
    g.font = "700 8px ui-sans-serif";
    g.textAlign = "center";
    g.fillText("HOSE", sx, sy + 3);

    g.strokeStyle = era >= 2 ? "#c9a24e" : "#2a6d72";
    g.lineWidth = 6;
    g.lineCap = "round";
    g.beginPath();
    g.moveTo(px(0.915, w), py(0.92, h));
    g.lineTo(px(0.915, w), py(0.34, h));
    g.stroke();
    g.fillStyle = era >= 2 ? "#e8c36a" : "#1ec8c0";
    g.beginPath();
    g.arc(px(0.915, w), py(0.30, h), 6, 0, Math.PI * 2);
    g.fill();

    function drawFlip(pivot, angle, right) {
      const tip = flipperEnd(pivot, angle);
      g.strokeStyle = era >= 2 ? "#f0d48a" : "#d8efe9";
      g.lineWidth = px(0.032, w);
      g.lineCap = "round";
      g.beginPath();
      g.moveTo(px(pivot.x, w), py(pivot.y, h));
      g.lineTo(px(tip.x, w), py(tip.y, h));
      g.stroke();
      g.fillStyle = era >= 2 ? "#e8c36a" : "#1ec8c0";
      g.beginPath();
      g.arc(px(pivot.x, w), py(pivot.y, h), px(0.018, w), 0, Math.PI * 2);
      g.fill();
      if (right) return;
    }
    drawFlip(LEFT_PIVOT, state.flipL, false);
    drawFlip(RIGHT_PIVOT, state.flipR, true);

    g.fillStyle = "#0b1012";
    g.fillRect(px(TABLE.drainL, w), py(0.93, h), px(TABLE.drainR - TABLE.drainL, w), py(0.05, h));

    const guardX = px(0.465, w), guardY = py(0.90, h);
    g.fillStyle = era >= 2 ? "#0c3a42" : "#1a3338";
    g.fillRect(guardX - 7, guardY - 22, 14, 20);
    g.fillStyle = "#e8c8a6";
    g.beginPath();
    g.arc(guardX, guardY - 26, 6, 0, Math.PI * 2);
    g.fill();
    g.fillStyle = era >= 2 ? "#d4b056" : "#16343a";
    g.fillRect(guardX - 7, guardY - 33, 14, 5);

    if (state.mode === "plunge") {
      g.fillStyle = "rgba(30,200,192,.7)";
      g.fillRect(px(0.888, w), py(0.84 - state.plunge * 0.08, h), px(0.054, w), py(0.07, h));
      const hint = opts.hint || "HOLD SPACE";
      g.fillStyle = "rgba(232,195,106,.92)";
      g.font = "700 12px ui-sans-serif, system-ui, sans-serif";
      g.textAlign = "center";
      g.textBaseline = "middle";
      g.fillText(hint, px(0.465, w), py(0.72, h));
    }

    if (state.ball) {
      const bx = px(state.ball.x, w), by = py(state.ball.y, h), br = px(REBOUND.BALL_R, w);
      const shine = g.createRadialGradient(bx - br * 0.3, by - br * 0.3, 1, bx, by, br);
      shine.addColorStop(0, "#e8fffb");
      shine.addColorStop(0.45, "#1ec8c0");
      shine.addColorStop(1, "#0a5a58");
      g.fillStyle = shine;
      g.beginPath();
      g.arc(bx, by, br, 0, Math.PI * 2);
      g.fill();
    }

    fx.sparks.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = p.color;
      g.fillRect(p.x, p.y, 2, 2);
    });
    fx.coins.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = "#f4d78a";
      g.beginPath();
      g.arc(p.x, p.y, 4, 0, Math.PI * 2);
      g.fill();
      g.fillStyle = "#7a5a10";
      g.font = "700 7px ui-sans-serif";
      g.textAlign = "center";
      g.textBaseline = "middle";
      g.fillText("$", p.x, p.y + 1);
    });
    fx.drops.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = "#9ff6ef";
      g.beginPath();
      g.ellipse(p.x, p.y, 2, 3.4, 0, 0, Math.PI * 2);
      g.fill();
    });
    fx.floats.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = "#f4d78a";
      g.font = "700 13px ui-sans-serif";
      g.textAlign = "center";
      g.fillText(p.text, p.x, p.y);
    });
    g.globalAlpha = 1;
    g.textBaseline = "alphabetic";
  }

  return { draw, spark, burstCoins, spray, floatText, fx };
})();

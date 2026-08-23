const ALTAR = (() => {
  const W = 420, H = 640;
  let strikeT = 0;
  let handT = 1;
  let bloomT = 0;
  let flash = 0;

  function punch(amount) {
    strikeT = 1;
    handT = 0;
    flash = Math.min(1, flash + amount);
  }

  function complete() {
    bloomT = 1;
    flash = 1;
  }

  function update(dt) {
    if (handT < 1) handT = Math.min(1, handT + dt * 5.6);
    if (strikeT > 0) strikeT = Math.max(0, strikeT - dt * 3.2);
    if (bloomT > 0) bloomT = Math.max(0, bloomT - dt * 0.55);
    if (flash > 0) flash = Math.max(0, flash - dt * 2.4);
  }

  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  function drawSky(ctx, city) {
    const g = ctx.createLinearGradient(0, 0, 0, H);
    g.addColorStop(0, "#070b16");
    g.addColorStop(0.45, city >= 2 ? "#12081c" : "#0b1020");
    g.addColorStop(1, "#1a100c");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = "rgba(255,224,138,.55)";
    for (let i = 0; i < 40; i++) {
      const x = (i * 97) % W;
      const y = (i * 53) % 220;
      ctx.globalAlpha = 0.25 + (i % 5) * 0.08;
      ctx.fillRect(x, y, 1.2, 1.2);
    }
    ctx.globalAlpha = 1;
    ctx.fillStyle = "rgba(255,45,149,.12)";
    ctx.beginPath();
    ctx.arc(70, 80, 40, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "rgba(61,186,138,.1)";
    ctx.beginPath();
    ctx.arc(340, 60, 50, 0, Math.PI * 2);
    ctx.fill();
  }

  function drawCity(ctx, city, t) {
    const horizon = 210 - city * 6;
    const cols = [
      { x: 0, w: 46, h: 90, win: "#ff2d95" },
      { x: 44, w: 38, h: 130, win: "#ffe08a" },
      { x: 80, w: 52, h: 80, win: "#3dba8a" },
      { x: 128, w: 30, h: 150, win: "#ff2d95" },
      { x: 156, w: 70, h: 70, win: "#c9a227" },
      { x: 224, w: 36, h: 140, win: "#3dba8a" },
      { x: 258, w: 48, h: 100, win: "#ffe08a" },
      { x: 304, w: 42, h: 160, win: "#ff2d95" },
      { x: 344, w: 80, h: 88, win: "#3dba8a" },
    ];
    cols.forEach((b, i) => {
      const h = b.h + city * 12;
      ctx.fillStyle = i % 2 ? "#0d121c" : "#10161f";
      ctx.fillRect(b.x, horizon - h + 40, b.w - 2, h + 80);
      ctx.fillStyle = b.win;
      for (let y = horizon - h + 50; y < horizon + 40; y += 10) {
        for (let x = b.x + 4; x < b.x + b.w - 8; x += 8) {
          if (((x + y + i) % 17) < 6 + city) {
            ctx.globalAlpha = 0.35 + ((x + y) % 5) * 0.08;
            ctx.fillRect(x, y, 3, 4);
          }
        }
      }
      ctx.globalAlpha = 1;
    });
    if (city >= 1) {
      ctx.save();
      ctx.translate(28, horizon - 70);
      ctx.fillStyle = "#ff2d95";
      ctx.globalAlpha = 0.85;
      ctx.font = "bold 11px Syne, sans-serif";
      ctx.fillText("功德", 0, 0);
      ctx.fillStyle = "#3dba8a";
      ctx.fillText("CLOUD", 292, 18);
      ctx.restore();
    }
    if (city >= 3) {
      for (let i = 0; i < 3; i++) {
        const x = ((t * 30 + i * 140) % (W + 40)) - 20;
        const y = 90 + i * 18;
        ctx.fillStyle = "#ffe08a";
        ctx.globalAlpha = 0.7;
        ctx.fillRect(x, y, 10, 2);
        ctx.fillStyle = "#ff2d95";
        ctx.fillRect(x + 10, y, 3, 2);
      }
      ctx.globalAlpha = 1;
    }
    ctx.fillStyle = "#0a0c12";
    ctx.fillRect(0, 248, W, 40);
  }

  function drawMandala(ctx, snap, t) {
    const cx = 210, cy = 168;
    const rings = 2 + snap.upgrades.mandala;
    const fill = snap.need ? snap.fill / snap.need : 0;
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(t * 0.15 + bloomT * 2);
    for (let r = rings; r >= 1; r--) {
      const rad = 18 + r * 16;
      ctx.strokeStyle = r % 2 ? "rgba(201,162,39,.55)" : "rgba(61,186,138,.45)";
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.arc(0, 0, rad, 0, Math.PI * 2);
      ctx.stroke();
      const petals = 6 + r * 2;
      for (let i = 0; i < petals; i++) {
        const a = (Math.PI * 2 * i) / petals;
        ctx.save();
        ctx.rotate(a);
        ctx.fillStyle = r % 2 ? "rgba(255,224,138,.22)" : "rgba(255,45,149,.16)";
        ctx.beginPath();
        ctx.ellipse(rad, 0, 10, 4.5, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }
      if (snap.upgrades.mandala >= 2) {
        ctx.strokeStyle = "rgba(61,186,138,.35)";
        ctx.lineWidth = 1;
        for (let i = 0; i < 8; i++) {
          const a = (Math.PI * 2 * i) / 8;
          ctx.beginPath();
          ctx.moveTo(Math.cos(a) * 12, Math.sin(a) * 12);
          ctx.lineTo(Math.cos(a) * rad, Math.sin(a) * rad);
          ctx.stroke();
          ctx.strokeRect(Math.cos(a) * rad - 3, Math.sin(a) * rad - 3, 6, 6);
        }
      }
    }
    ctx.restore();
    ctx.strokeStyle = "#c9a227";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, 62, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, fill));
    ctx.stroke();
    if (bloomT > 0) {
      ctx.strokeStyle = "rgba(255,224,138," + bloomT + ")";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(cx, cy, 70 + (1 - bloomT) * 40, 0, Math.PI * 2);
      ctx.stroke();
    }
  }

  function drawBeads(ctx, t, charms) {
    const n = 14 + Math.min(8, charms.length);
    for (let i = 0; i < n; i++) {
      const a = -0.2 + i * 0.13 + Math.sin(t + i) * 0.02;
      const x = 70 + Math.cos(a) * 18;
      const y = 300 + i * 9 + Math.sin(t * 2 + i) * 1.5;
      ctx.fillStyle = i % 3 === 0 ? "#3dba8a" : i % 3 === 1 ? "#c9a227" : "#ff2d95";
      ctx.beginPath();
      ctx.arc(x, y, 3.4, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.strokeStyle = "rgba(201,162,39,.45)";
    ctx.beginPath();
    ctx.moveTo(86, 298);
    ctx.quadraticCurveTo(74, 360, 82, 430);
    ctx.stroke();
  }

  function drawAltarBody(ctx, altar) {
    const y = 430;
    if (altar >= 2) {
      ctx.fillStyle = "#1a2240";
      ctx.fillRect(40, 250, 8, 200);
      ctx.fillRect(372, 250, 8, 200);
      ctx.strokeStyle = "#c9a227";
      ctx.strokeRect(36, 246, 16, 16);
      ctx.strokeRect(368, 246, 16, 16);
    }
    ctx.fillStyle = altar >= 1 ? "#2a1a12" : "#241810";
    ctx.beginPath();
    ctx.moveTo(36, y + 70);
    ctx.lineTo(70, y);
    ctx.lineTo(350, y);
    ctx.lineTo(384, y + 70);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = altar >= 1 ? "#8a5a2b" : "#5a3a1c";
    ctx.fillRect(60, y - 18, 300, 22);
    ctx.fillStyle = "#c9a227";
    ctx.fillRect(60, y - 20, 300, 3);
    if (altar >= 1) {
      ctx.strokeStyle = "rgba(255,45,149,.45)";
      ctx.strokeRect(80, y + 8, 260, 36);
      ctx.font = "9px Syne, sans-serif";
      ctx.fillStyle = "#3dba8a";
      ctx.fillText("SHRINE NODE 07", 150, y + 30);
    }
    ctx.fillStyle = "#3a2416";
    ctx.fillRect(188, 456, 44, 18);
    ctx.fillStyle = "#8a5a2b";
    ctx.beginPath();
    ctx.arc(210, 456, 14, Math.PI, 0);
    ctx.fill();
  }

  function fishColors(lv) {
    if (lv >= 4) return { body: "#1a2438", hi: "#3d5a58", edge: "#7affc8", glow: "rgba(61,186,138,.45)", eye: "#ffe08a" };
    if (lv >= 3) return { body: "#16382c", hi: "#2a6a4e", edge: "#3dba8a", glow: "rgba(61,186,138,.3)", eye: "#ffe08a" };
    if (lv >= 2) return { body: "#6b4220", hi: "#c9a227", edge: "#ffe08a", glow: "rgba(201,162,39,.28)", eye: "#1a1008" };
    if (lv >= 1) return { body: "#7a1f18", hi: "#d45a3a", edge: "#ffb347", glow: "rgba(255,80,40,.25)", eye: "#1a1008" };
    return { body: "#6b4224", hi: "#c9a227", edge: "#ffe08a", glow: "rgba(201,162,39,.28)", eye: "#1a1008" };
  }

  function drawFish(ctx, lv, t) {
    const cx = 210, cy = 400 + Math.sin(t * 1.4) * 2 + strikeT * 4;
    const col = fishColors(lv);
    ctx.save();
    ctx.translate(cx, cy);
    ctx.scale(1 + strikeT * 0.04, 1 - strikeT * 0.03);
    ctx.shadowColor = col.glow;
    ctx.shadowBlur = 18 + strikeT * 20;
    const body = ctx.createRadialGradient(-18, -10, 8, 0, 0, 82);
    body.addColorStop(0, col.hi);
    body.addColorStop(0.45, col.body);
    body.addColorStop(1, "#1a1008");
    ctx.fillStyle = body;
    ctx.beginPath();
    ctx.ellipse(0, 0, 78, 42, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.strokeStyle = col.edge;
    ctx.lineWidth = 2.4;
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(70, -6);
    ctx.quadraticCurveTo(96, -28, 88, 0);
    ctx.quadraticCurveTo(96, 24, 70, 8);
    ctx.fillStyle = col.body;
    ctx.fill();
    ctx.stroke();
    for (let i = -3; i <= 3; i++) {
      ctx.beginPath();
      ctx.ellipse(i * 14, 0, 10, 16, 0, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255,224,138,.18)";
      ctx.stroke();
    }
    ctx.fillStyle = col.eye;
    ctx.beginPath();
    ctx.arc(-40, -8, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#070b16";
    ctx.beginPath();
    ctx.arc(-39, -8, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = col.edge;
    ctx.beginPath();
    ctx.arc(-52, 6, 8, 0.2, 2.6);
    ctx.stroke();
    if (lv >= 3) {
      ctx.strokeStyle = "rgba(61,186,138,.55)";
      ctx.beginPath();
      ctx.moveTo(-20, -20); ctx.lineTo(20, 20);
      ctx.moveTo(-20, 20); ctx.lineTo(20, -20);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawHand(ctx, lv, t) {
    const impact = handT < 0.45 ? handT / 0.45 : 1 - (handT - 0.45) / 0.55;
    const y = 318 - (1 - Math.min(1, handT * 1.1)) * 50 + impact * 36;
    const x = 268;
    const hands = lv >= 3 ? 2 : 1;
    for (let h = 0; h < hands; h++) {
      const ox = h ? -120 : 0;
      ctx.save();
      ctx.translate(x + ox, y);
      ctx.rotate(-0.55 + impact * 0.7);
      ctx.globalAlpha = lv === 0 ? 0.45 : 0.85;
      ctx.strokeStyle = lv >= 2 ? "#ffe08a" : "#7affc8";
      ctx.fillStyle = lv >= 2 ? "rgba(201,162,39,.12)" : "rgba(61,186,138,.1)";
      ctx.lineWidth = 1.6;
      roundRect(ctx, -16, -10, 28, 36, 6);
      ctx.fill(); ctx.stroke();
      for (let i = 0; i < 4; i++) {
        ctx.beginPath();
        ctx.moveTo(-12 + i * 7, -10);
        ctx.lineTo(-12 + i * 7, -28 - (i === 1 ? 6 : 0));
        ctx.lineTo(-6 + i * 7, -28);
        ctx.stroke();
      }
      ctx.beginPath();
      ctx.moveTo(10, 6);
      ctx.lineTo(22, -4);
      ctx.stroke();
      if (lv >= 2) {
        ctx.strokeStyle = "rgba(255,45,149,.5)";
        ctx.strokeRect(-8, 0, 12, 8);
      }
      ctx.restore();
    }
    ctx.globalAlpha = 1;
  }

  function drawPulse(ctx, snap) {
    const p = snap.pulse;
    const near = Math.abs(p - 0.5);
    const r = 40 + near * 80;
    const a = Math.max(0, 1 - near * 4);
    ctx.strokeStyle = snap.inWindow ? "rgba(255,224,138," + a + ")" : "rgba(255,45,149," + a * 0.55 + ")";
    ctx.lineWidth = snap.inWindow ? 3 : 1.4;
    ctx.beginPath();
    ctx.arc(210, 400, r, 0, Math.PI * 2);
    ctx.stroke();
  }

  function drawOfuda(ctx, charms) {
    charms.slice(-4).forEach((c, i) => {
      const x = 300 + i * 8;
      const y = 310 + i * 14;
      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(0.1 * i);
      ctx.fillStyle = "#f2e4c9";
      ctx.fillRect(0, 0, 18, 36);
      ctx.strokeStyle = "#ff2d95";
      ctx.strokeRect(0, 0, 18, 36);
      ctx.fillStyle = "#8a1a2a";
      ctx.font = "10px Noto Serif SC, serif";
      ctx.fillText("符", 3, 22);
      ctx.restore();
    });
  }

  function drawFlash(ctx) {
    if (flash <= 0) return;
    ctx.fillStyle = "rgba(255,224,138," + flash * 0.16 + ")";
    ctx.fillRect(0, 0, W, H);
  }

  function drawHUDGlass(ctx, snap) {
    ctx.fillStyle = "rgba(7,11,22,.35)";
    roundRect(ctx, 12, 12, 120, 36, 6);
    ctx.fill();
    ctx.font = "9px Syne, sans-serif";
    ctx.fillStyle = "#8aa0b8";
    ctx.fillText("MERIT", 20, 24);
    ctx.fillStyle = "#ffe08a";
    ctx.font = "bold 16px Syne, sans-serif";
    ctx.fillText(String(snap.merit), 20, 42);
  }

  function draw(ctx, snap, now) {
    const t = now * 0.001;
    drawSky(ctx, snap.upgrades.city);
    drawCity(ctx, snap.upgrades.city, t);
    drawMandala(ctx, snap, t);
    drawAltarBody(ctx, snap.upgrades.altar);
    drawBeads(ctx, t, snap.charms);
    drawOfuda(ctx, snap.charms);
    drawFish(ctx, snap.upgrades.fish, t);
    drawHand(ctx, snap.upgrades.hand, t);
    drawPulse(ctx, snap);
    drawHUDGlass(ctx, snap);
    drawFlash(ctx);
    return { fish: { x: 210, y: 400 }, incense: { x: 210, y: 448 }, lotus: { x: 210, y: 168 } };
  }

  function hitTest(x, y) {
    const dx = x - 210, dy = y - 400;
    return (dx * dx) / (90 * 90) + (dy * dy) / (55 * 55) <= 1.15;
  }

  return { W, H, draw, update, punch, complete, hitTest, get strikeT() { return strikeT; } };
})();

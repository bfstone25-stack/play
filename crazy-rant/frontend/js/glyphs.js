var GLYPHS = (() => {
  const META = {
    ok: { color: "#eab308", accent: "#fde047", shape: "dot" },
    lie: { color: "#22d3ee", accent: "#a5f3fc", shape: "smile" },
    teach: { color: "#06b6d4", accent: "#67e8f9", shape: "hook" },
    quit: { color: "#e11d48", accent: "#fb7185", shape: "slash" },
    legend: { color: "#f8fafc", accent: "#eab308", shape: "burst" },
  };

  function bubblePath(ctx, x, y, r) {
    ctx.beginPath();
    ctx.moveTo(x - r * 0.7, y - r * 0.15);
    ctx.quadraticCurveTo(x - r, y - r * 0.85, x, y - r);
    ctx.quadraticCurveTo(x + r, y - r * 0.85, x + r * 0.75, y - r * 0.1);
    ctx.quadraticCurveTo(x + r * 0.9, y + r * 0.55, x + r * 0.15, y + r * 0.55);
    ctx.lineTo(x - r * 0.15, y + r * 0.95);
    ctx.lineTo(x - r * 0.05, y + r * 0.5);
    ctx.quadraticCurveTo(x - r * 0.95, y + r * 0.45, x - r * 0.7, y - r * 0.15);
    ctx.closePath();
  }

  function strokes(ctx, x, y, r, seed, color) {
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = Math.max(1.2, r * 0.16);
    ctx.lineCap = "round";
    const s = seed % 5;
    if (s === 0) {
      ctx.beginPath(); ctx.moveTo(x - r * 0.35, y - r * 0.25); ctx.lineTo(x + r * 0.3, y + r * 0.05); ctx.stroke();
      ctx.beginPath(); ctx.arc(x, y - r * 0.05, r * 0.22, 0.2, 3.1); ctx.stroke();
    } else if (s === 1) {
      ctx.beginPath(); ctx.moveTo(x - r * 0.28, y - r * 0.3); ctx.lineTo(x - r * 0.28, y + r * 0.22); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(x - r * 0.28, y); ctx.lineTo(x + r * 0.32, y - r * 0.08); ctx.stroke();
    } else if (s === 2) {
      ctx.beginPath(); ctx.arc(x, y - r * 0.08, r * 0.2, 0, Math.PI * 2); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(x - r * 0.32, y + r * 0.18); ctx.quadraticCurveTo(x, y + r * 0.32, x + r * 0.32, y + r * 0.12); ctx.stroke();
    } else if (s === 3) {
      ctx.beginPath(); ctx.moveTo(x - r * 0.3, y - r * 0.22); ctx.lineTo(x + r * 0.28, y + r * 0.2); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(x + r * 0.28, y - r * 0.22); ctx.lineTo(x - r * 0.3, y + r * 0.2); ctx.stroke();
    } else {
      for (let i = 0; i < 5; i++) {
        const a = (i / 5) * Math.PI * 2 - 0.4;
        ctx.beginPath();
        ctx.moveTo(x, y - r * 0.04);
        ctx.lineTo(x + Math.cos(a) * r * 0.34, y - r * 0.04 + Math.sin(a) * r * 0.34);
        ctx.stroke();
      }
    }
    ctx.restore();
  }

  function roundRect(ctx, x, y, w, h, r) {
    const rr = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + rr, y);
    ctx.arcTo(x + w, y, x + w, y + h, rr);
    ctx.arcTo(x + w, y + h, x, y + h, rr);
    ctx.arcTo(x, y + h, x, y, rr);
    ctx.arcTo(x, y, x + w, y, rr);
    ctx.closePath();
  }

  function drawBubble(ctx, x, y, r, kind, seed) {
    const m = META[kind] || META.ok;
    ctx.save();
    bubblePath(ctx, x, y, r);
    ctx.fillStyle = m.color;
    ctx.fill();
    ctx.lineWidth = Math.max(1.5, r * 0.14);
    ctx.strokeStyle = "#0a0a0a";
    ctx.stroke();
    strokes(ctx, x, y - r * 0.08, r, seed, "#0a0a0a");
    ctx.restore();
  }

  function charsOf(text) {
    return Array.from(String(text || "!"));
  }

  function fillOfuda(ctx, w, h, vermillion) {
    ctx.fillStyle = "#f4ead3";
    ctx.fillRect(-w / 2, -h / 2, w, h);
    ctx.strokeStyle = vermillion || "#c2412d";
    ctx.lineWidth = 2.4;
    ctx.strokeRect(-w / 2 + 1, -h / 2 + 1, w - 2, h - 2);
    ctx.lineWidth = 1;
    ctx.strokeRect(-w / 2 + 4, -h / 2 + 4, w - 8, h - 8);
    ctx.fillStyle = vermillion || "#c2412d";
    ctx.fillRect(-w / 2 + 5, -h / 2 + 5, w - 10, 3);
  }

  function verticalInk(ctx, chars, font, color) {
    ctx.fillStyle = color || "#1a120c";
    ctx.font = "700 " + font + "px \"Noto Serif JP\",\"Yu Mincho\",\"Songti SC\",\"Noto Serif SC\",serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    const lh = font + 1;
    const total = chars.length * lh;
    let y = -total / 2 + lh / 2;
    for (let i = 0; i < chars.length; i++) {
      ctx.fillText(chars[i], 0, y);
      y += lh;
    }
  }

  function hanko(ctx, y, color) {
    ctx.save();
    ctx.strokeStyle = color || "#9f1239";
    ctx.fillStyle = "rgba(159,18,57,.18)";
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.arc(0, y, 5.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  function drawOfuda(ctx, text, font, vermillion, wide) {
    const chars = charsOf(text).slice(0, 4);
    const lh = font + 1;
    const w = wide || Math.max(18, font + 8);
    const h = chars.length * lh + 22;
    fillOfuda(ctx, w, h, vermillion);
    verticalInk(ctx, chars, font, "#1a120c");
    hanko(ctx, h / 2 - 10, vermillion);
    return { w, h };
  }

  function drawShot(ctx, s, lang) {
    const m = META[s.kind] || META.ok;
    const text = (typeof PHRASES !== "undefined") ? PHRASES.shot(lang || "en", s.kind) : (s.kind || "!");
    ctx.save();
    ctx.translate(s.x, s.y);
    drawOfuda(ctx, text, s.font || 11, m.color, 16);
    ctx.restore();
  }

  function drawWord(ctx, h) {
    const text = h.text || "!";
    const font = h.font || 13;
    const vermillion = h.color || "#c2412d";
    ctx.save();
    ctx.translate(h.x, h.y);
    if (h.shape === "stamp") {
      const rad = 13;
      ctx.fillStyle = "#f4ead3";
      ctx.beginPath(); ctx.arc(0, 0, rad, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = vermillion;
      ctx.lineWidth = 2.2;
      ctx.stroke();
      ctx.beginPath(); ctx.arc(0, 0, rad - 3.5, 0, Math.PI * 2); ctx.stroke();
      verticalInk(ctx, charsOf(text).slice(0, 2), 11, "#1a120c");
    } else if (h.shape === "needle") {
      const chars = charsOf(text).slice(0, 3);
      const w = 12;
      const hgt = chars.length * (font + 1) + 14;
      ctx.fillStyle = "#f4ead3";
      ctx.fillRect(-w / 2, -hgt / 2, w, hgt);
      ctx.strokeStyle = vermillion;
      ctx.lineWidth = 1.6;
      ctx.strokeRect(-w / 2 + 0.5, -hgt / 2 + 0.5, w - 1, hgt - 1);
      verticalInk(ctx, chars, font, vermillion);
    } else if (h.shape === "giant") {
      drawOfuda(ctx, text, font, vermillion, 28);
    } else {
      drawOfuda(ctx, text, font, vermillion, h.shape === "bar" ? 18 : 20);
    }
    ctx.restore();
  }

  function drawSmile(ctx, x, y, r, smug) {
    ctx.save();
    ctx.fillStyle = "#eab308";
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = "#0a0a0a";
    ctx.lineWidth = Math.max(1.4, r * 0.12);
    ctx.stroke();
    ctx.fillStyle = "#0a0a0a";
    ctx.beginPath(); ctx.arc(x - r * 0.28, y - r * 0.12, r * 0.1, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(x + r * 0.28, y - r * 0.12, r * 0.1, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath();
    ctx.arc(x, y + r * 0.08, r * (smug ? 0.42 : 0.32), 0.15, Math.PI - 0.15);
    ctx.stroke();
    ctx.restore();
  }

  function drawSun(ctx, x, y, r, t) {
    ctx.save();
    ctx.strokeStyle = "#eab308";
    ctx.lineWidth = Math.max(1.2, r * 0.12);
    for (let i = 0; i < 10; i++) {
      const a = t * 0.8 + (i / 10) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(x + Math.cos(a) * r * 0.7, y + Math.sin(a) * r * 0.7);
      ctx.lineTo(x + Math.cos(a) * r * 1.25, y + Math.sin(a) * r * 1.25);
      ctx.stroke();
    }
    ctx.fillStyle = "#fde047";
    ctx.beginPath(); ctx.arc(x, y, r * 0.62, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = "#0a0a0a";
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.restore();
  }

  function drawPoster(ctx, x, y, w, h, rot, cracked) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(rot);
    ctx.fillStyle = "#f8fafc";
    ctx.strokeStyle = "#0a0a0a";
    ctx.lineWidth = 2;
    ctx.fillRect(-w / 2, -h / 2, w, h);
    ctx.strokeRect(-w / 2, -h / 2, w, h);
    ctx.fillStyle = "#22d3ee";
    ctx.fillRect(-w / 2, -h / 2, w, h * 0.18);
    ctx.fillStyle = "#eab308";
    ctx.beginPath(); ctx.arc(0, h * 0.04, Math.min(w, h) * 0.18, 0, Math.PI * 2); ctx.fill();
    if (cracked) {
      ctx.strokeStyle = "#e11d48";
      ctx.beginPath();
      ctx.moveTo(-w * 0.3, -h * 0.2);
      ctx.lineTo(0, 0);
      ctx.lineTo(w * 0.25, h * 0.28);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawShard(ctx, x, y, r, color) {
    ctx.save();
    ctx.fillStyle = color;
    ctx.strokeStyle = "#0a0a0a";
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(x, y - r);
    ctx.lineTo(x + r * 0.7, y + r * 0.4);
    ctx.lineTo(x - r * 0.7, y + r * 0.4);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  function drawPlayer(ctx, x, y, t, hurt, smear) {
    ctx.save();
    if (smear && !hurt) {
      ctx.globalAlpha = 0.22;
      ctx.fillStyle = "#22d3ee";
      ctx.fillRect(x - 18, y - 10, 12, 22);
      ctx.globalAlpha = 1;
    }
    if (hurt) ctx.globalAlpha = 0.45 + Math.sin(t * 40) * 0.25;
    ctx.fillStyle = "#f8fafc";
    ctx.strokeStyle = "#0a0a0a";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x - 9, y + 4);
    ctx.lineTo(x + 10, y + 2);
    ctx.lineTo(x + 8, y + 18);
    ctx.lineTo(x - 11, y + 18);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = "#e11d48";
    ctx.beginPath();
    ctx.moveTo(x, y + 5);
    ctx.lineTo(x + 5, y + 16);
    ctx.lineTo(x - 4, y + 16);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#f8fafc";
    ctx.beginPath(); ctx.arc(x + 1, y - 6, 7.5, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    ctx.strokeStyle = "#0a0a0a";
    ctx.beginPath(); ctx.moveTo(x - 2, y - 8); ctx.lineTo(x + 4, y - 6); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(x - 12, y + 8); ctx.lineTo(x - 20, y + 2); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(x + 10, y + 8); ctx.lineTo(x + 18, y + 14); ctx.stroke();
    ctx.restore();
  }

  function drawBurst(ctx, x, y, life, color) {
    ctx.save();
    ctx.globalAlpha = Math.max(0, life);
    ctx.strokeStyle = color || "#eab308";
    ctx.lineWidth = 2;
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * Math.PI * 2;
      const r = 8 + (1 - life) * 18;
      ctx.beginPath();
      ctx.moveTo(x + Math.cos(a) * r * 0.3, y + Math.sin(a) * r * 0.3);
      ctx.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawSpeedLines(ctx, w, h, t) {
    ctx.save();
    ctx.strokeStyle = "rgba(194,65,45,.22)";
    ctx.lineWidth = 1;
    for (let i = 0; i < 10; i++) {
      const y = ((i * 67 + t * 90) % h);
      ctx.beginPath();
      ctx.moveTo(w * 0.08, y);
      ctx.lineTo(w * 0.92, y + 8);
      ctx.stroke();
    }
    ctx.restore();
  }

  function paintSig(el, kind) {
    const m = META[kind] || META.ok;
    el.innerHTML = "";
    const c = document.createElement("canvas");
    c.width = 96; c.height = 56;
    c.className = "sig";
    const g = c.getContext("2d");
    g.scale(1, 1);
    const dl = document.documentElement.lang || "";
    const shotLang = dl.indexOf("zh") === 0 ? "zh" : dl.indexOf("ja") === 0 ? "ja" : "en";
    drawShot(g, { x: 40, y: 28, kind, font: 11, rot: 0 }, shotLang);
    el.appendChild(c);
    el.style.borderColor = m.color;
    return m;
  }

  return { META, drawBubble, drawShot, drawWord, drawSmile, drawSun, drawPoster, drawShard, drawPlayer, drawBurst, drawSpeedLines, paintSig };
})();

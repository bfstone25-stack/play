/* Canvas 2D presentation. Owns no numbers. */
var BMRender = (() => {
  const RED = "#e23b2f", COBALT = "#1e4cff", YELLOW = "#f5d031", BLACK = "#0a0b10";

  function fit(canvas) {
    const dpr = Math.min(2, (typeof devicePixelRatio !== "undefined" ? devicePixelRatio : 1) || 1);
    canvas.width = BMCore.W * dpr;
    canvas.height = BMCore.H * dpr;
    const ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return ctx;
  }

  function carpet(ctx, t) {
    ctx.fillStyle = "#12131a";
    ctx.fillRect(0, 0, BMCore.W, BMCore.H);
    ctx.strokeStyle = "rgba(255,255,255,.04)";
    ctx.lineWidth = 1;
    const off = (t * 14) % 40;
    for (let y = -40 + off; y < BMCore.H; y += 40) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(BMCore.W, y); ctx.stroke();
    }
    for (let x = 0; x < BMCore.W; x += 40) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, BMCore.H); ctx.stroke();
    }
  }

  function draw(ctx, run, t) {
    carpet(ctx, t);

    // pickups
    run.picks.forEach(p => {
      ctx.fillStyle = YELLOW;
      ctx.globalAlpha = 0.5 + 0.5 * Math.sin(t * 8);
      ctx.beginPath(); ctx.arc(p.x, p.y, 10, 0, 6.3); ctx.fill();
      ctx.globalAlpha = 1;
      ctx.fillStyle = BLACK; ctx.font = "700 9px ui-monospace,monospace";
      ctx.textAlign = "center"; ctx.fillText("+", p.x, p.y + 3);
    });

    // foes
    run.foes.forEach(f => {
      ctx.fillStyle = f.hit > 0 ? "#ffffff" : f.color;
      ctx.beginPath(); ctx.arc(f.x, f.y, f.r, 0, 6.3); ctx.fill();
      ctx.fillStyle = "rgba(10,11,16,.75)";
      ctx.fillRect(f.x - f.r, f.y - f.r - 4, f.r * 2, 2);
    });

    // boss
    if (run.boss) {
      const b = run.boss;
      ctx.fillStyle = b.hit > 0 ? "#fff" : RED;
      ctx.fillRect(b.x - b.r, b.y - b.r, b.r * 2, b.r * 2);
      ctx.fillStyle = BLACK;
      ctx.fillRect(b.x - b.r + 6, b.y - 8, b.r * 2 - 12, 5);
    }

    // incoming
    ctx.fillStyle = "#ff8a3d";
    run.foeShots.forEach(s => { ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, 6.3); ctx.fill(); });

    // player shots — rant shots carry the phrase
    run.shots.forEach(s => {
      if (s.text) {
        ctx.fillStyle = YELLOW;
        ctx.font = "800 15px ui-monospace,'PingFang SC',monospace";
        ctx.textAlign = "center";
        ctx.fillText(s.text, s.x, s.y + 5);
      } else {
        ctx.fillStyle = "#cfe3ff";
        ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, 6.3); ctx.fill();
      }
    });

    // party orbiting
    (run.profile.party || []).forEach((id, i) => {
      const p = BMData.PARTY.find(x => x.id === id);
      if (!p) return;
      const a = t * 1.6 + i * 2.1;
      ctx.fillStyle = p.color;
      ctx.beginPath(); ctx.arc(run.px + Math.cos(a) * 34, run.py + Math.sin(a) * 34, 5, 0, 6.3); ctx.fill();
    });

    // player
    ctx.fillStyle = run.hurtCd > 0 ? "#fff" : COBALT;
    ctx.beginPath(); ctx.arc(run.px, run.py, 11, 0, 6.3); ctx.fill();
    ctx.strokeStyle = YELLOW; ctx.lineWidth = 2; ctx.stroke();

    hud(ctx, run);
  }

  function hud(ctx, run) {
    ctx.fillStyle = "rgba(10,11,16,.85)";
    ctx.fillRect(0, 0, BMCore.W, 52);
    // hp
    ctx.fillStyle = "#2a1620";
    ctx.fillRect(10, 10, 240, 12);
    ctx.fillStyle = RED;
    ctx.fillRect(10, 10, 240 * Math.max(0, run.hp / run.maxHp), 12);
    // xp
    ctx.fillStyle = "#12203a";
    ctx.fillRect(10, 26, 240, 6);
    ctx.fillStyle = COBALT;
    ctx.fillRect(10, 26, 240 * Math.min(1, run.xp / BMCore.xpNeeded(run.level)), 6);
    ctx.fillStyle = YELLOW;
    ctx.font = "800 12px ui-monospace,monospace";
    ctx.textAlign = "left";
    ctx.fillText("LV " + run.level, 258, 21);
    ctx.fillStyle = "#8b8d99";
    ctx.font = "700 10px ui-monospace,monospace";
    const left = Math.max(0, Math.ceil(run.day.dur - run.t));
    ctx.fillText(run.phase === "boss" ? "BOSS" : left + "s", 258, 33);
    if (run.day.mode === "rant") {
      ctx.textAlign = "right";
      ctx.fillStyle = YELLOW;
      ctx.fillText(run.lastPattern.toUpperCase() + " ×" + run.rantCombo.length, BMCore.W - 10, 21);
    }
    if (run.boss) {
      ctx.fillStyle = "#2a1620";
      ctx.fillRect(10, 40, BMCore.W - 20, 6);
      ctx.fillStyle = YELLOW;
      ctx.fillRect(10, 40, (BMCore.W - 20) * Math.max(0, run.boss.hp / run.boss.maxHp), 6);
    }
  }

  return { fit, draw };
})();

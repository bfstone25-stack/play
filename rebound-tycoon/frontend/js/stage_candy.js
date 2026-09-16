/* stage_candy.js — the portal-facing look for Rebound Tycoon.
 *
 * Same contract as stage.js (draw / spark / burstCoins / spray / floatText), so game.js is
 * untouched and the renderer is swappable. It draws the pre-rendered candy sprites from
 * assets/candy/ on a bright playfield: chubby shapes, macaron palette, dark contours.
 *
 * Why sprites and not WebGL: the casual portals' house style reads as 3D but ships as 2D.
 * The parts were modelled and lit in Blender (ops/assets3d/candy_kit.py) and rendered to
 * PNG, so the runtime stays a 2D canvas with no GPU dependency and the whole set is 248KB.
 */
window.REBOUND_STAGE_CANDY = (() => {
  const fx = { sparks: [], coins: [], drops: [], floats: [], t: 0 };
  const IMG = {};
  let loaded = 0, wanted = 0;
  ["bumper_mint", "bumper_sky", "bumper_coral", "ball", "target", "flipper", "saucer", "rail"]
    .forEach((n) => {
      wanted++;
      const i = new Image();
      i.onload = () => { loaded++; };
      i.onerror = () => { loaded++; };
      i.src = "assets/candy/" + n + ".png";
      IMG[n] = i;
    });
  const ready = () => loaded >= wanted;

  // macaron palette - bright ground, saturated accents, dark contour
  const C = {
    cloth: ["#fdf3e7", "#ffe7d2"], rim: "#2a1b34", lane: "#ffd9a8",
    ink: "#3a2a4a", pop: "#ff5c8a", mint: "#5ef0bd", sky: "#5cb8ff", lemon: "#ffd44d",
  };
  const BUMP = ["bumper_mint", "bumper_sky", "bumper_coral"];

  function resize(c) {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const w = c.clientWidth || 600, h = c.clientHeight || 420;
    if (c.width !== w * dpr || c.height !== h * dpr) { c.width = w * dpr; c.height = h * dpr; }
    return { w, h, dpr };
  }
  const px = (v, w) => v * w, py = (v, h) => v * h;

  function sprite(g, img, cx, cy, w, rot) {
    if (!img || !img.complete || !img.naturalWidth) return false;
    const h = w * (img.naturalHeight / img.naturalWidth);
    g.save(); g.translate(cx, cy); if (rot) g.rotate(rot);
    g.drawImage(img, -w / 2, -h / 2, w, h); g.restore();
    return true;
  }

  function tickFx(dt, reduce) {
    fx.t += dt;
    if (reduce) { fx.sparks.length = fx.coins.length = fx.drops.length = fx.floats.length = 0; return; }
    [fx.sparks, fx.coins, fx.drops, fx.floats].forEach((L) => {
      for (let i = L.length - 1; i >= 0; i--) {
        const p = L[i]; p.age += dt;
        p.x += (p.vx || 0) * dt; p.y += (p.vy || 0) * dt;
        if (p.vy !== undefined) p.vy += 120 * dt;
        if (p.age >= p.life) L.splice(i, 1);
      }
    });
  }

  function draw(canvas, state, opts) {
    const { w, h, dpr } = resize(canvas);
    const g = canvas.getContext("2d");
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    tickFx(opts.dt || 0.016, opts.reduce);
    const K = globalThis;

    const bg = g.createLinearGradient(0, 0, 0, h);
    bg.addColorStop(0, C.cloth[0]); bg.addColorStop(1, C.cloth[1]);
    g.fillStyle = bg; g.fillRect(0, 0, w, h);

    // playfield card with a fat rounded border - the "chunky" cue
    const T = K.TABLE || { left: 0.075, right: 0.855, top: 0.055 };
    g.save();
    g.beginPath();
    g.roundRect(px(T.left - 0.03, w), py(T.top - 0.03, h),
                px(T.right - T.left + 0.06, w), py(0.94, h), 26);
    g.fillStyle = "#fffaf2"; g.fill();
    g.lineWidth = 9; g.strokeStyle = C.rim; g.stroke();
    g.clip();

    g.strokeStyle = "rgba(94,240,189,.35)"; g.lineWidth = 5;
    for (let i = 1; i <= 4; i++) {
      g.beginPath(); g.arc(px(0.46, w), py(0.46, h), px(0.075 * i, w), 0, Math.PI * 2); g.stroke();
    }

    g.strokeStyle = C.rim; g.lineWidth = 8; g.lineCap = "round";
    (K.WALLS || []).forEach((wl) => {
      g.beginPath(); g.moveTo(px(wl[0], w), py(wl[1], h)); g.lineTo(px(wl[2], w), py(wl[3], h)); g.stroke();
    });

    (K.TARGETS || []).forEach((t, i) => {
      const down = state.targetDown && state.targetDown[i];
      g.globalAlpha = down ? 0.35 : 1;
      if (!sprite(g, IMG.target, px(t.x + t.w / 2, w), py(t.y + t.h / 2, h), px(t.w * 1.5, w))) {
        g.fillStyle = down ? "#d9cfe6" : C.pop;
        g.fillRect(px(t.x, w), py(t.y, h), px(t.w, w), py(t.h, h));
      }
      g.globalAlpha = 1;
    });

    const S = K.SAUCER || { x: 0.46, y: 0.58, r: 0.028 };
    sprite(g, IMG.saucer, px(S.x, w), py(S.y, h), px(S.r * 4.2, w));

    (K.BUMPERS || []).forEach((b, i) => {
      const flash = (state.bumperFlash && state.bumperFlash[i]) || 0;
      const scale = 1 + Math.min(flash, 0.14) * 1.6;
      if (!sprite(g, IMG[BUMP[i % BUMP.length]], px(b.x, w), py(b.y, h), px(b.r * 2.9, w) * scale)) {
        g.fillStyle = flash > 0 ? C.lemon : C.mint;
        g.beginPath(); g.arc(px(b.x, w), py(b.y, h), px(b.r, w), 0, Math.PI * 2); g.fill();
      }
    });

    const FL = K.REBOUND?.FLIP_LEN ?? 0.115;
    [[K.LEFT_PIVOT, state.flipL, 1], [K.RIGHT_PIVOT, state.flipR, 1]].forEach(([p, ang]) => {
      if (!p) return;
      const cx = px(p.x, w), cy = py(p.y, h), len = px(FL * 1.55, w);
      const a = ang || 0;
      sprite(g, IMG.flipper, cx + Math.cos(a) * len * 0.42, cy + Math.sin(a) * len * 0.42, len, a);
    });

    if (state.ball) {
      sprite(g, IMG.ball, px(state.ball.x, w), py(state.ball.y, h), px((K.REBOUND?.BALL_R ?? 0.018) * 2.6, w));
    }

    if (state.mode === "plunge") {
      g.fillStyle = C.ink; g.font = "800 15px ui-rounded, ui-sans-serif, system-ui";
      g.textAlign = "center";
      g.fillText(opts.hint || "HOLD SPACE", px(0.465, w), py(0.72, h));
    }

    fx.coins.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = C.lemon; g.strokeStyle = C.rim; g.lineWidth = 2.5;
      g.beginPath(); g.arc(p.x, p.y, 7, 0, Math.PI * 2); g.fill(); g.stroke();
    });
    fx.sparks.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.fillStyle = p.color || C.pop;
      g.beginPath(); g.arc(p.x, p.y, 3.5, 0, Math.PI * 2); g.fill();
    });
    fx.drops.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life; g.fillStyle = C.sky;
      g.beginPath(); g.arc(p.x, p.y, 3, 0, Math.PI * 2); g.fill();
    });
    g.globalAlpha = 1;
    g.restore();

    fx.floats.forEach((p) => {
      g.globalAlpha = 1 - p.age / p.life;
      g.font = "800 17px ui-rounded, ui-sans-serif, system-ui"; g.textAlign = "center";
      g.lineWidth = 4; g.strokeStyle = "#fffaf2"; g.strokeText(p.text, p.x, p.y);
      g.fillStyle = C.pop; g.fillText(p.text, p.x, p.y);
    });
    g.globalAlpha = 1;
    return true;
  }

  return {
    draw, ready,
    spark: (x, y, color) => { for (let i = 0; i < 8; i++) fx.sparks.push({ x, y, vx: (Math.random()-.5)*180, vy: (Math.random()-.5)*180, life: .3, age: 0, color }); },
    burstCoins: (x, y, n) => { for (let i = 0; i < (n||6); i++) fx.coins.push({ x, y, vx: (Math.random()-.4)*80, vy: -30-Math.random()*60, life: .6, age: 0 }); },
    spray: (x, y, n) => { for (let i = 0; i < (n||8); i++) fx.drops.push({ x, y, vx: (Math.random()-.5)*220, vy: -20-Math.random()*140, life: .35, age: 0 }); },
    floatText: (x, y, text) => fx.floats.push({ x, y, text, life: .9, age: 0 }),
    fx,
  };
})();

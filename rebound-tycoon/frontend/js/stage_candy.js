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
  const BACKDROP = new Image();
  BACKDROP.src = "assets/candy/backdrop.jpg";
  ["bumper_mint", "bumper_sky", "bumper_coral", "ball", "target", "flipper", "saucer", "rail",
     "guard_idle", "guard_cheer", "guard_oops"]
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
    // dreamy sky, not a neutral card: lavender -> rose -> peach, the palette the portal's
    // cute-casual shelf actually uses.
    sky: ["#b8a6f0", "#f3a8d8", "#ffcfa8"],
    board: ["#4a2a6e", "#33195a"], rim: "#ffd44d", rimDark: "#ff7ab8",
    ink: "#5a3a6e", pop: "#ff5c8a", mint: "#5ef0bd", blue: "#5cb8ff", lemon: "#ffd44d",
  };
  // decoration is generated once and reused, so it does not crawl between frames
  const DECO = (() => {
    const clouds = [], stars = [], bokeh = [];
    let s = 7;
    const rnd = () => (s = (s * 16807) % 2147483647) / 2147483647;
    for (let i = 0; i < 7; i++) clouds.push({ x: rnd(), y: 0.05 + rnd() * 0.85, r: 0.05 + rnd() * 0.05, a: 0.5 + rnd() * 0.4 });
    for (let i = 0; i < 26; i++) stars.push({ x: rnd(), y: rnd(), r: 2 + rnd() * 3.5, ph: rnd() * 6.28 });
    for (let i = 0; i < 12; i++) bokeh.push({ x: rnd(), y: rnd(), r: 0.02 + rnd() * 0.05, a: 0.10 + rnd() * 0.14 });
    return { clouds, stars, bokeh };
  })();

  function puff(g, cx, cy, r, alpha) {
    g.globalAlpha = alpha;
    g.fillStyle = "#ffffff";
    [[0, 0, 1], [-0.85, 0.18, 0.72], [0.85, 0.18, 0.72], [-0.42, -0.3, 0.66], [0.45, -0.28, 0.6]]
      .forEach(([dx, dy, s2]) => { g.beginPath(); g.arc(cx + dx * r, cy + dy * r, r * s2, 0, Math.PI * 2); g.fill(); });
    g.globalAlpha = 1;
  }
  function star(g, cx, cy, r, color) {
    g.fillStyle = color; g.beginPath();
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * Math.PI * 2, rr = i % 2 ? r * 0.38 : r;
      g[i ? "lineTo" : "moveTo"](cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
    }
    g.closePath(); g.fill();
  }
  const BUMP = ["bumper_mint", "bumper_sky", "bumper_coral"];

  function resize(c) {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const w = c.clientWidth || 600, h = c.clientHeight || 420;
    if (c.width !== w * dpr || c.height !== h * dpr) { c.width = w * dpr; c.height = h * dpr; }
    return { w, h, dpr };
  }
  const px = (v, w) => v * w, py = (v, h) => v * h;

  function shadow(g, cx, cy, w, squash) {
    g.save();
    g.globalAlpha = 0.30;
    g.fillStyle = "#1a0d2e";
    g.beginPath();
    g.ellipse(cx, cy + w * 0.30, w * 0.42, w * 0.42 * (squash || 0.34), 0, 0, Math.PI * 2);
    g.filter = "blur(4px)";
    g.fill();
    g.restore();
  }

  function sprite(g, img, cx, cy, w, rot, cast) {
    if (!img || !img.complete || !img.naturalWidth) return false;
    const h = w * (img.naturalHeight / img.naturalWidth);
    if (cast !== false) shadow(g, cx, cy, w);
    g.save(); g.translate(cx, cy); if (rot) g.rotate(rot);
    g.drawImage(img, -w / 2, -h / 2, w, h); g.restore();
    return true;
  }

  function face(g, cx, cy, r, hit) {
    const ex = r * 0.34, ey = -r * 0.06, er = r * 0.12;
    g.fillStyle = "#3a244e";
    if (hit) {                                   // squint + open mouth on contact
      g.lineWidth = er * 1.1; g.strokeStyle = "#3a244e"; g.lineCap = "round";
      [-1, 1].forEach((s) => {
        g.beginPath();
        g.arc(cx + s * ex, cy + ey + er * 0.5, er * 1.5, Math.PI * 1.15, Math.PI * 1.85);
        g.stroke();
      });
      g.fillStyle = "#3a244e";
      g.beginPath(); g.ellipse(cx, cy + r * 0.34, er * 1.1, er * 1.35, 0, 0, Math.PI * 2); g.fill();
    } else {
      [-1, 1].forEach((s) => {
        g.beginPath(); g.ellipse(cx + s * ex, cy + ey, er, er * 1.2, 0, 0, Math.PI * 2); g.fill();
        g.fillStyle = "#fff"; g.beginPath();
        g.arc(cx + s * ex - er * 0.18, cy + ey - er * 0.42, er * 0.36, 0, Math.PI * 2); g.fill();
        g.fillStyle = "#3a244e";
      });
      g.lineWidth = Math.max(2, er * 0.55); g.strokeStyle = "#3a244e"; g.lineCap = "round";
      g.beginPath(); g.arc(cx, cy + r * 0.2, er * 1.25, 0.25, Math.PI - 0.25); g.stroke();
    }
    g.fillStyle = "rgba(255,120,160,.45)";
    [-1, 1].forEach((s) => { g.beginPath(); g.ellipse(cx + s * ex * 1.85, cy + er * 1.5, er * 0.9, er * 0.55, 0, 0, Math.PI * 2); g.fill(); });
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

    if (BACKDROP.complete && BACKDROP.naturalWidth) {
      // cover-fit the rendered plate so it never letterboxes
      const ar = BACKDROP.naturalWidth / BACKDROP.naturalHeight, ca = w / h;
      let dw = w, dh = h;
      if (ca > ar) dh = w / ar; else dw = h * ar;
      g.drawImage(BACKDROP, (w - dw) / 2, (h - dh) / 2, dw, dh);
    } else {
      const bg = g.createLinearGradient(0, 0, 0, h);
      bg.addColorStop(0, C.sky[0]); bg.addColorStop(0.55, C.sky[1]); bg.addColorStop(1, C.sky[2]);
      g.fillStyle = bg; g.fillRect(0, 0, w, h);
    }
    // a few twinkles still animate on top - the plate is static
    DECO.stars.forEach((s2, i) => {
      if (i % 4) return;
      const tw = 0.4 + 0.6 * Math.abs(Math.sin(fx.t * 1.6 + s2.ph));
      g.globalAlpha = tw * 0.8;
      star(g, s2.x * w, s2.y * h, s2.r * 1.1, "#fffdf4");
    });
    g.globalAlpha = 1;

    // playfield card with a fat rounded border - the "chunky" cue
    const T = K.TABLE || { left: 0.075, right: 0.855, top: 0.055 };
    const bx = px(T.left - 0.035, w), by = py(T.top - 0.03, h);
    const bw = px(T.right - T.left + 0.07, w), bh = py(0.945, h);

    // scalloped candy frame: a ring of dots behind the board reads as "cute" far faster
    // than any amount of shading does
    const per = 26, rr = 9;
    g.fillStyle = C.rim;
    for (let i = 0; i <= per; i++) {
      const u = i / per;
      g.beginPath(); g.arc(bx + u * bw, by - 3, rr, 0, Math.PI * 2); g.fill();
      g.beginPath(); g.arc(bx + u * bw, by + bh + 3, rr, 0, Math.PI * 2); g.fill();
    }
    const perV = 17;
    for (let i = 0; i <= perV; i++) {
      const v = i / perV;
      g.beginPath(); g.arc(bx - 3, by + v * bh, rr, 0, Math.PI * 2); g.fill();
      g.beginPath(); g.arc(bx + bw + 3, by + v * bh, rr, 0, Math.PI * 2); g.fill();
    }

    g.save();
    g.shadowColor = "rgba(120,60,140,.35)"; g.shadowBlur = 26; g.shadowOffsetY = 8;
    g.beginPath(); g.roundRect(bx, by, bw, bh, 34);
    const boardG = g.createLinearGradient(0, by, 0, by + bh);
    boardG.addColorStop(0, C.board[0]); boardG.addColorStop(1, C.board[1]);
    g.fillStyle = boardG; g.fill();
    g.shadowColor = "transparent"; g.shadowBlur = 0; g.shadowOffsetY = 0;
    g.lineWidth = 10; g.strokeStyle = C.rim; g.stroke();
    g.lineWidth = 4; g.strokeStyle = C.rimDark; g.stroke();
    g.clip();

    g.strokeStyle = "rgba(255,212,77,.18)"; g.lineWidth = 6;
    for (let i = 1; i <= 4; i++) {
      g.beginPath(); g.arc(px(0.46, w), py(0.46, h), px(0.075 * i, w), 0, Math.PI * 2); g.stroke();
    }
    // confetti + stars scattered on the cloth so the board is not an empty slab
    DECO.stars.forEach((s2, i) => {
      if (i % 3) return;
      g.globalAlpha = 0.5;
      star(g, px(0.1 + s2.x * 0.72, w), py(0.1 + s2.y * 0.78, h), s2.r * 1.5, i % 2 ? "#ffd44d" : "#7de8ff");
    });
    DECO.bokeh.forEach((b, i) => {
      if (i % 2) return;
      g.globalAlpha = 0.14; g.fillStyle = "#ffd6ef";
      g.beginPath(); g.arc(px(0.12 + b.x * 0.7, w), py(0.1 + b.y * 0.8, h), b.r * w * 0.5, 0, Math.PI * 2); g.fill();
    });
    g.globalAlpha = 1;

    g.strokeStyle = "#7de8ff"; g.lineWidth = 13; g.lineCap = "round";
    (K.WALLS || []).forEach((wl) => {
      g.strokeStyle = "#1d6a86"; g.lineWidth = 15;
      g.beginPath(); g.moveTo(px(wl[0], w), py(wl[1], h)); g.lineTo(px(wl[2], w), py(wl[3], h)); g.stroke();
      g.strokeStyle = "#7de8ff"; g.lineWidth = 9;
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
      const drawn = sprite(g, IMG[BUMP[i % BUMP.length]], px(b.x, w), py(b.y, h), px(b.r * 2.9, w) * scale);
      if (drawn) face(g, px(b.x, w), py(b.y - b.r * 0.18, h), px(b.r, w) * scale, flash > 0);
      if (!drawn) {
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

    const mood = state.mode === "drain" ? "guard_oops"
               : (state.combo || 0) >= 2 ? "guard_cheer" : "guard_idle";
    sprite(g, IMG[mood], px(0.465, w), py(0.945, h), px(0.115, w));

    if (state.mode === "plunge") {
      g.fillStyle = "#ffe9a8"; g.font = "800 16px ui-rounded, ui-sans-serif, system-ui";
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
      g.globalAlpha = 1 - p.age / p.life; g.fillStyle = C.blue;
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

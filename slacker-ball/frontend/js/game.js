(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const W = LAYOUT.width, H = LAYOUT.height;

  const POOL = [
    { id: "coffee", rarity: "N", color: "#c47a3a", name: "咖啡球" },
    { id: "cat", rarity: "SR", color: "#e8d7a0", name: "带薪摸鱼猫" },
    { id: "boss", rarity: "SSR", color: "#ff6b4a", name: "甩锅球" },
  ];

  const SFX = window.SFX || { peg() {}, launch() {}, redZone() {}, flipperHit() {} };
  window.SFX = SFX;

  I18N.register({
    "zh-Hans": {
      "ui.launch": "HOLD · 摸鱼发射",
      "ui.ad": "看广告补弹药",
      "ui.pull": "抽皮 50★",
      "toast.noAmmo": "弹药空了",
      "toast.noDust": "星尘不够",
      "toast.smash": "加急需求粉碎",
    },
    en: {
      "ui.launch": "HOLD · SLACK SHOT",
      "ui.ad": "Ad for ammo",
      "ui.pull": "Skin 50★",
      "toast.noAmmo": "No ammo",
      "toast.noDust": "Not enough StarDust",
      "toast.smash": "Urgent request smashed",
    },
  });
  I18N.setLang("zh-Hans");

  Save.load();
  let smashed = 0;
  let skinIndex = 0;
  let charging = false;
  let power = 0;
  let blocks = resetBlocks();

  function resetBlocks() {
    const row = [];
    const labels = ["加急", "周报", "会议", "KPI", "对齐"];
    const w = 68;
    for (let i = 0; i < 5; i++) {
      row.push({
        id: "u" + i,
        x: 28 + i * (w + 8),
        y: 548,
        w,
        h: 36,
        hp: 2 + (i % 2),
        max: 2 + (i % 2),
        label: labels[i],
      });
    }
    return row;
  }

  function toast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(toast.t);
    toast.t = setTimeout(() => el.classList.remove("show"), 1400);
  }

  function hud() {
    document.getElementById("dust").textContent = Economy.snapshot().stardust;
    document.getElementById("ammo").textContent = Economy.snapshot().tickets;
    document.getElementById("smash").textContent = smashed;
  }

  function currentSkin() {
    const inv = Gacha.snapshot().inventory;
    const owned = inv.length ? inv : [POOL[0]];
    return owned[skinIndex % owned.length];
  }

  const btn = document.getElementById("launchBtn");
  btn.addEventListener("pointerdown", () => { charging = true; power = 0.15; });
  window.addEventListener("pointerup", () => {
    if (!charging) return;
    charging = false;
    if (!Economy.consumeTicket()) { toast(I18N.t("toast.noAmmo")); hud(); return; }
    launch(power);
    Save.persist({ smashed });
    hud();
  });

  document.getElementById("adBtn").onclick = () => {
    Commerce.rewarded("ammo");
    Save.persist({ smashed });
    toast("+5 ammo");
    hud();
  };
  document.getElementById("pullBtn").onclick = () => {
    if (!Economy.spend(Gacha.PULL_COST)) { toast(I18N.t("toast.noDust")); return; }
    const got = Gacha.pull(POOL);
    toast(got.name || got.id);
    Save.persist({ smashed });
    hud();
  };
  document.getElementById("skinBtn").onclick = () => {
    skinIndex += 1;
    toast((currentSkin().name || currentSkin().id) + "");
  };

  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.032, (now - last) / 1000);
    last = now;
    if (charging) power = Math.min(1, power + dt * 0.9);
    updatePhysics(dt);
    updateParticles(dt);
    for (const b of WORLD.balls) {
      if (b.state !== "flying") continue;
      const hit = hitBreakables(b, blocks);
      if (hit) {
        smashed += 1;
        Economy.grant(8);
        toast(I18N.t("toast.smash"));
        hud();
      }
    }
    settleBalls((_ball, pocket) => {
      if (pocket) Economy.grant(pocket.reward || 1);
      hud();
      Save.persist({ smashed });
    });
    if (blocks.every(b => b.hp <= 0)) blocks = resetBlocks();
    draw();
    requestAnimationFrame(frame);
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = "#14110d";
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = "#2a241c";
    ctx.fillRect(LAYOUT.leftWall, 54, LAYOUT.rightWall - LAYOUT.leftWall, LAYOUT.pocketTop - 54);
    WORLD.pegs.forEach(n => {
      ctx.beginPath();
      ctx.arc(n.x, n.y, n.r, 0, Math.PI * 2);
      ctx.fillStyle = n.type === "bumper" ? "#d4a017" : n.type === "switch" ? "#c45c32" : "#6b5d48";
      ctx.fill();
    });
    blocks.forEach(b => {
      if (b.hp <= 0) return;
      ctx.fillStyle = `rgba(196,92,50,${0.35 + 0.25 * (b.hp / b.max)})`;
      ctx.fillRect(b.x, b.y, b.w, b.h);
      ctx.fillStyle = "#f4ead8";
      ctx.font = "11px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(b.label, b.x + b.w / 2, b.y + 22);
    });
    const skin = currentSkin();
    WORLD.balls.forEach(b => {
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fillStyle = skin.color || "#e8d7a0";
      ctx.fill();
    });
    if (charging) {
      ctx.fillStyle = "#d4a017";
      ctx.fillRect(18, H - 70, (W - 36) * power, 6);
    }
  }

  hud();
  requestAnimationFrame(frame);
})();

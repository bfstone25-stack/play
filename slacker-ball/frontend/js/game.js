(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const W = LAYOUT.width, H = LAYOUT.height;

  // Skin names live in the string table (skin.<id>) so a skin pulled in one language
  // reads right after the player flips the toggle.
  const POOL = [
    { id: "coffee", rarity: "N", color: "#c47a3a" },
    { id: "cat", rarity: "SR", color: "#e8d7a0" },
    { id: "boss", rarity: "SSR", color: "#ff6b4a" },
  ];

  const SFX = window.SFX || { peg() {}, launch() {}, redZone() {}, flipperHit() {} };
  window.SFX = SFX;

  const LANG_KEY = "sb_lang";
  const PACK = { en: "en", zh: "zh-Hans" };

  I18N.register({
    en: {
      "title": "Slacker Ball",
      "hud.dust": "STAR DUST",
      "hud.ammo": "AMMO",
      "hud.smash": "SMASHED",
      "ui.launch": "HOLD · SLACK SHOT",
      "ui.ad": "Watch ad · +5 ammo",
      "ui.pull": "Skin pull 50★",
      "ui.skin": "Swap skin",
      "toast.noAmmo": "Out of ammo",
      "toast.noDust": "Not enough StarDust",
      "toast.smash": "Urgent request smashed!",
      "toast.ammo": "+5 ammo",
      "toast.skin": "Skin: {name}",
      "toast.got": "Pulled: {name}",
      "block.0": "URGENT",
      "block.1": "REPORT",
      "block.2": "MEETING",
      "block.3": "KPI",
      "block.4": "SYNC",
      "skin.coffee": "Coffee Ball",
      "skin.cat": "Paid-to-Slack Cat",
      "skin.boss": "Blame-Shift Ball",
    },
    "zh-Hans": {
      "title": "摸鱼大暴弹 · Slacker Ball",
      "hud.dust": "星尘",
      "hud.ammo": "弹药",
      "hud.smash": "粉碎",
      "ui.launch": "HOLD · 摸鱼发射",
      "ui.ad": "看广告补弹药",
      "ui.pull": "抽皮 50★",
      "ui.skin": "换皮",
      "toast.noAmmo": "弹药空了",
      "toast.noDust": "星尘不够",
      "toast.smash": "加急需求粉碎",
      "toast.ammo": "+5 弹药",
      "toast.skin": "皮肤：{name}",
      "toast.got": "抽到：{name}",
      "block.0": "加急",
      "block.1": "周报",
      "block.2": "会议",
      "block.3": "KPI",
      "block.4": "对齐",
      "skin.coffee": "咖啡球",
      "skin.cat": "带薪摸鱼猫",
      "skin.boss": "甩锅球",
    },
  });

  function applyLang(code) {
    I18N.setLang(PACK[code] || PACK.en);
    document.documentElement.lang = code === "zh" ? "zh-Hans" : "en";
    document.title = I18N.t("title");
    document.querySelectorAll("[data-i18n]").forEach(el => { el.textContent = I18N.t(el.getAttribute("data-i18n")); });
    document.querySelectorAll("[data-lang]").forEach(b => b.classList.toggle("on", b.getAttribute("data-lang") === code));
    if (window.TEL && TEL.ev) TEL.ev("language", { lang: code });
  }
  document.querySelectorAll("[data-lang]").forEach(b => {
    b.addEventListener("click", () => {
      const code = b.getAttribute("data-lang");
      I18N.remember(LANG_KEY, code);
      applyLang(code);
    });
  });
  applyLang(I18N.detect(LANG_KEY));

  Save.load();
  let smashed = 0;
  let skinIndex = 0;
  let charging = false;
  let power = 0;
  let blocks = resetBlocks();

  function resetBlocks() {
    const row = [];
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
        label: "block." + i,   // resolved through I18N at draw time
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
  function skinName(skin) {
    const key = "skin." + skin.id;
    const s = I18N.t(key);
    return s === key ? (skin.name || skin.id) : s;
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
    toast(I18N.t("toast.ammo"));
    hud();
  };
  document.getElementById("pullBtn").onclick = () => {
    if (!Economy.spend(Gacha.PULL_COST)) { toast(I18N.t("toast.noDust")); return; }
    const got = Gacha.pull(POOL);
    toast(I18N.t("toast.got", { name: skinName(got) }));
    Save.persist({ smashed });
    hud();
  };
  document.getElementById("skinBtn").onclick = () => {
    skinIndex += 1;
    toast(I18N.t("toast.skin", { name: skinName(currentSkin()) }));
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
    if (blocks.every(b => b.hp <= 0)) {
      // Clearing the wall is the only end this endless game has, so it is where the
      // catalogue board is offered — once per session, and offered, never forced: the
      // board is dismissable and the next wall is already racking up behind it.
      if (!window.__boardOffered) {
        window.__boardOffered = 1;
        setTimeout(() => {
          if (window.BOARD && BOARD.adultAllowed()) BOARD.offerMore("adult");
          else if (window.PROMO) PROMO.showAfterRun("wall-clear");
        }, 900);
      }
      blocks = resetBlocks();
    }
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
      ctx.font = "700 11px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(I18N.t(b.label), b.x + b.w / 2, b.y + 22, b.w - 6);
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

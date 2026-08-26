(() => {
  const CATALOG = [
    { id: "ok", text: "好的好的", power: 5, rarity: "N" },
    { id: "lie", text: "我很好", power: 12, rarity: "N" },
    { id: "teach", text: "你在教我做事", power: 25, rarity: "R" },
    { id: "quit", text: "我不干了", power: 40, rarity: "SR" },
    { id: "legend", text: "你们不要再劝我努力了", power: 80, rarity: "SSR" },
  ];
  const ORDER = ["ok", "lie", "teach", "quit", "legend"];
  const KEY = "crazy-rant.cabinet.v3";

  const RELICS_POOL = [
    {
      id: "tableFlip", icon: "💥",
      name: { en: "Table Flip+", zh: "超级掀桌", ja: "超・ちゃぶ台返し" },
      desc: { en: "Bomb damage +160, larger blast radius.", zh: "下班掀桌大招伤害+160，全屏爆炸更猛烈。", ja: "退勤ボム威力+160、爆風範囲拡大。" }
    },
    {
      id: "slacking", icon: "🛡️",
      name: { en: "Slacking Shield", zh: "摸鱼护体", ja: "サボり結界" },
      desc: { en: "Gain 1 free hit shield every 20 seconds.", zh: "每20秒自动获得1次抵挡伤害的免伤护盾。", ja: "20秒ごとに被弾を1回無効化する結界を展開。" }
    },
    {
      id: "ignoreRead", icon: "👁️",
      name: { en: "Unread Grazing", zh: "已读不回", ja: "既読スルー" },
      desc: { en: "Graze radius +55%, charge bombs much faster.", zh: "擦弹判定半径+55%，大招充能极大加快。", ja: "擦弾判定+55%、ボムゲージ回収が超加速。" }
    },
    {
      id: "rageTyping", icon: "⚡",
      name: { en: "Rage Typing", zh: "键盘狂暴", ja: "爆速タイピング" },
      desc: { en: "Ofuda bullet damage +40%.", zh: "反击御札子弹伤害+40%。", ja: "反撃御札の攻撃力+40%。" }
    },
    {
      id: "coffee", icon: "☕",
      name: { en: "Iced Americano", zh: "冰美式续命", ja: "命のアイスコーヒー" },
      desc: { en: "Movement speed +26%, dodging made smoother.", zh: "移速+26%，走位闪避更加丝滑。", ja: "移動速度+26%、回避性能が向上。" }
    },
    {
      id: "thickSkin", icon: "🧱",
      name: { en: "Thick Skin", zh: "钝感力", ja: "鈍感力" },
      desc: { en: "Reduce all damage taken by 20%.", zh: "受到的所有职场伤害降低20%。", ja: "受けるダメージを20%軽減。" }
    }
  ];

  const OMAMORI_FORTUNES = {
    zh: [
      { title: "【大吉 · 准点下班】", verse: "群聊静音，下班神隐。今日万事皆休，绝不加班。" },
      { title: "【中吉 · 会议秒散】", verse: "言之无物，一语道破。十分钟速通全员会。" },
      { title: "【上上吉 · 锅不沾身】", verse: "金刚不坏，神道庇佑。一切甩锅皆反弹。" },
      { title: "【吉 · 咖啡续命】", verse: "灵台清明，指若奔雷。八小时工作两小时完。" }
    ],
    ja: [
      { title: "【大吉 · 定時退社】", verse: "通知オフ、即神隠し。本日残業の気配一切なし。" },
      { title: "【中吉 · 会議速決】", verse: "無駄口なし、一言解決。朝会10分で完全散会。" },
      { title: "【大業 · 責任回避】", verse: "神道加護、全弾反射。全ての無理難題を退散。" },
      { title: "【吉 · 心身健全】", verse: "気力充実、筆走る。職場平和の御利益あり。" }
    ],
    en: [
      { title: "【GREAT FORTUNE · 5PM ESCAPE】", verse: "Notifications muted. In office only in spirit. Zero overtime today." },
      { title: "【FORTUNE · MEETING ADJOURNED】", verse: "Points made, sync closed. Standup finished in 3 minutes flat." },
      { title: "【BLESSING · BLAME DEFLECTOR】", verse: "Shinto shielded. All workplace knives ricochet back." },
      { title: "【GOOD LUCK · CAFFEINE BLISS】", verse: "Sharp focus, swift keys. Work done with hours to spare." }
    ]
  };

  const COPY = {
    en: {
      tag: "CABINET 06 · OFFICE HELL",
      lore: "Workplace knives, written as ofuda.",
      hint: "Office-politics shmup. Read the charms. Graze the meeting.",
      start: "PRESS START",
      load: "PICK THREE",
      fight: "CLOCK IN",
      hold: "TAP",
      launchStart: "START",
      launchFight: "FIGHT",
      launchAgain: "AGAIN",
      hp: "HP", rage: "GRAZE", combo: "COMBO", phase: "MEETING",
      bomb: "BOMB (SPACE)", bombBtn: "FLIP TABLE", relics: "PERKS",
      best: "BEST", max: "MAX HIT", slots: "SLOTS",
      wait: "WAITING", live: "IN MEETING", down: "ADJOURNED", dead: "PIP'd",
      win: "PIP SURVIVED", lose: "SMILED TO DEATH",
      retry: "RETRY", next: "OVERTIME", share: "SAVE FORTUNE",
      relicTag: "MEETING ADJOURNED", relicTitle: "PICK A PERK", relicHint: "Choose your workplace survival buff:",
      omamoriBadge: "DAILY WORKPLACE OMAMORI",
      omamoriStamp: "【OFFERED】",
      dodge: "Drag / WASD. Space to Bomb. Graze to charge.",
      unlock: "UNLOCKED ",
      phases: ["STANDUP", "1:1", "ALL-HANDS", "PIP", "OVERTIME"],
      cards: { ok: "OK", lie: "LIE", teach: "TEACH", quit: "QUIT", legend: "LEGEND" },
    },
    zh: {
      tag: "六号机柜 · 职场弹幕",
      lore: "职场刀子写成神道灵符。竖着写，才能躲。",
      hint: "职场 STG。读御札，擦弹，把会开完。",
      start: "按开始",
      load: "选三张",
      fight: "上班",
      hold: "点",
      launchStart: "开始",
      launchFight: "开战",
      launchAgain: "再来",
      hp: "生命", rage: "擦弹", combo: "连击", phase: "会议",
      bomb: "大招 (空格)", bombBtn: "掀桌下班", relics: "被动词条",
      best: "最快", max: "最高连", slots: "槽位",
      wait: "待命", live: "开会中", down: "散会", dead: "优化",
      win: "PIP 活下来了", lose: "被微笑淹死",
      retry: "再战", next: "加班", share: "保存御守卡",
      relicTag: "散会修整", relicTitle: "选择职场词条", relicHint: "选择一项打工防身被动增益：",
      omamoriBadge: "今日打工人除厄御守",
      omamoriStamp: "【奉纳】",
      dodge: "拖拽/WASD走位，空格放掀桌大招，擦弹充能。",
      unlock: "解锁 ",
      phases: ["站会", "1对1", "全员会", "PIP", "加班"],
      cards: { ok: "好好", lie: "很好", teach: "教我", quit: "不干", legend: "别劝" },
    },
    ja: {
      tag: "六号機 · 社内御札",
      lore: "社内の刃は、御札になる。",
      hint: "職場STG。札を読んで、擦って、会議を終える。",
      start: "はじめる",
      load: "三枚選べ",
      fight: "出勤",
      hold: "タップ",
      launchStart: "開始",
      launchFight: "開戦",
      launchAgain: "もう一回",
      hp: "HP", rage: "擦弾", combo: "コンボ", phase: "会議",
      bomb: "退勤ボム (SPACE)", bombBtn: "ちゃぶ台返し", relics: "加護",
      best: "最速", max: "最大", slots: "札",
      wait: "待機", live: "会議中", down: "散会", dead: "PIP",
      win: "PIPを生き抜いた", lose: "笑顔に沈んだ",
      retry: "再戦", next: "残業", share: "御守保存",
      relicTag: "散会！", relicTitle: "加護選択", relicHint: "職場で生き残るための加護を1つ選択：",
      omamoriBadge: "本日社内除厄御守",
      omamoriStamp: "【奉納】",
      dodge: "ドラッグ / WASD。スペースでちゃぶ台返し。擦弾で充填。",
      unlock: "解禁 ",
      phases: ["朝会", "1on1", "全社会", "PIP", "残業"],
      cards: { ok: "了解", lie: "元気", teach: "指導", quit: "辞める", legend: "頑張るな" },
    },
  };

  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  let lang = "en";
  let screen = "title";
  let slots = [];
  let dragging = false;
  const save = { unlocked: ["ok", "lie", "teach"], bestTime: 0, maxCombo: 0, wins: 0 };
  try { Object.assign(save, JSON.parse(localStorage.getItem(KEY) || localStorage.getItem("crazy-rant.cabinet.v2") || "{}")); } catch (_) {}
  if (!save.unlocked || !save.unlocked.length) save.unlocked = ["ok", "lie", "teach"];
  const state = COMBAT.create();

  function t() { return COPY[lang] || COPY.en; }
  function persist() {
    try { localStorage.setItem(KEY, JSON.stringify(save)); } catch (_) {}
  }
  function banner(msg) {
    const el = document.getElementById("banner");
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(banner.t);
    banner.t = setTimeout(() => el.classList.remove("show"), 1400);
  }
  function fmtTime(s) {
    if (!s) return "—";
    const m = Math.floor(s / 60);
    const r = (s % 60).toFixed(1);
    return m ? m + ":" + String(r).padStart(4, "0") : r + "s";
  }

  function applyLang() {
    const c = t();
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : lang === "ja" ? "ja" : "en";
    document.getElementById("tagline").textContent = c.tag;
    document.getElementById("lore").textContent = c.lore;
    document.getElementById("titleTag").textContent = c.tag;
    document.getElementById("titleHint").textContent = c.hint;
    document.getElementById("startBtn").textContent = c.start;
    document.getElementById("loadTag").textContent = c.load;
    document.getElementById("loadHint").textContent = c.dodge;
    document.getElementById("fightBtn").textContent = c.fight;
    document.getElementById("lHp").textContent = c.hp;
    document.getElementById("lRage").textContent = c.rage;
    document.getElementById("lCombo").textContent = c.combo;
    document.getElementById("lPhase").textContent = c.phase;
    document.getElementById("lBomb").textContent = c.bomb;
    document.getElementById("bombBtn").textContent = c.bombBtn;
    document.getElementById("lRelics").textContent = c.relics;
    document.getElementById("lBest").textContent = c.best;
    document.getElementById("lMax").textContent = c.max;
    document.getElementById("lSlots").textContent = c.slots;
    document.getElementById("relicTag").textContent = c.relicTag;
    document.getElementById("relicTitle").textContent = c.relicTitle;
    document.getElementById("relicHint").textContent = c.relicHint;
    document.getElementById("shareBtn").textContent = c.share;
    document.getElementById("omamoriBadge").textContent = c.omamoriBadge;
    document.querySelectorAll(".lang-btn").forEach((b) => b.classList.toggle("active", b.dataset.lang === lang));
    renderBank();
    hud();
  }

  function renderBank() {
    const c = t();
    const bank = document.getElementById("bank");
    bank.innerHTML = "";
    CATALOG.forEach(p => {
      const locked = !save.unlocked.includes(p.id);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "card" + (slots.includes(p.id) ? " on" : "") + (locked ? " lock" : "");
      const sig = document.createElement("i");
      sig.className = "sig";
      btn.appendChild(sig);
      GLYPHS.paintSig(sig, p.id);
      const name = document.createElement("b");
      name.textContent = locked ? "••••" : c.cards[p.id];
      btn.appendChild(name);
      btn.onclick = () => {
        if (locked) return;
        SFX.unlock();
        const i = slots.indexOf(p.id);
        if (i >= 0) slots.splice(i, 1);
        else {
          if (slots.length >= 3) slots.shift();
          slots.push(p.id);
        }
        renderBank();
        hud();
      };
      bank.appendChild(btn);
    });
  }

  function paintChips(row, ids) {
    row.innerHTML = "";
    for (let i = 0; i < 3; i++) {
      const chip = document.createElement("div");
      chip.className = "chip";
      const id = ids[i];
      if (id) {
        chip.style.background = (GLYPHS.META[id] || GLYPHS.META.ok).color;
        const c = document.createElement("canvas");
        c.width = 40; c.height = 56;
        c.style.width = "100%"; c.style.height = "100%";
        const g = c.getContext("2d");
        GLYPHS.drawShot(g, { x: 20, y: 28, kind: id, font: 10, rot: 0 }, lang);
        chip.appendChild(c);
      }
      row.appendChild(chip);
    }
  }

  function renderRelicPills() {
    const container = document.getElementById("relicPills");
    if (!container) return;
    container.innerHTML = "";
    state.relics.forEach(rid => {
      const r = RELICS_POOL.find(x => x.id === rid);
      if (!r) return;
      const pill = document.createElement("span");
      pill.className = "relic-pill";
      pill.textContent = r.icon + " " + (r.name[lang] || r.name.en);
      container.appendChild(pill);
    });
  }

  function hud() {
    const c = t();
    document.getElementById("hp").textContent = Math.max(0, Math.ceil(state.player.hp));
    document.getElementById("hpFill").style.width = (state.player.hp / state.player.maxHp * 100) + "%";
    const rage = state.graze;
    document.getElementById("rage").textContent = Math.floor(rage);
    document.getElementById("rageFill").style.width = Math.min(100, (rage % 36) / 36 * 100) + "%";
    document.getElementById("combo").textContent = "×" + Math.floor(state.combo);
    const meetI = state.boss.endless ? 4 : Math.min(4, state.boss.meeting || 0);
    document.getElementById("phase").textContent = c.phases[meetI] || c.phases[0];
    document.getElementById("bossHp").textContent = Math.max(0, Math.ceil(state.boss.hp));
    document.getElementById("bossFill").style.width = (state.boss.hp / state.boss.maxHp * 100) + "%";
    document.getElementById("best").textContent = fmtTime(save.bestTime);
    document.getElementById("maxCombo").textContent = save.maxCombo;
    
    const bombValEl = document.getElementById("bombVal");
    const bombBtn = document.getElementById("bombBtn");
    const canBomb = state.bombs > 0 || state.bombCharge >= 36;
    if (bombValEl) bombValEl.textContent = "⚡ " + state.bombs + (state.bombCharge > 0 ? ` (${state.bombCharge}/36)` : "");
    if (bombBtn) {
      bombBtn.classList.toggle("ready", canBomb);
    }

    document.getElementById("runState").textContent = screen === "fight"
      ? (state.outcome === "win" ? c.down : state.outcome === "lose" ? c.dead : c.live)
      : c.wait;
    const steps = document.querySelectorAll("#chainTrack i");
    steps.forEach((el, i) => el.classList.toggle("on", state.combo > i * 2));
    paintChips(document.getElementById("slotRow"), slots);
    paintChips(document.getElementById("held"), slots);
    renderRelicPills();

    const deck = document.getElementById("deckBtn");
    document.getElementById("lHold").textContent = c.hold;
    if (screen === "title") document.getElementById("lLaunch").textContent = c.launchStart;
    else if (screen === "loadout") document.getElementById("lLaunch").textContent = c.launchFight;
    else document.getElementById("lLaunch").textContent = c.launchAgain;
    deck.disabled = false;
  }

  function show(id, on) {
    document.getElementById(id).hidden = !on;
  }

  function openTitle() {
    screen = "title";
    show("titleOv", true);
    show("loadOv", false);
    show("relicOv", false);
    show("endOv", false);
    SFX.pulse(false);
    hud();
  }

  function openLoadout() {
    screen = "loadout";
    if (!slots.length) slots = save.unlocked.slice(0, 3);
    show("titleOv", false);
    show("loadOv", true);
    show("relicOv", false);
    show("endOv", false);
    renderBank();
    hud();
  }

  function startFight() {
    if (!slots.length) slots = save.unlocked.slice(0, 3);
    if (!slots.length) { banner(t().load); return; }
    const load = parseLoadout(slots, CATALOG);
    const combo = combinePhrases(load.map(p => p.text));
    COMBAT.reset(state, {
      loadout: load.map(p => p.id),
      pattern: rantPattern(slots, CATALOG),
      shotPower: rantShotPower(combo, CATALOG),
      reduced,
      lang,
      endless: !!startFight.endless,
    });
    startFight.endless = false;
    screen = "fight";
    show("titleOv", false);
    show("loadOv", false);
    show("relicOv", false);
    show("endOv", false);
    SFX.unlock();
    SFX.pulse(true);
    hud();
  }

  function openRelicChoice() {
    screen = "relic";
    show("relicOv", true);
    const available = RELICS_POOL.filter(r => !state.relics.includes(r.id));
    const choices = [];
    const pool = available.slice();
    for (let i = 0; i < 3 && pool.length > 0; i++) {
      const idx = Math.floor(Math.random() * pool.length);
      choices.push(pool.splice(idx, 1)[0]);
    }
    const grid = document.getElementById("relicGrid");
    grid.innerHTML = "";
    choices.forEach(r => {
      const card = document.createElement("div");
      card.className = "relic-card";
      const icon = document.createElement("span");
      icon.className = "relic-icon";
      icon.textContent = r.icon;
      const info = document.createElement("div");
      info.className = "relic-info";
      const name = document.createElement("b");
      name.textContent = r.name[lang] || r.name.en;
      const desc = document.createElement("small");
      desc.textContent = r.desc[lang] || r.desc.en;
      info.appendChild(name);
      info.appendChild(desc);
      card.appendChild(icon);
      card.appendChild(info);
      card.onclick = () => {
        state.relics.push(r.id);
        if (r.id === "slacking") state.shields = 1;
        if (SFX.relic) SFX.relic();
        banner("+ " + (r.name[lang] || r.name.en));
        show("relicOv", false);
        screen = "fight";
        hud();
      };
      grid.appendChild(card);
    });
    hud();
  }

  window.onMeetingCleared = function(st, nextMeeting) {
    if (nextMeeting < 4) {
      setTimeout(() => openRelicChoice(), 300);
    }
  };

  function generateOmamoriCard() {
    const list = OMAMORI_FORTUNES[lang] || OMAMORI_FORTUNES.en;
    const item = list[Math.floor(Math.random() * list.length)];
    const today = new Date().toISOString().slice(0, 10);
    document.getElementById("omamoriTitle").textContent = item.title;
    document.getElementById("omamoriVerse").textContent = item.verse;
    document.getElementById("omamoriStats").textContent = 
      `${today} · 会议存活: ${fmtTime(state.time)} · 擦弹: ${state.graze} · 连击: ×${Math.floor(state.combo)}`;
  }

  function finish(kind) {
    const c = t();
    show("endOv", true);
    show("relicOv", false);
    document.getElementById("endTag").textContent = kind === "win" ? "KO" : "KO";
    document.getElementById("endTitle").textContent = kind === "win" ? c.win : c.lose;
    generateOmamoriCard();
    if (kind === "win") {
      save.wins += 1;
      if (!save.bestTime || state.time < save.bestTime) save.bestTime = state.time;
      if (state.combo > save.maxCombo) save.maxCombo = Math.floor(state.combo);
      const next = ORDER.find(id => !save.unlocked.includes(id));
      if (next) {
        save.unlocked.push(next);
        banner(c.unlock + c.cards[next]);
      }
      persist();
      document.getElementById("endDetail").textContent = fmtTime(state.time) + " · ×" + Math.floor(state.combo) + " · graze " + state.graze;
      document.getElementById("againBtn").textContent = c.next;
    } else {
      if (state.combo > save.maxCombo) { save.maxCombo = Math.floor(state.combo); persist(); }
      document.getElementById("endDetail").textContent = "×" + Math.floor(state.combo);
      document.getElementById("againBtn").textContent = c.retry;
    }
    SFX.pulse(false);
    hud();
  }

  function downloadOmamoriCard() {
    const card = document.getElementById("omamoriCard");
    const off = document.createElement("canvas");
    off.width = 480;
    off.height = 320;
    const g = off.getContext("2d");
    
    // Background washi paper
    g.fillStyle = "#fcf8ed";
    g.fillRect(0, 0, 480, 320);
    
    // Vermillion border
    g.strokeStyle = "#c2412d";
    g.lineWidth = 6;
    g.strokeRect(8, 8, 464, 304);
    g.lineWidth = 1.5;
    g.strokeRect(14, 14, 452, 292);

    // Title & Verse
    g.fillStyle = "#991b1b";
    g.font = "bold 16px sans-serif";
    g.textAlign = "center";
    g.fillText(document.getElementById("omamoriBadge").textContent, 240, 48);

    g.fillStyle = "#c2412d";
    g.font = "bold 26px \"Noto Serif JP\",\"Songti SC\",serif";
    g.fillText(document.getElementById("omamoriTitle").textContent, 240, 100);

    g.fillStyle = "#451a03";
    g.font = "italic 16px \"Noto Serif JP\",\"Songti SC\",serif";
    g.fillText(document.getElementById("omamoriVerse").textContent, 240, 150);

    // Stats
    g.fillStyle = "#78350f";
    g.font = "14px monospace";
    g.fillText(document.getElementById("omamoriStats").textContent, 240, 200);

    g.fillStyle = "#111";
    g.font = "bold 13px sans-serif";
    g.fillText("play.blazecore.dev/crazy-rant · 职场发疯神道STG", 240, 250);

    // Stamp
    g.save();
    g.translate(410, 260);
    g.rotate(-0.15);
    g.strokeStyle = "rgba(185,28,28,0.7)";
    g.lineWidth = 3;
    g.strokeRect(-30, -18, 60, 36);
    g.fillStyle = "rgba(185,28,28,0.8)";
    g.font = "bold 18px serif";
    g.fillText("奉納", 0, 6);
    g.restore();

    const link = document.createElement("a");
    link.download = `crazy-rant-omamori-${Date.now()}.png`;
    link.href = off.toDataURL("image/png");
    link.click();
    banner("OMAMORI SAVED!");
  }

  function resize() {
    const rect = canvas.parentElement.getBoundingClientRect();
    const dpr = Math.min(devicePixelRatio || 1, 2);
    canvas.width = Math.max(2, Math.floor(rect.width * dpr));
    canvas.height = Math.max(2, Math.floor(rect.height * dpr));
    canvas.style.width = rect.width + "px";
    canvas.style.height = rect.height + "px";
  }

  function worldFromEvent(e) {
    const r = canvas.getBoundingClientRect();
    return {
      x: (e.clientX - r.left) / r.width * COMBAT.W,
      y: (e.clientY - r.top) / r.height * COMBAT.H,
    };
  }

  function drawArena() {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const W = COMBAT.W, H = COMBAT.H;
    const sx = canvas.width / dpr / W, sy = canvas.height / dpr / H;
    const ox = reduced ? 0 : (Math.random() - 0.5) * state.shake;
    const oy = reduced ? 0 : (Math.random() - 0.5) * state.shake;
    ctx.setTransform(dpr * sx, 0, 0, dpr * sy, ox * dpr * sx, oy * dpr * sy);
    const g = ctx.createLinearGradient(0, 0, 0, H);
    g.addColorStop(0, "#2c1410");
    g.addColorStop(0.45, "#0c0a08");
    g.addColorStop(1, "#140c0a");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = "rgba(194,65,45,.10)";
    ctx.fillRect(0, 0, W, H);
    if (!reduced) GLYPHS.drawSpeedLines(ctx, W, H, state.time);

    const chroma = state.chroma;
    function body(shift) {
      ctx.save();
      if (shift) ctx.translate(shift, 0);
      BOSS.draw(ctx, state.boss, state.time, reduced);
      GLYPHS.drawPlayer(ctx, state.player.x, state.player.y, state.time, state.player.iFrames > 0, Math.abs(state.player.vx) > 4);
      ctx.restore();
    }
    if (chroma && !reduced) {
      ctx.globalCompositeOperation = "screen";
      ctx.globalAlpha = 0.35;
      ctx.fillStyle = "#e11d48";
      body(-3);
      ctx.fillStyle = "#22d3ee";
      body(3);
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
    }
    body(0);

    state.shots.live.forEach(s => GLYPHS.drawShot(ctx, s, lang));
    state.hazards.live.forEach(h => {
      if (h.text) GLYPHS.drawWord(ctx, h);
      else if (h.type === "smile") GLYPHS.drawSmile(ctx, h.x, h.y, h.r, true);
      else if (h.type === "poster") GLYPHS.drawPoster(ctx, h.x, h.y, 22, 28, h.rot, true);
      else if (h.type === "shard") GLYPHS.drawShard(ctx, h.x, h.y, h.r, h.color || "#22d3ee");
      else GLYPHS.drawSun(ctx, h.x, h.y, h.r, state.time);
    });

    if (state.bombTimer > 0) {
      GLYPHS.drawBombEffect(ctx, W, H, state.bombTimer);
    }

    // true hitbox
    ctx.save();
    ctx.globalAlpha = 0.9;
    ctx.fillStyle = "#22d3ee";
    ctx.fillRect(state.player.x - 2, state.player.y - 2, 4, 4);
    if (state.shields > 0) {
      ctx.strokeStyle = "#22d3ee";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(state.player.x, state.player.y, 16, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.restore();
    state.fx.live.forEach(f => GLYPHS.drawBurst(ctx, f.x, f.y, f.life, f.color, f.text));
  }

  canvas.addEventListener("pointerdown", (e) => {
    if (screen !== "fight" || state.outcome) return;
    dragging = true;
    canvas.setPointerCapture(e.pointerId);
    const p = worldFromEvent(e);
    COMBAT.aim(state, p.x, p.y);
  });
  canvas.addEventListener("pointermove", (e) => {
    if (!dragging || screen !== "fight") return;
    const p = worldFromEvent(e);
    COMBAT.aim(state, p.x, p.y);
  });
  canvas.addEventListener("pointerup", () => { dragging = false; });
  canvas.addEventListener("pointercancel", () => { dragging = false; });

  addEventListener("keydown", (e) => {
    if (e.code === "ArrowLeft" || e.code === "KeyA") state.keys.l = true;
    if (e.code === "ArrowRight" || e.code === "KeyD") state.keys.r = true;
    if (e.code === "ArrowUp" || e.code === "KeyW") state.keys.u = true;
    if (e.code === "ArrowDown" || e.code === "KeyS") state.keys.d = true;
    if (e.code === "Space") {
      if (screen === "fight") COMBAT.triggerBomb(state);
    }
  });
  addEventListener("keyup", (e) => {
    if (e.code === "ArrowLeft" || e.code === "KeyA") state.keys.l = false;
    if (e.code === "ArrowRight" || e.code === "KeyD") state.keys.r = false;
    if (e.code === "ArrowUp" || e.code === "KeyW") state.keys.u = false;
    if (e.code === "ArrowDown" || e.code === "KeyS") state.keys.d = false;
  });

  document.getElementById("startBtn").onclick = () => { SFX.unlock(); openLoadout(); };
  document.getElementById("fightBtn").onclick = startFight;
  document.getElementById("againBtn").onclick = () => {
    SFX.unlock();
    if (state.outcome === "win") {
      startFight.endless = true;
      startFight();
    } else startFight();
  };
  document.getElementById("shareBtn").onclick = downloadOmamoriCard;
  document.getElementById("bombBtn").onclick = () => {
    if (screen === "fight") COMBAT.triggerBomb(state);
  };
  document.getElementById("deckBtn").onclick = () => {
    SFX.unlock();
    if (screen === "title") openLoadout();
    else if (screen === "loadout") startFight();
    else if (screen === "fight") COMBAT.triggerBomb(state);
    else if (state.outcome) document.getElementById("againBtn").click();
    else openLoadout();
  };
  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.onclick = () => { lang = btn.dataset.lang; applyLang(); };
  });

  applyLang();
  resize();
  addEventListener("resize", resize);

  let last = performance.now();
  let ended = false;
  function frame(now) {
    const dt = Math.min(0.033, (now - last) / 1000);
    last = now;
    if (screen === "fight") {
      COMBAT.update(state, dt);
      if (state.outcome && !ended) {
        ended = true;
        finish(state.outcome);
      }
      if (!state.outcome) ended = false;
    } else {
      state.time += dt;
      state.boss.x = COMBAT.W * 0.5 + Math.sin(state.time * 1.1) * 8;
    }
    drawArena();
    hud();
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();

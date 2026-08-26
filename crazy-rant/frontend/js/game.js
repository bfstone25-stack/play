(() => {
  const CATALOG = [
    { id: "ok", text: "好的好的", power: 5, rarity: "N" },
    { id: "lie", text: "我很好", power: 12, rarity: "N" },
    { id: "teach", text: "你在教我做事", power: 25, rarity: "R" },
    { id: "quit", text: "我不干了", power: 40, rarity: "SR" },
    { id: "legend", text: "你们不要再劝我努力了", power: 80, rarity: "SSR" },
  ];
  const ORDER = ["ok", "lie", "teach", "quit", "legend"];
  const KEY = "crazy-rant.cabinet.v2";
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
      best: "BEST", max: "MAX HIT", slots: "SLOTS",
      wait: "WAITING", live: "IN MEETING", down: "ADJOURNED", dead: "PIP'd",
      win: "PIP SURVIVED", lose: "SMILED TO DEATH",
      retry: "RETRY", next: "OVERTIME",
      dodge: "Drag / WASD to dodge. Auto-fire. Graze the text.",
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
      best: "最快", max: "最高连", slots: "槽位",
      wait: "待命", live: "开会中", down: "散会", dead: "优化",
      win: "PIP 活下来了", lose: "被微笑淹死",
      retry: "再战", next: "加班",
      dodge: "拖拽或 WASD 走位，自动射击。擦过文字加分。",
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
      best: "最速", max: "最大", slots: "札",
      wait: "待機", live: "会議中", down: "散会", dead: "PIP",
      win: "PIPを生き抜いた", lose: "笑顔に沈んだ",
      retry: "再戦", next: "残業",
      dodge: "ドラッグ / WASD。自動射撃。札を擦れ。",
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
  try { Object.assign(save, JSON.parse(localStorage.getItem(KEY) || localStorage.getItem("crazy-rant.cabinet.v1") || "{}")); } catch (_) {}
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
    document.getElementById("lBest").textContent = c.best;
    document.getElementById("lMax").textContent = c.max;
    document.getElementById("lSlots").textContent = c.slots;
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
        c.width = 64; c.height = 48;
        c.style.width = "100%"; c.style.height = "100%";
        const g = c.getContext("2d");
        GLYPHS.drawShot(g, { x: 32, y: 24, kind: id, font: 10, rot: 0 }, lang);
        chip.appendChild(c);
      }
      row.appendChild(chip);
    }
  }

  function hud() {
    const c = t();
    const fighting = screen === "fight" && !state.outcome;
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
    document.getElementById("runState").textContent = screen === "fight"
      ? (state.outcome === "win" ? c.down : state.outcome === "lose" ? c.dead : c.live)
      : c.wait;
    const steps = document.querySelectorAll("#chainTrack i");
    steps.forEach((el, i) => el.classList.toggle("on", state.combo > i * 2));
    paintChips(document.getElementById("slotRow"), slots);
    paintChips(document.getElementById("held"), slots);
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
    show("endOv", false);
    SFX.pulse(false);
    hud();
  }

  function openLoadout() {
    screen = "loadout";
    if (!slots.length) slots = save.unlocked.slice(0, 3);
    show("titleOv", false);
    show("loadOv", true);
    show("endOv", false);
    renderBank();
    hud();
  }

  function startFight() {
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
    show("endOv", false);
    SFX.unlock();
    SFX.pulse(true);
    hud();
  }

  function finish(kind) {
    const c = t();
    const ov = document.getElementById("endOv");
    show("endOv", true);
    document.getElementById("endTag").textContent = kind === "win" ? "KO" : "KO";
    document.getElementById("endTitle").textContent = kind === "win" ? c.win : c.lose;
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
    // true hitbox
    ctx.save();
    ctx.globalAlpha = 0.9;
    ctx.fillStyle = "#22d3ee";
    ctx.fillRect(state.player.x - 2, state.player.y - 2, 4, 4);
    ctx.restore();
    state.fx.live.forEach(f => GLYPHS.drawBurst(ctx, f.x, f.y, f.life, f.color));
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
  document.getElementById("deckBtn").onclick = () => {
    SFX.unlock();
    if (screen === "title") openLoadout();
    else if (screen === "loadout") startFight();
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

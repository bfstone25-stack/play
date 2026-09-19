/* Screens, input, persistence. The loop lives in BMCore; this file only wires it. */
var BMRPG = (() => {
  const $ = id => document.getElementById(id);
  let canvas, ctx, profile, run = null, raf = 0, last = 0, clock = 0;
  let target = null, autopilot = false, screen = "title";
  const t = (k, v) => I18N.t(k, v);

  function langCode() {
    try {
      const saved = localStorage.getItem("bm.lang");
      if (saved) return saved;
    } catch (e) {}
    const n = (navigator.language || "en").toLowerCase();
    return n.indexOf("zh") === 0 ? "zh" : "en";
  }

  function save() {
    try { Save.persist({ beatMonday: profile }); } catch (e) {}
  }
  function loadProfile() {
    let data = {};
    try { data = Save.load() || {}; } catch (e) {}
    const p = data.beatMonday;
    const base = BMCore.newProfile();
    return p && p.role ? Object.assign(base, p) : base;
  }

  function show(id) {
    ["titleOv", "weekOv", "briefOv", "lvOv", "resOv", "deskOv", "endOv"].forEach(x => {
      const el = $(x); if (el) el.classList.toggle("show", x === id);
    });
    screen = id;
    if (window.TEL && TEL.ev) TEL.ev("screen", { screen: id });
  }

  // ---------- title / week board ----------
  function renderTitle() {
    $("tBrand").textContent = t("brand");
    $("tSub").textContent = t("sub");
    $("btnStart").textContent = profile.cleared.length ? t("cont") : t("start");
    $("btnDesk").textContent = t("locker");
    $("tHint").textContent = t("drag");
    show("titleOv");
  }

  function renderWeek() {
    $("wTitle").textContent = t("week", { n: (profile.week | 0) + 1 });
    const s = BMCore.computeStats(profile);
    $("wStats").textContent = t("stats", { lv: profile.level, hp: s.hp, atk: s.atk, rate: s.rate });
    const box = $("wDays");
    box.innerHTML = "";
    BMData.DAYS.forEach((d, i) => {
      const b = document.createElement("button");
      const done = profile.cleared.indexOf(d.id) >= 0;
      const locked = i > profile.day;
      b.className = "dayBtn" + (done ? " done" : "") + (locked ? " locked" : "");
      b.id = "day-" + d.id;
      b.innerHTML = "<em>" + t("day_" + d.id) + "</em><span>" + t("boss_" + d.boss) + "</span>";
      b.disabled = locked;
      b.onclick = () => brief(i);
      box.appendChild(b);
    });
    show("weekOv");
  }

  function brief(i) {
    const d = BMData.DAYS[i];
    $("bDay").textContent = t("day_" + d.id);
    $("bBoss").textContent = t("boss_" + d.boss);
    $("bBody").textContent = t("brief_" + d.id) + (d.mode === "rant" ? "  " + t("rant_hint") : "");
    $("bGo").textContent = t("go");
    $("bGo").onclick = () => startDay(i);
    $("bBack").textContent = t("back");
    $("bBack").onclick = renderWeek;
    show("briefOv");
  }

  // ---------- desk (equipment) ----------
  function renderDesk() {
    const box = $("dList");
    box.innerHTML = "";
    if (!profile.owned.length) {
      const p = document.createElement("p");
      p.textContent = "—";
      box.appendChild(p);
    }
    profile.owned.forEach(id => {
      const item = BMData.EQUIP.find(e => e.id === id);
      const on = profile.equipped[item.slot] === id;
      const b = document.createElement("button");
      b.className = "eqBtn" + (on ? " on" : "");
      b.id = "eq-" + id;
      b.innerHTML = "<em>" + t("eq_" + id) + "</em><span>" + item.slot + " · " +
        Object.keys(item.mods).map(k => k + " " + (item.mods[k] > 0 ? "+" : "") + item.mods[k]).join(" ") +
        "</span>" + (on ? "<small>" + t("equipped") + "</small>" : "");
      b.onclick = () => { BMCore.equip(profile, id); save(); renderDesk(); };
      box.appendChild(b);
    });
    const s = BMCore.computeStats(profile);
    $("dStats").textContent = t("stats", { lv: profile.level, hp: s.hp, atk: s.atk, rate: s.rate });
    $("dHint").textContent = t("tap_equip");
    $("dParty").textContent = (profile.party || []).map(id => t("pt_" + id)).join(" · ");
    $("dBack").textContent = t("back");
    $("dBack").onclick = () => (profile.cleared.length ? renderWeek() : renderTitle());
    show("deskOv");
  }

  // ---------- the day ----------
  function startDay(i) {
    run = BMCore.createRun(profile, i, Date.now() & 0xffff);
    run.lang = I18N.current() === "zh" ? "zh" : "en";
    target = { x: run.px, y: run.py };
    show("");
    if (window.TEL && TEL.play_start) TEL.play_start({ day: BMData.DAYS[i].id, week: profile.week });
    last = 0;
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(frame);
  }

  function frame(ts) {
    raf = requestAnimationFrame(frame);
    if (!last) last = ts;
    const dt = Math.min(0.05, (ts - last) / 1000);
    last = ts;
    clock += dt;
    if (!run) return;
    if (autopilot) {
      const n = BMCore.nearestFoe(run);
      if (n) {
        const dx = run.px - n.x, dy = run.py - n.y, m = Math.hypot(dx, dy) || 1;
        target = { x: Math.max(20, Math.min(BMCore.W - 20, run.px + dx / m * 120)),
                   y: Math.max(70, Math.min(BMCore.H - 20, run.py + dy / m * 120)) };
      }
      if (run.pending) pickSkill(run.pending[0]);
    }
    BMCore.step(run, dt, target);
    BMRender.draw(ctx, run, clock);
    if (run.pending && screen !== "lvOv") levelUp();
    if (run.over && screen !== "resOv" && screen !== "endOv") finish();
  }

  function levelUp() {
    $("lvTitle").textContent = t("lvup", { n: run.level });
    $("lvPick").textContent = t("pick");
    const box = $("lvCards");
    box.innerHTML = "";
    run.pending.forEach(id => {
      const b = document.createElement("button");
      b.className = "card";
      b.id = "sk-" + id;
      b.textContent = t("sk_" + id);
      b.onclick = () => pickSkill(id);
      box.appendChild(b);
    });
    show("lvOv");
  }

  function pickSkill(id) {
    if (!run || !run.pending) return;
    BMCore.applySkill(run, id);
    show("");
  }

  function finish() {
    cancelAnimationFrame(raf); raf = 0;
    const won = run.over === "clear";
    const idx = run.dayIndex;
    BMCore.commitRun(profile, run);
    save();
    if (window.TEL && TEL.play_end) TEL.play_end({ day: BMData.DAYS[idx].id, won: won, kills: run.kills });
    $("rTitle").textContent = won ? t("cleared") : t("dead");
    const lines = [];
    if (won && run.reward) lines.push(t("got", { item: t("eq_" + run.reward) }));
    if (won) BMData.PARTY.forEach(p => { if (p.after === BMData.DAYS[idx].id) lines.push(t("joined", { who: t("pt_" + p.id) })); });
    $("rBody").textContent = lines.join("  ");
    $("rGo").textContent = won ? t("back") : t("retry");
    $("rGo").onclick = () => {
      if (!won) { startDay(idx); return; }
      if (profile.weekend) { profile.weekend = false; save(); return weekend(); }
      renderWeek();
    };
    $("rDesk").textContent = t("locker");
    $("rDesk").onclick = renderDesk;
    show("resOv");
  }

  function weekend() {
    $("eTitle").textContent = t("weekend");
    $("eBody").textContent = t("weekend_body");
    $("eGo").textContent = t("nextweek", { n: (profile.week | 0) + 1 });
    $("eGo").onclick = renderWeek;
    $("eDesk").textContent = t("locker");
    $("eDesk").onclick = renderDesk;
    show("endOv");
  }

  // ---------- input ----------
  function bindInput() {
    const toLocal = e => {
      const r = canvas.getBoundingClientRect();
      const p = e.touches && e.touches[0] ? e.touches[0] : e;
      return { x: (p.clientX - r.left) / r.width * BMCore.W, y: (p.clientY - r.top) / r.height * BMCore.H };
    };
    let down = false;
    const start = e => { down = true; target = toLocal(e); e.preventDefault(); };
    const move = e => { if (down) { target = toLocal(e); e.preventDefault(); } };
    const end = () => { down = false; };
    canvas.addEventListener("pointerdown", start);
    canvas.addEventListener("pointermove", move);
    window.addEventListener("pointerup", end);
    canvas.addEventListener("touchstart", start, { passive: false });
    canvas.addEventListener("touchmove", move, { passive: false });
  }

  function setLang(code) {
    I18N.setLang(code);
    try { localStorage.setItem("bm.lang", I18N.current()); } catch (e) {}
    if (screen === "titleOv") renderTitle();
    else if (screen === "weekOv") renderWeek();
    else if (screen === "deskOv") renderDesk();
  }

  function boot() {
    canvas = $("game");
    ctx = BMRender.fit(canvas);
    I18N.register(BMStrings);
    I18N.setLang(langCode());
    profile = loadProfile();
    bindInput();
    $("btnStart").onclick = () => (profile.cleared.length || profile.week ? renderWeek() : brief(0));
    $("btnDesk").onclick = renderDesk;
    document.querySelectorAll("[data-lang]").forEach(b => {
      b.onclick = () => setLang(b.getAttribute("data-lang"));
    });
    renderTitle();
    if (!raf) raf = requestAnimationFrame(frame);
  }

  return {
    boot, startDay, pickSkill, renderWeek, renderDesk,
    get run() { return run; },
    get profile() { return profile; },
    setAuto(v) { autopilot = !!v; },
    resetSave() { profile = BMCore.newProfile(); save(); renderTitle(); },
  };
})();

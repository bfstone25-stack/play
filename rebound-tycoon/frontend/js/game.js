(() => {
  const KEY = "rebound.tycoon.v2";
  const canvas = document.getElementById("stage");
  const reducePref = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const LANGS = REBOUND_COPY.langs;

  const persist = { lang: "en", sound: true, motion: !reducePref, bestCoins: 0, prestiges: 0 };
  try { Object.assign(persist, JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (_) {}
  if (LANGS.indexOf(persist.lang) < 0) persist.lang = "en";

  let lang = persist.lang;
  let soundOn = persist.sound !== false;
  let motionOn = persist.motion !== false;
  let st = hydrate(persist.run);
  const input = { left: false, right: false, plunge: false, fire: false };
  let last = performance.now();
  let bannerTimer = 0;
  let firstHit = persist.firstHit || false;
  let firstBuy = persist.firstBuy || false;
  let started = persist.started || false;

  function t() { return REBOUND_COPY[lang] || REBOUND_COPY.en; }
  function tel(name, value) {
    if (window.TEL && window.TEL.ev) window.TEL.ev(name, value || {});
  }
  function save() {
    persist.lang = lang;
    persist.sound = soundOn;
    persist.motion = motionOn;
    persist.run = snapshot(st);
    persist.bestCoins = Math.max(persist.bestCoins || 0, st.lifetime);
    persist.prestiges = Math.max(persist.prestiges || 0, st.prestiges);
    persist.firstHit = firstHit;
    persist.firstBuy = firstBuy;
    persist.started = started;
    try { localStorage.setItem(KEY, JSON.stringify(persist)); } catch (_) {}
  }
  function banner(text) {
    const el = document.getElementById("banner");
    el.textContent = text;
    el.classList.add("show");
    bannerTimer = 1.4;
  }
  function setLine(key) {
    document.getElementById("loreLine").textContent = t().lines[key] || t().tagline;
  }
  function syncLangButtons() {
    document.querySelectorAll("[data-lang]").forEach((btn) => {
      const on = btn.getAttribute("data-lang") === lang;
      btn.classList.toggle("active", on);
      btn.classList.toggle("on", on);
    });
  }
  function renderText() {
    const c = t();
    document.documentElement.lang = lang === "zh" ? "zh-CN" : lang === "pt" ? "pt-BR" : lang;
    document.title = c.wordmark + " · " + c.localTitle;
    document.getElementById("tagline").textContent = c.kicker;
    document.getElementById("wordmark").textContent = c.wordmark;
    document.getElementById("submark").textContent = c.localTitle;
    document.getElementById("lCoins").textContent = c.coins;
    document.getElementById("lRent").textContent = c.rent;
    document.getElementById("lCombo").textContent = c.combo;
    document.getElementById("lNight").textContent = c.night;
    document.getElementById("lEra").textContent = c.era;
    document.getElementById("leftLabel").textContent = c.left;
    document.getElementById("sprayLabel").textContent = c.spray;
    document.getElementById("rightLabel").textContent = c.right;
    document.getElementById("shopLabel").textContent = c.shop;
    document.getElementById("prestigeLabel").textContent = c.prestige;
    document.getElementById("introTag").textContent = c.kicker;
    document.getElementById("introTitle").textContent = c.localTitle;
    document.getElementById("introBody").textContent = c.pitch;
    document.getElementById("startLabel").textContent = c.start;
    document.getElementById("shopTitle").textContent = c.shop;
    document.getElementById("shopBody").textContent = c.shopHint;
    document.getElementById("prestigeTitle").textContent = c.prestige;
    document.getElementById("settingsTitle").textContent = c.settings;
    document.getElementById("lSound").textContent = c.sound;
    document.getElementById("lMotion").textContent = c.motion;
    document.getElementById("lLanguage").textContent = c.language;
    document.getElementById("soundState").textContent = soundOn ? c.on : c.off;
    document.getElementById("motionState").textContent = motionOn ? c.full : c.reduce;
    document.getElementById("logTitle").textContent = c.log;
    document.getElementById("logBody").textContent = c.logBody;
    document.getElementById("sendLog").textContent = c.sendLog;
    document.getElementById("shareBtn").textContent = c.share;
    document.getElementById("closeShop").textContent = c.close;
    document.getElementById("closePrestige").textContent = c.close;
    document.getElementById("closeSettings").textContent = c.close;
    document.getElementById("closeLog").textContent = c.close;
    document.getElementById("prestigeGo").textContent = c.prestigeGo;
    document.getElementById("againLabel").textContent = c.again;
    syncLangButtons();
    document.getElementById("soundBtn").setAttribute("aria-pressed", soundOn ? "true" : "false");
  }
  function renderShop() {
    const c = t();
    const box = document.getElementById("shopList");
    box.innerHTML = "";
    let lastGroup = "";
    UPGRADES.forEach((u) => {
      if (u.group !== lastGroup) {
        lastGroup = u.group;
        const lab = document.createElement("div");
        lab.className = "group-label";
        lab.textContent = c.groups[u.group];
        box.appendChild(lab);
      }
      const lv = levelOf(st, u.id);
      const cost = upgradeCost(u.id, lv);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "shop-card";
      btn.disabled = !canBuy(st, u.id);
      btn.innerHTML = "<div><b>" + c.upgrades[u.id] + " · " + (lv + 1) + "</b><em>" + c.hints[u.id] + "</em></div><strong>" + formatCoins(cost) + "</strong>";
      btn.addEventListener("click", () => {
        const res = buy(st, u.id);
        if (!res.ok) { banner(c.need); return; }
        const prevEra = eraId(st);
        st = res.state;
        REBOUND_AUDIO.buy();
        if (!firstBuy) { firstBuy = true; tel("first_buy", { id: u.id }); }
        if (eraId(st) !== prevEra) {
          tel("era_up", { era: eraId(st) });
          banner(c.eras[eraId(st)]);
          setLine(eraId(st));
        } else setLine("buy");
        save();
        renderHud();
        renderShop();
      });
      box.appendChild(btn);
    });
  }
  function renderPerks() {
    const c = t();
    const box = document.getElementById("perkList");
    box.innerHTML = "";
    PERKS.forEach((p) => {
      const lv = perkOf(st, p.id);
      const cost = perkCost(p.id, lv);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "shop-card";
      btn.disabled = !canBuyPerk(st, p.id);
      btn.innerHTML = "<div><b>" + c.perks[p.id] + " · " + (lv + 1) + "</b><em>" + c.perkHints[p.id] + "</em></div><strong>" + cost + "</strong>";
      btn.addEventListener("click", () => {
        const res = buyPerk(st, p.id);
        if (!res.ok) { banner(c.needTokens); return; }
        st = res.state;
        REBOUND_AUDIO.buy();
        save();
        renderHud();
        renderPerks();
      });
      box.appendChild(btn);
    });
  }
  function renderHud() {
    const c = t();
    const era = eraId(st);
    document.getElementById("coins").textContent = formatCoins(st.coins);
    document.getElementById("rent").textContent = formatCoins(st.score);
    document.getElementById("combo").textContent = String(st.combo);
    document.getElementById("night").textContent = String(st.night);
    document.getElementById("eraName").textContent = c.eras[era];
    document.getElementById("tokens").textContent = String(st.tokens);
    document.getElementById("tokenHint").textContent = String(st.tokens);
    document.getElementById("balls").textContent = String(Math.max(0, st.balls));
    document.getElementById("lBalls").textContent = c.balls;
    const stateKey = st.mode === "live" ? "live" : st.mode === "nightover" ? "nightover" : "ringing";
    document.getElementById("runState").textContent = c[stateKey];
    const score = skylineScore(st);
    const idx = eraIndex(st);
    const nxt = ERAS[Math.min(ERAS.length - 1, idx + 1)];
    const prev = ERAS[idx].minScore;
    const span = Math.max(1, nxt.minScore - prev);
    const fill = idx >= ERAS.length - 1 ? 1 : Math.min(1, (score - prev) / span);
    document.getElementById("eraFill").style.width = (fill * 100) + "%";
    document.getElementById("guardPlate").className = "guard-plate " + era;
    document.getElementById("dutyLine").textContent = st.mode === "plunge"
      ? (c.launchHint || t().lines.booth)
      : t().lines[era];
    document.getElementById("prestigeBody").textContent = canPrestige(st) ? c.prestigeHint + " +" + prestigeTokensFor(st) : c.prestigeLocked;
    document.getElementById("prestigeGo").disabled = !canPrestige(st);
    document.getElementById("againBtn").style.display = st.mode === "nightover" ? "block" : "none";
  }
  function openOverlay(id, on) {
    document.getElementById(id).classList.toggle("show", !!on);
  }
  function closeAll() {
    ["shop", "prestige", "settings", "log"].forEach((id) => openOverlay(id, false));
  }
  ["shop", "prestige", "settings", "log"].forEach((id) => {
    document.getElementById(id).addEventListener("click", (e) => {
      if (e.target.id === id) openOverlay(id, false);
    });
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeAll();
  });
  function applyLang(next) {
    lang = next;
    tel("language", { lang });
    renderText();
    renderHud();
    renderShop();
    renderPerks();
    save();
  }
  function startDuty() {
    started = true;
    openOverlay("intro", false);
    REBOUND_AUDIO.engage(eraIndex(st));
    tel("start", { lang, era: eraId(st) });
    save();
    renderHud();
  }
  function shareNight() {
    const text = t().shareText + " · " + formatCoins(st.lifetime) + " · " + t().eras[eraId(st)];
    const url = location.href;
    if (navigator.share) navigator.share({ title: t().wordmark, text, url }).catch(() => {});
    else if (navigator.clipboard) navigator.clipboard.writeText(text + " " + url).then(() => banner(t().copied)).catch(() => {});
    tel("share", { era: eraId(st) });
  }

  document.querySelectorAll("[data-lang]").forEach((btn) => {
    btn.addEventListener("click", () => applyLang(btn.getAttribute("data-lang")));
  });
  document.getElementById("soundBtn").addEventListener("click", () => {
    soundOn = !soundOn;
    REBOUND_AUDIO.setEnabled(soundOn);
    if (soundOn) REBOUND_AUDIO.engage(eraIndex(st));
    renderText();
    save();
  });
  document.getElementById("settingsBtn").addEventListener("click", () => openOverlay("settings", true));
  document.getElementById("soundToggle").addEventListener("click", () => {
    soundOn = !soundOn;
    REBOUND_AUDIO.setEnabled(soundOn);
    renderText();
    save();
  });
  document.getElementById("motionToggle").addEventListener("click", () => {
    motionOn = !motionOn;
    renderText();
    save();
  });
  document.getElementById("startBtn").addEventListener("click", startDuty);
  document.getElementById("shopBtn").addEventListener("click", () => { renderShop(); openOverlay("shop", true); });
  document.getElementById("prestigeBtn").addEventListener("click", () => { renderPerks(); renderHud(); openOverlay("prestige", true); });
  document.getElementById("closeShop").addEventListener("click", () => openOverlay("shop", false));
  document.getElementById("closeShopX").addEventListener("click", () => openOverlay("shop", false));
  document.getElementById("closePrestige").addEventListener("click", () => openOverlay("prestige", false));
  document.getElementById("closePrestigeX").addEventListener("click", () => openOverlay("prestige", false));
  document.getElementById("closeSettings").addEventListener("click", () => openOverlay("settings", false));
  document.getElementById("closeSettingsX").addEventListener("click", () => openOverlay("settings", false));
  document.getElementById("closeLog").addEventListener("click", () => openOverlay("log", false));
  document.getElementById("closeLogX").addEventListener("click", () => openOverlay("log", false));
  document.getElementById("logBtn").addEventListener("click", () => openOverlay("log", true));
  document.getElementById("shareBtn").addEventListener("click", shareNight);
  document.getElementById("sendLog").addEventListener("click", () => {
    const score = document.querySelector(".scores button.on");
    if (window.TEL && window.TEL.feedback) {
      window.TEL.feedback(score ? score.getAttribute("data-score") : 0, document.getElementById("logNote").value);
    }
    openOverlay("log", false);
    banner(t().sendLog);
  });
  document.querySelectorAll(".scores button").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".scores button").forEach((b) => b.classList.remove("on"));
      btn.classList.add("on");
    });
  });
  document.getElementById("prestigeGo").addEventListener("click", () => {
    const res = doPrestige(st);
    if (!res.ok) return;
    st = res.state;
    REBOUND_AUDIO.prestige();
    tel("prestige", { tokens: res.tokens, night: st.night });
    setLine("prestige");
    banner(t().prestige + " +" + res.tokens);
    openOverlay("prestige", false);
    save();
    renderHud();
    renderShop();
    renderPerks();
  });
  document.getElementById("againBtn").addEventListener("click", () => {
    st = newNight(st);
    REBOUND_AUDIO.tap();
    save();
    renderHud();
  });

  function menuOpen() {
    return ["shop", "prestige", "settings", "log"].some((id) => document.getElementById(id).classList.contains("show"));
  }
  function blurButtons() {
    const el = document.activeElement;
    if (el && el.tagName === "BUTTON") el.blur();
  }
  function bindHold(el, key) {
    el.setAttribute("tabindex", "-1");
    const down = (e) => {
      e.preventDefault();
      el.blur();
      if (el.setPointerCapture && e.pointerId != null) el.setPointerCapture(e.pointerId);
      input[key] = true;
      REBOUND_AUDIO.engage(eraIndex(st));
      if (key === "left" || key === "right") REBOUND_AUDIO.flip();
    };
    const up = (e) => {
      if (e) e.preventDefault();
      input[key] = false;
      if (key === "plunge") input.fire = true;
    };
    el.addEventListener("pointerdown", down);
    el.addEventListener("pointerup", up);
    el.addEventListener("pointercancel", up);
    el.addEventListener("contextmenu", (e) => e.preventDefault());
    el.addEventListener("click", (e) => {
      e.preventDefault();
      el.blur();
      if (key === "plunge") input.fire = true;
    });
    el.addEventListener("keydown", (e) => {
      if (e.code === "Space" || e.key === " ") e.preventDefault();
    });
  }
  bindHold(document.getElementById("leftBtn"), "left");
  bindHold(document.getElementById("rightBtn"), "right");
  bindHold(document.getElementById("sprayBtn"), "plunge");
  document.getElementById("startBtn").setAttribute("tabindex", "-1");

  function mapKey(e) {
    if (e.code === "Space" || e.code === "Spacebar" || e.key === " " || e.key === "Spacebar") return "plunge";
    const keys = {
      ArrowLeft: "left", KeyZ: "left", KeyA: "left",
      ArrowRight: "right", Slash: "right", KeyX: "right", KeyL: "right",
      ArrowDown: "plunge", Enter: "plunge",
      ShiftLeft: "plunge", ShiftRight: "plunge",
    };
    return keys[e.code] || keys[e.key] || null;
  }
  window.addEventListener("keydown", (e) => {
    const k = mapKey(e);
    if (!k) return;
    if (menuOpen()) return;
    e.preventDefault();
    e.stopPropagation();
    blurButtons();
    if (!started) startDuty();
    if (st.mode === "nightover" && k === "plunge") {
      st = newNight(st);
      REBOUND_AUDIO.tap();
      save();
      renderHud();
      return;
    }
    if (e.repeat && k === "plunge") { input.plunge = true; return; }
    if (e.repeat) return;
    input[k] = true;
    REBOUND_AUDIO.engage(eraIndex(st));
    if (k === "left" || k === "right") REBOUND_AUDIO.flip();
  }, true);
  window.addEventListener("keyup", (e) => {
    const k = mapKey(e);
    if (!k) return;
    e.preventDefault();
    input[k] = false;
    if (k === "plunge" && !menuOpen()) input.fire = true;
  }, true);

  canvas.addEventListener("pointerdown", (e) => {
    const mid = canvas.clientWidth / 2;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    if (y > rect.height * 0.78) input.plunge = true;
    else if (x < mid) { input.left = true; REBOUND_AUDIO.flip(); }
    else { input.right = true; REBOUND_AUDIO.flip(); }
    REBOUND_AUDIO.engage(eraIndex(st));
  });
  canvas.addEventListener("pointerup", () => {
    if (input.plunge) input.fire = true;
    input.left = false;
    input.right = false;
    input.plunge = false;
  });

  if (started) openOverlay("intro", false);
  REBOUND_AUDIO.setEnabled(soundOn);
  renderText();
  renderHud();
  renderShop();
  renderPerks();
  setLine(eraId(st));
  tel("visit", { lang });

  function handleEvents(events) {
    events.forEach((ev) => {
      if (ev.type === "bumper" || ev.type === "sling" || ev.type === "target" || ev.type === "saucer" || ev.type === "gate") {
        REBOUND_AUDIO.coin(st.combo);
        if (ev.type === "bumper") REBOUND_AUDIO.bumper();
        if (ev.type === "target" || ev.type === "gate") REBOUND_AUDIO.intercom();
        const hitKey = ev.id || (ev.type === "gate" ? "gate" : ev.type === "sling" ? "sling" : ev.type === "saucer" ? "cannon" : "bumper");
        const hits = t().hits || {};
        document.getElementById("dutyLine").textContent = hits[hitKey] || t().lines.bumper;
        if (st.ball) {
          const hx = st.ball.x * canvas.clientWidth, hy = st.ball.y * canvas.clientHeight;
          REBOUND_STAGE.spark(hx, hy, "#f4d78a");
          REBOUND_STAGE.burstCoins(hx, hy, 7);
          REBOUND_STAGE.spray(hx, hy, 10);
          REBOUND_STAGE.floatText(hx, hy - 12, "+$" + (ev.pts || 0));
        }
        if (!firstHit) { firstHit = true; tel("first_rebound", ev); }
      }
      if (ev.type === "launch") { REBOUND_AUDIO.tap(); setLine("launch"); }
      if (ev.type === "reload") { document.getElementById("dutyLine").textContent = t().launchHint || t().lines.booth; }
      if (ev.type === "cannon") {
        REBOUND_AUDIO.spray();
        document.getElementById("dutyLine").textContent = (t().hits && t().hits.cannon) || t().lines.launch;
        if (st.ball) REBOUND_STAGE.spray(st.ball.x * canvas.clientWidth, st.ball.y * canvas.clientHeight, 18);
      }
      if (ev.type === "drain") { REBOUND_AUDIO.miss(); setLine("drain"); banner(t().lines.drain); }
      if (ev.type === "save") { REBOUND_AUDIO.buy(); setLine("save"); banner(t().lines.save); }
      if (ev.type === "nightover") { REBOUND_AUDIO.miss(); setLine("nightover"); banner(t().lines.nightover); }
    });
  }

  function frame(now) {
    const dt = Math.min(0.033, (now - last) / 1000);
    last = now;
    if (!started && (input.left || input.right || input.plunge || input.fire)) startDuty();
    const out = step(st, input, dt);
    st = out.state;
    input.fire = false;
    document.getElementById("sprayBtn").classList.toggle("charging", st.mode === "plunge" && (input.plunge || st.plunge > 0.02));
    handleEvents(out.events);
    if (bannerTimer > 0) {
      bannerTimer -= dt;
      if (bannerTimer <= 0) document.getElementById("banner").classList.remove("show");
    }
    REBOUND_STAGE.draw(canvas, st, { reduce: !motionOn || reducePref, dt, hint: t().spaceHint || "HOLD SPACE" });
    renderHud();
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  setInterval(save, 4000);
  window.addEventListener("beforeunload", save);
  if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
})();

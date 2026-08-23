(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d", { alpha: false, desynchronized: true });
  const W = ALTAR.W, H = ALTAR.H;
  const TOUCH = window.matchMedia("(max-width: 1024px), (pointer: coarse), (hover: none)").matches
    || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent || "");
  const PERF_LITE = TOUCH;
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const DPR = PERF_LITE ? Math.min(1.5, window.devicePixelRatio || 1) : Math.min(2, window.devicePixelRatio || 1);
  canvas.width = W * DPR;
  canvas.height = H * DPR;
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);

  const $ = (id) => document.getElementById(id);
  const cabinet = $("cabinet");
  const fxLayer = $("fxLayer");
  const pulseHint = $("pulseHint");

  FX.setCap(PERF_LITE ? 48 : 160);
  FX.seedRain(W, H, PERF_LITE ? 18 : 42);

  const saved = Save.load();
  if (saved.merit && typeof saved.merit === "object") {
    LITURGY.load({ ...saved.merit, merit: saved.merit.merit });
  } else {
    LITURGY.load(saved);
  }
  const idleGain = LITURGY.applyIdle(Date.now());
  I18N.setLang(LITURGY.snapshot().lang || "zh-Hans");

  const CAM = { yaw: 0, pitch: 6, punch: 0, userYaw: 0, userPitch: 0 };
  let lastHud = "";
  let incenseAcc = 0;
  let persistT = 0;
  let anchors = { fish: { x: 210, y: 400 }, incense: { x: 210, y: 448 }, lotus: { x: 210, y: 168 } };

  function toast(msg) {
    const el = $("toast");
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(toast.t);
    toast.t = setTimeout(() => el.classList.remove("show"), 1600);
  }

  function mascotLine(kind) {
    const line = MASCOT.say(kind, I18N.getLang());
    $("mascotLine").textContent = line;
    $("mascotFace").textContent = MASCOT.face;
  }

  function floatNum(text, combo) {
    const rect = canvas.getBoundingClientRect();
    const el = document.createElement("div");
    el.className = "float-num" + (combo ? " combo" : "");
    el.textContent = text;
    el.style.left = (rect.left + rect.width * 0.5) + "px";
    el.style.top = (rect.top + rect.height * 0.58) + "px";
    fxLayer.appendChild(el);
    setTimeout(() => el.remove(), 800);
  }

  function haptic(ms) {
    if (!LITURGY.snapshot().settings.haptics) return;
    if (navigator.vibrate) navigator.vibrate(ms);
  }

  function syncCam() {
    const motion = LITURGY.snapshot().settings.motion && !reduced;
    const punch = motion ? CAM.punch : 0;
    document.documentElement.style.setProperty("--yaw", (CAM.yaw + CAM.userYaw).toFixed(2) + "deg");
    document.documentElement.style.setProperty("--pitch", (CAM.pitch + CAM.userPitch).toFixed(2) + "deg");
    document.documentElement.style.setProperty("--punch", punch.toFixed(1) + "px");
    if (CAM.punch > 0) CAM.punch *= 0.82;
  }

  function hud() {
    const s = LITURGY.snapshot();
    const key = [s.merit, s.combo, s.fill, s.need, s.auto, s.upgrades.fish].join("|");
    if (key === lastHud) return;
    lastHud = key;
    $("meritValue").textContent = s.merit;
    $("comboValue").textContent = s.combo;
    $("mandalaLabel").textContent = Math.floor(s.fill) + " / " + s.need;
    $("mandalaFill").style.width = Math.min(100, (s.fill / s.need) * 100) + "%";
    $("autoValue").textContent = s.auto.toFixed(1) + "/s";
    const track = $("comboTrack");
    track.innerHTML = "";
    for (let i = 0; i < 6; i++) {
      const d = document.createElement("i");
      if (i < Math.min(6, s.combo)) d.className = "on";
      track.appendChild(d);
    }
    $("runState").textContent = s.inWindow ? (I18N.getLang() === "en" ? "PULSE" : "香脉") : I18N.t("ui.ready");
    pulseHint.classList.toggle("hot", s.inWindow);
  }

  function persist() {
    Save.persist(LITURGY.persistable());
  }

  function doStrike(fromAuto) {
    const snap0 = LITURGY.snapshot();
    const res = LITURGY.strike();
    const motion = snap0.settings.motion && !reduced;
    ALTAR.punch(res.perfect ? 1 : 0.55);
    if (motion) {
      CAM.punch = res.perfect ? 18 : 10;
      cabinet.classList.remove("shake");
      void cabinet.offsetWidth;
      cabinet.classList.add("shake");
    }
    SFX.strike(res.combo);
    if (res.perfect) SFX.perfect(res.combo);
    haptic(res.perfect ? [8, 20, 12] : 8);
    FX.spiral(anchors.fish.x, anchors.fish.y, PERF_LITE ? 8 : 14 + Math.min(12, res.combo), null, res.combo);
    floatNum("+" + res.gain, res.perfect);
    if (res.perfect) mascotLine("combo");
    else if (snap0.combo > 2 && res.combo === 0) mascotLine("drop");
    else if (!fromAuto && Math.random() < 0.18) mascotLine("strike");
    if (res.complete) {
      ALTAR.complete();
      SFX.liturgy();
      FX.bloom(anchors.lotus.x, anchors.lotus.y);
      toast(I18N.t("toast.liturgy"));
      mascotLine("liturgy");
      try {
        localStorage.setItem("blazecore_reward_receipt", JSON.stringify({
          app: "cyber-merit", merit: LITURGY.snapshot().merit, at: Date.now(),
        }));
      } catch (e) { /* ignore */ }
      openKoan(true);
    }
    hud();
    persist();
  }

  function renderShop() {
    const s = LITURGY.snapshot();
    const box = $("shopList");
    box.innerHTML = "";
    Object.keys(LITURGY.TRACKS).forEach((track) => {
      const spec = LITURGY.TRACKS[track];
      const lv = s.upgrades[track];
      const maxed = lv >= spec.max;
      const c = LITURGY.cost(track, lv);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "shop-row";
      btn.disabled = maxed || s.merit < c;
      const name = I18N.t("track." + track);
      const tier = I18N.t(track + "." + lv);
      btn.innerHTML = "<div><b>" + name + " · " + tier + "</b><span>Lv " + lv + " / " + spec.max + "</span></div><em>" +
        (maxed ? I18N.t("shop.max") : c + " 功德") + "</em>";
      btn.onclick = () => {
        if (!LITURGY.tryUpgrade(track)) { toast(I18N.t("shop.need")); return; }
        SFX.upgrade();
        toast(I18N.t("toast.up"));
        mascotLine("upgrade");
        hud();
        persist();
        renderShop();
      };
      box.appendChild(btn);
    });
  }

  function openModal(id, on) {
    $(id).hidden = !on;
  }

  function openKoan(fromLiturgy) {
    const k = KOANS.today(I18N.getLang());
    $("koanTitle").textContent = k.text;
    $("koanBody").textContent = I18N.getLang() === "en" ? k.zh : k.en;
    openModal("koanModal", true);
    if (fromLiturgy) SFX.ofuda();
  }

  function drawCard() {
    const c = $("shareCard");
    const g = c.getContext("2d");
    const s = LITURGY.snapshot();
    const k = KOANS.today(I18N.getLang());
    g.fillStyle = "#070b16";
    g.fillRect(0, 0, 720, 960);
    const bg = g.createLinearGradient(0, 0, 0, 960);
    bg.addColorStop(0, "#12081c");
    bg.addColorStop(1, "#1a100c");
    g.fillStyle = bg;
    g.fillRect(0, 0, 720, 960);
    g.strokeStyle = "#c9a227";
    g.lineWidth = 4;
    g.strokeRect(28, 28, 664, 904);
    g.fillStyle = "#ff2d95";
    g.font = "22px Syne, sans-serif";
    g.fillText("CABINET 07", 56, 80);
    g.fillStyle = "#ffe08a";
    g.font = "bold 48px Noto Serif SC, serif";
    g.fillText("赛博木鱼", 56, 140);
    g.fillStyle = "#3dba8a";
    g.font = "18px Syne, sans-serif";
    g.fillText("CYBER MERIT", 56, 172);
    g.strokeStyle = "#c9a227";
    g.beginPath();
    g.arc(360, 380, 110, 0, Math.PI * 2);
    g.stroke();
    for (let i = 0; i < 8; i++) {
      const a = (Math.PI * 2 * i) / 8;
      g.beginPath();
      g.ellipse(360 + Math.cos(a) * 130, 380 + Math.sin(a) * 130, 22, 9, a, 0, Math.PI * 2);
      g.strokeStyle = i % 2 ? "#3dba8a" : "#ff2d95";
      g.stroke();
    }
    g.fillStyle = "#ffe08a";
    g.font = "bold 64px Syne, sans-serif";
    g.textAlign = "center";
    g.fillText(String(s.merit), 360, 400);
    g.font = "16px Syne, sans-serif";
    g.fillStyle = "#8aa0b8";
    g.fillText("MERIT", 360, 430);
    g.textAlign = "left";
    g.fillStyle = "#f4ead8";
    g.font = "22px Noto Serif SC, serif";
    wrapText(g, k.text, 56, 620, 608, 32);
    g.fillStyle = "#3dba8a";
    g.font = "14px Syne, sans-serif";
    g.fillText("LING-7  ·  liturgy " + s.liturgyCount + "  ·  combo best " + s.comboBest, 56, 880);
    g.fillStyle = "#c9a227";
    g.fillText("play.blazecore.dev/cyber-merit", 56, 908);
  }

  function wrapText(g, text, x, y, max, lh) {
    const chars = text.split("");
    let line = "", yy = y;
    chars.forEach((ch) => {
      const test = line + ch;
      if (g.measureText(test).width > max) {
        g.fillText(line, x, yy);
        line = ch;
        yy += lh;
      } else line = test;
    });
    if (line) g.fillText(line, x, yy);
  }

  canvas.addEventListener("pointerdown", (e) => {
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) * (W / rect.width);
    const y = (e.clientY - rect.top) * (H / rect.height);
    if (ALTAR.hitTest(x, y) || y > 280) doStrike(false);
  });
  $("strikeBtn").addEventListener("click", () => doStrike(false));
  window.addEventListener("keydown", (e) => {
    if (e.code === "Space" || e.key === " ") {
      e.preventDefault();
      doStrike(false);
    }
  });

  $("shopBtn").onclick = () => { renderShop(); openModal("shopModal", true); SFX.click(); };
  $("shopClose").onclick = () => openModal("shopModal", false);
  $("koanBtn").onclick = () => openKoan(false);
  $("koanClose").onclick = () => openModal("koanModal", false);
  $("settingsBtn").onclick = () => {
    const s = LITURGY.snapshot().settings;
    $("setAudio").checked = s.audio;
    $("setMotion").checked = s.motion;
    $("setHaptics").checked = s.haptics;
    openModal("settingsModal", true);
  };
  $("settingsClose").onclick = () => openModal("settingsModal", false);
  $("setAudio").onchange = () => {
    LITURGY.setSetting("audio", $("setAudio").checked);
    BGM.setOn($("setAudio").checked);
    persist();
  };
  $("setMotion").onchange = () => { LITURGY.setSetting("motion", $("setMotion").checked); persist(); };
  $("setHaptics").onchange = () => { LITURGY.setSetting("haptics", $("setHaptics").checked); persist(); };
  $("ofudaBtn").onclick = () => {
    const item = LITURGY.pullOfuda();
    if (!item) { toast(I18N.t("shop.need")); return; }
    SFX.ofuda();
    const name = I18N.getLang() === "en" ? item.en : item.zh;
    toast(I18N.t("toast.ofuda", { name }));
    hud(); persist(); renderShop();
  };
  $("cardShare").onclick = () => {
    drawCard();
    openModal("cardModal", true);
    const s = LITURGY.snapshot();
    const text = KOANS.today(I18N.getLang()).text + " · " + s.merit + " merit";
    if (navigator.share) navigator.share({ title: "Cyber Merit", text }).catch(() => {});
  };
  $("cardDownload").onclick = () => {
    const a = document.createElement("a");
    a.href = $("shareCard").toDataURL("image/png");
    a.download = "cyber-merit.png";
    a.click();
  };
  $("cardClose").onclick = () => openModal("cardModal", false);

  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.onclick = () => {
      const code = I18N.setLang(btn.getAttribute("data-lang"));
      LITURGY.setLang(code);
      persist();
      hud();
      lastHud = "";
      hud();
      $("mascotLine").textContent = MASCOT.say("idle", code);
    };
  });

  $("introGo").onclick = () => {
    $("intro").classList.add("gone");
    setTimeout(() => { $("intro").hidden = true; }, 600);
    SFX.unlock();
    BGM.start();
    if (idleGain >= 1) toast("+" + Math.floor(idleGain) + " 功德");
    mascotLine("idle");
  };

  if (!PERF_LITE) {
    window.addEventListener("pointermove", (e) => {
      CAM.userYaw = ((e.clientX / innerWidth) - 0.5) * 6;
      CAM.userPitch = ((e.clientY / innerHeight) - 0.5) * -2.5;
    }, { passive: true });
  }

  function fitViewport() {
    const slot = $("fitSlot"), shell = $("fitShell");
    if (!slot || !shell) return;
    if (TOUCH) {
      shell.style.transform = "";
      slot.style.height = "";
      slot.style.width = "100%";
      return;
    }
    shell.style.transform = "scale(1)";
    const needH = shell.offsetHeight, needW = shell.offsetWidth;
    const availH = Math.max(320, (window.visualViewport && window.visualViewport.height) || window.innerHeight) - 8;
    const availW = Math.max(280, window.innerWidth) - 4;
    const scale = Math.min(1, availH / needH, availW / needW);
    shell.style.transformOrigin = "top center";
    shell.style.transform = "scale(" + scale + ")";
    slot.style.height = Math.ceil(needH * scale) + "px";
    slot.style.width = Math.ceil(needW * scale) + "px";
  }
  window.addEventListener("resize", () => setTimeout(fitViewport, 50), { passive: true });
  requestAnimationFrame(fitViewport);

  let last = performance.now();
  function loop(now) {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    const tickGain = LITURGY.tick(dt);
    ALTAR.update(dt);
    incenseAcc += dt;
    if (incenseAcc > 0.28) {
      incenseAcc = 0;
      FX.puff(anchors.incense.x, anchors.incense.y);
    }
    const autoEvt = MASCOT.update(dt, LITURGY.snapshot().auto);
    if (autoEvt === "auto") {
      mascotLine("steal");
      FX.spiral(132, 448, 5, "#3dba8a", 1);
    }
    FX.update(dt, W, H);
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    anchors = ALTAR.draw(ctx, LITURGY.snapshot(), now);
    MASCOT.draw(ctx, now * 0.001, anchors.incense);
    FX.draw(ctx);
    syncCam();
    hud();
    persistT += dt;
    if (persistT > 4) { persistT = 0; persist(); }
    if (tickGain > 0.4) lastHud = "";
    requestAnimationFrame(loop);
  }

  hud();
  I18N.apply();
  requestAnimationFrame(loop);

  if ("serviceWorker" in navigator && location.protocol !== "file:") {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
})();

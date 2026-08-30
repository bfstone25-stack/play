/* NULL//SHRINE — 2.5D cabinet, camera punch, impact-first presentation */
(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d", { alpha: false, desynchronized: true });
  const W = LAYOUT.width, H = LAYOUT.height;
  const TOUCH_UI = window.matchMedia("(max-width: 1024px), (pointer: coarse), (hover: none)").matches
    || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent || "");
  // Perf lite: fewer particles / lighter camera — NOT a dull art pass.
  const PERF_LITE = TOUCH_UI;
  window.__NS_LOWFX = PERF_LITE;
  const DPR = PERF_LITE
    ? Math.min(1.5, window.devicePixelRatio || 1)
    : Math.min(2, window.devicePixelRatio || 1);
  canvas.width = W * DPR;
  canvas.height = H * DPR;
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);

  const $ = id => document.getElementById(id);
  const cabinet = document.getElementById("cabinet");
  const powerFill = document.getElementById("powerFill");
  const fxLayer = document.getElementById("fxLayer");
  const stage = document.getElementById("stage");
  const heatFill = document.getElementById("heatFill");
  const fitSlot = document.getElementById("fitSlot");
  const fitShell = document.getElementById("fitShell");
  if (TOUCH_UI) document.documentElement.classList.add("touch-ui");

  function fitViewport() {
    if (!fitSlot || !fitShell) return;
    // Phones use CSS flex fill — scaling would shrink the shrine art.
    if (TOUCH_UI) {
      fitShell.style.transform = "";
      fitSlot.style.height = "";
      fitSlot.style.width = "100%";
      document.documentElement.style.setProperty("--fit-scale", "1");
      return;
    }
    fitShell.style.transform = "scale(1)";
    fitSlot.style.height = "auto";
    fitSlot.style.width = "";
    const needH = fitShell.offsetHeight;
    const needW = fitShell.offsetWidth;
    const availH = Math.max(320, (window.visualViewport && window.visualViewport.height) || window.innerHeight) - 6;
    const availW = Math.max(280, window.innerWidth) - 4;
    const scale = Math.min(1, availH / needH, availW / needW);
    fitShell.style.transformOrigin = "top center";
    fitShell.style.transform = "scale(" + scale + ")";
    fitSlot.style.height = Math.ceil(needH * scale) + "px";
    fitSlot.style.width = Math.ceil(needW * scale) + "px";
    document.documentElement.style.setProperty("--fit-scale", String(scale));
  }
  let fitTimer = 0;
  const scheduleFit = () => {
    clearTimeout(fitTimer);
    fitTimer = setTimeout(fitViewport, 60);
  };
  window.addEventListener("resize", scheduleFit, { passive: true });
  if (window.visualViewport) {
    window.visualViewport.addEventListener("resize", scheduleFit, { passive: true });
  }
  requestAnimationFrame(() => { fitViewport(); requestAnimationFrame(fitViewport); });

  const CAM = {
    yaw: 0, pitch: 8, punch: 0, shake: 0, aberration: 0, flash: 0,
    speed: 0, look: 0, userYaw: 0, userPitch: 0, hitLatch: 0
  };

  function aimCamera(clientX, clientY) {
    if (PERF_LITE) return;
    CAM.userYaw = ((clientX / innerWidth) - 0.5) * 7;
    CAM.userPitch = ((clientY / innerHeight) - 0.5) * -3;
  }
  if (!PERF_LITE) {
    window.addEventListener("pointermove", e => aimCamera(e.clientX, e.clientY), { passive: true });
    window.addEventListener("pointerleave", () => { CAM.userYaw = 0; CAM.userPitch = 0; });
  }

  const state = {
    charging: false,
    power: 0,
    challenge: { id: "hit", target: 10, done: 0 },
    tickets: 20,
    busy: false,
    fragments: [],
    mode: "focus",
    heat: 8,
    chain: 0,
    multiplier: 1,
    vault: 0,
    firstSignal: false,
    pendingMultiball: 0,
    stageCooldownUntil: 0,
    runBoons: { split: false, rift: false, wave: false },
    boonOffered: false,
    sanctuaryShown: false,
    chordHits: 0,
  };
  const ritualVeil = document.getElementById("ritualVeil");
  const launchRipple = document.getElementById("launchRipple");

  const toast = (message) => {
    const el = $("toast");
    el.textContent = message; el.classList.add("show");
    clearTimeout(toast.timer); toast.timer = setTimeout(() => el.classList.remove("show"), 1800);
  };

  function updateRelayUI() {
    let mult = Math.min(4, 1 + Math.floor(state.chain / 2) * .5);
    const sig = typeof RELICS !== "undefined" ? RELICS.sigil() : null;
    if (sig && sig.passive === "chord_mult" && state.chordHits >= 3) mult = Math.min(5, mult * 2);
    if (sig && sig.passive === "flip_mult") {
      const anyFlip = WORLD.flippers && WORLD.flippers.some(f => f.pressed || Math.abs(f.omega) > 6);
      if (anyFlip) mult = Math.min(5, mult + 0.5);
    }
    state.multiplier = mult;
    $("multiplierValue").textContent = state.multiplier.toFixed(1);
    $("heatValue").textContent = String(Math.round(state.heat)).padStart(2, "0");
    $("vaultValue").textContent = state.vault;
    $("chainLabel").textContent = String(state.chain);
    document.querySelectorAll("#chainTrack i").forEach((el, i) => el.classList.toggle("on", i < state.chain));
    $("claimBtn").disabled = state.vault <= 0;
    if (heatFill) heatFill.style.width = Math.max(8, state.heat) + "%";
    document.documentElement.style.setProperty("--heat", String(state.heat / 100));
    document.documentElement.style.setProperty("--overdrive", state.mode === "surge" ? "1" : "0");
    if (typeof SFX !== "undefined" && SFX.setChain) SFX.setChain(state.chain);
    if (typeof BGM !== "undefined") {
      BGM.setIntensity(Math.min(1, state.chain / 6 * 0.7 + state.heat / 100 * 0.45));
    }
  }

  function maybeOfferBoon() {
    if (state.boonOffered || state.busy || state.heat < 100) return;
    if (typeof ECMG === "undefined" || !ECMG.openBoons) return;
    state.boonOffered = true;
    state.busy = true;
    if (typeof RELICS !== "undefined") {
      RELICS.data.stats.cores = (RELICS.data.stats.cores || 0) + 1;
      RELICS.save();
    }
    ECMG.openBoons((boon) => {
      applyBoon(boon);
      state.busy = false;
      state.heat = 42;
      updateRelayUI();
      mascotSay(t("mascot.boon"), "兔");
      toast(t(boon.nameKey));
    });
  }

  function applyBoon(boon) {
    if (!boon) return;
    if (boon.kind === "split") {
      state.runBoons.split = true;
      spawnSplitBalls(LAYOUT.launcherX, 2);
      flashBanner("banner.multi.code", "banner.multi.title", "banner.multi.sub", "rift");
    } else if (boon.kind === "rift") {
      state.runBoons.rift = true;
    } else if (boon.kind === "wave") {
      state.runBoons.wave = true;
    }
  }

  function syncRelicStats(extra) {
    if (typeof RELICS === "undefined") return;
    const s = RELICS.data.stats;
    s.jackpots = Math.max(s.jackpots || 0, STATS.jackpots);
    s.near = Math.max(s.near || 0, STATS.nearMisses);
    s.shots = Math.max(s.shots || 0, STATS.shots);
    s.vaultPeak = Math.max(s.vaultPeak || 0, state.vault);
    s.chainMax = Math.max(s.chainMax || 0, state.chain);
    if (extra) Object.assign(s, extra);
    const gained = RELICS.evaluateUnlocks();
    gained.forEach(id => {
      const all = [...RELICS.ORBS, ...RELICS.SIGILS, ...RELICS.THEMES];
      const item = all.find(x => x.id === id);
      if (item) mascotSay(t("mascot.relic", { name: t(item.nameKey) }), "兔");
    });
  }

  function maybeShowSanctuary() {
    if (state.sanctuaryShown || state.tickets > 0 || WORLD.balls.length > 0) return;
    if (STATS.shots < 1 || typeof ECMG === "undefined") return;
    state.sanctuaryShown = true;
    const seed = ($("seedValue") && $("seedValue").textContent) || "SEED";
    const card = ECMG.buildCardFromRun(seed, state.chain, state.vault);
    ECMG.drawSanctuaryCard(card, true);
    mascotSay(t("mascot.sanctuary"), "兔");
  }

  function applySigilPhysics() {
    if (typeof RELICS === "undefined") return;
    const sig = RELICS.sigil();
    const riftChance = (sig && sig.passive === "rift_save" ? 0.15 : 0) + (state.runBoons.rift ? 0.5 : 0);
    if (riftChance <= 0) return;
    for (const b of WORLD.balls) {
      if (b.state !== "flying" || b.vy < 60) continue;
      if (b.y < LAYOUT.pocketTop - 50) continue;
      if (b._riftSaved) continue;
      const nearRed = WORLD.pockets.some(p => p.kind === "red" && b.x >= p.x0 && b.x < p.x0 + p.w);
      if (!nearRed) continue;
      if (Math.random() < riftChance) {
        b._riftSaved = true;
        b.vy = -680 - Math.random() * 160;
        b.vx += (Math.random() - 0.5) * 220;
        burstParticles(b.x, b.y, 12, "#ffc53d");
        if (SFX.breakthrough) SFX.breakthrough();
        floatNum(canvas, t("ui.bunTitle"), "#ffc53d");
        mascotSay(t("mascot.breach"), "兔");
      }
    }
  }

  function checkGateWave() {
    if (!state.runBoons.wave) return;
    for (const n of WORLD.nodes) {
      if (n.type !== "gate" || n.lit < 0.85 || n._waved) continue;
      n._waved = true;
      CAM.flash = Math.max(CAM.flash, 0.7);
      CAM.punch = Math.max(CAM.punch, 18);
      for (const b of WORLD.balls) {
        if (b.state === "flying") {
          b.vy -= 180;
          b.vx *= 0.92;
        }
      }
      burstParticles(n.x, n.y, 18, "#ffc53d");
      if (SFX.phiGain) SFX.phiGain();
      setTimeout(() => { n._waved = false; }, 900);
    }
  }

  let bannerTimer = 0;
  function flashBanner(codeKey, titleKey, subKey, tone) {
    const el = $("scoreBanner");
    if (!el) return;
    $("bannerCode").textContent = t(codeKey);
    $("bannerTitle").textContent = t(titleKey);
    $("bannerSub").textContent = t(subKey);
    el.classList.remove("hot", "rift", "show");
    void el.offsetWidth;
    if (tone) el.classList.add(tone);
    el.classList.add("show");
    clearTimeout(bannerTimer);
    bannerTimer = setTimeout(() => el.classList.remove("show", "hot", "rift"), 2100);
    if (SFX.conjure) SFX.conjure();
    else if (SFX.breakthrough) SFX.breakthrough();
  }

  function spawnBaguaRipple(x, y, color) {
    if (!WORLD.ripples) WORLD.ripples = [];
    const cap = PERF_LITE ? 5 : 10;
    if (WORLD.ripples.length >= cap) WORLD.ripples.shift();
    WORLD.ripples.push({ x, y, life: 0.62, max: 0.62, color: color || "#ffc53d" });
  }

  function updateRipples(dt) {
    if (!WORLD.ripples) return;
    for (const r of WORLD.ripples) r.life -= dt;
    WORLD.ripples = WORLD.ripples.filter(r => r.life > 0);
  }

  function drawRipples() {
    if (!WORLD.ripples || !WORLD.ripples.length) return;
    ctx.save();
    ctx.globalCompositeOperation = "lighter";
    for (const rip of WORLD.ripples) {
      const p = toScreen(rip.x, rip.y);
      const u = 1 - rip.life / rip.max;
      const rad = (18 + u * 70) * p.s;
      ctx.beginPath();
      ctx.arc(p.x, p.y + 8 * p.s, rad, 0, Math.PI * 2);
      ctx.strokeStyle = rip.color.replace(")", ", " + (0.55 * (1 - u)) + ")").replace("rgb", "rgba").replace("#", "");
      // hex/rgba fallback
      const alpha = 0.55 * (1 - u);
      ctx.strokeStyle = rip.color.startsWith("#")
        ? (rip.color === "#c23b2e" ? "rgba(194,59,46," + alpha + ")" : "rgba(255,197,61," + alpha + ")")
        : rip.color;
      ctx.lineWidth = Math.max(1.2, (2.4 - u * 1.6) * p.s);
      ctx.stroke();
      // inner lotus ring
      ctx.beginPath();
      ctx.arc(p.x, p.y + 8 * p.s, rad * 0.55, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255,244,220," + (alpha * 0.7) + ")";
      ctx.lineWidth = Math.max(1, 1.2 * p.s);
      ctx.stroke();
      // bagua ticks
      for (let i = 0; i < 8; i++) {
        const a = (Math.PI * 2 * i) / 8 + u;
        ctx.beginPath();
        ctx.moveTo(p.x + Math.cos(a) * rad * 0.72, p.y + 8 * p.s + Math.sin(a) * rad * 0.72);
        ctx.lineTo(p.x + Math.cos(a) * rad * 0.95, p.y + 8 * p.s + Math.sin(a) * rad * 0.95);
        ctx.strokeStyle = "rgba(255,197,61," + (alpha * 0.85) + ")";
        ctx.lineWidth = 1.4 * p.s;
        ctx.stroke();
      }
    }
    ctx.restore();
  }

  function awardPhi(amount, fromEl) {
    if (amount <= 0) return;
    state.vault += amount;
    updateRelayUI();
    const vaultBtn = $("claimBtn");
    vaultBtn.classList.remove("score-pulse");
    void vaultBtn.offsetWidth;
    vaultBtn.classList.add("score-pulse");
    floatNum(fromEl || vaultBtn, t("phiGain", { n: amount }), "#3dfff3");
    if (SFX.phiGain) SFX.phiGain();
  }

  function grantShine(ball, seconds) {
    if (!ball) return;
    ball.shineLife = Math.max(ball.shineLife || 0, seconds);
    ball.charge = Math.min(3, (ball.charge || 0) + 1);
  }

  function shineAllLive(seconds) {
    WORLD.balls.forEach(b => {
      if (b.state === "flying" || b.state === "pocket") grantShine(b, seconds);
    });
  }

  // Temporary shining echo-thoughts — help for a few seconds, then vanish.
  // They never cascade into more permanent balls.
  function spawnEchoOrbs(originX, count, life) {
    const ttl = life == null ? 3.2 : life;
    let spawned = 0;
    const midY = 240;
    const echoCap = 2;
    const existingEcho = WORLD.balls.filter(b => b.echo && b.state === "flying").length;
    const budget = Math.max(0, echoCap - existingEcho);
    const want = Math.min(count, budget);
    for (let i = 0; i < want; i++) {
      if (WORLD.balls.length >= LAYOUT.maxBalls) break;
      const side = i % 2 === 0 ? -1 : 1;
      // Bias toward wall VOID pockets so the short burst can chase jackpot skillfully.
      const angle = -Math.PI / 2 + side * (0.72 + Math.random() * 0.22);
      const speed = 780 + Math.random() * 160;
      WORLD.balls.push({
        x: Math.max(70, Math.min(350, (originX || LAYOUT.launcherX) + side * 28)),
        y: midY,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        r: LAYOUT.ballR,
        state: "flying",
        enteredField: true,
        trail: [],
        charge: 2,
        portalLock: 0.35,
        flipperHits: 0,
        fromSplit: true,
        echo: true,
        shineLife: ttl,
      });
      spawned++;
    }
    if (spawned) {
      if (SFX.multiball) SFX.multiball();
      burstParticles(originX || LAYOUT.launcherX, midY, 18, "#ffffff");
      flashBanner("banner.multi.code", "banner.multi.title", "banner.multi.sub", "rift");
      mascotSay(t("mascot.echo"), "兔");
      toast(t("lore.echo"));
      CAM.punch = 22;
      CAM.flash = 0.55;
    }
    return spawned;
  }

  function queueMultiball(count) {
    // Kept name for call sites — now queues temporary echoes only.
    state.pendingMultiball = Math.max(state.pendingMultiball, count);
  }

  function releasePendingMultiball(originX) {
    if (!state.pendingMultiball) return;
    const n = state.pendingMultiball;
    state.pendingMultiball = 0;
    spawnEchoOrbs(originX || LAYOUT.launcherX, n, 3.4);
  }

  function updateEchoLives(dt) {
    const jacks = WORLD.pockets.filter(p => p.kind === "jackpot");
    for (const b of WORLD.balls) {
      if (b.state !== "flying") continue;
      if (b.shineLife == null) continue;
      b.shineLife -= dt;
      // Soft pull toward nearest VOID while shining — a short skill window, not free score.
      if (b.shineLife > 0 && jacks.length) {
        let best = jacks[0], bestD = Infinity;
        for (const j of jacks) {
          const d = Math.hypot(b.x - j.cx, (LAYOUT.pocketTop + 20) - b.y);
          if (d < bestD) { bestD = d; best = j; }
        }
        const pull = b.echo ? 210 : 120;
        b.vx += ((best.cx - b.x) / Math.max(40, bestD)) * pull * dt;
        if (b.y > LAYOUT.pocketTop - 120) b.vy -= 40 * dt;
      }
      if (b.echo && b.shineLife <= 0) {
        burstParticles(b.x, b.y, 12, "#ffffff");
        floatNum(canvas, t("lore.echoGone"), "rgba(255,255,255,.85)");
        b.state = "vanished";
      }
    }
    WORLD.balls = WORLD.balls.filter(b => b.state !== "vanished");
  }

  // Legacy name used by ethereal boon — same temporary echoes.
  function spawnSplitBalls(originX, count) {
    return spawnEchoOrbs(originX, count, 3.8);
  }

  function syncCamera() {
    const ball = WORLD.balls.find(b => b.state === "flying" || b.state === "pocket");
    if (PERF_LITE) {
      // Keep mild look-follow for canvas depth only — no DOM style thrash.
      const targetYaw = ball ? ((ball.x / W) - 0.5) * -6 : 0;
      CAM.yaw += (targetYaw - CAM.yaw) * 0.08;
      CAM.punch *= 0.8;
      CAM.shake *= 0.75;
      CAM.aberration *= 0.8;
      CAM.flash *= 0.84;
      CAM.speed = ball ? Math.hypot(ball.vx || 0, ball.vy || 0) : 0;
      const targetLook = ball ? ((ball.y / H) - 0.42) * 14 : 0;
      CAM.look += (targetLook - CAM.look) * 0.1;
      CAM.pitch = 0;
      return;
    }
    const targetYaw = (ball ? ((ball.x / W) - 0.5) * -11 : 0) + CAM.userYaw;
    CAM.yaw += (targetYaw - CAM.yaw) * 0.11;
    CAM.punch *= 0.84;
    CAM.shake *= 0.8;
    CAM.aberration *= 0.88;
    CAM.flash *= 0.86;
    CAM.speed = ball ? Math.hypot(ball.vx || 0, ball.vy || 0) : 0;
    const targetLook = ball ? ((ball.y / H) - 0.42) * 22 : 0;
    CAM.look += (targetLook - CAM.look) * 0.1;
    const pitch = 8 + CAM.userPitch + Math.min(5, CAM.speed / 320) + (state.charging ? state.power * 3 : 0);
    CAM.pitch += (pitch - CAM.pitch) * 0.14;
    CAM.hitLatch = Math.max(0, CAM.hitLatch - 1);
    if (CAM.hitLatch === 0 && WORLD.pegs.some(n => n.lit > 0.9)) {
      CAM.punch = Math.max(CAM.punch, 14 + CAM.speed / 160);
      CAM.shake = Math.max(CAM.shake, 3.2);
      CAM.aberration = Math.max(CAM.aberration, 0.35);
      CAM.hitLatch = 5;
    }
    document.documentElement.style.setProperty("--yaw", (CAM.yaw + (Math.random() - 0.5) * CAM.shake * 0.55) + "deg");
    document.documentElement.style.setProperty("--pitch", CAM.pitch + "deg");
    document.documentElement.style.setProperty("--punch", (CAM.punch + CAM.shake * 3) + "px");
    document.documentElement.style.setProperty("--parallax-x", (-CAM.yaw * 2.2) + "px");
    document.documentElement.style.setProperty("--parallax-y", (CAM.userPitch * 3.2) + "px");
  }

  document.querySelectorAll(".mode").forEach(btn => btn.addEventListener("click", () => {
    state.mode = btn.dataset.mode;
    document.querySelectorAll(".mode").forEach(x => x.classList.toggle("active", x === btn));
    toast(state.mode === "surge" ? t("toast.surge") : t("toast.focus"));
    SFX.click();
    updateRelayUI();
  }));

  function driveFlipper(side, pressed) {
    setFlipper(side, pressed);
    const button = $(side === "left" ? "nudgeLeft" : "nudgeRight");
    button.classList.toggle("pressed", pressed);
    if (pressed) {
      CAM.punch = Math.max(CAM.punch, 5);
      if (SFX.flipper) SFX.flipper();
    }
  }
  function bindFlipper(id, side) {
    const button = $(id);
    button.addEventListener("pointerdown", e => {
      e.preventDefault();
      button.setPointerCapture(e.pointerId);
      driveFlipper(side, true);
    });
    ["pointerup", "pointercancel", "lostpointercapture"].forEach(type =>
      button.addEventListener(type, () => driveFlipper(side, false))
    );
  }
  bindFlipper("nudgeLeft", "left");
  bindFlipper("nudgeRight", "right");

  $("claimBtn").addEventListener("click", () => {
    if (!state.vault) return;
    const receipt = { id: "BC-" + Date.now().toString(36).toUpperCase(), value: state.vault, createdAt: new Date().toISOString(), source: "null-shrine" };
    localStorage.setItem("blazecore_reward_receipt", JSON.stringify(receipt));
    toast(receipt.id + "  +" + state.vault + " Φ");
    state.vault = 0; updateRelayUI();
  });

  function initChallenge() {
    const today = new Date().toDateString();
    let saved = null;
    try { saved = JSON.parse(localStorage.getItem("pp_challenge") || "null"); } catch (e) {}
    if (saved && saved.date === today && saved.id) {
      state.challenge = saved;
      return;
    }
    const pool = [
      { id: "hit", target: 10 },
      { id: "stage", target: 3 },
      { id: "red", target: 5 },
      { id: "streak", target: 6 },
    ];
    const pick = pool[Math.floor(Math.random() * pool.length)];
    const c = { id: pick.id, target: pick.target, date: today, done: 0 };
    state.challenge = c;
    localStorage.setItem("pp_challenge", JSON.stringify(c));
  }

  function updateChallengeUI() {
    document.getElementById("challengeText").textContent = t("challenge." + state.challenge.id);
    document.getElementById("challengeCount").textContent = state.challenge.done + "/" + state.challenge.target;
    document.getElementById("challengeFill").style.width = Math.min(100, state.challenge.done / state.challenge.target * 100) + "%";
  }

  function addChallengeProgress(n) {
    const before = state.challenge.done;
    state.challenge.done = Math.min(state.challenge.target, state.challenge.done + n);
    localStorage.setItem("pp_challenge", JSON.stringify(state.challenge));
    updateChallengeUI();
    if (before < state.challenge.target && state.challenge.done >= state.challenge.target) {
      SFX.fanfare();
      if (!state.challenge.rewarded) {
        state.challenge.rewarded = true;
        awardPhi(12, $("claimBtn"));
        localStorage.setItem("pp_challenge", JSON.stringify(state.challenge));
        toast(t("toast.challengeDone"));
        if (typeof RELICS !== "undefined") {
          RELICS.data.stats.challenges = (RELICS.data.stats.challenges || 0) + 1;
          syncRelicStats();
        }
      }
      mascotSay(t("challenge.done"), "兔");
    }
  }

  function updateHUD() {
    document.getElementById("ticketCount").textContent = state.tickets;
    document.getElementById("jackpotCount").textContent = STATS.jackpots;
    document.getElementById("nearMissCount").textContent = STATS.nearMisses;
    updateRelayUI();
  }

  function addTickets(n) {
    state.tickets += n;
    updateHUD();
    floatNum(document.getElementById("ticketCount"), t("stardustGain", { n }), "#ffc53d");
  }

  function floatNum(refEl, text, color) {
    const r = refEl.getBoundingClientRect();
    const el = document.createElement("div");
    el.className = "float-num";
    el.textContent = text;
    el.style.left = (r.left + r.width / 2) + "px";
    el.style.top = r.top + "px";
    el.style.color = color;
    fxLayer.appendChild(el);
    setTimeout(() => el.remove(), 1000);
  }

  function shakeCabinet() {
    CAM.shake = 8;
    cabinet.classList.remove("shake");
    void cabinet.offsetWidth;
    cabinet.classList.add("shake");
  }

  function mascotSay(text, face) {
    const line = document.getElementById("mascotLine");
    const faceEl = document.getElementById("mascotFace");
    line.textContent = text;
    if (face) {
      faceEl.textContent = face;
      faceEl.classList.add("excited");
      setTimeout(() => faceEl.classList.remove("excited"), 700);
    }
  }

  function playJackpotStage() {
    // Never re-open while the breach screen is already up — that was the stuck loop.
    if (state.busy || stage.classList.contains("show")) return false;
    if (performance.now() < state.stageCooldownUntil) return false;
    state.busy = true;
    SFX.jackpot();
    SFX.cascade();
    shakeCabinet();
    CAM.punch = 42;
    CAM.flash = 1;
    WORLD.timeScale = 0.15;
    setTimeout(() => { WORLD.timeScale = 0.4; }, 400);
    setTimeout(() => { WORLD.timeScale = 1; }, 900);
    stage.classList.add("show", "auto");
    document.getElementById("stageTitle").textContent = t("stage.title");
    const frag = t("stage.frag", { n: state.fragments.length + 1 });
    state.fragments.push(frag);
    addFragmentChip(frag);
    const cx = W / 2, cy = H / 2;
    const colors = ["#ff2d6a", "#3dfff3", "#ffc53d", "#8b5cff"];
    for (let i = 0; i < 4; i++) {
      setTimeout(() => burstParticles(cx + (Math.random() - 0.5) * 200, cy + (Math.random() - 0.5) * 100, 32, colors[i % 4]), i * 160);
    }
    document.getElementById("stageSub").textContent = t("stage.sub");
    mascotSay(t("mascot.breach"), "兔");
    clearTimeout(playJackpotStage._autoClose);
    // Auto ritual: appear, breathe, vanish — no click required.
    playJackpotStage._autoClose = setTimeout(closeStage, 1750);
    return true;
  }

  function closeStage() {
    clearTimeout(playJackpotStage._autoClose);
    if (!stage.classList.contains("show") && !state.busy) return;
    stage.classList.remove("show", "auto");
    state.busy = false;
    WORLD.timeScale = 1;
    state.stageCooldownUntil = performance.now() + 2500;
    updateHUD();
    // Multiball after the breach ritual ends (auto or early dismiss).
    releasePendingMultiball(LAYOUT.launcherX);
  }
  stage.addEventListener("click", closeStage);
  stage.addEventListener("pointerdown", closeStage);
  window.addEventListener("keydown", (e) => {
    if ((e.code === "Escape" || e.code === "Enter" || e.code === "Space") && stage.classList.contains("show")) {
      e.preventDefault();
      closeStage();
    }
  });

  // Peg/bumper → Resonance Anchors (cyber woodblock / pressure crush)
  let lastCrushSay = 0;
  window.onResonanceHit = (node) => {
    const col = node && node.type === "bumper" ? "#ffc53d" : "#c23b2e";
    spawnBaguaRipple(node.x, node.y, col);
    if (SFX.bowlStrike) SFX.bowlStrike();
    const now = performance.now();
    if (Math.random() > 0.16) return;
    const label = node && node.type === "bumper" ? t("lore.anchor") : t("lore.crush");
    floatNum(canvas, label, col);
    if (now - lastCrushSay > 2200 && Math.random() < 0.45) {
      lastCrushSay = now;
      mascotSay(t("mascot.crush"), "兔");
    }
  };

  function addFragmentChip(frag) {
    const chip = document.createElement("span");
    chip.className = "fragment-chip";
    chip.textContent = frag;
    document.getElementById("albumBody").appendChild(chip);
    const empty = document.querySelector("#albumBody .album-empty");
    if (empty) empty.remove();
  }

  function onSettled(ball, pocket) {
    STATS.shots++;
    if (!pocket) {
      STATS.lost++;
      STATS.bestStreak = 0;
      state.chain = 0;
      state.heat = Math.max(4, state.heat - 12);
      $("runState").textContent = "MISS";
      if (state.challenge.id === "streak" && state.challenge.done > 0) {
        state.challenge.done = 0;
        localStorage.setItem("pp_challenge", JSON.stringify(state.challenge));
        updateChallengeUI();
      }
      burstParticles(ball.x, LAYOUT.pocketTop, 5, "#8a7ab5");
      mascotSay(t("mascot.miss"), "兔");
      state.chordHits = 0;
      updateHUD();
      updatePersonaCard();
      syncRelicStats();
      maybeShowSanctuary();
      return;
    }
    STATS.bestStreak++;
    state.chain = Math.min(6, state.chain + 1);
    state.chordHits = Math.min(8, state.chordHits + 1);
    state.heat = Math.min(100, state.heat + (state.mode === "surge" ? 18 : 8));
    const relayGain = Math.round(pocket.reward * state.multiplier * (state.mode === "surge" ? 2 : 1));
    $("runState").textContent = state.chain >= 4 ? "CRITICAL" : "HIT";
    STATS.maxStreak = Math.max(STATS.maxStreak, STATS.bestStreak);
    CAM.punch = pocket.kind === "jackpot" ? 36 : 16;
    CAM.flash = 0.45;

    // Score always lands in the top-left SCORE · VAULT (Φ).
    awardPhi(relayGain, $("claimBtn"));
    if (!state.firstSignal) {
      state.firstSignal = true;
      flashBanner("banner.first.code", "banner.first.title", "banner.first.sub", "rift");
    }

    if (pocket.kind === "jackpot") {
      STATS.jackpots++;
      addTickets(pocket.reward);
      if (state.challenge.id === "stage") addChallengeProgress(1);
      burstParticles(ball.x, LAYOUT.pocketTop + 20, 30, "#ffc53d");
      mascotSay(t("mascot.jackpot"), "兔");
      flashBanner("banner.core.code", "banner.core.title", "banner.core.sub", "hot");
      // Echo orbs can open VOID, but never cascade into more permanent balls.
      if (!ball.echo && playJackpotStage()) {
        queueMultiball(2); // temporary shining echoes after breach fades
      } else if (ball.echo) {
        CAM.punch = 22;
        shineAllLive(1.6);
      } else {
        CAM.punch = 22;
      }
    } else if (pocket.kind === "red") {
      STATS.reds++;
      addTickets(pocket.reward);
      if (state.challenge.id === "red") addChallengeProgress(1);
      if (state.challenge.id === "streak") addChallengeProgress(1);
      SFX.redZone();
      burstParticles(ball.x, LAYOUT.pocketTop + 16, 16, "#ff2d6a");
      floatNum(canvas, t("redGain", { n: relayGain }), "#ff2d6a");
      mascotSay(t("mascot.red"), "兔");
      flashBanner("banner.rift.code", "banner.rift.title", "banner.rift.sub", "hot");
      // No permanent multiball on rift — brief shine on remaining thoughts only.
      if (state.chain >= 4 && !ball.echo) shineAllLive(2.2);
    } else {
      STATS.normals++;
      addTickets(pocket.reward);
      if (state.challenge.id === "hit") addChallengeProgress(1);
      if (state.challenge.id === "streak") addChallengeProgress(1);
      SFX.pocket();
      burstParticles(ball.x, LAYOUT.pocketTop + 12, 8, "#3dfff3");
      if (isNearMiss(ball)) {
        STATS.nearMisses++;
        SFX.nearMiss();
        shakeCabinet();
        CAM.aberration = 1;
        mascotSay(t("mascot.nearMiss"), "兔");
        floatNum(canvas, t("nearMissLabel"), "#ff2d6a");
      }
    }

    if (!state.busy && !ball.echo) {
      if (state.chain === 3) {
        flashBanner("banner.chain3.code", "banner.chain3.title", "banner.chain3.sub", "rift");
        shineAllLive(1.8);
      } else if (state.chain === 6) {
        flashBanner("banner.chain6.code", "banner.chain6.title", "banner.chain6.sub", "hot");
        shineAllLive(2.8);
        // One short echo window — not a permanent swarm.
        spawnEchoOrbs(ball.x, 1, 3.0);
      } else if (state.pendingMultiball) {
        releasePendingMultiball(ball.x);
      }
    }

    if (state.heat >= 100) maybeOfferBoon();
    syncRelicStats();
    updateHUD();
    updatePersonaCard();
    maybeShowSanctuary();
  }

  function updatePersonaCard() {
    const d = personaData();
    if (!d) return;
    const el = document.getElementById("personaBody");
    if (!el) return;
    el.classList.remove("persona-empty");
    el.innerHTML =
      '<div class="persona-name">' + d.name + '</div>' +
      '<div class="persona-desc">' + d.desc + '</div>';
  }

  document.getElementById("shareBtn").addEventListener("click", async () => {
    if (typeof ECMG !== "undefined") {
      const seed = ($("seedValue") && $("seedValue").textContent) || "SEED";
      const card = RELICS.data.cards[0] || ECMG.buildCardFromRun(seed, state.chain, state.vault);
      ECMG.drawSanctuaryCard(card, true);
      return;
    }
    const text = shareText();
    if (!text) { mascotSay(t("mascot.playFirst"), "兔"); return; }
    try {
      if (navigator.share) await navigator.share({ text });
      else {
        await navigator.clipboard.writeText(text);
        mascotSay(t("mascot.copied"), "兔");
      }
    } catch (e) { /* cancel */ }
  });

  function startCharge(e) {
    if (e && e.cancelable) e.preventDefault();
    if (state.busy) return;
    if (state.charging) return;
    SFX.unlock();
    if (typeof BGM !== "undefined") BGM.start();
    SFX.click();
    state.charging = true;
    $("runState").textContent = state.mode === "surge" ? "OVERDRIVE" : "CHARGE";
    const lb = document.getElementById("launchBtn");
    if (lb) lb.classList.add("charging");
    if (ritualVeil) ritualVeil.classList.add("on");
    if (typeof ECMG !== "undefined") ECMG.haptic([8]);
  }

  function releaseLaunch(e) {
    if (!state.charging) return;
    if (e && e.cancelable) e.preventDefault();
    state.charging = false;
    SFX.charge(0);
    const lb = document.getElementById("launchBtn");
    if (lb) lb.classList.remove("charging");
    if (ritualVeil) ritualVeil.classList.remove("on");
    const power = Math.min(Math.max(state.power, 0.12), 1);
    state.power = 0;
    powerFill.style.width = "0%";
    $("powerReadout").textContent = "00%";
    if (state.tickets <= 0) {
      mascotSay(t("mascot.outOfStardust"), "兔");
      maybeShowSanctuary();
      return;
    }
    if (state.mode === "surge" && state.heat >= 92 && Math.random() < .42) {
      state.tickets--;
      state.chain = 0; state.heat = 36; state.chordHits = 0;
      updateHUD(); shakeCabinet(); SFX.nearMiss();
      $("runState").textContent = "PURGE";
      mascotSay(t("mascot.chainLost"), "兔");
      toast(t("toast.chainLost"));
      return;
    }
    state.tickets--;
    updateHUD();
    CAM.punch = 8 + power * 22;
    CAM.flash = 0.35;
    if (launchRipple) {
      launchRipple.classList.remove("burst");
      void launchRipple.offsetWidth;
      launchRipple.classList.add("burst");
    }
    if (typeof ECMG !== "undefined") ECMG.haptic([10, 30, 24]);
    launch(power);
    $("seedValue").textContent = Math.random().toString(16).slice(2, 6).toUpperCase();
    mascotSay(t("mascot.launch", { power: Math.round(power * 100) }), "兔");
  }

  const launchBtn = document.getElementById("launchBtn");
  let chargePointerId = null;

  function isPlayfieldChrome(target) {
    if (!target || !target.closest) return false;
    return !!target.closest(
      "button, a, input, .callout, .score-banner, .side-rail, .nudge-controls, .modal, .stage, .dock, .lang-bar, .console"
    );
  }

  function bindChargeSurface(el, playfield) {
    if (!el) return;
    el.addEventListener("pointerdown", (e) => {
      if (e.button != null && e.button !== 0) return;
      if (playfield && isPlayfieldChrome(e.target)) return;
      if (state.charging) return;
      startCharge(e);
      if (!state.charging) return;
      chargePointerId = e.pointerId;
      try { el.setPointerCapture(e.pointerId); } catch (err) {}
    }, { passive: false });
    el.addEventListener("pointerup", (e) => {
      if (chargePointerId != null && e.pointerId !== chargePointerId) return;
      chargePointerId = null;
      releaseLaunch(e);
    });
    el.addEventListener("pointercancel", (e) => {
      if (chargePointerId != null && e.pointerId !== chargePointerId) return;
      chargePointerId = null;
      releaseLaunch(e);
    });
  }
  bindChargeSurface(launchBtn, false);
  // Hold the canvas — mobile 3D transforms often misalign the console launch seal.
  bindChargeSurface(canvas, true);
  // Fallback if pointer capture is lost mid-gesture (some mobile browsers).
  window.addEventListener("pointerup", (e) => {
    if (!state.charging) return;
    if (chargePointerId != null && e.pointerId !== chargePointerId) return;
    chargePointerId = null;
    releaseLaunch(e);
  });
  window.addEventListener("pointercancel", (e) => {
    if (!state.charging) return;
    if (chargePointerId != null && e.pointerId !== chargePointerId) return;
    chargePointerId = null;
    releaseLaunch(e);
  });

  window.addEventListener("keydown", e => {
    if (e.code === "Space" || e.code === "ArrowUp") { e.preventDefault(); startCharge(e); }
    if (!e.repeat && (e.code === "ArrowLeft" || e.code === "KeyA")) driveFlipper("left", true);
    if (!e.repeat && (e.code === "ArrowRight" || e.code === "KeyD")) driveFlipper("right", true);
  });
  window.addEventListener("keyup", e => {
    if (e.code === "Space" || e.code === "ArrowUp") releaseLaunch(e);
    if (e.code === "ArrowLeft" || e.code === "KeyA") driveFlipper("left", false);
    if (e.code === "ArrowRight" || e.code === "KeyD") driveFlipper("right", false);
  });

  function toScreen(x, y) {
    const t = Math.max(0, Math.min(1, y / H));
    const ease = Math.pow(t, 0.78);
    const s = 0.26 + ease * 0.92;
    const vanishX = W / 2 + CAM.yaw * 2.8;
    return {
      x: vanishX + (x - W / 2) * s,
      y: 40 + ease * (H - 62) - CAM.look * 0.35,
      s,
      t,
      ease
    };
  }

  function drawCorridor() {
    const ceilL = toScreen(LAYOUT.leftWall, 8);
    const ceilR = toScreen(LAYOUT.rightWall, 8);
    const tl = toScreen(LAYOUT.leftWall, 54);
    const tr = toScreen(LAYOUT.rightWall, 54);
    const bl = toScreen(LAYOUT.leftWall, LAYOUT.pocketTop);
    const br = toScreen(LAYOUT.rightWall, LAYOUT.pocketTop);
    const wellL = toScreen(LAYOUT.leftWall, H - 6);
    const wellR = toScreen(LAYOUT.rightWall, H - 6);

    const bg = ctx.createLinearGradient(0, 0, 0, H);
    bg.addColorStop(0, "#2a1038");
    bg.addColorStop(0.22, "#12081c");
    bg.addColorStop(1, "#050208");
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, W, H);

    ctx.beginPath();
    ctx.moveTo(0, 0); ctx.lineTo(W, 0); ctx.lineTo(ceilR.x, ceilR.y); ctx.lineTo(ceilL.x, ceilL.y); ctx.closePath();
    const ceiling = ctx.createLinearGradient(0, 0, 0, tl.y);
    ceiling.addColorStop(0, "#3a1848");
    ceiling.addColorStop(1, "#140818");
    ctx.fillStyle = ceiling;
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(0, 0); ctx.lineTo(tl.x, tl.y); ctx.lineTo(wellL.x, wellL.y); ctx.lineTo(0, H); ctx.closePath();
    const leftWall = ctx.createLinearGradient(0, 0, tl.x + 40, 0);
    leftWall.addColorStop(0, "#1c0a18");
    leftWall.addColorStop(0.7, "rgba(61,255,243,0.14)");
    leftWall.addColorStop(1, "#0a0610");
    ctx.fillStyle = leftWall;
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(W, 0); ctx.lineTo(tr.x, tr.y); ctx.lineTo(wellR.x, wellR.y); ctx.lineTo(W, H); ctx.closePath();
    const rightWall = ctx.createLinearGradient(W, 0, tr.x - 40, 0);
    rightWall.addColorStop(0, "#1a0814");
    rightWall.addColorStop(0.7, "rgba(255,45,106,0.16)");
    rightWall.addColorStop(1, "#0a0610");
    ctx.fillStyle = rightWall;
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(tl.x, tl.y); ctx.lineTo(tr.x, tr.y); ctx.lineTo(br.x, br.y); ctx.lineTo(bl.x, bl.y); ctx.closePath();
    const floor = ctx.createLinearGradient(0, tl.y, 0, br.y);
    floor.addColorStop(0, "#241036");
    floor.addColorStop(0.55, "#12081c");
    floor.addColorStop(1, "#1a0c22");
    ctx.fillStyle = floor;
    ctx.fill();

    // Layered floor light pools anchor mechanisms to the projected plane.
    const floorGlow = ctx.createRadialGradient(W * .5, H * .58, 8, W * .5, H * .58, W * .48);
    floorGlow.addColorStop(0, "rgba(139,92,255,.13)");
    floorGlow.addColorStop(.45, "rgba(61,255,243,.045)");
    floorGlow.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = floorGlow;
    ctx.fillRect(0, 60, W, H - 100);

    ctx.beginPath();
    ctx.moveTo(bl.x, bl.y); ctx.lineTo(br.x, br.y); ctx.lineTo(wellR.x, wellR.y); ctx.lineTo(wellL.x, wellL.y); ctx.closePath();
    ctx.fillStyle = "#0d0714";
    ctx.fill();

    ctx.strokeStyle = "rgba(255,244,234,0.09)";
    ctx.lineWidth = 1;
    for (let i = 1; i < 10; i++) {
      const y = 54 + i * 52;
      const a = toScreen(LAYOUT.leftWall, y);
      const b = toScreen(LAYOUT.rightWall, y);
      ctx.globalAlpha = 0.18 + a.t * 0.45;
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
    }
    ctx.globalAlpha = 1;
    for (let x = 54; x <= 366; x += 44) {
      const a = toScreen(x, 54);
      const b = toScreen(x, LAYOUT.pocketTop);
      ctx.strokeStyle = "rgba(139,92,255,0.12)";
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
    }

    ctx.strokeStyle = "rgba(61,255,243,0.75)";
    ctx.shadowColor = "#3dfff3";
    ctx.shadowBlur = PERF_LITE ? 10 : 18;
    ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(tl.x, tl.y); ctx.lineTo(wellL.x, wellL.y); ctx.stroke();
    ctx.strokeStyle = "rgba(255,45,106,0.7)";
    ctx.shadowColor = "#ff2d6a";
    ctx.beginPath(); ctx.moveTo(tr.x, tr.y); ctx.lineTo(wellR.x, wellR.y); ctx.stroke();
    ctx.shadowBlur = 0;
  }

  function drawMachine() {
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    if (!drawMachine._themeA || (drawMachine._themeTick = (drawMachine._themeTick || 0) + 1) % 30 === 0) {
      drawMachine._themeA = getComputedStyle(document.documentElement).getPropertyValue("--theme-a").trim() || "#3dfff3";
    }
    drawCorridor();

    for (const f of WORLD.fields) {
      if (PERF_LITE && f.active === false) continue;
      const p = toScreen(f.x, f.y);
      const active = f.active !== false;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.scale(1, 0.55);
      ctx.globalAlpha = active ? 0.8 : 0.18;
      ctx.strokeStyle = f.type === "magnet" || f.type === "repulsor" ? "#ff2d6a" : "#3dfff3";
      ctx.lineWidth = 2;
      const step = PERF_LITE ? 16 : 12;
      for (let r = f.r * 0.28 * p.s; r <= f.r * p.s; r += step) {
        ctx.beginPath();
        ctx.arc(0, 0, r, WORLD.time * (f.spin || 1), WORLD.time * (f.spin || 1) + Math.PI * 1.3);
        ctx.stroke();
      }
      ctx.restore();
    }

    for (const r of WORLD.rails) {
      const a = toScreen(r.x1, r.y1), b = toScreen(r.x2, r.y2);
      ctx.strokeStyle = "#ffc53d";
      ctx.shadowColor = "#ffc53d";
      ctx.shadowBlur = PERF_LITE ? 8 : 16;
      ctx.lineWidth = 5 * ((a.s + b.s) / 2);
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
      ctx.shadowBlur = 0;
    }

    for (const f of WORLD.flippers) {
      const endX = f.pivotX + Math.cos(f.angle) * f.length;
      const endY = f.pivotY + Math.sin(f.angle) * f.length;
      const a = toScreen(f.pivotX, f.pivotY);
      const b = toScreen(endX, endY);
      const yang = f.side === "left";
      const color = yang ? "#ffc53d" : "#3dfff3";
      const dx = b.x - a.x, dy = b.y - a.y;
      const len = Math.max(1, Math.hypot(dx, dy));
      const ux = dx / len, uy = dy / len;
      const nx = -uy, ny = ux;
      const deep = yang ? "#6e1a14" : "#0a1c22";
      const tipGlow = yang ? "#fff4e0" : "#e8fffc";
      const mark = yang ? "阳" : "阴";
      const root = 13 * a.s;
      const tip = 5.5 * b.s;
      const lift = 11 * ((a.s + b.s) / 2);
      const bow = (yang ? 1 : -1) * 5.5 * ((a.s + b.s) / 2); // taiji fish bow

      // Sample a ritual blade path (visual only — physics stays on the straight arm).
      const steps = PERF_LITE ? 7 : 10;
      const top = [], bot = [], spine = [];
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const ease = t * t * (3 - 2 * t);
        const cx = a.x + dx * t + nx * Math.sin(t * Math.PI) * bow * 0.35;
        const cy = a.y + dy * t - lift * (1 - ease * 0.55) + ny * Math.sin(t * Math.PI) * bow * 0.35;
        // Fat seal-hub → waisted prayer shaft → pointed relic tip
        const w = (root * (1 - t) + tip * t) * (1 + Math.sin(t * Math.PI) * 0.28) * (t > 0.88 ? (1 - (t - 0.88) / 0.12) : 1);
        const ww = Math.max(1.6 * b.s, w);
        top.push([cx + nx * ww, cy + ny * ww]);
        bot.push([cx - nx * ww, cy - ny * ww]);
        spine.push([cx, cy]);
      }

      ctx.save();
      // Shadow
      ctx.beginPath();
      ctx.ellipse((a.x + b.x) / 2 + 5, (a.y + b.y) / 2 + 12, len * 0.52, 6 + tip * 0.3, Math.atan2(dy, dx), 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0,.62)";
      ctx.fill();

      // Blade body
      ctx.beginPath();
      ctx.moveTo(top[0][0], top[0][1]);
      for (let i = 1; i < top.length; i++) ctx.lineTo(top[i][0], top[i][1]);
      for (let i = bot.length - 1; i >= 0; i--) ctx.lineTo(bot[i][0], bot[i][1]);
      ctx.closePath();
      const body = ctx.createLinearGradient(a.x, a.y, b.x, b.y);
      body.addColorStop(0, tipGlow);
      body.addColorStop(0.18, color);
      body.addColorStop(0.55, deep);
      body.addColorStop(0.82, color);
      body.addColorStop(1, "#050308");
      ctx.fillStyle = body;
      ctx.shadowColor = color;
      ctx.shadowBlur = 8 + f.pulse * (PERF_LITE ? 14 : 26);
      ctx.fill();
      ctx.shadowBlur = 0;
      ctx.strokeStyle = "rgba(255,255,255,.55)";
      ctx.lineWidth = 1.1;
      ctx.stroke();

      // Inlaid rune path along spine
      ctx.beginPath();
      ctx.moveTo(spine[1][0], spine[1][1]);
      for (let i = 2; i < spine.length - 1; i++) ctx.lineTo(spine[i][0], spine[i][1]);
      ctx.strokeStyle = color;
      ctx.globalAlpha = 0.75;
      ctx.lineWidth = Math.max(1.2, 1.8 * a.s);
      ctx.stroke();
      ctx.globalAlpha = 1;
      ctx.font = "600 " + Math.max(7, 8 * a.s) + "px serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      const runes = yang ? ["日", "升", "镇"] : ["月", "敛", "守"];
      for (let i = 0; i < runes.length; i++) {
        const t = 0.28 + i * 0.18;
        const ix = Math.min(steps - 1, Math.floor(t * steps));
        const p0 = spine[ix], p1 = spine[ix + 1] || p0;
        const px = (p0[0] + p1[0]) / 2 + nx * (yang ? -1 : 1) * 7 * a.s;
        const py = (p0[1] + p1[1]) / 2 + ny * (yang ? -1 : 1) * 7 * a.s;
        ctx.fillStyle = tipGlow;
        ctx.globalAlpha = 0.7 + f.pulse * 0.25;
        ctx.fillText(runes[i], px, py);
      }
      ctx.globalAlpha = 1;

      // Sacred rings on the shaft
      for (let i = 0; i < 3; i++) {
        const t = 0.22 + i * 0.2;
        const ix = Math.min(steps - 1, Math.floor(t * steps));
        const p = spine[ix];
        const rw = (root * (1 - t) + tip * t) * 1.05;
        ctx.beginPath();
        ctx.ellipse(p[0], p[1], rw * 0.95, rw * 0.28, Math.atan2(dy, dx), 0, Math.PI * 2);
        ctx.strokeStyle = color;
        ctx.globalAlpha = 0.55 + f.pulse * 0.35;
        ctx.lineWidth = Math.max(1, 1.4 * a.s);
        ctx.stroke();
      }
      ctx.globalAlpha = 1;

      // Relic tip crystal
      const tipP = spine[spine.length - 1];
      const tipPrev = spine[spine.length - 2] || tipP;
      const tdx = tipP[0] - tipPrev[0], tdy = tipP[1] - tipPrev[1];
      const tl = Math.max(1, Math.hypot(tdx, tdy));
      const crystal = ctx.createRadialGradient(tipP[0], tipP[1], 1, tipP[0], tipP[1], 10 * b.s);
      crystal.addColorStop(0, "#ffffff");
      crystal.addColorStop(0.35, tipGlow);
      crystal.addColorStop(1, color);
      ctx.beginPath();
      ctx.moveTo(tipP[0] + (tdx / tl) * 8 * b.s, tipP[1] + (tdy / tl) * 8 * b.s);
      ctx.lineTo(tipP[0] + nx * 5 * b.s, tipP[1] + ny * 5 * b.s);
      ctx.lineTo(tipP[0] - nx * 5 * b.s, tipP[1] - ny * 5 * b.s);
      ctx.closePath();
      ctx.fillStyle = crystal;
      ctx.shadowColor = color;
      ctx.shadowBlur = 12 + f.pulse * 18;
      ctx.fill();
      ctx.shadowBlur = 0;

      // Hub = mini taiji seal
      const hx = a.x, hy = a.y - lift * 0.15;
      ctx.beginPath();
      ctx.arc(hx, hy, root * 0.95, 0, Math.PI * 2);
      const hub = ctx.createRadialGradient(hx - 4, hy - 4, 1, hx, hy, root);
      if (yang) {
        hub.addColorStop(0, "#fff8e7");
        hub.addColorStop(0.35, color);
        hub.addColorStop(0.7, "#6e1a14");
        hub.addColorStop(1, "#12080c");
      } else {
        hub.addColorStop(0, "#e8fffc");
        hub.addColorStop(0.35, color);
        hub.addColorStop(0.7, "#0a1c22");
        hub.addColorStop(1, "#04080c");
      }
      ctx.fillStyle = hub;
      ctx.fill();
      ctx.strokeStyle = color;
      ctx.lineWidth = 2.2;
      ctx.stroke();
      // S-curve suggestion on hub
      ctx.beginPath();
      ctx.arc(hx, hy, root * 0.55, yang ? -0.2 : Math.PI - 0.2, yang ? Math.PI - 0.2 : Math.PI * 2 - 0.2);
      ctx.strokeStyle = tipGlow;
      ctx.globalAlpha = 0.55;
      ctx.lineWidth = 1.6;
      ctx.stroke();
      ctx.globalAlpha = 1;
      // Fish eye
      ctx.beginPath();
      ctx.arc(hx + (yang ? 3 : -3), hy - 2, root * 0.2, 0, Math.PI * 2);
      ctx.fillStyle = yang ? "#0a0608" : "#f6efd8";
      ctx.fill();
      // God mark
      ctx.fillStyle = tipGlow;
      ctx.font = "700 " + Math.max(9, 11 * a.s) + "px serif";
      ctx.globalAlpha = 0.9;
      ctx.fillText(mark, hx, hy + root * 0.12);
      ctx.globalAlpha = 1;

      // Tiny ofuda near hub
      const ox = hx - ux * root * 0.2 + nx * (yang ? -1 : 1) * root * 1.15;
      const oy = hy - uy * root * 0.2 + ny * (yang ? -1 : 1) * root * 1.15;
      ctx.fillStyle = "rgba(242,228,201,.9)";
      ctx.fillRect(ox - 3.5 * a.s, oy - 7 * a.s, 7 * a.s, 14 * a.s);
      ctx.strokeStyle = yang ? "#c23b2e" : "#2a9d95";
      ctx.lineWidth = 1;
      ctx.strokeRect(ox - 3.5 * a.s, oy - 7 * a.s, 7 * a.s, 14 * a.s);
      ctx.fillStyle = yang ? "#c23b2e" : "#176860";
      ctx.font = Math.max(6, 7 * a.s) + "px serif";
      ctx.fillText(yang ? "阳" : "阴", ox, oy + 2 * a.s);

      ctx.restore();
    }

    for (const portal of WORLD.portals) {
      const p = toScreen(portal.x, portal.y);
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(WORLD.time * 0.9 + portal.phase);
      ctx.strokeStyle = "#8b5cff";
      ctx.shadowColor = "#8b5cff";
      ctx.shadowBlur = 18;
      ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.ellipse(0, 0, 16 * p.s, 7 * p.s, 0, 0, Math.PI * 2); ctx.stroke();
      ctx.beginPath(); ctx.ellipse(0, 0, 7 * p.s, 16 * p.s, 0, 0, Math.PI * 2); ctx.stroke();
      ctx.restore();
      ctx.shadowBlur = 0;
    }

    for (const pocket of WORLD.pockets) {
      const a = toScreen(pocket.x0 + 2, LAYOUT.pocketTop);
      const b = toScreen(pocket.x0 + pocket.w - 2, LAYOUT.pocketTop + LAYOUT.pocketH);
      const color = pocket.kind === "jackpot" ? "#3dfff3" : pocket.kind === "red" ? "#ff2d6a" : "#6c5a7c";
      ctx.fillStyle = "rgba(0,0,0,0.72)";
      ctx.beginPath();
      ctx.moveTo(a.x, a.y);
      ctx.lineTo(b.x, a.y);
      ctx.lineTo(b.x + (b.x - a.x) * 0.04, b.y);
      ctx.lineTo(a.x - (b.x - a.x) * 0.04, b.y);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = color;
      ctx.shadowColor = color;
      ctx.shadowBlur = pocket.kind === "jackpot" ? 22 : 8;
      ctx.stroke();
      ctx.shadowBlur = 0;
      if (pocket.kind === "jackpot" && Math.floor(performance.now() / 320) % 2 === 0) {
        ctx.fillStyle = "rgba(255,197,61,0.2)";
        ctx.fill();
      }
      ctx.fillStyle = color;
      ctx.font = "700 " + Math.round(11 * a.s) + "px Syne, sans-serif";
      ctx.textAlign = "center";
      const label = pocket.kind === "jackpot" ? "VOID" : pocket.kind === "red" ? "RIFT" : pocket.kind === "normal" ? "NULL" : "";
      if (label) ctx.fillText(label, (a.x + b.x) / 2, a.y + (b.y - a.y) * 0.62);
    }

    const launcher = toScreen(LAYOUT.launcherX, LAYOUT.launcherY);
    ctx.save();
    ctx.translate(launcher.x, launcher.y + 8 * launcher.s);
    ctx.scale(1, 0.4);
    ctx.beginPath();
    ctx.arc(0, 0, 24 * launcher.s, 0, Math.PI * 2);
    ctx.fillStyle = "rgba(0,0,0,0.58)";
    ctx.fill();
    ctx.strokeStyle = state.charging ? "#ff2d6a" : "#3dfff3";
    ctx.lineWidth = 3.5;
    ctx.shadowColor = ctx.strokeStyle;
    ctx.shadowBlur = 18;
    ctx.stroke();
    ctx.restore();
    if (state.charging) {
      ctx.strokeStyle = "rgba(255,197,61,0.9)";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(launcher.x, launcher.y, (16 + state.power * 22) * launcher.s, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * state.power);
      ctx.stroke();
    }

    const sprites = WORLD.pegs.map(n => ({ kind: "peg", y: n.y, n }));
    for (const b of WORLD.balls) sprites.push({ kind: "ball", y: b.y, b });
    sprites.sort((a, b) => {
      const ay = a.kind === "peg" ? a.y + (a.n.r * 2.2) : a.y + 5;
      const by = b.kind === "peg" ? b.y + (b.n.r * 2.2) : b.y + 5;
      return ay - by;
    });

    function drawPeg(n) {
      const p = toScreen(n.x, n.y);
      const accent = n.type === "switch"
        ? (n.armed ? "#3dfff3" : "#c23b2e")
        : n.type === "gate" ? "#e2b45a"
        : n.type === "bumper" ? "#f0c3a0"
        : "#d7c7ff";
      const lacquer = n.type === "bumper" ? "#6e1a14" : n.type === "gate" ? "#3a2212" : "#2a1410";
      const bounce = 1 + n.lit * 0.28;
      const r = (n.r * 1.58 + n.lit * 2.4) * p.s * bounce;
      const h = r * (n.type === "bumper" ? 2.9 : n.type === "switch" ? 2.4 : 2.05);
      const baseY = p.y + h * 0.24;
      const topY = baseY - h;
      const bodyW = r * 1.55;

      ctx.save();
      ctx.filter = (!PERF_LITE && p.t < .24) ? "blur(.45px)" : "none";

      // Shadow
      ctx.beginPath();
      ctx.ellipse(p.x + 5 * p.s, baseY + 5 * p.s, r * 2.1, r * 0.52, 0, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0," + (0.36 + p.t * 0.34) + ")";
      ctx.fill();

      // Stone pedestal
      ctx.beginPath();
      ctx.ellipse(p.x, baseY, r * 1.7, r * 0.58, 0, 0, Math.PI * 2);
      const stone = ctx.createLinearGradient(p.x - r * 1.7, baseY, p.x + r * 1.7, baseY);
      stone.addColorStop(0, "#1a1210");
      stone.addColorStop(0.35, "#5a4a3c");
      stone.addColorStop(0.55, "#c9b08a");
      stone.addColorStop(1, "#1a1210");
      ctx.fillStyle = stone;
      ctx.fill();
      ctx.strokeStyle = "rgba(242,228,201,.28)";
      ctx.lineWidth = Math.max(1, 1.1 * p.s);
      ctx.stroke();

      // Lacquer column body
      const bodyGrad = ctx.createLinearGradient(p.x - bodyW, topY, p.x + bodyW, baseY);
      bodyGrad.addColorStop(0, "#140808");
      bodyGrad.addColorStop(0.22, lacquer);
      bodyGrad.addColorStop(0.48, accent);
      bodyGrad.addColorStop(0.72, "#fff0d2");
      bodyGrad.addColorStop(1, "#0c0606");
      ctx.beginPath();
      ctx.moveTo(p.x - bodyW / 2, topY + r * 0.2);
      ctx.bezierCurveTo(p.x - bodyW * 0.58, topY + h * 0.25, p.x - bodyW * 0.55, baseY - h * 0.2, p.x - bodyW * 0.48, baseY);
      ctx.lineTo(p.x + bodyW * 0.48, baseY);
      ctx.bezierCurveTo(p.x + bodyW * 0.55, baseY - h * 0.2, p.x + bodyW * 0.58, topY + h * 0.25, p.x + bodyW / 2, topY + r * 0.2);
      ctx.closePath();
      ctx.fillStyle = bodyGrad;
      ctx.fill();

      // Gold / vermillion sacred rings
      for (let i = 0; i < 2; i++) {
        const yy = topY + h * (0.38 + i * 0.22);
        ctx.beginPath();
        ctx.ellipse(p.x, yy, bodyW * 0.52, r * 0.22, 0, 0, Math.PI * 2);
        ctx.strokeStyle = n.lit > 0.15 ? accent : "rgba(226,180,90,.45)";
        ctx.lineWidth = r * 0.14;
        ctx.shadowColor = accent;
        ctx.shadowBlur = n.lit * 16;
        ctx.stroke();
        ctx.shadowBlur = 0;
      }

      // Torii-like cap / lantern top
      ctx.beginPath();
      ctx.moveTo(p.x - bodyW * 0.72, topY + r * 0.18);
      ctx.lineTo(p.x + bodyW * 0.72, topY + r * 0.18);
      ctx.lineWidth = Math.max(2, 2.4 * p.s);
      ctx.strokeStyle = "#c23b2e";
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(p.x - bodyW * 0.58, topY + r * 0.02);
      ctx.lineTo(p.x + bodyW * 0.58, topY + r * 0.02);
      ctx.lineWidth = Math.max(1.5, 1.8 * p.s);
      ctx.strokeStyle = "#e2b45a";
      ctx.stroke();

      // Glowing washi cap + breathing cyber relic crystal
      const breath = 1 + Math.sin(WORLD.time * 3.2 + n.x * 0.05) * 0.08;
      const cap = ctx.createRadialGradient(p.x - r * 0.35, topY - r * 0.1, r * 0.05, p.x, topY, r * 1.1);
      cap.addColorStop(0, "#ffffff");
      cap.addColorStop(0.2, accent);
      cap.addColorStop(0.7, lacquer);
      cap.addColorStop(1, "#0a0505");
      ctx.beginPath();
      ctx.ellipse(p.x, topY, bodyW * 0.5, r * 0.4, 0, 0, Math.PI * 2);
      ctx.fillStyle = cap;
      ctx.fill();

      // Relic crystal (赛博舍利)
      const cr = r * 0.42 * breath;
      const crystal = ctx.createRadialGradient(p.x - cr * 0.3, topY - cr * 1.1, cr * 0.1, p.x, topY - cr * 0.55, cr * 1.4);
      crystal.addColorStop(0, "#ffffff");
      crystal.addColorStop(0.25, n.lit > 0.3 ? "#ffe29a" : accent);
      crystal.addColorStop(0.7, lacquer);
      crystal.addColorStop(1, "rgba(0,0,0,0)");
      ctx.beginPath();
      ctx.moveTo(p.x, topY - cr * 1.55);
      ctx.lineTo(p.x + cr * 0.7, topY - cr * 0.35);
      ctx.lineTo(p.x, topY + cr * 0.15);
      ctx.lineTo(p.x - cr * 0.7, topY - cr * 0.35);
      ctx.closePath();
      ctx.fillStyle = crystal;
      ctx.shadowColor = accent;
      ctx.shadowBlur = 8 + n.lit * 28;
      ctx.fill();
      ctx.shadowBlur = 0;

      // Slow rotating rune orbit
      const runes = ["咒", "灵", "镇", "煞", "空", "念"];
      ctx.save();
      ctx.font = "600 " + Math.max(7, 8.5 * p.s) + "px serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      for (let i = 0; i < runes.length; i++) {
        const ang = WORLD.time * 0.7 + (Math.PI * 2 * i) / runes.length + n.x * 0.01;
        const rr = bodyW * 0.78;
        const rx = p.x + Math.cos(ang) * rr;
        const ry = topY + h * 0.42 + Math.sin(ang) * r * 0.55;
        ctx.fillStyle = n.lit > 0.2
          ? "rgba(255,244,210," + (0.55 + n.lit * 0.4) + ")"
          : "rgba(226,180,90,.45)";
        ctx.fillText(runes[i], rx, ry);
      }
      ctx.restore();

      if (n.type === "gate") {
        // Mini ofuda strip
        ctx.fillStyle = "rgba(242,228,201,.88)";
        ctx.fillRect(p.x - 5 * p.s, topY + r * 0.35, 10 * p.s, 18 * p.s);
        ctx.strokeStyle = "#c23b2e";
        ctx.lineWidth = 1;
        ctx.strokeRect(p.x - 5 * p.s, topY + r * 0.35, 10 * p.s, 18 * p.s);
        ctx.fillStyle = "#c23b2e";
        ctx.font = (7 * p.s) + "px serif";
        ctx.textAlign = "center";
        ctx.fillText("示", p.x, topY + r * 0.35 + 12 * p.s);
      }
      if (n.type === "switch") {
        ctx.strokeStyle = n.armed ? "#3dfff3" : "#c23b2e";
        ctx.lineWidth = 2 * p.s;
        ctx.strokeRect(p.x - r * 0.42, topY - r * 0.35, r * 0.84, r * 0.84);
        ctx.beginPath();
        ctx.arc(p.x, topY, r * 0.18, 0, Math.PI * 2);
        ctx.fillStyle = n.armed ? "#3dfff3" : "#c23b2e";
        ctx.fill();
      }
      if (n.lit > 0.45) {
        ctx.fillStyle = "rgba(255,197,61," + (0.12 + n.lit * 0.18) + ")";
        ctx.beginPath();
        ctx.arc(p.x, topY - r * 0.1, r * (1.6 + n.lit), 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }

    function drawLumen(ball, idle) {
      const p = toScreen(ball.x, ball.y);
      const charged = (ball.charge || 0) > 0;
      const shining = (ball.shineLife || 0) > 0 || ball.echo;
      const orb = typeof RELICS !== "undefined" ? RELICS.orb() : null;
      const themeA = drawMachine._themeA || "#3dfff3";
      // Stardust thought-relic: yang-gold when charged, yin-cyan when calm, vermillion when raw.
      let hot = charged ? "#ffc53d" : (shining ? "#3dfff3" : "#c23b2e");
      if (orb && orb.id === "orb_null") hot = "#6b4cff";
      if (orb && orb.id === "orb_aurora") hot = themeA || "#3dfff3";
      if (orb && orb.id === "orb_bowl") hot = "#e2b45a";
      const r = ball.r * p.s * (idle ? 1.7 : 1.9);

      const breath = 1 + Math.sin(WORLD.time * 4 + (ball.x || 0) * 0.02) * 0.04;

      // Ground shadow
      ctx.beginPath();
      ctx.ellipse(p.x + 2, p.y + r * 1.25, r * 1.7, r * 0.4, 0, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0," + (idle ? 0.32 : 0.55) + ")";
      ctx.fill();

      // Incense / stardust trail
      if (!idle && ball.trail && ball.trail.length > 1) {
        ctx.save();
        ctx.globalCompositeOperation = "lighter";
        ctx.lineCap = "round";
        for (let i = 1; i < ball.trail.length; i++) {
          const a = toScreen(ball.trail[i - 1].x, ball.trail[i - 1].y);
          const c = toScreen(ball.trail[i].x, ball.trail[i].y);
          const u = i / ball.trail.length;
          ctx.strokeStyle = charged
            ? "rgba(255,197,61," + (u * 0.55) + ")"
            : "rgba(194,59,46," + (u * 0.5) + ")";
          ctx.lineWidth = (1.5 + u * 9) * c.s;
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(c.x, c.y); ctx.stroke();
          ctx.strokeStyle = "rgba(255,244,220," + (u * 0.7) + ")";
          ctx.lineWidth = (0.7 + u * 4) * c.s;
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(c.x, c.y); ctx.stroke();
        }
        ctx.restore();
      }

      if (CAM.aberration > 0.08 && !idle) {
        ctx.save();
        ctx.globalCompositeOperation = "screen";
        ctx.fillStyle = "rgba(194,59,46,0.7)";
        ctx.beginPath(); ctx.arc(p.x - 4 * CAM.aberration, p.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = "rgba(61,255,243,0.7)";
        ctx.beginPath(); ctx.arc(p.x + 4 * CAM.aberration, p.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
      }

      ctx.save();
      ctx.shadowColor = hot;
      ctx.shadowBlur = idle ? 16 : 26 + Math.min(22, CAM.speed / 70);

      // Outer washi seal ring
      ctx.beginPath();
      ctx.arc(p.x, p.y, r * 1.12 * breath, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(242,228,201," + (0.35 + (shining ? 0.25 : 0)) + ")";
      ctx.lineWidth = Math.max(1, 1.3 * p.s);
      ctx.stroke();

      // Core orb — frosted relic
      const g = ctx.createRadialGradient(p.x - r * 0.35, p.y - r * 0.4, r * 0.08, p.x, p.y + r * 0.1, r);
      g.addColorStop(0, "#ffffff");
      g.addColorStop(0.2, charged ? "#ffe29a" : "#f6e8c8");
      g.addColorStop(0.48, hot);
      g.addColorStop(0.78, charged ? "#6e1a14" : "#1a100e");
      g.addColorStop(1, "#050308");
      ctx.beginPath();
      ctx.arc(p.x, p.y, r * breath, 0, Math.PI * 2);
      ctx.fillStyle = g;
      ctx.fill();
      ctx.shadowBlur = 0;

      // Mini taiji swirl (阳金 / 阴青)
      ctx.beginPath();
      ctx.arc(p.x, p.y, r * 0.62, -Math.PI / 2, Math.PI / 2);
      ctx.strokeStyle = "rgba(255,197,61,.55)";
      ctx.lineWidth = Math.max(1.2, 1.6 * p.s);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(p.x, p.y, r * 0.62, Math.PI / 2, Math.PI * 1.5);
      ctx.strokeStyle = "rgba(61,255,243,.5)";
      ctx.lineWidth = Math.max(1.2, 1.6 * p.s);
      ctx.stroke();
      // Fish eyes
      ctx.beginPath();
      ctx.arc(p.x, p.y - r * 0.32, r * 0.12, 0, Math.PI * 2);
      ctx.fillStyle = "#0a0608";
      ctx.fill();
      ctx.beginPath();
      ctx.arc(p.x, p.y + r * 0.32, r * 0.12, 0, Math.PI * 2);
      ctx.fillStyle = "#f6efd8";
      ctx.fill();

      // Center seal character
      ctx.fillStyle = "rgba(255,244,220,.85)";
      ctx.font = "700 " + Math.max(7, r * 0.55) + "px serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(ball.echo ? "回" : (charged ? "灵" : "念"), p.x, p.y + 0.5);

      if (shining) {
        const pulse = 0.55 + 0.45 * Math.sin(performance.now() / 90);
        ctx.beginPath();
        ctx.arc(p.x, p.y, r * (1.35 + pulse * 0.2), 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(255,255,255," + (0.3 + pulse * 0.35) + ")";
        ctx.lineWidth = 2 * p.s;
        ctx.shadowColor = "#ffffff";
        ctx.shadowBlur = 14 + pulse * 14;
        ctx.stroke();
        ctx.shadowBlur = 0;
        // Bagua ticks
        for (let i = 0; i < 8; i++) {
          const ang = (Math.PI * 2 * i) / 8 + WORLD.time;
          ctx.beginPath();
          ctx.moveTo(p.x + Math.cos(ang) * r * 1.2, p.y + Math.sin(ang) * r * 1.2);
          ctx.lineTo(p.x + Math.cos(ang) * r * 1.45, p.y + Math.sin(ang) * r * 1.45);
          ctx.strokeStyle = "rgba(255,197,61," + (0.35 + pulse * 0.25) + ")";
          ctx.lineWidth = 1.2 * p.s;
          ctx.stroke();
        }
      }

      ctx.restore();
    }

    // One painter's-order pass: balls can pass behind foreground mechanisms.
    for (const sprite of sprites) {
      if (sprite.kind === "peg") {
        drawPeg(sprite.n);
      } else {
        sprite.b.trail.push({ x: sprite.b.x, y: sprite.b.y });
        if (sprite.b.trail.length > (PERF_LITE ? 12 : 22)) sprite.b.trail.shift();
        drawLumen(sprite.b, false);
      }
    }
    drawRipples();

    const flying = WORLD.balls.some(b => b.state === "flying" || b.state === "pocket");
    if (!flying) {
      const bob = Math.sin(WORLD.time * 3.2) * 3;
      drawLumen({
        x: LAYOUT.launcherX,
        y: LAYOUT.launcherY - 6 + bob,
        r: LAYOUT.ballR * (1 + state.power * 0.35),
        charge: 0,
        trail: []
      }, true);
    }

    if (CAM.speed > 720) {
      ctx.strokeStyle = "rgba(255,244,234,0.12)";
      ctx.lineWidth = 1;
      for (let i = 0; i < (PERF_LITE ? 6 : 10); i++) {
        const y = (WORLD.time * 420 + i * 70) % H;
        const a = toScreen(40 + (i % 3) * 120, y);
        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(a.x, a.y + 18); ctx.stroke();
      }
    }

    for (const p of WORLD.particles) {
      const s = toScreen(p.x, p.y);
      ctx.globalAlpha = Math.max(0, p.life / p.maxLife);
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(s.x, s.y, p.size * s.s, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    if (CAM.flash > 0.02) {
      ctx.fillStyle = "rgba(255,244,234," + (CAM.flash * 0.22) + ")";
      ctx.fillRect(0, 0, W, H);
    }
    if (WORLD.comboFlash > 0) {
      ctx.fillStyle = "rgba(255,45,106," + (WORLD.comboFlash * 0.18) + ")";
      ctx.fillRect(0, 0, W, H);
    }

    // Optical vignette and glass reflection unify the virtual depth with the cabinet.
    const vignette = ctx.createRadialGradient(W/2,H*.48,H*.16,W/2,H*.48,H*.73);
    vignette.addColorStop(.45,"rgba(0,0,0,0)");vignette.addColorStop(1,"rgba(0,0,0,.55)");
    ctx.fillStyle=vignette;ctx.fillRect(0,0,W,H);
    const sheen=ctx.createLinearGradient(0,0,W,H*.7);sheen.addColorStop(0,"rgba(255,255,255,.09)");sheen.addColorStop(.17,"rgba(255,255,255,0)");sheen.addColorStop(.78,"rgba(61,255,243,.025)");sheen.addColorStop(1,"rgba(255,255,255,0)");
    ctx.fillStyle=sheen;ctx.fillRect(0,0,W,H);
  }

  let last = performance.now(), lastFlipperPulse = 0;
  function loop(now) {
    const dt = Math.min((now - last) / 1000, 0.033);
    last = now;
    if (state.charging && !state.busy) {
      state.power = Math.min(1, state.power + dt * 1.4);
      powerFill.style.width = (state.power * 100) + "%";
      $("powerReadout").textContent = String(Math.round(state.power * 100)).padStart(2, "0") + "%";
      SFX.charge(state.power);
    } else {
      SFX.charge(0);
    }
    updatePhysics(state.busy ? 0 : dt);
    if (!state.busy) {
      updateEchoLives(dt);
      updateRipples(dt);
      applySigilPhysics();
      checkGateWave();
    }
    if (WORLD.flipperPulse > lastFlipperPulse) {
      const ball = WORLD.balls.find(b => b.state === "flying");
      const rally = ball ? ball.flipperHits || 0 : 0;
      if (rally > 0) {
        $("runState").textContent = rally >= 5 ? "RALLY ×" + rally : "SAVE " + rally;
        CAM.punch = Math.max(CAM.punch, 18);
        CAM.shake = Math.max(CAM.shake, 4);
        CAM.flash = Math.max(CAM.flash, .22);
      }
    }
    lastFlipperPulse = WORLD.flipperPulse;
    if (!state.charging && WORLD.balls.length === 0) {
      state.heat = Math.max(4, state.heat - dt * (state.mode === "focus" ? 2.4 : 0.7));
      if (state.heat < 88) state.boonOffered = false;
      if (Math.floor(now / 250) !== Math.floor((now - dt * 1000) / 250)) updateRelayUI();
    }
    if (!state.busy) settleBalls(onSettled);
    updateParticles(dt);
    syncCamera();
    try { drawMachine(); } catch (err) { window.__lastRenderError = String(err && err.stack || err); console.error(err); }
    requestAnimationFrame(loop);
  }

  window.onLangChange = () => {
    updateChallengeUI();
    updateHUD();
    updatePersonaCard();
    const empty = document.getElementById("personaBody");
    if (empty && empty.classList.contains("persona-empty")) {
      empty.textContent = t("persona.empty");
    }
    if ($("runState") && $("runState").textContent === "WAITING") {
      $("runState").textContent = t("ui.waiting");
    }
    mascotSay(t("mascot.hello"), "兔");
  };

  initChallenge();
  updateChallengeUI();
  updateHUD();
  if (typeof ECMG !== "undefined") ECMG.bindChrome();
  mascotSay(t("mascot.boot"), "兔");
  loop(performance.now());
})();

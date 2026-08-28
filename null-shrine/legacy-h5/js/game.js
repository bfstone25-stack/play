/* NULL//SHRINE — 2.5D cabinet, camera punch, impact-first presentation */
(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const W = LAYOUT.width, H = LAYOUT.height;
  const DPR = Math.min(2, window.devicePixelRatio || 1);
  canvas.width = W * DPR;
  canvas.height = H * DPR;
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);

  const $ = id => document.getElementById(id);
  const cabinet = document.getElementById("cabinet");
  const powerFill = document.getElementById("powerFill");
  const fxLayer = document.getElementById("fxLayer");
  const stage = document.getElementById("stage");
  const heatFill = document.getElementById("heatFill");

  const CAM = {
    yaw: 0, pitch: 8, punch: 0, shake: 0, aberration: 0, flash: 0,
    speed: 0, look: 0, userYaw: 0, userPitch: 0, hitLatch: 0
  };

  function aimCamera(clientX, clientY) {
    CAM.userYaw = ((clientX / innerWidth) - 0.5) * 7;
    CAM.userPitch = ((clientY / innerHeight) - 0.5) * -3;
  }
  window.addEventListener("pointermove", e => aimCamera(e.clientX, e.clientY), { passive: true });
  window.addEventListener("pointerleave", () => { CAM.userYaw = 0; CAM.userPitch = 0; });

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
  };

  const toast = (message) => {
    const el = $("toast");
    el.textContent = message; el.classList.add("show");
    clearTimeout(toast.timer); toast.timer = setTimeout(() => el.classList.remove("show"), 1800);
  };

  function updateRelayUI() {
    state.multiplier = Math.min(4, 1 + Math.floor(state.chain / 2) * .5);
    $("multiplierValue").textContent = state.multiplier.toFixed(1);
    $("heatValue").textContent = String(Math.round(state.heat)).padStart(2, "0");
    $("vaultValue").textContent = state.vault;
    $("chainLabel").textContent = String(state.chain);
    document.querySelectorAll("#chainTrack i").forEach((el, i) => el.classList.toggle("on", i < state.chain));
    $("claimBtn").disabled = state.vault <= 0;
    if (heatFill) heatFill.style.height = Math.max(8, state.heat) + "%";
    document.documentElement.style.setProperty("--heat", String(state.heat / 100));
    document.documentElement.style.setProperty("--overdrive", state.mode === "surge" ? "1" : "0");
  }

  function syncCamera() {
    const ball = WORLD.balls.find(b => b.state === "flying" || b.state === "pocket");
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
    toast(state.mode === "surge" ? "OVERDRIVE" : "FOCUS");
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
        state.vault += 12;
        localStorage.setItem("pp_challenge", JSON.stringify(state.challenge));
        updateRelayUI();
        toast("+12 Φ");
      }
      mascotSay(t("challenge.done"), "◇");
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
    state.busy = true;
    SFX.jackpot();
    SFX.cascade();
    shakeCabinet();
    CAM.punch = 42;
    CAM.flash = 1;
    WORLD.timeScale = 0.15;
    setTimeout(() => { WORLD.timeScale = 0.4; }, 400);
    setTimeout(() => { WORLD.timeScale = 1; }, 900);
    stage.classList.add("show");
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
  }

  function closeStage() {
    stage.classList.remove("show");
    state.busy = false;
    updateHUD();
  }
  stage.addEventListener("click", closeStage);

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
      mascotSay(t("mascot.miss"), "◇");
      updateHUD();
      updatePersonaCard();
      return;
    }
    STATS.bestStreak++;
    state.chain = Math.min(6, state.chain + 1);
    state.heat = Math.min(100, state.heat + (state.mode === "surge" ? 18 : 8));
    const relayGain = Math.round(pocket.reward * state.multiplier * (state.mode === "surge" ? 2 : 1));
    state.vault += relayGain;
    $("runState").textContent = state.chain >= 4 ? "CRITICAL" : "HIT";
    STATS.maxStreak = Math.max(STATS.maxStreak, STATS.bestStreak);
    CAM.punch = pocket.kind === "jackpot" ? 36 : 16;
    CAM.flash = 0.45;

    if (pocket.kind === "jackpot") {
      STATS.jackpots++;
      addTickets(pocket.reward);
      if (state.challenge.id === "stage") addChallengeProgress(1);
      burstParticles(ball.x, LAYOUT.pocketTop + 20, 30, "#ffc53d");
      mascotSay(t("mascot.jackpot"), "◇");
      playJackpotStage();
    } else if (pocket.kind === "red") {
      STATS.reds++;
      addTickets(pocket.reward);
      if (state.challenge.id === "red") addChallengeProgress(1);
      if (state.challenge.id === "streak") addChallengeProgress(1);
      SFX.redZone();
      burstParticles(ball.x, LAYOUT.pocketTop + 16, 16, "#ff2d6a");
      floatNum(canvas, t("redGain", { n: pocket.reward }), "#ff2d6a");
      mascotSay(t("mascot.red"), "◇");
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
        mascotSay(t("mascot.nearMiss"), "◇");
        floatNum(canvas, t("nearMissLabel"), "#ff2d6a");
      }
    }
    updateHUD();
    updatePersonaCard();
  }

  function updatePersonaCard() {
    const d = personaData();
    if (!d) return;
    document.getElementById("personaBody").innerHTML =
      '<div class="persona-name">' + d.name + '</div>' +
      '<div class="persona-desc">' + d.desc + '</div>';
  }

  document.getElementById("shareBtn").addEventListener("click", async () => {
    const text = shareText();
    if (!text) { mascotSay(t("mascot.playFirst"), "◇"); return; }
    try {
      if (navigator.share) await navigator.share({ text });
      else {
        await navigator.clipboard.writeText(text);
        mascotSay(t("mascot.copied"), "◇");
      }
    } catch (e) { /* cancel */ }
  });

  function startCharge() {
    if (state.busy) return;
    SFX.unlock();
    SFX.click();
    state.charging = true;
    $("runState").textContent = state.mode === "surge" ? "OVERDRIVE" : "CHARGE";
    document.getElementById("launchBtn").classList.add("charging");
  }

  function releaseLaunch() {
    if (!state.charging) return;
    state.charging = false;
    SFX.charge(0);
    document.getElementById("launchBtn").classList.remove("charging");
    const power = Math.min(Math.max(state.power, 0.12), 1);
    state.power = 0;
    powerFill.style.width = "0%";
    $("powerReadout").textContent = "00%";
    if (state.tickets <= 0) {
      mascotSay(t("mascot.outOfStardust"), "◇");
      return;
    }
    if (state.mode === "surge" && state.heat >= 92 && Math.random() < .42) {
      state.tickets--;
      state.chain = 0; state.heat = 36;
      updateHUD(); shakeCabinet(); SFX.nearMiss();
      $("runState").textContent = "PURGE";
      mascotSay("熔断。贪心也要看时机。", "×");
      toast("CHAIN LOST");
      return;
    }
    state.tickets--;
    updateHUD();
    CAM.punch = 8 + power * 22;
    CAM.flash = 0.35;
    launch(power);
    $("seedValue").textContent = Math.random().toString(16).slice(2, 6).toUpperCase();
    mascotSay(t("mascot.launch", { power: Math.round(power * 100) }), "◇");
  }

  const launchBtn = document.getElementById("launchBtn");
  launchBtn.addEventListener("mousedown", startCharge);
  window.addEventListener("mouseup", releaseLaunch);
  launchBtn.addEventListener("touchstart", e => { e.preventDefault(); startCharge(); }, { passive: false });
  window.addEventListener("touchend", releaseLaunch);
  window.addEventListener("keydown", e => {
    if (e.code === "Space" || e.code === "ArrowUp") { e.preventDefault(); startCharge(); }
    if (!e.repeat && (e.code === "ArrowLeft" || e.code === "KeyA")) driveFlipper("left", true);
    if (!e.repeat && (e.code === "ArrowRight" || e.code === "KeyD")) driveFlipper("right", true);
  });
  window.addEventListener("keyup", e => {
    if (e.code === "Space" || e.code === "ArrowUp") releaseLaunch();
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
    ctx.shadowBlur = 18;
    ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(tl.x, tl.y); ctx.lineTo(wellL.x, wellL.y); ctx.stroke();
    ctx.strokeStyle = "rgba(255,45,106,0.7)";
    ctx.shadowColor = "#ff2d6a";
    ctx.beginPath(); ctx.moveTo(tr.x, tr.y); ctx.lineTo(wellR.x, wellR.y); ctx.stroke();
    ctx.shadowBlur = 0;
  }

  function drawMachine() {
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    drawCorridor();

    for (const f of WORLD.fields) {
      const p = toScreen(f.x, f.y);
      const active = f.active !== false;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.scale(1, 0.55);
      ctx.globalAlpha = active ? 0.8 : 0.18;
      ctx.strokeStyle = f.type === "magnet" ? "#ff2d6a" : "#3dfff3";
      ctx.lineWidth = 2;
      for (let r = f.r * 0.28 * p.s; r <= f.r * p.s; r += 12) {
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
      ctx.shadowBlur = 16;
      ctx.lineWidth = 5 * ((a.s + b.s) / 2);
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
      ctx.shadowBlur = 0;
    }

    for (const f of WORLD.flippers) {
      const endX=f.pivotX+Math.cos(f.angle)*f.length,endY=f.pivotY+Math.sin(f.angle)*f.length;
      const a=toScreen(f.pivotX,f.pivotY),b=toScreen(endX,endY);
      const dx=b.x-a.x,dy=b.y-a.y,len=Math.max(1,Math.hypot(dx,dy));
      const nx=-dy/len,ny=dx/len;
      const root=12*a.s,tip=7*b.s,lift=10*((a.s+b.s)/2);
      const color=f.side==="left"?"#3dfff3":"#ff2d6a";
      ctx.save();
      ctx.beginPath();
      ctx.ellipse((a.x+b.x)/2+4,(a.y+b.y)/2+10,len*.55,5+tip*.25,Math.atan2(dy,dx),0,Math.PI*2);
      ctx.fillStyle="rgba(0,0,0,.62)";ctx.fill();
      ctx.beginPath();
      ctx.moveTo(a.x+nx*root,a.y+ny*root);
      ctx.lineTo(b.x+nx*tip,b.y+ny*tip);
      ctx.lineTo(b.x-nx*tip,b.y-ny*tip);
      ctx.lineTo(a.x-nx*root,a.y-ny*root);
      ctx.closePath();
      ctx.fillStyle="#09050e";ctx.fill();
      ctx.beginPath();
      ctx.moveTo(a.x+nx*root,a.y+ny*root-lift);
      ctx.lineTo(b.x+nx*tip,b.y+ny*tip-lift);
      ctx.lineTo(b.x+nx*tip,b.y+ny*tip);
      ctx.lineTo(a.x+nx*root,a.y+ny*root);
      ctx.closePath();
      const side=ctx.createLinearGradient(0,a.y-lift,0,a.y+lift);
      side.addColorStop(0,color);side.addColorStop(1,"#160818");ctx.fillStyle=side;ctx.fill();
      ctx.beginPath();
      ctx.moveTo(a.x+nx*root,a.y+ny*root-lift);
      ctx.lineTo(b.x+nx*tip,b.y+ny*tip-lift);
      ctx.lineTo(b.x-nx*tip,b.y-ny*tip-lift);
      ctx.lineTo(a.x-nx*root,a.y-ny*root-lift);
      ctx.closePath();
      const top=ctx.createLinearGradient(a.x,a.y,b.x,b.y);
      top.addColorStop(0,"#fff8e7");top.addColorStop(.16,color);top.addColorStop(.72,color);top.addColorStop(1,"#40102b");
      ctx.fillStyle=top;ctx.shadowColor=color;ctx.shadowBlur=10+f.pulse*24;ctx.fill();
      ctx.strokeStyle="rgba(255,255,255,.8)";ctx.lineWidth=1.2;ctx.stroke();
      ctx.shadowBlur=0;
      ctx.beginPath();ctx.arc(a.x,a.y-lift,root*.78,0,Math.PI*2);
      const hub=ctx.createRadialGradient(a.x-3,a.y-lift-3,1,a.x,a.y-lift,root);
      hub.addColorStop(0,"#fff");hub.addColorStop(.28,color);hub.addColorStop(1,"#160818");
      ctx.fillStyle=hub;ctx.fill();ctx.strokeStyle=color;ctx.lineWidth=2;ctx.stroke();
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
      const label = pocket.kind === "jackpot" ? "CORE" : pocket.kind === "red" ? "RIFT" : "";
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
    sprites.sort((a, b) => a.y - b.y);

    function drawPeg(n) {
      const p = toScreen(n.x, n.y);
      const color = n.type === "switch" ? (n.armed ? "#3dfff3" : "#ff2d6a") : n.type === "gate" ? "#ffc53d" : n.type === "bumper" ? "#3dfff3" : "#d7c7ff";
      const r = (n.r + n.lit * 3) * p.s * 1.4;
      const stem = r * (1.65 + p.t * 0.9);
      ctx.save();
      ctx.filter = p.t < .26 ? "blur(.35px)" : "none";
      ctx.beginPath();
      ctx.ellipse(p.x + 3 + CAM.yaw * .04, p.y + stem * 1.04, r * 1.95, r * 0.44, 0, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0," + (0.32 + p.t * 0.4) + ")";
      ctx.fill();
      const body = ctx.createLinearGradient(p.x - r, p.y, p.x + r, p.y);
      body.addColorStop(0, "#0a0610");
      body.addColorStop(0.35, color);
      body.addColorStop(0.7, "rgba(255,255,255,0.55)");
      body.addColorStop(1, "#140818");
      ctx.fillStyle = body;
      ctx.beginPath();
      ctx.moveTo(p.x - r * 0.62, p.y);
      ctx.lineTo(p.x + r * 0.62, p.y);
      ctx.lineTo(p.x + r * 0.48, p.y + stem);
      ctx.lineTo(p.x - r * 0.48, p.y + stem);
      ctx.closePath();
      ctx.fill();
      ctx.beginPath();
      ctx.ellipse(p.x, p.y + stem, r * 0.55, r * 0.18, 0, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0,0.5)";
      ctx.fill();
      const g = ctx.createRadialGradient(p.x - r * 0.35, p.y - r * 0.45, 1, p.x, p.y, r);
      g.addColorStop(0, "#fff");
      g.addColorStop(0.32, color);
      g.addColorStop(1, "#1a1024");
      ctx.beginPath();
      ctx.ellipse(p.x, p.y - r * 0.04, r * 1.05, r * 0.58, 0, 0, Math.PI * 2);
      ctx.fillStyle = g;
      ctx.fill();
      if (n.lit > 0.15) {
        ctx.shadowColor = color;
        ctx.shadowBlur = 16 + n.lit * 18;
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        ctx.shadowBlur = 0;
      }
      if (n.type === "gate") {
        ctx.strokeStyle = color;
        ctx.lineWidth = 3 * p.s;
        ctx.beginPath();
        ctx.moveTo(p.x - 22 * p.s, p.y);
        ctx.lineTo(p.x + 22 * p.s, p.y);
        ctx.stroke();
      }
      ctx.restore();
    }

    function drawLumen(ball, idle) {
      const p = toScreen(ball.x, ball.y);
      const charged = (ball.charge || 0) > 0;
      const hot = charged ? "#3dfff3" : "#ff2d6a";
      const r = ball.r * p.s * (idle ? 1.7 : 1.85);
      ctx.beginPath();
      ctx.ellipse(p.x + 2, p.y + r * 1.25, r * 1.75, r * 0.42, 0, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0," + (idle ? 0.35 : 0.55) + ")";
      ctx.fill();
      if (!idle && ball.trail && ball.trail.length > 1) {
        ctx.save();
        ctx.globalCompositeOperation = "lighter";
        ctx.lineCap = "round";
        for (let i = 1; i < ball.trail.length; i++) {
          const a = toScreen(ball.trail[i - 1].x, ball.trail[i - 1].y);
          const c = toScreen(ball.trail[i].x, ball.trail[i].y);
          const u = i / ball.trail.length;
          ctx.strokeStyle = "rgba(255,80,140," + (u * 0.55) + ")";
          ctx.lineWidth = (2 + u * 11) * c.s;
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(c.x, c.y); ctx.stroke();
          ctx.strokeStyle = "rgba(255,244,200," + (u * 0.85) + ")";
          ctx.lineWidth = (0.8 + u * 5) * c.s;
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(c.x, c.y); ctx.stroke();
        }
        ctx.restore();
      }
      if (CAM.aberration > 0.08 && !idle) {
        ctx.save();
        ctx.globalCompositeOperation = "screen";
        ctx.fillStyle = "rgba(255,45,106,0.75)";
        ctx.beginPath(); ctx.arc(p.x - 4 * CAM.aberration, p.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = "rgba(61,255,243,0.75)";
        ctx.beginPath(); ctx.arc(p.x + 4 * CAM.aberration, p.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
      }
      ctx.save();
      ctx.shadowColor = hot;
      ctx.shadowBlur = idle ? 18 : 28 + Math.min(24, CAM.speed / 70);
      const g = ctx.createRadialGradient(p.x - r * 0.38, p.y - r * 0.48, r * 0.08, p.x, p.y + r * 0.12, r);
      g.addColorStop(0, "#ffffff");
      g.addColorStop(0.18, charged ? "#d6fff9" : "#ffe9a8");
      g.addColorStop(0.48, charged ? "#3dfff3" : "#ff6b9a");
      g.addColorStop(1, charged ? "#083830" : "#5a1024");
      ctx.beginPath();
      ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
      ctx.fillStyle = g;
      ctx.fill();
      ctx.shadowBlur = 0;
      ctx.fillStyle = "rgba(255,255,255,0.9)";
      ctx.beginPath();
      ctx.ellipse(p.x - r * 0.28, p.y - r * 0.36, r * 0.28, r * 0.16, -0.55, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = "rgba(255,255,255,0.35)";
      ctx.lineWidth = 1.4;
      ctx.beginPath();
      ctx.arc(p.x, p.y, r * 0.92, 0.15, 1.4);
      ctx.stroke();
      ctx.restore();
    }

    // One painter's-order pass: balls can pass behind foreground mechanisms.
    for (const sprite of sprites) {
      if (sprite.kind === "peg") {
        drawPeg(sprite.n);
      } else {
        sprite.b.trail.push({ x: sprite.b.x, y: sprite.b.y });
        if (sprite.b.trail.length > 22) sprite.b.trail.shift();
        drawLumen(sprite.b, false);
      }
    }

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
      for (let i = 0; i < 10; i++) {
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
    vignette.addColorStop(.45,"rgba(0,0,0,0)");vignette.addColorStop(1,"rgba(0,0,0,.6)");
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
    updatePhysics(dt);
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
      if (Math.floor(now / 250) !== Math.floor((now - dt * 1000) / 250)) updateRelayUI();
    }
    settleBalls(onSettled);
    updateParticles(dt);
    syncCamera();
    try { drawMachine(); } catch (err) { window.__lastRenderError = String(err && err.stack || err); console.error(err); }
    requestAnimationFrame(loop);
  }

  window.onLangChange = () => {
    updateChallengeUI();
    updateHUD();
    updatePersonaCard();
    mascotSay(t("mascot.hello"), "◇");
  };

  initChallenge();
  updateChallengeUI();
  updateHUD();
  mascotSay("把光送进不可能的路径。按住，然后放手。", "◇");
  loop(performance.now());
})();

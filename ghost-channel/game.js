/* GHOST CHANNEL — Brackeys Game Jam 2026.2 — theme: TRUST NO ONE */
(() => {
  const AGENTS = [
    { id: "viper", name: "VIPER", color: "#2df0f0", freq: 220, grid0: [2, 2], face: "scar" },
    { id: "moth", name: "MOTH", color: "#ff3dad", freq: 178, grid0: [6, 1], face: "moth" },
    { id: "hex", name: "HEX", color: "#f5d031", freq: 256, grid0: [4, 5], face: "glasses" },
    { id: "raven", name: "RAVEN", color: "#7cff6b", freq: 146, grid0: [1, 6], face: "raven" },
    { id: "quill", name: "QUILL", color: "#ff8a3d", freq: 198, grid0: [7, 6], face: "youth" },
  ];

  const COLORS = ["BLUE", "IVORY", "ASH", "VIOLET", "COPPER"];
  const WORDS = ["IVY", "HARBOR", "NEEDLE", "GLASS", "CINDER", "FENCE"];

  const OPS = [
    { id: 1, requests: 7, time: 150, mapSpoof: false, captured: false, poison: false, unlock: 0 },
    { id: 2, requests: 9, time: 165, mapSpoof: false, captured: true, poison: false, unlock: 1 },
    { id: 3, requests: 10, time: 180, mapSpoof: true, captured: false, poison: true, unlock: 2 },
  ];

  const t = (k, v) => GCi18n.t(k, v);
  const loc = (a) => Object.assign({}, a, GCi18n.agent(a.id));
  const who = (a) => GCi18n.agent(a.id).local;

  const $ = (id) => document.getElementById(id);
  const screens = {};
  ["boot", "title", "ops", "how", "credits", "play", "debrief"].forEach((n) => {
    screens[n] = $("screen-" + n);
  });

  const save = {
    best: JSON.parse(localStorage.getItem("gc-best") || "{}"),
    wins: Number(localStorage.getItem("gc-wins") || 0),
  };
  function persist() {
    localStorage.setItem("gc-best", JSON.stringify(save.best));
    localStorage.setItem("gc-wins", String(save.wins));
  }

  function tel(name, value) {
    try { if (window.TEL) window.TEL.ev(name, value || {}); } catch (e) {}
  }

  let state = null;
  let mapRaf = 0;
  let ticker = 0;

  function show(name) {
    Object.values(screens).forEach((el) => el.classList.remove("show"));
    screens[name].classList.add("show");
    tel("screen", { screen: name });
  }

  function pick(arr) { return arr[(Math.random() * arr.length) | 0]; }
  function shuffle(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = (Math.random() * (i + 1)) | 0;
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }
  function gridLabel(g) { return String.fromCharCode(65 + g[0]) + (g[1] + 1); }
  function dist(a, b) { return Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]); }

  function newBook() {
    return {
      color: pick(COLORS),
      num: 2 + ((Math.random() * 7) | 0),
      word: pick(WORDS),
    };
  }
  function bookText(b) { return `${b.color}-${b.num}-${b.word}`; }

  function log(html, cls) {
    const row = document.createElement("div");
    row.className = "log-row " + (cls || "");
    row.innerHTML = html;
    $("log").prepend(row);
  }

  function agentById(id) { return state.agents.find((a) => a.id === id); }

  function startOp(op) {
    const yesterday = newBook();
    let today = newBook();
    while (today.word === yesterday.word && today.color === yesterday.color) today = newBook();

    const mimic = pick(AGENTS);
    let captured = null;
    if (op.captured) {
      captured = pick(AGENTS.filter((a) => a.id !== mimic.id));
    }

    state = {
      op,
      mimicId: mimic.id,
      capturedId: captured ? captured.id : null,
      book: today,
      yesterday,
      poisoned: false,
      agents: AGENTS.map((a) => ({
        ...loc(a),
        grid: a.grid0.slice(),
        alive: true,
        wounded: false,
        suspect: false,
        lastPhrase: "",
      })),
      pending: [],
      request: null,
      awaitingName: false,
      time: op.time,
      ff: 0,
      score: 0,
      done: 0,
      stats: { auth: 0, deny: 0, q: 0, correct: 0, wrong: 0 },
      phase: "play",
      ended: false,
    };

    state.pending = planRequests(state);
    $("log").innerHTML = "";
    $("op-name").textContent = GCi18n.opMeta(op.id - 1).name;
    $("op-sub").textContent = t("opSub");
    $("codebook").textContent = bookText(state.book);
    $("code-note").textContent = t("yestNote", { book: bookText(state.yesterday) });
    renderRoster();
    setNamingMode(false);
    log(t("netOpen", { book: bookText(state.book) }), "sys");
    if (state.capturedId) {
      log(t("intelCap", { who: who(agentById(state.capturedId)) }), "sys");
    }
    show("play");
    tel("play", { op: op.id, returning: save.wins > 0, prior_wins: save.wins });
    nextRequest();
    loopMap();
    startTicker();
    GCAudio.pulse();
  }

  function planRequests(s) {
    const types = ["fire", "extract", "resupply", "move", "codebook", "accuse"];
    const queue = [];
    const ids = s.agents.map((a) => a.id);

    // First two are friendlies so the player learns the voice.
    const friendlies = ids.filter((id) => id !== s.mimicId);
    queue.push({ speaker: friendlies[0], type: "resupply", forceClean: true });
    queue.push({ speaker: friendlies[1 % friendlies.length], type: "move", forceClean: true });

    const rest = s.op.requests - 2;
    let mimicLeft = 2 + (s.op.id > 1 ? 1 : 0);
    for (let i = 0; i < rest; i++) {
      const useMimic = mimicLeft > 0 && (i === rest - 1 || Math.random() < 0.38);
      const speaker = useMimic ? s.mimicId : pick(friendlies);
      if (useMimic) mimicLeft--;
      queue.push({ speaker, type: pick(types), forceClean: false });
    }
    return queue;
  }

  function occupiedGrids() {
    return state.agents.filter((a) => a.alive).map((a) => a.grid);
  }

  function emptyGrid() {
    for (let n = 0; n < 40; n++) {
      const g = [(Math.random() * 8) | 0, (Math.random() * 8) | 0];
      if (!occupiedGrids().some((o) => o[0] === g[0] && o[1] === g[1])) return g;
    }
    return [0, 0];
  }

  function buildRequest(spec) {
    const speaker = agentById(spec.speaker);
    const isMimic = speaker.id === state.mimicId;
    const isCaptured = speaker.id === state.capturedId;
    const type = spec.type;
    const req = {
      speaker: speaker.id,
      type,
      isMimic,
      isCaptured,
      tells: [],
      target: null,
      auth: bookText(state.book),
      phrase: "",
      extra: "",
    };

    if (type === "fire") {
      if (isMimic && !spec.forceClean) {
        const victim = pick(state.agents.filter((a) => a.id !== speaker.id && a.alive));
        req.target = victim.grid.slice();
        req.tells.push("friendly-fire");
      } else {
        req.target = emptyGrid();
      }
    }
    if (type === "move") req.target = emptyGrid();
    if (type === "accuse") {
      const tgt = pick(state.agents.filter((a) => a.id !== speaker.id));
      req.targetId = tgt.id;
      req.targetName = who(tgt);
    }

    if ((isMimic || (isCaptured && !spec.forceClean)) && !spec.forceClean) {
      const pool = ["auth", "tic", "oldbook"];
      if (type === "fire") pool.push("friendly-fire");
      if (state.op.mapSpoof) pool.push("ghost-plot");
      const tell = pick(pool);
      if (!req.tells.includes(tell)) req.tells.push(tell);
      if (tell === "auth") req.auth = bookText(state.yesterday);
      if (tell === "oldbook") req.auth = bookText(state.yesterday);
    }

    // Captured friendlies never request a codebook poison or a true ghost accuse of themselves.
    if (isMimic && type === "codebook" && !spec.forceClean) req.tells.push("poison");

    req.phrase = writeLine(req, speaker);
    if (req.tells.includes("tic")) {
      const other = pick(state.agents.filter((a) => a.id !== speaker.id));
      req.phrase += " ……" + GCi18n.agent(other.id).tic + ".";
      req.extra = t("borrowedTic");
    }
    speaker.lastPhrase = req.phrase;
    return req;
  }

  function writeLine(req, speaker) {
    const auth = t("authWord", { book: req.auth });
    const pool = GCi18n.lines(req.type);
    return pick(pool).replace(/\{auth\}/g, auth).replace(/\{who\}/g, who(speaker)).replace(/\{grid\}/g, req.target ? gridLabel(req.target) : "").replace(/\{target\}/g, req.targetName || "");
  }

  function nextRequest() {
    if (state.ended) return;
    if (!state.pending.length) {
      beginNaming();
      return;
    }
    const spec = state.pending.shift();
    state.request = buildRequest(spec);
    state.done += 1;
    const a = agentById(state.request.speaker);
    $("incoming").classList.remove("locked");
    $("inc-who").textContent = who(a) + " · " + a.name + " · " + gridLabel(a.grid);
    $("inc-type").textContent = GCi18n.typeName(state.request.type) + " · " + state.done + "/" + state.op.requests;
    $("inc-body").textContent = state.request.phrase;
    $("inc-extra").textContent = GCi18n.agent(a.id).role + "  ·  「" + GCi18n.agent(a.id).quote + "」";
    paintPortrait($("inc-face"), a, 72);
    log(`<span class="who" style="color:${a.color}">${who(a)}</span> — ${state.request.phrase}`);
    GCAudio.callsign(a.freq);
    renderRoster();
  }

  function interrogate() {
    if (!state.request || state.ended) return;
    state.stats.q += 1;
    state.time = Math.max(0, state.time - 8);
    const req = state.request;
    const a = agentById(req.speaker);
    const fail = req.isMimic || (req.isCaptured && Math.random() < 0.7);
    GCAudio.click();
    tel("q", { op: state.op.id, mimic: !!req.isMimic, captured: !!req.isCaptured, fail: !!fail, type: req.type });
    if (fail) {
      const fake = bookText(state.yesterday);
      $("inc-extra").textContent = t("qFail", { who: who(a), fake });
      log(t("qFailLog", { who: who(a) }), "bad");
      GCAudio.warn();
    } else {
      $("inc-extra").textContent = t("qPass", { who: who(a), book: bookText(state.book), grid: gridLabel(a.grid) });
      log(t("qPassLog", { who: who(a) }), "sys");
    }
  }

  function resolve(choice) {
    if (!state.request || state.ended) return;
    const req = state.request;
    const a = agentById(req.speaker);
    $("incoming").classList.add("locked");
    tel("radio", {
      op: state.op.id,
      choice: choice,
      type: req.type,
      mimic: !!req.isMimic,
      captured: !!req.isCaptured,
      tells: (req.tells || []).slice(0, 6),
    });

    if (choice === "auth") {
      state.stats.auth += 1;
      GCAudio.auth();
      if (req.tells.includes("friendly-fire") && req.isMimic) {
        const hit = state.agents.find((x) => x.alive && x.grid[0] === req.target[0] && x.grid[1] === req.target[1]);
        if (hit) {
          hit.alive = false;
          state.ff += 1;
          state.stats.wrong += 1;
          state.score -= 150;
          log(t("ffLog", { who: who(hit) }), "bad");
          GCAudio.warn();
        }
      } else if (req.type === "codebook" && req.isMimic) {
        state.poisoned = true;
        const fake = newBook();
        state.yesterday = state.book;
        state.book = fake;
        $("codebook").textContent = bookText(state.book);
        $("code-note").textContent = t("bookPoisonNote");
        state.stats.wrong += 1;
        state.score -= 80;
        log(t("bookPoisonLog", { who: who(a) }), "bad");
      } else if (req.type === "extract" && req.isMimic) {
        state.stats.wrong += 1;
        state.score -= 120;
        log(t("extractGhostLog"), "bad");
        endOp(false, t("extractGhostEnd"), "extract");
        return;
      } else if (req.type === "accuse" && !req.isMimic) {
        const named = state.agents.find((x) => x.id === req.targetId);
        if (named && named.id !== state.mimicId) {
          named.wounded = true;
          state.score -= 40;
          log(t("falseAccuse", { who: who(named) }), "bad");
        } else {
          state.stats.correct += 1;
          state.score += 90;
          log(t("accuseOk"), "sys");
        }
      } else if (req.isMimic && req.tells.length) {
        state.stats.wrong += 1;
        state.score -= 40;
        log(t("authItch", { who: who(a) }), "bad");
      } else {
        if (req.type === "move") a.grid = req.target;
        state.stats.correct += 1;
        state.score += 40;
        log(t("authOk", { who: who(a) }), "sys");
      }
    } else {
      state.stats.deny += 1;
      GCAudio.deny();
      if (req.isMimic) {
        state.stats.correct += 1;
        state.score += 110;
        log(t("denyGhost", { who: who(a) }), "sys");
      } else if (req.type === "extract") {
        a.wounded = true;
        state.stats.wrong += 1;
        state.score -= 60;
        log(t("denyExtract", { who: who(a) }), "bad");
      } else {
        state.score -= 10;
        log(t("denySoft", { who: who(a) }), "sys");
      }
    }

    renderRoster();
    updateHud();
    if (state.ff >= 2) {
      endOp(false, t("twoFF"), "ff");
      return;
    }
    setTimeout(nextRequest, 650);
  }

  function setNamingMode(on) {
    $("incoming").classList.toggle("naming", !!on);
    document.querySelector(".roster-wrap").classList.toggle("naming", !!on);
    const box = $("name-acts");
    if (!box) return;
    box.hidden = !on;
    box.innerHTML = "";
    if (!on || !state) return;
    state.agents.forEach((a, i) => {
      const btn = document.createElement("button");
      btn.className = "warn";
      btn.disabled = !a.alive;
      btn.textContent = t("nameBtn", { n: i + 1, who: who(a) });
      btn.onclick = () => accuse(a.id);
      box.appendChild(btn);
    });
  }

  function beginNaming() {
    state.awaitingName = true;
    state.request = null;
    state.time = Math.max(state.time, 25);
    $("incoming").classList.remove("locked");
    $("inc-who").textContent = t("nameGhost");
    $("inc-type").textContent = t("finalCall");
    $("inc-body").textContent = t("nameBody");
    $("inc-extra").textContent = t("nameExtra");
    log(t("nameLog"), "sys");
    renderRoster();
    setNamingMode(true);
    tel("naming", {
      op: state.op.id,
      score: state.score,
      auth: state.stats.auth,
      deny: state.stats.deny,
      q: state.stats.q,
      ff: state.ff,
    });
  }

  function accuse(id) {
    if (!state || !state.awaitingName || state.ended) return;
    const ghost = agentById(state.mimicId);
    const pickA = agentById(id);
    const ok = id === state.mimicId;
    if (ok) {
      state.score += 200;
      save.wins += 1;
      persist();
      endOp(true, t("winLead", { who: who(ghost) }), "named-ok");
    } else {
      endOp(false, t("loseLead", { who: who(pickA), ghost: who(ghost) }), "named-wrong");
    }
  }

  function endOp(win, lead, reason) {
    if (state.ended) return;
    state.ended = true;
    clearInterval(ticker);
    const key = "op" + state.op.id;
    if (win) save.best[key] = Math.max(save.best[key] || 0, state.score);
    persist();
    $("end-title").textContent = win ? t("winTitle") : t("loseTitle");
    $("end-title").style.color = win ? "var(--cyan)" : "var(--mag)";
    $("end-lead").textContent = lead;
    $("end-stats").innerHTML = `
      <div>${t("statScore")}<b>${state.score}</b></div>
      <div>${t("statAuth")}<b>${state.stats.auth}</b></div>
      <div>${t("statDeny")}<b>${state.stats.deny}</b></div>
      <div>${t("statQ")}<b>${state.stats.q}</b></div>
      <div>${t("statFF")}<b>${state.ff}</b></div>
      <div>${t("statBest")}<b>${save.best["op" + state.op.id] || 0}</b></div>`;
    setNamingMode(false);
    show("debrief");
    tel(win ? "win" : "lose", {
      op: state.op.id,
      reason: reason || (win ? "named-ok" : "unknown"),
      score: state.score,
      auth: state.stats.auth,
      deny: state.stats.deny,
      q: state.stats.q,
      correct: state.stats.correct,
      wrong: state.stats.wrong,
      ff: state.ff,
      remaining: state.time | 0,
    });
    if (!win) GCAudio.warn();
    else GCAudio.winSting();
    // The debrief is the end of the run, and the end of a run is where this catalogue
    // offers the rest of itself. Offered, never forced: the board is dismissable and the
    // debrief is still behind it.
    setTimeout(function () {
      if (window.BOARD && BOARD.adultAllowed()) BOARD.offerMore("adult");
      else if (window.PROMO) PROMO.showAfterRun(win ? "win" : "lose");
    }, 900);
  }

  function paintPortrait(cv, a, size) {
    if (!cv) return;
    cv.width = size; cv.height = size;
    const x = cv.getContext("2d");
    x.fillStyle = "#0a0912";
    x.fillRect(0, 0, size, size);
    x.fillStyle = a.color + "22";
    x.fillRect(0, 0, size, size);
    const cx = size / 2, cy = size * 0.46, r = size * 0.28;
    x.fillStyle = "#d7c4b0";
    x.beginPath(); x.arc(cx, cy, r, 0, Math.PI * 2); x.fill();
    x.fillStyle = a.color;
    if (a.face === "moth") {
      x.beginPath(); x.ellipse(cx, cy - r * 0.2, r * 1.05, r * 0.7, 0, 0, Math.PI * 2); x.fill();
      x.fillStyle = "#1a1020";
      x.fillRect(cx - r * 0.7, cy - r * 0.05, r * 1.4, r * 0.12);
    } else if (a.face === "glasses") {
      x.fillRect(cx - r, cy - r * 0.95, r * 2, r * 0.55);
      x.strokeStyle = a.color; x.lineWidth = 2;
      x.strokeRect(cx - r * 0.7, cy - r * 0.15, r * 0.5, r * 0.35);
      x.strokeRect(cx + r * 0.2, cy - r * 0.15, r * 0.5, r * 0.35);
      x.beginPath(); x.moveTo(cx - r * 0.2, cy); x.lineTo(cx + r * 0.2, cy); x.stroke();
    } else if (a.face === "raven") {
      x.fillRect(cx - r * 0.95, cy - r * 0.85, r * 1.9, r * 0.35);
      x.fillStyle = "#2a2018";
      x.beginPath(); x.arc(cx, cy + r * 0.35, r * 0.55, 0, Math.PI); x.fill();
    } else if (a.face === "youth") {
      x.beginPath(); x.ellipse(cx, cy - r * 0.35, r * 0.95, r * 0.7, 0, Math.PI, 0); x.fill();
    } else {
      x.fillRect(cx - r * 0.9, cy - r * 0.7, r * 1.8, r * 0.4);
      x.strokeStyle = "#8a3040"; x.lineWidth = 2;
      x.beginPath(); x.moveTo(cx - r * 0.45, cy - r * 0.15); x.lineTo(cx - r * 0.1, cy + r * 0.05); x.stroke();
    }
    x.fillStyle = "#1a1420";
    x.beginPath(); x.arc(cx - r * 0.28, cy, r * 0.08, 0, Math.PI * 2); x.fill();
    x.beginPath(); x.arc(cx + r * 0.28, cy, r * 0.08, 0, Math.PI * 2); x.fill();
    x.fillStyle = "#0a0912";
    x.fillRect(0, size * 0.78, size, size * 0.22);
    x.fillStyle = a.color;
    x.font = "bold " + Math.max(8, size * 0.14) + "px monospace";
    x.textAlign = "center";
    x.fillText(who(a), cx, size * 0.93);
  }

  function drawMarker(x, px, py, a, t) {
    const s = 11 + Math.sin(t / 200) * 1.2;
    x.save();
    x.translate(px, py);
    x.fillStyle = a.color;
    x.globalAlpha = 0.95;
    x.beginPath();
    if (a.id === "viper") {
      x.moveTo(0, -s); x.lineTo(s * 0.7, s); x.lineTo(0, s * 0.45); x.lineTo(-s * 0.7, s); x.closePath();
    } else if (a.id === "moth") {
      x.ellipse(-s * 0.55, 0, s * 0.7, s * 0.45, -0.4, 0, Math.PI * 2);
      x.ellipse(s * 0.55, 0, s * 0.7, s * 0.45, 0.4, 0, Math.PI * 2);
    } else if (a.id === "hex") {
      for (let i = 0; i < 6; i++) {
        const ang = Math.PI / 3 * i - Math.PI / 6;
        const fn = i ? x.lineTo : x.moveTo;
        fn.call(x, Math.cos(ang) * s, Math.sin(ang) * s);
      }
      x.closePath();
    } else if (a.id === "raven") {
      x.moveTo(0, -s); x.lineTo(s, s * 0.3); x.lineTo(0, s * 0.1); x.lineTo(-s, s * 0.3); x.closePath();
    } else {
      x.moveTo(0, -s); x.lineTo(s * 0.75, 0); x.lineTo(0, s); x.lineTo(-s * 0.75, 0); x.closePath();
    }
    x.fill();
    x.restore();
  }

  function renderRoster() {
    const box = $("roster");
    box.innerHTML = "";
    state.agents.forEach((a) => {
      const b = document.createElement("button");
      b.className = "agent" + (a.suspect ? " suspect" : "") + (a.alive ? "" : " dead");
      b.innerHTML = `<canvas class="face" width="56" height="56"></canvas>
        <div class="meta"><div class="nm" style="color:${a.color}">${who(a)} · ${a.name}</div>
        <div class="st">${GCi18n.agent(a.id).role} · ${a.alive ? gridLabel(a.grid) : t("kia")}${a.wounded ? " · " + t("wounded") : ""}${a.suspect ? " · " + t("pinned") : ""}</div>
        <div class="qt">「${GCi18n.agent(a.id).quote}」</div></div>`;
      paintPortrait(b.querySelector("canvas"), a, 56);
      b.onclick = () => {
        if (state.awaitingName) accuse(a.id);
        else {
          a.suspect = !a.suspect;
          renderRoster();
        }
      };
      box.appendChild(b);
    });
  }

  function updateHud() {
    $("hud-time").textContent = String(Math.max(0, state.time | 0)).padStart(2, "0");
    $("hud-ff").textContent = String(state.ff);
    $("hud-ff").className = state.ff ? "bad" : "";
    $("hud-score").textContent = String(state.score);
  }

  function startTicker() {
    clearInterval(ticker);
    ticker = setInterval(() => {
      if (!state || state.ended) return;
      state.time -= 1;
      updateHud();
      if (state.time <= 0) {
        endOp(false, t("clockZero"), "timeout");
      }
    }, 1000);
    updateHud();
  }

  function loopMap() {
    cancelAnimationFrame(mapRaf);
    const c = $("map");
    const x = c.getContext("2d");
    const tick = (t) => {
      const w = c.width, h = c.height;
      x.fillStyle = "#080714";
      x.fillRect(0, 0, w, h);
      x.strokeStyle = "rgba(45,240,240,.12)";
      x.lineWidth = 1;
      for (let i = 0; i <= 8; i++) {
        x.beginPath(); x.moveTo(40 + i * 70, 30); x.lineTo(40 + i * 70, 30 + 8 * 54); x.stroke();
        x.beginPath(); x.moveTo(40, 30 + i * 54); x.lineTo(40 + 8 * 70, 30 + i * 54); x.stroke();
      }
      x.fillStyle = "#4e5a6e";
      x.font = "11px monospace";
      for (let i = 0; i < 8; i++) {
        x.fillText(String.fromCharCode(65 + i), 66 + i * 70, 22);
        x.fillText(String(i + 1), 18, 62 + i * 54);
      }
      if (state) {
        state.agents.forEach((a) => {
          if (!a.alive) return;
          let gx = a.grid[0], gy = a.grid[1];
          if (state.op.mapSpoof && a.id === state.mimicId && Math.sin(t / 400) > 0.2) {
            gx = (gx + 2) % 8; gy = (gy + 1) % 8;
          }
          const px = 40 + gx * 70 + 35;
          const py = 30 + gy * 54 + 27;
          x.globalAlpha = 0.22;
          x.fillStyle = a.color;
          x.beginPath(); x.arc(px, py, 20, 0, Math.PI * 2); x.fill();
          x.globalAlpha = 1;
          drawMarker(x, px, py, a, t);
          x.fillStyle = "#e8f6ff";
          x.font = "11px monospace";
          x.fillText(who(a), px - 16, py + 26);
        });
        if (state.request && state.request.target) {
          const g = state.request.target;
          const px = 40 + g[0] * 70 + 35;
          const py = 30 + g[1] * 54 + 27;
          x.strokeStyle = "#ff3dad";
          x.globalAlpha = 0.8;
          x.strokeRect(px - 24, py - 20, 48, 40);
          x.globalAlpha = 1;
        }
      }
      mapRaf = requestAnimationFrame(tick);
    };
    mapRaf = requestAnimationFrame(tick);
  }

  function renderOps() {
    const box = $("op-list");
    box.innerHTML = "";
    OPS.forEach((op, i) => {
      const locked = save.wins < op.unlock && i > 0 && !(save.best["op" + (op.id - 1)]);
      const b = document.createElement("button");
      b.className = "op-card";
      b.disabled = locked;
      const meta = GCi18n.opMeta(i);
      // Dual-track (ops/DUAL_TRACK.md): operation 1 is the free game; 2 and 3 are
      // behind the gate — a price on itch, a sponsor clip on the ad-supported site.
      const gated = i > 0 && window.Gate && !window.Gate.has("op" + op.id) && window.Gate.dist() !== "paid";
      b.innerHTML = `<b>${meta.name}</b><span>${meta.blurb}</span><small>${locked ? t("locked") : gated ? "🔒 " + (window.Gate.dist() === "ads_web" ? "sponsor clip" : (window.GATE_CONFIG || {}).price || "full game") : t("best", { n: save.best["op" + op.id] || 0 })}</small>`;
      b.onclick = () => {
        if (!gated) return startOp(op);
        window.Gate.require("op" + op.id, { title: meta.name, kind: "level", blurb: meta.blurb }).then((r) => {
          if (r === "unlocked") { renderOps(); startOp(op); }
        });
      };
      box.appendChild(b);
    });
  }

  function goTitle() { show("title"); }
  function bootContinue() {
    GCAudio.unlock();
    show("title");
  }

  function mountLang() {
    const dock = $("lang-dock");
    dock.innerHTML = "";
    GCi18n.LANGS.forEach((code) => {
      const b = document.createElement("button");
      b.dataset.lang = code;
      b.textContent = GCi18n.LANG_LABEL[code];
      b.onclick = () => { GCAudio.click(); GCi18n.setLang(code); tel("lang", { lang: code }); };
      dock.appendChild(b);
    });
  }
  window.GCOnLang = () => {
    if (state) {
      state.agents.forEach((a) => Object.assign(a, GCi18n.agent(a.id)));
      $("op-name").textContent = GCi18n.opMeta(state.op.id - 1).name;
      $("op-sub").textContent = t("opSub");
      renderRoster();
      if (state.awaitingName && !state.ended) setNamingMode(true);
    }
    renderOps();
  };
  mountLang();
  GCi18n.applyStatic();

  $("btn-start").onclick = () => {
    GCAudio.click();
    renderOps();
    const returning = save.wins > 0 || Object.keys(save.best).length > 0;
    if (returning) show("ops");
    else startOp(OPS[0]);
  };
  $("btn-how").onclick = () => { GCAudio.click(); show("how"); };
  $("btn-credits").onclick = () => { GCAudio.click(); show("credits"); };
  $("btn-again").onclick = () => { if (state) startOp(state.op); };
  $("btn-menu").onclick = () => { renderOps(); show("ops"); };
  $("btn-auth").onclick = () => resolve("auth");
  $("btn-deny").onclick = () => resolve("deny");
  $("btn-q").onclick = () => interrogate();
  document.querySelectorAll("[data-back]").forEach((b) => {
    b.onclick = () => show(b.getAttribute("data-back"));
  });

  window.addEventListener("keydown", (e) => {
    if (screens.boot.classList.contains("show")) { bootContinue(); return; }
    if (state && state.awaitingName && !state.ended) {
      const n = Number(e.key);
      if (n >= 1 && n <= 5 && state.agents[n - 1]) accuse(state.agents[n - 1].id);
      return;
    }
    const k = e.key.toLowerCase();
    if (k === "a") resolve("auth");
    if (k === "d") resolve("deny");
    if (k === "q") interrogate();
  });
  screens.boot.addEventListener("click", bootContinue);
  setTimeout(() => {
    if (screens.boot.classList.contains("show")) bootContinue();
  }, 900);

  function returningPlayer() {
    return save.wins > 0 || Object.keys(save.best).length > 0;
  }
  function jamHotstart() {
    const compact = window.innerWidth < 960 || window.innerHeight < 720;
    if (compact && !returningPlayer()) {
      bootContinue();
      startOp(OPS[0]);
      tel("hotstart", { reason: "embed" });
      return true;
    }
    return false;
  }

  function applyLayout() {
    const compact = window.innerWidth < 960 || window.innerHeight < 720;
    const crt = $("crt") || document.getElementById("crt");
    if (crt) crt.classList.toggle("compact", compact);
    return compact;
  }
  applyLayout();
  tel("layout", {
    compact: applyLayout(),
    w: window.innerWidth | 0,
    h: window.innerHeight | 0,
  });
  let layoutTimer = 0;
  window.addEventListener("resize", () => {
    applyLayout();
    clearTimeout(layoutTimer);
    layoutTimer = setTimeout(() => {
      tel("layout", {
        compact: applyLayout(),
        w: window.innerWidth | 0,
        h: window.innerHeight | 0,
      });
    }, 400);
  });

  jamHotstart();

  // Expose a tiny test hook for headless checks.
  window.GCTest = {
    bookText,
    planRequests,
    newStateForTest(opId) {
      const op = OPS[opId - 1];
      const mimic = AGENTS[0];
      return {
        op, mimicId: mimic.id, capturedId: null,
        book: { color: "BLUE", num: 7, word: "IVY" },
        yesterday: { color: "ASH", num: 3, word: "FENCE" },
        agents: AGENTS.map((a) => ({ ...a, grid: a.grid0.slice(), alive: true, wounded: false, suspect: false })),
      };
    },
  };
})();

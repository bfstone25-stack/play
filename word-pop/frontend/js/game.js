(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  // Pet names live in the string table (pet.<id>) so a pull reads right in either language.
  const PETS = [
    { id: "vocab", rarity: "N" },
    { id: "math", rarity: "SR" },
  ];
  const LANG_KEY = "wp_lang";
  const PACK = { en: "en", zh: "zh-Hans" };
  let lang = "en";

  I18N.register({
    en: {
      "title": "Word Pop Quest",
      "hud.charge": "CHARGE",
      "hud.ok": "CORRECT",
      "hud.dust": "STAR DUST",
      "ui.answer": "Your answer",
      "ui.go": "ANSWER · CHARGE · FIRE",
      "ui.report": "Parent report",
      "ui.pull": "Pet pull 50★",
      "toast.full": "Full charge — FIRE!",
      "toast.ok": "Correct! +{pct}%",
      "toast.wrong": "Not quite — try again",
      "toast.noDust": "Not enough StarDust",
      "toast.got": "New pet: {name}",
      "pet.vocab": "Vocab Sprite",
      "pet.math": "Math Beast",
    },
    "zh-Hans": {
      "title": "单词弹珠英雄 · Word Pop Quest",
      "hud.charge": "充能",
      "hud.ok": "答对",
      "hud.dust": "星尘",
      "ui.answer": "答案",
      "ui.go": "答题充能 / 发射",
      "ui.report": "家长日报",
      "ui.pull": "萌宠 50★",
      "toast.full": "充能满，发射",
      "toast.ok": "正确 +{pct}%",
      "toast.wrong": "再试一次",
      "toast.noDust": "星尘不够",
      "toast.got": "新萌宠：{name}",
      "pet.vocab": "词汇精灵",
      "pet.math": "算术神兽",
    },
  });

  let charge = 0, correct = 0, attempts = 0, item = pickQuiz();
  Save.load();

  function applyLang(code) {
    lang = code === "zh" ? "zh" : "en";
    I18N.setLang(PACK[lang]);
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
    document.title = I18N.t("title");
    document.querySelectorAll("[data-i18n]").forEach(el => { el.textContent = I18N.t(el.getAttribute("data-i18n")); });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(el => { el.placeholder = I18N.t(el.getAttribute("data-i18n-placeholder")); });
    document.querySelectorAll("[data-lang]").forEach(b => b.classList.toggle("on", b.getAttribute("data-lang") === lang));
    hud();
    if (window.TEL && TEL.ev) TEL.ev("language", { lang });
  }
  document.querySelectorAll("[data-lang]").forEach(b => {
    b.addEventListener("click", () => {
      const code = b.getAttribute("data-lang");
      I18N.remember(LANG_KEY, code);
      applyLang(code);
    });
  });

  function toast(m) {
    const el = document.getElementById("toast");
    el.textContent = m;
    el.classList.add("show");
    clearTimeout(toast.t);
    toast.t = setTimeout(() => el.classList.remove("show"), 1600);
  }
  function hud() {
    document.getElementById("chg").textContent = Math.round(charge * 100) + "%";
    document.getElementById("ok").textContent = correct;
    document.getElementById("dust").textContent = Economy.snapshot().stardust;
    document.getElementById("prompt").textContent = item.prompt + " · " + quizHint(item, lang);
  }
  function next() { item = pickQuiz(); hud(); }
  function petName(pet) {
    const key = "pet." + pet.id;
    const s = I18N.t(key);
    return s === key ? (pet.name || pet.id) : s;
  }

  document.getElementById("goBtn").onclick = () => {
    const input = document.getElementById("ans").value;
    attempts += 1;
    const ok = checkQuiz(item, input);
    charge = chargeShot(charge, ok);
    if (ok) {
      correct += 1;
      Economy.grant(2);
      document.getElementById("ans").value = "";
      if (charge >= 0.99) {
        launch(charge);
        charge = 0;
        toast(I18N.t("toast.full"));
      } else toast(I18N.t("toast.ok", { pct: Math.round(charge * 100) }));
      next();
    } else toast(I18N.t("toast.wrong"));
    Save.persist({ wordpop: { correct, attempts } });
    hud();
  };
  document.getElementById("reportBtn").onclick = async () => {
    const r = parentReport({ correct, attempts }, lang);
    const text = r.title + "\n" + r.lines.join("\n");
    toast(text.split("\n")[1] || r.title);
    if (navigator.share) {
      try { await navigator.share({ title: r.title, text }); } catch (e) { /* cancel */ }
    }
    // Word Pop never ends on its own; asking for the parent report is the player saying
    // "that was a session", so that is where the catalogue board is offered. Offered,
    // never forced: it is dismissable and the board behind it is untouched.
    if (!window.__boardOffered) {
      window.__boardOffered = 1;
      setTimeout(() => {
        if (window.BOARD) BOARD.offerMore("casual");   // casual board only — see index.html
      }, 900);
    }
  };
  document.getElementById("pullBtn").onclick = () => {
    if (!Economy.spend(Gacha.PULL_COST)) { toast(I18N.t("toast.noDust")); return; }
    toast(I18N.t("toast.got", { name: petName(Gacha.pull(PETS)) }));
    hud();
  };

  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.032, (now - last) / 1000);
    last = now;
    updatePhysics(dt);
    updateParticles(dt);
    settleBalls((_b, pocket) => {
      if (pocket) Economy.grant(pocket.reward || 1);
      hud();
    });
    ctx.fillStyle = "#14110d";
    ctx.fillRect(0, 0, 420, 420);
    ctx.fillStyle = "#2a241c";
    ctx.fillRect(LAYOUT.leftWall, 40, LAYOUT.rightWall - LAYOUT.leftWall, 320);
    WORLD.pegs.forEach(n => {
      ctx.beginPath();
      ctx.arc(n.x, n.y * 0.62, n.r, 0, Math.PI * 2);
      ctx.fillStyle = "#d4a017";
      ctx.fill();
    });
    WORLD.balls.forEach(b => {
      ctx.beginPath();
      ctx.arc(b.x, b.y * 0.62, b.r, 0, Math.PI * 2);
      ctx.fillStyle = "#e8d7a0";
      ctx.fill();
    });
    requestAnimationFrame(frame);
  }
  applyLang(I18N.detect(LANG_KEY));
  requestAnimationFrame(frame);
})();

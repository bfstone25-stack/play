(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const PETS = [
    { id: "vocab", rarity: "N", name: "词汇精灵" },
    { id: "math", rarity: "SR", name: "算术神兽" },
  ];
  let charge = 0, correct = 0, attempts = 0, item = pickQuiz();
  Save.load();

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
    document.getElementById("prompt").textContent = item.prompt + " · " + item.hint;
  }
  function next() { item = pickQuiz(); hud(); }

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
        toast("充能满，发射");
      } else toast("正确 +" + Math.round(charge * 100) + "%");
      next();
    } else toast("再试一次");
    Save.persist({ wordpop: { correct, attempts } });
    hud();
  };
  document.getElementById("reportBtn").onclick = async () => {
    const r = parentReport({ correct, attempts });
    const text = r.title + "\n" + r.lines.join("\n");
    toast(text.split("\n")[1] || r.title);
    if (navigator.share) {
      try { await navigator.share({ title: r.title, text }); } catch (e) { /* cancel */ }
    }
  };
  document.getElementById("pullBtn").onclick = () => {
    if (!Economy.spend(Gacha.PULL_COST)) { toast("星尘不够"); return; }
    toast(Gacha.pull(PETS).name);
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
  hud();
  requestAnimationFrame(frame);
})();

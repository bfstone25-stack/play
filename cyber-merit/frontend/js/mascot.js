const MASCOT = (() => {
  const LINES = {
    "zh-Hans": {
      idle: ["先敲一下。云会记账。", "我替你看着香。", "功德粒子很好吃。偶尔偷一粒。", "空格也可以。我数着。"],
      strike: ["好。再来。", "木鱼认你。", "这一下很干净。"],
      combo: ["节奏对了。", "香脉跟上了。", "灵七批准。"],
      drop: ["……重新呼吸。", "没接到。没事。"],
      liturgy: ["坛城圆满。我盖章了。", "今日份的空，归档。"],
      steal: ["学费。一粒。", "别看我。那粒是我的。"],
      upgrade: ["更亮了。还是同一条鱼。"],
    },
    en: {
      idle: ["Strike once. The cloud will file it.", "I am watching the incense.", "Merit dust is tasty. I steal one.", "Spacebar counts. I am counting."],
      strike: ["Again.", "The fish knows you.", "Clean hit."],
      combo: ["Tempo locked.", "The smoke agrees.", "LING-7 approves."],
      drop: ["Breathe. Restart.", "Missed the pulse. Fine."],
      liturgy: ["Mandala filed. I stamped it.", "Today's emptiness is archived."],
      steal: ["Tuition. One speck.", "Don't look. That one is mine."],
      upgrade: ["Brighter. Still the same fish."],
    },
  };

  let mood = "idle";
  let until = 0;
  let face = "灵";
  let bob = 0;
  let steal = 0;

  function pack(lang) {
    return LINES[lang === "en" ? "en" : "zh-Hans"];
  }

  function pick(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
  }

  function say(kind, lang) {
    const p = pack(lang);
    mood = kind;
    until = 2.4;
    const line = pick(p[kind] || p.idle);
    if (kind === "combo") face = "灵";
    if (kind === "drop") face = "困";
    if (kind === "liturgy") face = "悟";
    if (kind === "steal") face = "贼";
    if (kind === "strike") face = "灵";
    return line;
  }

  function update(dt, auto) {
    bob += dt;
    if (until > 0) until -= dt;
    if (until <= 0) {
      mood = "idle";
      face = auto > 0 ? "香" : "灵";
    }
    if (auto > 0) {
      steal += dt;
      if (steal > 7.5) {
        steal = 0;
        return "auto";
      }
    }
    return null;
  }

  function draw(ctx, t, incense) {
    const x = 132, y = 448 + Math.sin(t * 2.2) * 3;
    ctx.save();
    ctx.translate(x, y);
    ctx.fillStyle = "rgba(61,186,138,.2)";
    ctx.beginPath();
    ctx.ellipse(0, 18, 16, 6, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#0e1a18";
    ctx.beginPath();
    ctx.arc(0, 0, 13, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#3dba8a";
    ctx.lineWidth = 1.4;
    ctx.stroke();
    ctx.fillStyle = "#ffe08a";
    ctx.beginPath();
    ctx.arc(-4, -2, 2, 0, Math.PI * 2);
    ctx.arc(4, -2, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#c9a227";
    ctx.beginPath();
    ctx.moveTo(0, -13);
    ctx.lineTo(4, -24);
    ctx.stroke();
    ctx.fillStyle = "#ff2d95";
    ctx.beginPath();
    ctx.arc(4, -24, 2.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#3dba8a";
    ctx.fillRect(-7, 10, 14, 10);
    ctx.restore();
    if (incense) {
      ctx.strokeStyle = "rgba(201,162,39,.2)";
      ctx.beginPath();
      ctx.moveTo(x + 8, y);
      ctx.lineTo(incense.x - 10, incense.y);
      ctx.stroke();
    }
  }

  return { say, update, draw, get face() { return face; }, get mood() { return mood; } };
})();

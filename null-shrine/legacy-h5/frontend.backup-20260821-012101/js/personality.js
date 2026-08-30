/* ===== 运气人格生成器（自我验证 + 传播卡片）· i18n 支持 ===== */

// 统计维度
const STATS = {
  shots: 0,          // 总发射数
  jackpots: 0,       // 大吉（演出）次数
  reds: 0,           // 红区次数
  normals: 0,        // 普通入槽
  nearMisses: 0,     // 近失次数
  lost: 0,           // 空心
  bestStreak: 0,     // 当前连中
  maxStreak: 0,
};

// 人格库：nameKey/descKey 为 i18n key（渲染时翻译）
const PERSONAS = [
  {
    nameKey: "p.edge",
    emoji: "🌀",
    match: s => s.shots >= 5 && (s.nearMisses / Math.max(1, s.shots)) > 0.28,
    descKey: "p.edge.desc",
    color: "#b9a7ff",
  },
  {
    nameKey: "p.deity",
    emoji: "⚡",
    match: s => s.jackpots >= 3 || (s.jackpots > 0 && s.jackpots / Math.max(1, s.shots) > 0.22),
    descKey: "p.deity.desc",
    color: "#ff9ec7",
  },
  {
    nameKey: "p.strategist",
    emoji: "🧠",
    match: s => s.shots >= 10 && s.nearMisses / Math.max(1, s.shots) < 0.2 && s.lost / Math.max(1, s.shots) < 0.25,
    descKey: "p.strategist.desc",
    color: "#9fd9ff",
  },
  {
    nameKey: "p.occult",
    emoji: "🔮",
    match: s => s.shots >= 8 && (s.lost / Math.max(1, s.shots)) > 0.4,
    descKey: "p.occult.desc",
    color: "#a58cff",
  },
  {
    nameKey: "p.collector",
    emoji: "📖",
    match: s => s.maxStreak >= 3 && s.jackpots + s.reds >= 4,
    descKey: "p.collector.desc",
    color: "#ffd9a0",
  },
];

// 近失判定：珠子在到达 jackpot 槽之前"擦肩而过"（由 game.js 调用）
function isNearMiss(ball) {
  // 简化：球在槽区上方、x 落在 jackpot 槽边缘 ±14px、且即将进入普通槽
  const jp = WORLD.pockets.filter(p => p.kind === "jackpot");
  return jp.some(p => Math.abs(ball.x - p.cx) < 16 && ball.x > p.x0 - 2 && ball.x < p.x0 + p.w + 2);
}

function evalPersona() {
  if (STATS.shots === 0) return null;
  let best = PERSONAS[PERSONAS.length - 1];
  for (const p of PERSONAS) {
    if (p.match(STATS)) { best = p; break; }
  }
  return best;
}

function personaData() {
  const p = evalPersona();
  if (!p) return null;
  const hitRate = ((STATS.jackpots + STATS.reds + STATS.normals) / STATS.shots * 100).toFixed(0);
  return {
    ...p,
    name: t(p.nameKey),
    desc: t(p.descKey),
    stats: {
      "s.shots": STATS.shots,
      "s.hitRate": hitRate + "%",
      "s.showcases": STATS.jackpots,
      "s.nearMisses": STATS.nearMisses,
      "s.maxStreak": STATS.maxStreak,
      "s.missed": STATS.lost,
    }
  };
}

function shareText() {
  const d = personaData();
  if (!d) return null;
  return [
    t("share.head", { emoji: d.emoji, name: d.name }),
    t("share.place"),
    "📊 " + Object.entries(d.stats).map(([k, v]) => t(k) + " " + v).join(" · "),
    t("share.cta"),
  ].join("\n");
}

/* NULL//SHRINE — Cyber-Shrine Relics & Ethereal Keepsakes */
const RELICS = (() => {
  const STORAGE = "ns_relics_v1";
  const ORBS = [
    { id: "orb_null", nameKey: "relic.orb.null", trail: "absorb", audio: "crystal", unlock: "start" },
    { id: "orb_aurora", nameKey: "relic.orb.aurora", trail: "neon_ribbon", audio: "crystal", unlock: "jackpot1" },
    { id: "orb_bowl", nameKey: "relic.orb.bowl", trail: "smoke_ring", audio: "bowl", unlock: "chain6" },
  ];
  const SIGILS = [
    { id: "sigil_none", nameKey: "relic.sigil.none", passive: null, unlock: "start" },
    { id: "sigil_bun", nameKey: "relic.sigil.bun", passive: "rift_save", unlock: "near3" },
    { id: "sigil_bell", nameKey: "relic.sigil.bell", passive: "chord_mult", unlock: "challenge" },
    { id: "sigil_overdrive", nameKey: "relic.sigil.overdrive", passive: "flip_mult", unlock: "cores3" },
  ];
  const THEMES = [
    { id: "theme_void", nameKey: "relic.theme.void", palette: ["#07040c", "#3dfff3", "#ff2d6a"], unlock: "start" },
    { id: "theme_rain", nameKey: "relic.theme.rain", palette: ["#0d1117", "#58a6ff", "#8b5cff"], unlock: "shots20" },
    { id: "theme_bamboo", nameKey: "relic.theme.bamboo", palette: ["#04140f", "#3dff9a", "#c8ff7a"], unlock: "vault50" },
    { id: "theme_flare", nameKey: "relic.theme.flare", palette: ["#1a0a08", "#ffc53d", "#ff5d86"], unlock: "jackpot3" },
  ];

  const APHORISMS = {
    en: [
      "Noise cleared {pct}%. Sleep early. Skip the spiral.",
      "Silence is a strategy, not a defeat.",
      "You threw the noise into the void. Keep the quiet.",
      "Resonance {res}. The shrine remembers soft persistence.",
      "No overtime tonight. The cabinet already worked for you.",
    ],
    "zh-Hans": [
      "杂念消除 {pct}%。宜早睡，忌内耗。",
      "沉默是策略，不是认输。",
      "你把噪音扔进了虚无。把安静留下。",
      "共振 {res}。神社记得温柔的坚持。",
      "今晚不要加班。机台已经替你忙过了。",
    ],
    "zh-Hant": [
      "雜念消除 {pct}%。宜早睡，忌內耗。",
      "沉默是策略，不是認輸。",
      "你把噪音扔進了虛無。把安靜留下。",
      "共振 {res}。神社記得溫柔的堅持。",
      "今晚不要加班。機台已經替你忙過了。",
    ],
    es: [
      "Ruido eliminado {pct}%. Duerme temprano. Evita la espiral.",
      "El silencio es estrategia, no derrota.",
      "Lanzaste el ruido al vacío. Quédate con la calma.",
      "Resonancia {res}. El santuario recuerda la constancia suave.",
      "Sin horas extra hoy. El gabinete ya trabajó por ti.",
    ],
    fr: [
      "Bruit dissipé {pct}%. Dors tôt. Évite la spirale.",
      "Le silence est une stratégie, pas une défaite.",
      "Tu as jeté le bruit dans le vide. Garde le calme.",
      "Résonance {res}. Le sanctuaire se souvient de la douce persistance.",
      "Pas d’heures sup ce soir. Le cabinet a déjà travaillé pour toi.",
    ],
    ja: [
      "雑念消去 {pct}%。早く寝よう。内耗は禁物。",
      "沈黙は敗北ではなく戦略。",
      "ノイズを虚無へ投げた。静けさを残せ。",
      "共振 {res}。神社は柔らかな継続を覚えている。",
      "今夜は残業なし。筐体が代わりに働いた。",
    ],
  };

  const BOONS = [
    { id: "boon_split", nameKey: "boon.split", descKey: "boon.split.desc", kind: "split" },
    { id: "boon_rift", nameKey: "boon.rift", descKey: "boon.rift.desc", kind: "rift" },
    { id: "boon_wave", nameKey: "boon.wave", descKey: "boon.wave.desc", kind: "wave" },
  ];

  function load() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE) || "null") || defaultState();
    } catch (e) {
      return defaultState();
    }
  }

  function defaultState() {
    return {
      unlocked: { orb_null: true, sigil_none: true, theme_void: true },
      equipped: { orb: "orb_null", sigil: "sigil_none", theme: "theme_void" },
      cards: [],
      stats: { jackpots: 0, near: 0, shots: 0, vaultPeak: 0, cores: 0, challenges: 0, chainMax: 0 },
    };
  }

  let data = load();

  function save() {
    try { localStorage.setItem(STORAGE, JSON.stringify(data)); } catch (e) {}
  }

  function unlock(id) {
    if (data.unlocked[id]) return false;
    data.unlocked[id] = true;
    save();
    return true;
  }

  function equip(slot, id) {
    if (!data.unlocked[id]) return false;
    data.equipped[slot] = id;
    save();
    return true;
  }

  function evaluateUnlocks(extra = {}) {
    const s = data.stats;
    Object.assign(s, extra);
    const gained = [];
    const rules = [
      ["orb_aurora", s.jackpots >= 1],
      ["orb_bowl", s.chainMax >= 6],
      ["sigil_bun", s.near >= 3],
      ["sigil_bell", s.challenges >= 1],
      ["sigil_overdrive", s.cores >= 3],
      ["theme_rain", s.shots >= 20],
      ["theme_bamboo", s.vaultPeak >= 50],
      ["theme_flare", s.jackpots >= 3],
    ];
    for (const [id, ok] of rules) {
      if (ok && unlock(id)) gained.push(id);
    }
    return gained;
  }

  function aphorism(seed, pct, res) {
    const lang = (typeof getLang === "function" ? getLang() : "en");
    const pool = APHORISMS[lang] || APHORISMS.en;
    let h = 0;
    const str = String(seed || "SEED");
    for (let i = 0; i < str.length; i++) h = (h * 33 + str.charCodeAt(i)) >>> 0;
    const line = pool[h % pool.length]
      .replace("{pct}", String(pct))
      .replace("{res}", String(res));
    return { id: "card_" + (h % 1000).toString().padStart(3, "0"), line };
  }

  function addCard(card) {
    if (data.cards.some(c => c.seed === card.seed && c.line === card.line)) return false;
    data.cards.unshift(card);
    if (data.cards.length > 48) data.cards.length = 48;
    save();
    return true;
  }

  function pickBoons(n = 3) {
    const pool = BOONS.slice();
    for (let i = pool.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [pool[i], pool[j]] = [pool[j], pool[i]];
    }
    return pool.slice(0, n);
  }

  function orb() { return ORBS.find(o => o.id === data.equipped.orb) || ORBS[0]; }
  function sigil() { return SIGILS.find(o => o.id === data.equipped.sigil) || SIGILS[0]; }
  function theme() { return THEMES.find(o => o.id === data.equipped.theme) || THEMES[0]; }

  return {
    ORBS, SIGILS, THEMES, BOONS,
    get data() { return data; },
    save, unlock, equip, evaluateUnlocks, aphorism, addCard, pickBoons,
    orb, sigil, theme,
    isUnlocked: id => !!data.unlocked[id],
  };
})();

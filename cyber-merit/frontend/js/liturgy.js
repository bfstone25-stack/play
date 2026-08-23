const LITURGY = (() => {
  const TRACKS = {
    fish: { max: 4, base: 40, grow: 2.2 },
    hand: { max: 4, base: 60, grow: 2.4 },
    altar: { max: 2, base: 120, grow: 3 },
    city: { max: 3, base: 80, grow: 2.1 },
    mandala: { max: 3, base: 100, grow: 2.3 },
  };
  const CHARMS = [
    { id: "lotus", rarity: "N", zh: "纸符", en: "Paper charm" },
    { id: "arm", rarity: "SR", zh: "机械臂", en: "Mech arm" },
    { id: "goldfish", rarity: "SSR", zh: "金木鱼", en: "Gold fish" },
    { id: "bead", rarity: "R", zh: "电念珠", en: "LED beads" },
    { id: "incense", rarity: "R", zh: "数据香", en: "Data incense" },
  ];
  const OFUDA_COST = 80;
  const PULSE_PERIOD = 1.22;
  const PULSE_WINDOW = 0.16;

  const state = {
    merit: 0,
    clicks: 0,
    combo: 0,
    comboBest: 0,
    liturgyCount: 0,
    fill: 0,
    lastDay: "",
    lastIdleAt: 0,
    upgrades: { fish: 0, hand: 0, altar: 0, city: 0, mandala: 0 },
    charms: [],
    settings: { audio: true, motion: true, haptics: true },
    lang: "zh-Hans",
    pulseT: 0,
    lastCompleteDay: "",
  };

  function need() {
    return 36 + state.liturgyCount * 7 + state.upgrades.mandala * 8;
  }

  function autoRate() {
    const hand = state.upgrades.hand;
    const auto = hand >= 3 ? (hand - 2) * 0.55 + state.upgrades.fish * 0.08 : 0;
    return auto * Math.pow(1.08, state.upgrades.fish);
  }

  function clickGain() {
    const fish = state.upgrades.fish;
    const base = Math.max(1, Math.round((1 + fish) * Math.pow(1.25, fish)));
    const combo = 1 + state.combo * 0.15;
    const hand = 1 + state.upgrades.hand * 0.12;
    return Math.max(1, Math.floor(base * combo * hand));
  }

  function fillGain(perfect) {
    return (perfect ? 1.8 : 1) * (1 + state.combo * 0.35) * (1 + state.upgrades.mandala * 0.25);
  }

  function cost(track, level) {
    const spec = TRACKS[track];
    if (!spec) return Infinity;
    return Math.floor(spec.base * Math.pow(spec.grow, level));
  }

  function pulsePhase() {
    return (state.pulseT % PULSE_PERIOD) / PULSE_PERIOD;
  }

  function inWindow() {
    const p = pulsePhase();
    const peak = 0.5;
    return Math.abs(p - peak) <= (PULSE_WINDOW / PULSE_PERIOD);
  }

  function strike() {
    const perfect = inWindow();
    if (perfect) {
      state.combo += 1;
      if (state.combo > state.comboBest) state.comboBest = state.combo;
    } else {
      state.combo = 0;
    }
    const gain = clickGain();
    state.merit += gain;
    state.clicks += 1;
    state.fill += fillGain(perfect);
    let complete = false;
    if (state.fill >= need()) {
      complete = true;
      state.fill = 0;
      state.liturgyCount += 1;
      state.lastCompleteDay = KOANS.dayKey();
      state.merit += 12 + state.liturgyCount * 2;
    }
    return { gain, perfect, combo: state.combo, complete, need: need(), fill: state.fill };
  }

  function tick(dt) {
    state.pulseT += dt;
    const rate = autoRate();
    if (rate <= 0) return 0;
    const gain = rate * dt;
    state.merit += gain;
    state.fill += gain * 0.12;
    if (state.fill >= need()) {
      state.fill = 0;
      state.liturgyCount += 1;
    }
    return gain;
  }

  function applyIdle(now) {
    const t = now || Date.now();
    if (!state.lastIdleAt) {
      state.lastIdleAt = t;
      return 0;
    }
    const elapsed = Math.max(0, Math.min(8 * 3600, (t - state.lastIdleAt) / 1000));
    state.lastIdleAt = t;
    const gain = autoRate() * elapsed * 0.65;
    if (gain > 0) state.merit += gain;
    return gain;
  }

  function tryUpgrade(track) {
    const spec = TRACKS[track];
    if (!spec) return false;
    const lv = state.upgrades[track] || 0;
    if (lv >= spec.max) return false;
    const c = cost(track, lv);
    if (state.merit < c) return false;
    state.merit -= c;
    state.upgrades[track] = lv + 1;
    return true;
  }

  function pullOfuda(rng) {
    rng = rng || Math.random;
    if (state.merit < OFUDA_COST) return null;
    state.merit -= OFUDA_COST;
    const item = CHARMS[Math.floor(rng() * CHARMS.length) % CHARMS.length];
    state.charms.push({ ...item, at: state.clicks });
    return item;
  }

  function snapshot() {
    return {
      merit: Math.floor(state.merit),
      clicks: state.clicks,
      combo: state.combo,
      comboBest: state.comboBest,
      liturgyCount: state.liturgyCount,
      fill: state.fill,
      need: need(),
      auto: autoRate(),
      upgrades: { ...state.upgrades },
      charms: state.charms.slice(),
      settings: { ...state.settings },
      lang: state.lang,
      lastCompleteDay: state.lastCompleteDay,
      pulse: pulsePhase(),
      inWindow: inWindow(),
    };
  }

  function load(data) {
    if (!data) return snapshot();
    state.merit = Math.max(0, Number(data.merit) || 0);
    state.clicks = Math.max(0, Math.floor(data.clicks) || 0);
    state.combo = 0;
    state.comboBest = Math.max(0, Math.floor(data.comboBest) || 0);
    state.liturgyCount = Math.max(0, Math.floor(data.liturgyCount) || 0);
    state.fill = Math.max(0, Number(data.fill) || 0);
    state.lastIdleAt = Number(data.lastIdleAt) || Date.now();
    const u = data.upgrades || {};
    Object.keys(TRACKS).forEach((k) => {
      const max = TRACKS[k].max;
      let lv = Math.max(0, Math.floor(u[k]) || 0);
      if (k === "fish" && !u.fish && data.level) lv = Math.min(max, Math.max(0, (data.level | 0) - 1));
      state.upgrades[k] = Math.min(max, lv);
    });
    state.charms = Array.isArray(data.charms) ? data.charms.slice() : [];
    state.settings = Object.assign({ audio: true, motion: true, haptics: true }, data.settings || {});
    state.lang = data.lang === "en" ? "en" : "zh-Hans";
    state.lastCompleteDay = data.lastCompleteDay || "";
    return snapshot();
  }

  function persistable() {
    const s = snapshot();
    return {
      merit: s.merit,
      clicks: s.clicks,
      comboBest: s.comboBest,
      liturgyCount: s.liturgyCount,
      fill: s.fill,
      lastIdleAt: Date.now(),
      upgrades: s.upgrades,
      charms: s.charms,
      settings: s.settings,
      lang: state.lang,
      lastCompleteDay: state.lastCompleteDay,
    };
  }

  function setSetting(k, v) { state.settings[k] = !!v; }
  function setLang(code) { state.lang = code === "en" ? "en" : "zh-Hans"; }

  return {
    TRACKS, CHARMS, OFUDA_COST, PULSE_PERIOD, PULSE_WINDOW,
    strike, tick, applyIdle, tryUpgrade, pullOfuda, cost, need,
    snapshot, load, persistable, setSetting, setLang,
    pulsePhase, inWindow, clickGain, autoRate, fillGain,
  };
})();

(function () {
  "use strict";

  const editions = {
    en: {
      id: "en", locale: "en", label: "EN", contentSet: "en",
      localTitle: "", title: "FLUTTER — He remembers you",
      tagline: "He remembers you",
      palette: {bg0:"#130a0f", bg1:"#4b1728", bg2:"#211019", glowA:"#d59a82", glowB:"#955069", ink:"#f8eee9", muted:"#d1b9b6", cardA:"#572033", cardB:"#29131e"},
      typography: "'Avenir Next','Helvetica Neue',Inter,Arial,sans-serif",
      motion: "cinematic", feedback: "restrained"
    },
    es: {
      id: "es", locale: "es", label: "ES", contentSet: "es",
      localTitle: "LATIDO", title: "FLUTTER · LATIDO — Él te recuerda",
      tagline: "Él te recuerda",
      palette: {bg0:"#200b14", bg1:"#6b1e32", bg2:"#2a1024", glowA:"#ff8a5b", glowB:"#d83c6b", ink:"#fff1e8", muted:"#e6bdb8", cardA:"#7b2c3f", cardB:"#3a1728"},
      typography: "'Avenir Next','Helvetica Neue',Inter,Arial,sans-serif",
      motion: "dramatic", feedback: "expressive"
    },
    "pt-BR": {
      id: "pt-BR", locale: "pt-BR", label: "PT", contentSet: "pt",
      localTitle: "ENTRE NÓS", title: "FLUTTER · ENTRE NÓS — Ele se lembra de você",
      tagline: "Ele se lembra de você",
      palette: {bg0:"#102018", bg1:"#315f4a", bg2:"#142834", glowA:"#f2a65a", glowB:"#42a88b", ink:"#fff4df", muted:"#d7c9ac", cardA:"#39644f", cardB:"#19352e"},
      typography: "'Avenir Next','Helvetica Neue',Inter,Arial,sans-serif",
      motion: "alive", feedback: "warm"
    },
    zh: {
      id: "zh", locale: "zh-CN", label: "中文", contentSet: "zh",
      localTitle: "怦然", title: "FLUTTER · 怦然 — 他真的会记得你",
      tagline: "他，真的会记得你",
      palette: {bg0:"#24131e", bg1:"#694052", bg2:"#261b31", glowA:"#f09bb9", glowB:"#b68bd4", ink:"#fff0f3", muted:"#dfbdc9", cardA:"#f7dce6", cardB:"#e9c1d2"},
      typography: "'PingFang SC','Hiragino Sans GB','Microsoft YaHei',sans-serif",
      motion: "dreamy", feedback: "sweet"
    },
    ja: {
      id: "ja", locale: "ja", label: "日本語", contentSet: "ja",
      localTitle: "あわい", title: "FLUTTER · あわい — あなたを、覚えている",
      tagline: "あなたを、覚えている",
      palette: {bg0:"#17191d", bg1:"#31373c", bg2:"#1d2128", glowA:"#c99ca5", glowB:"#778a9a", ink:"#f1efeb", muted:"#bbb8b2", cardA:"#3a3c40", cardB:"#24272c"},
      typography: "'Hiragino Sans','Yu Gothic UI','Noto Sans JP',sans-serif",
      motion: "quiet", feedback: "subtle"
    }
  };
  const order = ["en", "es", "pt-BR", "zh", "ja"];
  const aliases = {pt:"pt-BR", "pt-br":"pt-BR", "zh-cn":"zh", "zh-hans":"zh"};

  function normalize(value) {
    const raw = String(value || "").trim();
    if (editions[raw]) return raw;
    const low = raw.toLowerCase();
    if (aliases[low]) return aliases[low];
    const base = low.split("-")[0];
    return aliases[base] || (editions[base] ? base : "en");
  }
  function detect() {
    try {
      const saved = localStorage.getItem("flutter_edition");
      if (saved) return normalize(saved);
    } catch (_) {}
    return normalize(navigator.language);
  }
  function apply(id) {
    const edition = editions[normalize(id)];
    const root = document.documentElement;
    root.lang = edition.locale;
    root.dataset.edition = edition.id;
    root.dataset.motion = edition.motion;
    root.dataset.feedback = edition.feedback;
    Object.entries(edition.palette).forEach(([key, value]) => root.style.setProperty("--edition-"+key, value));
    root.style.setProperty("--edition-font", edition.typography);
    document.title = edition.title;
    try { localStorage.setItem("flutter_edition", edition.id); } catch (_) {}
    return edition;
  }

  window.FLUTTER_EDITIONS = {editions, order, normalize, detect, apply};
})();

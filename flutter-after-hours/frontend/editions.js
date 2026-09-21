(function () {
  "use strict";

  const editions = {
    en: {
      id: "en", locale: "en", label: "EN", contentSet: "en",
      localTitle: "AFTER HOURS", title: "FLUTTER: AFTER HOURS — He remembers what you told him",
      tagline: "He remembers what you told him",
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
    /* The zh entry was inherited from the parent verbatim, and shipping it that way
       broke the fork rule in the most literal place there is: switching to 中文 put
       "FLUTTER · 怦然 — 他真的会记得你" on the brand screen, which is the ALL-AGES
       game's name and tagline, on the 18+ build, under a candy-pink palette
       (cardA #f7dce6) taken from the same place. STANDARD.md: an adult fork differs
       from its parent in name, composition, character and palette; PLICATA is not
       "FOLD: After Dark".
       So zh gets the fork's own name the way en did -- 熄灯之后, "after the lights go
       out", which is the image the English routes keep returning to (Ethan's top-floor
       light, off for the first time in eleven years) and is not a decoration of 怦然 --
       and the fork's saturated plum in place of the parent's candy.
       NAMES ARE BLAZE'S CALL. This one is reported for his eye; what could not stay is
       the parent's name on the adult build. */
    zh: {
      id: "zh", locale: "zh-CN", label: "中文", contentSet: "zh",
      localTitle: "熄灯之后", title: "熄灯之后 — 他记得你说过的每一句话",
      tagline: "他记得你说过的每一句话",
      palette: {bg0:"#130a0f", bg1:"#4b1728", bg2:"#211019", glowA:"#e0a07f", glowB:"#a2506c", ink:"#f8eee9", muted:"#d6b9bd", cardA:"#5a2035", cardB:"#2a131f"},
      typography: "'PingFang SC','Hiragino Sans GB','Microsoft YaHei',sans-serif",
      motion: "cinematic", feedback: "restrained"
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
  /* The parent ships five market editions. This fork's content pack is English
   * only — backend/stories_x/*.json carries `*_en` and the route list is
   * filtered by content language in app.py:routes(), so asking the backend for
   * any other edition returns ZERO routes and the player lands on an empty
   * route grid with no way back. Verified against the running backend:
   *   en -> 6 routes, zh/ja/es/pt-BR -> 0.
   * So the picker offers only what the content pack actually has. The other
   * four definitions stay (palette, typography, motion) because the zh pack is
   * mostly a matter of deriving it from the parent's `*_zh`, which is already
   * written — when that lands, add the id back to this list and nothing else
   * changes. */
  /* 2026-09-21: zh joins en. The hole was never the palette or the UI strings —
   * both have existed here since the parent — it was the CONTENT: the fork's own
   * additions (beat.text, the adult turn, the lane openers, the holds, the
   * declines, the cast note, the coda) were authored in English only, so a zh
   * player would have met an English paragraph at every beat while `_field()`
   * fell back to `_en`. tools/derive_zh.py is that missing pack, and after
   * re-deriving, ethan/guyan/luxingye/fushen measure 100% real Chinese on every
   * localized field.
   *
   * liam and adrian are NOT in it, and are gated off in backend/chars.json
   * rather than here: their `_zh` fields in the PARENT hold English text (38 of
   * 123 fields on liam are real Chinese; `title_zh` is literally "the
   * firefighter next door"). Offering them would be Floor 13's ja/ko/es failure
   * with the languages swapped. */
  const SHIPPED = ["en", "zh"];
  const order = SHIPPED.slice();
  const aliases = {pt:"pt-BR", "pt-br":"pt-BR", "zh-cn":"zh", "zh-hans":"zh"};

  function normalize(value) {
    const raw = String(value || "").trim();
    let id;
    if (editions[raw]) id = raw;
    else {
      const low = raw.toLowerCase();
      const base = low.split("-")[0];
      id = aliases[low] || aliases[base] || (editions[base] ? base : "en");
    }
    // Clamp to a shipped edition. detect() reads navigator.language, so a
    // zh-CN or ja browser would otherwise be sent straight to the empty grid
    // without ever touching the picker.
    return SHIPPED.indexOf(id) === -1 ? "en" : id;
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

  window.FLUTTER_EDITIONS = {editions, order, normalize, detect, apply, SHIPPED};
})();

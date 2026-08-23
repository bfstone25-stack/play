const I18N = (() => {
  let lang = "zh-Hans";
  const dict = { "zh-Hans": {}, en: {} };

  function register(bundle) {
    Object.keys(bundle || {}).forEach((code) => {
      dict[code] = dict[code] || {};
      Object.assign(dict[code], bundle[code]);
    });
  }

  function t(key, vars) {
    const table = dict[lang] || dict.en || {};
    let s = table[key] || (dict.en && dict.en[key]) || key;
    if (vars) {
      Object.keys(vars).forEach((k) => {
        s = s.replace(new RegExp("\\{" + k + "\\}", "g"), String(vars[k]));
      });
    }
    return s;
  }

  function apply() {
    document.documentElement.lang = lang === "en" ? "en" : "zh-Hans";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      el.textContent = t(el.getAttribute("data-i18n"));
    });
    document.querySelectorAll(".lang-btn").forEach((btn) => {
      btn.classList.toggle("active", btn.getAttribute("data-lang") === lang);
    });
  }

  function setLang(code) {
    lang = code === "en" ? "en" : "zh-Hans";
    apply();
    return lang;
  }

  register({
    "zh-Hans": {
      "ui.cabinet": "CABINET 07 · CYBER MERIT",
      "ui.lore": "敲一记全息木鱼，把功德上传云端",
      "ui.ready": "READY",
      "ui.merit": "功德",
      "ui.combo": "COMBO",
      "ui.liturgy": "今日坛城",
      "ui.auto": "梵烟",
      "ui.lingTitle": "LING-7 · 灵七",
      "ui.shopTag": "龛",
      "ui.shop": "升级",
      "ui.strike": "敲",
      "ui.strikeHint": "点木鱼 / 空格",
      "ui.koanTag": "偈",
      "ui.koan": "今日偈",
      "intro.eyebrow": "BLAZECORE PLAY · CABINET 07",
      "intro.sub": "全息手敲木鱼。功德粒子螺旋升入数字莲花与电路坛城。",
      "intro.go": "入龛",
      "shop.eyebrow": "ALTAR UPGRADES",
      "shop.title": "装点神龛",
      "shop.lead": "功德换形，不换本质。木鱼还是木鱼。",
      "shop.ofuda": "挂一纸符 · 80 功德",
      "shop.max": "已满级",
      "shop.need": "功德不足",
      "koan.eyebrow": "DAILY KOAN",
      "card.share": "分享功德卡",
      "card.close": "收下",
      "card.eyebrow": "MERIT CARD",
      "card.download": "保存卡片",
      "card.dismiss": "合上",
      "set.eyebrow": "NOVICE PREFS",
      "set.title": "设置",
      "set.audio": "梵音",
      "set.motion": "镜头冲击",
      "set.haptics": "触觉",
      "toast.liturgy": "坛城圆满 · 今日功德已归档",
      "toast.ofuda": "纸符已挂上神龛：{name}",
      "toast.up": "神龛更亮了一寸",
      "track.fish": "木鱼",
      "track.hand": "全息手",
      "track.altar": "神龛",
      "track.city": "夜城",
      "track.mandala": "坛城",
      "fish.0": "古木", "fish.1": "朱漆", "fish.2": "古铜", "fish.3": "翠电路", "fish.4": "全息鱼",
      "hand.0": "残影", "hand.1": "实体", "hand.2": "金络", "hand.3": "双手", "hand.4": "自动僧伽",
      "altar.0": "街摊", "altar.1": "霓虹龛", "altar.2": "天寺",
      "city.0": "小巷", "city.1": "霓虹区", "city.2": "雨城", "city.3": "飞行车道",
      "mandala.0": "单莲", "mandala.1": "双环", "mandala.2": "电路坛城", "mandala.3": "万花",
    },
    en: {
      "ui.cabinet": "CABINET 07 · CYBER MERIT",
      "ui.lore": "Strike the holo-fish. Upload merit to the cloud.",
      "ui.ready": "READY",
      "ui.merit": "MERIT",
      "ui.combo": "COMBO",
      "ui.liturgy": "TODAY'S MANDALA",
      "ui.auto": "INCENSE",
      "ui.lingTitle": "LING-7 · NOVICE",
      "ui.shopTag": "ALTAR",
      "ui.shop": "UPGRADE",
      "ui.strike": "STRIKE",
      "ui.strikeHint": "tap fish / space",
      "ui.koanTag": "KOAN",
      "ui.koan": "TODAY",
      "intro.eyebrow": "BLAZECORE PLAY · CABINET 07",
      "intro.sub": "A holographic hand strikes the wooden fish. Golden merit spirals into digital lotuses.",
      "intro.go": "ENTER",
      "shop.eyebrow": "ALTAR UPGRADES",
      "shop.title": "Dress the shrine",
      "shop.lead": "Merit changes the form, never the fish.",
      "shop.ofuda": "Hang an ofuda · 80 merit",
      "shop.max": "MAX",
      "shop.need": "Not enough merit",
      "koan.eyebrow": "DAILY KOAN",
      "card.share": "Share merit card",
      "card.close": "Keep",
      "card.eyebrow": "MERIT CARD",
      "card.download": "Save card",
      "card.dismiss": "Close",
      "set.eyebrow": "NOVICE PREFS",
      "set.title": "Settings",
      "set.audio": "Fan-yin pad",
      "set.motion": "Camera punch",
      "set.haptics": "Haptics",
      "toast.liturgy": "Mandala complete · today's merit filed",
      "toast.ofuda": "Ofuda hung: {name}",
      "toast.up": "The shrine brightens a little",
      "track.fish": "Fish",
      "track.hand": "Holo hand",
      "track.altar": "Altar",
      "track.city": "City",
      "track.mandala": "Mandala",
      "fish.0": "Old wood", "fish.1": "Lacquer", "fish.2": "Temple bronze", "fish.3": "Jade circuit", "fish.4": "Holo fish",
      "hand.0": "Mesh", "hand.1": "Solid", "hand.2": "Gold circuit", "hand.3": "Twin", "hand.4": "Auto sangha",
      "altar.0": "Street stall", "altar.1": "Neon shrine", "altar.2": "Sky temple",
      "city.0": "Alley", "city.1": "Neon ward", "city.2": "Rain city", "city.3": "Skylane",
      "mandala.0": "One lotus", "mandala.1": "Twin rings", "mandala.2": "PCB mandala", "mandala.3": "Myriad",
    },
  });

  return { register, t, setLang, apply, getLang: () => lang };
})();

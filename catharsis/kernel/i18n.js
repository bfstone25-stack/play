const I18N = (() => {
  let lang = "en";
  let dict = {};

  function t(key, vars) {
    let s = (dict[lang] && dict[lang][key]) || (dict["en"] && dict["en"][key]) || key;
    if (vars) {
      Object.keys(vars).forEach(k => {
        s = s.replace(new RegExp("\\{" + k + "\\}", "g"), String(vars[k]));
      });
    }
    return s;
  }

  function setLang(code) {
    lang = dict[code] ? code : "en";
    return lang;
  }

  function register(pack) {
    dict = pack || {};
  }

  function current() { return lang; }

  // Which language should a player see? English-first: only a zh browser gets Chinese
  // unless the player asked otherwise. Order: explicit ?lang= in the URL, then the
  // choice stored under `key` (the in-game EN/中 toggle writes it), then the browser.
  // Returns `zh` or `en` (the caller maps `zh` onto its own pack code, e.g. "zh-Hans").
  function detect(key) {
    let pick = "";
    try {
      const q = new URLSearchParams(location.search).get("lang");
      if (q) pick = q;
    } catch (e) {}
    if (!pick && key) {
      try { pick = localStorage.getItem(key) || ""; } catch (e) {}
    }
    if (!pick) {
      let langs = [];
      try { langs = (navigator.languages && navigator.languages.length) ? navigator.languages : [navigator.language || ""]; } catch (e) {}
      pick = langs[0] || "en";
    }
    return /^zh/i.test(String(pick).trim()) ? "zh" : "en";
  }

  function remember(key, code) {
    try { localStorage.setItem(key, code); } catch (e) {}
  }

  return { t, setLang, register, current, detect, remember };
})();

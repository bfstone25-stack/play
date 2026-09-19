const I18N = (() => {
  let lang = "zh-Hans";
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

  return { t, setLang, register, current };
})();

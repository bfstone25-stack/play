var PHRASES = (() => {
  /* Short CJK/kana only — ofuda are vertical. Never ship a horizontal sentence. */
  const JA = {
    ok: ["了解", "承知", "問題無", "一旦"],
    sync: ["共有", "確認", "摺合せ", "後ほど"],
    cc: ["展開", "上長", "共有済", "ご査収"],
    own: ["担当", "確認頼", "見解は", "宜しく"],
    group: ["招集", "会議", "全員", "部屋"],
    loop: ["完了", "締め", "宿題", "論点"],
    power: ["推進", "粒度", "工数", "活用"],
    family: ["一丸", "悪気無", "上も大変", "念の為"],
    bless: ["残業", "成長", "簡単", "土日"],
    rush: ["急ぎ", "本日中", "大至急", "先方待"],
    knife: ["当方無", "既知では", "今は無", "工数無"],
    stamp: ["御査収", "既読", "確認印", "奉納"],
  };
  const ZH = {
    ok: ["好的", "收到", "嗯嗯", "先这样"],
    sync: ["对齐", "同步", "拉会", "复盘"],
    cc: ["抄送", "上意", "同步了", "请查收"],
    own: ["你跟", "你看", "你来", "怎么看"],
    group: ["拉群", "开会", "全员", "圈人"],
    loop: ["闭环", "沉淀", "抓手", "收口"],
    power: ["赋能", "颗粒", "工时", "杠杆"],
    family: ["一家", "无恶意", "上边难", "提醒"],
    bless: ["加班福", "成长", "很简单", "周末加"],
    rush: ["尽快", "今晚", "很急", "客户等"],
    knife: ["不背锅", "你该知", "现在不", "没资源"],
    stamp: ["请查收", "已读", "确认", "奉纳"],
  };
  const EN = {
    ok: ["OK", "GOT IT", "SURE", "YES"],
    sync: ["SYNC", "ALIGN", "HUDDLE", "LATER"],
    cc: ["CC", "FYI", "BOSS", "SEEN"],
    own: ["YOU", "OWN", "LOOK", "SEE"],
    group: ["MEET", "ALL", "CALL", "ROOM"],
    loop: ["DONE", "TODO", "LOOP", "END"],
    power: ["PUSH", "USE", "GO", "DO"],
    family: ["TEAM", "HARM", "HARD", "FYI"],
    bless: ["OT", "GROW", "EASY", "SAT"],
    rush: ["ASAP", "NOW", "GO", "WAIT"],
    knife: ["ME?", "KNEW", "NO", "L8R"],
    stamp: ["READ", "SEEN", "STAMP", "OFFER"],
  };

  const COLORS = {
    ok: "#c9a227",
    sync: "#7a1f1f",
    cc: "#9b2c2c",
    own: "#6b1220",
    group: "#5c1a1a",
    loop: "#8a5a12",
    power: "#a33b2a",
    family: "#c2412d",
    bless: "#b45309",
    rush: "#9f1239",
    knife: "#7f1d1d",
    stamp: "#991b1b",
  };

  const SHOTS = {
    ja: { ok: "了解", lie: "元気", teach: "指導", quit: "辞める", legend: "頑張るな" },
    zh: { ok: "好的", lie: "很好", teach: "教我", quit: "不干", legend: "别劝" },
    en: { ok: "OK", lie: "FINE", teach: "TEACH", quit: "QUIT", legend: "STOP" },
  };

  function bank(lang) {
    if (lang === "ja") return JA;
    if (lang === "zh") return ZH;
    return EN;
  }

  function clip(s, n) {
    const ch = Array.from(String(s || ""));
    return ch.length <= n ? ch.join("") : ch.slice(0, n).join("");
  }

  function pick(lang, key, i) {
    const list = bank(lang)[key] || bank(lang).ok;
    return clip(list[(i >>> 0) % list.length], 4);
  }

  function shot(lang, kind) {
    const pack = SHOTS[lang] || SHOTS.en;
    return clip(pack[kind] || pack.ok, 4);
  }

  function color(key) {
    return COLORS[key] || COLORS.ok;
  }

  const KEYS = Object.keys(JA);

  return { JA, ZH, EN, COLORS, SHOTS, KEYS, bank, pick, shot, color, clip };
})();

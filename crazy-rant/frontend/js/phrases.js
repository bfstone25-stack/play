var PHRASES = (() => {
  const ZH = {
    ok: ["好的好的", "收到", "嗯嗯", "先这样"],
    sync: ["对齐一下", "先同步", "拉个会", "复盘"],
    cc: ["CC领导", "同步领导", "上面的意思", "请查收"],
    own: ["你来跟进", "这个你来", "你看下", "你怎么看"],
    group: ["拉个群", "圈个会", "抄送全员", "开个会"],
    loop: ["闭环", "沉淀", "抓手", "链路"],
    power: ["赋能", "颗粒度", "颗粒对齐", "向下兼容"],
    family: ["我们是一家人", "不是针对你", "领导也很难", "我只是提醒"],
    bless: ["加班是福报", "成长机会", "这个简单吧", "周末加一下"],
    rush: ["尽快", "今晚必须", "这个很急", "客户要看"],
    knife: ["不是我的锅", "我以为你知道", "不是现在", "资源不够"],
    stamp: ["请查收", "请惠存", "已读", "FYI"],
  };
  const EN = {
    ok: ["Sounds good", "Got it", "OK OK", "Sure"],
    sync: ["Let's sync", "Circling back", "Quick huddle", "Align"],
    cc: ["CC the lead", "Per my last", "From above", "FYI"],
    own: ["You own this", "Take a look", "Your action", "Thoughts?"],
    group: ["Make a group", "Recurring", "All-hands", "Invite all"],
    loop: ["Close the loop", "Action item", "Owner?", "Follow up"],
    power: ["Empower", "Granularity", "Bandwidth", "Leverage"],
    family: ["We're a family", "Not personal", "Leadership is hard", "Just flagging"],
    bless: ["Overtime is growth", "Stretch role", "Easy, right?", "Weekend hop"],
    rush: ["ASAP", "Tonight", "URGENT", "Client wants it"],
    knife: ["Not my fault", "Thought you knew", "Not now", "No bandwidth"],
    stamp: ["Please advise", "Received", "Noted", "See attached"],
  };

  const COLORS = {
    ok: "#eab308",
    sync: "#22d3ee",
    cc: "#67e8f9",
    own: "#fb7185",
    group: "#a78bfa",
    loop: "#34d399",
    power: "#38bdf8",
    family: "#fde047",
    bless: "#f97316",
    rush: "#e11d48",
    knife: "#f43f5e",
    stamp: "#f8fafc",
  };

  const SHOTS = {
    zh: {
      ok: "好的好的",
      lie: "我很好",
      teach: "你在教我做事",
      quit: "我不干了",
      legend: "别再劝我努力",
    },
    en: {
      ok: "OK OK",
      lie: "I'm fine",
      teach: "Don't teach me",
      quit: "I quit",
      legend: "Stop the grind talk",
    },
  };

  function bank(lang) {
    return lang === "zh" ? ZH : EN;
  }

  function pick(lang, key, i) {
    const list = bank(lang)[key] || bank(lang).ok;
    return list[(i >>> 0) % list.length];
  }

  function shot(lang, kind) {
    const pack = SHOTS[lang] || SHOTS.en;
    return pack[kind] || pack.ok;
  }

  function color(key) {
    return COLORS[key] || COLORS.ok;
  }

  const KEYS = Object.keys(ZH);

  return { ZH, EN, COLORS, SHOTS, KEYS, bank, pick, shot, color };
})();

/* ===== 三语 i18n：zh / EN / ja · t() 插值 · 语言切换与持久化 ===== */
(function () {
  const DICT = {
    zh: {
      "app.title": "blazeCore Play · 星尘神社 StarDust Shrine",
      "shrine.name": "星尘神社",
      "shrine.sub": "STARDUST SHRINE · 弹珠兔的运气神社 · 机台 01",
      "stat.stardust": "星尘",
      "stat.showcase": "演出",
      "stat.nearMiss": "近失",
      "launch.btn": "发射 弹珠",
      "launch.hint": "按住蓄力 · 松开发射",
      "card.persona": "🔮 你的运气人格",
      "card.personaEmpty": "先玩几发，看看你是什么类型的玩家",
      "share.btn": "📤 分享我的运气人格",
      "card.keeper": "🐰 机台守护 · 弹珠兔",
      "mascot.hello": "投入星尘，兔子替你祈祷好运",
      "card.album": "📖 收藏册",
      "album.empty": "收集到「演出片段」后会出现在这里",
      "stage.title": "大吉！",
      "stage.fragLine": "✨ 获得演出片段「弹珠兔 · 初登场」",
      "foot.eco": "✦ 星尘可在 blazeCore 生态内流通 · 从弹珠机到《明夕》的跨应用奖励，此刻开始沉淀",
      "challenge.hit": "命中 10 个普通槽",
      "challenge.stage": "触发 3 次演出",
      "challenge.red": "进入 5 次红区",
      "challenge.streak": "连中 6 次",
      "challenge.done": "今日挑战完成！星尘之力正在汇聚 ✨",
      "stardustGain": "+{n} 星尘",
      "redGain": "+{n} 星尘 · 红区！",
      "nearMissLabel": "近失！差一点",
      "lucky": "大吉",
      "canvas.title": "星尘神社 · STARDUST SHRINE",
      "canvas.sub": "机台 01 · 投入星尘，祈福弹珠",
      "mascot.miss": "哎哟……力气不够，珠子掉回来了",
      "mascot.jackpot": "大吉！！兔子的祈祷灵验了！",
      "mascot.red": "红区！好兆头！",
      "mascot.nearMiss": "差一点！就一点点！",
      "mascot.playFirst": "先玩几发，兔子才知道你的运气呀",
      "mascot.copied": "已复制分享文案！",
      "mascot.outOfStardust": "星尘用完了……休息一下再来吧",
      "mascot.launch": "{power}% 力度！冲鸭！",
      "mascot.demo": "送你三发试玩，试试手感～",
      "stage.sub": "星尘之光为你闪耀",
      "stage.frag": "演出片段 #{n}",
      "p.edge": "刀尖舞者",
      "p.edge.desc": "常与大奖擦肩而过，却从未真正倒下——你是悬在胜负边界上的赌徒诗人。",
      "p.deity": "天选之人",
      "p.deity.desc": "大吉频繁降临，仿佛与星尘神签下了契约。这台机器，为你而造。",
      "p.strategist": "运筹师",
      "p.strategist.desc": "出手精准、极少失误，你用冷静的计算把概率踩在脚下。",
      "p.occult": "幽玄使者",
      "p.occult.desc": "大量空振仍不气馁——你信的不是概率，是肉眼看不见的引力。",
      "p.collector": "收藏家",
      "p.collector.desc": "连击稳定、演出常有，你的收藏册正在一点点变厚。",
      "s.shots": "总发射",
      "s.hitRate": "命中率",
      "s.showcases": "演出",
      "s.nearMisses": "近失",
      "s.maxStreak": "最长连中",
      "s.missed": "空心",
      "share.head": "{emoji} 我的运气人格是「{name}」！",
      "share.place": "星尘神社 · blazeCore Play 机台 01",
      "share.cta": "来测测你的运气 → play.blazecore.dev",
    },
    en: {
      "app.title": "blazeCore Play · StarDust Shrine",
      "shrine.name": "StarDust Shrine",
      "shrine.sub": "STARDUST SHRINE · The Luck Shrine of Bun-Bun · Machine 01",
      "stat.stardust": "StarDust",
      "stat.showcase": "Showcase",
      "stat.nearMiss": "Near Miss",
      "launch.btn": "Launch Ball",
      "launch.hint": "Hold to charge · Release to fire",
      "card.persona": "🔮 Your Luck Persona",
      "card.personaEmpty": "Play a few balls to reveal your persona",
      "share.btn": "📤 Share My Luck Persona",
      "card.keeper": "🐰 Machine Keeper · Bun-Bun",
      "mascot.hello": "Toss in StarDust, and Bun-Bun will pray for your luck",
      "card.album": "📖 Album",
      "album.empty": "Showcase fragments you collect will appear here",
      "stage.title": "JACKPOT!",
      "stage.fragLine": "✨ Showcase fragment unlocked: “Bun-Bun · First Debut”",
      "foot.eco": "✦ StarDust flows across the blazeCore ecosystem — from pachinko to Mingxi, cross-app rewards start here",
      "challenge.hit": "Hit 10 regular pockets",
      "challenge.stage": "Trigger 3 showcase stages",
      "challenge.red": "Enter the red zone 5 times",
      "challenge.streak": "Reach a 6-ball streak",
      "challenge.done": "Daily challenge complete! StarDust is gathering ✨",
      "stardustGain": "+{n} StarDust",
      "redGain": "+{n} StarDust · Red zone!",
      "nearMissLabel": "Near miss! So close",
      "lucky": "LUCKY",
      "canvas.title": "StarDust Shrine · STARDUST SHRINE",
      "canvas.sub": "Machine 01 · Toss StarDust, pray for luck",
      "mascot.miss": "Oof... not enough power, the ball dropped back",
      "mascot.jackpot": "JACKPOT!! Bun-Bun's prayer worked!",
      "mascot.red": "Red zone! A good omen!",
      "mascot.nearMiss": "So close! Just an inch away!",
      "mascot.playFirst": "Play a few balls first, so Bun-Bun can read your luck",
      "mascot.copied": "Share text copied!",
      "mascot.outOfStardust": "Out of StarDust... take a break and come back",
      "mascot.launch": "{power}% power! Go!",
      "mascot.demo": "3 free balls to warm up — feel the power!",
      "stage.sub": "StarDust light shines for you",
      "stage.frag": "Showcase Fragment #{n}",
      "p.edge": "Blade Dancer",
      "p.edge.desc": "Always brushing past the grand prize yet never falling — you are a gambler-poet balanced on the edge of victory.",
      "p.deity": "Chosen One",
      "p.deity.desc": "Jackpots fall like rain, as if you've signed a pact with the StarDust god. This machine was made for you.",
      "p.strategist": "The Strategist",
      "p.strategist.desc": "Precise shots, minimal waste — you trample probability with cold calculation.",
      "p.occult": "Occult Emissary",
      "p.occult.desc": "Endless misses never shake you — you believe not in probability, but in an unseen gravity.",
      "p.collector": "Collector",
      "p.collector.desc": "Steady streaks, frequent showcases — your album grows a little thicker each day.",
      "s.shots": "Shots",
      "s.hitRate": "Hit Rate",
      "s.showcases": "Showcases",
      "s.nearMisses": "Near Misses",
      "s.maxStreak": "Best Streak",
      "s.missed": "Missed",
      "share.head": "{emoji} My luck persona is “{name}”!",
      "share.place": "StarDust Shrine · blazeCore Play Machine 01",
      "share.cta": "Test your luck → play.blazecore.dev",
    },
    ja: {
      "app.title": "blazeCore Play · スターダスト神社",
      "shrine.name": "スターダスト神社",
      "shrine.sub": "STARDUST SHRINE · 弾珠うさぎの運気神社 · 台 01",
      "stat.stardust": "星屑",
      "stat.showcase": "ショー",
      "stat.nearMiss": "ニアミス",
      "launch.btn": "発射 玉",
      "launch.hint": "長押しでチャージ · 離して発射",
      "card.persona": "🔮 あなたの運勢キャラ",
      "card.personaEmpty": "何球か遊んで、あなたのタイプを見つけよう",
      "share.btn": "📤 運勢キャラを共有",
      "card.keeper": "🐰 台守り · 弾珠うさぎ",
      "mascot.hello": "星屑を入れて、うさぎが運を祈るよ",
      "card.album": "📖 コレクション",
      "album.empty": "「ショー片」を集めるとここに現れるよ",
      "stage.title": "大吉！",
      "stage.fragLine": "✨ ショー片を獲得「弾珠うさぎ · 初登場」",
      "foot.eco": "✦ 星屑は blazeCore エコシステムで流通 — パチンコから『明夕』まで、クロスアプリ報酬はここから始まる",
      "challenge.hit": "通常ポケットに10回入れる",
      "challenge.stage": "ショーを3回発生させる",
      "challenge.red": "レッドゾーンに5回入る",
      "challenge.streak": "6回連続で入れる",
      "challenge.done": "本日のチャレンジ達成！星屑が集まっている ✨",
      "stardustGain": "+{n} 星屑",
      "redGain": "+{n} 星屑 · レッドゾーン！",
      "nearMissLabel": "ニアミス！あと一歩",
      "lucky": "大吉",
      "canvas.title": "スターダスト神社 · STARDUST SHRINE",
      "canvas.sub": "台 01 · 星屑を入れて運を祈る",
      "mascot.miss": "うーん…力が足りなくて玉が戻ってきちゃった",
      "mascot.jackpot": "大吉！！うさぎの祈りが通じた！",
      "mascot.red": "レッドゾーン！いい兆し！",
      "mascot.nearMiss": "あと少し！惜しい！",
      "mascot.playFirst": "何球か遊んでから、うさぎが運を占うよ",
      "mascot.copied": "共有テキストをコピーしたよ！",
      "mascot.outOfStardust": "星屑がなくなった…休んでからまた来てね",
      "mascot.launch": "{power}% の力！いくよ！",
      "mascot.demo": "お試し3球をプレゼント！感触を確かめて～",
      "stage.sub": "星屑の光があなたのために輝く",
      "stage.frag": "ショー片 #{n}",
      "p.edge": "刃上の踊り手",
      "p.edge.desc": "大当たりと擦れ違い続けながらも決して倒れない——勝敗の境界に立つ博徒詩人。",
      "p.deity": "選ばれし者",
      "p.deity.desc": "大吉が頻繁に降り注ぎ、星屑の神と契約を結んだかのよう。この台はあなたのためにある。",
      "p.strategist": "戦略家",
      "p.strategist.desc": "正確な一打、無駄のない運び——冷静な計算で確率を踏みつける。",
      "p.occult": "幽玄の使者",
      "p.occult.desc": "何度外れても挫けない——信じているのは確率ではなく、目に見えない引力。",
      "p.collector": "コレクター",
      "p.collector.desc": "安定した連チャン、頻繁なショー——コレクションが少しずつ厚くなる。",
      "s.shots": "発射数",
      "s.hitRate": "命中率",
      "s.showcases": "ショー",
      "s.nearMisses": "ニアミス",
      "s.maxStreak": "最高連チャン",
      "s.missed": "空振り",
      "share.head": "{emoji} 私の運勢キャラは「{name}」！",
      "share.place": "スターダスト神社 · blazeCore Play 台 01",
      "share.cta": "運勢をチェック → play.blazecore.dev",
    },
  };

  const SUPPORTED = ["zh", "en", "ja"];
  let lang = "zh";

  function normalize(raw) {
    if (SUPPORTED.indexOf(raw) !== -1) return raw;
    if (raw && raw.slice(0, 2) === "zh") return "zh";
    if (raw && raw.slice(0, 2) === "ja") return "ja";
    return "en";
  }

  function detect() {
    try {
      const saved = localStorage.getItem("pp_lang");
      if (saved) return normalize(saved);
    } catch (e) {}
    return normalize((navigator.language || "zh").toLowerCase());
  }

  // 插值：t("stardustGain", { n: 5 }) → "+5 星尘"
  function t(key, vars) {
    let s = (DICT[lang] && DICT[lang][key]) || DICT.zh[key] || key;
    if (vars) {
      for (const k of Object.keys(vars)) {
        s = s.replace(new RegExp("\\{" + k + "\\}", "g"), vars[k]);
      }
    }
    return s;
  }

  function applyStatic() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      el.textContent = t(el.getAttribute("data-i18n"));
    });
  }

  function updateButtons() {
    document.querySelectorAll(".lang-btn").forEach(btn => {
      btn.classList.toggle("active", btn.getAttribute("data-lang") === lang);
    });
  }

  function setLang(next) {
    lang = normalize(next);
    try { localStorage.setItem("pp_lang", lang); } catch (e) {}
    document.documentElement.lang = lang === "zh" ? "zh-CN" : lang;
    applyStatic();
    updateButtons();
    // 动态 UI 刷新钩子（game.js 注册）
    if (typeof window.onLangChange === "function") window.onLangChange();
  }

  window.t = t;
  window.setLang = setLang;
  window.getLang = () => lang;

  // 语言按钮绑定
  document.querySelectorAll(".lang-btn").forEach(btn => {
    btn.addEventListener("click", () => setLang(btn.getAttribute("data-lang")));
  });

  // 启动：跟随持久化或浏览器语言
  lang = detect();
  document.documentElement.lang = lang === "zh" ? "zh-CN" : lang;
  applyStatic();
  updateButtons();
})();

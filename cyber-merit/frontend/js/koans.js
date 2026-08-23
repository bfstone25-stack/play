const KOANS = (() => {
  const PACK = [
    { zh: "云不存你的业。目前。", en: "The cloud does not store your karma. Yet." },
    { zh: "木鱼没有意见。你的KPI有。", en: "The fish has no opinion. Your KPI does." },
    { zh: "敲一下，少一封未读。", en: "One strike. One fewer unread." },
    { zh: "全息手不会酸。你的腕会。", en: "The holo-hand never aches. Your wrist will." },
    { zh: "功德可叠加。觉悟不行。", en: "Merit stacks. Awakening does not." },
    { zh: "今日份的空，已经缓存。", en: "Today's emptiness is already cached." },
    { zh: "莲花是粒子系统。你也是。", en: "The lotus is a particle system. So are you." },
    { zh: "香燃尽之前，Slack还在响。", en: "Incense dies. Slack does not." },
    { zh: "你在敲木鱼。木鱼在敲你。", en: "You strike the fish. The fish strikes you." },
    { zh: "数字功德没有退款政策。", en: "Digital merit has no refund policy." },
    { zh: "电路坛城比地铁准。", en: "The circuit mandala is more punctual than the subway." },
    { zh: "灵七说：先敲，再解释。", en: "LING-7 says: strike first. Explain later." },
    { zh: "把执念压缩成一朵莲。", en: "Compress attachment into one lotus." },
    { zh: "霓虹也是一种供养。", en: "Neon is also an offering." },
    { zh: "升级神龛，不升级欲望。", en: "Upgrade the shrine, not the craving." },
    { zh: "空格键是当代木槌。", en: "Spacebar is this century's mallet." },
    { zh: "今日偈已生成。请勿刷新。", en: "Today's koan is generated. Do not refresh." },
    { zh: "雨落在服务器上，也算甘露。", en: "Rain on the rack still counts as nectar." },
    { zh: "你的401k轮回概率更高。", en: "Your 401k has better reincarnation odds." },
    { zh: "机械臂比心诚。", en: "The mechanical arm is more sincere than the heart." },
    { zh: "功德粒子遵守本地物理。", en: "Merit particles obey local physics." },
    { zh: "坛城圆满不等于周一消失。", en: "A finished mandala does not cancel Monday." },
    { zh: "纸符没有权限访问你的日历。", en: "The ofuda has no calendar permissions." },
    { zh: "翡翠电路比翡翠贵，因为能闪。", en: "Jade circuit costs more than jade. It blinks." },
    { zh: "把通知静音，也是持戒。", en: "Muting notifications is also a precept." },
    { zh: "全息手只会敲这一下。很专一。", en: "The holo-hand only strikes. Devotion, of a kind." },
    { zh: "夜城不睡。木鱼不评。", en: "The city does not sleep. The fish does not judge." },
    { zh: "自动僧伽正在代你出家。", en: "Auto-sangha is taking vows on your behalf." },
    { zh: "功德卡可以分享。愧疚不行。", en: "The merit card can be shared. Guilt cannot." },
    { zh: "少刷一条，多敲一下。", en: "One less scroll. One more strike." },
    { zh: "铜绿是时间的皮肤。", en: "Patina is time wearing a body." },
    { zh: "卫星上看不见你的执着，只看见灯。", en: "Satellites cannot see clinging. Only lights." },
    { zh: "灵七偷走一粒功德。当学费。", en: "LING-7 steals one speck of merit. Tuition." },
    { zh: "梵音不是订阅。它已经在响。", en: "Fan-yin is not a subscription. It is already sounding." },
    { zh: "街摊神龛也度人。尤其度自己。", en: "A street-stall shrine still saves. Mostly you." },
    { zh: "把愤怒交给木鱼。它会做成金粉。", en: "Give anger to the fish. It mills it into gold dust." },
    { zh: "今日目标：少一点有用。", en: "Today's goal: be slightly less useful." },
    { zh: "电路会热。心也可以凉。", en: "Circuits heat. The mind may still cool." },
    { zh: "没有下一世推送。只有这一击。", en: "No next-life push notification. Only this strike." },
    { zh: "你已在线。木鱼也在线。够了。", en: "You are online. The fish is online. Enough." },
    { zh: "功德不是KPI，除非你非要。", en: "Merit is not a KPI unless you insist." },
    { zh: "莲开在显卡里，也算开。", en: "A lotus blooming in the GPU still blooms." },
  ];

  function dayKey(date) {
    const d = date ? new Date(date) : new Date();
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  }

  function hash(s) {
    let h = 2166136261;
    for (let i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = Math.imul(h, 16777619);
    }
    return h >>> 0;
  }

  function pick(key) {
    const i = hash(String(key || dayKey())) % PACK.length;
    return PACK[i];
  }

  function today(lang, date) {
    const k = pick(dayKey(date));
    return { key: dayKey(date), text: lang === "en" ? k.en : k.zh, zh: k.zh, en: k.en };
  }

  return { PACK, pick, today, dayKey };
})();

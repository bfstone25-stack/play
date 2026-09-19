/* game.js — Overtime Landlord: Idle. The parent's placement UI over a building that keeps
 * running when you leave (idle.js), a roster that is the gacha (roster.js + economy.js),
 * and the parent's two plate ladders side by side.
 *
 * What is the parent's, unchanged: the 5×4 canvas desk, three offers a beat, the ten PLATES
 * predicates and awardBoard()/awardCleared() (copied verbatim: they read st.cells / st.relics
 * / st.floor / st.bank, which here are getters onto whichever floor is being settled).
 */
(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const KEY = "overtime-idle.cabinet.v1";
  const BKEY = "overtime-idle.building.v1";
  const ART = "../../office-landlord-x/frontend/assets/cg/";     // installed plates, by path; no art copied
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const $ = (id) => document.getElementById(id);

  const COPY = {
    en: {
      tag: "AFTER HOURS · IDLE · 18+",
      lore: "The building keeps running when you leave.",
      rate: "RENT / HOUR", bank: "BANK", gold: "GOLD", chain: "CHAIN", floor: "FLOOR", next: "NEXT SHIFT", due: "RENT DUE / DAY",
      relics: "RELICS", line: "LANDLORD", hold: "COMMIT", settle: "SETTLE", reroll: "REROLL",
      start: "OPEN THE BUILDING", open: "OPEN", daily: "DAILY FLOOR", frozen: "FROZEN",
      introTag: "18+ · ADULTS ONLY",
      intro: "A 5×4 floor that keeps working after you close the tab. Every ten minutes each floor you built pays a shift — the board you place sets the rent per hour. Rent is due per floor, per day; a floor that cannot cover it is evicted and its people walk back to the roster. Staff are the gacha. Objects are bought with rent. Two ladders of plates: the skill ladder is a board you built and never comes from time; the affection ladder is time, and says so. Everyone in this building is an adult.",
      shift: "SHIFT", covers: "COVERS RENT", short: "SHORT",
      pick: "Pick a symbol, then a cell. Tap a placed piece to send it back.",
      full: "Desk is full.", need: "Need more rent.", needGold: "Need more Gold.", noPool: "Roster empty — pull, or buy objects.",
      committed: "Committed. The shifts will do the rest.",
      returned: "Back to the roster.",
      newPlate: "NEW PLATE", locked: "Locked — in the full download", close: "Close",
      galleryTitle: "Plates", galleryBody: "Skill plates are a board you built. Affection plates are shifts a person worked for you.",
      rosterTitle: "Roster", rosterBody: "Every person is a rule. Pull for a new one; a duplicate adds +5% to that person's shifts, up to +50%. Pity: an epic is guaranteed within 30 pulls.",
      pity: (n) => "Epic guaranteed within " + n + " pull" + (n === 1 ? "" : "s"),
      owned: "OWNED", slots: "ON FLOOR", dupes: "DUPES", aff: "SHIFTS",
      shopTitle: "Shop", shopBody: "Objects and relics are paid in rent. Gold buys time, pulls and shields — never a rule.",
      addFloor: "+ FLOOR", floorCost: "costs", evicted: "EVICTED", solvent: "SOLVENT",
      collect: "COLLECT", extend: "EXTEND TO 24 H",
      returnTag: "WHILE YOU WERE GONE",
      capNote: (h) => "The building froze after " + h + " hours. Offline shifts stop at the cap — extend it once, for good.",
      dailyTitle: "Everyone gets the same pieces today", dailyBody: "One layout, the same for every landlord today. Score is your best single settle. Pieces come from the house, not your roster.",
      dailyBest: (b) => (b ? "Today's best: " + b : "Not played yet today."),
      dailyStart: "PLAY TODAY'S FLOOR", dailyEndTag: "DAILY FLOOR · SETTLED",
      pct: (n) => "You beat " + n + "% of landlords.  你已经打败了 " + n + "% 的房东。",
      dailyEnd: "BACK TO THE BUILDING",
      noticeTitle: "Eviction", noticeBody: (fl) => "Floor " + fl.join(", ") + " did not cover the day's rent. Cleared. The people are back in the roster; the objects are gone.",
      noticeShield: "A rent shield absorbed an eviction.",
      prestigeTitle: "A second building", prestigeBody: "Seven days with every floor solvent. Mirei has found a bigger building. You start it empty — the roster comes with you — and every shift in it pays ×1.5.",
      prestigeBtn: "SIGN FOR IT", notYet: "NOT YET",
      tierUp: (name, t) => name + " · affection " + t,
      symbol: { coffee: "Coffee", dan: "Dan, 41", priya: "Priya, 29", wes: "Wes, 36", mute: "Headphones", printer: "Printer", mara: "Mara, 34", corner: "Corner", nia: "Nia, 33", sol: "Sol, 38" },
      relic: { severance: "Severance", quiet: "Quiet Floor", pto: "Unlimited PTO", glass: "Glass Office", badge: "Badge Reel", army: "Intern Army" },
      relicHint: { severance: "Empty desks pay 1.", quiet: "Headphones shield diagonally.", pto: "First reroll each floor is free.", glass: "Meetings stop taxing. Rent +10%.", badge: "+1 per chain event.", army: "Priya takes her best neighbour's score." },
      objectHint: { coffee: "Triples the Dan beside it.", mute: "Shields the staff beside it from Wes.", printer: "Pays per occupied desk in its row.", corner: "3, but only in a corner." },
      lines: {
        empty: "An empty floor bills the same as a full one. Your call.",
        calm: "Rent is covered. Do not decorate.",
        tense: "Close. The day is long.",
        fail: "That floor will not make the day.",
        chain: "Who authorized this synergy?",
        place: "Put it where it earns.",
      },
      barks: {
        first: "You came back. Most do not. The floor ran without you, which is the whole point.",
        big: "The building made more while you were gone than you did while you were here. Do not take it personally.",
        good: "Shifts ran. Rent came in. I did not have to call anyone.",
        small: "It ran. Barely. Put something next to something.",
        nothing: "Nothing happened, because nothing was placed. An empty floor is not a strategy.",
        evicted: "A floor missed rent. I cleared it. The people are fine; the furniture is not.",
        capped: "It stopped after the cap. I am a landlord, not a charity — extend it if you want it to keep going.",
        shield: "A floor missed rent and your shield covered it. Once.",
      },
    },
    zh: {
      tag: "加班之后 · 放置 · 18+",
      lore: "你走了，楼还在转。",
      rate: "每小时租金", bank: "账户", gold: "金币", chain: "连携", floor: "楼层", next: "下一班", due: "每日租金",
      relics: "遗物", line: "房东", hold: "提交", settle: "结算", reroll: "重抽",
      start: "开楼", open: "营业中", daily: "每日楼层", frozen: "已冻结",
      introTag: "18+ · 仅限成年人",
      intro: "一个关掉标签页还在上班的五乘四楼面。每十分钟，你建好的每一层结算一班——你摆的盘面决定每小时租金。租金按层按天收；交不上的那层被清退，人回名册。员工就是抽卡，物件用租金买。两条图板阶梯：技能梯是你摆出来的盘面，永远不靠时间；好感梯就是时间，并且明说。楼里每个人都是成年人。",
      shift: "每班", covers: "够租", short: "差",
      pick: "先选符号，再点空位。点已放的棋子可以收回。",
      full: "工位已满。", need: "租金不够。", needGold: "金币不够。", noPool: "名册空了——去抽，或者买物件。",
      committed: "已提交。剩下的交给班次。",
      returned: "已收回名册。",
      newPlate: "新图板", locked: "未解锁 · 完整版内含", close: "关闭",
      galleryTitle: "图板", galleryBody: "技能图板是你摆出来的盘面。好感图板是某人替你上过的班。",
      rosterTitle: "名册", rosterBody: "每个人都是一条规则。抽新的人；重复的给这个人每班 +5%，上限 +50%。保底：30 抽内必出史诗。",
      pity: (n) => n + " 抽内必出史诗",
      owned: "拥有", slots: "在岗", dupes: "重复", aff: "班次",
      shopTitle: "采购", shopBody: "物件和遗物用租金买。金币买时间、抽卡和护盾——永远不卖规则。",
      addFloor: "+ 楼层", floorCost: "需要", evicted: "已清退", solvent: "偿付中",
      collect: "收取", extend: "延长到 24 小时",
      returnTag: "你不在的时候",
      capNote: (h) => "楼在 " + h + " 小时后冻结了。离线班次到上限就停——延长一次，永久有效。",
      dailyTitle: "今天大家拿到同样的棋子", dailyBody: "一套布局，今天每个房东都一样。分数取单次结算最高。棋子由楼里提供，不占你的名册。",
      dailyBest: (b) => (b ? "今日最佳：" + b : "今天还没玩。"),
      dailyStart: "玩今天的楼层", dailyEndTag: "每日楼层 · 已结算",
      pct: (n) => "你已经打败了 " + n + "% 的房东。",
      dailyEnd: "回到大楼",
      noticeTitle: "清退", noticeBody: (fl) => "第 " + fl.join("、") + " 层没交齐当天的租金。已清空。人回了名册，物件没了。",
      noticeShield: "租金护盾抵消了一次清退。",
      prestigeTitle: "第二栋楼", prestigeBody: "连续七天每层都偿付。美玲找到了一栋更大的楼。从空楼开始——名册跟着你——里面每一班都 ×1.5。",
      prestigeBtn: "签下来", notYet: "先不",
      tierUp: (name, t) => name + " · 好感 " + t,
      symbol: { coffee: "咖啡机", dan: "丹恩 41", priya: "普莉娅 29", wes: "韦斯 36", mute: "降噪耳机", printer: "打印机", mara: "玛拉 34", corner: "角落工位", nia: "妮娅 33", sol: "索尔 38" },
      relic: { severance: "离职补偿", quiet: "静音层", pto: "无限年假", glass: "玻璃办公室", badge: "工牌卷轴", army: "实习军团" },
      relicHint: { severance: "空位各付 1。", quiet: "耳机斜向也护人。", pto: "每层第一次重抽免费。", glass: "会议不再抽税。租金 +10%。", badge: "每次连携 +1。", army: "普莉娅拿走邻格最高结算。" },
      objectHint: { coffee: "邻格丹恩三倍。", mute: "护住邻格员工不被韦斯抽税。", printer: "本行每个占用工位 +1。", corner: "3，但只在角落。" },
      lines: { empty: "空着也是策略？不是。", calm: "租金够了。别装修。", tense: "差一点。日子还长。", fail: "这层撑不过今天。", chain: "谁批的这套连携？", place: "放在能赚钱的格子上。" },
      barks: {
        first: "你回来了。多数人不回来。楼在你不在的时候照转，这就是全部意义。",
        big: "你不在的时候楼赚得比你在的时候多。别往心里去。",
        good: "班次照跑，租金照进。我一个电话都没打。",
        small: "转了。勉强。把什么东西放到什么东西旁边。",
        nothing: "什么都没发生，因为什么都没放。空楼不是策略。",
        evicted: "有一层没交租。我清了。人没事，家具没了。",
        capped: "到上限就停了。我是房东不是慈善家——想让它继续就延长。",
        shield: "有一层没交租，你的护盾顶了。就一次。",
      },
    },
  };

  let lang = "en", soundOn = true;
  const persistShape = { lang: "en", sound: true, cg: [], affSeen: {}, visits: 0 };
  try { Object.assign(persistShape, JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (_) {}
  lang = persistShape.lang === "zh" ? "zh" : "en";
  soundOn = persistShape.sound !== false;
  function t() { return COPY[lang]; }

  // ---- the building ----------------------------------------------------------
  function now() { return Date.now() + (B.clockOffset || 0); }
  let B = null;
  try { B = JSON.parse(localStorage.getItem(BKEY) || "null"); } catch (_) {}
  if (!B || B.v !== 1) B = Idle.fresh(Date.now());
  function saveB() { try { localStorage.setItem(BKEY, JSON.stringify(B)); } catch (_) {} }

  // `view` is the floor the canvas shows and the floor a settle describes. The parent's
  // predicates read st.cells / st.relics / st.floor / st.bank; here those are views onto it.
  let view = B.floors[0];
  const st = { phase: "play", mode: "building", offers: [], selected: -1, bestPayout: 0, bestChain: 0, castScore: { mara: 0, dan: 0, priya: 0, wes: 0 }, daily: null };
  Object.defineProperties(st, {
    cells: { get: () => view.cells, set: (v) => { view.cells = v; } },
    relics: { get: () => (st.mode === "daily" ? [] : B.relics) },
    floor: { get: () => view.n },
    bank: { get: () => B.bank },
  });
  function withFloor(f, fn) { const keep = view; view = f; try { fn(); } finally { view = keep; } }

  function emptyCells() { return Idle.emptyCells(); }
  function settleNow() { return settleIdle(st.cells, st.relics, st.mode === "daily" ? null : Economy.dupeMap()); }
  function occupied() { return st.cells.filter(Boolean).length; }
  function rerollCost() { return 4 + (view.n - 1); }
  function persist() {
    persistShape.lang = lang; persistShape.sound = soundOn;
    try { localStorage.setItem(KEY, JSON.stringify(persistShape)); } catch (_) {}
  }

  // ---- plates: the skill ladder — the parent's ten predicates, verbatim -----------------
  const PLATES = [
    { slot: "cg_mirei_lease", who: "Mirei", en: "Make rent on any floor with a surplus.", zh: "任意一层交租后还有结余。", free: true },
    { slot: "cg_dan_x", who: "Dan", en: "Three coffee→Dan multipliers in one settle.", zh: "单次结算里三组咖啡→丹恩。" },
    { slot: "cg_priya_x", who: "Priya", en: "Settle with 3+ staff placed, someone shielded, and no tax from Wes.", zh: "场上三名以上员工、有人被耳机罩住、且韦斯零抽税。" },
    { slot: "cg_mara_corners", who: "Mara", en: "Hold all four corners with corner desks.", zh: "四个角都放上角落工位。" },
    { slot: "cg_wes_x", who: "Wes", en: "With the Intern Army relic, four copies in one settle.", zh: "持有实习军团，单次结算抄四次。" },
    { slot: "cg_quiet_floor", who: "Mirei & Priya", en: "With Quiet Floor, clear a settle with a six-link chain.", zh: "持有静音层，单次结算连携六段。" },
    { slot: "cg_glass_office", who: "Mirei", en: "With Glass Office, make rent on floor 6 or later.", zh: "持有玻璃办公室，在第六层或更深处交齐租。" },
    { slot: "cg_vault_x", who: "Mirei", en: "Bank 40 or more.", zh: "账户存到 40 以上。" },
    { slot: "cg_floor9", who: "The ninth floor", en: "Reach floor nine.", zh: "抵达第九层。" },
    { slot: "cg_evicted", who: "The badge", en: "Get evicted. It happens.", zh: "被清退。总会有那么一次。" },
  ];
  function plateBy(slot) { return PLATES.find((p) => p.slot === slot); }
  function earned(slot) { return (persistShape.cg || []).indexOf(slot) >= 0; }

  function award(slot) {
    if (earned(slot)) return;
    persistShape.cg = (persistShape.cg || []).concat([slot]);
    persist();
    const p = plateBy(slot) || {};
    banner(t().newPlate + " — " + (p.who || slot));
    if (window.TEL) TEL.ev("cg_earned", { slot: slot, floor: st.floor });
    markGallery();
  }
  function markGallery() {
    const btn = $("galleryBtn");
    const n = (persistShape.cg || []).length;
    btn.textContent = "▣ " + n + "/" + PLATES.length;
    btn.classList.toggle("lit", n > 0);
  }
  function plateSrc(slot, open) { return ART + slot + (open ? "" : "_locked") + ".webp"; }

  function awardBoard(r, chain) {
    const ev = r.events;
    const n = (name) => ev.filter((e) => e === name).length;
    if (n("coffee-dan") >= 3) award("cg_dan_x");
    const staffOn = st.cells.filter((c) => c === "dan" || c === "priya" || c === "mara").length;
    if (staffOn >= 3 && ev.includes("mute-shield") && n("wes-tax") === 0) award("cg_priya_x");
    if ([0, 4, 15, 19].every((i) => st.cells[i] === "corner")) award("cg_mara_corners");
    if (st.relics.includes("army") && n("priya-army") >= 4) award("cg_wes_x");
    if (st.relics.includes("quiet") && chain >= 6) award("cg_quiet_floor");
    LANDLORD_CAST.forEach((id) => {
      st.cells.forEach((c, i) => { if (c === id) st.castScore[id] += (r.cellScore[i] || 0); });
    });
  }
  function awardCleared(surplus) {
    if (surplus > 0) award("cg_mirei_lease");
    if (st.relics.includes("glass") && st.floor >= 6) award("cg_glass_office");
    if (st.bank >= 40) award("cg_vault_x");
  }
  // A shift is a settle. Break-even per shift is the day's rent over the day's 144 shifts.
  function breakEven(f) { return Math.ceil(Idle.dailyRent(f, B.relics) / (Idle.DAY_MS / Idle.SHIFT_MS)); }
  function onShiftSettle(f, r, chain) {
    withFloor(f, () => {
      st.bestPayout = Math.max(st.bestPayout, r.payout);
      st.bestChain = Math.max(st.bestChain, chain);
      awardBoard(r, chain);
      awardCleared(Math.round(r.shift * B.mult) - breakEven(f));
    });
  }

  // ---- affection ladder: shifts worked, per character, and the plates by path ----------
  // Tier plates reuse the parent's installed art by path: the character's own plate as the
  // teaser (t1, its _locked cut) and open (t2), a house plate for t3, and a placeholder for
  // the tier-4 scene, which is Blaze's own and not in this tree.
  const AFF_PLATE = { dan: "cg_dan_x", priya: "cg_priya_x", mara: "cg_mara_corners", wes: "cg_wes_x", nia: "cg_glass_office", sol: "cg_quiet_floor" };
  function affSrc(id, tier) {
    const base = AFF_PLATE[id] || "cg_mirei_lease";
    if (tier === 1) return ART + base + "_locked.webp";
    if (tier === 2) return ART + base + ".webp";
    if (tier === 3) return ART + "cg_mirei_lease.webp";
    return ART + "plate_unearned.webp";
  }
  function affKey(id, tier) { return "cg_aff_" + id + "_" + tier; }
  function checkAffection() {
    IDLE_STAFF.forEach((id) => {
      const tier = Economy.affectionTier(id);
      const seen = persistShape.affSeen[id] | 0;
      if (tier > seen) {
        persistShape.affSeen[id] = tier;
        persist();
        banner(t().tierUp(t().symbol[id] || id, tier));
        if (window.TEL) TEL.ev("aff_tier", { id, tier });
      }
    });
  }

  // ---- ticker ------------------------------------------------------------------------
  function tickOpts() {
    return {
      capMs: Economy.offlineCapMs(),
      dupes: Economy.dupeMap(),
      shields: () => Economy.useShield(),
      onSettle: onShiftSettle,
      onShift: (id) => Economy.addShifts(id, 1),
      onEvict: () => award("cg_evicted"),
    };
  }
  function runTick(fromVisit) {
    const rep = Idle.tick(B, now(), tickOpts());
    if (rep.shifts || rep.days) { Economy.save(); saveB(); checkAffection(); }
    if (fromVisit && (rep.shifts > 0 || rep.evictions.length || rep.capped)) showReturn(rep);
    else if (rep.evictions.length) showEviction(rep);
    else if (rep.shielded) banner(t().noticeShield);
    if (rep.shifts && !fromVisit) { burst(null, rep.rent); if (window.SFX) SFX.settle(Math.min(5, rep.shifts)); }
    if (Idle.canPrestige(B) && !$("prestige").classList.contains("show") && !st.prestigeOffered) { st.prestigeOffered = true; showPrestige(); }
    hud();
    return rep;
  }

  function fmtDur(ms) {
    const m = Math.floor(ms / 60e3), h = Math.floor(m / 60), d = Math.floor(h / 24);
    if (d) return d + " d " + (h % 24) + " h";
    if (h) return h + " h " + (m % 60) + " min";
    return m + " min";
  }
  function bark(rep) {
    const b = t().barks;
    if (rep.evictions.length) return b.evicted;
    if (rep.shielded) return b.shield;
    if (rep.capped && rep.shifts) return b.capped;
    if (!rep.shifts) return b.nothing;
    if (persistShape.visits <= 1) return b.first;
    const perShift = rep.rent / rep.shifts;
    if (perShift >= 60) return b.big;
    if (perShift >= 12) return b.good;
    return b.small;
  }
  function showReturn(rep) {
    $("returnTag").textContent = t().returnTag;
    $("returnTitle").textContent = fmtDur(rep.elapsed);
    $("returnSay").textContent = "“" + bark(rep) + "”";
    $("retShifts").textContent = rep.shifts;
    $("retRent").textContent = rep.rent.toLocaleString();
    $("retRate").textContent = rep.shifts ? Math.round(rep.rent / (Math.min(rep.elapsed, Economy.offlineCapMs()) / 3600e3)).toLocaleString() : "0";
    $("lRetShifts").textContent = lang === "zh" ? "班次" : "SHIFTS";
    $("lRetRent").textContent = lang === "zh" ? "租金" : "RENT";
    $("lRetRate").textContent = lang === "zh" ? "每小时" : "/ HOUR";
    const ul = $("returnFloors"); ul.innerHTML = "";
    B.floors.forEach((f) => {
      const li = document.createElement("li");
      const ev = rep.evictions.includes(f.n);
      li.className = ev ? "evicted" : "";
      const a = document.createElement("span"); a.textContent = (lang === "zh" ? "第 " + f.n + " 层" : "Floor " + f.n);
      const b = document.createElement("span"); b.textContent = ev ? t().evicted : "+" + (rep.perFloor[f.n] || 0);
      li.appendChild(a); li.appendChild(b); ul.appendChild(li);
    });
    const note = $("returnNote");
    const cap = $("returnCap");
    if (rep.capped) { note.textContent = t().capNote(Economy.offlineCapMs() / 3600e3); cap.hidden = Economy.isOwned("offline_cap_24h"); }
    else { note.textContent = rep.rentPaid ? (lang === "zh" ? "已扣当日租金 " + rep.rentPaid : "Daily rent taken: " + rep.rentPaid) : ""; cap.hidden = true; }
    $("lReturnCap").textContent = t().extend;
    $("lCollect").textContent = t().collect;
    $("return").classList.add("show");
    if (window.TEL) TEL.ev("return_screen", { shifts: rep.shifts, rent: rep.rent, capped: rep.capped, evictions: rep.evictions.length });
  }
  function showEviction(rep) {
    $("noticeTag").textContent = lang === "zh" ? "通知" : "NOTICE";
    $("noticeTitle").textContent = t().noticeTitle;
    $("noticeBody").textContent = t().noticeBody(rep.evictions);
    $("lNotice").textContent = lang === "zh" ? "知道了" : "UNDERSTOOD";
    $("notice").classList.add("show");
    if (window.SFX) SFX.evict();
  }
  function showPrestige() {
    $("prestigeTag").textContent = lang === "zh" ? "收购" : "ACQUISITION";
    $("prestigeTitle").textContent = t().prestigeTitle;
    $("prestigeBody").textContent = t().prestigeBody;
    $("lPrestige").textContent = t().prestigeBtn;
    $("lClose4").textContent = t().notYet;
    $("prestige").classList.add("show");
  }

  // ---- roster pool: what can be placed right now ---------------------------------------
  function placedCount(id) { return B.floors.reduce((n, f) => n + f.cells.filter((c) => c === id).length, 0); }
  function available() {
    const pool = [];
    IDLE_ROSTER.forEach((p) => {
      if (!Economy.owned(p.id)) return;
      const free = p.slots - placedCount(p.id);
      for (let i = 0; i < free; i++) pool.push(p.id);
    });
    IDLE_OBJECTS.forEach((id) => { for (let i = 0; i < (B.inventory[id] | 0); i++) pool.push(id); });
    return pool;
  }
  function drawOffers(n) {
    if (st.mode === "daily") return st.daily.seq.slice(st.daily.at, st.daily.at + n);
    const pool = available();
    const out = [];
    for (let i = 0; i < n && pool.length; i++) out.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
    return out;
  }
  function refillOffers() { st.offers = drawOffers(3); st.selected = -1; }

  // ---- HUD --------------------------------------------------------------------------
  function banner(msg) {
    const el = $("banner");
    el.textContent = msg; el.classList.add("show");
    clearTimeout(banner.t); banner.t = setTimeout(() => el.classList.remove("show"), 1400);
  }
  function setLine(key) { $("landlordLine").textContent = t().lines[key] || t().lines.empty; }
  function moodFrom(shift, need) {
    const plate = $("landlordPlate");
    plate.classList.remove("tense", "evict");
    if (!occupied()) return "empty";
    if (shift >= need) return "calm";
    plate.classList.add("tense");
    return shift >= need * 0.75 ? "tense" : "fail";
  }

  function applyLang() {
    const c = t();
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
    $("tagline").textContent = c.tag; $("lore").textContent = c.lore;
    $("lRate").textContent = c.rate; $("lBank").textContent = c.bank; $("lGold").textContent = c.gold; $("lChain").textContent = c.chain;
    $("lFloor").textContent = c.floor; $("lNext").textContent = c.next; $("lDue").textContent = c.due; $("lRelics").textContent = c.relics; $("lLine").textContent = c.line;
    $("lHold").textContent = c.hold; $("lSettle").textContent = c.settle; $("lReroll").textContent = c.reroll; $("lStart").textContent = c.start;
    $("introTag").textContent = c.introTag; $("introBody").textContent = c.intro;
    document.querySelectorAll(".lang-btn[data-lang]").forEach((b) => b.classList.toggle("active", b.dataset.lang === lang));
    $("soundBtn").setAttribute("aria-pressed", soundOn ? "true" : "false");
    $("soundBtn").textContent = soundOn ? "♪" : "×";
    $("rosterBtn").textContent = "✦ " + (lang === "zh" ? "名册" : "ROSTER");
    $("shopBtn").textContent = "▤ " + (lang === "zh" ? "采购" : "SHOP");
    $("dailyBtn").textContent = "◷ " + (lang === "zh" ? "每日" : "DAILY");
    hud();
  }

  function hud() {
    const c = t();
    const r = settleNow();
    const dupes = Economy.dupeMap();
    $("rate").textContent = Math.round(Idle.ratePerHour(B, dupes)).toLocaleString();
    $("bank").textContent = Math.round(B.bank).toLocaleString();
    $("gold").textContent = Economy.gold().toLocaleString();
    $("chain").textContent = r.chain;
    const pips = document.querySelectorAll("#chainTrack i");
    pips.forEach((el, i) => el.classList.toggle("on", r.chain > i));
    if (window.SFX) SFX.setChain(Math.min(5, r.chain));
    const pay = st.mode === "daily" ? r.shift : Math.round(r.shift * B.mult);
    $("previewPay").textContent = c.shift + " " + pay + "  ×" + r.mult.toFixed(2);
    if (st.mode === "daily") {
      $("floorLabel").textContent = c.daily;
      $("floorFill").style.width = Math.min(100, st.daily.at / st.daily.seq.length * 100) + "%";
      $("rentDue").textContent = "—"; $("dueCover").textContent = "";
      $("runState").textContent = c.daily;
    } else {
      $("floorLabel").textContent = view.n + " / " + B.floors.length + (B.building > 1 ? "  · B" + B.building + " ×" + B.mult : "");
      $("floorFill").style.width = (view.n / Idle.MAX_FLOORS * 100) + "%";
      const need = Idle.dailyRent(view, B.relics);
      $("rentDue").textContent = need.toLocaleString();
      const perDay = pay * (Idle.DAY_MS / Idle.SHIFT_MS);
      const cover = $("dueCover");
      cover.textContent = perDay >= need ? c.covers + " ×" + (perDay / need).toFixed(1) : c.short + " " + Math.round(need - perDay) + "/d";
      cover.className = "cover" + (perDay >= need ? "" : " short");
      $("runState").textContent = c.open;
    }
    const left = Math.max(0, B.nextShift - now());
    const mm = Math.floor(left / 60e3), ss = Math.floor((left % 60e3) / 1000);
    $("nextShift").textContent = mm + ":" + (ss < 10 ? "0" : "") + ss;
    $("rerollCost").textContent = st.mode === "daily" ? "—" : rerollCost();
    const relicList = $("relicList"); relicList.innerHTML = "";
    (st.relics.length ? st.relics : [null]).forEach((id) => {
      const span = document.createElement("span"); span.className = "relic-chip";
      span.textContent = id ? (c.relic[id] || id) : (lang === "zh" ? "还没有遗物。" : "No relics yet.");
      relicList.appendChild(span);
    });
    renderOffers();
    renderFloorStrip();
    const mood = st.mode === "daily" ? (occupied() ? "calm" : "empty") : moodFrom(pay, breakEven(view));
    if (st.phase === "play" && !st.lineLock) setLine(mood);
  }

  function renderOffers() {
    const box = $("offers"); box.innerHTML = "";
    if (!st.offers.length) {
      const b = document.createElement("div"); b.className = "offer none";
      b.textContent = st.mode === "daily" ? (lang === "zh" ? "棋子用完了。结算。" : "Out of pieces. Settle.") : t().noPool;
      box.appendChild(b); return;
    }
    st.offers.forEach((id, i) => {
      const b = document.createElement("button"); b.type = "button";
      b.className = "offer" + (st.selected === i ? " sel" : "");
      b.appendChild(ICONS.badge(id, 28));
      const name = document.createElement("b"); name.textContent = t().symbol[id] || id;
      const small = document.createElement("small"); small.textContent = "+" + ((IDLE_CATALOG.find((s) => s.id === id) || {}).payout || 1);
      b.appendChild(name); b.appendChild(small);
      b.onclick = () => { if (st.phase !== "play") return; st.selected = i; if (window.SFX) SFX.place(); st.lineLock = true; setLine("place"); hud(); };
      box.appendChild(b);
    });
  }

  function renderFloorStrip() {
    const strip = $("floorStrip"); strip.innerHTML = "";
    if (st.mode === "daily") {
      const b = document.createElement("button"); b.type = "button"; b.className = "floor-tab on";
      b.textContent = t().daily + " · " + Idle.dayIndex(now());
      strip.appendChild(b);
      const x = document.createElement("button"); x.type = "button"; x.className = "floor-tab";
      x.textContent = lang === "zh" ? "← 回大楼" : "← BUILDING"; x.onclick = leaveDaily; strip.appendChild(x);
      return;
    }
    B.floors.forEach((f) => {
      const b = document.createElement("button"); b.type = "button";
      const r = Idle.floorShift(B, f, Economy.dupeMap());
      b.className = "floor-tab" + (f === view ? " on" : "") + (f.cells.some(Boolean) ? "" : " empty");
      b.textContent = (lang === "zh" ? "第 " + f.n + " 层" : "F" + f.n) + " · " + r.pay + "/" + (lang === "zh" ? "班" : "shift");
      b.setAttribute("data-floor", f.n);
      b.onclick = () => { view = f; refillOffers(); st.lineLock = false; hud(); };
      strip.appendChild(b);
    });
    if (B.floors.length < Idle.MAX_FLOORS) {
      const n = B.floors.length + 1, cost = Idle.floorCost(n);
      const b = document.createElement("button"); b.type = "button"; b.className = "floor-tab buy";
      b.id = "addFloor";
      b.innerHTML = "";
      b.textContent = t().addFloor + " " + n;
      const s = document.createElement("small"); s.textContent = t().floorCost + " " + cost; b.appendChild(s);
      b.onclick = () => buildFloor(n);
      strip.appendChild(b);
    }
  }
  const FREE_FLOORS = 3;
  function buildFloor(n) {
    const key = "floor" + n;
    if (n > FREE_FLOORS && window.Gate && Gate.dist() !== "paid" && !Gate.has(key)) {
      Gate.require(key, { title: "Floor " + n, kind: "level" }).then((r) => { if (r === "unlocked") buildFloor(n); });
      return;
    }
    const res = Idle.buildFloor(B, now());
    if (!res.ok) { banner(res.why === "bank" ? t().need + " (" + res.need + ")" : "—"); return; }
    if (n >= Idle.MAX_FLOORS) award("cg_floor9");
    view = B.floors[B.floors.length - 1];
    saveB(); refillOffers(); if (window.SFX) SFX.shop(); hud();
  }

  // ---- placement: the parent's, plus "tap a placed piece to send it back" ---------------
  function placeSelected(index) {
    if (st.phase !== "play") return;
    if (st.cells[index]) {
      if (st.mode === "daily") return;
      const id = st.cells[index];
      const next = st.cells.slice(); next[index] = null; st.cells = next;
      if (IDLE_OBJECTS.includes(id)) B.inventory[id] = (B.inventory[id] | 0) + 1;
      banner(t().returned); saveB(); refillOffers(); hud(); return;
    }
    if (st.selected < 0) { banner(t().pick); return; }
    const id = st.offers[st.selected];
    const next = placeAt(st.cells, id, index);
    if (!next) { banner(t().full); return; }
    st.cells = next;
    if (st.mode === "daily") { st.daily.at += 1; st.offers = drawOffers(3); st.selected = -1; }
    else {
      if (IDLE_OBJECTS.includes(id)) B.inventory[id] -= 1;
      // refill only the slot we used, from what is still available after this placement
      const at = st.selected;
      st.offers.splice(at, 1);
      const pool = available();
      st.offers.forEach((o) => { const k = pool.indexOf(o); if (k >= 0) pool.splice(k, 1); });
      if (pool.length) st.offers.splice(Math.min(at, st.offers.length), 0, pool[Math.floor(Math.random() * pool.length)]);
      st.selected = -1;
      saveB();
    }
    if (window.SFX) SFX.place();
    const r = settleNow();
    st.lineLock = false;
    if (r.events.includes("coffee-dan") || r.events.includes("priya-copy") || r.events.includes("nia-audit") || r.events.includes("sol-late")) { st.lineLock = true; setLine("chain"); }
    hud();
  }
  function doReroll() {
    if (st.phase !== "play" || st.mode === "daily") return;
    const cost = rerollCost();
    if (B.bank < cost) { banner(t().need); return; }
    B.bank -= cost; refillOffers(); saveB(); if (window.SFX) SFX.reroll(); hud();
  }
  // A manual settle commits the board: the skill ladder is evaluated on it (no pay — the
  // shifts pay). In the daily floor it is the scoring settle.
  function doSettle() {
    if (st.phase !== "play") return;
    if (!occupied()) { banner(lang === "zh" ? "没有可结算的。" : "Nothing to settle."); return; }
    const r = settleNow();
    burst(r.links, r.shift);
    if (window.SFX) { SFX.settle(r.chain); if (r.chain) SFX.combo(); }
    if (st.mode === "daily") { finishDaily(r); return; }
    st.bestPayout = Math.max(st.bestPayout, r.payout);
    st.bestChain = Math.max(st.bestChain, r.chain);
    awardBoard(r, r.chain);
    awardCleared(Math.round(r.shift * B.mult) - breakEven(view));
    banner(t().committed);
    st.lineLock = true; setLine(r.chain >= 4 ? "chain" : "calm");
    if (window.TEL) TEL.ev("commit", { floor: view.n, shift: r.shift, chain: r.chain });
    saveB(); hud();
  }

  // ---- daily floor -------------------------------------------------------------------
  function seeded(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
  function dailyKey() { return String(Idle.dayIndex(now())); }
  function dailySeq() {
    const rng = seeded(Idle.dayIndex(now()) * 7919 + 17);
    const bag = ["coffee", "coffee", "coffee", "dan", "dan", "priya", "priya", "priya", "mara", "wes", "mute", "mute", "printer", "corner", "nia", "sol"];
    const seq = [];
    for (let i = 0; i < 12; i++) seq.push(bag[Math.floor(rng() * bag.length)]);
    return seq;
  }
  function openDaily() {
    $("dailyTag").textContent = t().daily; $("dailyTitle").textContent = t().dailyTitle; $("dailyBody").textContent = t().dailyBody;
    $("dailyBest").textContent = t().dailyBest(B.daily[dailyKey()]);
    $("lDailyStart").textContent = t().dailyStart; $("lClose3").textContent = t().close;
    $("daily").classList.add("show");
  }
  function startDaily() {
    $("daily").classList.remove("show");
    st.mode = "daily";
    st.daily = { seq: dailySeq(), at: 0, cells: emptyCells(), n: 0 };
    view = st.daily;
    st.offers = drawOffers(3); st.selected = -1; st.lineLock = false;
    hud();
  }
  function leaveDaily() {
    st.mode = "building"; view = B.floors[0]; st.daily = null; refillOffers(); hud();
  }
  // Mocked distribution for the prototype: a percentile off an exponential fit to the
  // random-vs-chain spread in tests/kill_condition.cjs. The real one comes from the server.
  function percentile(score) { return Math.max(1, Math.min(99, Math.round(100 * (1 - Math.exp(-score / 90))))); }
  function finishDaily(r) {
    const k = dailyKey();
    B.daily[k] = Math.max(B.daily[k] | 0, r.shift);
    saveB();
    const pct = percentile(B.daily[k]);
    $("dailyEndTag").textContent = t().dailyEndTag;
    $("dailyEndTitle").textContent = r.shift + (lang === "zh" ? " / 班" : " / shift");
    $("dailyEndBody").textContent = (lang === "zh" ? "今日最佳 " : "Today's best ") + B.daily[k] + " · " + (lang === "zh" ? "连携 " : "chain ") + r.chain;
    $("dailyPct").textContent = t().pct(pct);
    $("lDailyEnd").textContent = t().dailyEnd;
    $("dailyEnd").classList.add("show");
    if (window.TEL) TEL.ev("daily_settle", { day: k, shift: r.shift, pct });
  }

  // ---- roster / gacha drawer ----------------------------------------------------------
  function renderRoster() {
    $("rosterTag").textContent = lang === "zh" ? "员工 · 抽卡" : "STAFF · THE GACHA";
    $("rosterTitle").textContent = t().rosterTitle; $("rosterBody").textContent = t().rosterBody;
    $("lPull1").textContent = lang === "zh" ? "单抽" : "PULL ×1"; $("lPull10").textContent = lang === "zh" ? "十连" : "PULL ×10";
    $("lClose1").textContent = t().close;
    $("pity").textContent = t().pity(IDLE_PITY - Economy.sinceEpic()) + " · " + (lang === "zh" ? "金币 " : "Gold ") + Economy.gold();
    const grid = $("rosterGrid"); grid.innerHTML = "";
    IDLE_ROSTER.forEach((p) => {
      const owned = Economy.owned(p.id);
      const card = document.createElement("div");
      card.className = "staff-card" + (owned ? "" : " unowned");
      const top = document.createElement("div"); top.className = "top";
      top.appendChild(ICONS.badge(p.id, 32));
      const nm = document.createElement("div");
      const b = document.createElement("b"); b.textContent = owned ? p[lang].name : "???";
      const rar = document.createElement("span"); rar.className = "rar " + p.rarity; rar.textContent = p.rarity.toUpperCase();
      nm.appendChild(b); nm.appendChild(rar); top.appendChild(nm); card.appendChild(top);
      const rule = document.createElement("span"); rule.className = "rule"; rule.textContent = p[lang].rule; card.appendChild(rule);
      const bio = document.createElement("span"); bio.className = "bio"; bio.textContent = owned ? p[lang].bio : (lang === "zh" ? "还没抽到。" : "Not pulled yet."); card.appendChild(bio);
      const meta = document.createElement("div"); meta.className = "meta";
      meta.textContent = t().slots + " " + placedCount(p.id) + "/" + p.slots + " · " + t().dupes + " " + Economy.dupes(p.id) + " (+" + Math.round((dupeBonus(Economy.dupes(p.id)) - 1) * 100) + "%) · " + t().aff + " " + Economy.affection(p.id);
      card.appendChild(meta);
      const aff = document.createElement("div"); aff.className = "aff";
      const tier = Economy.affectionTier(p.id);
      Economy.AFF_TIERS.forEach((x, i) => { const pip = document.createElement("i"); pip.className = tier > i ? "on" : ""; pip.title = x + " shifts"; aff.appendChild(pip); });
      const nxt = document.createElement("span");
      const next = Economy.AFF_TIERS.find((x) => x > Economy.affection(p.id));
      nxt.textContent = next ? Economy.affection(p.id) + "/" + next : "MAX";
      aff.appendChild(nxt); card.appendChild(aff);
      grid.appendChild(card);
    });
  }
  function doPull(n) {
    const sku = n === 10 ? "pull_10" : "pull_1";
    if (Economy.tickets() < n) {
      const r = Economy.buy(sku);
      if (!r.ok) { banner(t().needGold); renderRoster(); return; }
    }
    const res = Economy.pull(n);
    if (!res.ok) { banner(t().needGold); return; }
    const box = $("pullResult"); box.innerHTML = "";
    res.results.forEach((x) => {
      const chip = document.createElement("span"); chip.className = "pull-chip " + x.rarity;
      chip.appendChild(ICONS.badge(x.id, 20));
      const nm = document.createElement("b"); nm.textContent = t().symbol[x.id] || x.id;
      chip.appendChild(nm);
      if (x.dupe) { const em = document.createElement("em"); em.textContent = "+5%"; chip.appendChild(em); }
      box.appendChild(chip);
    });
    if (window.SFX) SFX.shop();
    if (window.TEL) TEL.ev("pull", { n, ids: res.results.map((x) => x.id) });
    renderRoster(); refillOffers(); hud();
  }

  // ---- shop --------------------------------------------------------------------------
  const OBJECT_PRICE = { coffee: 12, mute: 20, printer: 16, corner: 16 };
  const RELIC_PRICE = 150;
  function card(kindText, name, hint, price, priceKind, on, off) {
    const b = document.createElement("button"); b.type = "button"; b.className = "shop-card" + (off ? " off" : "");
    const k = document.createElement("small"); k.textContent = kindText;
    const n = document.createElement("b"); n.textContent = name;
    const h = document.createElement("span"); h.textContent = hint; h.style.display = "block"; h.style.marginTop = "4px"; h.style.color = "#7e8a8a"; h.style.fontSize = "12px";
    const p = document.createElement("span"); p.className = "price " + priceKind; p.textContent = price;
    b.appendChild(k); b.appendChild(n); b.appendChild(h); b.appendChild(p);
    b.onclick = () => { if (!off) on(); };
    return b;
  }
  function renderShop() {
    const c = t();
    $("shopTag").textContent = lang === "zh" ? "采购 · 用租金付" : "PROCUREMENT · PAID IN RENT";
    $("shopTitle").textContent = c.shopTitle; $("shopBody").textContent = c.shopBody; $("lClose2").textContent = c.close;
    $("goldTag").textContent = (lang === "zh" ? "金币 " : "GOLD ") + Economy.gold() + " · " + (lang === "zh" ? "抽卡券 " : "tickets ") + Economy.tickets() + " · " + (lang === "zh" ? "护盾 " : "shields ") + Economy.shields();
    const row = $("shopRow"); row.innerHTML = "";
    IDLE_OBJECTS.forEach((id) => {
      row.appendChild(card(lang === "zh" ? "物件" : "OBJECT", c.symbol[id] + "  ×" + (B.inventory[id] | 0), c.objectHint[id], (lang === "zh" ? "租金 " : "rent ") + OBJECT_PRICE[id], "rent",
        () => { if (B.bank < OBJECT_PRICE[id]) { banner(c.need); return; } B.bank -= OBJECT_PRICE[id]; B.inventory[id] = (B.inventory[id] | 0) + 1; saveB(); if (window.SFX) SFX.shop(); renderShop(); refillOffers(); hud(); }));
    });
    LANDLORD_RELICS.forEach((r) => {
      const have = B.relics.includes(r.id);
      row.appendChild(card(lang === "zh" ? "遗物" : "RELIC", c.relic[r.id], c.relicHint[r.id], have ? (lang === "zh" ? "已持有" : "owned") : (lang === "zh" ? "租金 " : "rent ") + RELIC_PRICE, "rent",
        () => { if (B.bank < RELIC_PRICE) { banner(c.need); return; } B.bank -= RELIC_PRICE; B.relics.push(r.id); saveB(); if (window.SFX) SFX.shop(); renderShop(); hud(); }, have));
    });
    const grow = $("goldRow"); grow.innerHTML = "";
    ["timeskip_4h", "offline_cap_24h", "rent_shield", "pull_1", "pull_10"].forEach((sku) => {
      const d = Economy.SKUS[sku];
      const owned = Economy.isOwned(sku);
      grow.appendChild(card(lang === "zh" ? "金币商品" : "GOLD SKU", sku, d[lang], owned ? (lang === "zh" ? "已持有" : "owned") : (lang === "zh" ? "金币 " : "Gold ") + d.gold, "",
        () => {
          const r = Economy.buy(sku);
          if (!r.ok) { banner(r.why === "gold" ? c.needGold : r.why); return; }
          if (sku === "timeskip_4h") { const ms = Economy.takeTimeskip(); const rep = Idle.timeskip(B, now(), ms, tickOpts()); Economy.save(); saveB(); checkAffection(); $("shop").classList.remove("show"); showReturn(rep); }
          if (window.SFX) SFX.shop(); renderShop(); hud();
        }, owned));
    });
    ["gold_s", "gold_m", "gold_l"].forEach((sku) => {
      const d = Economy.SKUS[sku];
      grow.appendChild(card(lang === "zh" ? "充值（原型：模拟）" : "IAP (prototype: mocked)", d[lang], d.iap, d.iap, "",
        () => { Economy.purchase(sku); if (window.SFX) SFX.shop(); renderShop(); hud(); }));
    });
  }

  // ---- gallery: both ladders ----------------------------------------------------------
  function openPlate(slot, src, capText, gated) {
    const pv = $("plateView"), img = $("plateImg"), cap = $("plateCap");
    function show(open) { img.src = open ? src : src.replace(/\.webp$/, "_locked.webp"); cap.textContent = capText + (open ? "" : "  ·  " + t().locked); pv.classList.add("show"); }
    if (!gated) { show(true); return; }
    const p = plateBy(slot) || {};
    const paid = window.Gate && Gate.dist() === "paid";
    if (p.free || paid || (window.Gate && Gate.has(slot))) { show(true); return; }
    show(false);
    if (!window.Gate) return;
    Gate.require(slot, { title: (lang === "zh" ? "图板 · " : "Plate — ") + (p.who || slot), kind: "cg" }).then((r) => { if (r === "unlocked") show(true); });
  }
  function renderGallery() {
    $("galleryTitle").textContent = t().galleryTitle; $("galleryBody").textContent = t().galleryBody; $("lClose5").textContent = t().close;
    $("lSkill").textContent = lang === "zh" ? "技能 — 你摆出来的盘面。永远不靠时间。" : "SKILL — A BOARD YOU BUILT. NEVER FROM TIME.";
    $("lAff").textContent = lang === "zh" ? "好感 — 在偿付楼层上的班次。这条就是时间，并且明说。" : "AFFECTION — SHIFTS WORKED ON A SOLVENT FLOOR. THIS ONE IS TIME, AND SAYS SO.";
    const grid = $("galleryGrid"); grid.innerHTML = "";
    PLATES.forEach((p) => {
      const got = earned(p.slot);
      const b = document.createElement("button"); b.type = "button"; b.className = "plate-tile" + (got ? " got" : "");
      const im = document.createElement("img"); im.alt = "";
      im.src = got ? plateSrc(p.slot, p.free || (window.Gate && (Gate.dist() === "paid" || Gate.has(p.slot)))) : ART + "plate_unearned.webp";
      const name = document.createElement("b"); name.textContent = got ? p.who : "???";
      const hint = document.createElement("span"); hint.textContent = lang === "zh" ? p.zh : p.en;
      b.appendChild(im); b.appendChild(name); b.appendChild(hint);
      b.onclick = () => { if (got) openPlate(p.slot, plateSrc(p.slot, true), p.who + " — " + (lang === "zh" ? p.zh : p.en), true); };
      grid.appendChild(b);
    });
    const ag = $("affGrid"); ag.innerHTML = "";
    IDLE_ROSTER.forEach((p) => {
      const tier = Economy.affectionTier(p.id);
      [1, 2, 3, 4].forEach((k) => {
        const open = tier >= k || (k === 4 && Economy.canSeeScene(p.id));
        const b = document.createElement("button"); b.type = "button"; b.className = "plate-tile aff-tile" + (open ? " got" : " t0");
        const im = document.createElement("img"); im.alt = ""; im.src = open ? affSrc(p.id, k) : ART + "plate_unearned.webp";
        const name = document.createElement("b"); name.textContent = t().symbol[p.id] + " · cg" + k;
        const tr = document.createElement("span"); tr.className = "tier";
        tr.textContent = k === 4 ? (Economy.canSeeScene(p.id) ? (lang === "zh" ? "第四阶 · 占位" : "TIER 4 · PLACEHOLDER") : Economy.AFF_TIERS[3] + (lang === "zh" ? " 班 · 或 150 班时用 scene_skip" : " shifts · or scene_skip at 150")) : Economy.AFF_TIERS[k - 1] + (lang === "zh" ? " 班" : " shifts");
        b.appendChild(im); b.appendChild(name); b.appendChild(tr);
        b.onclick = () => {
          if (open) { openPlate(affKey(p.id, k), affSrc(p.id, k), t().symbol[p.id] + " · cg" + k + (k === 4 ? (lang === "zh" ? "（第四阶场景：占位，Blaze 自制）" : " (tier-4 scene: placeholder, Blaze's own)") : ""), false); return; }
          if (k === 4 && tier >= 3) { const r = Economy.buy("scene_skip_" + p.id); banner(r.ok ? "scene_skip_" + p.id : t().needGold); renderGallery(); }
        };
        ag.appendChild(b);
      });
    });
  }

  // ---- canvas: the parent's isometric desk, verbatim ---------------------------------
  const fx = { hover: -1, punch: 0, coins: [], pulse: 0, t: 0 };
  function geo() {
    const w = canvas.clientWidth || 320, h = canvas.clientHeight || 320;
    const span = LANDLORD.COLS + LANDLORD.ROWS;
    const twW = (w * 0.86) * 2 / span, twH = (h * 0.68) * 2 / (span * 0.52);
    const tw = Math.max(28, Math.min(70, twW, twH)), th = tw * 0.52;
    const ox = w * 0.5, gridH = span * th / 2, oy = Math.max(22, (h - gridH) * 0.38);
    return { w, h, tw, th, ox, oy };
  }
  function iso(x, y, g) { return { sx: g.ox + (x - y) * (g.tw / 2), sy: g.oy + (x + y) * (g.th / 2) }; }
  function cellAt(px, py) {
    const g = geo(); let best = -1, bestD = 1e9;
    for (let i = 0; i < LANDLORD.SIZE; i++) {
      const p = xyOf(i), c = iso(p.x, p.y, g);
      const dx = px - c.sx, dy = py - (c.sy + g.th * 0.15);
      const d = (dx * dx) / (g.tw * g.tw) + (dy * dy) / (g.th * g.th);
      if (d < 0.55 && d < bestD) { bestD = d; best = i; }
    }
    return best;
  }
  function resize() {
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.floor((canvas.clientWidth || 1) * dpr); canvas.height = Math.floor((canvas.clientHeight || 1) * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  function diamond(g, x, y, lift) {
    const c = iso(x, y, g), tw = g.tw * 0.48, th = g.th * 0.48, top = c.sy - lift;
    ctx.beginPath(); ctx.moveTo(c.sx, top - th); ctx.lineTo(c.sx + tw, top); ctx.lineTo(c.sx, top + th); ctx.lineTo(c.sx - tw, top); ctx.closePath();
    return c;
  }
  function drawDesk(r) {
    const g = geo();
    ctx.clearRect(0, 0, g.w, g.h);
    if (fx.punch > 0 && !reduce) { const s = 1 + fx.punch * 0.018; ctx.translate(g.w * 0.5, g.h * 0.5); ctx.scale(s, s); ctx.translate(-g.w * 0.5, -g.h * 0.5); }
    ctx.fillStyle = "rgba(16, 28, 32, 0.9)"; ctx.beginPath();
    const a = iso(-0.85, -0.85, g), b = iso(LANDLORD.COLS - 0.15, -0.85, g), c = iso(LANDLORD.COLS - 0.15, LANDLORD.ROWS - 0.15, g), d = iso(-0.85, LANDLORD.ROWS - 0.15, g);
    ctx.moveTo(a.sx, a.sy); ctx.lineTo(b.sx, b.sy); ctx.lineTo(c.sx, c.sy); ctx.lineTo(d.sx, d.sy); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = "#3d5360"; ctx.stroke();
    const watch = iso((LANDLORD.COLS - 1) / 2, -1.35, g);
    ctx.save(); ctx.fillStyle = "rgba(74, 109, 140, 0.35)"; ctx.beginPath(); ctx.ellipse(watch.sx, watch.sy + 6, g.tw * 0.7, g.th * 0.35, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#4a6d8c"; ctx.beginPath(); ctx.arc(watch.sx, watch.sy - 8, 5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#e0a14a"; ctx.globalAlpha = 0.7; ctx.beginPath(); ctx.arc(watch.sx, watch.sy - 16, 2, 0, Math.PI * 2); ctx.fill(); ctx.restore();
    ctx.fillStyle = "#7e8a8a"; ctx.font = "10px ui-monospace, monospace"; ctx.textAlign = "center";
    const caption = iso((LANDLORD.COLS - 1) / 2, LANDLORD.ROWS - 0.15, g);
    ctx.fillText(st.mode === "daily" ? "DAILY · 5 × 4" : "FLOOR " + view.n + " · 5 × 4", caption.sx, caption.sy + g.th + 18);
    const order = []; for (let i = 0; i < LANDLORD.SIZE; i++) order.push(i);
    order.sort((i, j) => { const A = xyOf(i), Bq = xyOf(j); return (A.x + A.y) - (Bq.x + Bq.y); });
    order.forEach((i) => {
      const p = xyOf(i), hover = fx.hover === i, lift = hover ? 5 : 0;
      const cc = diamond(g, p.x, p.y, lift);
      const filled = !!st.cells[i], checker = (p.x + p.y) % 2;
      ctx.fillStyle = filled ? "#1a3d34" : (checker ? "#142c34" : "#1a3840");
      if (hover && st.selected >= 0 && !filled) ctx.fillStyle = "#2a5a44";
      ctx.fill(); ctx.strokeStyle = filled ? "#e0a14a" : "#4a6d8c"; ctx.lineWidth = filled ? 1.4 : 1; ctx.stroke();
      ctx.beginPath(); ctx.moveTo(cc.sx - g.tw * 0.48, cc.sy - lift); ctx.lineTo(cc.sx, cc.sy + g.th * 0.48 - lift); ctx.lineTo(cc.sx, cc.sy + g.th * 0.48 + 8); ctx.lineTo(cc.sx - g.tw * 0.48, cc.sy + 8); ctx.closePath();
      ctx.fillStyle = "rgba(10, 16, 20, 0.45)"; ctx.fill();
      if (st.cells[i]) {
        ICONS.paint(ctx, st.cells[i], cc.sx, cc.sy - lift - 2, Math.min(34, g.tw * 0.42));
        if (r.cellScore && r.cellScore[i]) { ctx.fillStyle = "#e0a14a"; ctx.font = "11px ui-monospace, monospace"; ctx.textAlign = "center"; ctx.fillText((r.cellScore[i] > 0 ? "+" : "") + r.cellScore[i], cc.sx, cc.sy - lift + g.th * 0.42 + 10); }
      }
    });
    if (r.links && r.links.length) {
      ctx.save(); ctx.globalAlpha = 0.55 + (reduce ? 0 : Math.sin(fx.t * 0.08) * 0.15);
      r.links.forEach((link) => {
        const A = xyOf(link.a), Bq = xyOf(link.b), pa = iso(A.x, A.y, g), pb = iso(Bq.x, Bq.y, g);
        ctx.beginPath(); ctx.moveTo(pa.sx, pa.sy); ctx.lineTo(pb.sx, pb.sy);
        ctx.strokeStyle = link.kind === "wes-tax" ? "#c45c32" : link.kind.indexOf("shield") >= 0 ? "#4a6d8c" : link.kind === "nia-audit" || link.kind === "sol-late" ? "#d9739a" : "#e0a14a";
        ctx.lineWidth = 1.6; ctx.stroke();
      });
      ctx.restore();
    }
    fx.coins = fx.coins.filter((p) => p.life > 0);
    fx.coins.forEach((p) => { p.x += p.vx; p.y += p.vy; p.vy += 0.00045; p.life -= 0.018; ctx.globalAlpha = Math.max(0, p.life); ctx.fillStyle = "#e0a14a"; ctx.beginPath(); ctx.arc(p.x * g.w, p.y * g.h, 2.4, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1; });
    if (fx.punch > 0) fx.punch *= 0.86; if (fx.pulse > 0) fx.pulse *= 0.9; fx.t += 1;
  }
  function burst(links, payout) {
    if (reduce) return;
    fx.punch = 1; fx.pulse = 1;
    const n = Math.min(28, 8 + Math.min(20, payout | 0));
    for (let i = 0; i < n; i++) fx.coins.push({ x: 0.5 + (Math.random() - 0.5) * 0.3, y: 0.48 + (Math.random() - 0.5) * 0.2, vx: (Math.random() - 0.5) * 0.012, vy: -0.01 - Math.random() * 0.012, life: 1 });
    void links;
  }
  function loop() { ctx.save(); drawDesk(settleNow()); ctx.restore(); requestAnimationFrame(loop); }
  function localPoint(ev) { const rect = canvas.getBoundingClientRect(); const p = ev.touches ? ev.touches[0] : ev; return { x: p.clientX - rect.left, y: p.clientY - rect.top }; }
  canvas.addEventListener("pointermove", (ev) => { const p = localPoint(ev); fx.hover = cellAt(p.x, p.y); });
  canvas.addEventListener("pointerleave", () => { fx.hover = -1; });
  canvas.addEventListener("pointerdown", (ev) => { const p = localPoint(ev); const i = cellAt(p.x, p.y); if (i >= 0) placeSelected(i); });

  // ---- wiring ----------------------------------------------------------------------
  const show = (id) => $(id).classList.add("show"), hide = (id) => $(id).classList.remove("show");
  document.querySelectorAll(".lang-btn[data-lang]").forEach((b) => { b.onclick = () => { lang = b.dataset.lang === "zh" ? "zh" : "en"; persist(); applyLang(); }; });
  $("soundBtn").onclick = () => { soundOn = !soundOn; if (window.SFX) { SFX.unlock(); SFX.setMuted(!soundOn); } persist(); applyLang(); };
  $("startBtn").onclick = () => {
    if (window.SFX) { SFX.unlock(); SFX.setMuted(!soundOn); }
    hide("intro");
    persistShape.visits = (persistShape.visits || 0) + 1; persist();
    if (window.TEL) TEL.ev("open_building", { visit: persistShape.visits, floors: B.floors.length });
    runTick(true);
    refillOffers(); hud();
  };
  $("settleBtn").onclick = doSettle;
  $("rerollBtn").onclick = doReroll;
  $("returnBtn").onclick = () => { hide("return"); if (window.SFX) SFX.win(); hud(); };
  $("returnCap").onclick = () => { const r = Economy.buy("offline_cap_24h"); if (!r.ok) { banner(t().needGold); return; } $("returnCap").hidden = true; banner("offline_cap_24h"); hud(); };
  $("rosterBtn").onclick = () => { renderRoster(); $("pullResult").innerHTML = ""; show("roster"); };
  $("rosterClose").onclick = () => hide("roster");
  $("pull1").onclick = () => doPull(1);
  $("pull10").onclick = () => doPull(10);
  $("shopBtn").onclick = () => { renderShop(); show("shop"); };
  $("shopClose").onclick = () => hide("shop");
  $("dailyBtn").onclick = openDaily;
  $("dailyClose").onclick = () => hide("daily");
  $("dailyStart").onclick = startDaily;
  // The daily floor is this game's run, and its end is where the parent offers the board:
  // the casual one, in the page, on a click. Nothing opens by itself.
  $("dailyEndBtn").onclick = () => { hide("dailyEnd"); leaveDaily(); setTimeout(() => { if (window.BOARD && BOARD.offerBreak) BOARD.offerBreak(); }, 900); };
  $("noticeBtn").onclick = () => { hide("notice"); setTimeout(() => { if (window.BOARD && BOARD.offerBreak) BOARD.offerBreak(); }, 900); };
  $("prestigeBtn").onclick = () => { Idle.prestige(B, now()); view = B.floors[0]; st.prestigeOffered = false; saveB(); hide("prestige"); refillOffers(); banner("×" + B.mult); if (window.SFX) SFX.win(); hud(); };
  $("prestigeClose").onclick = () => hide("prestige");
  $("galleryBtn").onclick = () => { renderGallery(); show("gallery"); };
  $("galleryClose").onclick = () => hide("gallery");
  $("plateClose").onclick = () => hide("plateView");

  // dev panel: the switches the brief asks for
  const dev = {
    addGold: (n) => { Economy.devAddGold(n); hud(); },
    advance: (ms) => { B.clockOffset = (B.clockOffset || 0) + ms; saveB(); return runTick(true); },
    forcePrestige: () => { B.solventDays = Idle.PRESTIGE_DAYS; st.prestigeOffered = false; saveB(); runTick(false); },
    reset: () => { localStorage.removeItem(KEY); localStorage.removeItem(BKEY); Economy.reset(); location.reload(); },
    state: () => B, econ: Economy, idle: Idle, st, hud, refillOffers, view: () => view,
    place: (i, id) => { const next = placeAt(st.cells, id, i); if (next) { st.cells = next; saveB(); hud(); } return !!next; },
    cellXY: (i) => { const g = geo(), p = xyOf(i), c = iso(p.x, p.y, g), r = canvas.getBoundingClientRect(); return { x: r.left + c.sx, y: r.top + c.sy + g.th * 0.15 }; },
  };
  window.OI = dev;
  $("devGold").onclick = () => dev.addGold(500);
  $("devH1").onclick = () => dev.advance(3600e3);
  $("devH8").onclick = () => dev.advance(8 * 3600e3);
  $("devD1").onclick = () => dev.advance(24 * 3600e3);
  $("devPrestige").onclick = dev.forcePrestige;
  $("devReset").onclick = dev.reset;

  window.addEventListener("resize", resize);
  document.addEventListener("visibilitychange", () => { if (!document.hidden && now() - B.lastSeen >= Idle.SHIFT_MS) runTick(true); });
  setInterval(() => { if (!$("intro").classList.contains("show")) runTick(false); else hud(); }, 1000);

  resize(); markGallery(); refillOffers(); applyLang(); requestAnimationFrame(loop);
})();

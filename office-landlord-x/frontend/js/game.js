(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  const KEY = "overtime-landlord.cabinet.v1";
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const COPY = {
    en: {
      tag: "AFTER HOURS · DESK LEASE · 18+",
      lore: "Place the people. Build chains. Pay the landlord.",
      rent: "RENT DUE", bank: "BANK", chain: "CHAIN", floor: "FLOOR",
      next: "NEXT RENT", relics: "RELICS", line: "LANDLORD",
      hold: "COLLECT", settle: "SETTLE", reroll: "REROLL",
      start: "SIGN THE LEASE", again: "NEW LEASE",
      introTag: "18+ · ADULTS ONLY",
      intro: "A 5×4 floor. Three offers each beat. The pieces are people who work late. Chains pay, rent rises 45% a floor, and the ninth floor is not about rent. Everyone in this building is an adult. No plate unlocks from playing longer — every one of them is a board you built.",
      shopTag: "BETWEEN FLOORS", shopTitle: "Procurement",
      shopBody: "Pick one. The elevator is already closing.",
      wait: "WAITING", live: "ON LEASE", shop: "PROCUREMENT", evict: "EVICTED", won: "RENEWED",
      preview: "PREVIEW",
      need: "Need more coins",
      full: "Desk is full. Settle.",
      pick: "Pick a symbol, then a cell.",
      empty: "Nothing to collect.",
      none: "No relics yet.",
      endLose: "Rent missed. Badge revoked. The plant stays.",
      endWin: "Nine floors. The building is briefly yours, and so is the night.",
      notice: "NOTICE",
      evictTitle: "Eviction",
      winTitle: "Floor nine",
      gallery: "GALLERY", galleryTitle: "Plates",
      galleryBody: "Every plate is a board you built. Tap a lit one to open it.",
      locked: "Locked — in the full download", newPlate: "NEW PLATE",
      close: "Close", ninth: "Floor 9 · After Hours",
      symbol: {
        coffee: "Coffee", dan: "Dan, 41", priya: "Priya, 29", wes: "Wes, 36",
        mute: "Headphones", printer: "Printer", mara: "Mara, 34", corner: "Corner",
      },
      relic: {
        severance: "Severance", quiet: "Quiet Floor", pto: "Unlimited PTO",
        glass: "Glass Office", badge: "Badge Reel", army: "Intern Army",
      },
      relicHint: {
        severance: "Empty desks pay 1.",
        quiet: "Headphones shield diagonally.",
        pto: "First reroll each floor is free.",
        glass: "Meetings stop taxing. Rent +10%.",
        badge: "+1 per chain event.",
        army: "Priya takes her best neighbour's score.",
      },
      lines: {
        empty: "An empty floor bills the same as a full one. Your call.",
        calm: "Rent is covered. Do not decorate.",
        tense: "Close. I can hear the interns sweating.",
        fail: "Clear your badge. The plant stays.",
        win: "You paid. I am still the landlord.",
        chain: "Who authorized this synergy?",
        place: "Put it where it earns.",
      },
    },
    zh: {
      tag: "加班之后 · 工位租约 · 18+",
      lore: "落人。连携。交租。",
      rent: "本层租金", bank: "账户", chain: "连携", floor: "楼层",
      next: "下层租金", relics: "遗物", line: "房东",
      hold: "收租", settle: "结算", reroll: "重抽",
      start: "签租约", again: "续租",
      introTag: "18+ · 仅限成年人",
      intro: "五乘四楼面。每次三张牌。牌是留下来加班的人。连携给钱，租金每层涨 45%，第九层跟租金无关。楼里每个人都是成年人。没有任何一张图靠时间解锁——每一张都是你摆出来的盘面。",
      shopTag: "楼层之间", shopTitle: "采购",
      shopBody: "只准拿一件。电梯门在关。",
      wait: "待命", live: "租期内", shop: "采购中", evict: "已清退", won: "续约",
      preview: "预估",
      need: "硬币不够",
      full: "工位已满，先结算",
      pick: "先选符号，再点空位。",
      empty: "没有可结算的。",
      none: "还没有遗物。",
      endLose: "租金没交齐。工牌收回。绿植留下。",
      endWin: "九层交清。这栋楼、这一夜，暂时算你的。",
      notice: "通知",
      evictTitle: "清退",
      winTitle: "第九层",
      gallery: "画廊", galleryTitle: "图板",
      galleryBody: "每张图都是你摆出来的盘面。点亮着的那张打开。",
      locked: "未解锁 · 完整版内含", newPlate: "新图板",
      close: "关闭", ninth: "第九层 · 加班之后",
      symbol: {
        coffee: "咖啡机", dan: "丹恩 41", priya: "普莉娅 29", wes: "韦斯 36",
        mute: "降噪耳机", printer: "打印机", mara: "玛拉 34", corner: "角落工位",
      },
      relic: {
        severance: "离职补偿", quiet: "静音层", pto: "无限年假",
        glass: "玻璃办公室", badge: "工牌卷轴", army: "实习军团",
      },
      relicHint: {
        severance: "空位各付 1。",
        quiet: "耳机斜向也护人。",
        pto: "每层第一次重抽免费。",
        glass: "会议不再抽税。租金 +10%。",
        badge: "每次连携 +1。",
        army: "普莉娅拿走邻格最高结算。",
      },
      lines: {
        empty: "空着也是策略？不是。",
        calm: "租金够了。别装修。",
        tense: "差一点。我听见实习生在出汗。",
        fail: "工牌放下。绿植留下。",
        win: "你交了。房东还是我。",
        chain: "谁批的这套连携？",
        place: "放在能赚钱的格子上。",
      },
    },
  };

  let lang = "en";
  let soundOn = true;
  const persistShape = { lang: "en", sound: true, bestBank: 0, leases: 0, cg: [] };
  try { Object.assign(persistShape, JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (_) {}
  lang = persistShape.lang === "zh" ? "zh" : "en";
  soundOn = persistShape.sound !== false;

  const st = {
    phase: "intro",
    bank: 0,
    floor: 1,
    cells: emptyCells(),
    deck: starterDeck(),
    relics: [],
    offers: [],
    selected: -1,
    ptoFree: true,
    bestPayout: 0,
    bestChain: 0,
    castScore: { mara: 0, dan: 0, priya: 0, wes: 0 },
  };

  const fx = {
    hover: -1,
    punch: 0,
    coins: [],
    pulse: 0,
    t: 0,
  };

  function emptyCells() { return new Array(LANDLORD.SIZE).fill(null); }
  function t() { return COPY[lang]; }
  function catalog() { return LANDLORD_CATALOG; }
  function settleNow() { return settleGrid(st.cells, catalog(), st.relics); }
  function rentNow() { return rentForFloor(st.floor, st.relics); }
  function nextRent() { return rentForFloor(Math.min(LANDLORD.FLOORS, st.floor + 1), st.relics); }
  function occupied() { return st.cells.filter(Boolean).length; }
  function rerollCost() { return st.relics.includes("pto") && st.ptoFree ? 0 : 4 + (st.floor - 1); }

  function persist() {
    persistShape.lang = lang;
    persistShape.sound = soundOn;
    persistShape.bestBank = Math.max(persistShape.bestBank || 0, st.bank);
    try { localStorage.setItem(KEY, JSON.stringify(persistShape)); } catch (_) {}
  }


  // ---- plates -------------------------------------------------------------
  // The whole rule of this fork, and the line that goes at the top of the store page:
  // no plate unlocks from time spent. Every one of them is a board state that
  // settleGrid() already names, or one of the two run-end plates (an ending needs an
  // image). Slots live in a `cg_*` key namespace on the SAME Gate that already gates
  // floors 4-8 (FREE_FLOORS below), so award() never opens a gate mid-floor: it banners
  // and lights the drawer, and Gate.require fires only when the player opens the entry.
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
    if (earned(slot)) return;                       // earned once is earned forever; farming pays nothing
    persistShape.cg = (persistShape.cg || []).concat([slot]);
    persist();
    const p = plateBy(slot) || {};
    banner(t().newPlate + " — " + (p.who || slot));
    if (window.TEL) TEL.ev("cg_earned", { slot: slot, floor: st.floor });
    markGallery();
  }

  function markGallery() {
    const btn = document.getElementById("galleryBtn");
    if (!btn) return;
    const n = (persistShape.cg || []).length;
    btn.textContent = "▣ " + n + "/" + PLATES.length;
    btn.classList.toggle("lit", n > 0);
  }

  function plateSrc(slot, open) {
    return "assets/cg/" + slot + (open ? "" : "_locked") + ".webp";
  }

  function openPlate(slot) {
    const p = plateBy(slot);
    const view = document.getElementById("plateView");
    const img = document.getElementById("plateImg");
    const cap = document.getElementById("plateCap");
    function show(open) {
      img.src = plateSrc(slot, open);
      cap.textContent = (p.who || slot) + " — " + (lang === "zh" ? p.zh : p.en) + (open ? "" : "  ·  " + t().locked);
      view.classList.add("show");
    }
    const paid = window.Gate && Gate.dist() === "paid";
    if (p.free || paid || (window.Gate && Gate.has(slot))) { show(true); return; }
    show(false);                                    // the censored plate is what the free package actually ships
    if (!window.Gate) return;
    Gate.require(slot, { title: (lang === "zh" ? "图板 · " : "Plate — ") + (p.who || slot), kind: "cg" })
      .then((r) => { if (r === "unlocked") show(true); });
  }

  function renderGallery() {
    const grid = document.getElementById("galleryGrid");
    if (!grid) return;
    grid.innerHTML = "";
    PLATES.forEach((p) => {
      const got = earned(p.slot);
      const b = document.createElement("button");
      b.type = "button";
      b.className = "plate-tile" + (got ? " got" : "");
      const im = document.createElement("img");
      im.alt = "";
      im.src = got ? plateSrc(p.slot, p.free || (window.Gate && (Gate.dist() === "paid" || Gate.has(p.slot)))) : "assets/cg/plate_unearned.webp";
      const name = document.createElement("b");
      name.textContent = got ? p.who : "???";
      const hint = document.createElement("span");
      hint.textContent = lang === "zh" ? p.zh : p.en;
      b.appendChild(im); b.appendChild(name); b.appendChild(hint);
      b.onclick = () => { if (got) openPlate(p.slot); };
      grid.appendChild(b);
    });
    document.getElementById("galleryTitle").textContent = t().galleryTitle;
    document.getElementById("galleryBody").textContent = t().galleryBody;
  }

  // Board-shape predicates: these describe THIS board, so they must run before doSettle()
  // returns on a failed rent check. (Getting that backwards silently changes which plates
  // are reachable — see §3 of the design doc.)
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

  // Cleared-floor predicates: below the rent check, because they are about surviving it.
  function awardCleared(surplus) {
    if (surplus > 0) award("cg_mirei_lease");
    if (st.relics.includes("glass") && st.floor >= 6) award("cg_glass_office");
    if (st.bank >= 40) award("cg_vault_x");
  }

  function leadCast() {
    return LANDLORD_CAST.slice().sort((a, b) => st.castScore[b] - st.castScore[a])[0];
  }

  function banner(msg) {
    const el = document.getElementById("banner");
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(banner.t);
    banner.t = setTimeout(() => el.classList.remove("show"), 1300);
  }

  function setLine(key) {
    document.getElementById("landlordLine").textContent = t().lines[key] || t().lines.empty;
  }

  function moodFrom(preview, rent) {
    const plate = document.getElementById("landlordPlate");
    plate.classList.remove("tense", "evict");
    if (st.phase === "evict") { plate.classList.add("evict"); return "fail"; }
    if (!occupied()) return "empty";
    if (preview >= rent) return "calm";
    if (preview >= rent * 0.75) { plate.classList.add("tense"); return "tense"; }
    plate.classList.add("tense");
    return "tense";
  }

  function applyLang() {
    const c = t();
    document.documentElement.lang = lang === "zh" ? "zh-Hans" : "en";
    document.getElementById("tagline").textContent = c.tag;
    document.getElementById("lore").textContent = c.lore;
    document.getElementById("lRent").textContent = c.rent;
    document.getElementById("lBank").textContent = c.bank;
    document.getElementById("lChain").textContent = c.chain;
    document.getElementById("lFloor").textContent = c.floor;
    document.getElementById("lNext").textContent = c.next;
    document.getElementById("lRelics").textContent = c.relics;
    document.getElementById("lLine").textContent = c.line;
    document.getElementById("lHold").textContent = c.hold;
    document.getElementById("lSettle").textContent = c.settle;
    document.getElementById("lReroll").textContent = c.reroll;
    document.getElementById("lStart").textContent = c.start;
    document.getElementById("lAgain").textContent = c.again;
    document.getElementById("introTag").textContent = c.introTag;
    document.getElementById("introBody").textContent = c.intro;
    document.getElementById("shopTag").textContent = c.shopTag;
    document.getElementById("shopTitle").textContent = c.shopTitle;
    document.getElementById("shopBody").textContent = c.shopBody;
    document.querySelectorAll(".lang-btn[data-lang]").forEach((b) => {
      b.classList.toggle("active", b.dataset.lang === lang);
    });
    document.getElementById("soundBtn").setAttribute("aria-pressed", soundOn ? "true" : "false");
    document.getElementById("soundBtn").textContent = soundOn ? "♪" : "×";
    hud();
  }

  function hud() {
    const c = t();
    const r = settleNow();
    const rent = rentNow();
    const chain = r.events.filter((e) => e !== "wes-tax").length;
    document.getElementById("rent").textContent = rent;
    document.getElementById("bank").textContent = st.bank.toLocaleString();
    document.getElementById("chain").textContent = chain;
    document.getElementById("floorLabel").textContent = st.floor + " / " + LANDLORD.FLOORS;
    document.getElementById("floorFill").style.width = ((st.floor - 1) / LANDLORD.FLOORS * 100) + "%";
    document.getElementById("previewPay").textContent = c.preview + " " + r.payout;
    document.getElementById("nextRent").textContent = st.floor >= LANDLORD.FLOORS ? "—" : nextRent();
    document.getElementById("rerollCost").textContent = rerollCost() || "0";
    const states = { intro: c.wait, play: c.live, shop: c.shop, evict: c.evict, win: c.won };
    document.getElementById("runState").textContent = states[st.phase] || c.wait;
    const pips = document.querySelectorAll("#chainTrack i");
    pips.forEach((el, i) => el.classList.toggle("on", chain > i));
    if (window.SFX) SFX.setChain(Math.min(5, chain));
    const relicList = document.getElementById("relicList");
    relicList.innerHTML = "";
    if (!st.relics.length) {
      const span = document.createElement("span");
      span.className = "relic-chip";
      span.textContent = c.none;
      relicList.appendChild(span);
    } else {
      st.relics.forEach((id) => {
        const span = document.createElement("span");
        span.className = "relic-chip";
        span.textContent = c.relic[id] || id;
        relicList.appendChild(span);
      });
    }
    renderOffers();
    const mood = moodFrom(r.payout, rent);
    if (st.phase === "play") setLine(mood);
  }

  function renderOffers() {
    const box = document.getElementById("offers");
    box.innerHTML = "";
    st.offers.forEach((id, i) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "offer" + (st.selected === i ? " sel" : "");
      const icon = ICONS.badge(id, 28);
      const small = document.createElement("small");
      small.textContent = "+" + ((catalog().find((s) => s.id === id) || {}).payout || 1);
      const name = document.createElement("b");
      name.textContent = t().symbol[id] || id;
      b.appendChild(icon);
      b.appendChild(name);
      b.appendChild(small);
      b.onclick = () => {
        if (st.phase !== "play") return;
        st.selected = i;
        if (window.SFX) SFX.place();
        setLine("place");
        hud();
      };
      box.appendChild(b);
    });
  }

  function newLease() {
    persistShape.leases = (persistShape.leases || 0) + 1;
    st.phase = "play";
    st.bank = 0;
    st.floor = 1;
    st.cells = emptyCells();
    st.deck = starterDeck();
    st.relics = [];
    st.offers = rollFrom(st.deck, 3);
    st.selected = -1;
    st.ptoFree = true;
    st.bestPayout = 0;
    st.bestChain = 0;
    st.castScore = { mara: 0, dan: 0, priya: 0, wes: 0 };
    persist();
    document.getElementById("intro").classList.remove("show");
    document.getElementById("shop").classList.remove("show");
    document.getElementById("end").classList.remove("show");
    setLine("empty");
    hud();
  }

  const FREE_FLOORS = 3; // dual-track (ops/DUAL_TRACK.md): floors 1-3 free, 4-8 behind the gate
  function nextFloor() {
    const key = "floor" + (st.floor + 1);
    if (st.floor + 1 > FREE_FLOORS && window.Gate && window.Gate.dist() !== "paid" && !window.Gate.has(key)) {
      window.Gate.require(key, { title: "Floor " + (st.floor + 1), kind: "level" }).then((r) => { if (r === "unlocked") nextFloor(); });
      return;
    }
    st.floor += 1;
    st.cells = emptyCells();
    st.offers = rollFrom(st.deck, 3);
    st.selected = -1;
    st.ptoFree = true;
    st.phase = "play";
    document.getElementById("shop").classList.remove("show");
    if (st.floor >= LANDLORD.FLOORS) {
      // Floor 9 has no rent and no shop. It is one scene, and which scene is decided by
      // whoever earned the most on the board across the run.
      award("cg_floor9");
      finish(true);
      return;
    }
    setLine("place");
    hud();
  }

  function openShop() {
    st.phase = "shop";
    const row = document.getElementById("shopRow");
    row.innerHTML = "";
    pickShop(st.relics, catalog(), 3).forEach((card) => {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "shop-card";
      const kind = document.createElement("small");
      kind.textContent = card.kind === "relic" ? t().relics : t().symbol[card.id] ? t().preview : "ITEM";
      kind.textContent = card.kind === "relic" ? (lang === "zh" ? "遗物" : "RELIC") : (lang === "zh" ? "符号" : "SYMBOL");
      const name = document.createElement("b");
      name.textContent = card.kind === "relic" ? (t().relic[card.id] || card.id) : (t().symbol[card.id] || card.id);
      const hint = document.createElement("span");
      hint.textContent = card.kind === "relic"
        ? (t().relicHint[card.id] || "")
        : (lang === "zh" ? "加入牌组" : "Add to the deck");
      hint.style.display = "block";
      hint.style.marginTop = "4px";
      hint.style.color = "#7e8a8a";
      hint.style.fontSize = "12px";
      b.appendChild(kind);
      b.appendChild(name);
      b.appendChild(hint);
      b.onclick = () => {
        if (card.kind === "relic") st.relics.push(card.id);
        else st.deck.push(card.id);
        if (window.SFX) SFX.shop();
        nextFloor();
      };
      row.appendChild(b);
    });
    document.getElementById("shop").classList.add("show");
    hud();
  }

  function finish(won) {
    st.phase = won ? "win" : "evict";
    persistShape.bestBank = Math.max(persistShape.bestBank || 0, st.bank);
    persist();
    document.getElementById("endTag").textContent = t().notice;
    document.getElementById("endTitle").textContent = won ? t().winTitle : t().evictTitle;
    if (!won) award("cg_evicted");
    document.getElementById("endBody").textContent = won ? t().endWin : t().endLose;
    if (won) {
      const lead = leadCast();
      document.getElementById("endTitle").textContent = t().ninth;
      document.getElementById("endBody").textContent = t().endWin + " " +
        (lang === "zh" ? "留下来的是" : "The one who stayed: ") + (t().symbol[lead] || lead) + ".";
    }
    document.getElementById("endStat").textContent = (lang === "zh" ? "账户 " : "BANK ") + st.bank +
      (lang === "zh" ? " · 最佳连携 " : " · BEST CHAIN ") + st.bestChain;
    document.getElementById("end").classList.add("show");
    setLine(won ? "win" : "fail");
    if (window.SFX) { won ? SFX.win() : SFX.evict(); }
    hud();
    // The return leg of the cross-promotion loop: the adult titles send players to this
    // catalogue, and the end of a run is where this catalogue sends some back. Inert
    // unless the build sets PROMO_ADULT_OK, so portal builds never carry it.
    // The board is the offer Blaze asked for: a grid the player chooses from, not a
    // single link. PROMO's one-card version stays as the fallback for builds that do not
    // ship board.js.
    setTimeout(function () {
      // The loop runs the other way here: this is an adult title, so the offer on the way
      // out is the casual board (arousal fatigues; see board.js).
      if (window.BOARD && BOARD.offerBreak) BOARD.offerBreak();
      else if (window.PROMO) PROMO.showAfterRun(won ? "win" : "evict");
    }, 900);
  }

  function burst(links, payout) {
    if (reduce) return;
    fx.punch = 1;
    fx.pulse = 1;
    const n = Math.min(28, 8 + payout);
    for (let i = 0; i < n; i++) {
      fx.coins.push({
        x: 0.5 + (Math.random() - 0.5) * 0.3,
        y: 0.48 + (Math.random() - 0.5) * 0.2,
        vx: (Math.random() - 0.5) * 0.012,
        vy: -0.01 - Math.random() * 0.012,
        life: 1,
      });
    }
    void links;
  }

  function doSettle() {
    if (st.phase !== "play") return;
    if (!occupied()) { banner(t().empty); return; }
    const r = settleNow();
    const rent = rentNow();
    const chain = r.events.filter((e) => e !== "wes-tax").length;
    st.bestPayout = Math.max(st.bestPayout, r.payout);
    st.bestChain = Math.max(st.bestChain, chain);
    awardBoard(r, chain);
    burst(r.links, r.payout);
    if (window.SFX) {
      SFX.settle(chain);
      if (chain) SFX.combo();
    }
    if (!meetRent(r.payout, rent)) {
      banner((lang === "zh" ? "差 " : "SHORT ") + (rent - r.payout));
      finish(false);
      return;
    }
    const surplus = r.payout - rent;
    st.bank += surplus;
    persist();
    awardCleared(surplus);
    if (chain >= 4) setLine("chain");
    else setLine("calm");
    banner((lang === "zh" ? "结余 +" : "SURPLUS +") + surplus);
    if (st.floor >= LANDLORD.FLOORS - 1) nextFloor();
    else openShop();
    hud();
  }

  function doReroll() {
    if (st.phase !== "play") return;
    const cost = rerollCost();
    if (st.bank < cost) { banner(t().need); return; }
    st.bank -= cost;
    if (cost === 0) st.ptoFree = false;
    st.offers = rollFrom(st.deck, 3);
    st.selected = -1;
    persist();
    if (window.SFX) SFX.reroll();
    hud();
  }

  function placeSelected(index) {
    if (st.phase !== "play") return;
    if (st.selected < 0) { banner(t().pick); return; }
    if (st.cells[index]) return;
    const id = st.offers[st.selected];
    const next = placeAt(st.cells, id, index);
    if (!next) { banner(t().full); return; }
    st.cells = next;
    st.offers[st.selected] = rollFrom(st.deck, 1)[0];
    st.selected = -1;
    if (window.SFX) SFX.place();
    const r = settleNow();
    if (r.events.includes("coffee-dan") || r.events.includes("priya-copy")) setLine("chain");
    hud();
  }

  // --- isometric desk ---
  function geo() {
    const w = canvas.clientWidth || 320;
    const h = canvas.clientHeight || 320;
    const span = LANDLORD.COLS + LANDLORD.ROWS;
    const twW = (w * 0.86) * 2 / span;
    const twH = (h * 0.68) * 2 / (span * 0.52);
    const tw = Math.max(28, Math.min(70, twW, twH));
    const th = tw * 0.52;
    const ox = w * 0.5;
    const gridH = span * th / 2;
    const oy = Math.max(22, (h - gridH) * 0.38);
    return { w, h, tw, th, ox, oy };
  }

  function iso(x, y, g) {
    return {
      sx: g.ox + (x - y) * (g.tw / 2),
      sy: g.oy + (x + y) * (g.th / 2),
    };
  }

  function cellAt(px, py) {
    const g = geo();
    const x = px, y = py;
    let best = -1, bestD = 1e9;
    for (let i = 0; i < LANDLORD.SIZE; i++) {
      const p = xyOf(i);
      const c = iso(p.x, p.y, g);
      const dx = x - c.sx, dy = y - (c.sy + g.th * 0.15);
      const d = (dx * dx) / (g.tw * g.tw) + (dy * dy) / (g.th * g.th);
      if (d < 0.55 && d < bestD) { bestD = d; best = i; }
    }
    return best;
  }

  function resize() {
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const w = canvas.clientWidth || 1;
    const h = canvas.clientHeight || 1;
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function diamond(g, x, y, lift) {
    const c = iso(x, y, g);
    const tw = g.tw * 0.48, th = g.th * 0.48;
    const top = c.sy - lift;
    ctx.beginPath();
    ctx.moveTo(c.sx, top - th);
    ctx.lineTo(c.sx + tw, top);
    ctx.lineTo(c.sx, top + th);
    ctx.lineTo(c.sx - tw, top);
    ctx.closePath();
    return c;
  }

  function drawDesk(r) {
    const g = geo();
    ctx.clearRect(0, 0, g.w, g.h);
    if (fx.punch > 0 && !reduce) {
      const s = 1 + fx.punch * 0.018;
      ctx.translate(g.w * 0.5, g.h * 0.5);
      ctx.scale(s, s);
      ctx.translate(-g.w * 0.5, -g.h * 0.5);
    }

    ctx.fillStyle = "rgba(16, 28, 32, 0.9)";
    ctx.beginPath();
    const a = iso(-0.85, -0.85, g), b = iso(LANDLORD.COLS - 0.15, -0.85, g);
    const c = iso(LANDLORD.COLS - 0.15, LANDLORD.ROWS - 0.15, g), d = iso(-0.85, LANDLORD.ROWS - 0.15, g);
    ctx.moveTo(a.sx, a.sy);
    ctx.lineTo(b.sx, b.sy);
    ctx.lineTo(c.sx, c.sy);
    ctx.lineTo(d.sx, d.sy);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = "#3d5360";
    ctx.stroke();

    const watch = iso((LANDLORD.COLS - 1) / 2, -1.35, g);
    ctx.save();
    ctx.fillStyle = "rgba(74, 109, 140, 0.35)";
    ctx.beginPath();
    ctx.ellipse(watch.sx, watch.sy + 6, g.tw * 0.7, g.th * 0.35, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#4a6d8c";
    ctx.beginPath();
    ctx.arc(watch.sx, watch.sy - 8, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#e0a14a";
    ctx.globalAlpha = 0.7;
    ctx.beginPath();
    ctx.arc(watch.sx, watch.sy - 16, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    ctx.fillStyle = "#7e8a8a";
    ctx.font = "10px ui-monospace, monospace";
    ctx.textAlign = "center";
    const caption = iso((LANDLORD.COLS - 1) / 2, LANDLORD.ROWS - 0.15, g);
    ctx.fillText("5 × 4", caption.sx, caption.sy + g.th + 18);

    const order = [];
    for (let i = 0; i < LANDLORD.SIZE; i++) order.push(i);
    order.sort((i, j) => {
      const A = xyOf(i), B = xyOf(j);
      return (A.x + A.y) - (B.x + B.y);
    });

    order.forEach((i) => {
      const p = xyOf(i);
      const hover = fx.hover === i;
      const lift = hover ? 5 : 0;
      const c = diamond(g, p.x, p.y, lift);
      const filled = !!st.cells[i];
      const checker = (p.x + p.y) % 2;
      ctx.fillStyle = filled ? "#1a3d34" : (checker ? "#142c34" : "#1a3840");
      if (hover && st.selected >= 0 && !filled) ctx.fillStyle = "#2a5a44";
      ctx.fill();
      ctx.strokeStyle = filled ? "#e0a14a" : "#4a6d8c";
      ctx.lineWidth = filled ? 1.4 : 1;
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(c.sx - g.tw * 0.48, c.sy - lift);
      ctx.lineTo(c.sx, c.sy + g.th * 0.48 - lift);
      ctx.lineTo(c.sx, c.sy + g.th * 0.48 + 8);
      ctx.lineTo(c.sx - g.tw * 0.48, c.sy + 8);
      ctx.closePath();
      ctx.fillStyle = "rgba(10, 16, 20, 0.45)";
      ctx.fill();

      if (st.cells[i]) {
        ICONS.paint(ctx, st.cells[i], c.sx, c.sy - lift - 2, Math.min(34, g.tw * 0.42));
        if (r.cellScore && r.cellScore[i]) {
          ctx.fillStyle = "#e0a14a";
          ctx.font = "11px ui-monospace, monospace";
          ctx.textAlign = "center";
          ctx.fillText((r.cellScore[i] > 0 ? "+" : "") + r.cellScore[i], c.sx, c.sy - lift + g.th * 0.42 + 10);
        }
      }
    });

    if (r.links && r.links.length) {
      ctx.save();
      ctx.globalAlpha = 0.55 + (reduce ? 0 : Math.sin(fx.t * 0.08) * 0.15);
      r.links.forEach((link) => {
        const A = xyOf(link.a), B = xyOf(link.b);
        const pa = iso(A.x, A.y, g), pb = iso(B.x, B.y, g);
        ctx.beginPath();
        ctx.moveTo(pa.sx, pa.sy);
        ctx.lineTo(pb.sx, pb.sy);
        ctx.strokeStyle = link.kind === "tax" ? "#c45c32" : link.kind.indexOf("shield") >= 0 ? "#4a6d8c" : "#e0a14a";
        ctx.lineWidth = 1.6;
        ctx.stroke();
      });
      ctx.restore();
    }

    fx.coins = fx.coins.filter((p) => p.life > 0);
    fx.coins.forEach((p) => {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.00045;
      p.life -= 0.018;
      ctx.globalAlpha = Math.max(0, p.life);
      ctx.fillStyle = "#e0a14a";
      ctx.beginPath();
      ctx.arc(p.x * g.w, p.y * g.h, 2.4, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
    });

    if (fx.punch > 0) fx.punch *= 0.86;
    if (fx.pulse > 0) fx.pulse *= 0.9;
    fx.t += 1;
  }

  function loop() {
    ctx.save();
    drawDesk(st.phase === "intro" ? { payout: 0, events: [], links: [], cellScore: [] } : settleNow());
    ctx.restore();
    requestAnimationFrame(loop);
  }

  function localPoint(ev) {
    const rect = canvas.getBoundingClientRect();
    const p = ev.touches ? ev.touches[0] : ev;
    return { x: p.clientX - rect.left, y: p.clientY - rect.top };
  }

  canvas.addEventListener("pointermove", (ev) => {
    const p = localPoint(ev);
    fx.hover = cellAt(p.x, p.y);
  });
  canvas.addEventListener("pointerleave", () => { fx.hover = -1; });
  canvas.addEventListener("pointerdown", (ev) => {
    const p = localPoint(ev);
    const i = cellAt(p.x, p.y);
    if (i >= 0) placeSelected(i);
  });

  document.querySelectorAll(".lang-btn[data-lang]").forEach((b) => {
    b.onclick = () => {
      lang = b.dataset.lang === "zh" ? "zh" : "en";
      persist();
      applyLang();
    };
  });
  document.getElementById("soundBtn").onclick = () => {
    soundOn = !soundOn;
    if (window.SFX) {
      SFX.unlock();
      SFX.setMuted(!soundOn);
    }
    persist();
    applyLang();
  };
  document.getElementById("startBtn").onclick = () => {
    if (window.SFX) { SFX.unlock(); SFX.setMuted(!soundOn); }
    newLease();
  };
  document.getElementById("againBtn").onclick = () => {
    if (window.SFX) { SFX.unlock(); SFX.setMuted(!soundOn); }
    newLease();
  };
  document.getElementById("settleBtn").onclick = doSettle;
  document.getElementById("rerollBtn").onclick = doReroll;

  document.getElementById("galleryBtn").onclick = () => { renderGallery(); document.getElementById("gallery").classList.add("show"); };
  document.getElementById("galleryClose").onclick = () => { document.getElementById("gallery").classList.remove("show"); };
  document.getElementById("plateClose").onclick = () => { document.getElementById("plateView").classList.remove("show"); };

  window.addEventListener("resize", resize);
  resize();
  markGallery();
  applyLang();
  requestAnimationFrame(loop);
})();

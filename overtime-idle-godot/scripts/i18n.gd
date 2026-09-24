extends Node
## OCCUPANCY: IDLE (formerly Overtime Landlord) — en / zh / ja.
##
## Autoloaded as "I18n". The shape is play/the-other-side-godot/scripts/i18n.gd's, which is
## play/across-the-hall's, which is play/fold-godot's: one table keyed by language,
## `I18n.t(key)` to read it, `I18n.f(key, args)` for the formatted ones, a `changed` signal,
## the choice saved to user://. The same shape on purpose — a studio with four i18n
## architectures has none, and `ops/subset_cjk.py` parses this exact block layout
## (`"lang": {`) to cut the fonts down to the characters this game can actually show.
##
## WHY. STANDARD.md item 7: en + zh minimum, **ja the priority**. 507 of the 581 DLsite
## works in ops/market/dlsite_data/ are Japanese, and this title's plan is Nutaku first —
## whose storefront is Japanese as well. Shipping English only is not "most of the market",
## it is one of three.
##
## WHAT IS TRANSLATED: everything a player reads. The HUD, the tray, the floor strip, all
## six overlays, the roster's six bios and six rules, the shop's objects, relics and SKUs,
## the ten skill-plate conditions, Mirei's six floor lines and her nine return reports, and
## the title screen. Every line below is written out by hand in all three. Floor 13 shipped
## ja/ko/es whose story files held Chinese prose and someone had to switch them off (memory:
## `renpy-translation-blind-spots`); `ops/check_overtime_loc.py` fails if any zh or ja value
## here is byte-identical to its English or carries no CJK at all. A fourth language that is
## not finished does not go in LANGS.
##
## THE VOICE. Mirei owns the building, is 36, and is never warm. The English is clipped and
## a little cruel. The Japanese is plain form, short, no polite endings and no feminine
## sentence particles — a woman who gives instructions and does not soften them. The Chinese
## is the same register: short sentences, no 啊 / 呢 / 吧. A landlord's line that comes out
## polite in translation is a different character, which is the failure mode here.
##
## NUMBERS STAY OUTSIDE. Every formatted string keeps its %d / %s in the same order in all
## three languages, because `f()` passes one array. Where a language would want a different
## order, the line is rewritten rather than reordered.

signal changed(lang: String)

## Three, and no more than three, because these three are finished. Order is the cycle
## order of the title screen's language control.
const LANGS := ["en", "zh", "ja"]

## What each language calls itself. Never "Chinese" / "Japanese" in English — a language
## picker written in a language you cannot read is useless.
const ENDONYM := {"en": "English", "zh": "简体中文", "ja": "日本語"}

var lang := "en"

const T := {
# =======================================================================================
"en": {
	# ---- title screen --------------------------------------------------------
	"tagline": "THE BUILDING KEEPS EARNING WHILE YOU ARE AWAY",
	"start": "OPEN THE BUILDING",
	"footer": "FLAT 404   ·   Everyone depicted is an adult.",
	# ---- HUD -----------------------------------------------------------------
	"hud_name": "OCCUPANCY",
	"hud_sub": "AFTER HOURS · IDLE · 18+",
	"hud_sub_n": "AFTER HOURS · IDLE · 18+   ·   BUILDING %d",
	"rent_hour": "RENT / HOUR",
	"bank": "BANK",
	"gold": "GOLD",
	"chain": "CHAIN ",
	"next_shift": "NEXT SHIFT",
	"roster_btn": "ROSTER",
	"shop_btn": "SHOP",
	"daily_btn": "DAILY",
	"plates_btn": "PLATES %d/%d",
	"sound_on": "SOUND ON",
	"sound_off": "SOUND OFF",
	"floors": "FLOORS",
	"relics": "RELICS",
	"rent_due": "RENT DUE / DAY",
	"board_day": "THIS BOARD / DAY",
	"covers": "COVERS ×%.1f",
	"short_day": "SHORT %d/d",
	"plates_count": "PLATES %d/%d",
	# ---- tray and floor ------------------------------------------------------
	"offers": "OFFERS — pick one, then tap an open desk. Tap a placed piece to send it back.",
	"reroll": "REROLL · %d",
	"reroll_none": "REROLL · —",
	"commit": "COMMIT",
	"shift_mult": "SHIFT %d   ×%.2f",
	"floor_hdr": "FLOOR %d · 5 × 4",
	"out_of_pieces": "Out of pieces. Settle.",
	"roster_empty": "The roster is empty — pull, or buy objects.",
	"floor_btn": "F%d  ·  %d/shift",
	"add_floor": "+ FLOOR %d  ·  %d",
	"daily_strip": "DAILY · %s",
	"back_building": "« BUILDING",
	"daily_pieces": "%d / 12 pieces",
	"daily_same": "DAILY FLOOR · SAME PIECES FOR EVERYONE",
	"shield_used": "A rent shield covered one eviction.",
	# ---- Mirei, on the floor --------------------------------------------------
	"m_empty": "Empty is not a strategy.",
	"m_calm": "Rent is covered. Do not redecorate.",
	"m_tense": "Close. The day is long.",
	"m_fail": "That floor will not make the day.",
	"m_chain": "Who authorized this synergy?",
	"m_place": "Put it where it earns.",
	"mood_calm": "CALM", "mood_tense": "TENSE", "mood_fail": "FAIL", "mood_empty": "EMPTY",
	"mirei_card": "MIREI, 36 · LANDLORD",
	# ---- the return screen ----------------------------------------------------
	"while_gone": "WHILE YOU WERE GONE",
	"shifts": "SHIFTS",
	"rent": "RENT",
	"per_hour": "/ HOUR",
	"collect": "COLLECT",
	"extend_cap": "EXTEND TO 24 HOURS · 120 GOLD",
	"floor_n": "Floor %d",
	"evicted_tag": "EVICTED",
	"froze_note": "The building froze after %d h. Offline shifts stop at the cap — extend it once, for good.",
	"rent_taken": "Daily rent taken: %d",
	# Mirei's report. Nine lines, picked by what actually happened.
	"r_evicted": "A floor missed rent. I cleared it. The people are fine; the furniture is not.",
	"r_shielded": "A floor missed rent and your shield covered it. Once.",
	"r_capped": "It stopped after the cap. I am a landlord, not a charity — extend it if you want it to keep going.",
	"r_nothing": "Nothing happened, because nothing was placed. An empty floor is not a strategy.",
	"r_first": "You came back. Most do not. The floor ran without you, which is the whole point.",
	"r_rich": "The building made more while you were gone than you did while you were here. Do not take it personally.",
	"r_ok": "Shifts ran. Rent came in. I did not have to call anyone.",
	"r_thin": "It ran. Barely. Put something next to something.",
	# ---- roster ---------------------------------------------------------------
	"roster_tag": "STAFF · THE GACHA",
	"roster_title": "Roster",
	"pull_1_btn": "PULL ×1 · 30",
	"pull_10_btn": "PULL ×10 · 270",
	"close": "CLOSE",
	"roster_para": "Everyone is a rule. Pull new people; a duplicate gives that person +5% per shift, capped at +50%. Pity: an epic within 30 pulls.",
	"pity": "Epic guaranteed within %d pulls  ·  Gold %d  ·  tickets %d",
	"new_hires": "NEW HIRES",
	"take_them": "TAKE THEM TO THE FLOOR",
	"not_pulled": "Not pulled yet.",
	"on_floor": "on floor %d/%d · dupes %d (+%d%%) · shifts %d",
	"max": "MAX",
	"dupe_bonus": "DUPE  +5%",
	"unknown": "???",
	"common": "COMMON", "rare": "RARE", "epic": "EPIC",
	# the six, their rule and their bio
	"n_dan": "Dan, 41",
	"rule_dan": "Coffee beside him triples. Headphones beside him +2.",
	"bio_dan": "The last engineer who never goes home. He says the build is green and the trains have stopped, and both are true. The coffee chain runs through him because he is the only one still drinking it at two in the morning.",
	"n_priya": "Priya, 29",
	"rule_priya": "Copies the best base beside her.",
	"bio_priya": "Facilities contractor, three nights a week. Covers whoever she is standing next to — it is her mechanic and her joke. She has keys she is not supposed to have and a very good reason for each.",
	"n_mara": "Mara, 34",
	"rule_mara": "Every neighbour +1.",
	"bio_mara": "Night-shift building manager. Keys to every floor, opinions about every tenant. Lifts everyone around her by one because she has already done their job once, quietly, before they got in.",
	"n_wes": "Wes, 36",
	"rule_wes": "Taxes unshielded Dan and Priya beside him. Tag: noise.",
	"bio_wes": "The tenant on 7 who sublets space he does not have. His meetings are a tax on anyone who cannot put headphones on. He is charming for exactly as long as it takes.",
	"n_nia": "Nia, 33",
	"rule_nia": "Audits Wes: each Wes beside her pays her his 2.",
	"bio_nia": "Forensic accountant, brought in by Mirei to find out what the tenant on 7 is actually paying for. Sits down next to him on purpose. Wes has never once finished a sentence in her presence.",
	"n_sol": "Sol, 38",
	"rule_sol": "Coffee beside her +2 to her. Floor: every other staff +1.",
	"bio_sol": "Night editor for a paper that stopped printing. Still files at four. The whole floor works later when she is on it, and nobody can say why, and nobody has asked her to leave.",
	# ---- objects and relics ---------------------------------------------------
	"n_coffee": "Coffee", "n_coffee_shop": "Coffee machine",
	"n_mute": "Headphones", "n_printer": "Printer", "n_corner": "Corner desk",
	"h_coffee": "Triples Dan beside it.",
	"h_mute": "Covers staff beside it from Wes's tax.",
	"h_printer": "+1 per occupied desk in its row.",
	"h_corner": "3, but only in a corner.",
	"rl_severance": "Severance", "rl_quiet": "Quiet Floor", "rl_pto": "Unlimited PTO",
	"rl_glass": "Glass Office", "rl_badge": "Badge Reel", "rl_army": "Intern Army",
	"rh_severance": "Empty desks pay 1 each.",
	"rh_quiet": "Headphones cover diagonals too.",
	"rh_pto": "First reroll per floor is free.",
	"rh_glass": "Meetings no longer tax. Rent +10%.",
	"rh_badge": "+1 per chain event.",
	"rh_army": "Priya takes the best settled score beside her.",
	# ---- shop -----------------------------------------------------------------
	"shop_tag": "PROCUREMENT · PAID IN RENT",
	"shop_title": "Shop",
	"shop_para": "Objects and relics are bought with rent. Gold buys time, pulls and a shield — never a rule.",
	"shop_gold_row": "GOLD · TIME, PULLS, A SHIELD.  IAP ROW IS MOCKED IN THIS BUILD.",
	"shop_gold_tag": "GOLD %d  ·  bank %d  ·  tickets %d  ·  shields %d",
	"k_object": "OBJECT", "k_relic": "RELIC", "k_sku": "GOLD SKU", "k_iap": "IAP (MOCKED)",
	"price_rent": "rent %d", "price_gold": "Gold %d", "owned": "owned",
	"sku_timeskip_4h": "Collect four hours of shifts now",
	"sku_offline_cap_24h": "Offline earnings cap 8h -> 24h, forever",
	"sku_pull_1": "One pull",
	"sku_pull_10": "Ten pulls",
	"sku_rent_shield": "Skip one eviction",
	"sku_gold_s": "100 Gold", "sku_gold_m": "600 Gold", "sku_gold_l": "3000 Gold",
	"sku_scene_skip": "See the scene now",
	"iap_note": "Prototype: the store call is simulated. On Nutaku the GPHS PUT grants this.",
	# ---- gallery --------------------------------------------------------------
	"gal_tag": "PLATES",
	"gal_title": "Gallery",
	"gal_skill": "SKILL — A BOARD YOU BUILT. NEVER FROM TIME.",
	"gal_aff": "AFFECTION — SHIFTS WORKED ON A SOLVENT FLOOR. THIS ONE IS TIME, AND SAYS SO.",
	"gal_shifts": "%d shifts",
	"gal_tier4": "TIER 4 · PLACEHOLDER",
	"gal_tier4_locked": "300 shifts · or scene_skip at 150 (80 Gold)",
	"gal_placeholder": " (tier-4 scene: placeholder, Blaze's own)",
	"locked_caption": "  ·  LOCKED · IN THE FULL VERSION",
	# the skill ladder's ten conditions, and who each plate is of
	"who_mirei": "Mirei", "who_dan": "Dan", "who_priya": "Priya", "who_mara": "Mara",
	"who_wes": "Wes", "who_mirei_priya": "Mirei & Priya", "who_ninth": "The ninth floor",
	"who_badge": "The badge",
	"p_lease": "Make rent on any floor with a surplus.",
	"p_dan": "Three coffee->Dan multipliers in one settle.",
	"p_priya": "Settle with 3+ staff placed, someone shielded, and no tax from Wes.",
	"p_mara": "Hold all four corners with corner desks.",
	"p_wes": "With the Intern Army relic, four copies in one settle.",
	"p_quiet": "With Quiet Floor, clear a settle with a six-link chain.",
	"p_glass": "With Glass Office, make rent on floor 6 or later.",
	"p_vault": "Bank 40 or more.",
	"p_floor9": "Reach floor nine.",
	"p_evicted": "Get evicted. It happens.",
	# ---- daily floor, prestige, eviction notice -------------------------------
	"daily_tag": "DAILY FLOOR",
	"daily_title": "Everyone gets the same pieces today",
	"daily_para": "One layout, the same for every landlord today. Score is your best single settle. The pieces are the building's, not your roster's.",
	"daily_best": "Today's best: %d",
	"daily_none": "Not played today.",
	"daily_play": "PLAY TODAY'S FLOOR",
	"daily_settled": "DAILY FLOOR · SETTLED",
	"daily_per_shift": " / shift",
	"daily_beat": "You beat ",
	"daily_beat_end": "% of landlords.",
	"daily_result": "Today's best %d · chain %d",
	"daily_back": "BACK TO THE BUILDING",
	"pres_tag": "ACQUISITION",
	"pres_title": "A second building",
	"pres_para": "Seven days with every floor solvent. Mirei has found a bigger building. You start it empty — the roster comes with you — and every shift in it pays ×1.5.",
	"pres_no": "NOT YET",
	"pres_yes": "SIGN",
	"notice_tag": "NOTICE",
	"notice_title": "Evicted",
	"notice_body": "Floor %s did not cover the day's rent. Cleared. The people are back in the roster; the objects are gone.",
	"understood": "UNDERSTOOD",
	"aff_caption": "%s — affection %d",
	"daily_caption": "DAILY FLOOR · 5 × 4",
	"no_relics": "No relics yet.",
	"floor_caption_b": "  ·  B%d ×%s",
	# ---- banners --------------------------------------------------------------
	"b_no_gold": "Not enough Gold.",
	"b_no_rent": "Not enough rent.",
	"b_cap_24": "Offline cap is now 24 hours.",
	"b_back_roster": "%s is back in the roster.",
	"b_pick_first": "Pick a piece from the tray first.",
	"b_desk_taken": "That desk is taken.",
	"b_nothing": "Nothing to settle.",
	"b_committed": "Committed. The shifts take it from here.",

},
# =======================================================================================
"zh": {
	"tagline": "你不在的时候，楼还在收租",
	"start": "开 楼",
	"footer": "FLAT 404   ·   画面中人物均为成年人。",
	"hud_name": "OCCUPANCY",
	"hud_sub": "深夜 · 挂机 · 18+",
	"hud_sub_n": "深夜 · 挂机 · 18+   ·   第 %d 栋",
	"rent_hour": "每小时租金",
	"bank": "账上",
	"gold": "金币",
	"chain": "连锁 ",
	"next_shift": "下一班",
	"roster_btn": "人事",
	"shop_btn": "采购",
	"daily_btn": "每日",
	"plates_btn": "图 %d/%d",
	"sound_on": "声音 开",
	"sound_off": "声音 关",
	"floors": "楼层",
	"relics": "藏品",
	"rent_due": "每日应付租",
	"board_day": "本层每日产出",
	"covers": "覆盖 ×%.1f",
	"short_day": "每日缺口 %d",
	"plates_count": "图 %d/%d",
	"offers": "候选 —— 先选一个，再点空工位。点已放下的可以收回。",
	"reroll": "换一批 · %d",
	"reroll_none": "换一批 · —",
	"commit": "结 班",
	"shift_mult": "本班 %d   ×%.2f",
	"floor_hdr": "第 %d 层 · 5 × 4",
	"out_of_pieces": "没牌了，结班吧。",
	"roster_empty": "人事是空的 —— 去抽人，或者买设备。",
	"floor_btn": "%d层  ·  每班 %d",
	"add_floor": "+ 第 %d 层  ·  %d",
	"daily_strip": "每日 · %s",
	"back_building": "« 回楼里",
	"daily_pieces": "%d / 12 块",
	"daily_same": "每日楼层 · 所有人同一副牌",
	"shield_used": "一次清退被护盾挡下了。",
	"m_empty": "空着不叫策略。",
	"m_calm": "租金够了。别再动布置。",
	"m_tense": "差一点。今天还长。",
	"m_fail": "这一层撑不到今晚。",
	"m_chain": "这种协同谁批准的？",
	"m_place": "放到能挣钱的位置。",
	"mood_calm": "稳", "mood_tense": "紧", "mood_fail": "崩", "mood_empty": "空",
	"mirei_card": "美玲，36 · 房东",
	"while_gone": "你不在的这段时间",
	"shifts": "班次",
	"rent": "租金",
	"per_hour": "每小时",
	"collect": "收 走",
	"extend_cap": "上限延到 24 小时 · 120 金币",
	"floor_n": "第 %d 层",
	"evicted_tag": "已清退",
	"froze_note": "%d 小时后这栋楼就停了。离线班次卡在上限 —— 花一次钱，永久解决。",
	"rent_taken": "已扣当日租金：%d",
	"r_evicted": "有一层没交上租，我清了。人没事，家具没了。",
	"r_shielded": "有一层没交上租，你的护盾挡了。就这一次。",
	"r_capped": "到上限就停了。我是房东，不是慈善家 —— 想让它一直跑就把上限买了。",
	"r_nothing": "什么都没发生，因为你什么都没放。空楼层不叫策略。",
	"r_first": "你回来了。多数人不回。楼没有你也照跑，这才是重点。",
	"r_rich": "你不在的时候，这栋楼挣的比你在的时候还多。别往心里去。",
	"r_ok": "班照上，租照收。我一个电话都没打。",
	"r_thin": "跑是跑了，勉强。把东西放到东西旁边去。",
	"roster_tag": "员工 · 抽卡",
	"roster_title": "人事",
	"pull_1_btn": "抽 ×1 · 30",
	"pull_10_btn": "抽 ×10 · 270",
	"close": "关闭",
	"roster_para": "每个人都是一条规则。抽新人；重复的人每班 +5%，最多 +50%。保底：30 抽内必出史诗。",
	"pity": "%d 抽内必出史诗  ·  金币 %d  ·  抽卡券 %d",
	"new_hires": "新 人",
	"take_them": "带他们上楼",
	"not_pulled": "还没抽到。",
	"on_floor": "在岗 %d/%d · 重复 %d（+%d%%） · 班次 %d",
	"max": "满",
	"dupe_bonus": "重复  +5%",
	"unknown": "？？？",
	"common": "普通", "rare": "稀有", "epic": "史诗",
	"n_dan": "丹，41",
	"rule_dan": "旁边有咖啡，三倍。旁边有耳机，+2。",
	"bio_dan": "最后一个不回家的工程师。他说构建是绿的、末班车也停了，两句都是真的。咖啡链从他这里走，因为凌晨两点只剩他还在喝。",
	"n_priya": "普莉娅，29",
	"rule_priya": "复制旁边最好的基础分。",
	"bio_priya": "后勤外包，一周来三个晚上。谁站在她旁边她就顶谁的班 —— 这是她的机制，也是她的笑话。她手上有一串不该有的钥匙，每一把都有很正当的理由。",
	"n_mara": "玛拉，34",
	"rule_mara": "每个邻居 +1。",
	"bio_mara": "夜班楼管。每层楼的钥匙都有，每个租客都有意见。她把周围所有人抬高一格，因为这些活她早就悄悄替人干过一遍。",
	"n_wes": "韦斯，36",
	"rule_wes": "抽税旁边没被护住的丹和普莉娅。标签：噪音。",
	"bio_wes": "七楼那个把自己没有的工位转租出去的人。他的会议是一道税，收在所有戴不上耳机的人头上。他的魅力刚好够撑到你发现为止。",
	"n_nia": "妮娅，33",
	"rule_nia": "查账韦斯：旁边每个韦斯把他的 2 分交给她。",
	"bio_nia": "法务会计，美玲请来查七楼那位到底在付什么钱。她是故意坐到他旁边的。韦斯在她面前从来没说完过一句话。",
	"n_sol": "索尔，38",
	"rule_sol": "旁边有咖啡，她 +2。全层：其他员工各 +1。",
	"bio_sol": "一家已经停印的报纸的夜班编辑。四点还在发稿。她在的时候整层楼都收工更晚，没人说得清为什么，也没人请她走。",
	"n_coffee": "咖啡", "n_coffee_shop": "咖啡机",
	"n_mute": "耳机", "n_printer": "打印机", "n_corner": "角位工位",
	"h_coffee": "让旁边的丹三倍。",
	"h_mute": "护住旁边的员工，不被韦斯抽税。",
	"h_printer": "同一行每个有人的工位 +1。",
	"h_corner": "3 分，但只在角上算。",
	"rl_severance": "遣散费", "rl_quiet": "安静楼层", "rl_pto": "无限假期",
	"rl_glass": "玻璃办公室", "rl_badge": "工牌绳", "rl_army": "实习生大军",
	"rh_severance": "空工位每个给 1。",
	"rh_quiet": "耳机连斜角也护。",
	"rh_pto": "每层第一次换牌免费。",
	"rh_glass": "会议不再抽税。租金 +10%。",
	"rh_badge": "每触发一次连锁 +1。",
	"rh_army": "普莉娅拿旁边结算后的最高分。",
	"shop_tag": "采购 · 用租金付",
	"shop_title": "采购",
	"shop_para": "设备和藏品用租金买。金币买时间、抽卡和护盾 —— 永远不卖规则。",
	"shop_gold_row": "金币 · 时间、抽卡、护盾。本版本内购为模拟。",
	"shop_gold_tag": "金币 %d  ·  账上 %d  ·  抽卡券 %d  ·  护盾 %d",
	"k_object": "设备", "k_relic": "藏品", "k_sku": "金币商品", "k_iap": "内购（模拟）",
	"price_rent": "租金 %d", "price_gold": "金币 %d", "owned": "已有",
	"sku_timeskip_4h": "立刻收下四小时的班次",
	"sku_offline_cap_24h": "离线收益上限 8 小时 → 24 小时，永久",
	"sku_pull_1": "抽一次",
	"sku_pull_10": "抽十次",
	"sku_rent_shield": "免掉一次清退",
	"sku_gold_s": "100 金币", "sku_gold_m": "600 金币", "sku_gold_l": "3000 金币",
	"sku_scene_skip": "现在就看这段",
	"iap_note": "原型：商店调用是模拟的。上 Nutaku 时由 GPHS PUT 发货。",
	"gal_tag": "图鉴",
	"gal_title": "图鉴",
	"gal_skill": "技巧 —— 你自己摆出来的局，跟时间无关。",
	"gal_aff": "好感 —— 在不亏的楼层上班攒的。这一列就是时间，明说。",
	"gal_shifts": "%d 班",
	"gal_tier4": "第四级 · 占位图",
	"gal_tier4_locked": "300 班 · 或 150 班时花 80 金币直接看",
	"gal_placeholder": "（第四级场景：占位图，Blaze 自己的）",
	"locked_caption": "  ·  未解锁 · 完整版内提供",
	"who_mirei": "美玲", "who_dan": "丹", "who_priya": "普莉娅", "who_mara": "玛拉",
	"who_wes": "韦斯", "who_mirei_priya": "美玲与普莉娅", "who_ninth": "第九层",
	"who_badge": "那张工牌",
	"p_lease": "任意一层收租有结余。",
	"p_dan": "一次结班里触发三次咖啡→丹的倍率。",
	"p_priya": "结班时场上 3 个以上员工、有人被护住、且韦斯没抽到税。",
	"p_mara": "四个角全用角位工位占住。",
	"p_wes": "带着实习生大军，一次结班里出现四个他。",
	"p_quiet": "带着安静楼层，打出六连锁的一次结班。",
	"p_glass": "带着玻璃办公室，在第 6 层或更高的楼层收够租。",
	"p_vault": "账上存到 40 以上。",
	"p_floor9": "开到第九层。",
	"p_evicted": "被清退一次。这很正常。",
	"daily_tag": "每日楼层",
	"daily_title": "今天所有人拿到的牌都一样",
	"daily_para": "今天只有一副布局，全服房东共用。成绩取你单次结班的最好值。牌是楼里的，不是你人事里的。",
	"daily_best": "今日最好：%d",
	"daily_none": "今天还没玩。",
	"daily_play": "玩今天这一层",
	"daily_settled": "每日楼层 · 已结算",
	"daily_per_shift": " / 班",
	"daily_beat": "你赢过了 ",
	"daily_beat_end": "% 的房东。",
	"daily_result": "今日最好 %d · 连锁 %d",
	"daily_back": "回楼里去",
	"pres_tag": "并 购",
	"pres_title": "第二栋楼",
	"pres_para": "连续七天每层都不亏。美玲找到了一栋更大的楼。新楼是空的 —— 人事跟着你走 —— 里面每一班都 ×1.5。",
	"pres_no": "再等等",
	"pres_yes": "签",
	"notice_tag": "通知",
	"notice_title": "清退",
	"notice_body": "第 %s 层没交够当天的租金。已清空。人回到人事，东西没了。",
	"understood": "知道了",
	"aff_caption": "%s —— 好感 %d",
	"daily_caption": "每日楼层 · 5 × 4",
	"no_relics": "还没有藏品。",
	"floor_caption_b": "  ·  第%d栋 ×%s",
	"b_no_gold": "金币不够。",
	"b_no_rent": "租金不够。",
	"b_cap_24": "离线上限已改为 24 小时。",
	"b_back_roster": "%s 回到了人事。",
	"b_pick_first": "先从候选里选一个。",
	"b_desk_taken": "这个工位有人了。",
	"b_nothing": "没有可结算的。",
	"b_committed": "已结。接下来交给班次。",

},
# =======================================================================================
"ja": {
	"tagline": "あなたが留守の間も、ビルは稼いでいる",
	"start": "ビルを開ける",
	"footer": "FLAT 404   ·   登場人物はすべて成人です。",
	"hud_name": "OCCUPANCY",
	"hud_sub": "深夜 · 放置 · 18+",
	"hud_sub_n": "深夜 · 放置 · 18+   ·   %d 棟目",
	"rent_hour": "時給家賃",
	"bank": "残高",
	"gold": "ゴールド",
	"chain": "連鎖 ",
	"next_shift": "次のシフト",
	"roster_btn": "人事",
	"shop_btn": "調達",
	"daily_btn": "日替り",
	"plates_btn": "絵 %d/%d",
	"sound_on": "音 オン",
	"sound_off": "音 オフ",
	"floors": "フロア",
	"relics": "備品",
	"rent_due": "一日の家賃",
	"board_day": "このフロアの日収",
	"covers": "充足 ×%.1f",
	"short_day": "日 %d 不足",
	"plates_count": "絵 %d/%d",
	"offers": "手札 —— 一枚選んでから空席をタップ。置いた駒はタップで戻る。",
	"reroll": "引き直し · %d",
	"reroll_none": "引き直し · —",
	"commit": "締める",
	"shift_mult": "シフト %d   ×%.2f",
	"floor_hdr": "%d 階 · 5 × 4",
	"out_of_pieces": "手札切れ。締めろ。",
	"roster_empty": "人事が空だ —— 引くか、備品を買え。",
	"floor_btn": "%d階  ·  毎シフト %d",
	"add_floor": "+ %d 階  ·  %d",
	"daily_strip": "日替り · %s",
	"back_building": "« ビルへ",
	"daily_pieces": "%d / 12 枚",
	"daily_same": "日替りフロア · 全員同じ手札",
	"shield_used": "立ち退き一回をシールドが肩代わりした。",
	"m_empty": "空室は戦略じゃない。",
	"m_calm": "家賃は足りた。模様替えはするな。",
	"m_tense": "惜しい。一日は長い。",
	"m_fail": "このフロアでは今日は持たない。",
	"m_chain": "この相乗効果、誰が許可した。",
	"m_place": "稼げる場所に置け。",
	"mood_calm": "平静", "mood_tense": "緊迫", "mood_fail": "破綻", "mood_empty": "空室",
	"mirei_card": "ミレイ、36 · 大家",
	"while_gone": "あなたが留守の間に",
	"shifts": "シフト",
	"rent": "家賃",
	"per_hour": "時給",
	"collect": "受け取る",
	"extend_cap": "上限を 24 時間へ · 120 ゴールド",
	"floor_n": "%d 階",
	"evicted_tag": "立ち退き",
	"froze_note": "%d 時間でビルは止まった。オフラインのシフトは上限で打ち切りだ —— 一度払えば、以後ずっと回る。",
	"rent_taken": "本日の家賃を徴収：%d",
	"r_evicted": "家賃を落としたフロアがあった。片付けた。人は無事、家具は無事じゃない。",
	"r_shielded": "家賃を落としたフロアをシールドが肩代わりした。一度だけだ。",
	"r_capped": "上限で止まった。私は大家であって慈善家じゃない —— 回し続けたいなら上限を買え。",
	"r_nothing": "何も起きなかった。何も置かなかったからだ。空のフロアは戦略じゃない。",
	"r_first": "戻ってきたな。たいていは戻らない。あなた抜きでフロアは回った、それがこの仕事の全部だ。",
	"r_rich": "あなたが留守の間の稼ぎのほうが、いた間より多い。個人的に受け取るな。",
	"r_ok": "シフトは回り、家賃は入った。誰にも電話せずに済んだ。",
	"r_thin": "回った。ぎりぎりだ。何かの隣に何かを置け。",
	"roster_tag": "従業員 · ガチャ",
	"roster_title": "人事",
	"pull_1_btn": "単発 ×1 · 30",
	"pull_10_btn": "十連 ×10 · 270",
	"close": "閉じる",
	"roster_para": "全員が一つのルールだ。新しい人を引け。重複はその人のシフト収入 +5%、上限 +50%。天井：30 連以内にエピック。",
	"pity": "%d 連以内にエピック確定  ·  ゴールド %d  ·  チケット %d",
	"new_hires": "新 入 り",
	"take_them": "フロアへ連れて行く",
	"not_pulled": "まだ引いていない。",
	"on_floor": "配置 %d/%d · 重複 %d（+%d%%） · シフト %d",
	"max": "上限",
	"dupe_bonus": "重複  +5%",
	"unknown": "？？？",
	"common": "コモン", "rare": "レア", "epic": "エピック",
	"n_dan": "ダン、41",
	"rule_dan": "隣のコーヒーで三倍。隣のヘッドホンで +2。",
	"bio_dan": "家に帰らない最後のエンジニア。ビルドは緑で終電はもう無い、と言う。どちらも本当だ。コーヒーの連鎖が彼を通るのは、午前二時にまだ飲んでいるのが彼だけだからだ。",
	"n_priya": "プリヤ、29",
	"rule_priya": "隣で一番高い基礎点をコピーする。",
	"bio_priya": "設備の請負、週に三晩。隣に立った相手を誰でも肩代わりする —— それが彼女の仕組みで、彼女の冗談だ。持っているはずのない鍵を持っていて、一本ごとにちゃんとした理由がある。",
	"n_mara": "マーラ、34",
	"rule_mara": "隣接する全員に +1。",
	"bio_mara": "夜勤のビル管理。全フロアの鍵と、全テナントへの意見を持っている。周りを一段引き上げるのは、彼らの仕事を先に黙って一度やってあるからだ。",
	"n_wes": "ウェス、36",
	"rule_wes": "隣の無防備なダンとプリヤに課税する。タグ：騒音。",
	"bio_wes": "持ってもいない区画を又貸ししている七階の住人。彼の会議は、ヘッドホンを着けられない全員にかかる税だ。魅力が保つのは、ばれるまでの間だけ。",
	"n_nia": "ニア、33",
	"rule_nia": "ウェスを監査：隣のウェス一人につき、彼の 2 点を彼女が取る。",
	"bio_nia": "法廷会計士。七階の住人が実際に何の金を払っているのか調べるためにミレイが呼んだ。わざと隣に座る。ウェスは彼女の前で一度も文を言い終えたことがない。",
	"n_sol": "ソル、38",
	"rule_sol": "隣のコーヒーで彼女に +2。フロア：他の従業員全員に +1。",
	"bio_sol": "印刷をやめた新聞の夜編集。今も四時に原稿を出す。彼女がいるとフロア全体の終業が遅くなる。理由は誰にも説明できず、誰も出て行けとは言わない。",
	"n_coffee": "コーヒー", "n_coffee_shop": "コーヒーメーカー",
	"n_mute": "ヘッドホン", "n_printer": "プリンター", "n_corner": "角席",
	"h_coffee": "隣のダンを三倍にする。",
	"h_mute": "隣の従業員をウェスの課税から守る。",
	"h_printer": "同じ行の埋まった席ごとに +1。",
	"h_corner": "3 点、ただし角に置いたときだけ。",
	"rl_severance": "退職金", "rl_quiet": "静かなフロア", "rl_pto": "無制限休暇",
	"rl_glass": "ガラス張りの部屋", "rl_badge": "社員証ストラップ", "rl_army": "インターン軍団",
	"rh_severance": "空席が一つにつき 1 払う。",
	"rh_quiet": "ヘッドホンが斜めも守る。",
	"rh_pto": "各フロア最初の引き直しが無料。",
	"rh_glass": "会議が課税しなくなる。家賃 +10%。",
	"rh_badge": "連鎖が起きるたび +1。",
	"rh_army": "プリヤが隣の締め後の最高点を取る。",
	"shop_tag": "調達 · 支払いは家賃",
	"shop_title": "調達",
	"shop_para": "備品と収蔵品は家賃で買う。ゴールドで買えるのは時間と回数とシールドだけ —— ルールは売らない。",
	"shop_gold_row": "ゴールド · 時間、ガチャ、シールド。この版の課金は模擬です。",
	"shop_gold_tag": "ゴールド %d  ·  残高 %d  ·  チケット %d  ·  シールド %d",
	"k_object": "備品", "k_relic": "収蔵品", "k_sku": "ゴールド商品", "k_iap": "課金（模擬）",
	"price_rent": "家賃 %d", "price_gold": "ゴールド %d", "owned": "所持済み",
	"sku_timeskip_4h": "四時間分のシフトを今すぐ回収",
	"sku_offline_cap_24h": "オフライン上限 8 時間 → 24 時間、永久",
	"sku_pull_1": "単発一回",
	"sku_pull_10": "十連一回",
	"sku_rent_shield": "立ち退きを一回免除",
	"sku_gold_s": "100 ゴールド", "sku_gold_m": "600 ゴールド", "sku_gold_l": "3000 ゴールド",
	"sku_scene_skip": "この場面を今すぐ見る",
	"iap_note": "試作：ストア呼び出しは模擬です。Nutaku では GPHS の PUT で付与されます。",
	"gal_tag": "原画",
	"gal_title": "原画",
	"gal_skill": "技量 —— あなたが組んだ盤面。時間では手に入らない。",
	"gal_aff": "好感 —— 黒字のフロアで働いたシフト。こちらは時間だ、と正直に言う。",
	"gal_shifts": "%d シフト",
	"gal_tier4": "第四段階 · 仮画像",
	"gal_tier4_locked": "300 シフト · または 150 で 80 ゴールド",
	"gal_placeholder": "（第四段階の場面：仮画像、Blaze 本人の手によるもの）",
	"locked_caption": "  ·  未開放 · 製品版に収録",
	"who_mirei": "ミレイ", "who_dan": "ダン", "who_priya": "プリヤ", "who_mara": "マーラ",
	"who_wes": "ウェス", "who_mirei_priya": "ミレイとプリヤ", "who_ninth": "九階",
	"who_badge": "あの社員証",
	"p_lease": "どれか一つのフロアを黒字で締める。",
	"p_dan": "一度の締めでコーヒー→ダンの倍率を三回起こす。",
	"p_priya": "従業員を 3 人以上置き、誰かが守られ、ウェスの課税なしで締める。",
	"p_mara": "四隅すべてを角席で押さえる。",
	"p_wes": "インターン軍団を持ち、一度の締めで彼を四人出す。",
	"p_quiet": "静かなフロアを持ち、六連鎖で締める。",
	"p_glass": "ガラス張りの部屋を持ち、6 階以上で家賃を満たす。",
	"p_vault": "残高を 40 以上にする。",
	"p_floor9": "九階まで建てる。",
	"p_evicted": "一度立ち退かれる。よくあることだ。",
	"daily_tag": "日替りフロア",
	"daily_title": "今日は全員が同じ手札だ",
	"daily_para": "今日の盤面は一つだけ、どの大家にも同じものが配られる。記録は一度の締めの最高値。手札はビルのもので、あなたの人事のものではない。",
	"daily_best": "本日の最高：%d",
	"daily_none": "今日はまだ。",
	"daily_play": "今日のフロアを遊ぶ",
	"daily_settled": "日替りフロア · 締め済み",
	"daily_per_shift": " / シフト",
	"daily_beat": "あなたは大家の ",
	"daily_beat_end": "% に勝った。",
	"daily_result": "本日の最高 %d · 連鎖 %d",
	"daily_back": "ビルへ戻る",
	"pres_tag": "買 収",
	"pres_title": "二棟目",
	"pres_para": "七日続けて全フロアが黒字。ミレイがもっと大きいビルを見つけた。新しいビルは空で始まる —— 人事は連れて行ける —— そこでのシフトはすべて ×1.5 だ。",
	"pres_no": "まだだ",
	"pres_yes": "署名する",
	"notice_tag": "通知",
	"notice_title": "立ち退き",
	"notice_body": "%s 階がその日の家賃に届かなかった。引き払った。人は人事に戻り、物は無くなった。",
	"understood": "了解した",
	"aff_caption": "%s —— 好感 %d",
	"daily_caption": "日替りフロア · 5 × 4",
	"no_relics": "収蔵品はまだない。",
	"floor_caption_b": "  ·  %d棟目 ×%s",
	"b_no_gold": "ゴールドが足りない。",
	"b_no_rent": "家賃が足りない。",
	"b_cap_24": "オフライン上限を 24 時間にした。",
	"b_back_roster": "%s は人事に戻った。",
	"b_pick_first": "先に手札から一枚選べ。",
	"b_desk_taken": "その席は埋まっている。",
	"b_nothing": "締めるものがない。",
	"b_committed": "締めた。あとはシフトがやる。",

},
}

const CFG := "user://lang.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	lang = _saved()
	if lang not in LANGS:
		lang = _from_url()
	if lang not in LANGS:
		lang = _from_os()
	if lang not in LANGS:
		lang = "en"


func _saved() -> String:
	var c := ConfigFile.new()
	if c.load(CFG) != OK:
		return ""
	return str(c.get_value("i18n", "lang", ""))


## An explicit ?lang= wins on the web: that is how a Japanese storefront link lands on a
## Japanese page without the player having to find the control first. Nutaku and DLsite
## both send traffic that way.
func _from_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var q = JavaScriptBridge.eval(
		"(new URLSearchParams(location.search).get('lang')||'')", true)
	return _narrow(str(q) if q != null else "")


func _from_os() -> String:
	return _narrow(OS.get_locale())


## A BCP-47-ish tag narrowed to what is actually finished here. "zh-TW" is deliberately NOT
## mapped to "zh": Traditional is not written yet, and a Taiwanese player is better served
## by English than by Simplified pretending to be their language.
func _narrow(code: String) -> String:
	var c := code.strip_edges().replace("_", "-").to_lower()
	if c.begins_with("ja"):
		return "ja"
	if c == "zh" or c.begins_with("zh-cn") or c.begins_with("zh-hans") or c.begins_with("zh-sg"):
		return "zh"
	if c.begins_with("en"):
		return "en"
	return ""


func set_lang(next: String) -> void:
	if next not in LANGS or next == lang:
		return
	lang = next
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("i18n", "lang", lang)
	c.save(CFG)
	changed.emit(lang)


func cycle() -> void:
	set_lang(LANGS[(LANGS.find(lang) + 1) % LANGS.size()])


## One string. Falls back to English, then to the key itself — a missing key shows up as a
## visible key on screen rather than as an empty label nobody notices.
func t(key: String) -> String:
	var table: Dictionary = T[lang]
	if table.has(key):
		return str(table[key])
	return str(T["en"].get(key, key))


## A formatted one. `value` is whatever `%` takes: a single value or an Array.
func f(key: String, value: Variant) -> String:
	return t(key) % value


## True when the current language needs the CJK face. The Latin faces have no CJK glyphs
## and Godot draws a missing glyph as a blank box, not as an error.
func needs_cjk() -> bool:
	return lang != "en"

extends Node
## OFFICE LANDLORD — en / zh / ja. Autoloaded as "I18n".
##
## Shape matches play/overtime-idle-godot/scripts/i18n.gd (STANDARD.md item 7: en + zh
## minimum, ja the priority): one table keyed by language, I18n.t(key) to read it, a
## `changed` signal, the choice saved to user://. Every line below is written by hand in
## all three; none is byte-identical to English (renpy-translation-blind-spots memory).
##
## Rewritten for the real grid loop (2026-09-21): the old table's shop/staff/report keys
## described static placeholder panels ("Furniture upgrades are queued for the next
## pass.") that no longer exist now those panels read live `Grid` state. New keys cover
## the tray, the 8 catalog symbols, the 6 relics (including flavour text for `pto`, which
## `landlord.js`'s settleGrid() never actually checks -- see the comment on relic_desc_pto
## below, it is an honest joke about the mechanic, not a bug), the shop, the staff
## directory and the weekly report's real event names.

signal changed(lang: String)

const LANGS := ["en", "zh", "ja"]
const ENDONYM := {"en": "English", "zh": "简体中文", "ja": "日本語"}

var lang := "en"

const T := {
"en": {
	"title": "OFFICE LANDLORD",
	"subtitle": "Fill the floor. Collect the rent.",
	"start": "OPEN FOR BUSINESS",

	"floor_label": "Floor %d",
	"rent_due_label": "Rent due",
	"payout_label": "This week",
	"banked_label": "Banked",
	"met_label": "Rent met",
	"not_met_label": "Short",
	"collect": "Collect rent",
	"shop_hint": "1: shop   2: staff   3: report",
	"tray_label": "Tray",

	"symbol_coffee": "Coffee",
	"symbol_dev": "Developer",
	"symbol_intern": "Intern",
	"symbol_meeting": "Meeting",
	"symbol_mute": "Noise-cancelling",
	"symbol_printer": "Printer",
	"symbol_standup": "Standup",
	"symbol_corner": "Corner suite",

	"relic_severance": "Severance Package",
	"relic_quiet": "Quiet Hours",
	"relic_pto": "Unlimited PTO",
	"relic_glass": "Corner Office",
	"relic_badge": "Access Badge",
	"relic_army": "Temp Agency",
	"relic_desc_severance": "Empty desks pay 1 rent each.",
	"relic_desc_quiet": "Noise-cancelling shields the whole block, not just its neighbours.",
	# pto is a real, buyable relic in LANDLORD_RELICS, but settleGrid() never checks for
	# it -- there is no coded mechanical effect yet. Rather than invent one (and quietly
	# diverge from the canonical kernel), the flavour text says so, in character: nobody
	# actually uses the PTO they're owed, which is the joke.
	"relic_desc_pto": "Everyone has it. Nobody uses it. Does nothing to the board.",
	"relic_desc_glass": "No meeting ever taxes your rent — but rent itself runs 10% steeper.",
	"relic_desc_badge": "Every scored event pays you one more.",
	"relic_desc_army": "Every intern copies the single best score on the whole floor.",

	"shop_title": "Office Shop",
	"buy_button": "Buy",
	"owned_label": "Owned",
	"cant_afford": "Can't afford",

	"staff_title": "Staff Directory",
	"staff_empty": "No staff on the floor yet — place a developer, intern or standup.",
	"staff_row": "Desk %d — %s",

	"report_title": "Weekly Report",
	"report_payout": "Collected: %d",
	"report_rent": "Rent due: %d",
	"report_met": "Rent met — moving up to floor %d.",
	"report_evicted": "Evicted — short by %d. Floor reset, %d banked lost.",
	"report_events_label": "Top events",
	"report_no_events": "Nothing scored yet — place something on the floor.",

	"close": "Close",
	"evicted_banner": "EVICTED",

	"ev_coffee-dev": "Coffee run",
	"ev_dev-mute": "Focus time",
	"ev_tag-fuel": "Caffeinated",
	"ev_tag-staff": "Team synergy",
	"ev_tag-noise": "Open-plan noise",
	"ev_tag-infra": "Shared infrastructure",
	"ev_meeting-tax": "Meeting overrun",
	"ev_mute-shield": "Headphones on",
	"ev_intern-copy": "Intern shadowing",
	"ev_print-job": "Print queue",
	"ev_standup-boost": "Standup energy",
	"ev_intern-army": "Temp reinforcements",
},
"zh": {
	"title": "地产房东",
	"subtitle": "招满这层楼，收租金。",
	"start": "开门营业",

	"floor_label": "第 %d 层",
	"rent_due_label": "应缴租金",
	"payout_label": "本周收入",
	"banked_label": "存款",
	"met_label": "租金已达标",
	"not_met_label": "还差一点",
	"collect": "收租",
	"shop_hint": "1：商店　2：员工　3：周报",
	"tray_label": "手牌",

	"symbol_coffee": "咖啡机",
	"symbol_dev": "程序员",
	"symbol_intern": "实习生",
	"symbol_meeting": "会议室",
	"symbol_mute": "降噪耳机",
	"symbol_printer": "打印机",
	"symbol_standup": "站会",
	"symbol_corner": "角落套间",

	"relic_severance": "遣散费方案",
	"relic_quiet": "安静时段",
	"relic_pto": "无限带薪假",
	"relic_glass": "带窗办公室",
	"relic_badge": "门禁卡",
	"relic_army": "临时工中介",
	"relic_desc_severance": "空桌子每张也能收 1 点租金。",
	"relic_desc_quiet": "降噪耳机保护整整一圈，不只是相邻的桌子。",
	# pto 在原版 landlord.js 的 settleGrid() 里根本没有被读取——目前没有任何机制效果。
	# 与其偷偷加一个（那就和权威内核对不上了），不如老实写清楚，还顺带是个职场梗：
	# 假期人人都有，但没人真的休。
	"relic_desc_pto": "人人都有，谁也不休。对棋盘没有任何影响。",
	"relic_desc_glass": "会议室再也扣不到你的租金——但租金本身涨得快了一成。",
	"relic_desc_badge": "每触发一次事件，就多给你一点。",
	"relic_desc_army": "每个实习生都直接抄全场最高分。",

	"shop_title": "办公商店",
	"buy_button": "购买",
	"owned_label": "已拥有",
	"cant_afford": "存款不够",

	"staff_title": "员工名录",
	"staff_empty": "这层还没有员工——放一个程序员、实习生或站会试试。",
	"staff_row": "%d 号桌 — %s",

	"report_title": "周报",
	"report_payout": "本周收入：%d",
	"report_rent": "应缴租金：%d",
	"report_met": "租金达标——升到第 %d 层。",
	"report_evicted": "被驱逐——还差 %d。楼层重置，存款也蒸发了 %d。",
	"report_events_label": "本周要闻",
	"report_no_events": "这周还没发生什么——先在楼层上放点东西。",

	"close": "关闭",
	"evicted_banner": "已被驱逐",

	"ev_coffee-dev": "去买了杯咖啡",
	"ev_dev-mute": "专注模式",
	"ev_tag-fuel": "续命成功",
	"ev_tag-staff": "团队默契",
	"ev_tag-noise": "开放式办公噪音",
	"ev_tag-infra": "共享设施",
	"ev_meeting-tax": "会议拖堂",
	"ev_mute-shield": "戴上耳机",
	"ev_intern-copy": "实习生偷师",
	"ev_print-job": "打印排队",
	"ev_standup-boost": "站会打了鸡血",
	"ev_intern-army": "临时工来支援",
},
"ja": {
	"title": "オフィス大家",
	"subtitle": "フロアを埋めて、家賃を集める。",
	"start": "開店する",

	"floor_label": "%d 階",
	"rent_due_label": "家賃の目安",
	"payout_label": "今週の稼ぎ",
	"banked_label": "貯金",
	"met_label": "家賃クリア",
	"not_met_label": "あと少し",
	"collect": "家賃を集める",
	"shop_hint": "1：ショップ　2：名簿　3：週報",
	"tray_label": "手札",

	"symbol_coffee": "コーヒー",
	"symbol_dev": "エンジニア",
	"symbol_intern": "インターン",
	"symbol_meeting": "会議室",
	"symbol_mute": "ノイズキャンセル",
	"symbol_printer": "プリンター",
	"symbol_standup": "朝会",
	"symbol_corner": "角部屋",

	"relic_severance": "退職金プラン",
	"relic_quiet": "静音タイム",
	"relic_pto": "無制限有給休暇",
	"relic_glass": "角の個室",
	"relic_badge": "入館証",
	"relic_army": "派遣会社",
	"relic_desc_severance": "空席のデスクも 1 ポイントの家賃を稼ぐ。",
	"relic_desc_quiet": "ノイズキャンセルが隣だけでなく周囲全体を守る。",
	# pto は LANDLORD_RELICS には実在するが、settleGrid() のどこからも参照されない
	# ——今のところ盤面には何の効果もない。勝手に効果を足すと本家のカーネルからずれて
	# しまうので、代わりに正直にそう書いた。実は職場あるあるのジョークでもある：
	# 有給はみんな持ってるのに、誰も使わない。
	"relic_desc_pto": "みんな持ってる。誰も使わない。盤面には何も起きない。",
	"relic_desc_glass": "会議室に家賃を取られなくなる——その代わり家賃自体が1割高くなる。",
	"relic_desc_badge": "スコアが発生するたびに、もう1ポイント多くもらえる。",
	"relic_desc_army": "インターン全員がフロア最高得点をそのままコピーする。",

	"shop_title": "オフィスショップ",
	"buy_button": "購入",
	"owned_label": "所有済み",
	"cant_afford": "貯金が足りない",

	"staff_title": "テナント名簿",
	"staff_empty": "このフロアにはまだ誰もいない——エンジニアかインターン、朝会を置いてみて。",
	"staff_row": "%d 番デスク — %s",

	"report_title": "週報",
	"report_payout": "今週の稼ぎ：%d",
	"report_rent": "家賃の目安：%d",
	"report_met": "家賃クリア——%d 階へ。",
	"report_evicted": "退去——%d 足りなかった。フロアはリセット、貯金も %d 減った。",
	"report_events_label": "今週のできごと",
	"report_no_events": "まだ何も起きていない——フロアに何か置いてみて。",

	"close": "閉じる",
	"evicted_banner": "退去",

	"ev_coffee-dev": "コーヒーブレイク",
	"ev_dev-mute": "集中タイム",
	"ev_tag-fuel": "カフェイン効果",
	"ev_tag-staff": "チームの相性",
	"ev_tag-noise": "オープンオフィスの騒がしさ",
	"ev_tag-infra": "設備の共有",
	"ev_meeting-tax": "会議の延長",
	"ev_mute-shield": "ヘッドホン装着",
	"ev_intern-copy": "インターンの見習い",
	"ev_print-job": "印刷待ち",
	"ev_standup-boost": "朝会の勢い",
	"ev_intern-army": "派遣スタッフの応援",
},
}

func _ready() -> void:
	var f := FileAccess.open("user://lang.cfg", FileAccess.READ)
	if f:
		var saved := f.get_as_text().strip_edges()
		if saved in LANGS:
			lang = saved

func t(key: String) -> String:
	return T.get(lang, T["en"]).get(key, T["en"].get(key, key))

func f(key: String, args: Array) -> String:
	return t(key) % args

## Event kind (e.g. "coffee-dev", "meeting-tax") -> a readable, translated label. Falls
## back to the raw kind so a kernel event this table hasn't caught up with still shows
## something rather than crashing the report panel.
func ev(kind: String) -> String:
	return t("ev_" + kind) if T.get(lang, T["en"]).has("ev_" + kind) else kind

## Catalog symbol id -> translated display name.
func symbol(id: String) -> String:
	return t("symbol_" + id)

## Relic id -> translated display name / description.
func relic(id: String) -> String:
	return t("relic_" + id)

func relic_desc(id: String) -> String:
	return t("relic_desc_" + id)

func set_lang(l: String) -> void:
	if l == lang or not l in LANGS:
		return
	lang = l
	var f := FileAccess.open("user://lang.cfg", FileAccess.WRITE)
	if f:
		f.store_string(lang)
	changed.emit(lang)

func cycle() -> void:
	var i := LANGS.find(lang)
	set_lang(LANGS[(i + 1) % LANGS.size()])

extends Node
## OFFICE LANDLORD — en / zh / ja. Autoloaded as "I18n".
##
## Shape matches play/overtime-idle-godot/scripts/i18n.gd (STANDARD.md item 7: en + zh
## minimum, ja the priority): one table keyed by language, I18n.t(key) to read it, a
## `changed` signal, the choice saved to user://. Every line below is written by hand in
## all three; none is byte-identical to English (renpy-translation-blind-spots memory).

signal changed(lang: String)

const LANGS := ["en", "zh", "ja"]
const ENDONYM := {"en": "English", "zh": "简体中文", "ja": "日本語"}

var lang := "en"

const T := {
"en": {
	"title": "OFFICE LANDLORD",
	"subtitle": "Fill the floor. Collect the rent.",
	"start": "OPEN FOR BUSINESS",
	"rent_label": "Rent",
	"hire": "Hire tenant",
	"hire_cost": "Costs %d",
	"floor_full": "Floor full!",
	"move_up": "Move to a bigger building",
	"floor_label": "Floor %d",
	"shop_title": "Office shop",
	"shop_body": "Furniture upgrades are queued for the next pass.",
	"staff_title": "Staff directory",
	"staff_body": "Six desks, six tenants, six little businesses paying rent.",
	"result_title": "Weekly report",
	"result_body": "Rent collected: %d\nDesks filled: %d / 6\nFloor: %d",
	"close": "Close",
},
"zh": {
	"title": "地产房东",
	"subtitle": "招满这层楼，收租金。",
	"start": "开门营业",
	"rent_label": "租金",
	"hire": "招租户",
	"hire_cost": "花费 %d",
	"floor_full": "这层已招满！",
	"move_up": "搬去更大的楼",
	"floor_label": "第 %d 层",
	"shop_title": "办公商店",
	"shop_body": "家具升级下一版再做。",
	"staff_title": "员工名录",
	"staff_body": "六张桌子，六位租户，六份租金。",
	"result_title": "周报",
	"result_body": "已收租金：%d\n已招租户：%d / 6\n楼层：%d",
	"close": "关闭",
},
"ja": {
	"title": "オフィス大家",
	"subtitle": "フロアを埋めて、家賃を集める。",
	"start": "開店する",
	"rent_label": "家賃",
	"hire": "テナントを入れる",
	"hire_cost": "費用 %d",
	"floor_full": "満室！",
	"move_up": "もっと大きいビルへ移る",
	"floor_label": "%d 階",
	"shop_title": "オフィスショップ",
	"shop_body": "家具のアップグレードは次回に用意する。",
	"staff_title": "テナント名簿",
	"staff_body": "六つの机、六つのテナント、六件分の家賃。",
	"result_title": "週報",
	"result_body": "集めた家賃：%d\nテナント数：%d / 6\n階：%d",
	"close": "閉じる",
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

## I18n — English and Chinese, lifted from the shipped page's T / INTRO_T / soundWords /
## renderLevels tables so the wording is the wording players already have. Autoloaded as
## "I18n".
##
## The web build carries five languages; the brief for this port is en + zh, which are the
## two the page's own telemetry shows traffic in. The table is keyed the same way, so
## adding es/pt/ja back later is data, not code.
##
## The level names are not here: every entry in data/levels.json is "中文 / English" and
## Fold.level_name() splits it, so the two stay in one file and cannot drift apart.
extends Node

signal changed(lang: String)

const LANGS := ["en", "zh"]

var lang := "en"

const T := {
	"en": {
		"goal": "Fold everything into %d",
		"moves": "Move %d",
		"undo": "Undo",
		"reset": "Reset",
		"hint": "Swipe or arrows · equals merge · fold the grid until one tile remains",
		"win": "SNAP",
		"next": "Next",
		"retry": "Retry",
		"share": "Share",
		"parhint": "%d moves for 3★",
		"level": "Level",
		"done": "done",
		"curated": "Curated",
		"endless": "Endless",
		"sfx": "Sound effects",
		"ambience": "Ambience",
		"on": "ON",
		"off": "OFF",
		# title screen — INTRO_T.en
		"kicker": "SATISFYING · SPATIAL PUZZLE",
		"tagline": "Fold the grid. Solve the shape. Relax your mind.",
		"snapline": "Click, drag, and watch it snap perfectly.",
		"rules": ["Click, drag, and watch it snap perfectly.",
			"Equals meet, merge, and double.",
			"Three-minute levels. Satisfying first, clever second."],
		"fine": "%d short levels · pause anytime",
		"play": "FOLD IT",
		"continue": "CONTINUE",
		"levels_btn": "LEVELS",
		"nerd": "For Nerds / Tech Stack",
		"nerd_body": "Deterministic puzzles with a conservation invariant. Endless generator stays backstage. The solver and RL never show up in play.",
		"studio": "blazeCore Play",
		"rating": "ALL AGES",
		"back": "Back",
		"stars_1": "1 star", "stars_2": "2 stars", "stars_3": "3 stars",
		# the coach's fallback lines — COACH_FALLBACK.en
		"coach_easy": "The first fold is complete.",
		"coach_medium": "You saw the order hidden in the space.",
		"coach_hard": "Complexity yielded to a quiet plan.",
		"coach_expert": "Many possibilities, one inevitable form.",
	},
	"zh": {
		"goal": "目标 · 归一至 %d",
		"moves": "第 %d 手",
		"undo": "撤销",
		"reset": "重置",
		"hint": "滑动或方向键 · 同值合并 · 折到只剩一块",
		"win": "咬 合",
		"next": "下一关",
		"retry": "再来",
		"share": "晒战绩",
		"parhint": "满星 %d 步",
		"level": "关卡",
		"done": "已通",
		"curated": "精选",
		"endless": "无尽",
		"sfx": "音效",
		"ambience": "氛围",
		"on": "开",
		"off": "关",
		"kicker": "空间解谜 · 咬合快感",
		"tagline": "折格子。对形状。松口气。",
		"snapline": "点一下，拖一下，看它严丝合缝咬上。",
		"rules": ["点、拖，看它严丝合缝地咬合",
			"相同数字相遇，合二为一",
			"三分钟一关，解压比烧脑更先到"],
		"fine": "%d 道短关 · 随时可停",
		"play": "开 折",
		"continue": "继 续",
		"levels_btn": "选 关",
		"nerd": "给极客 / 技术栈",
		"nerd_body": "确定性关卡，守恒可解。无尽生成器在后台。求解器与 RL 不出现在玩局里。",
		"studio": "blazeCore Play",
		"rating": "全年龄",
		"back": "返回",
		"stars_1": "一星", "stars_2": "两星", "stars_3": "满星",
		"coach_easy": "初折已成，两端归一。",
		"coach_medium": "你看见了空间里潜藏的秩序。",
		"coach_hard": "繁复终究让位于从容的布局。",
		"coach_expert": "万般可能，终成一形。",
	},
}

## The wordmark. The page draws 归一 for zh and FOLD for en, with the other as a subtitle;
## scenes/title.gd draws the same pair as a designed mark rather than a Label.
const WORDMARK := {"en": "FOLD", "zh": "归一"}
const WORDMARK_SUB := {"en": "", "zh": "FOLD"}

var _coach := {}
var _last_coach := ""


func _ready() -> void:
	var saved := Save.get_lang()
	lang = saved if saved in LANGS else _from_os()
	var f := FileAccess.open("res://data/coach_tips.json", FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			_coach = parsed


func _from_os() -> String:
	return "zh" if OS.get_locale().to_lower().begins_with("zh") else "en"


func set_lang(next: String) -> void:
	if next not in LANGS or next == lang:
		return
	lang = next
	Save.set_lang(next)
	changed.emit(lang)


func toggle() -> void:
	set_lang(LANGS[(LANGS.find(lang) + 1) % LANGS.size()])


func t(key: String) -> String:
	var table: Dictionary = T[lang]
	if table.has(key):
		return str(table[key])
	return str(T["en"].get(key, key))


func f(key: String, value) -> String:
	return t(key) % value


func list(key: String) -> Array:
	var table: Dictionary = T[lang]
	return table.get(key, T["en"].get(key, []))


func stars_word(n: int) -> String:
	return t("stars_%d" % clampi(n, 1, 3))


## JS `coachTier(par)`.
func coach_tier(p: int) -> String:
	if p <= 3:
		return "easy"
	if p <= 6:
		return "medium"
	if p <= 9:
		return "hard"
	return "expert"


## JS `coachLine(par)`: a line from coach_tips.json for this language and tier, never the
## same one twice running, falling back to the built-in line for the tier.
func coach_line(p: int) -> String:
	var tier := coach_tier(p)
	var pool: Array = []
	if _coach.has(lang) and _coach[lang].has(tier):
		pool = _coach[lang][tier]
	elif _coach.has("en") and _coach["en"].has(tier):
		pool = _coach["en"][tier]
	var choices := []
	for x in pool:
		if str(x) != _last_coach:
			choices.append(str(x))
	if choices.is_empty():
		choices = []
		for x in pool:
			choices.append(str(x))
	var line := ""
	if not choices.is_empty():
		line = choices[randi() % choices.size()]
	if line == "":
		line = t("coach_" + tier)
	_last_coach = line
	return line

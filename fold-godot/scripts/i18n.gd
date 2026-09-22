## I18n — English, Chinese (both scripts) and Japanese, lifted from the shipped page's T / INTRO_T / soundWords /
## renderLevels tables so the wording is the wording players already have. Autoloaded as
## "I18n".
##
## en + zh were the port's brief; ja and zh-Hant were added 2026-09-21 for ops/STANDARD.md
## item 7 — ja is the studio's priority language, and this game is a Japanese craft. The
## hard rule there is that a language on the switch was really translated: ja is written
## by hand here and in data/steps.json, zh-Hant is an OpenCC conversion of the zh block,
## and coach_tips.json carries both. es/pt are still in coach_tips.json only and are
## therefore NOT in LANGS.
##
## The level names are not here: every entry in data/levels.json is "中文 / English" and
## Fold.level_name() splits it. Since the origami bridge landed, the header and the level
## list name the level by its MODEL (data/models.json + data/steps.json, which carry all
## four languages), so that pair is only a fallback for a level the model data misses.
extends Node

signal changed(lang: String)

## Four languages, and every one of them was actually translated (ops/STANDARD.md item 7).
## ja is the studio's priority language; zh-Hant is the zh block converted with OpenCC.
const LANGS := ["en", "zh", "ja", "zh-Hant"]

## What the language button says: the name of the language it switches TO, written in
## that language. A button reading "EN" in a four-language cycle tells the player nothing
## about where the next press lands.
const LANG_LABEL := {"en": "EN", "zh": "中文", "ja": "日本語", "zh-Hant": "繁體"}

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
		# the origami bridge, ops/fold/BRIDGE.md. The tile value is the layer count, so
		# the board has been folding all along; these are the words that say so.
		"folds": "%d folds",
		"folded": "You folded",
		"fold_step": "Fold %d",
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
		"folds": "共 %d 折",
		"folded": "你折出了",
		"fold_step": "第 %d 折",
	},
	# Traditional Chinese, converted from the zh block above with OpenCC s2twp and
	# checked by eye. It is the same translation in the other script, which is what a
	# zh-Hant reader is actually asking for -- not a second, different wording.
	"zh-Hant": {
		"goal": "目標 · 歸一至 %d",
		"moves": "第 %d 手",
		"undo": "撤銷",
		"reset": "重置",
		"hint": "滑動或方向鍵 · 同值合併 · 折到只剩一塊",
		"win": "咬 合",
		"next": "下一關",
		"retry": "再來",
		"share": "曬戰績",
		"parhint": "滿星 %d 步",
		"level": "關卡",
		"done": "已通",
		"curated": "精選",
		"endless": "無盡",
		"sfx": "音效",
		"ambience": "氛圍",
		"on": "開",
		"off": "關",
		"kicker": "空間解謎 · 咬合快感",
		"tagline": "折格子。對形狀。鬆口氣。",
		"snapline": "點一下，拖一下，看它嚴絲合縫咬上。",
		"rules": ["點、拖，看它嚴絲合縫地咬合",
			"相同數字相遇，合二為一",
			"三分鐘一關，解壓比燒腦更先到"],
		"fine": "%d 道短關 · 隨時可停",
		"play": "開 折",
		"continue": "繼 續",
		"levels_btn": "選 關",
		"nerd": "給極客 / 技術棧",
		"nerd_body": "確定性關卡，守恆可解。無盡生成器在後臺。求解器與 RL 不出現在玩局裡。",
		"studio": "blazeCore Play",
		"rating": "全年齡",
		"back": "返回",
		"stars_1": "一星", "stars_2": "兩星", "stars_3": "滿星",
		"coach_easy": "初折已成，兩端歸一。",
		"coach_medium": "你看見了空間裡潛藏的秩序。",
		"coach_hard": "繁複終究讓位於從容的佈局。",
		"coach_expert": "萬般可能，終成一形。",
		"folds": "共 %d 折",
		"folded": "你折出了",
		"fold_step": "第 %d 折",
	},
	# Japanese. ops/STANDARD.md item 7: ja is the studio's priority language (507 of the
	# 581 scraped DLsite works are Japanese), and origami is a Japanese word for a
	# Japanese craft — a folding game with no Japanese is the wrong game to skip it on.
	# Every string below is written here, not machine-filled: the rule is that a language
	# on the switch is a language that was actually translated (Floor 13 shipped three
	# that were not). The model and step names live in data/steps.json and carry "ja" for
	# the same reason.
	"ja": {
		"goal": "%d まで折りたたむ",
		"moves": "%d 手目",
		"undo": "ひとつ戻す",
		"reset": "やり直す",
		"hint": "スワイプか矢印キー · 同じ数どうしが重なる · 一枚になるまで折る",
		"win": "ぴたり",
		"next": "次へ",
		"retry": "もう一度",
		"share": "共有",
		"parhint": "★3 は %d 手",
		"level": "ステージ",
		"done": "クリア",
		"curated": "選りすぐり",
		"endless": "エンドレス",
		"sfx": "効果音",
		"ambience": "環境音",
		"on": "オン",
		"off": "オフ",
		"kicker": "空間パズル · 心地よい手ざわり",
		"tagline": "折る。形にする。心をほどく。",
		"snapline": "触れて、動かして、ぴたりと重なる瞬間を。",
		"rules": ["触れて動かすと、紙がぴたりと重なります",
			"同じ数どうしが出会うと、ひとつに重なって倍になります",
			"一面三分。まず心地よく、それから賢く。"],
		"fine": "短いステージ %d 面 · いつでも中断できます",
		"play": "折りはじめる",
		"continue": "つづきから",
		"levels_btn": "ステージ選択",
		"nerd": "技術のはなし",
		"nerd_body": "保存量を持つ決定論的パズル。エンドレス生成は裏方に徹し、ソルバーと強化学習はプレイ中に姿を見せません。",
		"studio": "blazeCore Play",
		"rating": "全年齢",
		"back": "もどる",
		"stars_1": "★1", "stars_2": "★2", "stars_3": "★3",
		"coach_easy": "はじめの一折りができました。",
		"coach_medium": "空間に潜む秩序を見抜きました。",
		"coach_hard": "複雑さが、静かな構想に道を譲りました。",
		"coach_expert": "無数の可能性が、ひとつの必然の形に。",
		"folds": "全 %d 折り",
		"folded": "折りあがったのは",
		"fold_step": "%d 折り目",
	},
}

## The wordmark. The page draws 归一 for zh and FOLD for en, with the other as a subtitle;
## scenes/title.gd draws the same pair as a designed mark rather than a Label.
## ja and zh-Hant take the Latin mark: the drawn 归一 is simplified, and VectorMark has no
## traditional or Japanese mark of its own (scripts/vector_mark.gd falls back to "en").
const WORDMARK := {"en": "FOLD", "zh": "归一", "ja": "FOLD", "zh-Hant": "FOLD"}
const WORDMARK_SUB := {"en": "", "zh": "FOLD", "ja": "折り紙パズル", "zh-Hant": "歸一"}

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
	var loc := OS.get_locale().to_lower()
	if loc.begins_with("ja"):
		return "ja"
	if loc.begins_with("zh"):
		# tw/hk/mo and any locale tagged Hant read traditional; everything else simplified
		for hant in ["tw", "hk", "mo", "hant"]:
			if hant in loc:
				return "zh-Hant"
		return "zh"
	return "en"


func set_lang(next: String) -> void:
	if next not in LANGS or next == lang:
		return
	lang = next
	Save.set_lang(next)
	changed.emit(lang)


func toggle() -> void:
	set_lang(next_lang())


func next_lang() -> String:
	return LANGS[(LANGS.find(lang) + 1) % LANGS.size()]


## The word on the language button: where the next press lands, in its own script.
func next_lang_label() -> String:
	return str(LANG_LABEL.get(next_lang(), next_lang()))


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

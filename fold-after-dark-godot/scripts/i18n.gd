## I18n — English and Chinese, lifted from the shipped page's T / INTRO_T / soundWords /
## renderLevels tables so the wording is the wording players already have. Autoloaded as
## "I18n".
##
## The web build carries five languages; this port shipped en + zh, and **ja was added on
## 2026-09-21** because ja is where this fork sells: 507 of the 581 DLsite works in
## ops/market/dlsite_data/ are Japanese, and without it PLICATA is not on that shelf at all.
##
## Every string in the ja table below is actually translated -- that is the whole of the
## rule in ops/STANDARD.md item 7, and Floor 13 broke it by shipping ja/ko/es whose story
## files held Chinese prose. The one honest gap, stated rather than hidden: the 201 LEVEL
## NAMES in data/levels.json are "中文 / English" pairs, so `Fold.level_name` hands a ja
## player the ENGLISH half. They are proper names of origami models; translating them is a
## data pass on levels.json, not a code change, and it is the next thing this file needs.
##
## The level names are not here: every entry in data/levels.json is "中文 / English" and
## Fold.level_name() splits it, so the two stay in one file and cannot drift apart.
extends Node

signal changed(lang: String)

const LANGS := ["en", "zh", "ja"]

var lang := "en"

const T := {
	"en": {
		"goal": "Fold everything into %d",
		"folds": "%d folds",
		"moves": "Move %d",
		"undo": "Undo",
		"reset": "Reset",
		"hint": "Swipe or arrows · equals merge · fold the grid until one tile remains",
		"win": "SNAP",
		"next": "Next",
		"retry": "Retry",
		"share": "Share",
		"parhint": "%d moves for 3★",
		"parhint_1": "%d move for 3★",
		"level": "Level",
		"done": "done",
		"curated": "Curated",
		"endless": "Endless",
		"sfx": "Sound effects",
		"ambience": "Ambience",
		"on": "ON",
		"off": "OFF",
		# title screen — INTRO_T.en
		"kicker": "PLICATA · MERGE & UNLOCK",
		"tagline": "Same board. Lights down. Every tier you clear folds one more layer off her.",
		"snapline": "Click, drag, snap.",
		"rules": ["Fold fast. Equals merge and double.",
			"Clear a tier, take the trophy, unlock her scene.",
			"Streaks and dailies count. Nothing is drawn until it is earned."],
		"fine": "%d short levels · 25 scenes",
		"play": "PLAY",
		"continue": "CONTINUE",
		"levels_btn": "TIER MAP",
		"tier": "Tier",
		"scene": "Scene",
		"locked": "LOCKED",
		"unlocked": "UNLOCKED",
		"clear_to_unlock": "Clear the tier to unlock",
		"trophy": "TIER CLEARED",
		"unlock_scene": "UNLOCK HER SCENE",
		"delivering": "Fetching the scene…",
		"not_delivered": "The scene did not arrive. Nothing to show — try again.",
		"retry_fetch": "TRY AGAIN",
		"map_btn": "TIER MAP",
		"streak": "STREAK",
		"daily": "DAILY MISSION",
		"daily_line": "Clear %d levels today",
		"daily_days": "%d-day run",
		"board": "LEADERBOARD",
		"stub": "LOCAL STUB · not networked",
		"mosaic": "Mosaic",
		"close": "CLOSE",
		"placeholder_scene": "PLACEHOLDER · no scene rendered for this tier yet",
		"rating_18": "18+",
		"back_to_map": "BACK TO MAP",
		"nerd": "For Nerds / Tech Stack",
		"nerd_body": "Deterministic puzzles with a conservation invariant. Endless generator stays backstage. The solver and RL never show up in play.",
		"studio": "blazeCore Play",
		"rating": "18+ · ADULTS ONLY",
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
		"folds": "共 %d 折",
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
		"kicker": "深夜版 · 合成解锁",
		"tagline": "同一块板，熄灯之后。每清一层，她就少一层。",
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
		"rating": "18+ · 仅限成人",
		"back": "返回",
		"stars_1": "一星", "stars_2": "两星", "stars_3": "满星",
		"coach_easy": "初折已成，两端归一。",
		"coach_medium": "你看见了空间里潜藏的秩序。",
		"coach_hard": "繁复终究让位于从容的布局。",
		"coach_expert": "万般可能，终成一形。",
		"parhint_1": "满星 %d 步",
		"tier": "层",
		"scene": "场景",
		"locked": "未解锁",
		"unlocked": "已解锁",
		"clear_to_unlock": "通关这一层即可解锁",
		"trophy": "本层通关",
		"unlock_scene": "解锁她的场景",
		"delivering": "正在取回场景…",
		"not_delivered": "场景没有送达，暂时没有可显示的内容。请再试一次。",
		"retry_fetch": "再试一次",
		"map_btn": "层级地图",
		"streak": "连胜",
		"daily": "每日任务",
		"daily_line": "今天通关 %d 关",
		"daily_days": "连续 %d 天",
		"board": "排行榜",
		"stub": "本地示意 · 未联网",
		"mosaic": "马赛克",
		"close": "关闭",
		"placeholder_scene": "占位图 · 这一层的场景还没有画好",
		"rating_18": "18+",
		"back_to_map": "返回地图",
	},
	"ja": {
		"goal": "すべてを %d に折り重ねる",
		"folds": "全 %d 折り",
		"moves": "%d 手目",
		"undo": "戻す",
		"reset": "やり直す",
		"hint": "スワイプか矢印キー · 同じ数字は合わさる · 一枚になるまで折る",
		"win": "ぴたり",
		"next": "次へ",
		"retry": "もう一度",
		"share": "記録を共有",
		"parhint": "★3 は %d 手",
		"level": "ステージ",
		"done": "クリア",
		"curated": "厳選",
		"endless": "エンドレス",
		"sfx": "効果音",
		"ambience": "環境音",
		"on": "オン",
		"off": "オフ",
		"kicker": "PLICATA · 合わせて、ひらく",
		"tagline": "同じ盤面、灯りを落として。ひと段クリアするたび、彼女が一枚ずつ薄くなる。",
		"snapline": "つまんで、運んで、ぴたりと。",
		"rules": ["手早く折る。同じ数字は合わさって倍になる。",
			"ひと段クリアでトロフィー、彼女のシーンがひらく。",
			"連勝もデイリーも数える。稼いだぶんしか描かれない。"],
		"fine": "%d の短いステージ · 25 のシーン",
		"play": "はじめる",
		"continue": "つづきから",
		"levels_btn": "ステージ選択",
		"tier": "段",
		"scene": "シーン",
		"locked": "ロック中",
		"unlocked": "解放",
		"clear_to_unlock": "この段をクリアで解放",
		"trophy": "段クリア",
		"unlock_scene": "彼女のシーンをひらく",
		"delivering": "シーンを取得中…",
		"not_delivered": "シーンが届きませんでした。表示できるものはありません。もう一度お試しください。",
		"retry_fetch": "再試行",
		"map_btn": "ステージ選択",
		"streak": "連勝",
		"daily": "デイリー",
		"daily_line": "今日 %d ステージをクリア",
		"daily_days": "%d 日連続",
		"board": "ランキング",
		"stub": "ローカル表示 · 通信なし",
		"mosaic": "モザイク",
		"close": "閉じる",
		"placeholder_scene": "仮画像 · この段のシーンはまだ未収録",
		"rating_18": "18+",
		"back_to_map": "ステージ選択へ",
		"nerd": "技術メモ",
		"nerd_body": "保存量の決まった決定論パズル。エンドレス生成器は裏方に置く。ソルバーと強化学習はプレイ中に出てこない。",
		"studio": "blazeCore Play",
		"rating": "18+ · アダルト",
		"back": "戻る",
		"stars_1": "星ひとつ", "stars_2": "星ふたつ", "stars_3": "星みっつ",
		"coach_easy": "最初の一折りは、これで決まり。",
		"coach_medium": "空白にひそむ順序が、見えていた。",
		"coach_hard": "複雑さが、静かな段取りに屈した。",
		"coach_expert": "無数の可能性が、ひとつの形に。",
		"parhint_1": "★3 は %d 手",
	},
}

## The wordmark. Named 2026-09-20: the adult fork is PLICATA, not "FOLD: After Dark".
##
## Latin *plicāre*, to fold; *plicata* is the feminine perfect participle -- "she who has
## been folded". Blaze chose the feminine over the plain noun *plica* (a crease) because
## this fork's verb is folding paper away to reveal her, so the name should point at the
## subject rather than at the object. The all-ages parent keeps FOLD.
##
## zh keeps 归一 as the second line rather than a translation: PLICATA is a name, and a
## name is not translated. scenes/title.gd draws the pair as a designed mark, not a Label.
const WORDMARK := {"en": "PLICATA", "zh": "PLICATA", "ja": "PLICATA"}
const WORDMARK_SUB := {"en": "plicāre · to fold", "zh": "归一 · 夜场", "ja": "折る · 夜の卓"}

var _coach := {}
var _f2p := {}          # data/i18n_f2p.json: key -> {en, zh, ja}; the F2P build's strings
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
	var g := FileAccess.open("res://data/i18n_f2p.json", FileAccess.READ)
	if g:
		var rows = JSON.parse_string(g.get_as_text())
		g.close()
		if rows is Dictionary:
			for k in rows.keys():
				if not str(k).begins_with("_"):
					_f2p[str(k)] = rows[k]


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


## What the language button should SAY: the language it will switch to, in that language.
## The title screen used to hard-code `"中文" if lang == "en" else "EN"`, which with three
## languages offers Chinese from English and English from everywhere else -- ja would have
## been unreachable by the only control that reaches it.
func next_lang_label() -> String:
	match LANGS[(LANGS.find(lang) + 1) % LANGS.size()]:
		"zh": return "中文"
		"ja": return "日本語"
		_: return "EN"


func t(key: String) -> String:
	var table: Dictionary = T[lang]
	if table.has(key):
		return str(table[key])
	if _f2p.has(key):
		var row: Dictionary = _f2p[key]
		return str(row.get(lang, row.get("en", key)))
	return str(T["en"].get(key, key))


## True if the key exists in either table (for server ids: a mission the client has no
## words for falls back to a generic line, never to the server's English).
func has(key: String) -> bool:
	return (T[lang] as Dictionary).has(key) or _f2p.has(key)


# ---- server content, mapped from the server's ids (data/i18n_f2p.json) --------------------
# The title server speaks English labels ("Coco · Hello", "Clear 3 new levels", "level
# locked"); the client never shows them. It shows the key for the id instead. Checked by
# ops/nutaku/fold_f2p/check_i18n.py, which also fails if the server grows an id with no key.

static func slug(s: String) -> String:
	var out := ""
	var gap := false
	for ch in s.to_lower():
		var ok := (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")
		if ok:
			if gap and out != "":
				out += "_"
			out += ch
			gap = false
		else:
			gap = true
	return out


func scene_title(id: String, fallback: String = "") -> String:
	return t("scene_" + id) if has("scene_" + id) else fallback


func stage(name: String) -> String:
	var k := "stage_" + slug(name)
	return t(k) if has(k) else ""


func chapter(id: String) -> String:
	return t("chapter_" + id) if has("chapter_" + id) else ""


func mission(m: Dictionary) -> String:
	var k := "mission_" + str(m.get("id", ""))
	if not has(k):
		return t("mission_other")
	var s := t(k)
	return s % int(m.get("goal", 0)) if s.contains("%d") else s


func event_title(ev: Dictionary) -> String:
	var k := "event_" + str(ev.get("who", ""))
	return t(k) if has(k) else t("event")


func event_blurb(ev: Dictionary) -> String:
	var k := "event_%s_blurb" % str(ev.get("who", ""))
	return t(k) if has(k) else ""


func event_reward(ev: Dictionary) -> String:
	var k := "event_%s_reward" % str(ev.get("who", ""))
	return t(k) if has(k) else ""


## A refusal from the server ("level locked", "over budget (31 > 30)", "attempt is won"):
## the longest known prefix of its words, else a plain "the server refused it".
func reason(r) -> String:
	var words := slug(str(r).split("(")[0]).split("_", false)
	for n in range(words.size(), 0, -1):
		var k := "reason_" + "_".join(words.slice(0, n))
		if has(k):
			return t(k)
	return t("reason_other")


func f(key: String, value) -> String:
	# English singular ("1 move", not "1 moves") where a table has a key_1 form
	if typeof(value) == TYPE_INT and value == 1 and has(key + "_1"):
		return t(key + "_1") % value
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

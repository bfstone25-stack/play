class_name Loc
extends Object

const SETTINGS_PATH := "user://settings.cfg"
# 2026-09-23 (LIEN): zh and ja are real translations of every player-facing string --
# the ~9,500 words of story and the shop UI -- in locale/{zh,ja}.json (UI keys) and
# locale/story_{zh,ja}.json (English source -> translation). ja first because it is the
# DLsite majority (507 of 581 works). ops/STANDARD.md item 7: never offer a language that
# is not genuinely translated; tests/locale_cover.gd fails the build if a story string has
# no translation.
const ALLOWED := ["en", "zh", "ja"]
const NATIVE := {
	"en": "English",
	"zh": "简体中文",
	"ja": "日本語",
}
static var _ui := {}
static var _story := {}

static var code: String = ""
static var _hooks: Array[Callable] = []

static func current() -> String:
	if code == "":
		_load()
	return code


static func is_zh() -> bool:
	return current() == "zh"


static func set_code(next: String) -> void:
	if next not in ALLOWED:
		next = "en"
	if code == next:
		for hook in _hooks:
			if hook.is_valid():
				hook.call()
		return
	code = next
	_save()
	for hook in _hooks:
		if hook.is_valid():
			hook.call()


static func on_change(cb: Callable) -> void:
	_hooks.append(cb)


static func table() -> Dictionary:
	var c := current()
	if c == "en":
		return EN
	if not _ui.has(c):
		_ui[c] = _read_json("res://locale/%s.json" % c)
	return _ui[c]


## Story and in-world text: looked up by its English source, so a string written in the
## scripts is its own key and nothing has to be renumbered when copy changes. Falls back
## to the source, which the coverage test catches before a build ships.
static func s(src: String) -> String:
	var c := current()
	if c == "en" or src == "":
		return src
	if not _story.has(c):
		_story[c] = _read_json("res://locale/story_%s.json" % c)
	return str(_story[c].get(src, src))


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}



static func t(key: String, args: Array = []) -> String:
	var text := str(table().get(key, EN.get(key, key)))
	if args.is_empty():
		return text
	return text % args


static func _load() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			var forced := arg.trim_prefix("--locale=")
			code = forced if forced in ALLOWED else "en"
			return
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved := str(cfg.get_value("locale", "code", ""))
		if saved in ALLOWED:
			code = saved
			return
	code = _os_default()


static func _os_default() -> String:
	var lang := OS.get_locale_language().to_lower()
	if lang in ALLOWED:
		return lang
	if lang.begins_with("zh"):
		return "zh"
	return "en"


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("locale", "code", current())
	cfg.save(SETTINGS_PATH)


const EN := {}






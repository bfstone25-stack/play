## Save — progress, in the same shape the web build keeps in localStorage, so a player
## who moves from free.blazecore.dev/fold/ to the Godot build recognises their own save
## and a future migration is a copy rather than a conversion. Autoloaded as "Save".
##
##   fold_cur    int     the level last opened
##   fold_done   {i: stars}  best stars per level index
##   fold_lang   "en"|"zh"
##   fold_sfx / fold_music   "1"|"0"
##
## On the web the file lands in the browser's IndexedDB-backed user:// and is flushed
## explicitly, because a tab that is closed without a flush loses the write.
extends Node

const PATH := "user://fold_save.json"

var _data := {
	"fold_cur": 0,
	"fold_done": {},
	"fold_lang": "",
	"fold_sfx": "1",
	"fold_music": "1",
	"fold_intro_seen": "0",
}


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		for k in parsed.keys():
			_data[k] = parsed[k]


func flush() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_data))
	f.close()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.FS && FS.syncfs) FS.syncfs(false, function(){});", true)


func get_lang() -> String:
	return str(_data.get("fold_lang", ""))


func set_lang(v: String) -> void:
	_data["fold_lang"] = v
	flush()


func current_level() -> int:
	return int(_data.get("fold_cur", 0))


func set_current_level(i: int) -> void:
	_data["fold_cur"] = i
	flush()


## JS: `doneLv[L] = Math.max(doneLv[L] || 0, stars)` — a worse run never lowers a score.
func record(level_index: int, stars: int) -> void:
	var done: Dictionary = _data["fold_done"]
	var key := str(level_index)
	done[key] = maxi(int(done.get(key, 0)), stars)
	_data["fold_done"] = done
	flush()


func stars_at(level_index: int) -> int:
	return int((_data["fold_done"] as Dictionary).get(str(level_index), 0))


func completed_count() -> int:
	var n := 0
	for k in (_data["fold_done"] as Dictionary).keys():
		if int(_data["fold_done"][k]) > 0:
			n += 1
	return n


## The furthest level the player has any business continuing from: one past their best
## completed level, clamped to what exists.
func continue_level() -> int:
	var best := -1
	for k in (_data["fold_done"] as Dictionary).keys():
		if int(_data["fold_done"][k]) > 0:
			best = maxi(best, int(k))
	return clampi(maxi(best + 1, current_level()), 0, maxi(0, Fold.level_count() - 1))


func sfx_on() -> bool:
	return str(_data.get("fold_sfx", "1")) != "0"


func music_on() -> bool:
	return str(_data.get("fold_music", "1")) != "0"


func set_sfx(v: bool) -> void:
	_data["fold_sfx"] = "1" if v else "0"
	flush()


func set_music(v: bool) -> void:
	_data["fold_music"] = "1" if v else "0"
	flush()


func intro_seen() -> bool:
	return str(_data.get("fold_intro_seen", "0")) == "1"


func mark_intro_seen() -> void:
	_data["fold_intro_seen"] = "1"
	flush()


func reset_all() -> void:
	_data["fold_done"] = {}
	_data["fold_cur"] = 0
	flush()

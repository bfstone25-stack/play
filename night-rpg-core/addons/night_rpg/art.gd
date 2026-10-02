class_name NRArt
extends RefCounted
## Texture lookup through the game's art manifest (res://data/art_manifest.json):
##   {"rooms": {"study": ["res://assets/rpg/rooms/study.png", "res://assets/placeholder/rooms/study.webp"]}, ...}
## The first path that exists wins, so a newly rendered plate replaces its placeholder by
## being copied in -- no code or data change. Every fallback is existing rendered art.

static var _manifest: Dictionary = {}
static var _cache: Dictionary = {}


static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var f := FileAccess.open("res://data/art_manifest.json", FileAccess.READ)
		if f != null:
			_manifest = JSON.parse_string(f.get_as_text())
	return _manifest


## group: "rooms" / "enemies" / "sprites" / "cg" / "outfits" ...; id within it.
static func path(group: String, id: String) -> String:
	var cands = manifest().get(group, {}).get(id, [])
	if cands is String:
		cands = [cands]
	for p in cands:
		if ResourceLoader.exists(p):
			return p
	return ""


static func is_placeholder(group: String, id: String) -> bool:
	return path(group, id).contains("/placeholder/") or path(group, id).contains("/sprites/")


static func tex(group: String, id: String) -> Texture2D:
	var p := path(group, id)
	if p == "":
		push_warning("night_rpg: no art for %s/%s" % [group, id])
		return null
	if not _cache.has(p):
		_cache[p] = load(p)
	return _cache[p]

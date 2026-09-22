extends RefCounted
class_name Cjk
## The CJK face for the current language, as a FALLBACK behind Office Landlord's Latin
## faces (Lilita One / Nunito). Ported from play/overtime-idle-godot/scripts/cjk.gd —
## same shape, same two engine rules, subset files regenerated from THIS game's own
## scripts/i18n.gd (`python3 ops/subset_cjk.py play/office-landlord-godot/scripts/i18n.gd
## --out play/office-landlord-godot/assets/fonts`), not copied from overtime's. Overtime's
## subset only carries the glyphs OVERTIME's zh/ja strings use — Office Landlord's own
## vocabulary (房东/收租/商店/员工名录/周报, etc.) is a different character set and would
## draw as empty boxes if this game borrowed the wrong subset file.
##
## Two engine rules, both bought by other games in this studio:
##
## The resource is HELD in `_kept`. A FontFile loaded and dropped is freed, and on the web
## export the label then draws in the fallback with no error at all (memory:
## `godot-web-font-fallback`).
##
## load(), never preload(). preload resolves at parse time, so a build whose subset is
## missing would refuse to compile the script rather than fall back to Latin — a missing
## font should cost you the glyphs, not the game.

const DIR := "res://assets/fonts/"
const FILES := {
	"zh": "NotoSansCJKsc-subset.ttf",
	"ja": "NotoSansCJKjp-subset.ttf",
}

static var _kept := {}

static func lang() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("I18n"):
		return str(tree.root.get_node("I18n").lang)
	return "en"

## The face the current language needs, or null for English (Latin stack only).
static func face() -> Font:
	return face_for(lang())

static func face_for(l: String) -> Font:
	if not FILES.has(l):
		return null
	if _kept.has(l):
		return _kept[l]
	var path: String = DIR + str(FILES[l])
	if not ResourceLoader.exists(path):
		push_warning("CJK subset missing: %s — %s will draw as empty boxes" % [path, l])
		return null
	var f: Font = load(path)
	_kept[l] = f
	return f

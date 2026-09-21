extends RefCounted
class_name Cjk
## The CJK face for the current language, as a FALLBACK behind the game's Latin faces.
##
## Shape borrowed from play/the-other-side-godot/scripts/cjk.gd, with one deliberate
## difference: that game applies a CJK face TO a label, this one hands the face to
## `StudioTheme.font()` to hang off the Latin faces' `fallbacks`. The reason is arithmetic.
## Overtime Idle has ~40 `add_theme_font_override("font", Look.font_display)` call sites
## across the HUD, the tray, the gacha cards and the title screen; converting every one of
## them to a Cjk.apply_control() is forty chances to miss one, and a missed one draws empty
## boxes in Japanese with no error anywhere (memory: `verification-that-lies`). A fallback
## set on the three faces themselves covers every call site that already exists and every
## one anyone adds later, and it keeps the Latin face for the Latin runs inside a CJK line
## — "GOLD 120", "×1.5", "Nutaku" — which is what a fallback is for.
##
## ONE FILE PER SCRIPT FAMILY, built by `ops/subset_cjk.py` from scripts/i18n.gd's own
## literals. Every regional Noto CJK face covers the whole unified repertoire, so a single
## file would render with no missing glyph and no error at all — and would draw Japanese
## kanji in Chinese glyph forms, which a Japanese reader sees at once and no check on disk
## would catch.
##
## TWO ENGINE RULES, both of them bought by other games in this studio:
##
## The resource is HELD in `_kept`. A FontFile loaded and dropped is freed, and on the web
## export the label then draws in the fallback with no error at all (memory:
## `godot-web-font-fallback`). Being referenced by a live Theme is not enough to trust,
## because the Theme is rebuilt on a language change.
##
## load(), never preload(). preload resolves at parse time, so a build whose subset is
## missing would refuse to compile the script rather than fall back to Latin — and a
## missing font should cost you the glyphs, not the game.

const DIR := "res://assets/fonts/"
const FILES := {
	"zh": "NotoSansCJKsc-subset.ttf",
	"ja": "NotoSansCJKjp-subset.ttf",
	"zh-Hant": "NotoSansCJKtc-subset.ttf",
}

static var _kept := {}


## The current language, read without assuming the autoload is up: `StudioTheme.font()` is
## static and is called from `Look._ready()`, whose order against I18n's is set by
## project.godot rather than by this file.
static func lang() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("I18n"):
		return str(tree.root.get_node("I18n").lang)
	return "en"


## The face the current language needs, or null for English (which uses the Latin stack —
## a CJK face set for Latin copy is a different, worse-looking bug).
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

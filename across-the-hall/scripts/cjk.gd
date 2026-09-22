extends RefCounted
class_name Cjk
## The CJK face for the current language.
##
## What this file used to be, and why it could never have worked:
##
##     const FACE := preload("res://fonts/DroidSansFallback.ttf")
##
## fonts/ contains DroidSansFallback.ttf.import and NOT DroidSansFallback.ttf. The font was
## never in the repository. Nothing called Cjk.apply_label(), so the broken preload was
## never reached and never reported — the game had a Chinese font helper, an import stub
## for a file that does not exist, and no Chinese. That is the memory
## `verification-that-lies` in its purest form: a thing that looks done from the outside
## because nobody ever asked it to do anything.
##
## What it is now: assets/fonts/NotoSansCJK{sc,tc,jp}-subset.ttf, built by
## ops/subset_cjk.py from the game's own i18n table, one face per script family so Japanese
## kanji render in Japanese forms. ~300 KB for all three.
##
## TWO ENGINE RULES, both of them bought.
##
## The resource is HELD in _kept. A FontFile loaded and dropped is freed, and on the web
## export the label then draws in the fallback with no error at all (memory:
## `godot-web-font-fallback`). A static array on the class is the simplest thing that
## survives for the life of the run.
##
## load(), never preload(). preload resolves at parse time, so a language whose subset is
## missing from a build would refuse to compile the whole script rather than fall back to
## Latin — and a missing font should cost you the glyphs, not the game.

const DIR := "res://assets/fonts/"
const FILES := {
	"zh": "NotoSansCJKsc-subset.ttf",
	"zh-Hant": "NotoSansCJKtc-subset.ttf",
	"ja": "NotoSansCJKjp-subset.ttf",
}

static var _kept := {}


## The face the current language needs, or null for English (which uses the Latin stack in
## ui_font.gd — a CJK face set for Latin copy is a different, worse-looking bug).
static func face() -> Font:
	var lang := "en"
	if Engine.has_singleton("I18n"):
		lang = str(Engine.get_singleton("I18n").lang)
	else:
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root.has_node("I18n"):
			lang = str(tree.root.get_node("I18n").lang)
	if not FILES.has(lang):
		return null
	if _kept.has(lang):
		return _kept[lang]
	var path: String = DIR + str(FILES[lang])
	if not ResourceLoader.exists(path):
		push_warning("CJK subset missing: %s — %s will draw as empty boxes" % [path, lang])
		return null
	var f: Font = load(path)
	_kept[lang] = f
	return f


## Set whichever face the current language wants on a Label: CJK when there is one, the
## browser-safe Latin stack when there is not. Every call site can use this unconditionally.
static func apply_label(l: Label) -> void:
	var f := face()
	if f:
		l.add_theme_font_override("font", f)
	else:
		UiFont.apply_label(l)


static func apply_3d(l: Label3D) -> void:
	var f := face()
	if f:
		l.font = f
	else:
		UiFont.apply_3d(l)


## For a Button (or anything else that takes a "font" theme override).
static func apply_control(c: Control) -> void:
	var f := face()
	if f:
		c.add_theme_font_override("font", f)

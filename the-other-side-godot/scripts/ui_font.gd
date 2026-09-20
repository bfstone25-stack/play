extends RefCounted
class_name UiFont

## The game's type. Work Sans (SIL OFL 1.1, fonts/WorkSans-OFL.txt) — a grotesque with
## enough weight in the bold to carry a title card, and enough room in the regular to stay
## readable at 16 px over a dark room. Bundled, not a system face: UI_DIRECTION.md's rule
## is that a system font is how a build ends up looking like whatever machine opened it,
## and the first capture was set in Arial.
##
## The fonts are held in static vars for the life of the process. A FontFile that is
## load()ed and then dropped loses its fallbacks on the web export (memory:
## godot-web-font-fallback), and the same holding rule keeps the face itself alive.
## Verify any change to this file on the web build, not just on desktop.

const BOLD_PATH := "res://fonts/WorkSans-Bold.ttf"
const BODY_PATH := "res://fonts/WorkSans-Regular.ttf"

static var _bold: Font = null
static var _body: Font = null
static var _fallback: Font = null

static func _system() -> Font:
	if _fallback == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Arial", "Helvetica", "Noto Sans", "DejaVu Sans", "sans-serif"])
		_fallback = f
	return _fallback

static func _held(path: String, slot: int) -> Font:
	var cached: Font = _bold if slot == 0 else _body
	if cached != null:
		return cached
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	if f == null:
		f = _system()
	if slot == 0:
		_bold = f
	else:
		_body = f
	return f

## Display: the title card, the chapter cards, the speaker's line.
static func display() -> Font:
	return _held(BOLD_PATH, 0)

## UI: prompts, objectives, notes, the clock.
static func face() -> Font:
	return _held(BODY_PATH, 1)

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", face())

static func apply_display(l: Label) -> void:
	l.add_theme_font_override("font", display())

static func apply_3d(l: Label3D) -> void:
	l.font = face()

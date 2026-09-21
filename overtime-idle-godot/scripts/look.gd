extends Node
## Look autoload — the studio palette and Theme (scripts/palette.gd, scripts/studio_theme.gd:
## the same two files play/silvertongue-cards-godot carries), and the art loader for the
## parent's installed plates (assets/art/, filled by tools/sync_art.py at build time;
## nothing is committed from there).
##
## The names below are what the scenes were written against; they resolve onto the
## UI_DIRECTION roles. New code should say Palette.GOLD, not Look.AMBER.

const BG := Palette.GROUND
const INK := Palette.TEXT
const MUTED := Palette.MUTED
const EMERALD := Palette.SUCCESS
const AMBER := Palette.GOLD
const STEEL := Palette.COMMON
const CHAR := Palette.GROUND_DEEP
const PANEL := Palette.PANEL
const LINE := Palette.PANEL_EDGE
const LINE2 := Palette.LINE_STRONG
const EMBER := Palette.HEAT
const ROSE := Palette.ACCENT
const LAMP := Palette.GOLD_PALE

const ART_DIR := "res://assets/art/"

## Mirei's mood sprites render as calm / tense / pleased / cold; the game's moods are the
## parent's calm / tense / fail / empty. The alias is where the two meet.
const MOOD_ALIAS := {"fail": "cold", "empty": "cold", "chain": "pleased"}

var theme: Theme
var font_ui: Font
var font_ui_bold: Font
var font_display: Font
var font_italic: Font
var font_mono: Font        # retired: resolves to the UI face
var font_mono_bold: Font   # retired: resolves to the display face (numbers on the floor)
var _art: Dictionary = {}


func _ready() -> void:
	font_ui = StudioTheme.font("ui")
	font_ui_bold = StudioTheme.font("bold")
	font_display = StudioTheme.font("display")
	font_italic = StudioTheme.font("italic")
	font_mono = font_ui
	font_mono_bold = font_display
	theme = StudioTheme.build()
	get_tree().root.theme = theme


## Rebuild every face and the Theme after a language change, and put the new Theme on the
## tree root. `StudioTheme.reset_fonts()` has to have been called first — it drops the
## static caches the old (Latin-only, or wrong-script) FontFiles live in.
func rebuild() -> void:
	font_ui = StudioTheme.font("ui")
	font_ui_bold = StudioTheme.font("bold")
	font_display = StudioTheme.font("display")
	font_italic = StudioTheme.font("italic")
	font_mono = font_ui
	font_mono_bold = font_display
	theme = StudioTheme.build()
	get_tree().root.theme = theme


## The scenes' StyleBox helper (integer padding); StudioTheme.flat takes a Vector2.
static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 6, bw: int = 1, pad: int = 10) -> StyleBoxFlat:
	return StudioTheme.flat(bg, border, radius, bw, Vector2(pad, pad))


func build_theme() -> Theme:
	return StudioTheme.build()


## The parent's installed plate, by id ("cg_priya_x", "cg_priya_x_locked", "title",
## "landlord-portrait", "plate_unearned", and once rendered "piece_dan", "mirei_calm").
## Null when the art is not in this package — the scene degrades to a drawn placeholder,
## never to a crash.
func art(id: String) -> Texture2D:
	if _art.has(id):
		return _art[id]
	var path := ART_DIR + id + ".webp"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			tex = res
	if tex == null and FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
	_art[id] = tex
	return tex


## A staff piece's portrait sprite (piece_<id>.webp), or null while the vector block
## stands in. The cards are built portrait-first, so the swap is this texture arriving.
func piece_portrait(id: String) -> Texture2D:
	return art("piece_" + id)


## Mirei's HUD portrait: a figure crop of the free tier-1 plate. The parent's
## `landlord-portrait.webp` is a different character (a man in a suit), so it is not her.
## Mood sprites (mirei_<mood>.webp, via MOOD_ALIAS) are used when installed; until then
## the base crop is tinted by mood in mirei.gd. Honest stub: one plate, four moods.
func portrait(mood: String) -> Texture2D:
	var key := "portrait_" + mood
	if _art.has(key):
		return _art[key]
	var specific := art("mirei_" + mood)
	if specific == null and MOOD_ALIAS.has(mood):
		specific = art("mirei_" + MOOD_ALIAS[mood])
	if specific != null:
		_art[key] = specific
		return specific
	var base := art("cg_mirei_lease")
	if base == null:
		_art[key] = null
		return null
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = Rect2(370, 0, 450, 600)
	_art[key] = at
	return at

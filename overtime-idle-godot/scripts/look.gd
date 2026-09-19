extends Node
## Look autoload — the palette (the parent's CSS variables), the Theme built from it, and
## the art loader for the parent's installed plates (assets/art/, filled by
## tools/sync_art.py at build time; nothing is committed from there).

const BG := Color("#12161c")
const INK := Color("#e8efe8")
const MUTED := Color("#7e8a8a")
const EMERALD := Color("#1f8a64")
const AMBER := Color("#e0a14a")
const STEEL := Color("#4a6d8c")
const CHAR := Color("#0d1116")
const PANEL := Color("#171d24")
const LINE := Color("#2c3842")
const LINE2 := Color("#3d5360")
const EMBER := Color("#c45c32")
const ROSE := Color("#d9739a")
const LAMP := Color("#ffb45c")

const ART_DIR := "res://assets/art/"

var theme: Theme
var font_ui: FontFile
var font_ui_bold: FontFile
var font_mono: FontFile
var font_mono_bold: FontFile
var _art: Dictionary = {}


func _ready() -> void:
	font_ui = load("res://assets/fonts/Ubuntu-R.ttf")
	font_ui_bold = load("res://assets/fonts/Ubuntu-B.ttf")
	font_mono = load("res://assets/fonts/UbuntuMono-R.ttf")
	font_mono_bold = load("res://assets/fonts/UbuntuMono-B.ttf")
	theme = build_theme()
	get_tree().root.theme = theme


static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 6, bw: int = 1, pad: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw if border.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.anti_aliasing = true
	return s


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_ui
	t.default_font_size = 15

	var panel := flat(Color(PANEL, 0.94), LINE, 8, 1, 14)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 18
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# Buttons: dark steel, amber on hover, pressed sinks.
	var b_norm := flat(Color("#1a2228"), LINE2, 6, 1, 10)
	var b_hover := flat(Color("#22303a"), AMBER, 6, 1, 10)
	var b_press := flat(Color("#0f1418"), AMBER, 6, 1, 10)
	var b_dis := flat(Color("#141a20"), LINE, 6, 1, 10)
	t.set_stylebox("normal", "Button", b_norm)
	t.set_stylebox("hover", "Button", b_hover)
	t.set_stylebox("pressed", "Button", b_press)
	t.set_stylebox("disabled", "Button", b_dis)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color("#c9d4c9"))
	t.set_color("font_hover_color", "Button", AMBER)
	t.set_color("font_pressed_color", "Button", AMBER)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_font("font", "Button", font_ui_bold)
	t.set_font_size("font_size", "Button", 14)

	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", font_ui)
	t.set_font("bold_font", "RichTextLabel", font_ui_bold)
	t.set_font("mono_font", "RichTextLabel", font_mono)

	var sb := flat(Color("#0f1418"), LINE, 4, 1, 2)
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", flat(LINE2, Color(0, 0, 0, 0), 4, 0, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(AMBER, Color(0, 0, 0, 0), 4, 0, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat(AMBER, Color(0, 0, 0, 0), 4, 0, 2))

	# Named variations the scenes use.
	t.add_type("Primary")
	t.set_type_variation("Primary", "Button")
	var p_norm := StyleBoxFlat.new()
	p_norm.bg_color = Color("#2a6b52")
	p_norm.border_color = Color("#3d8a68")
	p_norm.set_border_width_all(1)
	p_norm.set_corner_radius_all(6)
	p_norm.set_content_margin_all(12)
	t.set_stylebox("normal", "Primary", p_norm)
	t.set_stylebox("hover", "Primary", flat(Color("#32805f"), AMBER, 6, 1, 12))
	t.set_stylebox("pressed", "Primary", flat(Color("#1a4536"), AMBER, 6, 1, 12))
	t.set_color("font_color", "Primary", INK)
	t.set_font_size("font_size", "Primary", 16)

	t.add_type("Amber")
	t.set_type_variation("Amber", "Button")
	t.set_stylebox("normal", "Amber", flat(Color("#2b2417"), AMBER, 6, 1, 10))
	t.set_stylebox("hover", "Amber", flat(Color("#3b2f18"), LAMP, 6, 1, 10))
	t.set_stylebox("pressed", "Amber", flat(Color("#1c170e"), LAMP, 6, 1, 10))
	t.set_color("font_color", "Amber", AMBER)

	t.add_type("Ghost")
	t.set_type_variation("Ghost", "Button")
	t.set_stylebox("normal", "Ghost", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 6, 0, 8))
	t.set_stylebox("hover", "Ghost", flat(Color(1, 1, 1, 0.05), Color(0, 0, 0, 0), 6, 0, 8))
	t.set_stylebox("pressed", "Ghost", flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 6, 0, 8))
	t.set_color("font_color", "Ghost", MUTED)

	t.add_type("Tag")
	t.set_type_variation("Tag", "Label")
	t.set_font("font", "Tag", font_mono_bold)
	t.set_font_size("font_size", "Tag", 12)
	t.set_color("font_color", "Tag", MUTED)

	t.add_type("Mono")
	t.set_type_variation("Mono", "Label")
	t.set_font("font", "Mono", font_mono)
	t.set_font_size("font_size", "Mono", 15)

	t.add_type("Big")
	t.set_type_variation("Big", "Label")
	t.set_font("font", "Big", font_mono_bold)
	t.set_font_size("font_size", "Big", 30)
	t.set_color("font_color", "Big", AMBER)

	t.add_type("Title")
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", font_ui_bold)
	t.set_font_size("font_size", "Title", 26)

	t.add_type("Glass")
	t.set_type_variation("Glass", "PanelContainer")
	var g := flat(Color(0.07, 0.086, 0.11, 0.78), Color(LINE2, 0.7), 8, 1, 12)
	t.set_stylebox("panel", "Glass", g)

	t.add_type("Card")
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", flat(Color("#1a2228"), LINE2, 8, 1, 12))
	return t


## The parent's installed plate, by id ("cg_priya_x", "cg_priya_x_locked", "title",
## "landlord-portrait", "plate_unearned"). Null when the art is not in this package —
## the scene degrades to a drawn placeholder, never to a crash.
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


## Mirei's HUD portrait: a figure crop of the free tier-1 plate. The parent's
## `landlord-portrait.webp` is a different character (a man in a suit), so it is not her.
## Mood variants (portrait_<mood>.webp) are loaded when installed; until then the base crop
## is tinted by mood in mirei.gd. Honest stub: one plate, four moods.
func portrait(mood: String) -> Texture2D:
	var key := "portrait_" + mood
	if _art.has(key):
		return _art[key]
	var specific := art("mirei_" + mood)
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

## StudioTheme — the Theme, built in code so it lives in git as text (the siblings'
## convention). Fonts, all OFL, bundled in assets/fonts/ with licences beside them:
##   ui       Nunito (variable)             buttons, labels, HUD — Latin, with the CJK face as fallback
##   serif    Noto Serif CJK SC (subset)    签文, readings, her lines in zh — the temple voice
##   italic   Playfair Display Italic       her lines in en, the West's readings
## The CJK subset is rebuilt by tools/subset_font.py from exactly the strings the game has.
class_name StudioTheme

const FONT_UI := "res://assets/fonts/Nunito.ttf"
const FONT_CJK := "res://assets/fonts/NotoSerifSC-subset.otf"
const FONT_ITALIC := "res://assets/fonts/PlayfairDisplay-Italic.ttf"

static var _cache: Theme
static var _fonts := {}
static var _files := {}


static func _file(path: String) -> Font:
	if not _files.has(path):
		_files[path] = load(path)
	return _files[path]


static func _var(path: String, wght: int, fallbacks: Array) -> Font:
	var fv := FontVariation.new()
	fv.base_font = _file(path)
	if wght > 0:
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	var fb: Array[Font] = []
	for f in fallbacks:
		fb.append(_file(f))
	fv.fallbacks = fb
	return fv


## "ui" (600) | "bold" (700) | "black" (800) | "serif" | "italic" | "display" (-> black)
static func font(which: String) -> Font:
	if _fonts.has(which):
		return _fonts[which]
	var f: Font
	match which:
		"bold": f = _var(FONT_UI, 700, [FONT_CJK])
		"black", "display": f = _var(FONT_UI, 800, [FONT_CJK])
		"serif": f = _var(FONT_CJK, 0, [FONT_UI])
		"italic": f = _var(FONT_ITALIC, 500, [FONT_CJK])
		_: f = _var(FONT_UI, 600, [FONT_CJK])
	_fonts[which] = f
	return f


static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 8, width: int = 1,
		pad: Vector2 = Vector2(10, 6)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(width if border.a > 0 else 0)
	s.border_color = border
	s.content_margin_left = pad.x
	s.content_margin_right = pad.x
	s.content_margin_top = pad.y
	s.content_margin_bottom = pad.y
	s.anti_aliasing = true
	return s


static func glow(s: StyleBoxFlat, color: Color, size: int = 14, alpha: float = 0.55) -> StyleBoxFlat:
	s.shadow_color = Color(color, alpha)
	s.shadow_size = size
	s.shadow_offset = Vector2.ZERO
	return s


static func _variation(t: Theme, name: String, base: String) -> void:
	t.add_type(name)
	t.set_type_variation(name, base)


static func build() -> Theme:
	if _cache:
		return _cache
	var t := Theme.new()
	t.default_font = font("ui")
	t.default_font_size = 18

	t.set_font("font", "Button", font("bold"))
	t.set_font_size("font_size", "Button", 19)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.GOLD_PALE)
	t.set_color("font_pressed_color", "Button", Palette.TEXT)
	t.set_color("font_disabled_color", "Button", Palette.MUTED)
	t.set_color("font_focus_color", "Button", Palette.TEXT)
	t.set_stylebox("normal", "Button", flat(Palette.INK_SOFT, Palette.INK_EDGE, 10, 1, Vector2(18, 12)))
	t.set_stylebox("hover", "Button", flat(Palette.INK_EDGE, Palette.GOLD, 10, 1, Vector2(18, 12)))
	t.set_stylebox("pressed", "Button", flat(Palette.INK_DEEP, Palette.GOLD, 10, 1, Vector2(18, 12)))
	t.set_stylebox("disabled", "Button", flat(Color(Palette.INK_SOFT, 0.6), Color(Palette.INK_EDGE, 0.5), 10, 1, Vector2(18, 12)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	var panel := flat(Color(Palette.INK_SOFT, 0.96), Palette.INK_EDGE, 14, 1, Vector2(18, 18))
	panel.shadow_color = Color(0, 0, 0, 0.5)
	panel.shadow_size = 18
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_font_size("font_size", "Label", 18)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_font("normal_font", "RichTextLabel", font("ui"))
	t.set_font("bold_font", "RichTextLabel", font("bold"))
	t.set_font("italics_font", "RichTextLabel", font("italic"))
	t.set_font("bold_italics_font", "RichTextLabel", font("italic"))
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := flat(Palette.INK_EDGE, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0))
	var track := flat(Color(Palette.INK_DEEP, 0.6), Color(0, 0, 0, 0), 4, 0, Vector2(2, 2))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.GOLD, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.GOLD_PALE, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))

	t.set_stylebox("background", "ProgressBar", flat(Palette.WOOD_DARK, Palette.WOOD, 6, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.LACQUER, Color(0, 0, 0, 0), 6, 0, Vector2(0, 0)))
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 10)

	# Lacquer: the one thing to press on the East side — the shake button.
	_variation(t, "Lacquer", "Button")
	t.set_stylebox("normal", "Lacquer", glow(flat(Palette.LACQUER, Palette.GOLD, 12, 1, Vector2(24, 14)), Palette.LACQUER, 14, 0.45))
	t.set_stylebox("hover", "Lacquer", glow(flat(Palette.LACQUER_SOFT, Palette.GOLD_PALE, 12, 1, Vector2(24, 14)), Palette.LACQUER, 20, 0.6))
	t.set_stylebox("pressed", "Lacquer", flat(Palette.LACQUER_DEEP, Palette.GOLD, 12, 1, Vector2(24, 14)))
	t.set_stylebox("disabled", "Lacquer", flat(Color(Palette.LACQUER_DEEP, 0.5), Color(Palette.GOLD_DEEP, 0.5), 12, 1, Vector2(24, 14)))
	t.set_color("font_color", "Lacquer", Palette.GOLD_PALE)
	t.set_color("font_hover_color", "Lacquer", Palette.TEXT)
	t.set_font_size("font_size", "Lacquer", 24)

	# Candle: the one thing to press on the West side — turn the card, begin.
	_variation(t, "Candle", "Button")
	t.set_stylebox("normal", "Candle", glow(flat(Palette.CANDLE_DEEP, Palette.CANDLE, 12, 1, Vector2(24, 14)), Palette.CANDLE, 14, 0.4))
	t.set_stylebox("hover", "Candle", glow(flat(Palette.CANDLE, Palette.PARCHMENT, 12, 1, Vector2(24, 14)), Palette.CANDLE, 20, 0.6))
	t.set_stylebox("pressed", "Candle", flat(Palette.CANDLE_DEEP, Palette.PARCHMENT, 12, 1, Vector2(24, 14)))
	t.set_stylebox("disabled", "Candle", flat(Color(Palette.CANDLE_DEEP, 0.4), Color(Palette.CANDLE, 0.4), 12, 1, Vector2(24, 14)))
	t.set_color("font_color", "Candle", Palette.VIOLET_DEEP)
	t.set_color("font_hover_color", "Candle", Palette.VIOLET_DEEP)
	t.set_font_size("font_size", "Candle", 24)

	# Silver: a West secondary — cut the deck, a choice at her table.
	_variation(t, "Silver", "Button")
	t.set_stylebox("normal", "Silver", flat(Palette.VIOLET_SOFT, Palette.SILVER_DIM, 10, 1, Vector2(18, 12)))
	t.set_stylebox("hover", "Silver", flat(Palette.VIOLET_EDGE, Palette.SILVER, 10, 1, Vector2(18, 12)))
	t.set_stylebox("pressed", "Silver", flat(Palette.VIOLET_DEEP, Palette.SILVER, 10, 1, Vector2(18, 12)))
	t.set_color("font_color", "Silver", Palette.SILVER)

	# Hot: the night skin's primary (ops/adult_forks/UI_DIRECTION.md) — the read button,
	# and nothing else. One hot control per screen or it stops meaning "press this".
	_variation(t, "Hot", "Button")
	t.set_stylebox("normal", "Hot", glow(flat(Palette.HOT, Palette.HOT_PALE, 12, 1, Vector2(22, 14)), Palette.HOT, 16, 0.45))
	t.set_stylebox("hover", "Hot", glow(flat(Palette.HOT.lightened(0.12), Palette.TEXT, 12, 1, Vector2(22, 14)), Palette.HOT, 20, 0.6))
	t.set_stylebox("pressed", "Hot", flat(Palette.HOT_DEEP, Palette.HOT_PALE, 12, 1, Vector2(22, 14)))
	t.set_stylebox("disabled", "Hot", flat(Palette.PLUM_SOFT, Palette.PLUM_EDGE, 12, 1, Vector2(22, 14)))
	t.set_color("font_color", "Hot", Palette.PLUM)
	t.set_color("font_hover_color", "Hot", Palette.PLUM)
	t.set_color("font_disabled_color", "Hot", Palette.MAUVE)
	t.set_font_size("font_size", "Hot", 24)

	# Gold: an East secondary — add incense, keep.
	_variation(t, "Gold", "Button")
	t.set_stylebox("normal", "Gold", flat(Palette.INK_SOFT, Palette.GOLD, 10, 1, Vector2(18, 12)))
	t.set_stylebox("hover", "Gold", flat(Palette.INK_EDGE, Palette.GOLD_PALE, 10, 1, Vector2(18, 12)))
	t.set_stylebox("pressed", "Gold", flat(Palette.GOLD_DEEP, Palette.GOLD_PALE, 10, 1, Vector2(18, 12)))
	t.set_color("font_color", "Gold", Palette.GOLD)
	t.set_color("font_hover_color", "Gold", Palette.GOLD_PALE)

	# Chip: a small toggle (subject, tab); Active when on.
	_variation(t, "Chip", "Button")
	t.set_stylebox("normal", "Chip", flat(Color(Palette.INK_SOFT, 0.7), Palette.INK_EDGE, 16, 1, Vector2(14, 6)))
	t.set_stylebox("hover", "Chip", flat(Palette.INK_EDGE, Palette.GOLD_DEEP, 16, 1, Vector2(14, 6)))
	t.set_stylebox("pressed", "Chip", flat(Palette.LACQUER_DEEP, Palette.GOLD, 16, 1, Vector2(14, 6)))
	t.set_font_size("font_size", "Chip", 16)
	t.set_color("font_color", "Chip", Palette.MUTED)
	_variation(t, "ChipOn", "Chip")
	t.set_stylebox("normal", "ChipOn", flat(Palette.LACQUER_DEEP, Palette.GOLD, 16, 1, Vector2(14, 6)))
	t.set_stylebox("hover", "ChipOn", flat(Palette.LACQUER, Palette.GOLD_PALE, 16, 1, Vector2(14, 6)))
	t.set_color("font_color", "ChipOn", Palette.GOLD_PALE)

	_variation(t, "Ghost", "Button")
	t.set_stylebox("normal", "Ghost", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0, Vector2(10, 8)))
	t.set_stylebox("hover", "Ghost", flat(Color(Palette.GOLD, 0.12), Color(0, 0, 0, 0), 8, 0, Vector2(10, 8)))
	t.set_stylebox("pressed", "Ghost", flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 8, 0, Vector2(10, 8)))
	t.set_color("font_color", "Ghost", Palette.MUTED)

	_variation(t, "Tag", "Label")
	t.set_font("font", "Tag", font("bold"))
	t.set_font_size("font_size", "Tag", 13)
	t.set_color("font_color", "Tag", Palette.MUTED)

	_variation(t, "Big", "Label")
	t.set_font("font", "Big", font("black"))
	t.set_font_size("font_size", "Big", 34)
	t.set_color("font_color", "Big", Palette.GOLD)

	_variation(t, "Title", "Label")
	t.set_font("font", "Title", font("serif"))
	t.set_font_size("font_size", "Title", 34)
	t.set_color("font_color", "Title", Palette.TEXT)

	# Paper: the slip, the parchment. Warm paper, thin gold line.
	_variation(t, "Paper", "PanelContainer")
	var paper := flat(Palette.PAPER, Color(Palette.GOLD_DEEP, 0.6), 6, 1, Vector2(26, 24))
	paper.shadow_color = Color(0, 0, 0, 0.45)
	paper.shadow_size = 16
	t.set_stylebox("panel", "Paper", paper)
	_variation(t, "Parchment", "PanelContainer")
	var parch := flat(Palette.PARCHMENT, Color(Palette.SILVER_DIM, 0.7), 10, 1, Vector2(26, 24))
	parch.shadow_color = Color(0, 0, 0, 0.5)
	parch.shadow_size = 18
	t.set_stylebox("panel", "Parchment", parch)

	_variation(t, "Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", flat(Color(Palette.INK, 0.72), Color(Palette.INK_EDGE, 0.9), 12, 1, Vector2(16, 14)))
	_variation(t, "GlassWest", "PanelContainer")
	t.set_stylebox("panel", "GlassWest", flat(Color(Palette.VIOLET_DEEP, 0.72), Color(Palette.VIOLET_EDGE, 0.9), 12, 1, Vector2(16, 14)))

	_cache = t
	return t


static func label(text: String, size: int = 18, color: Color = Palette.TEXT, which: String = "ui") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(which))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrapped(text: String, size: int = 18, color: Color = Palette.TEXT, which: String = "ui") -> Label:
	var l := label(text, size, color, which)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	return b

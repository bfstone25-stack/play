## StudioTheme — the one Theme for the studio's Godot forks, built in code so it lives in
## git as text and so the sibling titles can call `StudioTheme.build()` and get the same
## buttons, panels and fonts. No default Godot grey anywhere: every control type used in
## the client has its StyleBox set here.
class_name StudioTheme

const FONT_DISPLAY := "res://assets/fonts/display_bold.ttf"
const FONT_SERIF := "res://assets/fonts/serif.ttf"
const FONT_SERIF_BOLD := "res://assets/fonts/serif_bold.ttf"
const FONT_SERIF_ITALIC := "res://assets/fonts/serif_italic.ttf"
const FONT_MONO := "res://assets/fonts/mono_bold.ttf"

const FONT_SYMBOLS := "res://assets/fonts/fallback_symbols.ttf"   # ♥ ◆ ⚡ ★ ◈ ✕ — DejaVu, the web has no system fallback

static var _cache: Theme
static var _fonts := {}

static func font(which: String) -> Font:
	if _fonts.has(which):
		return _fonts[which]
	var path := FONT_SERIF
	match which:
		"display": path = FONT_DISPLAY
		"bold": path = FONT_SERIF_BOLD
		"italic": path = FONT_SERIF_ITALIC
		"mono": path = FONT_MONO
	var f: Font = load(path)
	if f is FontFile and (f as FontFile).fallbacks.is_empty():
		var fb: Font = load(FONT_SYMBOLS)
		if fb:
			(f as FontFile).fallbacks = [fb]
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


static func build() -> Theme:
	if _cache:
		return _cache
	var t := Theme.new()
	t.default_font = font("serif")
	t.default_font_size = 16

	# --- Button: brass on dark, amber when hovered, lamp-gold when pressed -------------
	t.set_font("font", "Button", font("mono"))
	t.set_font_size("font_size", "Button", 13)
	t.set_color("font_color", "Button", Color("d8c39a"))
	t.set_color("font_hover_color", "Button", Palette.LAMP)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("font_focus_color", "Button", Palette.LAMP)
	t.set_stylebox("normal", "Button", flat(Color("28201d"), Palette.LINE_STRONG, 7))
	t.set_stylebox("hover", "Button", flat(Color("33281f"), Palette.AMBER, 7))
	t.set_stylebox("pressed", "Button", flat(Palette.AMBER, Palette.AMBER, 7))
	t.set_stylebox("disabled", "Button", flat(Color("1e1816"), Palette.LINE_SOFT, 7))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# --- Panel / PanelContainer ----------------------------------------------------------
	t.set_stylebox("panel", "Panel", flat(Palette.PANEL, Palette.LINE, 10, 1, Vector2(0, 0)))
	t.set_stylebox("panel", "PanelContainer", flat(Palette.PANEL, Palette.LINE, 10, 1, Vector2(12, 10)))

	# --- Label ---------------------------------------------------------------------------
	t.set_color("font_color", "Label", Palette.CREAM)
	t.set_font_size("font_size", "Label", 16)
	t.set_color("default_color", "RichTextLabel", Palette.CREAM)
	t.set_font("normal_font", "RichTextLabel", font("serif"))
	t.set_font("bold_font", "RichTextLabel", font("bold"))
	t.set_font("italics_font", "RichTextLabel", font("italic"))
	t.set_font("mono_font", "RichTextLabel", font("mono"))
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

	# --- LineEdit: the wild card's mouth -------------------------------------------------
	t.set_font("font", "LineEdit", font("serif"))
	t.set_font_size("font_size", "LineEdit", 18)
	t.set_color("font_color", "LineEdit", Palette.PARCHMENT)
	t.set_color("font_placeholder_color", "LineEdit", Palette.DIM)
	t.set_color("caret_color", "LineEdit", Palette.AMBER)
	t.set_color("selection_color", "LineEdit", Color(Palette.AMBER, 0.35))
	t.set_stylebox("normal", "LineEdit", flat(Palette.PANEL, Palette.AMBER, 20, 1, Vector2(16, 9)))
	t.set_stylebox("focus", "LineEdit", flat(Palette.PANEL, Palette.LAMP, 20, 2, Vector2(16, 9)))
	t.set_stylebox("read_only", "LineEdit", flat(Palette.PANEL, Palette.LINE, 20, 1, Vector2(16, 9)))

	# --- ScrollContainer / scrollbars ----------------------------------------------------
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := flat(Palette.LINE_STRONG, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0))
	var track := flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 4, 0, Vector2(0, 0))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.AMBER, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.LAMP, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))

	# --- ProgressBar (energy) ------------------------------------------------------------
	t.set_stylebox("background", "ProgressBar", flat(Color("2a2220"), Color("4a3c30"), 5, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.GREEN, Color(0, 0, 0, 0), 5, 0, Vector2(0, 0)))

	# --- Tooltip -------------------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", flat(Color("2a1c10"), Palette.AMBER, 8))
	t.set_color("font_color", "TooltipLabel", Palette.LAMP)

	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 8)
	_cache = t
	return t


## Style variants used across screens. Names are what the sibling title should reuse.
static func style_button(b: Button, variant: String) -> void:
	match variant:
		"primary":   # amber, ink text — the one thing on the screen to press
			b.add_theme_stylebox_override("normal", flat(Palette.AMBER_DEEP, Palette.AMBER, 8, 1, Vector2(14, 8)))
			b.add_theme_stylebox_override("hover", flat(Palette.AMBER, Palette.LAMP, 8, 1, Vector2(14, 8)))
			b.add_theme_stylebox_override("pressed", flat(Palette.LAMP, Palette.LAMP, 8, 1, Vector2(14, 8)))
			b.add_theme_color_override("font_color", Palette.INK)
			b.add_theme_color_override("font_hover_color", Palette.INK)
			b.add_theme_color_override("font_pressed_color", Palette.INK)
		"free":      # green — costs nothing
			b.add_theme_stylebox_override("normal", flat(Palette.GREEN_DEEP, Palette.GREEN, 8, 1, Vector2(14, 8)))
			b.add_theme_stylebox_override("hover", flat(Palette.GREEN, Palette.GREEN, 8, 1, Vector2(14, 8)))
			b.add_theme_stylebox_override("pressed", flat(Color("b8e08a"), Palette.GREEN, 8, 1, Vector2(14, 8)))
			b.add_theme_color_override("font_color", Color("0f1e0f"))
			b.add_theme_color_override("font_hover_color", Color("0f1e0f"))
			b.add_theme_color_override("font_pressed_color", Color("0f1e0f"))
		"active":    # a nav tab that is on
			b.add_theme_stylebox_override("normal", flat(Color("33281f"), Palette.AMBER, 7))
			b.add_theme_color_override("font_color", Palette.LAMP)
		"quiet":
			b.add_theme_stylebox_override("normal", flat(Color(0, 0, 0, 0), Palette.LINE_STRONG, 7))


static func mono_label(text: String, size: int = 11, color: Color = Palette.MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("mono"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func serif_label(text: String, size: int = 16, color: Color = Palette.CREAM, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold" if bold else "serif"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func display_label(text: String, size: int = 28, color: Color = Palette.LAMP) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("display"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

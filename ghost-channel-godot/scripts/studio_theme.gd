## StudioTheme — the one Theme for GHOST CHANNEL, built in code so it lives in git as text
## and so the call sites match the studio's other Godot forks
## (play/overtime-idle-godot/scripts/studio_theme.gd): `StudioTheme.build()`,
## `StudioTheme.font("display")`, the "Primary" / "Amber" / "Active" / "Ghost" / "Tag" /
## "Value" / "Big" / "Title" / "Card" / "Glass" type variations.
##
## No default Godot grey anywhere: every control type the client uses has its StyleBox set.
##
## Type — four OFL/Apache faces bundled in assets/fonts/, licences beside them, never a
## system font. The faces are this title's, not the shared set: a relay station is
## instrumentation, and instrumentation is condensed grotesque and monospace, not the
## poster face and the Playfair italic the adult forks use.
##
##   display   Fira Sans Compressed Heavy    the logotype, headings, the numbers that land
##   ui        Fira Sans Condensed Book      body, the log, the roster
##   bold      Fira Sans Condensed SemiBold  buttons, labels, the HUD
##   mono      Fira Mono Medium              the readouts: codebook, grid squares, clock
##
## Every face carries DroidSansFallbackFull as a fallback, so the zh build draws its own
## characters from the package instead of borrowing the browser's.
class_name StudioTheme

const FONT_DISPLAY := "res://assets/fonts/FiraSansCompressed-Heavy.otf"
const FONT_UI := "res://assets/fonts/FiraSansCondensed-Book.otf"
const FONT_BOLD := "res://assets/fonts/FiraSansCondensed-SemiBold.otf"
const FONT_MONO := "res://assets/fonts/FiraMono-Medium.otf"
const FONT_CJK := "res://assets/fonts/DroidSansFallbackFull.ttf"
# the sibling's constant names, resolved onto the four faces above
const FONT_SERIF := FONT_UI
const FONT_SERIF_BOLD := FONT_BOLD
const FONT_ITALIC := FONT_UI

static var _cache: Theme
static var _fonts := {}
static var _cjk: FontFile


static func _file(path: String) -> FontFile:
	var f: FontFile = load(path)
	if _cjk == null:
		_cjk = load(FONT_CJK)
	if path != FONT_CJK and not f.fallbacks.has(_cjk):
		f.fallbacks = [_cjk]
	return f


## "display" | "ui" | "bold" | "mono". The sibling's names resolve here too:
## "black" -> display, "serif" -> ui, "italic" -> ui.
static func font(which: String) -> Font:
	if _fonts.has(which):
		return _fonts[which]
	var f: Font
	match which:
		"display", "black": f = _file(FONT_DISPLAY)
		"bold": f = _file(FONT_BOLD)
		"mono": f = _file(FONT_MONO)
		_: f = _file(FONT_UI)
	_fonts[which] = f
	return f


static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 3, width: int = 1,
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


## The same box with a glow: a soft shadow in the accent colour, drawn all round. Allowed
## on a live channel, the verdict buttons, a lit call-light. Never on body text.
static func glow(s: StyleBoxFlat, color: Color, size: int = 12, alpha: float = 0.5) -> StyleBoxFlat:
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
	t.default_font_size = 16

	# Corner radius stays near-zero across the whole client on purpose: this is a steel
	# panel with square-cut holes, not a phone app.
	# --- Button ---------------------------------------------------------------------
	t.set_font("font", "Button", font("bold"))
	t.set_font_size("font_size", "Button", 15)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.ACCENT_SOFT)
	t.set_color("font_pressed_color", "Button", Palette.GROUND)
	t.set_color("font_disabled_color", "Button", Palette.DIM)
	t.set_color("font_focus_color", "Button", Palette.ACCENT_SOFT)
	t.set_stylebox("normal", "Button", flat(Palette.PANEL_RAISED, Palette.LINE_STRONG, 3, 1, Vector2(14, 9)))
	t.set_stylebox("hover", "Button", flat(Palette.PANEL_TOP, Palette.ACCENT, 3, 1, Vector2(14, 9)))
	t.set_stylebox("pressed", "Button", flat(Palette.ACCENT_DEEP, Palette.ACCENT_SOFT, 3, 1, Vector2(14, 9)))
	t.set_stylebox("disabled", "Button", flat(Palette.PANEL, Palette.LINE_SOFT, 3, 1, Vector2(14, 9)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# --- Panel / PanelContainer ------------------------------------------------------
	var panel := flat(Color(Palette.PANEL, 0.96), Palette.PANEL_EDGE, 4, 1, Vector2(14, 14))
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 18
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	# --- Label / RichTextLabel -------------------------------------------------------
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_font_size("font_size", "Label", 16)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_font("normal_font", "RichTextLabel", font("ui"))
	t.set_font("bold_font", "RichTextLabel", font("bold"))
	t.set_font("italics_font", "RichTextLabel", font("ui"))
	t.set_font("bold_italics_font", "RichTextLabel", font("bold"))
	t.set_font("mono_font", "RichTextLabel", font("mono"))
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

	# --- ScrollContainer / scrollbars -------------------------------------------------
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := flat(Palette.LINE_STRONG, Color(0, 0, 0, 0), 2, 0, Vector2(0, 0))
	var track := flat(Color(Palette.GROUND_DEEP, 0.7), Color(0, 0, 0, 0), 2, 0, Vector2(2, 2))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.ACCENT_DEEP, Color(0, 0, 0, 0), 2, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.ACCENT, Color(0, 0, 0, 0), 2, 0, Vector2(0, 0)))

	# --- ProgressBar: the clock draining ----------------------------------------------
	t.set_stylebox("background", "ProgressBar", flat(Palette.GROUND_DEEP, Palette.PANEL_EDGE, 2, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.ACCENT, Color(0, 0, 0, 0), 2, 0, Vector2(0, 0)))

	# --- Tooltip -----------------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", flat(Palette.PANEL_TOP, Palette.GOLD, 3))
	t.set_color("font_color", "TooltipLabel", Palette.GOLD_PALE)

	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 10)

	# --- named variations the scenes use ------------------------------------------------
	# Primary: signal cyan — the live channel's verdict, the one thing to press.
	_variation(t, "Primary", "Button")
	t.set_stylebox("normal", "Primary", flat(Color(Palette.ACCENT, 0.16), Palette.ACCENT, 3, 1, Vector2(18, 13)))
	t.set_stylebox("hover", "Primary", glow(flat(Color(Palette.ACCENT, 0.3), Palette.ACCENT_SOFT, 3, 1, Vector2(18, 13)), Palette.ACCENT, 14, 0.45))
	t.set_stylebox("pressed", "Primary", flat(Palette.ACCENT, Palette.ACCENT_SOFT, 3, 1, Vector2(18, 13)))
	t.set_stylebox("disabled", "Primary", flat(Palette.PANEL, Palette.LINE_SOFT, 3, 1, Vector2(18, 13)))
	t.set_color("font_color", "Primary", Palette.ACCENT_SOFT)
	t.set_color("font_hover_color", "Primary", Palette.TEXT)
	t.set_color("font_pressed_color", "Primary", Palette.GROUND)
	t.set_font("font", "Primary", font("display"))
	t.set_font_size("font_size", "Primary", 20)

	# Alarm: the deny/burn side — magenta, the colour of a lie.
	_variation(t, "Alarm", "Primary")
	t.set_stylebox("normal", "Alarm", flat(Color(Palette.HEAT, 0.16), Palette.HEAT, 3, 1, Vector2(18, 13)))
	t.set_stylebox("hover", "Alarm", glow(flat(Color(Palette.HEAT, 0.3), Palette.HEAT_SOFT, 3, 1, Vector2(18, 13)), Palette.HEAT, 14, 0.45))
	t.set_stylebox("pressed", "Alarm", flat(Palette.HEAT, Palette.HEAT_SOFT, 3, 1, Vector2(18, 13)))
	t.set_stylebox("disabled", "Alarm", flat(Palette.PANEL, Palette.LINE_SOFT, 3, 1, Vector2(18, 13)))
	t.set_color("font_color", "Alarm", Palette.HEAT_SOFT)
	t.set_color("font_hover_color", "Alarm", Palette.TEXT)
	t.set_color("font_pressed_color", "Alarm", Palette.GROUND)

	# Amber: the lamp — a secondary action, the interrogate key, anything on paper.
	_variation(t, "Amber", "Button")
	t.set_stylebox("normal", "Amber", flat(Color(Palette.GOLD, 0.1), Palette.GOLD_DEEP, 3, 1, Vector2(16, 11)))
	t.set_stylebox("hover", "Amber", flat(Color(Palette.GOLD, 0.2), Palette.GOLD, 3, 1, Vector2(16, 11)))
	t.set_stylebox("pressed", "Amber", flat(Palette.GOLD_DEEP, Palette.GOLD_PALE, 3, 1, Vector2(16, 11)))
	t.set_color("font_color", "Amber", Palette.GOLD)
	t.set_color("font_hover_color", "Amber", Palette.GOLD_PALE)
	t.set_color("font_pressed_color", "Amber", Palette.GROUND)
	t.set_font("font", "Amber", font("bold"))
	t.set_font_size("font_size", "Amber", 16)

	# Active: a nav tab / language chip that is on.
	_variation(t, "Active", "Button")
	t.set_stylebox("normal", "Active", flat(Color(Palette.ACCENT, 0.24), Palette.ACCENT, 3, 1, Vector2(12, 7)))
	t.set_stylebox("hover", "Active", flat(Color(Palette.ACCENT, 0.32), Palette.ACCENT_SOFT, 3, 1, Vector2(12, 7)))
	t.set_stylebox("pressed", "Active", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 3, 1, Vector2(12, 7)))
	t.set_color("font_color", "Active", Palette.ACCENT_SOFT)
	t.set_color("font_hover_color", "Active", Palette.TEXT)

	# Ghost: a quiet action — BACK, the language chip that is off.
	# Tertiary, but not invisible: on a photographic ground a fully transparent button
	# reads as a caption. A hair of the panel behind it is enough to say "this is a
	# control" without competing with the two above it.
	_variation(t, "Ghost", "Button")
	t.set_stylebox("normal", "Ghost", flat(Color(Palette.PANEL, 0.55), Palette.LINE_STRONG, 3, 1, Vector2(12, 7)))
	t.set_stylebox("hover", "Ghost", flat(Color(Palette.ACCENT, 0.1), Palette.LINE_STRONG, 3, 1, Vector2(12, 7)))
	t.set_stylebox("pressed", "Ghost", flat(Color(0, 0, 0, 0.35), Palette.LINE_STRONG, 3, 1, Vector2(12, 7)))
	t.set_color("font_color", "Ghost", Palette.MUTED)
	t.set_color("font_hover_color", "Ghost", Palette.TEXT)

	# Tag: the small caps label over a value. Condensed semibold, blue-steel, tracked out.
	_variation(t, "Tag", "Label")
	t.set_font("font", "Tag", font("bold"))
	t.set_font_size("font_size", "Tag", 11)
	t.set_color("font_color", "Tag", Palette.MUTED)

	# Value: a fact at body size, bold.
	_variation(t, "Value", "Label")
	t.set_font("font", "Value", font("bold"))
	t.set_font_size("font_size", "Value", 16)

	# Read: an instrument readout — monospace, phosphor. The codebook, the grid, the clock.
	_variation(t, "Read", "Label")
	t.set_font("font", "Read", font("mono"))
	t.set_font_size("font_size", "Read", 16)
	t.set_color("font_color", "Read", Palette.SUCCESS)

	# Big: the number that lands.
	_variation(t, "Big", "Label")
	t.set_font("font", "Big", font("display"))
	t.set_font_size("font_size", "Big", 34)
	t.set_color("font_color", "Big", Palette.GOLD)

	_variation(t, "Title", "Label")
	t.set_font("font", "Title", font("display"))
	t.set_font_size("font_size", "Title", 30)
	t.set_color("font_color", "Title", Palette.TEXT)

	# Say: the voice on the air. Body face at speech size; the emphasis is the colour of
	# the call-sign, applied by the panel, not a second typeface.
	_variation(t, "Say", "RichTextLabel")
	t.set_font("normal_font", "Say", font("ui"))
	t.set_font_size("normal_font_size", "Say", 21)
	t.set_color("default_color", "Say", Palette.TEXT)

	# Card / Glass: a raised instrument panel, and a translucent one over the room.
	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 3, 1, Vector2(14, 12)))
	_variation(t, "Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", flat(Color(Palette.GROUND, 0.82), Color(Palette.PANEL_EDGE, 0.9), 3, 1, Vector2(14, 12)))
	# Paper: the codebook card under the lamp — the one warm surface in the build.
	_variation(t, "Paper", "PanelContainer")
	var paper := flat(Color(Palette.PAPER, 0.93), Color(Palette.GOLD_DEEP, 0.7), 2, 1, Vector2(14, 10))
	paper.shadow_color = Color(0, 0, 0, 0.4)
	paper.shadow_size = 10
	t.set_stylebox("panel", "Paper", paper)

	_cache = t
	return t


## Style variants used across screens, by the sibling's names.
static func style_button(b: Button, variant: String) -> void:
	match variant:
		"primary": b.theme_type_variation = "Primary"
		"alarm": b.theme_type_variation = "Alarm"
		"amber": b.theme_type_variation = "Amber"
		"active": b.theme_type_variation = "Active"
		"quiet": b.theme_type_variation = "Ghost"


static func mono_label(text: String, size: int = 13, color: Color = Palette.SUCCESS) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("mono"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func serif_label(text: String, size: int = 16, color: Color = Palette.TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold" if bold else "ui"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func display_label(text: String, size: int = 30, color: Color = Palette.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("display"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

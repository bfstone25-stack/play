## StudioTheme — the one Theme for FOLD, built in code so it lives in git as text and so
## it keeps the same API as play/overtime-idle-godot/scripts/studio_theme.gd:
## `StudioTheme.build()`, `font(which)`, `flat()`, `glow()`, the named variations
## ("Primary", "Amber", "Ghost", "Tag", "Value", "Big", "Title", "Say", "Paper", "Glass",
## "Card"). A scene written for either title works against either file. No default Godot
## grey anywhere.
##
## Type is this title's own. The adult forks use Lilita One — a poster face, loud, right
## for a gacha counter and wrong for a board game about folding paper. FOLD's display face
## is **Marcellus**: a Roman-capital serif with a chiselled stem and a wide letterfit,
## which is what the logotype and the level names are set in. Body stays Nunito, because
## it is the studio's UI face and a HUD is a HUD.
##
##   display  Marcellus                  logotype, level names, the number on a piece
##   ui/bold  Nunito 600 / 700           buttons, HUD, labels
##   italic   Playfair Display Italic    the coach's line at the end of a level, only that
##
## Every face carries a Noto Sans CJK subset as a fallback (tools/subset_cjk.py), because
## the web export has no system font and half this game's text is Chinese. Without the
## fallback the zh build renders tofu, silently — the kind of failure the memory note
## `verification-that-lies` is about, so tests/run_tests.gd asserts the fallback is
## actually attached and that a Chinese glyph measures non-zero.
class_name StudioTheme

const FONT_DISPLAY := "res://assets/fonts/Marcellus-Regular.ttf"
const FONT_UI := "res://assets/fonts/Nunito.ttf"                        # variable, wght 200-1000
const FONT_ITALIC := "res://assets/fonts/PlayfairDisplay-Italic.ttf"    # variable, wght 400-900
const FONT_CJK := "res://assets/fonts/NotoSansCJK-subset.otf"
# the siblings' constant names, resolved onto the three faces above
const FONT_SERIF := FONT_DISPLAY
const FONT_SERIF_BOLD := FONT_DISPLAY
const FONT_SERIF_ITALIC := FONT_ITALIC
const FONT_MONO := FONT_UI

static var _cache: Theme
static var _fonts := {}
static var _files := {}
static var _cjk: FontFile


static func cjk() -> FontFile:
	if _cjk == null and ResourceLoader.exists(FONT_CJK):
		_cjk = load(FONT_CJK)
	return _cjk


static func _file(path: String) -> Font:
	if not _files.has(path):
		var f: FontFile = load(path)
		var fb := cjk()
		if fb != null and f != null:
			var arr := f.fallbacks.duplicate()
			arr.append(fb)
			f.fallbacks = arr
		_files[path] = f
	return _files[path]


static func _weight(path: String, wght: int) -> Font:
	var fv := FontVariation.new()
	fv.base_font = _file(path)
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	# A FontVariation does NOT inherit its base font's fallback chain: the first zh build
	# rendered every button label as tofu while the base face measured the same glyphs
	# fine, because the buttons are all weighted variations. Attach it here as well.
	var fb := cjk()
	if fb != null:
		fv.fallbacks = [fb]
	return fv


## "display" | "ui" (600) | "bold" (700) | "black" (800) | "italic" | "serif" | "mono".
static func font(which: String) -> Font:
	if _fonts.has(which):
		return _fonts[which]
	var f: Font
	match which:
		"display", "serif": f = _file(FONT_DISPLAY)
		"bold", "mono": f = _weight(FONT_UI, 700)
		"black": f = _weight(FONT_UI, 800)
		"italic": f = _weight(FONT_ITALIC, 500)
		_: f = _weight(FONT_UI, 600)
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


## The same box with a glow: a soft shadow in the accent colour, drawn all round. Allowed
## on the crease, the primary button and a lit piece. Never on body text.
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
	t.default_font_size = 15

	# --- Button: panel on ground, gold edge when hovered, gold when pressed -------------
	t.set_font("font", "Button", font("bold"))
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.GOLD_PALE)
	t.set_color("font_pressed_color", "Button", Palette.GROUND)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("font_focus_color", "Button", Palette.GOLD_PALE)
	t.set_stylebox("normal", "Button", flat(Palette.PANEL_RAISED, Palette.LINE_STRONG, 10, 1, Vector2(14, 9)))
	t.set_stylebox("hover", "Button", flat(Palette.PANEL_TOP, Palette.ACCENT, 10, 1, Vector2(14, 9)))
	t.set_stylebox("pressed", "Button", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 10, 1, Vector2(14, 9)))
	t.set_stylebox("disabled", "Button", flat(Palette.PANEL, Palette.LINE_SOFT, 10, 1, Vector2(14, 9)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# --- Panel / PanelContainer ---------------------------------------------------------
	var panel := flat(Color(Palette.PANEL, 0.96), Palette.PANEL_EDGE, 14, 1, Vector2(16, 16))
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 22
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	# --- Label / RichTextLabel -----------------------------------------------------------
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_font_size("font_size", "Label", 15)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_font("normal_font", "RichTextLabel", font("ui"))
	t.set_font("bold_font", "RichTextLabel", font("bold"))
	t.set_font("italics_font", "RichTextLabel", font("italic"))
	t.set_font("bold_italics_font", "RichTextLabel", font("italic"))
	t.set_font("mono_font", "RichTextLabel", font("bold"))
	t.set_font_size("normal_font_size", "RichTextLabel", 15)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

	# --- ScrollContainer / scrollbars ----------------------------------------------------
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := flat(Palette.LINE_STRONG, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0))
	var track := flat(Color(Palette.GROUND_DEEP, 0.6), Color(0, 0, 0, 0), 4, 0, Vector2(2, 2))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.ACCENT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.ACCENT_SOFT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))

	# --- ProgressBar ---------------------------------------------------------------------
	t.set_stylebox("background", "ProgressBar", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 5, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.ACCENT, Color(0, 0, 0, 0), 5, 0, Vector2(0, 0)))

	# --- Tooltip -------------------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", flat(Palette.PANEL_TOP, Palette.GOLD, 8))
	t.set_color("font_color", "TooltipLabel", Palette.GOLD_PALE)

	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 10)

	# --- named variations ----------------------------------------------------------------
	# Primary: gold — the one thing on the screen to press.
	_variation(t, "Primary", "Button")
	t.set_stylebox("normal", "Primary", flat(Palette.ACCENT, Palette.GOLD_PALE, 12, 1, Vector2(20, 12)))
	t.set_stylebox("hover", "Primary", glow(flat(Palette.ACCENT_SOFT, Palette.GOLD_PALE, 12, 1, Vector2(20, 12)), Palette.ACCENT, 16, 0.55))
	t.set_stylebox("pressed", "Primary", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 12, 1, Vector2(20, 12)))
	t.set_stylebox("disabled", "Primary", flat(Palette.PANEL_RAISED, Palette.LINE_SOFT, 12, 1, Vector2(20, 12)))
	t.set_color("font_color", "Primary", Palette.GROUND)
	t.set_color("font_hover_color", "Primary", Palette.GROUND)
	t.set_color("font_pressed_color", "Primary", Palette.GOLD_PALE)
	t.set_font("font", "Primary", font("display"))
	t.set_font_size("font_size", "Primary", 19)

	# Amber: gold edge on dark — a secondary action.
	_variation(t, "Amber", "Button")
	t.set_stylebox("normal", "Amber", flat(Color(Palette.PANEL_TOP, 0.85), Palette.GOLD, 10, 1, Vector2(16, 10)))
	t.set_stylebox("hover", "Amber", glow(flat(Palette.PANEL_TOP, Palette.GOLD_PALE, 10, 1, Vector2(16, 10)), Palette.ACCENT, 12, 0.4))
	t.set_stylebox("pressed", "Amber", flat(Palette.GOLD_DEEP, Palette.GOLD_PALE, 10, 1, Vector2(16, 10)))
	t.set_color("font_color", "Amber", Palette.GOLD)
	t.set_color("font_hover_color", "Amber", Palette.GOLD_PALE)
	t.set_color("font_pressed_color", "Amber", Palette.GROUND)
	t.set_font("font", "Amber", font("display"))
	t.set_font_size("font_size", "Amber", 16)

	# Active: a picker chip that is on.
	_variation(t, "Active", "Button")
	t.set_stylebox("normal", "Active", flat(Palette.ACCENT, Palette.GOLD_PALE, 8, 1, Vector2(10, 7)))
	t.set_stylebox("hover", "Active", flat(Palette.ACCENT_SOFT, Palette.GOLD_PALE, 8, 1, Vector2(10, 7)))
	t.set_color("font_color", "Active", Palette.GROUND)
	t.set_color("font_hover_color", "Active", Palette.GROUND)

	_variation(t, "Ghost", "Button")
	t.set_stylebox("normal", "Ghost", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0, Vector2(10, 7)))
	t.set_stylebox("hover", "Ghost", flat(Color(Palette.ACCENT, 0.12), Color(0, 0, 0, 0), 8, 0, Vector2(10, 7)))
	t.set_stylebox("pressed", "Ghost", flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 8, 0, Vector2(10, 7)))
	t.set_color("font_color", "Ghost", Palette.MUTED)
	t.set_color("font_hover_color", "Ghost", Palette.GOLD)

	# Tag: the small caps label over a value.
	_variation(t, "Tag", "Label")
	t.set_font("font", "Tag", font("bold"))
	t.set_font_size("font_size", "Tag", 11)
	t.set_color("font_color", "Tag", Palette.MUTED)

	_variation(t, "Value", "Label")
	t.set_font("font", "Value", font("bold"))
	t.set_font_size("font_size", "Value", 15)

	# Big: the number that lands. Display face, gold.
	_variation(t, "Big", "Label")
	t.set_font("font", "Big", font("display"))
	t.set_font_size("font_size", "Big", 32)
	t.set_color("font_color", "Big", Palette.GOLD)

	_variation(t, "Title", "Label")
	t.set_font("font", "Title", font("display"))
	t.set_font_size("font_size", "Title", 28)
	t.set_color("font_color", "Title", Palette.TEXT)

	# Say: the coach's line. Playfair italic, on paper.
	_variation(t, "Say", "RichTextLabel")
	t.set_font("normal_font", "Say", font("italic"))
	t.set_font("italics_font", "Say", font("italic"))
	t.set_font("bold_font", "Say", font("italic"))
	t.set_font_size("normal_font_size", "Say", 17)
	t.set_color("default_color", "Say", Palette.INK)

	_variation(t, "Paper", "PanelContainer")
	var paper := flat(Color(Palette.PAPER, Palette.PAPER_ALPHA), Color(Palette.GOLD, 0.5), 10, 1, Vector2(16, 13))
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_size = 14
	t.set_stylebox("panel", "Paper", paper)

	_variation(t, "Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", flat(Color(Palette.GROUND, 0.82), Color(Palette.PANEL_EDGE, 0.9), 12, 1, Vector2(14, 14)))

	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 12, 1, Vector2(14, 14)))

	_cache = t
	return t


static func style_button(b: Button, variant: String) -> void:
	match variant:
		"primary": b.theme_type_variation = "Primary"
		"amber": b.theme_type_variation = "Amber"
		"active": b.theme_type_variation = "Active"
		"quiet": b.theme_type_variation = "Ghost"


static func mono_label(text: String, size: int = 11, color: Color = Palette.MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func serif_label(text: String, size: int = 15, color: Color = Palette.TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold" if bold else "ui"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func display_label(text: String, size: int = 28, color: Color = Palette.GOLD) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("display"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func say_label(size: int = 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.theme_type_variation = "Say"
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	return r

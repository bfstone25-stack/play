## StudioTheme — the one Theme for FOLD, built in code so it lives in git as text and so
## it keeps the same API as play/overtime-idle-godot/scripts/studio_theme.gd:
## `StudioTheme.build()`, `font(which)`, `flat()`, `glow()`, the named variations
## ("Primary", "Amber", "Ghost", "Tag", "Value", "Big", "Title", "Say", "Paper", "Glass",
## "Card"). A scene written for either title works against either file. No default Godot
## grey anywhere.
##
## Type is this title's own, and on 2026-09-19 it changed hands. The file used to argue
## that Lilita One was "a poster face, loud, right for a gacha counter and wrong for a
## board game about folding paper", and set FOLD in Marcellus — a Roman-capital serif with
## a chiselled stem. That was a good argument about a game we are no longer making. FOLD is
## all-ages and sits on the casual shelf; a chiselled Roman capital is the voice of a
## museum label. **Lilita One** is the display face now, the same one the reference build
## (play/rebound-tycoon-godot) uses, because loud is the correct register here.
##
## Playfair italic goes with Marcellus: there is no coach's aside in a toy box, and the
## one caller of it now takes the UI face. Both files stay in assets/fonts with their OFL
## notices, unreferenced, rather than being deleted in the same commit that repaints.
##
##   display  Lilita One                 logotype lockups, level names, the big number
##   ui/bold  Nunito 600 / 700           buttons, HUD, labels
##   italic   Nunito 700                 kept as a name so callers do not break
##
## Every face carries a Noto Sans CJK subset as a fallback (tools/subset_cjk.py), because
## the web export has no system font and half this game's text is Chinese. Without the
## fallback the zh build renders tofu, silently — the kind of failure the memory note
## `verification-that-lies` is about, so tests/run_tests.gd asserts the fallback is
## actually attached and that a Chinese glyph measures non-zero.
class_name StudioTheme

const FONT_DISPLAY := "res://assets/fonts/LilitaOne-Regular.ttf"
const FONT_UI := "res://assets/fonts/Nunito.ttf"                        # variable, wght 200-1000
const FONT_ITALIC := "res://assets/fonts/PlayfairDisplay-Italic.ttf"    # variable, wght 400-900
const FONT_CJK := "res://assets/fonts/NotoSansCJK-subset.otf"
# the siblings' constant names, resolved onto the three faces above
const FONT_SERIF := FONT_UI
const FONT_SERIF_BOLD := FONT_UI
const FONT_SERIF_ITALIC := FONT_UI
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
		"italic": f = _weight(FONT_UI, 700)
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


## A warm drop shadow under a box, offset down: what makes a pill on a sunny page read as
## a physical thing you can press. Black shadows are for dark rooms; on cream they read as
## dirt, which is half of why the first bright pass still looked heavy.
static func drop(s: StyleBoxFlat, size: int = 8, alpha: float = 0.30) -> StyleBoxFlat:
	s.shadow_color = Color(Palette.WALL_EDGE, alpha)
	s.shadow_size = size
	s.shadow_offset = Vector2(0, maxi(2, size / 3))
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
	t.set_color("font_hover_color", "Button", Palette.ACCENT_DEEP)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Palette.FAINT)
	t.set_color("font_focus_color", "Button", Palette.ACCENT_DEEP)
	# Radius 18 rather than 10: on the casual shelf a button is a pill, and the rounder it
	# is the more tappable it reads. `drop` is what makes it a physical object instead of a
	# coloured rectangle — a warm shadow, never a black one, on a sunny ground.
	t.set_stylebox("normal", "Button", drop(flat(Palette.PANEL, Palette.LINE_STRONG, 18, 2, Vector2(16, 11))))
	t.set_stylebox("hover", "Button", drop(flat(Palette.PANEL_TOP, Palette.ACCENT, 18, 2, Vector2(16, 11)), 10))
	t.set_stylebox("pressed", "Button", flat(Palette.GOLD_PALE, Palette.ACCENT_DEEP, 18, 2, Vector2(16, 11)))
	t.set_stylebox("disabled", "Button", flat(Palette.PAPER_GRAY, Palette.LINE_SOFT, 18, 2, Vector2(16, 11)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# --- Panel / PanelContainer ---------------------------------------------------------
	var panel := flat(Color(Palette.PANEL, 0.98), Palette.PANEL_EDGE, 20, 2, Vector2(18, 18))
	panel.shadow_color = Color(Palette.WALL_EDGE, 0.28)
	panel.shadow_size = 18
	panel.shadow_offset = Vector2(0, 5)
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
	var track := flat(Color(Palette.GROUND_DEEP, 0.7), Color(0, 0, 0, 0), 4, 0, Vector2(2, 2))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.ACCENT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.ACCENT_SOFT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))

	# --- ProgressBar ---------------------------------------------------------------------
	t.set_stylebox("background", "ProgressBar", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 5, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.ACCENT, Color(0, 0, 0, 0), 5, 0, Vector2(0, 0)))

	# --- Tooltip -------------------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", flat(Palette.PANEL_TOP, Palette.ACCENT, 12))
	t.set_color("font_color", "TooltipLabel", Palette.TEXT)

	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("separation", "VBoxContainer", 10)

	# --- named variations ----------------------------------------------------------------
	# Primary: gold — the one thing on the screen to press.
	_variation(t, "Primary", "Button")
	t.set_stylebox("normal", "Primary", drop(flat(Palette.ACCENT, Palette.PAPER, 22, 3, Vector2(24, 15)), 14))
	t.set_stylebox("hover", "Primary", drop(glow(flat(Palette.ACCENT_SOFT, Palette.PAPER, 22, 3, Vector2(24, 15)), Palette.GOLD, 20, 0.7), 18))
	t.set_stylebox("pressed", "Primary", flat(Palette.ACCENT_DEEP, Palette.PAPER, 22, 3, Vector2(24, 15)))
	t.set_stylebox("disabled", "Primary", flat(Palette.PAPER_GRAY, Palette.LINE_SOFT, 22, 3, Vector2(24, 15)))
	# Ink on tangerine measures 6.37:1; white measures 2.59 and was the first thing tried.
	t.set_color("font_color", "Primary", Palette.INK)
	t.set_color("font_hover_color", "Primary", Palette.INK)
	t.set_color("font_pressed_color", "Primary", Palette.INK)
	t.set_font("font", "Primary", font("display"))
	t.set_font_size("font_size", "Primary", 24)

	# Amber: gold edge on dark — a secondary action.
	_variation(t, "Amber", "Button")
	t.set_stylebox("normal", "Amber", drop(flat(Palette.GOLD, Palette.PAPER, 18, 3, Vector2(18, 12)), 10))
	t.set_stylebox("hover", "Amber", drop(glow(flat(Palette.GOLD_PALE, Palette.PAPER, 18, 3, Vector2(18, 12)), Palette.GOLD, 16, 0.6), 14))
	t.set_stylebox("pressed", "Amber", flat(Palette.GOLD_DEEP, Palette.PAPER, 18, 3, Vector2(18, 12)))
	t.set_color("font_color", "Amber", Palette.INK)
	t.set_color("font_hover_color", "Amber", Palette.INK)
	t.set_color("font_pressed_color", "Amber", Palette.INK)
	t.set_font("font", "Amber", font("display"))
	t.set_font_size("font_size", "Amber", 18)

	# Active: a picker chip that is on.
	_variation(t, "Active", "Button")
	t.set_stylebox("normal", "Active", flat(Palette.ACCENT, Palette.PAPER, 14, 2, Vector2(11, 8)))
	t.set_stylebox("hover", "Active", flat(Palette.ACCENT_SOFT, Palette.PAPER, 14, 2, Vector2(11, 8)))
	t.set_color("font_color", "Active", Palette.INK)
	t.set_color("font_hover_color", "Active", Palette.INK)

	_variation(t, "Ghost", "Button")
	# 0.85, not 0.55: over a busy key visual a half-transparent chip had no ground and the
	# language and sound buttons were the least readable things on the title screen.
	t.set_stylebox("normal", "Ghost", flat(Color(Palette.PANEL, 0.85), Palette.PANEL_EDGE, 14, 1, Vector2(12, 9)))
	t.set_stylebox("hover", "Ghost", flat(Color(Palette.ACCENT, 0.22), Color(0, 0, 0, 0), 14, 0, Vector2(12, 9)))
	t.set_stylebox("pressed", "Ghost", flat(Color(Palette.ACCENT, 0.4), Color(0, 0, 0, 0), 14, 0, Vector2(12, 9)))
	t.set_color("font_color", "Ghost", Palette.TEXT)
	t.set_color("font_hover_color", "Ghost", Palette.ACCENT_DEEP)

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
	t.set_font_size("font_size", "Big", 38)
	t.set_color("font_color", "Big", Palette.ACCENT_DEEP)

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
	paper.shadow_color = Color(Palette.WALL_EDGE, 0.28)
	paper.shadow_size = 14
	paper.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "Paper", paper)

	_variation(t, "Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", flat(Color(Palette.PANEL, 0.88), Color(Palette.PANEL_EDGE, 0.9), 18, 2, Vector2(14, 14)))

	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", drop(flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 18, 2, Vector2(14, 14)), 10))

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

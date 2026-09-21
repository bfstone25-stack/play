## StudioTheme — the one Theme for the studio's Godot forks, built in code so it lives in
## git as text and so the sibling titles can call `StudioTheme.build()` and get the same
## buttons, panels and fonts. No default Godot grey anywhere: every control type used in
## the client has its StyleBox set here.
##
## Type, per ops/adult_forks/UI_DIRECTION.md — three OFL faces bundled in assets/fonts/,
## licences beside them, never a system font:
##   display  Lilita One            titles, big numbers, GACHA, counters — the number lands
##   ui/bold  Nunito 600 / 700      buttons, labels, chips, HUD
##   italic   Playfair Display It.  the character's spoken line, and only that
## "serif" and "mono" are kept as names for the sibling's call sites and resolve to Nunito:
## the monospace labels and the Times-like body serif are retired.
class_name StudioTheme

const FONT_DISPLAY := "res://assets/fonts/LilitaOne-Regular.ttf"
const FONT_UI := "res://assets/fonts/Nunito.ttf"                        # variable, wght 200-1000
const FONT_ITALIC := "res://assets/fonts/PlayfairDisplay-Italic.ttf"    # variable, wght 400-900
# the sibling's constant names, resolved onto the three faces above
const FONT_SERIF := FONT_UI
const FONT_SERIF_BOLD := FONT_UI
const FONT_SERIF_ITALIC := FONT_ITALIC
const FONT_MONO := FONT_UI

static var _cache: Theme
static var _fonts := {}
static var _files := {}


static func _file(path: String) -> Font:
	if not _files.has(path):
		var f: FontFile = load(path)
		# The CJK face hangs off the Latin one rather than replacing it, so a mixed line
		# ("ゴールド 120", "家賃 +10%") keeps Lilita/Nunito for its Latin runs and picks up
		# Noto only for the glyphs the Latin face does not have. Set here, once per face,
		# so every `add_theme_font_override("font", Look.font_display)` in the game inherits
		# it without being edited -- see scripts/cjk.gd for why that matters.
		var cjk := Cjk.face()
		if cjk:
			f.fallbacks = [cjk]
		_files[path] = f
	return _files[path]


## Drop every cached face and the built Theme, so the next `font()` / `build()` picks up
## the new language's CJK fallback. These caches are `static var`s, which survive a scene
## reload -- without this, switching to Japanese and reloading would rebuild the Theme out
## of the same Latin-only FontFiles and draw boxes.
static func reset_fonts() -> void:
	_fonts.clear()
	_files.clear()
	_cache = null


static func _weight(path: String, wght: int) -> Font:
	var fv := FontVariation.new()
	fv.base_font = _file(path)
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	# Belt and braces: `fallbacks` is a property of Font, so a FontVariation carries its own
	# list rather than reading the base font's. Setting it on the base alone left the bold
	# and black weights -- i.e. every Tag, Value and Button in the game -- without CJK.
	var cjk := Cjk.face()
	if cjk:
		fv.fallbacks = [cjk]
	return fv


## "display" | "ui" (600) | "bold" (700) | "black" (800) | "italic" | the sibling's
## "serif" (-> ui), "mono" (-> bold).
static func font(which: String) -> Font:
	if _fonts.has(which):
		return _fonts[which]
	var f: Font
	match which:
		"display": f = _file(FONT_DISPLAY)
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


## The same box with a glow: a soft shadow in the accent colour, drawn all round.
## Allowed on rarity frames, the pull button, a lit chain link, a plate unlocking. Never
## on body text.
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

	# --- Button: panel on ground, magenta edge when hovered, magenta when pressed -------
	t.set_font("font", "Button", font("bold"))
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.ACCENT_SOFT)
	t.set_color("font_pressed_color", "Button", Palette.TEXT)
	t.set_color("font_disabled_color", "Button", Palette.DIM)
	t.set_color("font_focus_color", "Button", Palette.ACCENT_SOFT)
	t.set_stylebox("normal", "Button", flat(Palette.PANEL_RAISED, Palette.LINE_STRONG, 8, 1, Vector2(12, 8)))
	t.set_stylebox("hover", "Button", flat(Palette.PANEL_TOP, Palette.ACCENT, 8, 1, Vector2(12, 8)))
	t.set_stylebox("pressed", "Button", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 8, 1, Vector2(12, 8)))
	t.set_stylebox("disabled", "Button", flat(Palette.PANEL, Palette.LINE_SOFT, 8, 1, Vector2(12, 8)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# --- Panel / PanelContainer ----------------------------------------------------------
	var panel := flat(Color(Palette.PANEL, 0.96), Palette.PANEL_EDGE, 12, 1, Vector2(14, 14))
	panel.shadow_color = Color(0, 0, 0, 0.5)
	panel.shadow_size = 20
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

	# --- LineEdit ------------------------------------------------------------------------
	t.set_font("font", "LineEdit", font("ui"))
	t.set_font_size("font_size", "LineEdit", 17)
	t.set_color("font_color", "LineEdit", Palette.TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Palette.DIM)
	t.set_color("caret_color", "LineEdit", Palette.ACCENT)
	t.set_color("selection_color", "LineEdit", Color(Palette.ACCENT, 0.35))
	t.set_stylebox("normal", "LineEdit", flat(Palette.PANEL, Palette.LINE_STRONG, 20, 1, Vector2(16, 9)))
	t.set_stylebox("focus", "LineEdit", flat(Palette.PANEL, Palette.ACCENT, 20, 2, Vector2(16, 9)))
	t.set_stylebox("read_only", "LineEdit", flat(Palette.PANEL, Palette.LINE, 20, 1, Vector2(16, 9)))

	# --- ScrollContainer / scrollbars ----------------------------------------------------
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grab := flat(Palette.LINE_STRONG, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0))
	var track := flat(Color(Palette.GROUND_DEEP, 0.6), Color(0, 0, 0, 0), 4, 0, Vector2(2, 2))
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, flat(Palette.ACCENT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))
		t.set_stylebox("grabber_pressed", sb, flat(Palette.ACCENT_SOFT, Color(0, 0, 0, 0), 4, 0, Vector2(0, 0)))

	# --- ProgressBar: heat ---------------------------------------------------------------
	t.set_stylebox("background", "ProgressBar", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 5, 1, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", flat(Palette.HEAT, Color(0, 0, 0, 0), 5, 0, Vector2(0, 0)))

	# --- Tooltip -------------------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", flat(Palette.PANEL_TOP, Palette.GOLD, 8))
	t.set_color("font_color", "TooltipLabel", Palette.GOLD_PALE)

	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 8)

	# --- named variations the scenes use ------------------------------------------------
	# Primary: magenta — the one thing on the screen to press.
	_variation(t, "Primary", "Button")
	t.set_stylebox("normal", "Primary", flat(Palette.ACCENT, Palette.ACCENT_SOFT, 10, 1, Vector2(14, 10)))
	t.set_stylebox("hover", "Primary", glow(flat(Palette.ACCENT_SOFT, Palette.GOLD_PALE, 10, 1, Vector2(14, 10)), Palette.ACCENT, 12, 0.5))
	t.set_stylebox("pressed", "Primary", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 10, 1, Vector2(14, 10)))
	t.set_stylebox("disabled", "Primary", flat(Palette.PANEL_RAISED, Palette.LINE_SOFT, 10, 1, Vector2(14, 10)))
	t.set_color("font_color", "Primary", Palette.TEXT)
	t.set_color("font_hover_color", "Primary", Palette.TEXT)
	t.set_color("font_pressed_color", "Primary", Palette.TEXT)
	t.set_font("font", "Primary", font("display"))
	t.set_font_size("font_size", "Primary", 17)

	# Pull: the gacha button — magenta, and it glows.
	_variation(t, "Pull", "Primary")
	t.set_stylebox("normal", "Pull", glow(flat(Palette.ACCENT, Palette.ACCENT_SOFT, 12, 1, Vector2(18, 12)), Palette.ACCENT, 16, 0.6))
	t.set_stylebox("hover", "Pull", glow(flat(Palette.ACCENT_SOFT, Palette.GOLD_PALE, 12, 1, Vector2(18, 12)), Palette.ACCENT, 22, 0.8))
	t.set_stylebox("pressed", "Pull", glow(flat(Palette.ACCENT_DEEP, Palette.GOLD, 12, 1, Vector2(18, 12)), Palette.GOLD, 16, 0.6))
	t.set_font_size("font_size", "Pull", 19)

	# Amber: gold edge on dark — a secondary action, a lit thing.
	_variation(t, "Amber", "Button")
	t.set_stylebox("normal", "Amber", flat(Palette.PANEL_TOP, Palette.GOLD, 8, 1, Vector2(12, 8)))
	t.set_stylebox("hover", "Amber", flat(Palette.PANEL_TOP, Palette.GOLD_PALE, 8, 1, Vector2(12, 8)))
	t.set_stylebox("pressed", "Amber", flat(Palette.GOLD_DEEP, Palette.GOLD_PALE, 8, 1, Vector2(12, 8)))
	t.set_color("font_color", "Amber", Palette.GOLD)
	t.set_color("font_hover_color", "Amber", Palette.GOLD_PALE)
	t.set_color("font_pressed_color", "Amber", Palette.GROUND)

	# Active: a nav tab that is on — magenta.
	_variation(t, "Active", "Button")
	t.set_stylebox("normal", "Active", flat(Color(Palette.ACCENT, 0.22), Palette.ACCENT, 8, 1, Vector2(12, 8)))
	t.set_stylebox("hover", "Active", flat(Color(Palette.ACCENT, 0.3), Palette.ACCENT_SOFT, 8, 1, Vector2(12, 8)))
	t.set_stylebox("pressed", "Active", flat(Palette.ACCENT_DEEP, Palette.ACCENT, 8, 1, Vector2(12, 8)))
	t.set_color("font_color", "Active", Palette.ACCENT_SOFT)
	t.set_color("font_hover_color", "Active", Palette.TEXT)

	# Free: green — costs nothing.
	_variation(t, "Free", "Button")
	t.set_stylebox("normal", "Free", flat(Palette.GREEN_DEEP, Palette.SUCCESS, 8, 1, Vector2(12, 8)))
	t.set_stylebox("hover", "Free", flat(Palette.SUCCESS, Palette.SUCCESS, 8, 1, Vector2(12, 8)))
	t.set_color("font_color", "Free", Palette.GROUND)
	t.set_color("font_hover_color", "Free", Palette.GROUND)

	_variation(t, "Ghost", "Button")
	t.set_stylebox("normal", "Ghost", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0, Vector2(8, 6)))
	t.set_stylebox("hover", "Ghost", flat(Color(Palette.ACCENT, 0.12), Color(0, 0, 0, 0), 8, 0, Vector2(8, 6)))
	t.set_stylebox("pressed", "Ghost", flat(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 8, 0, Vector2(8, 6)))
	t.set_color("font_color", "Ghost", Palette.MUTED)

	# Tag: the small caps label over a value. Nunito bold, mauve.
	_variation(t, "Tag", "Label")
	t.set_font("font", "Tag", font("bold"))
	t.set_font_size("font_size", "Tag", 11)
	t.set_color("font_color", "Tag", Palette.MUTED)

	# Value: a number or a short fact at body size, bold.
	_variation(t, "Value", "Label")
	t.set_font("font", "Value", font("bold"))
	t.set_font_size("font_size", "Value", 15)

	# Big: the number that lands. Display face, gold.
	_variation(t, "Big", "Label")
	t.set_font("font", "Big", font("display"))
	t.set_font_size("font_size", "Big", 30)
	t.set_color("font_color", "Big", Palette.GOLD)

	_variation(t, "Title", "Label")
	t.set_font("font", "Title", font("display"))
	t.set_font_size("font_size", "Title", 28)
	t.set_color("font_color", "Title", Palette.TEXT)

	# Say: her line. The one serif, italic, on paper.
	_variation(t, "Say", "RichTextLabel")
	t.set_font("normal_font", "Say", font("italic"))
	t.set_font("italics_font", "Say", font("italic"))
	t.set_font("bold_font", "Say", font("italic"))
	t.set_font_size("normal_font_size", "Say", 17)
	t.set_color("default_color", "Say", Palette.INK)

	# Paper: the speech panel — warm paper at 92%.
	_variation(t, "Paper", "PanelContainer")
	var paper := flat(Color(Palette.PAPER, Palette.PAPER_ALPHA), Color(Palette.GOLD, 0.5), 12, 1, Vector2(14, 12))
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_size = 12
	t.set_stylebox("panel", "Paper", paper)

	# Glass: a translucent panel over the room.
	_variation(t, "Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", flat(Color(Palette.GROUND, 0.8), Color(Palette.PANEL_EDGE, 0.9), 10, 1, Vector2(12, 12)))

	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", flat(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 10, 1, Vector2(12, 12)))

	_cache = t
	return t


## Style variants used across screens. Names are what the sibling title should reuse;
## the same looks are also Theme type variations ("Primary", "Free", "Active", "Ghost",
## "Pull") for scenes that set theme_type_variation instead.
static func style_button(b: Button, variant: String) -> void:
	match variant:
		"primary": b.theme_type_variation = "Primary"
		"pull": b.theme_type_variation = "Pull"
		"free": b.theme_type_variation = "Free"
		"active": b.theme_type_variation = "Active"
		"quiet": b.theme_type_variation = "Ghost"


## Kept for the sibling's call sites: a small bold label. Nothing monospace is left.
static func mono_label(text: String, size: int = 11, color: Color = Palette.MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Body label in the UI face (the sibling calls it serif; there is no serif in the UI).
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


## A spoken line, in her voice: Playfair Italic on nothing (put it on a "Paper" panel).
static func say_label(size: int = 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.theme_type_variation = "Say"
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	return r


# ---- the stub ----------------------------------------------------------------------------
#
# Studio rule 4: a button's shape comes from the game's world. This game is a landlord
# collecting rent, so its control is the RENT STUB -- the torn ticket with the perforated
# edge that a tenant gets back across the desk. `shared/godot/shaped_button.gd` earmarks
# Shape.TICKET for exactly this title.
#
# Every button in the game goes through one of two places (Overlay.button() for the panels,
# _build_hud/_build_tray for the room), and both now call this, so there is no second
# treatment to drift away from the first.
#
# The tint carries the meaning the Theme variation used to carry, because a shaped button
# draws its own fill and a StyleBox it no longer uses cannot colour it:
#
#   primary / pull  ACCENT       the one thing to press
#   amber           GOLD         a lit secondary
#   free            SUCCESS      earned, confirmed, costs nothing
#   ghost / quiet   PANEL_TOP    a stub printed on the panel it sits on
#   (default)       GOLD_DEEP    a plain stub
const STUB_TINT := {
	"Primary": Palette.ACCENT, "Pull": Palette.ACCENT, "Amber": Palette.GOLD,
	"Free": Palette.SUCCESS, "Active": Palette.HEAT, "Ghost": Palette.PANEL_TOP,
}


## Turn a plain Button's job into a rent stub. Returns a ShapedButton carrying the same
## text, the same tooltip and nothing else -- the caller connects `pressed` itself, so this
## can be used both on a button being built and on one already wired.
## `compact` skips ShapedButton's 220x56 floor, and every caller that sets its own
## custom_minimum_size MUST pass it. That floor is sized for a title screen's one big
## verb; applied to a button a layout has already measured, it silently makes the button
## wider than the panel holding it, and a Godot container does not clip -- it draws the
## overflow over whatever is next to it. On this game's 1280x720 room that shipped as
## three separate bugs from one cause: the HUD tab strip ran off the right edge of the
## screen (DAILY and PLATES were not on screen at all, so nothing could open them), the
## tray's REROLL and COMMIT crossed into Mirei's portrait column and sat on top of her
## speech panel, and the floor strip overhung the FLOORS panel it lives in. All three were
## in every screenshot taken of this build and none of them is visible in the code.
static func stub(txt: String, variation: String = "", compact: bool = false) -> ShapedButton:
	var b := ShapedButton.new()
	b.compact = compact
	b.shape = ShapedButton.Shape.TICKET
	b.tint = STUB_TINT.get(variation, Palette.GOLD_DEEP)
	# Ink is the paper-dark on every fill except Ghost, whose fill IS the panel: dark ink
	# on a dark panel is an unreadable button, and an unreadable button is the studio's
	# most-repeated bug (three dials with no words on them, and counting).
	b.ink = Palette.GOLD_PALE if variation == "Ghost" else Palette.INK
	b.label = txt
	b.text = ""
	b.add_theme_font_override("font", font("display"))
	b.add_theme_font_size_override("font_size", 16)
	return b

class_name NRSkin
extends RefCounted
## Builds the Theme from the game's own UI art (game.json "ui") and fonts ("fonts").
## Every panel and button is a StyleBoxTexture over a rendered image -- no flat boxes.
## The CJK font is attached as a fallback and the FontFiles are held in a static array:
## a load()ed FontFile with nobody holding it drops its fallbacks on the web export
## (memory: godot-web-font-fallback).

static var _held: Array = []
static var _theme: Theme
static var fonts: Dictionary = {}


static func ui(key: String) -> String:
	return RPG.game.get("ui", {}).get(key, "")


static func box(key: String, margin: float = 14.0, content: float = -1.0) -> StyleBox:
	var p := ui(key)
	if p == "" or not ResourceLoader.exists(p):
		return StyleBoxEmpty.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(p)
	_held.append(sb.texture)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	var c := margin if content < 0 else content
	sb.content_margin_left = c + 6
	sb.content_margin_right = c + 6
	sb.content_margin_top = c * 0.6
	sb.content_margin_bottom = c * 0.6
	return sb


static func _font(key: String) -> Font:
	if fonts.has(key):
		return fonts[key]
	var p: String = RPG.game.get("fonts", {}).get(key, "")
	if p == "" or not ResourceLoader.exists(p):
		return null
	var f: FontFile = load(p)
	_held.append(f)
	fonts[key] = f
	if not key.begins_with("cjk"):
		f.fallbacks = _fallbacks(Loc.lang if Loc else "en")
	return f


## CJK fallbacks: "cjk" (Japanese), optional "cjk_sc" (Simplified Chinese) and "cjk_ko" (Hangul).
## The current language's face goes first so shared ideographs take that language's forms.
static var _cjk: Dictionary = {}


static func _cjk_font(key: String) -> FontFile:
	if _cjk.has(key):
		return _cjk[key]
	# cjk_sc / cjk_ko default to the subsets tools/cjk_fonts.py writes into every title
	var dflt: String = {"cjk_sc": "res://assets/fonts/nr_cjk_sc.otf", "cjk_ko": "res://assets/fonts/nr_cjk_kr.otf"}.get(key, "")
	var p: String = RPG.game.get("fonts", {}).get(key, dflt)
	var f: FontFile = null
	if p != "" and ResourceLoader.exists(p):
		f = load(p)
		_held.append(f)
	_cjk[key] = f
	return f


static func _fallbacks(lang: String) -> Array:
	var order := ["cjk", "cjk_sc", "cjk_ko"]
	if lang == "zh":
		order = ["cjk_sc", "cjk", "cjk_ko"]
	elif lang == "ko":
		order = ["cjk_ko", "cjk", "cjk_sc"]
	var out: Array = []
	for k in order:
		var c := _cjk_font(k)
		if c != null:
			out.append(c)
	return out


static func apply_lang(lang: String) -> void:
	var fb := _fallbacks(lang)
	for k in fonts.keys():
		var f = fonts[k]
		if f is FontFile and not str(k).begins_with("cjk"):
			f.fallbacks = fb


static func font(key: String) -> Font:
	var f := _font(key)
	return f if f != null else ThemeDB.fallback_font


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	var body := font("body")
	t.default_font = body
	t.default_font_size = 24
	var ink := Color(0.93, 0.88, 0.80)
	var gold := Color(0.87, 0.74, 0.52)
	for cls in ["Label", "Button", "RichTextLabel", "CheckBox", "OptionButton"]:
		t.set_color("font_color", cls, ink)
	t.set_color("default_color", "RichTextLabel", ink)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_pressed_color", "Button", gold)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.48))
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("normal", "Button", box("choice_idle", 8))
	t.set_stylebox("hover", "Button", box("choice_hover", 8))
	t.set_stylebox("pressed", "Button", box("choice_hover", 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	var dis := box("choice_idle", 8)
	if dis is StyleBoxTexture:
		dis.modulate_color = Color(1, 1, 1, 0.45)
	t.set_stylebox("disabled", "Button", dis)
	t.set_stylebox("panel", "PanelContainer", box("panel", 20))
	t.set_stylebox("panel", "Panel", box("panel", 20))
	t.set_font_size("font_size", "Button", 22)
	_theme = t
	return t


## A heading label in the display face.
static func heading(text: String, size: int = 40) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("display"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.87, 0.74, 0.52))
	return l


static func label(text: String, size: int = 22, color: Color = Color(0.93, 0.88, 0.80)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, cb: Callable, size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func():
		Sound.play_sfx("click")
		cb.call())
	return b


## A textured meter: the game's "bar_under" art with "bar_fill" art clipped to the value.
static func meter(fill_key: String = "bar_fill") -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	var u := ui("bar_under")
	var f := ui(fill_key)
	if u != "" and ResourceLoader.exists(u):
		bar.texture_under = load(u)
	if f != "" and ResourceLoader.exists(f):
		bar.texture_progress = load(f)
	bar.nine_patch_stretch = true
	bar.stretch_margin_left = 4
	bar.stretch_margin_right = 4
	bar.stretch_margin_top = 4
	bar.stretch_margin_bottom = 4
	bar.custom_minimum_size = Vector2(220, 18)
	return bar


## A soft light texture for Light2D (a light, not something drawn on screen).
static func light_texture() -> Texture2D:
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 512
	g.height = 512
	_held.append(g)
	return g

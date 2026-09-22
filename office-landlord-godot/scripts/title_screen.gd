class_name OfficeTitle
extends Control
## Office Landlord's title screen, composed rather than a themed dialog — the technique
## borrowed from play/overtime-idle-godot/scripts/title_screen.gd (key visual + wordmark
## layering, the `_font()` FontFile+CJK-fallback-holding pattern, an entrance tween built
## entirely from `.from()` calls so an interrupted build still leaves every element
## visible, `_gui_input` for the mouse vs `_unhandled_input` for the keyboard). NONE of
## overtime's noir direction comes with it: this is the all-ages candy sibling, so there
## is no `dim` overlay, no vignette, no 18+ badge — just Palette's cream/coral/teal on a
## bright office.
##
## Key visual and wordmark are both OPTIONAL at the file-existence level, on purpose: this
## screen has to look like *something* the moment it is opened, before ops/render_queue.py
## has finished a render pass, and "a blank Control" is not that. Missing either asset
## logs a push_warning and falls back to a plain Palette.GROUND ground / a Lilita-set
## Label reading the title — which is explicitly NOT a claim that a real key visual or a
## real logotype exists (see ops/PUNCHLIST.md's Office Landlord row for which is which at
## any given point).

signal start

const ShapedButtonScript := preload("res://scripts/shaped_button.gd")

const KV := "res://assets/title/keyvisual.webp"
const WORDMARK := "res://assets/title/wordmark.webp"
const DISPLAY := "res://assets/fonts/LilitaOne-Regular.ttf"
const TEXT_FONT := "res://assets/fonts/Nunito.ttf"

const W := 1280.0
const H := 720.0

var bg: TextureRect
var scrim: TextureRect
var wordmark_tex: TextureRect
var wordmark_label: Label
var primary
var t := 0.0
var _ready_to_start := false
var _kept: Array = []
var _has_kv := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_compose()
	I18n.changed.connect(func(_l): _relabel())
	call_deferred("_animate_in")


func _font(path: String) -> Font:
	var fnt: Font = load(path)
	if fnt == null:
		return ThemeDB.fallback_font
	var cjk := Cjk.face()
	if cjk and fnt is FontFile:
		fnt.fallbacks = [cjk]
		_kept.append(cjk)
	_kept.append(fnt)
	return fnt


func _compose() -> void:
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	_has_kv = ResourceLoader.exists(KV)
	if not _has_kv:
		push_warning("OfficeTitle: no %s yet — ops/render_queue.py add allages plates " % KV
			+ "--n 3 --only office_landlord_title, then ops/install_title_keyvisual.py "
			+ "office_landlord. Showing the plain candy ground until it lands.")
	if _has_kv:
		bg = TextureRect.new()
		bg.texture = load(KV)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bg.size = Vector2(W, H)
		bg.pivot_offset = Vector2(W / 2.0, H / 2.0)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

		scrim = _scrim()

	_wordmark()
	_menu()
	_lang()


## The bottom-of-frame gradient the menu sits on, so light-on-picture type stays legible.
## A generated Image + TextureRect, never a shader — a shader draws nothing at all on the
## Godot web export (memory pattern repeated across this studio's title screens).
func _scrim() -> TextureRect:
	var top := 340.0
	var h := int(H - top)
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var frac := float(y) / float(h - 1)
		# Warm cream, not noir black — the candy ground darkened toward its own deep
		# shade, so the picture runs out into the game's own palette rather than into a
		# generic bruise-brown gradient.
		var c := Palette.GROUND_DEEP
		img.set_pixel(0, y, Color(c.r, c.g, c.b, frac * 0.78))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = Vector2(0, top)
	tr.size = Vector2(W, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


func _wordmark() -> void:
	if ResourceLoader.exists(WORDMARK):
		wordmark_tex = TextureRect.new()
		wordmark_tex.texture = load(WORDMARK)
		wordmark_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wordmark_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wordmark_tex.position = Vector2(60, 90)
		wordmark_tex.size = Vector2(560, 220)
		wordmark_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(wordmark_tex)
		return
	# No baked logotype yet -- an honestly-labelled Lilita/Nunito placeholder, not a claim
	# of real art. See this file's header and ops/PUNCHLIST.md.
	push_warning("OfficeTitle: no %s — using a typeset Label as an interim wordmark, " % WORDMARK
		+ "not a real logotype bake. No generic 'mark bake' tool exists yet for this game.")
	wordmark_label = Label.new()
	wordmark_label.name = "TitleLabel"
	wordmark_label.text = I18n.t("title")
	wordmark_label.position = Vector2(60, 130)
	wordmark_label.size = Vector2(700, 140)
	wordmark_label.add_theme_font_override("font", _font(DISPLAY))
	wordmark_label.add_theme_font_size_override("font_size", 64)
	wordmark_label.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	wordmark_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	wordmark_label.add_theme_constant_override("outline_size", 8)
	wordmark_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wordmark_label)


func _menu() -> void:
	var sub := Label.new()
	sub.name = "SubtitleLabel"
	sub.text = I18n.t("subtitle")
	sub.position = Vector2(64, wordmark_tex.position.y + wordmark_tex.size.y + 8 if wordmark_tex else 260)
	sub.size = Vector2(680, 60)
	sub.add_theme_font_override("font", _font(TEXT_FONT))
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Palette.TEXT)
	# The plate behind this went from a dim grey-blue office to a candy-bright one when the
	# title swapped to the mascot, and Palette.TEXT alone stopped separating from it. Same
	# fix as OCCUPANCY's CTA earlier: keep the dark type, give it an opaque bright halo so
	# it reads on whatever the plate puts behind it.
	sub.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.92, 1.0))
	sub.add_theme_constant_override("outline_size", 5)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	primary = ShapedButtonScript.new()
	primary.shape = ShapedButtonScript.Shape.TICKET
	primary.tint = Palette.ACCENT
	primary.custom_minimum_size = Vector2(320, 90)
	primary.position = Vector2(64, sub.position.y + 80)
	primary.text = I18n.t("start")
	primary.pressed.connect(_begin)
	add_child(primary)


func _lang() -> void:
	var lang_btn := Button.new()
	lang_btn.text = I18n.ENDONYM[I18n.lang]
	lang_btn.position = Vector2(1080, 20)
	lang_btn.add_theme_font_override("font", _font(TEXT_FONT))
	lang_btn.pressed.connect(func():
		I18n.cycle()
		lang_btn.text = I18n.ENDONYM[I18n.lang])
	add_child(lang_btn)


func _relabel() -> void:
	if wordmark_label:
		wordmark_label.text = I18n.t("title")
	if primary:
		primary.text = I18n.t("start")


func _animate_in() -> void:
	modulate.a = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	if wordmark_tex:
		tw.tween_property(wordmark_tex, "modulate:a", 1.0, 0.9).from(0.0).set_delay(0.2)
	elif wordmark_label:
		tw.tween_property(wordmark_label, "modulate:a", 1.0, 0.9).from(0.0).set_delay(0.2)
	if primary:
		tw.tween_property(primary, "modulate:a", 1.0, 0.6).from(0.0).set_delay(0.55)
	tw.chain().tween_callback(func() -> void: _ready_to_start = true)


func _process(delta: float) -> void:
	if not visible or bg == null:
		return
	t += delta
	# A gentle daylight drift and swell, much smaller than the noir titles' — this is a
	# bright, cheerful screen and any dip in it is brightness spent for nothing.
	bg.position = Vector2(sin(t * 0.09) * 5.0, cos(t * 0.07) * 3.0)
	var swell := 1.04 + 0.012 * sin(t * 0.15)
	bg.scale = Vector2(swell, swell)


func _begin() -> void:
	if not _ready_to_start:
		return
	_ready_to_start = false
	Sfx.tick()
	start.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_begin()

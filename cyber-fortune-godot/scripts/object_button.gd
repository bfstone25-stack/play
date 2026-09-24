## ObjectButton — a button that is an object from the game, with its label beside it.
##
## ops/STANDARD.md, "Buttons are objects from the game, not reshaped rectangles"
## (2026-09-23). The earlier answer to "buttons are not rectangles" was ShapedButton:
## a rectangle cut into a tag, a slip, a sticky note. Across the board those still read as
## rectangles in costume. This is the other answer: no box at all. The control is the
## OBJECT (a rendered bell, key, knob, coin — cut out by ops/title_logotypes.py::gpu_object)
## plus its label set next to it on the art, and hover moves the object rather than lighting
## a surface.
##
## It extends Button on purpose, so `.text`, `pressed`, focus and keyboard activation all
## behave exactly as they did, and every test that presses a title button by node still
## does. Every StyleBox is emptied, so Godot draws nothing of its own.
##
##   var b := ObjectButton.new()
##   b.object_texture = load("res://assets/title/btn_bell.png")
##   b.text = "BEGIN"
##   b.object_size = 44
##
## `selected` replaces ShapedButton.tint for "this language is the current one": the object
## sits lit and slightly raised, and the label takes the accent colour.
class_name ObjectButton
extends Button

enum Motion { DIP, TURN, BOB }

@export var object_texture: Texture2D
@export var object_size := 44.0                 # px, square box the object is fitted into
@export var gap := 8.0                          # object -> label
@export var label_color := Color("#f1dfb0")
@export var accent_color := Color("#ffd27a")
@export var ink := Color(0.03, 0.02, 0.04, 0.95)  # label shadow / outline colour
@export var outline_px := 2                      # 0 for bitmap fonts (they cannot grow one)
@export var shadow_px := 1
@export var motion := Motion.DIP
@export var object_on_right := false
@export var selected := false:
	set(v):
		selected = v
		queue_redraw()

var _last_text := ""
var _hover := 0.0          # 0..1 eased hover amount
var _press := 0.0          # 0..1 eased press amount
var _t := 0.0


func _ready() -> void:
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Button draws its own text; this control draws the label itself so it can sit beside
	# the object, so the built-in text is made invisible rather than removed (keeping
	# `.text` authoritative for localisation and tests).
	_hide_builtin_text()
	_fit()
	set_process(true)


var _hiding := false


## Button's own text must stay invisible: this control draws the label itself. Callers that
## style every button in a screen (apply_locale, style_button) re-add font colours after
## _ready, and Button then draws the word a second time under ours -- seen on Overnight
## Clause's language row, 2026-09-23, every label doubled. Re-clear on every theme change.
func _hide_builtin_text() -> void:
	_hiding = true
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color", "font_disabled_color", "font_outline_color"]:
		add_theme_color_override(c, Color(0, 0, 0, 0))
	add_theme_constant_override("outline_size", 0)
	_hiding = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and not _hiding and is_inside_tree():
		_hide_builtin_text.call_deferred()


func _process(dt: float) -> void:
	_t += dt
	# Button has no text_changed signal, and a container sizes this control from
	# _get_minimum_size(). Without this, a label set after the control is laid out (every
	# localised title does that) gets a zero-width slot and draws nowhere visible.
	if text != _last_text:
		_last_text = text
		_fit()
	var want_h := 1.0 if (is_hovered() or has_focus()) else 0.0
	var want_p := 1.0 if button_pressed or (is_hovered() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) else 0.0
	_hover = move_toward(_hover, want_h, dt * 6.0)
	_press = move_toward(_press, want_p, dt * 14.0)
	queue_redraw()


## Button computes its own minimum size natively and never calls a script's
## _get_minimum_size(), so the width is pushed in through custom_minimum_size instead --
## measured on the fallback-carrying theme font, object + gap + label + outline. Found the
## hard way: FOLD's language control laid out 32 px wide (the native measure of the hidden
## built-in text) and its label was drawn underneath the next button.
func _fit() -> void:
	var f := get_theme_font("font")
	var fs := get_theme_font_size("font_size")
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if f else 0.0
	var want := Vector2(object_size + gap + tw + outline_px * 2 + 4.0, maxf(object_size, float(fs) + 6.0))
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, want.x), maxf(custom_minimum_size.y, want.y))


func _draw() -> void:
	var f := get_theme_font("font")
	var fs := get_theme_font_size("font_size")
	var h := size.y
	var ox := size.x - object_size if object_on_right else 0.0
	var oy := (h - object_size) * 0.5

	# --- the object, moving the way that object moves
	if object_texture:
		var e := _hover * _hover * (3.0 - 2.0 * _hover)
		var lift := -2.0 * e + 2.0 * _press + (-1.5 if selected else 0.0)
		var rot := 0.0
		var sc := 1.0 + 0.06 * e - 0.05 * _press
		match motion:
			Motion.DIP:
				lift += sin(_t * 9.0) * 0.8 * e
			Motion.TURN:
				rot = deg_to_rad(-14.0 * e + 6.0 * _press)
			Motion.BOB:
				lift += sin(_t * 5.0) * 1.6 * e
		var c := Vector2(ox + object_size * 0.5, oy + object_size * 0.5 + lift)
		draw_set_transform(c, rot, Vector2(sc, sc))
		var mod := Color(1, 1, 1, 1) if (selected or _hover > 0.01) else Color(0.86, 0.86, 0.86, 1)
		draw_texture_rect(object_texture,
			Rect2(Vector2(-object_size * 0.5, -object_size * 0.5), Vector2(object_size, object_size)),
			false, mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- the label, set on the art with its own ink
	if f and text != "":
		var col := accent_color if (selected or _hover > 0.5) else label_color
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tx := (ox - gap - tw) if object_on_right else (object_size + gap)
		var base := h * 0.5 + f.get_ascent(fs) * 0.5 - f.get_descent(fs) * 0.25
		var at := Vector2(tx + 2.0 * _hover, base)
		if outline_px > 0:
			draw_string_outline(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline_px * 2, ink)
		if shadow_px > 0:
			draw_string(f, at + Vector2(shadow_px, shadow_px), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		draw_string(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

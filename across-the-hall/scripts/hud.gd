extends Control

@onready var prompt: Label = $Prompt
@onready var note: Label = $Note
@onready var objective: Label = $Objective
@onready var vignette: ColorRect = $Vignette

var note_t := 0.0
var fear := 0.0
var clock: Label
var title: Label
var grain: ColorRect
var splash: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	note.visible = false
	prompt.text = ""
	UiFont.apply_label(prompt)
	UiFont.apply_label(note)
	UiFont.apply_label(objective)
	_clock()
	_title()
	_grain()
	_splash()

func _clock() -> void:
	clock = Label.new()
	clock.name = "Clock"
	clock.position = Vector2(28, 52)
	clock.add_theme_font_size_override("font_size", 14)
	clock.add_theme_color_override("font_color", Color(0.55, 0.72, 0.48, 0.85))
	clock.text = "02:17"
	UiFont.apply_label(clock)
	add_child(clock)

func _title() -> void:
	title = Label.new()
	title.name = "Title"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -280.0
	title.offset_right = 280.0
	title.offset_top = -40.0
	title.offset_bottom = 40.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.86, 0.8, 0.7, 1))
	title.visible = false
	UiFont.apply_label(title)
	add_child(title)

func _grain() -> void:
	grain = ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.color = Color(1, 1, 1, 1)
	var sh := load("res://shaders/grain.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		grain.material = mat
	add_child(grain)
	move_child(grain, 1)

## The title screen. 2026-09-20.
##
## What was here: splash.png behind a 38%-black ColorRect, with ONE plain Label carrying
## the title, the call to action and the keyboard map as three lines of the same 26 px
## system font in the middle of the screen. splash.png measures 0.08 brightness against a
## shelf floor of 0.45, so captured through ops/capture_title.sh the whole frame came back
## effectively black — the worst of the four all-ages titles, and worst because nobody had
## ever looked at it.
##
## It is now scripts/ath_title.gd, which owns the key visual, the logotype, the motion and
## the marks. The splash VARIABLE and hide_splash() keep their names and their behaviour,
## because game.gd drives both of them (its _unhandled_input checks hud.splash.visible to
## decide whether a click enters the game or interacts with the world) and this pass is a
## title screen, not a refactor of the input flow.
func _splash() -> void:
	splash = Control.new()
	splash.name = "Splash"
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.set_script(load("res://scripts/ath_title.gd"))
	splash.enter_pressed.connect(_enter)
	add_child(splash)


func _enter() -> void:
	hide_splash()
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("capture_mouse"):
		p.capture_mouse()


func hide_splash() -> void:
	if splash:
		splash.visible = false
		splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_prompt(t: String) -> void:
	prompt.text = t

func set_objective(t: String) -> void:
	objective.text = t

func set_clock(t: String) -> void:
	if clock:
		clock.text = t

func show_title(t: String) -> void:
	title.text = t
	title.visible = true

func hide_title() -> void:
	if title:
		title.visible = false

func set_fear(v: float) -> void:
	fear = v

func show_note(t: String) -> void:
	note.text = t
	note.visible = true
	note_t = 9.0

func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0:
			note.visible = false
	vignette.color.a = 0.04 + fear * 0.28
	if grain and grain.material is ShaderMaterial:
		(grain.material as ShaderMaterial).set_shader_parameter("grain", 0.05 + fear * 0.1)

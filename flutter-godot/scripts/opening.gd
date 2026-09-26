extends Control
## The opening (PORT_PLAN.md step 6), from frontend/opening.js: per edition, a few timed
## shots over one scene image -- an eyebrow line and a line of text each -- then the brand.
## Data and assets come from tools/extract_editions.js; nothing is re-typed here.
## Emits `done` at the end or on skip, and reports opening_done as index.html does.

signal done

const FONT_REG := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")

var _scene: TextureRect
var _eyebrow: Label
var _text: Label
var _amb: AudioStreamPlayer
var _finished := false


func play() -> void:
	var sc := Edition.opening()
	# Sized from the viewport, not by anchors: main.gd's root is not a sized Control, so
	# PRESET_FULL_RECT left this at 0x0 and only the absolutely placed captions drew.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("#100a0e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_scene = TextureRect.new()
	_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_scene.pivot_offset = Vector2(640, 360)
	_scene.modulate.a = 0.0
	add_child(_scene)
	var shade := ColorRect.new()   # the web build's caption gradient, as a flat foot band
	shade.color = Color(0.06, 0.03, 0.05, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_eyebrow = _label(FONT_BOLD, 16, Vector2(80, 520))
	_text = _label(FONT_REG, 34, Vector2(80, 552))
	var skip := Label.new()
	skip.text = "›› SKIP"
	skip.add_theme_font_override("font", FONT_BOLD)
	skip.add_theme_font_size_override("font_size", 14)
	skip.position = Vector2(1170, 24)
	skip.mouse_filter = Control.MOUSE_FILTER_STOP
	skip.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: finish())
	add_child(skip)
	if str(sc.get("ambience", "")) != "" and ResourceLoader.exists(sc["ambience"]):
		_amb = AudioStreamPlayer.new()
		_amb.stream = load(sc["ambience"])
		_amb.volume_db = -30.0
		add_child(_amb)
		_amb.play()
		create_tween().tween_property(_amb, "volume_db", -10.0, 1.2)
	var dur := float(sc.get("duration", 6000)) / 1000.0
	for i in sc.get("shots", []).size():
		var sh: Dictionary = sc["shots"][i]
		get_tree().create_timer(float(sh.get("at", 0)) / 1000.0).timeout.connect(func(): _shot(sh, i, dur))
	get_tree().create_timer(dur).timeout.connect(finish)


func _label(font: Font, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.97, 0.92, 0.9))
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.02, 0.05, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.position = pos
	l.size = Vector2(1120, 120)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l


func _shot(sh: Dictionary, i: int, dur: float) -> void:
	if _finished:
		return
	if str(sh.get("kind", "")) == "brand":
		var e := Edition.data()
		_eyebrow.text = str(e.get("localTitle", "")) if str(e.get("localTitle", "")) != "" else "FLUTTER"
		_text.text = str(e.get("tagline", ""))
	else:
		_eyebrow.text = str(sh.get("eyebrow", ""))
		_text.text = str(sh.get("text", ""))
		var p := str(sh.get("scene", ""))
		if _scene.texture == null and p != "" and ResourceLoader.exists(p):
			_scene.texture = load(p)
			_scene.scale = Vector2(1.10, 1.10)
			var tw := create_tween().set_parallel(true)
			tw.tween_property(_scene, "modulate:a", 1.0, 0.9)
			tw.tween_property(_scene, "scale", Vector2(1.0, 1.0), dur)   # one slow push-in, the whole piece
	for l in [_eyebrow, _text]:
		l.modulate.a = 0.0
		create_tween().tween_property(l, "modulate:a", 1.0, 0.5)


func finish() -> void:
	if _finished:
		return
	_finished = true
	Tel.ev("opening_done", "")   # = index.html:1961
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	if _amb:
		tw.parallel().tween_property(_amb, "volume_db", -40.0, 0.5)
	tw.tween_callback(func():
		done.emit()
		queue_free())

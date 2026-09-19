## Main — the client: the station behind everything, the screens on top of it, the CRT over
## the lot, and the keys.
##
## Screens are Controls built in code (title, ops, how, credits, play, debrief) and only one
## is visible at a time, which is the prototype's `show(name)`. The station layer and the
## CRT never unload, so the room is continuous across a screen change — the console does not
## blink when you press HOW TO PLAY, because a console does not.
extends Control

const DESIGN := Vector2(1280, 720)

var station: Node2D
var crt: ColorRect
var stage: Control
var screens := {}
var _lang_dock: HBoxContainer


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	station = preload("res://scripts/station.gd").new()
	back.add_child(station)

	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	var fx := CanvasLayer.new()
	fx.layer = 10
	add_child(fx)
	crt = preload("res://scripts/crt.gd").new()
	fx.add_child(crt)

	screens["title"] = preload("res://scripts/title_screen.gd").new()
	screens["ops"] = preload("res://scripts/ops_screen.gd").new()
	screens["how"] = preload("res://scripts/text_screen.gd").new()
	screens["credits"] = preload("res://scripts/text_screen.gd").new()
	screens["play"] = preload("res://scripts/play_screen.gd").new()
	screens["debrief"] = preload("res://scripts/debrief_screen.gd").new()
	screens["how"].page = "how"
	screens["credits"].page = "credits"
	for name in screens:
		var s: Control = screens[name]
		s.set_anchors_preset(Control.PRESET_FULL_RECT)
		s.visible = false
		s.main = self
		stage.add_child(s)

	_build_lang_dock()
	Game.lang_changed.connect(_on_lang)
	Sfx.bed()
	show_screen("title")


# ---- screens --------------------------------------------------------------------------
func show_screen(name: String) -> void:
	for k in screens:
		screens[k].visible = (k == name)
	Game.note_screen(name)
	# the station is a title-screen composition; behind the play screen it stills and dims
	# so the instrument readouts are the brightest thing on the tube, which is how a
	# console at night actually looks.
	var playing := name == "play" or name == "debrief"
	station.motion = 0.25 if playing else 1.0
	station.modulate = Color(1, 1, 1, 0.30 if playing else 1.0)
	crt.set_floor(0.07 if playing else 0.11)
	if screens[name].has_method("on_show"):
		screens[name].on_show()


func title() -> void:
	show_screen("title")


# ---- the language dock ------------------------------------------------------------------
## Bottom-right, on every screen, the way the prototype's #lang-dock was. Two chips.
func _build_lang_dock() -> void:
	_lang_dock = HBoxContainer.new()
	_lang_dock.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_lang_dock.position = Vector2(-150, -44)
	_lang_dock.add_theme_constant_override("separation", 6)
	add_child(_lang_dock)
	for code in GCStrings.LANGS:
		var b := Button.new()
		b.text = GCStrings.LANG_LABEL[code]
		b.custom_minimum_size = Vector2(56, 30)
		b.pressed.connect(func():
			Sfx.click()
			Game.set_lang(code))
		_lang_dock.add_child(b)
	_paint_lang()


func _paint_lang() -> void:
	var i := 0
	for code in GCStrings.LANGS:
		var b: Button = _lang_dock.get_child(i)
		b.theme_type_variation = "Active" if code == Game.lang else "Ghost"
		i += 1


func _on_lang(_l: String) -> void:
	_paint_lang()
	for k in screens:
		if screens[k].has_method("relocalise"):
			screens[k].relocalise()


# ---- keys -----------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: InputEventKey = event
	var scr: Control = screens.get(Game.current)
	if scr and scr.has_method("on_key") and scr.on_key(k):
		get_viewport().set_input_as_handled()
		return
	if k.keycode == KEY_ESCAPE and Game.current in ["how", "credits", "ops"]:
		Sfx.click()
		show_screen("title")
		get_viewport().set_input_as_handled()


# ---- the dev bridge -----------------------------------------------------------------------
## A command channel for tests/headless_web.py, and the same one the overtime build uses:
## the page pushes into window.__gc_cmd, this drains it once a frame and answers in
## window.__gc_result / window.__gc_state.
##
## Every command is something a player can also do with a mouse — there is no verb here
## that is not a button — so a run of it exercises the real client, not a back door. It
## exists because a Godot game draws into a canvas: without it "the debrief rendered" can
## only be checked by a human looking at a screenshot, and that is exactly the kind of
## check that has silently passed while being wrong before (memory: verification-that-lies).
##
## Costs nothing in a normal session: on the web it is one JavaScriptBridge.eval per frame
## reading an array that is almost always empty, and off the web it never runs.
func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return
	var raw := str(JavaScriptBridge.eval(
		"JSON.stringify((window.__gc_cmd && window.__gc_cmd.splice(0, 1)[0]) || null)"))
	if raw == "" or raw == "null":
		_publish_state()
		return
	var c = JSON.parse_string(raw)
	if not (c is Dictionary):
		return
	var out := _bridge(c)
	out["seq"] = c.get("seq", 0)
	JavaScriptBridge.eval("window.__gc_result = %s" % JSON.stringify(out))
	_publish_state()


func _bridge(c: Dictionary) -> Dictionary:
	var play: Control = screens["play"]
	match str(c.get("op", "")):
		"start":
			play.start_op(int(c.get("op_index", 0)))
			return {"ok": true}
		"screen":
			show_screen(str(c.get("name", "title")))
			return {"ok": true}
		"lang":
			Game.set_lang(str(c.get("lang", "en")))
			return {"ok": true}
		"auth", "deny":
			play._resolve(str(c.get("op")))
			return {"ok": true}
		"q":
			play._interrogate()
			return {"ok": true}
		"pin":
			play._roster_pressed(int(c.get("i", 0)))
			return {"ok": true}
		"name":
			play._accuse(int(c.get("i", 0)))
			return {"ok": true}
		"name_ghost":
			# press the face that is actually the mimic: the only winning move, and the
			# only way a scripted run can reach the win debrief on purpose
			if play.state.is_empty():
				return {"ok": false}
			for i in range(play.state.agents.size()):
				if str(play.state.agents[i].id) == str(play.state.mimicId):
					play._accuse(i)
					return {"ok": true, "i": i}
			return {"ok": false}
		"reset":
			Game.wins = 0
			Game.best = {}
			Game.persist()
			return {"ok": true}
	return {"ok": false, "why": "unknown op"}


func _publish_state() -> void:
	var play: Control = screens["play"]
	var s: Dictionary = play.state
	var st := {
		"screen": Game.current,
		"lang": Game.lang,
		"wins": Game.wins,
		"voice_langs": Voice.have(),
		"plates": station.has_plates(),
	}
	if not s.is_empty():
		st.merge({
			"op": int(s.op.id),
			"done": int(s.done),
			"requests": int(s.op.requests),
			"time": int(s.time),
			"ff": int(s.ff),
			"score": int(s.score),
			"codebook": str(s.codebook),
			"who": str(s.panel.who),
			"body": str(s.panel.body),
			"type": str(s.panel.type),
			"naming": bool(s.panel.naming),
			"ended": bool(s.ended),
			"win": bool(s.win),
			"reason": str(s.reason),
			"log": s.log.size(),
			"mimic": str(s.mimicId),
			"speaker": (str(s.request.speaker) if s.request != null else ""),
			"tells": (s.request.tells if s.request != null else []),
		})
	JavaScriptBridge.eval("window.__gc_state = %s" % JSON.stringify(st))

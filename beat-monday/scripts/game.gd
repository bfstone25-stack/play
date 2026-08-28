extends Node2D

## Prototype: dark pixel cubicle, point-click hotspots, coworker dialogue, flee vs obey.

var flags := {
	"pc": false,
	"sticky": false,
	"drawer": false,
	"coworker": false,
	"choice_done": false,
	"obey": false,
	"flee": false,
}
var title_t := 2.8
var ending := false

var room: Node2D
var pixel_root: Node2D
var hud: HorrorHud
var scale_wrap: Node2D

const LOGICAL := Vector2(320, 180)
const SCALE := 4.0

func _ready() -> void:
	add_to_group("game")
	_build_view()
	_build_hotspots()
	_build_hud()
	hud.show_title(true)
	hud.set_objective("Click the desk. Read what overtime left behind.")
	hud.set_clock("23:47  ·  FLOOR 13")

func _build_view() -> void:
	# Pixel room scaled with nearest filtering (project default_texture_filter=0).
	scale_wrap = Node2D.new()
	scale_wrap.name = "ScaleWrap"
	scale_wrap.scale = Vector2(SCALE, SCALE)
	scale_wrap.position = Vector2(
		(1280.0 - LOGICAL.x * SCALE) * 0.5,
		(720.0 - LOGICAL.y * SCALE) * 0.5
	)
	add_child(scale_wrap)

	pixel_root = Node2D.new()
	pixel_root.name = "PixelRoot"
	scale_wrap.add_child(pixel_root)

	room = Node2D.new()
	room.name = "Office"
	room.set_script(preload("res://scripts/office_builder.gd"))
	pixel_root.add_child(room)
	room.call("build")

func _build_hud() -> void:
	hud = HorrorHud.new()
	hud.name = "HUD"
	add_child(hud)
	# HorrorHud builds in _ready; wait one frame then wire.
	await get_tree().process_frame
	if not hud.choice_made.is_connected(_on_choice):
		hud.choice_made.connect(_on_choice)

func _build_hotspots() -> void:
	_hotspot("pc", "Check the CRT", Rect2(52, 58, 52, 40), Color(0.1, 0.9, 0.5, 0.18))
	_hotspot("sticky", "Read sticky note", Rect2(108, 86, 18, 14), Color(0.95, 0.85, 0.2, 0.25))
	_hotspot("drawer", "Open drawer", Rect2(88, 108, 36, 22), Color(0.5, 0.35, 0.2, 0.2))
	_hotspot("coworker", "Speak to coworker", Rect2(248, 58, 28, 72), Color(0.9, 0.1, 0.1, 0.2))

func _hotspot(id: String, prompt: String, rect: Rect2, color: Color) -> void:
	var h := Hotspot.new()
	h.name = "Hotspot_%s" % id
	pixel_root.add_child(h)
	h.configure(id, prompt, rect, color)
	h.activated.connect(_on_hotspot)
	h.add_to_group("hotspot")

func _process(delta: float) -> void:
	if title_t > 0.0:
		title_t -= delta
		if title_t <= 0.0:
			hud.show_title(false)

func set_prompt(t: String) -> void:
	if hud and not hud.is_busy():
		hud.set_prompt(t)

func clear_prompt(_t: String = "") -> void:
	if hud and not hud.is_busy():
		hud.clear_prompt()

func _on_hotspot(id: String) -> void:
	if ending or (hud and hud.is_busy()) or title_t > 0.0:
		return
	match id:
		"pc":
			flags["pc"] = true
			hud.show_dialogue([
				{"name": "CRT", "text": "OVERTIME TICKET #1313 — Due before clock-out.\nStatus: REQUIRED. Author: — — —"},
				{"name": "CRT", "text": "Slack sidebar: 14 coworkers Active.\nThe open-plan is empty. Your reflection lags one frame."},
			])
			hud.set_palette(0.05, 0.55, 0.0)
			hud.set_clock("23:51  ·  FLOOR 13")
		"sticky":
			flags["sticky"] = true
			hud.show_dialogue([
				{"name": "Sticky", "text": "Don't take the elevator after 23:50.\nIf the badge glows blue, they already counted you."},
			])
			hud.set_palette(0.0, 0.65, 0.15)
		"drawer":
			flags["drawer"] = true
			hud.show_dialogue([
				{"name": "Drawer", "text": "A half-written resignation letter.\nThe signature line is already filled — not in your handwriting."},
			])
			hud.set_palette(0.35, 0.35, 0.0)
			hud.set_clock("23:58  ·  FLOOR 13")
		"coworker":
			if not (flags["pc"] or flags["sticky"]):
				hud.show_dialogue([
					{"name": "???", "text": "Finish your desk first.\nWe still have a deck to ship."},
				])
				return
			flags["coworker"] = true
			hud.show_dialogue([
				{"name": "Coworker", "text": "You're still here. Good.\nManagement loves people who don't need sleep."},
				{"name": "Coworker", "text": "The eyes on the badge scan once.\nThey never finish loading a face."},
			])
			hud.set_palette(0.15, 0.7, 0.4)

func on_dialogue_done() -> void:
	if ending or flags["choice_done"]:
		return
	if flags["coworker"] and not flags["choice_done"]:
		hud.set_objective("Intercom crackles. Choose.")
		hud.set_clock("11:59  ·  FLOOR 13")
		hud.set_palette(0.45, 0.35, 0.5)
		hud.show_choice(
			"INTERCOM: Stay and finish the deck. Or leave Floor 13 now.",
			"OBEY — finish the deck",
			"obey",
			"FLEE — take the stairs",
			"flee"
		)

func _on_choice(choice_id: String) -> void:
	flags["choice_done"] = true
	ending = true
	match choice_id:
		"obey":
			flags["obey"] = true
			hud.set_palette(0.85, 0.1, 0.8)
			hud.set_clock("11:59  ·  FOREVER")
			hud.set_objective("Ending B (stub): Complicit — Slack shows you Active forever.")
			hud.show_dialogue([
				{"name": "System", "text": "Deck submitted.\nYour status will remain Active.\nWelcome to the night shift."},
			])
		"flee":
			flags["flee"] = true
			hud.set_palette(0.1, 0.85, 0.2)
			hud.set_clock("00:00  ·  STAIRS")
			hud.set_objective("Ending A (stub): Witness — you leave with a resignation that is not yours.")
			hud.show_dialogue([
				{"name": "Stairs", "text": "Emergency blue washes the concrete.\nYour badge number is already blank."},
			])
		_:
			hud.show_dialogue([{"name": "System", "text": "…"}])
	# Disable hotspots after ending choice.
	for n in get_tree().get_nodes_in_group("hotspot"):
		if n.has_method("set_hotspot_enabled"):
			n.set_hotspot_enabled(false)

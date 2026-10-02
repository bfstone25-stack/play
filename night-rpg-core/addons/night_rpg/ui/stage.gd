class_name NRStage
extends Node2D
## The 2.5D room: a painted plate on the back layer, a dust layer on the front, both
## drifting against the pointer at different rates (parallax), darkened by a CanvasModulate
## and lit by Light2D -- a torch that follows the pointer and lamps the room data places.
## Characters standing in the room are sprites on a middle layer, lit the same way.

const VIEW := Vector2(1280, 720)

var plate: Sprite2D
var figure: Sprite2D
var dust: Sprite2D
var vignette: Sprite2D
var dark: CanvasModulate
var torch: PointLight2D
var lamps: Array = []
var drift := Vector2.ZERO
var figure_base := Vector2(922, 446)
var plate_base := Vector2(640, 360)
var t := 0.0
var torch_on := true


func _ready() -> void:
	plate = Sprite2D.new()
	plate.position = VIEW / 2
	add_child(plate)
	figure = Sprite2D.new()
	figure.position = Vector2(VIEW.x * 0.72, VIEW.y * 0.62)
	add_child(figure)
	dust = Sprite2D.new()
	dust.position = VIEW / 2
	var dm := CanvasItemMaterial.new()
	dm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	dm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	dust.material = dm
	add_child(dust)
	vignette = Sprite2D.new()
	vignette.position = VIEW / 2
	var vm := CanvasItemMaterial.new()
	vm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	vignette.material = vm
	add_child(vignette)
	var dp := NRSkin.ui("dust")
	if dp != "" and ResourceLoader.exists(dp):
		dust.texture = load(dp)
		dust.scale = Vector2.ONE * (VIEW.x * 1.15 / dust.texture.get_width())
	var vp := NRSkin.ui("vignette")
	if vp != "" and ResourceLoader.exists(vp):
		vignette.texture = load(vp)
		vignette.scale = VIEW / vignette.texture.get_size()
	dark = CanvasModulate.new()
	dark.color = Color(0.55, 0.52, 0.6)
	add_child(dark)
	torch = PointLight2D.new()
	torch.texture = NRSkin.light_texture()
	torch.texture_scale = 1.6
	torch.energy = 0.9
	torch.color = Color(1.0, 0.82, 0.6)
	torch.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(torch)


func set_plate(tex: Texture2D, mood: Dictionary = {}) -> void:
	plate.texture = tex
	if tex != null:
		var k: float = max(VIEW.x * 1.08 / tex.get_width(), VIEW.y * 1.08 / tex.get_height()) * float(mood.get("zoom", 1.0))
		plate.scale = Vector2(k, k)
	var off = mood.get("offset", [0, 0])
	plate_base = VIEW / 2 + Vector2(float(off[0]), float(off[1]))
	dark.color = Color.html(mood.get("ambient", "#8a8496"))
	torch_on = bool(mood.get("torch", true))
	torch.visible = torch_on
	for l in lamps:
		l.queue_free()
	lamps.clear()
	for lp in mood.get("lamps", []):
		var l := PointLight2D.new()
		l.texture = NRSkin.light_texture()
		l.position = Vector2(float(lp[0]) * VIEW.x, float(lp[1]) * VIEW.y)
		l.texture_scale = float(lp[2]) if lp.size() > 2 else 1.2
		l.color = Color.html(lp[3]) if lp.size() > 3 else Color(1, 0.75, 0.45)
		l.energy = 0.8
		add_child(l)
		lamps.append(l)


func set_figure(tex: Texture2D, x: float = 0.72) -> void:
	figure.texture = tex
	figure.visible = tex != null
	if tex != null:
		var k := VIEW.y * 0.86 / tex.get_height()
		figure.scale = Vector2(k, k)
		figure_base = Vector2(VIEW.x * x, VIEW.y - tex.get_height() * k / 2 + 30)


func _process(delta: float) -> void:
	t += delta
	var m := get_viewport().get_mouse_position()
	var target := (m - VIEW / 2) / (VIEW / 2)
	drift = drift.lerp(target, min(1.0, delta * 2.0))
	var breathe := Vector2(sin(t * 0.21), cos(t * 0.17)) * 0.25
	plate.position = plate_base - (drift + breathe) * 14.0
	figure.position = figure_base - (drift + breathe) * 22.0
	dust.position = VIEW / 2 - (drift + breathe) * 34.0 + Vector2(0, fmod(t * 6.0, 40.0) - 20.0)
	if torch_on:
		torch.position = torch.position.lerp(m, min(1.0, delta * 8.0))
		torch.energy = 0.85 + 0.08 * sin(t * 7.3) + 0.04 * sin(t * 13.1)
	for i in lamps.size():
		lamps[i].energy = 0.75 + 0.06 * sin(t * 3.1 + i)

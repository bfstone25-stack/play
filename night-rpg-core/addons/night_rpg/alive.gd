class_name NRAlive
extends RefCounted
## Breathing and sway for figures and CGs (ui/alive.gdshader): the painted art is deformed,
## nothing is drawn on top of it. Where the breath sits comes from data/anim.json
## ({"<file name>": {"chest": [x, y], "radius": r, "amp": a}} in texture UV) when a title has
## annotated it; otherwise a standing figure finds its own chest from its alpha silhouette
## (a quarter of the way down the figure, centred on the body at that height) and a CG
## breathes softly around its centre. Settings "motion" off sets every amplitude to zero.

const SHADER := preload("res://addons/night_rpg/ui/alive.gdshader")
static var _anim = null
static var _auto: Dictionary = {}


static func enabled() -> bool:
	return bool(RPG.persist.get("motion", true))


static func material_for(_tex: Texture2D, figure: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("phase", randf() * TAU)
	m.set_shader_parameter("sway", 0.006 if figure else 0.0)
	m.set_shader_parameter("motion", 1.0 if enabled() else 0.0)
	return m


static func _data() -> Dictionary:
	if _anim == null:
		_anim = {}
		if FileAccess.file_exists("res://data/anim.json"):
			var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim.json"))
			if d is Dictionary:
				_anim = d
	return _anim


## Chest point of a standing figure from its silhouette: top of the opaque area, then 26% of
## the figure's height below it, x = middle of the opaque run at that row.
static func _figure_chest(tex: Texture2D) -> Vector2:
	var key := tex.resource_path
	if _auto.has(key):
		return _auto[key]
	var img := tex.get_image()
	var out := Vector2(0.5, 0.3)
	if img != null:
		if img.is_compressed():
			img = img.duplicate()
			img.decompress()
		var w := img.get_width()
		var h := img.get_height()
		var top := -1
		var bottom := h - 1
		for y in range(0, h, 4):
			for x in range(0, w, 6):
				if img.get_pixel(x, y).a > 0.5:
					top = y
					break
			if top >= 0:
				break
		if top >= 0:
			var cy := top + int((bottom - top) * 0.26)
			var x0 := -1
			var x1 := -1
			for x in range(0, w, 2):
				if img.get_pixel(x, cy).a > 0.5:
					if x0 < 0:
						x0 = x
					x1 = x
			if x0 >= 0:
				out = Vector2((x0 + x1) * 0.5 / w, float(cy) / h)
	_auto[key] = out
	return out


static func fit(m: Material, tex: Texture2D, figure: bool) -> void:
	if not (m is ShaderMaterial) or tex == null:
		return
	m.set_shader_parameter("motion", 1.0 if enabled() else 0.0)
	var a: Dictionary = _data().get(tex.resource_path.get_file(), {})
	if a.has("chest"):
		m.set_shader_parameter("chest", Vector2(float(a["chest"][0]), float(a["chest"][1])))
	elif figure:
		m.set_shader_parameter("chest", _figure_chest(tex))
	else:
		m.set_shader_parameter("chest", Vector2(0.5, 0.55))
	m.set_shader_parameter("radius", float(a.get("radius", 0.2 if figure else 0.28)))
	m.set_shader_parameter("breath_amp", float(a.get("amp", 0.016 if figure else 0.012)))
	var amp := float(a.get("amp", 0.016 if figure else 0.012))
	m.set_shader_parameter("lift", float(a.get("lift", 0.0035 if figure else 0.0025)) if amp > 0.0 else 0.0)

## Portrait — her, large. One image; the four phases are lighting and colour treatments
## on it (saturation, brightness, a cool or warm tint, lamp warmth), tweened between, plus
## a slow breathing motion. Never four faces. "lost" is the desaturated closed state.
## The image is assets/portraits/<who>.webp — the bust cut from the installed tier-1 plate
## by tools/sync_art.py — never the early ref renders in ops/.
class_name Portrait
extends Control

const SHADER := """
shader_type canvas_item;
uniform float saturation = 1.0;
uniform float brightness = 1.0;
uniform vec4 tint : source_color = vec4(0.0);
uniform float tint_amount = 0.0;
uniform float warm = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = mix(vec3(l), c.rgb, saturation) * brightness;
	g = mix(g, tint.rgb, tint_amount);
	// lamp from the upper right: warm falloff
	float d = distance(UV, vec2(0.78, 0.12));
	g += vec3(0.95, 0.72, 0.38) * warm * 0.22 * (1.0 - smoothstep(0.1, 0.9, d));
	// vignette
	float v = smoothstep(1.15, 0.45, distance(UV, vec2(0.5, 0.42)));
	g *= mix(0.55, 1.0, v);
	COLOR = vec4(g, c.a);
}
"""

var who := ""
var phase := "guarded"
var _tex: TextureRect
var _mat: ShaderMaterial
var _breath: Tween
var _tag: Label
var _tag_panel: PanelContainer


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = TextureRect.new()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_tex.material = _mat
	add_child(_tex)
	_tag_panel = PanelContainer.new()
	_tag_panel.add_theme_stylebox_override("panel", StudioTheme.flat(Color(Palette.GROUND, 0.85), Palette.PANEL_EDGE, 6, 1, Vector2(8, 3)))
	_tag = StudioTheme.mono_label("GUARDED", 10, Palette.GOLD)
	_tag_panel.add_child(_tag)
	_tag_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_tag_panel.position = Vector2(10, 0)
	add_child(_tag_panel)
	resized.connect(_layout)
	_layout()
	_apply(Palette.PHASE["guarded"], 0.0)
	_start_breath()


func _layout() -> void:
	_tag_panel.position = Vector2(10, size.y - 34)
	_tex.pivot_offset = size * Vector2(0.5, 0.35)


static func portrait_path(id: String) -> String:
	return "res://assets/portraits/%s.webp" % id


func show_character(id: String) -> void:
	who = id
	var path := portrait_path(id)
	if ResourceLoader.exists(path):
		_tex.texture = load(path)


func texture_path() -> String:
	return _tex.texture.resource_path if _tex.texture else ""


func set_phase(p: String, closed: bool = false, instant: bool = false) -> void:
	var key := "lost" if closed else p
	phase = p
	_tag.text = ("CLOSED · " if closed else "") + p.to_upper()
	_tag.add_theme_color_override("font_color", Palette.HEAT if closed else Palette.GOLD)
	_apply(Palette.PHASE.get(key, Palette.PHASE["guarded"]), 0.0 if instant else 0.7)


func _apply(t: Dictionary, secs: float) -> void:
	if secs <= 0.0:
		_mat.set_shader_parameter("saturation", t["sat"])
		_mat.set_shader_parameter("brightness", t["bright"])
		_mat.set_shader_parameter("tint", t["tint"])
		_mat.set_shader_parameter("tint_amount", t["amount"])
		_mat.set_shader_parameter("warm", t["warm"])
		return
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_mat, "shader_parameter/saturation", t["sat"], secs)
	tw.tween_property(_mat, "shader_parameter/brightness", t["bright"], secs)
	tw.tween_property(_mat, "shader_parameter/tint", t["tint"], secs)
	tw.tween_property(_mat, "shader_parameter/tint_amount", t["amount"], secs)
	tw.tween_property(_mat, "shader_parameter/warm", t["warm"], secs)


func _start_breath() -> void:
	if _breath:
		_breath.kill()
	_breath = create_tween().set_loops()
	_breath.tween_property(_tex, "scale", Vector2(1.025, 1.025), 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath.tween_property(_tex, "scale", Vector2(1.0, 1.0), 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## A small lean-in when a card lands, on top of the breathing.
func react(strength: float = 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_tex, "position:y", -6.0 * strength, 0.16).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_tex, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func shader_params() -> Dictionary:
	return {"saturation": _mat.get_shader_parameter("saturation"), "warm": _mat.get_shader_parameter("warm")}

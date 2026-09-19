## Chip — a needs / signal pill. Lit = the engine has this signal in evidence; help =
## dashed border (support, not path); harm = red, "closed".
class_name Chip
extends PanelContainer

var lit := false
var help := false
var harm := false
var _label: Label
var _pulse := 0.0


static func make(text: String, is_lit: bool, is_help: bool, is_harm: bool = false, size: int = 10) -> Chip:
	var c := Chip.new()
	c.lit = is_lit
	c.help = is_help
	c.harm = is_harm
	c._label = StudioTheme.mono_label(text, size, Palette.MUTED)
	c.add_child(c._label)
	c._style()
	return c


func set_lit(on: bool) -> void:
	if lit == on:
		return
	lit = on
	_style()
	if on:
		# the chip "lights": a quick swell
		var tw := create_tween()
		pivot_offset = size / 2
		tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1, 1), 0.18)


func _style() -> void:
	var bg := Color("2a2220")
	var border := Color("4a3c30")
	var fg := Color("c9b48f")
	if harm:
		bg = Color("2a1a18"); border = Palette.RED_DIM; fg = Color("f0a090")
	elif lit:
		bg = Palette.AMBER; border = Palette.AMBER; fg = Color("1e1408")
	var s := StudioTheme.flat(bg, border, 9, 1, Vector2(7, 2))
	if help and not lit:
		s.border_color = Color(border, 0.9)
		s.set_border_width_all(1)
		s.bg_color = Color(bg, 0.5)
	add_theme_stylebox_override("panel", s)
	if _label:
		_label.add_theme_color_override("font_color", fg)

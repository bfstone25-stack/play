class_name MireiPanel
extends VBoxContainer
## Mirei on screen: her portrait, swapped by mood (calm/tense/fail/empty — the parent's
## moodFrom()), a lamp that warms or cools with it, and her line in a speech panel.

## The six floor lines, as I18n keys (scripts/i18n.gd holds the English, Chinese and
## Japanese). She is the same character in all three: clipped, never warm.
const LINES := {
	"empty": "m_empty",
	"calm": "m_calm",
	"tense": "m_tense",
	"fail": "m_fail",
	"chain": "m_chain",
	"place": "m_place",
}
const MOOD_TINT := {
	"calm": Color(1.0, 0.96, 0.9),
	"tense": Color(0.95, 0.85, 0.72),
	"fail": Color(0.9, 0.62, 0.55),
	"empty": Color(0.82, 0.74, 0.84),
}
const MOOD_LAMP := {"calm": Palette.GOLD, "tense": Palette.GOLD_DEEP, "fail": Palette.HEAT, "empty": Palette.MUTED}

var portrait: TextureRect
var frame: PanelContainer
var lamp: ColorRect
var mood_tag: Label
var say: RichTextLabel
var mood := "empty"
var _typing: Tween
var _line_lock := false


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	frame = PanelContainer.new()
	frame.theme_type_variation = "Glass"
	frame.custom_minimum_size = Vector2(0, 250)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(frame)
	var stack := Control.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(stack)
	lamp = ColorRect.new()
	lamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lamp.color = Color(MOOD_LAMP["empty"], 0.14)
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(lamp)
	portrait = TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(portrait)
	var vig := TextureRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	vig.offset_top = -90
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gt := GradientTexture2D.new()
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.75))
	gt.gradient = g
	gt.width = 4
	gt.height = 64
	vig.texture = gt
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(vig)
	var name_row := HBoxContainer.new()
	name_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_row.offset_top = -30
	name_row.offset_left = 10
	name_row.offset_right = -14
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(name_row)
	var nm := Label.new()
	nm.text = I18n.t("mirei_card")
	nm.theme_type_variation = "Tag"
	nm.add_theme_color_override("font_color", Palette.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(nm)
	mood_tag = Label.new()
	mood_tag.theme_type_variation = "Tag"
	mood_tag.text = "—"
	name_row.add_child(mood_tag)
	# her speech panel: warm paper, her line in the one serif
	var speech := PanelContainer.new()
	speech.theme_type_variation = "Paper"
	speech.custom_minimum_size = Vector2(0, 92)
	add_child(speech)
	say = StudioTheme.say_label(17)
	say.custom_minimum_size = Vector2(0, 60)
	speech.add_child(say)
	set_mood("empty", true)
	set_line("empty")


func set_mood(m: String, instant: bool = false) -> void:
	if m == mood and not instant:
		return
	mood = m
	var tex := Look.portrait(m)
	if tex != null:
		portrait.texture = tex
	var tint: Color = MOOD_TINT.get(m, Color.WHITE)
	var lamp_c: Color = MOOD_LAMP.get(m, Palette.GOLD)
	mood_tag.text = I18n.t("mood_" + m)
	mood_tag.add_theme_color_override("font_color", lamp_c)
	if instant:
		portrait.modulate = tint
		lamp.color = Color(lamp_c, 0.16)
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(portrait, "modulate", tint, 0.5)
	tw.tween_property(lamp, "color", Color(lamp_c, 0.16), 0.5)
	# a small breath on a mood change
	tw.tween_property(portrait, "scale", Vector2(1.02, 1.02), 0.18).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(portrait, "scale", Vector2(1, 1), 0.3)
	portrait.pivot_offset = portrait.size * 0.5


func set_line(key: String, lock: bool = false) -> void:
	if _line_lock and not lock:
		return
	_line_lock = lock
	speak(I18n.t(str(LINES.get(key, LINES["empty"]))))


func unlock_line() -> void:
	_line_lock = false


## Typewriter: the text arrives, it does not appear.
func speak(txt: String) -> void:
	say.text = "[i]“" + txt + "”[/i]"
	say.visible_characters = 0
	if _typing and _typing.is_valid():
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(say, "visible_characters", txt.length() + 4, min(1.4, 0.022 * txt.length()))

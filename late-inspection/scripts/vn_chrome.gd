extends Control
class_name VnChrome

## Bottom ADV bar for ordinary inspects, full-screen NVL for diary / collapse / endings.

const NVL_IDS := ["letters", "answering", "cassette", "mirror", "final_evidence"]

const SPEAKER_KEYS := {
	"MARA": "spk.mara",
	"MARA'S FIELD NOTE": "spk.inner",
	"MARA'S VOICE": "spk.mara",
	"IRIS": "spk.iris",
	"DANE": "spk.dane",
	"PELL": "spk.pell",
	"HARROW": "spk.harrow",
	"SYSTEM": "spk.system",
	"OPERATOR": "spk.system",
	"INNER": "spk.inner",
	"玛拉": "spk.mara",
	"玛拉的现场笔记": "spk.inner",
	"玛拉的声音": "spk.mara",
	"艾里斯": "spk.iris",
	"戴恩": "spk.dane",
	"佩尔": "spk.pell",
	"哈罗": "spk.harrow",
	"系统": "spk.system",
	"接线员": "spk.system",
	"内心": "spk.inner",
	"マラ": "spk.mara",
	"マラの現場メモ": "spk.inner",
	"マラの声": "spk.mara",
	"アイリス": "spk.iris",
	"デイン": "spk.dane",
	"ペル": "spk.pell",
	"ハロー": "spk.harrow",
	"システム": "spk.system",
	"オペレーター": "spk.system",
	"独白": "spk.inner",
	"INTERIOR": "spk.inner",
	"SISTEMA": "spk.system",
	"OPERADORA": "spk.system",
	"마라": "spk.mara",
	"마라의 현장 메모": "spk.inner",
	"마라의 목소리": "spk.mara",
	"아이리스": "spk.iris",
	"데인": "spk.dane",
	"펠": "spk.pell",
	"해로우": "spk.harrow",
	"시스템": "spk.system",
	"교환원": "spk.system",
	"속마음": "spk.inner",
}

var lines: Array = []
var line_index := 0
var document_pages: PackedStringArray = PackedStringArray()
var nvl_mode := false
var stay_open := false
var typing := false
var typed := 0
var type_t := 0.0
var full_body := ""
var _done: Callable = Callable()
var pulse_t := 0.0
var fade_t := 0.0

var adv_root: Control
var adv_plate: ColorRect
var nameplate: Label
var body: Label
var hint: Label
var choice_root: Control
var choice_prompt: Label
var btn_a: Button
var btn_b: Button
var _choice_cb: Callable = Callable()
var nvl_root: Control
var nvl_veil: ColorRect
var nvl_name: Label
var nvl_body: Label
var nvl_hint: Label
var pressure: Label
var shake_host: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_adv()
	_build_choice()
	_build_nvl()
	_build_pressure()
	visible = true
	call_deferred("_fit")

func _fit() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if adv_root:
		adv_root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		adv_root.offset_top = -196.0
		adv_root.offset_bottom = -18.0
		adv_root.offset_left = 48.0
		adv_root.offset_right = -48.0
	if nvl_root:
		nvl_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if choice_root:
		choice_root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		choice_root.offset_top = -348.0
		choice_root.offset_bottom = -200.0
		choice_root.offset_left = 80.0
		choice_root.offset_right = -80.0

func is_open() -> bool:
	return adv_root.visible or nvl_root.visible

func is_nvl_open() -> bool:
	return nvl_root.visible

func is_choice_open() -> bool:
	return choice_root.visible

func line_count() -> int:
	return lines.size()

static func is_nvl_id(id: String) -> bool:
	return id in NVL_IDS


func show_text(text: String, use_nvl: bool, cb: Callable = Callable(), keep := false) -> void:
	document_pages = text.split("\n---\n", false)
	show_lines(parse_text(text), use_nvl, cb, keep)


func show_lines(parsed: Array, use_nvl: bool, cb: Callable = Callable(), keep := false) -> void:
	lines = parsed
	line_index = 0
	nvl_mode = use_nvl
	stay_open = keep
	_done = cb
	choice_root.visible = false
	if lines.is_empty():
		_finish()
		return
	if use_nvl:
		adv_root.visible = false
		nvl_root.visible = true
		nvl_veil.color = Color(0.04, 0.0, 0.01, 1)
		fade_t = 0.12
		pressure.visible = true
	else:
		nvl_root.visible = false
		pressure.visible = false
		adv_root.visible = true
		adv_root.modulate.a = 0.0
		fade_t = 0.0
	_render_line(true)


func open_choice(text: String, a: String, b: String, cb: Callable) -> void:
	_choice_cb = cb
	choice_prompt.text = text
	btn_a.text = "A  " + a
	btn_b.text = "B  " + b
	if not adv_root.visible:
		adv_root.visible = true
		adv_root.modulate.a = 1.0
		nameplate.text = Loc.t("spk.system")
		nameplate.visible = true
		body.text = text
		hint.text = Loc.t("vn.choose")
		typing = false
	choice_root.visible = true
	btn_a.grab_focus()


func pick(i: int) -> void:
	if not choice_root.visible:
		return
	choice_root.visible = false
	var cb := _choice_cb
	_choice_cb = Callable()
	if cb.is_valid():
		cb.call(i)


func advance(force_page := false) -> void:
	if choice_root.visible:
		return
	if not is_open():
		return
	if typing and not force_page:
		_snap_type()
		return
	if line_index >= lines.size() - 1:
		if stay_open:
			return
		_finish()
		return
	line_index += 1
	_render_line(not force_page)


func current_body() -> String:
	if nvl_root.visible:
		return nvl_body.text
	return body.text


func apply_locale() -> void:
	if hint and adv_root.visible and not choice_root.visible:
		hint.text = Loc.t("vn.advance")
	if nvl_hint and nvl_root.visible:
		nvl_hint.text = Loc.t("vn.advance")
	if pressure:
		pressure.text = Loc.t("vn.pressure")
	if line_index < lines.size():
		_paint_speaker(str(lines[line_index].get("speaker", "")))


func _finish() -> void:
	adv_root.visible = false
	nvl_root.visible = false
	choice_root.visible = false
	pressure.visible = false
	typing = false
	var cb := _done
	_done = Callable()
	if cb.is_valid():
		cb.call()


func _render_line(use_type: bool) -> void:
	var row: Dictionary = lines[line_index]
	full_body = str(row.get("body", ""))
	_paint_speaker(str(row.get("speaker", "")))
	if nvl_mode:
		nvl_body.text = full_body
		nvl_hint.text = Loc.t("vn.advance") if not stay_open or line_index < lines.size() - 1 else ""
		typing = false
	else:
		hint.text = Loc.t("vn.advance")
		if use_type and full_body.length() > 8:
			typing = true
			typed = 0
			type_t = 0.0
			body.text = ""
		else:
			typing = false
			body.text = full_body


func _paint_speaker(raw: String) -> void:
	var key := _speaker_key(raw)
	var label := Loc.t(key) if key != "" else ""
	nameplate.text = label
	nameplate.visible = label != ""
	nvl_name.text = label
	nvl_name.visible = label != ""
	var color := _speaker_color(key)
	nameplate.add_theme_color_override("font_color", color)
	nvl_name.add_theme_color_override("font_color", color)


func _snap_type() -> void:
	typing = false
	body.text = full_body


func _process(delta: float) -> void:
	if typing:
		type_t += delta * 78.0
		var next := mini(full_body.length(), int(type_t))
		if next != typed:
			typed = next
			body.text = full_body.substr(0, typed)
		if typed >= full_body.length():
			typing = false
	if adv_root.visible and adv_root.modulate.a < 1.0:
		adv_root.modulate.a = minf(1.0, adv_root.modulate.a + delta * 4.0)
	if nvl_root.visible:
		fade_t += delta
		var target := Color(0.2, 0.015, 0.03, 0.9)
		nvl_veil.color = Color(0, 0, 0, 1).lerp(target, clampf(fade_t * 3.2, 0.0, 1.0))
		pulse_t += delta
		var pulse := 1.0 + 0.085 * sin(pulse_t * 3.5)
		# Keep the BMFont at its atlas size; animate its Control transform only.
		nvl_body.scale = Vector2.ONE * (1.625 * pulse)
		if nvl_body.material is ShaderMaterial:
			(nvl_body.material as ShaderMaterial).set_shader_parameter("time", pulse_t)
			(nvl_body.material as ShaderMaterial).set_shader_parameter("shake", 2.6 + 1.1 * sin(pulse_t * 7.0))
		pressure.modulate.a = 0.45 + 0.4 * absf(sin(pulse_t * 2.4))


func _build_adv() -> void:
	adv_root = Control.new()
	adv_root.name = "AdvRoot"
	adv_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	adv_root.offset_top = -196.0
	adv_root.offset_bottom = -18.0
	adv_root.offset_left = 48.0
	adv_root.offset_right = -48.0
	adv_root.visible = false
	adv_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adv_plate = ColorRect.new()
	adv_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	adv_plate.color = Color(0.035, 0.025, 0.02, 0.82)
	adv_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adv_root.add_child(adv_plate)
	var edge := ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_TOP_WIDE)
	edge.offset_bottom = 2.0
	edge.color = Color(0.72, 0.48, 0.28, 0.55)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adv_root.add_child(edge)
	nameplate = Label.new()
	nameplate.position = Vector2(22, 10)
	nameplate.size = Vector2(360, 28)
	nameplate.add_theme_font_size_override("font_size", 15)
	UiFont.apply_label(nameplate)
	adv_root.add_child(nameplate)
	body = Label.new()
	body.position = Vector2(22, 40)
	body.size = Vector2(1100, 110)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 19)
	body.add_theme_color_override("font_color", Color(0.92, 0.87, 0.78))
	UiFont.apply_label(body)
	adv_root.add_child(body)
	hint = Label.new()
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -280.0
	hint.offset_top = -28.0
	hint.offset_right = -12.0
	hint.offset_bottom = -6.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.62, 0.54, 0.42, 0.85))
	UiFont.apply_label(hint)
	adv_root.add_child(hint)
	add_child(adv_root)


func _build_choice() -> void:
	choice_root = Control.new()
	choice_root.name = "ChoiceRoot"
	choice_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_root.offset_top = -348.0
	choice_root.offset_bottom = -200.0
	choice_root.offset_left = 80.0
	choice_root.offset_right = -80.0
	choice_root.visible = false
	choice_root.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_prompt = Label.new()
	choice_prompt.set_anchors_preset(Control.PRESET_TOP_WIDE)
	choice_prompt.offset_bottom = 44.0
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_prompt.add_theme_font_size_override("font_size", 16)
	choice_prompt.add_theme_color_override("font_color", Color(0.9, 0.82, 0.68))
	UiFont.apply_label(choice_prompt)
	choice_root.add_child(choice_prompt)
	btn_a = _choice_btn("ChoiceA", 48.0)
	btn_b = _choice_btn("ChoiceB", 96.0)
	btn_a.pressed.connect(func() -> void: pick(0))
	btn_b.pressed.connect(func() -> void: pick(1))
	choice_root.add_child(btn_a)
	choice_root.add_child(btn_b)
	add_child(choice_root)


func _choice_btn(n: String, top: float) -> Button:
	var b := Button.new()
	b.name = n
	b.set_anchors_preset(Control.PRESET_TOP_WIDE)
	b.offset_top = top
	b.offset_bottom = top + 42.0
	b.add_theme_font_size_override("font_size", 16)
	UiFont.apply_button(b)
	return b


func _build_nvl() -> void:
	nvl_root = Control.new()
	nvl_root.name = "NvlRoot"
	nvl_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	nvl_root.visible = false
	nvl_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nvl_veil = ColorRect.new()
	nvl_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	nvl_veil.color = Color(0.12, 0.01, 0.02, 0.9)
	nvl_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nvl_root.add_child(nvl_veil)
	shake_host = Control.new()
	shake_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	shake_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nvl_root.add_child(shake_host)
	nvl_name = Label.new()
	nvl_name.set_anchors_preset(Control.PRESET_CENTER_TOP)
	nvl_name.offset_left = -400.0
	nvl_name.offset_right = 400.0
	nvl_name.offset_top = 78.0
	nvl_name.offset_bottom = 118.0
	nvl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nvl_name.add_theme_font_size_override("font_size", 18)
	UiFont.apply_label(nvl_name)
	shake_host.add_child(nvl_name)
	nvl_body = Label.new()
	nvl_body.set_anchors_preset(Control.PRESET_CENTER)
	nvl_body.offset_left = -460.0
	nvl_body.offset_right = 460.0
	nvl_body.offset_top = -180.0
	nvl_body.offset_bottom = 200.0
	nvl_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nvl_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nvl_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nvl_body.add_theme_font_size_override("font_size", 26)
	nvl_body.add_theme_color_override("font_color", Color(0.96, 0.78, 0.7))
	UiFont.apply_label(nvl_body)
	nvl_body.pivot_offset = nvl_body.size * 0.5
	var sh := load("res://shaders/nvl_shake.gdshader")
	if sh:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		nvl_body.material = mat
	shake_host.add_child(nvl_body)
	nvl_hint = Label.new()
	nvl_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	nvl_hint.offset_left = -200.0
	nvl_hint.offset_right = 200.0
	nvl_hint.offset_top = -56.0
	nvl_hint.offset_bottom = -24.0
	nvl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nvl_hint.add_theme_font_size_override("font_size", 13)
	nvl_hint.add_theme_color_override("font_color", Color(0.7, 0.4, 0.38, 0.8))
	UiFont.apply_label(nvl_hint)
	nvl_root.add_child(nvl_hint)
	add_child(nvl_root)


func _build_pressure() -> void:
	pressure = Label.new()
	pressure.name = "Pressure"
	pressure.position = Vector2(28, 94)
	pressure.add_theme_font_size_override("font_size", 12)
	pressure.add_theme_color_override("font_color", Color(0.82, 0.22, 0.2, 0.9))
	pressure.visible = false
	UiFont.apply_label(pressure)
	add_child(pressure)


static func parse_text(text: String) -> Array:
	var out: Array = []
	for page in text.split("\n---\n", false):
		for block in _split_speakers(page.strip_edges()):
			if str(block.get("body", "")).strip_edges() != "":
				out.append(block)
	return out


static func _split_speakers(page: String) -> Array:
	var out: Array = []
	var speaker := ""
	var buf: PackedStringArray = PackedStringArray()
	for raw in page.split("\n"):
		var tagged := _match_speaker(raw)
		if tagged.size() == 2:
			if buf.size() > 0:
				out.append({"speaker": speaker, "body": "\n".join(buf).strip_edges()})
				buf = PackedStringArray()
			speaker = tagged[0]
			if tagged[1] != "":
				buf.append(tagged[1])
		else:
			buf.append(raw)
	if buf.size() > 0:
		out.append({"speaker": speaker, "body": "\n".join(buf).strip_edges()})
	return out


static func _match_speaker(line: String) -> PackedStringArray:
	for sep in ["：", ": "]:
		var idx := line.find(sep)
		if idx <= 0 or idx > 24:
			continue
		var head := line.substr(0, idx).strip_edges()
		if _speaker_key(head) == "":
			continue
		return PackedStringArray([head, line.substr(idx + sep.length()).strip_edges()])
	return PackedStringArray()


static func _speaker_key(raw: String) -> String:
	var trimmed := raw.strip_edges()
	if SPEAKER_KEYS.has(trimmed):
		return str(SPEAKER_KEYS[trimmed])
	var upper := trimmed.to_upper()
	if SPEAKER_KEYS.has(upper):
		return str(SPEAKER_KEYS[upper])
	var best := ""
	var best_len := 0
	for key in SPEAKER_KEYS.keys():
		var token := str(key)
		if (trimmed.begins_with(token) or upper.begins_with(token.to_upper())) and token.length() > best_len:
			best = str(SPEAKER_KEYS[key])
			best_len = token.length()
	return best


static func _speaker_color(key: String) -> Color:
	match key:
		"spk.mara":
			return Color(0.93, 0.78, 0.48)
		"spk.iris":
			return Color(0.95, 0.72, 0.68)
		"spk.dane":
			return Color(0.62, 0.78, 0.88)
		"spk.pell":
			return Color(0.62, 0.72, 0.42)
		"spk.inner":
			return Color(0.86, 0.58, 0.7)
		"spk.system":
			return Color(0.7, 0.68, 0.58)
		"spk.harrow":
			return Color(0.72, 0.64, 0.56)
	return Color(0.86, 0.8, 0.7)

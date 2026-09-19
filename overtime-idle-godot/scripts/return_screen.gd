class_name ReturnScreen
extends Overlay
## "While you were gone" — the game's single most important screen. Mirei, large, talking
## to you; the numbers roll in; the floors list what they made; COLLECT closes it.

signal collect
signal extend_cap

var portrait: TextureRect
var dur_label: Label
var say: RichTextLabel
var shifts_l: RollingLabel
var rent_l: RollingLabel
var rate_l: RollingLabel
var floors_box: VBoxContainer
var note: Label
var cap_btn: Button
var collect_btn: Button
var _rep: Dictionary = {}


func build() -> void:
	card_width = 900
	card.custom_minimum_size = Vector2(900, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	body.add_child(row)
	var left := PanelContainer.new()
	left.theme_type_variation = "Glass"
	left.custom_minimum_size = Vector2(300, 400)
	row.add_child(left)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.custom_minimum_size = Vector2(300, 400)
	left.add_child(portrait)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	var t := Label.new()
	t.text = "WHILE YOU WERE GONE"
	t.theme_type_variation = "Tag"
	t.add_theme_color_override("font_color", Palette.GOLD)
	right.add_child(t)
	dur_label = Label.new()
	dur_label.theme_type_variation = "Title"
	right.add_child(dur_label)
	var paper := PanelContainer.new()
	paper.theme_type_variation = "Paper"
	right.add_child(paper)
	say = StudioTheme.say_label(18)
	say.custom_minimum_size = Vector2(0, 54)
	paper.add_child(say)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	right.add_child(stats)
	shifts_l = _stat(stats, "SHIFTS")
	rent_l = _stat(stats, "RENT")
	rate_l = _stat(stats, "/ HOUR")
	floors_box = VBoxContainer.new()
	floors_box.add_theme_constant_override("separation", 2)
	right.add_child(floors_box)
	note = Label.new()
	note.add_theme_color_override("font_color", Palette.MUTED)
	note.add_theme_font_size_override("font_size", 13)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(note)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	right.add_child(btns)
	collect_btn = button("COLLECT", "Primary", func() -> void:
		collect.emit()
		close())
	collect_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(collect_btn)
	cap_btn = button("EXTEND TO 24 HOURS · 120 GOLD", "Amber", func() -> void: extend_cap.emit())
	cap_btn.visible = false
	btns.add_child(cap_btn)


func _stat(parent: Control, label: String) -> RollingLabel:
	var p := PanelContainer.new()
	p.theme_type_variation = "Card"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var l := Label.new()
	l.text = label
	l.theme_type_variation = "Tag"
	v.add_child(l)
	var n := RollingLabel.new()
	n.theme_type_variation = "Big"
	n.add_theme_font_size_override("font_size", 34)
	if label == "RENT":
		n.add_theme_color_override("font_color", Palette.GOLD)
	elif label == "/ HOUR":
		n.add_theme_color_override("font_color", Palette.HEAT)
	else:
		n.add_theme_color_override("font_color", Palette.TEXT)
	n.set_now(0)
	v.add_child(n)
	return n


static func fmt_dur(ms: int) -> String:
	var m := ms / 60000
	var h := m / 60
	var d := h / 24
	if d > 0:
		return "%d d %d h" % [d, h % 24]
	if h > 0:
		return "%d h %d min" % [h, m % 60]
	return "%d min" % m


func show_report(rep: Dictionary) -> void:
	_rep = rep
	portrait.texture = Look.portrait("pleased" if rep["evictions"].size() == 0 else "fail")
	dur_label.text = fmt_dur(int(rep["elapsed"]))
	var bark := Ticker.bark(rep)
	say.text = "[i]“" + bark + "”[/i]"
	say.visible_characters = 0
	shifts_l.set_now(0)
	rent_l.set_now(0)
	rate_l.set_now(0)
	clear(floors_box)
	for f in Ticker.B["floors"]:
		var h := HBoxContainer.new()
		var a := Label.new()
		a.text = "Floor %d" % int(f["n"])
		a.theme_type_variation = "Value"
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ev: bool = rep["evictions"].has(int(f["n"]))
		var b := Label.new()
		b.theme_type_variation = "Value"
		b.text = "EVICTED" if ev else "+" + str(int(rep["perFloor"].get(str(int(f["n"])), 0)))
		b.add_theme_font_override("font", Look.font_display)
		b.add_theme_color_override("font_color", Palette.HEAT if ev else Palette.GOLD)
		h.add_child(a)
		h.add_child(b)
		floors_box.add_child(h)
	if bool(rep["capped"]):
		note.text = "The building froze after %d h. Offline shifts stop at the cap — extend it once, for good." % (Economy.offline_cap_ms() / 3600000)
		cap_btn.visible = not Economy.is_owned("offline_cap_24h")
	else:
		note.text = ("Daily rent taken: %d" % int(rep["rentPaid"])) if int(rep["rentPaid"]) > 0 else ""
		cap_btn.visible = false
	open()
	var tw := create_tween()
	tw.tween_property(say, "visible_characters", bark.length() + 4, min(1.6, 0.02 * bark.length()))
	var hours: float = min(float(rep["elapsed"]), float(Economy.offline_cap_ms())) / 3600000.0
	var rate: float = (float(rep["rent"]) / hours) if int(rep["shifts"]) > 0 and hours > 0.0 else 0.0
	await get_tree().create_timer(0.25).timeout
	shifts_l.set_target(float(rep["shifts"]), 0.9)
	rent_l.set_target(float(rep["rent"]), 1.2)
	rate_l.set_target(rate, 1.0)

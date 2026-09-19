## Affection — a ladder you can see climbing. One row per character: portrait, then four
## rungs (1 / 3 / 6 / 10 wins) joined by a rail; earned rungs light and hold the plate's
## thumbnail (fetched from the backend, never in the package); the heart marker rises to
## the current count when the screen opens. Tier 4 is Blaze's own and a placeholder.
extends Control

var main: Node
var _list: VBoxContainer
var data := {}


func setup(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 14
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(StudioTheme.display_label("AFFECTION", 30, Palette.LAMP))
	var sub := StudioTheme.serif_label("Affection is the count of duels won against her. Plates unlock at 1, 3 and 6 wins; the fourth rung at 10 is a scene of Blaze's own and is a placeholder in this build. Nothing here unlocks from time.", 13, Palette.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_load()


func _load() -> void:
	var r := await Api.affection()
	if r.has("error"):
		main.toast(str(r["error"]))
		return
	data = r.get("affection", {})
	var i := 0
	for who in ["mara", "ines", "yuenha", "sanne", "teodora"]:
		if not data.has(who):
			continue
		_row(who, data[who], i)
		i += 1


func _row(who: String, a: Dictionary, index: int) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, Palette.LINE, 12, 1, Vector2(12, 8)))
	_list.add_child(row)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	var pw := Control.new()
	pw.custom_minimum_size = Vector2(72, 84)
	pw.clip_contents = true
	var img := TextureRect.new()
	img.texture = load("res://assets/portraits/%s.webp" % who)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.offset_bottom = 40
	pw.add_child(img)
	h.add_child(pw)
	var namebox := VBoxContainer.new()
	namebox.custom_minimum_size.x = 120
	namebox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	namebox.add_child(StudioTheme.display_label(str(a.get("name", who)), 20, Palette.PARCHMENT))
	namebox.add_child(StudioTheme.mono_label("♥ %d" % int(a.get("wins", 0)), 12, Palette.AMBER))
	h.add_child(namebox)
	var ladder := Ladder.new()
	ladder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ladder.custom_minimum_size.y = 84
	ladder.wins = int(a.get("wins", 0))
	ladder.rungs = a.get("ladder", [])
	ladder.rung_pressed.connect(func(key): _show(who, key))
	h.add_child(ladder)
	ladder.climb(0.15 * index)
	# thumbnails for earned plates
	for r in a.get("ladder", []):
		if r.get("earned", false) and not r.get("placeholder", false):
			_thumb(ladder, str(r.get("key", "")))


func _thumb(ladder: Ladder, key: String) -> void:
	var tex := await Api.plate_texture(key)
	if tex and is_instance_valid(ladder):
		ladder.set_thumb(key, tex)


func _show(who: String, key: String) -> void:
	Sfx.play("ui_click")
	var tex := await Api.plate_texture(key)
	if tex == null:
		main.toast("Plate not available.")
		return
	var sc := {}
	for s in main.state.get("scenarios", []):
		if s.get("who") == who:
			sc = s
	PlateView.open(self, tex, str(sc.get(key.substr(0, 3) + "_caption", "")), key.to_upper())


## The rail with four rungs. Custom-drawn; thumbnails are TextureRect children placed on
## the rungs. The heart marker tweens from 0 to `wins` on open.
class Ladder extends Control:
	signal rung_pressed(key: String)
	var wins := 0
	var rungs: Array = []
	var marker := 0.0
	var _thumbs := {}
	var _font: Font

	func _ready() -> void:
		_font = StudioTheme.font("mono")
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_place)

	func climb(delay: float) -> void:
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_method(func(v): marker = v; queue_redraw(), 0.0, float(wins), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	func _rung_x(i: int) -> float:
		return 90 + i * ((size.x - 180) / 3.0)

	## position along the rail for a win count (0 .. 10+)
	func _x_for(w: float) -> float:
		var ats := [0.0, 1.0, 3.0, 6.0, 10.0]
		var xs := [20.0, _rung_x(0), _rung_x(1), _rung_x(2), _rung_x(3)]
		for i in 4:
			if w <= ats[i + 1]:
				var t: float = (w - ats[i]) / (ats[i + 1] - ats[i])
				return lerpf(xs[i], xs[i + 1], t)
		return xs[4]

	func set_thumb(key: String, tex: Texture2D) -> void:
		for i in rungs.size():
			if rungs[i].get("key") == key:
				var t := TextureRect.new()
				t.texture = tex
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				t.size = Vector2(96, 56)
				t.mouse_filter = Control.MOUSE_FILTER_IGNORE
				t.modulate.a = 0.0
				add_child(t)
				_thumbs[key] = t
				_place()
				create_tween().tween_property(t, "modulate:a", 1.0, 0.3)

	func _place() -> void:
		for key in _thumbs:
			for i in rungs.size():
				if rungs[i].get("key") == key:
					_thumbs[key].position = Vector2(_rung_x(i) - 48, 4)
		queue_redraw()

	func _gui_input(ev: InputEvent) -> void:
		var pos: Vector2
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			pos = ev.position
		elif ev is InputEventScreenTouch and ev.pressed:
			pos = ev.position
		else:
			return
		for i in rungs.size():
			var r: Dictionary = rungs[i]
			if r.get("earned", false) and not r.get("placeholder", false) and abs(pos.x - _rung_x(i)) < 50 and pos.y < 64:
				rung_pressed.emit(str(r.get("key", "")))
				accept_event()
				return

	func _draw() -> void:
		var rail_y := 66.0
		draw_line(Vector2(20, rail_y), Vector2(size.x - 20, rail_y), Color("4a3c30"), 3.0)
		var lit_to := _x_for(minf(marker, 10.0))
		draw_line(Vector2(20, rail_y), Vector2(lit_to, rail_y), Palette.AMBER, 3.0)
		for i in rungs.size():
			var r: Dictionary = rungs[i]
			var x := _rung_x(i)
			var earned := bool(r.get("earned", false))
			var ph := bool(r.get("placeholder", false))
			var box := Rect2(x - 48, 4, 96, 56)
			draw_rect(box, Color("151020"), true)
			if ph:
				# dashed placeholder
				for k in range(0, 96, 8):
					draw_line(box.position + Vector2(k, 0), box.position + Vector2(k + 4, 0), Color("8a6a60"), 1.0)
					draw_line(box.position + Vector2(k, 56), box.position + Vector2(k + 4, 56), Color("8a6a60"), 1.0)
				draw_string(_font, box.position + Vector2(6, 24), "tier 4 · at 10", HORIZONTAL_ALIGNMENT_LEFT, 90, 8, Color("8a6a60"))
				draw_string(_font, box.position + Vector2(6, 38), "Blaze's own", HORIZONTAL_ALIGNMENT_LEFT, 90, 8, Color("8a6a60"))
			else:
				draw_rect(box, Palette.AMBER if earned else Color("3a2a44"), false, 1.5 if earned else 1.0)
				if not earned:
					draw_string(_font, box.position + Vector2(6, 24), "tier %d" % int(r.get("tier", i + 1)), HORIZONTAL_ALIGNMENT_LEFT, 90, 8, Color("5c5468"))
					draw_string(_font, box.position + Vector2(6, 38), "at %d wins" % int(r.get("at", 0)), HORIZONTAL_ALIGNMENT_LEFT, 90, 8, Color("5c5468"))
			# rung peg
			draw_circle(Vector2(x, rail_y), 5.0, Palette.AMBER if earned else Color("3a3026"))
			draw_string(_font, Vector2(x - 8, rail_y + 16), str(int(r.get("at", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.MUTED)
		# the heart marker
		var mx := _x_for(minf(marker, 10.0))
		draw_circle(Vector2(mx, rail_y), 7.0, Palette.LAMP)
		draw_string(_font, Vector2(mx - 4, rail_y + 4), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.INK)

extends Control
## 读心术 — the reader. A fortune-teller who tells you before you tell her: four forces
## (ReaderForces), each played as a scene — she is on screen, the room is lit, she
## speaks, there is a beat before the reveal — and then she gives something back.
## No typing, no clicking on the answer. The UI says once, lightly, that this is a
## performance (Fortune.seen_reader_note).

var teller: Teller
var say: RichTextLabel
var say_panel: PanelContainer
var controls: VBoxContainer
var table: Control
var dim: ColorRect
var force := ""
var step := 0
var answers: Array = []
var pair: Array = []
var pushed: Array = []
var revealed := false
var last_answer := ""
var _typing: Tween
var _script: Dictionary


func _ready() -> void:
	_script = Fortune.reader
	relayout()


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var bg := Backdrop.new()
	bg.mode = "reader"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	teller = Teller.new()
	teller.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	teller.offset_top = 70
	teller.offset_bottom = 640
	add_child(teller)
	table = Control.new()
	table.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	table.offset_top = 470
	table.offset_bottom = 720
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(table)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -560
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.offset_bottom = -26
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 14)
	add_child(bottom)
	say_panel = PanelContainer.new()
	say_panel.theme_type_variation = "Parchment"
	bottom.add_child(say_panel)
	say = RichTextLabel.new()
	say.bbcode_enabled = false
	say.fit_content = true
	say.scroll_active = false
	say.add_theme_font_override("normal_font", StudioTheme.font("italic" if Tx.lang == "en" else "serif"))
	say.add_theme_font_size_override("normal_font_size", 22)
	say.add_theme_color_override("default_color", Palette.PARCHMENT_INK)
	say.custom_minimum_size = Vector2(0, 60)
	say_panel.add_child(say)
	controls = VBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	bottom.add_child(controls)
	if force == "":
		_door()
	else:
		_render()


func _speak(text: String, then: Callable = Callable(), beat: float = 0.0) -> void:
	if _typing and _typing.is_valid():
		_typing.kill()
	say.text = text
	say.visible_ratio = 0.0
	var dur := clampf(text.length() * 0.028, 0.35, 2.2)
	_typing = create_tween()
	_typing.tween_property(say, "visible_ratio", 1.0, dur)
	if beat > 0.0:
		_typing.tween_interval(beat)
	if then.is_valid():
		_typing.tween_callback(then)


func _clear_controls() -> void:
	for c in controls.get_children():
		controls.remove_child(c)
		c.queue_free()
	for c in table.get_children():
		table.remove_child(c)
		c.queue_free()


func _btn(text: String, cb: Callable, variation: String = "Silver") -> Button:
	var b := StudioTheme.button(text, variation)
	b.custom_minimum_size = Vector2(200, 0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	controls.add_child(b)
	return b


func _row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	controls.add_child(h)
	return h


# ---- the door ----------------------------------------------------------------------------
func _door() -> void:
	_clear_controls()
	teller.mood = "waiting"
	if not Fortune.seen_reader_note:
		var note := StudioTheme.wrapped(Tx.pick(_script["note"]), 15, Palette.SILVER_DIM, "ui")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		controls.add_child(note)
	_speak(Tx.pick(_script["door"]))
	var pick := StudioTheme.label(Tx.t("reader.pick"), 15, Palette.CANDLE, "bold")
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(pick)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.add_child(grid)
	for k in ["binary", "math", "princess", "equivoque"]:
		var b := StudioTheme.button(Tx.pick(_script["forces"][k]["title"]), "Silver")
		b.custom_minimum_size = Vector2(300, 64)
		b.pressed.connect(func(): begin(k))
		grid.add_child(b)


func begin(k: String) -> void:
	force = k
	step = 0
	answers = []
	pair = []
	pushed = []
	revealed = false
	last_answer = ""
	Fortune.seen_reader_note = true
	Fortune.reader_plays += 1
	Fortune.save_state()
	teller.mood = "listening"
	_render()


func _f() -> Dictionary:
	return _script["forces"][force]


# ---- the scenes --------------------------------------------------------------------------
func _render() -> void:
	_clear_controls()
	match force:
		"binary": _binary()
		"math": _math()
		"princess": _princess()
		"equivoque": _equivoque()


func _next_btn(cb: Callable) -> void:
	_btn(Tx.t("reader.begin") if step == 0 else Tx.pick(_script["next"]), cb, "Candle")


func _binary() -> void:
	var f := _f()
	var intro: Array = f["intro"]
	if step < intro.size():
		_speak(Tx.pick(intro[step]))
		_next_btn(func():
			step += 1
			_render())
		return
	var k := step - intro.size()
	if k < 6:
		_speak(Tx.pick(f["ask"]))
		var card := NumberCard.new()
		card.numbers = ReaderForces.binary_card(k)
		card.custom_minimum_size = Vector2(560, 210)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		controls.add_child(card)
		var row := _row()
		for yes in [true, false]:
			var b := StudioTheme.button(Tx.pick(f["yes"] if yes else f["no"]), "Candle" if yes else "Silver")
			b.custom_minimum_size = Vector2(200, 0)
			b.pressed.connect(func():
				answers.append(yes)
				step += 1
				_render())
			row.add_child(b)
		return
	var n := ReaderForces.binary_result(answers)
	last_answer = str(n)
	_reveal(Tx.pick(f["reveal"]).replace("{n}", str(n)), f)


func _math() -> void:
	var f := _f()
	var intro: Array = f["intro"]
	var steps: Array = f["steps"]
	if step < intro.size():
		_speak(Tx.pick(intro[step]))
		_next_btn(func():
			step += 1
			_render())
		return
	var k := step - intro.size()
	if k < steps.size():
		_speak(Tx.pick(steps[k]))
		if k == steps.size() - 1:
			_symbol_table(-1)
		_btn(Tx.pick(f["done"]), func():
			step += 1
			_render(), "Candle")
		return
	last_answer = "lantern"
	_symbol_table(ReaderForces.MATH_ANSWER - 1)
	_reveal(Tx.pick(f["reveal"]), f)


func _symbol_table(lit: int) -> void:
	var f := _f()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.add_child(row)
	var syms: Array = f["symbols"]
	for i in range(syms.size()):
		var p := PanelContainer.new()
		p.theme_type_variation = "GlassWest"
		p.custom_minimum_size = Vector2(68, 74)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var num := StudioTheme.label(str(i + 1), 13, Palette.CANDLE if i == lit else Palette.SILVER_DIM, "bold")
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var nm := StudioTheme.label(Tx.pick(syms[i]).replace("the ", ""), 13, Palette.CANDLE if i == lit else Palette.SILVER, "ui")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(num)
		v.add_child(nm)
		p.add_child(v)
		if i == lit:
			p.add_theme_stylebox_override("panel", StudioTheme.glow(StudioTheme.flat(Palette.VIOLET_SOFT, Palette.CANDLE, 12, 1, Vector2(6, 6)), Palette.CANDLE, 16, 0.8))
		row.add_child(p)


func _cards_row(slugs: Array, up: bool, small: bool = false) -> Array:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.add_child(row)
	var out := []
	for s in slugs:
		var cv := CardView.new()
		cv.setup(s, false, up)
		cv.custom_minimum_size = Vector2(118, 190) if not small else Vector2(100, 160)
		row.add_child(cv)
		out.append(cv)
	return out


func _princess() -> void:
	var f := _f()
	match step:
		0:
			_speak(Tx.pick(f["intro"][0]))
			_cards_row(ReaderForces.PRINCESS_SHOW, true)
			_btn(Tx.pick(f["got"]), func():
				step = 1
				_render(), "Candle")
		1:
			_speak(Tx.pick(f["intro"][1]))
			_cards_row(ReaderForces.PRINCESS_SHOW, true)
			_btn(Tx.pick(f["got"]), func():
				step = 2
				_render(), "Candle")
		2:
			# The trick is in the pacing, so it is played as hands would play it: she turns
			# the five over one at a time, gathers them, deals four face down one at a time,
			# the room dims, she turns them one at a time, and there is a breath before the
			# line. Nothing here happens all at once.
			var cards := _cards_row(ReaderForces.PRINCESS_SHOW, true)
			_speak(Tx.pick(f["turn"]), func(): _princess_turn(cards, f), 0.3)


func _princess_turn(cards: Array, f: Dictionary) -> void:
	for cv in cards:
		cv.flip()
		await get_tree().create_timer(0.34).timeout
	await get_tree().create_timer(0.7).timeout
	_speak(Tx.pick(f["take"]), func(): _princess_take(cards, f), 0.7)


func _princess_take(cards: Array, f: Dictionary) -> void:
	# the face-down five gather into her hand: they draw together and go
	var tw := create_tween().set_parallel(true)
	for cv in cards:
		cv.pivot_offset = cv.size * 0.5
		tw.tween_property(cv, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(cv, "scale", Vector2(0.7, 0.7), 0.55).set_trans(Tween.TRANS_SINE)
	await tw.finished
	Sfx.flip()
	await get_tree().create_timer(0.45).timeout
	step = 3
	last_answer = "gone"
	_clear_controls()
	var dealt := _cards_row(ReaderForces.PRINCESS_AFTER, false)
	for cv in dealt:
		cv.modulate.a = 0.0
	_speak(Tx.pick(f["deal"]), func(): _princess_deal(dealt, f), 0.2)


func _princess_deal(dealt: Array, f: Dictionary) -> void:
	for cv in dealt:
		Sfx.flip()
		create_tween().tween_property(cv, "modulate:a", 1.0, 0.3)
		await get_tree().create_timer(0.36).timeout
	await get_tree().create_timer(0.5).timeout
	_princess_reveal(dealt, f)


func _princess_reveal(dealt: Array, f: Dictionary) -> void:
	for cv in dealt:
		cv.flip()
		await get_tree().create_timer(0.5).timeout
	# The breath: four faces up, none of them yours, and she lets you see that yourself
	# before she says it. Then the same dim-and-hold every other force uses — it used to
	# come *before* the cards turned, which put the hold in the middle of the deal instead
	# of in front of the line.
	await get_tree().create_timer(1.1).timeout
	_reveal(Tx.pick(f["reveal"]), f)


func _equivoque() -> void:
	var f := _f()
	var items: Array = f["items"]
	var ids: Array = items.map(func(x): return x["id"])
	match step:
		0, 1:
			_speak(Tx.pick(f["intro"][step]))
			_note_on_table(false)
			_lay_objects(ids, Callable())
			_next_btn(func():
				step += 1
				_render())
		2:
			_speak(Tx.pick(f["push"]))
			_note_on_table(false)
			_lay_objects(ids, func(id: String):
				if step != 2:
					return
				if id in pushed:
					pushed.erase(id)
				else:
					pushed.append(id)
				_refresh_objects()
				if pushed.size() == 2:
					var r := ReaderForces.equivoque_push(pushed)
					pair = r["pair"]
					step = 3
					_speak(Tx.pick(f[r["line"]]), func():
						step = 4
						_render(), 0.7))
		4:
			_speak(Tx.pick(f["hand"]))
			_note_on_table(false)
			_lay_objects(pair, func(id: String):
				if step != 4:
					return
				var r := ReaderForces.equivoque_hand(pair, id)
				last_answer = r["result"]
				step = 5
				_hand_over(id, func():
					_speak(Tx.pick(f[r["line"]]), func():
						step = 6
						_render(), 0.8)))
		6:
			teller.mood = "reveal"
			_speak(Tx.pick(f["open"]))
			_note_on_table(false)
			_btn(Tx.pick(f["open"]).rstrip("。."), func():
				step = 7
				_clear_controls()
				# The paper unfolds first and is allowed to be read on its own — it is in her
				# hand and dated before you reached out — and only then does the force take
				# the same beat line / dim-and-hold / spoken line the other three take.
				_note_on_table(true)
				_reveal(Tx.pick(f["reveal"]), f), "Candle")


## The folded note: "· · ·" while closed; opened, it shows what she wrote — in her hand,
## dated before you chose — which is not the line she speaks.
func _note_on_table(open: bool) -> void:
	var f := _f()
	var n := PanelContainer.new()
	n.theme_type_variation = "Parchment"
	n.custom_minimum_size = Vector2(220, 0)
	n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var written: String = Tx.pick(f.get("note_written", f["note_text"]))
	var l := StudioTheme.label(written if open else "· · ·", 20 if open else 18, Palette.PARCHMENT_INK if open else Palette.SILVER_DIM, ("italic" if Tx.lang == "en" else "serif") if open else "serif")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_child(l)
	if open:
		n.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(n, "modulate:a", 1.0, 0.6)
	controls.add_child(n)
	controls.move_child(n, 0)


# ---- the objects on the table --------------------------------------------------------------
## Four things on her cloth: the candle, the key, the coin, the feather. Drawn, not labelled
## buttons — you push one toward her (tap, or drag it up the table) and it slides to her side.
func _lay_objects(ids: Array, on_pick: Callable) -> void:
	var n := ids.size()
	var cx := table.size.x * 0.5 if table.size.x > 0 else 360.0
	for i in range(n):
		var o := TableObject.new()
		o.id = str(ids[i])
		var it: Array = _f()["items"].filter(func(x): return x["id"] == o.id)
		o.text = Tx.pick(it[0]) if it.size() > 0 else o.id
		o.size = Vector2(112, 96)
		o.rest = Vector2(cx + (i - (n - 1) * 0.5) * 140.0 - 56.0, 56.0)
		o.position = o.rest
		o.pushed = o.id in pushed
		o.enabled = on_pick.is_valid()
		if on_pick.is_valid():
			o.pressed.connect(func(): on_pick.call(o.id))
		table.add_child(o)


func _refresh_objects() -> void:
	for o in table.get_children():
		if o is TableObject:
			o.set_pushed(o.id in pushed)


func _hand_over(id: String, then: Callable) -> void:
	for o in table.get_children():
		if o is TableObject:
			o.enabled = false
			if o.id == id:
				o.lift_to(Vector2(table.size.x * 0.5 - 56.0, -40.0), then)


## The beat before a reveal: the room dims a shade, she goes still, a low hush, a hold.
## Every force passes through here, so the reveals share one rhythm.
func _beat(then: Callable) -> void:
	teller.mood = "reveal"
	Sfx.hush()
	var tw := create_tween()
	tw.tween_property(dim, "color:a", 0.38, 0.55)
	tw.tween_interval(1.0)
	tw.tween_property(dim, "color:a", 0.0, 0.7)
	tw.tween_callback(then)


## The one way a reveal arrives, and the only one: a half-line while she goes quiet, then
## _beat's dim-and-hold, then the line itself. All four forces end here — the Princess and
## the equivoque used to reach _reveal_line by their own routes, with the hold in a
## different place each time, so the four reveals did not share a rhythm.
func _reveal(line: String, f: Dictionary) -> void:
	var beats: Array = f.get("beat", [])
	var b := "…"
	if beats.size() > 0:
		b = Tx.pick(beats[Fortune.reader_plays % beats.size()])
	_speak(b, func():
		_beat(func(): _reveal_line(line, f)), 0.5)


func _reveal_line(line: String, f: Dictionary) -> void:
	revealed = true
	teller.mood = "reveal"
	Sfx.chime(1.25)
	teller.pulse()
	_speak(line, func():
		teller.mood = "warm"
		var gives: Array = f["give"]
		var g: Dictionary = gives[Fortune.reader_plays % gives.size()]
		var give := StudioTheme.wrapped(Tx.pick(g), 18, Palette.PARCHMENT, "italic" if Tx.lang == "en" else "serif")
		give.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var gp := PanelContainer.new()
		gp.theme_type_variation = "GlassWest"
		gp.add_child(give)
		gp.modulate.a = 0.0
		controls.add_child(gp)
		create_tween().tween_property(gp, "modulate:a", 1.0, 0.8)
		var row := _row()
		var again := StudioTheme.button(Tx.pick(_script["again"]), "Silver")
		again.pressed.connect(func():
			force = ""
			_door())
		row.add_child(again)
		var leave := StudioTheme.button(Tx.pick(_script["leave"]), "Candle")
		leave.pressed.connect(func(): get_parent().open("home"))
		row.add_child(leave), 1.1)


## Space / Enter / a tap on the dark of her room. She is a sequence of beats with one
## control live at a time, so "the obvious next thing" is literally the first live control
## -- which is what dev_cmd's `press` already means, reused rather than re-derived.
##
## When the reveal is on the table there is nothing further to press, so this returns
## false and the player is handed on to the rack.
func screen_advance() -> bool:
	if revealed:
		return false
	var btns := _buttons(controls) + _buttons(table)
	for b in btns:
		if b is Button and b.disabled:
			continue
		if b is TableObject and not b.enabled:
			continue
		b.pressed.emit()
		Sfx.bark("stage" if force != "" else "greet")
		return true
	return false


# ---- dev bridge --------------------------------------------------------------------------
func dev_state() -> Dictionary:
	return {"force": force, "step": step, "revealed": revealed, "answer": last_answer, "line": say.text, "sprite": teller.has_sprite() if teller else false}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	match str(cmd["op"]):
		"reader":
			begin(str(cmd.get("force", "binary")))
			return {"ok": true}
		"press":
			# press the i-th button in the controls (depth-first), as a player would
			var i := int(cmd.get("i", 0))
			var btns := _buttons(controls) + _buttons(table)
			if i < btns.size():
				btns[i].pressed.emit()
				return {"ok": true, "text": btns[i].text}
			return {"ok": false, "why": "no_button", "n": btns.size()}
		"buttons":
			return {"ok": true, "texts": (_buttons(controls) + _buttons(table)).map(func(b): return b.text)}
	return {"ok": false, "why": "unknown"}


func _buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Button or c is TableObject:
			out.append(c)
		out.append_array(_buttons(c))
	return out


## A card of numbers for the binary force.
class NumberCard extends Control:
	var numbers: Array = []

	func _draw() -> void:
		var sb := StudioTheme.flat(Palette.PARCHMENT, Palette.SILVER_DIM, 8, 1, Vector2.ZERO)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 12
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var f := StudioTheme.font("bold")
		var cols := 8
		var cw := (size.x - 24) / cols
		var rows := int(ceil(numbers.size() / float(cols)))
		var rh := (size.y - 20) / rows
		for i in range(numbers.size()):
			var x := 12 + (i % cols) * cw
			var y := 10 + int(i / cols) * rh
			var s := str(numbers[i])
			var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(f, Vector2(x + cw * 0.5 - w * 0.5, y + rh * 0.68), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.PARCHMENT_INK)


## One of the four things on her table. Drawn as the object (a stub of candle, a key, a
## 铜钱, a quill) with its name small beneath; tap it or drag it up the cloth to push it
## toward her. pressed fires once per push/unpush, like a button would, so the dev bridge
## can press it by name.
class TableObject extends Control:
	signal pressed
	var id := ""
	var text := ""
	var rest := Vector2.ZERO
	var pushed := false
	var enabled := true
	var _down := false
	var _drag := Vector2.ZERO
	var _dragged := false
	var _hover := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())

	func _process(dt: float) -> void:
		_t += dt
		if id == "candle" or _hover:
			queue_redraw()

	func set_pushed(on: bool) -> void:
		pushed = on
		var tw := create_tween()
		tw.tween_property(self, "position", rest + (Vector2(0, -52) if on else Vector2.ZERO), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		Sfx.flip()

	func lift_to(target: Vector2, then: Callable) -> void:
		Sfx.flip()
		var tw := create_tween()
		tw.tween_property(self, "position", target, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.55).set_delay(0.25)
		tw.tween_callback(then)

	func _gui_input(ev: InputEvent) -> void:
		if not enabled:
			return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_down = true
				_dragged = false
				_drag = ev.position
			elif _down:
				_down = false
				if _dragged:
					# dragged: up the table means pushed toward her, back down means not
					var dy := position.y - rest.y
					var want := dy < -26.0
					position = rest + (Vector2(0, -52) if pushed else Vector2.ZERO)
					if want != pushed:
						pressed.emit()
					else:
						create_tween().tween_property(self, "position", rest + (Vector2(0, -52) if pushed else Vector2.ZERO), 0.2)
				else:
					pressed.emit()
			accept_event()
		elif ev is InputEventMouseMotion and _down:
			var d: Vector2 = ev.position - _drag
			if _dragged or d.length() > 8.0:
				_dragged = true
				position.y = clampf(position.y + d.y, rest.y - 70.0, rest.y + 14.0)
			accept_event()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 40.0)
		# a soft shadow on the cloth, and the candle's edge when it is pushed or hovered
		draw_set_transform(Vector2(c.x, 70.0), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 40.0, Color(0, 0, 0, 0.35))
		if pushed or (_hover and enabled):
			draw_circle(Vector2.ZERO, 46.0, Color(Palette.CANDLE, 0.22 if pushed else 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var silver := Palette.SILVER
		var ink := Palette.VIOLET_DEEP
		match id:
			"candle":
				draw_rect(Rect2(c.x - 9, 30, 18, 38), Palette.PARCHMENT)
				draw_rect(Rect2(c.x - 15, 66, 30, 6), Palette.SILVER_DIM)
				var fl := Vector2(c.x + sin(_t * 12.0) * 1.2, 20)
				draw_circle(fl, 12.0, Color(Palette.CANDLE, 0.2))
				draw_circle(fl, 6.0, Palette.CANDLE)
				draw_circle(fl + Vector2(0, 2), 2.6, Palette.PARCHMENT)
			"key":
				draw_set_transform(c + Vector2(0, 10), -0.55, Vector2.ONE)
				draw_arc(Vector2(-24, 0), 11.0, 0, TAU, 24, silver, 4.0, true)
				draw_line(Vector2(-13, 0), Vector2(30, 0), silver, 4.0)
				draw_line(Vector2(30, 0), Vector2(30, 10), silver, 4.0)
				draw_line(Vector2(20, 0), Vector2(20, 8), silver, 4.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"coin":
				var cc := c + Vector2(0, 12)
				draw_circle(cc, 24.0, Palette.GOLD_DEEP)
				draw_circle(cc, 21.0, Palette.GOLD)
				draw_arc(cc, 22.5, 0, TAU, 40, Palette.GOLD_PALE, 1.2, true)
				draw_rect(Rect2(cc.x - 7, cc.y - 7, 14, 14), ink)
				draw_rect(Rect2(cc.x - 8, cc.y - 8, 16, 16), Palette.GOLD_DEEP, false, 1.0)
			"feather":
				var pts := PackedVector2Array()
				for k in range(16):
					var u := k / 15.0
					pts.append(c + Vector2(-30 + u * 62, 26 - u * 40 - sin(u * PI) * 12))
				draw_polyline(pts, Palette.SILVER_DIM, 2.0, true)
				for k in range(1, 13):
					var u := k / 13.0
					var base := c + Vector2(-30 + u * 62, 26 - u * 40 - sin(u * PI) * 12)
					var w := 14.0 * sin(u * PI) + 4.0
					draw_line(base, base + Vector2(-w * 0.5, -w), Color(silver, 0.85), 2.0)
					draw_line(base, base + Vector2(-w * 0.3, w * 0.9), Color(silver, 0.6), 1.6)
		var f := StudioTheme.font("ui")
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, Vector2(c.x - w * 0.5, 92), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Palette.CANDLE if pushed else Palette.SILVER, 0.9))


## The reader. If assets/reader/reader_<state>.webp exist she is the rendered portrait —
## breathing, the candle's flicker on her face, a crossfade between calm / reveal (eyes
## closed) / giveback (a small smile). Without them she is the drawn figure: a hood at a
## round table, a candle between you, her hands on the cloth. Either way the candle
## flickers and her mood moves the light: waiting, listening, reveal (lamp low), warm (up).
class Teller extends Control:
	const STATES := {"waiting": "calm", "listening": "calm", "reveal": "reveal", "warm": "giveback"}
	var mood := "waiting":
		set(v):
			if v == mood:
				return
			mood = v
			var want: Texture2D = _tex.get(STATES.get(v, "calm"))
			if want != _cur:
				_prev = _cur
				_cur = want
				_xfade = 0.0
	var _t := 0.0
	var _pulse := 0.0
	var _tex: Dictionary = {}
	var _cur: Texture2D
	var _prev: Texture2D
	var _xfade := 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for st in ["calm", "reveal", "giveback"]:
			var path := "res://assets/reader/reader_%s.webp" % st
			if ResourceLoader.exists(path):
				_tex[st] = load(path)
		_cur = _tex.get(STATES.get(mood, "calm"))

	func has_sprite() -> bool:
		return _cur != null

	func pulse() -> void:
		_pulse = 1.0

	func _process(dt: float) -> void:
		_t += dt
		_pulse = maxf(0.0, _pulse - dt * 0.8)
		_xfade = minf(1.0, _xfade + dt / 0.45)
		queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var flick := 1.0 + 0.05 * sin(_t * 11.0) + 0.03 * sin(_t * 27.0 + 1.0)
		var lamp := 1.0
		match mood:
			"reveal": lamp = 0.6
			"warm": lamp = 1.25
			"listening": lamp = 1.05
		lamp += _pulse * 0.8
		# the candle's light on the wall behind her
		for i in range(14, 0, -1):
			draw_circle(Vector2(cx, 330), 26.0 * i * flick, Color(Palette.CANDLE, 0.011 * lamp))
		var face_col := Color("D9B596").lerp(Color("4A3140"), 0.6 - 0.3 * lamp)
		if not _cur:
			_draw_figure(cx, lamp, face_col)
		# the table: an ellipse of dark cloth with a silver edge
		var tbl := PackedVector2Array()
		for i in range(64):
			var a := TAU * i / 64.0
			tbl.append(Vector2(cx + cos(a) * 300.0, 470 + sin(a) * 78.0))
		draw_colored_polygon(tbl, Color("1A1128"))
		draw_polyline(tbl + PackedVector2Array([tbl[0]]), Color(Palette.SILVER, 0.35), 2.0, true)
		if _cur:
			# she sits at the far side of the cloth: the portrait is drawn over the ellipse,
			# its own tabletop faded out by the installer so her hands rest on this one
			_draw_sprite(cx, lamp, flick)
		else:
			# her hands on the cloth
			for sx in [-1.0, 1.0]:
				var hx: float = cx + sx * 120.0
				draw_circle(Vector2(hx, 440), 22.0, face_col.darkened(0.1))
				draw_line(Vector2(hx, 440), Vector2(hx + sx * 40.0, 405), Color("221737"), 30.0)
		# the candle's pool of light on the cloth
		draw_set_transform(Vector2(cx, 462), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 150.0 * flick, Color(Palette.CANDLE, 0.06 * lamp))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the candle between you, on the near cloth, and its flame
		draw_rect(Rect2(cx - 9, 425, 18, 60), Palette.PARCHMENT)
		draw_rect(Rect2(cx - 16, 482, 32, 8), Palette.SILVER_DIM)
		var fl := Vector2(cx + sin(_t * 13.0) * 2.0, 410)
		draw_circle(fl, 16.0 * flick, Color(Palette.CANDLE, 0.25 * lamp))
		draw_circle(fl, 8.0 * flick, Palette.CANDLE)
		draw_circle(fl + Vector2(0, 3), 4.0, Palette.PARCHMENT)

	## The portrait: a 448x520 plate (tools/install_reader.py) standing on the cloth, its
	## base at the table's centre line so her hands land on the ellipse. She breathes (a slow
	## scale from the base), and the light on her is the candle's — the lamp level and the
	## flicker modulate the whole sprite between a cool dark and a warm lit, with a warm
	## bloom from the candle's side.
	func _draw_sprite(cx: float, lamp: float, flick: float) -> void:
		var breath := 1.0 + 0.009 * sin(_t * 1.35) + 0.003 * sin(_t * 2.9)
		var lit := clampf((lamp * flick - 0.5) / 0.8, 0.0, 1.0)
		var tint := Color(0.56, 0.5, 0.66).lerp(Color(1.0, 0.95, 0.88), lit)
		var base := Vector2(cx, 500.0)
		var rect := Rect2(Vector2(-224, -520), Vector2(448, 520))
		draw_set_transform(base, 0.0, Vector2(1.0 + (breath - 1.0) * 0.4, breath))
		if _prev and _xfade < 1.0:
			draw_texture_rect(_prev, rect, false, Color(tint, 1.0 - _xfade))
			draw_texture_rect(_cur, rect, false, Color(tint, _xfade))
		else:
			draw_texture_rect(_cur, rect, false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# the candle's bloom on her: low, warm, moving with the flame
		draw_circle(Vector2(cx, 300), 170.0 * flick, Color(Palette.CANDLE, 0.05 * lamp))
		draw_circle(Vector2(cx + sin(_t * 13.0) * 4.0, 380), 90.0 * flick, Color(Palette.CANDLE, 0.09 * lamp))

	## The drawn fallback, kept for any state whose texture is missing.
	func _draw_figure(cx: float, lamp: float, face_col: Color) -> void:
		# the cloak: a wide hooded shape
		var cloak := PackedVector2Array([Vector2(cx - 190, 470), Vector2(cx - 150, 300), Vector2(cx - 90, 210),
			Vector2(cx - 50, 130), Vector2(cx, 105), Vector2(cx + 50, 130), Vector2(cx + 90, 210),
			Vector2(cx + 150, 300), Vector2(cx + 190, 470)])
		draw_colored_polygon(cloak, Color("221737"))
		draw_polyline(cloak, Color(Palette.SILVER, 0.25), 2.0, true)
		# the hood's inner shadow and her face in it, lit from below by the candle
		var hood := PackedVector2Array([Vector2(cx - 62, 250), Vector2(cx - 48, 150), Vector2(cx, 122), Vector2(cx + 48, 150), Vector2(cx + 62, 250)])
		draw_colored_polygon(hood, Color("120B1E"))
		var face := PackedVector2Array()
		for i in range(40):
			var a := TAU * i / 40.0
			face.append(Vector2(cx + cos(a) * 34.0, 208 + sin(a) * 42.0))
		draw_colored_polygon(face, face_col)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 40, 150), Vector2(cx + 40, 150), Vector2(cx + 36, 196), Vector2(cx - 36, 196)]), Color("120B1E", 0.85))
		# eyes: closed on the reveal (she goes still), lowered otherwise
		var ink := Color("2A1A2E")
		for sx in [-1.0, 1.0]:
			var ex: float = cx + sx * 13.0
			if mood == "reveal":
				draw_arc(Vector2(ex, 202), 6.0, PI * 0.15, PI * 0.85, 10, ink, 1.6, true)
			else:
				draw_set_transform(Vector2(ex, 205), 0.0, Vector2(1.0, 0.55))
				draw_circle(Vector2.ZERO, 6.5, Color("F3E9D8", 0.85))
				draw_circle(Vector2(0, 1), 3.6, ink)
				draw_circle(Vector2(1.2, -0.6), 1.1, Color(Palette.CANDLE, 0.9))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(Vector2(cx, 226 if mood == "warm" else 230), 7.0, PI * 0.2, PI * 0.8, 8, Color("6A3A44"), 1.3, true)

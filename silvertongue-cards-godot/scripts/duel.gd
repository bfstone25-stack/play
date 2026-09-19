## Duel — the table. Her portrait left, the gauge / needs / speech panel right, the hand
## fanned along the bottom. Every number on this screen came back from /cards/play; the
## client animates it and never computes it.
extends Control

signal turn_resolved(response: Dictionary)

const PHASE_ORDER := {"guarded": 0, "engaged": 1, "wavering": 2, "breakthrough": 3}

var main: Node
var duel := {}
var scen := {}
var ended := false
var hand: Hand
var wild_input: LineEdit
var portrait: Portrait
var gauge: MomentumGauge
var _needs: HBoxContainer
var _goal: Label
var _brief: Label
var _turns: Label
var _turn_pips: Control
var _nerve_pips: Control
var _deck_left: Label
var _who: Label
var _speech: RichTextLabel
var _speech_panel: PanelContainer
var _wild_bar: PanelContainer
var _banner: Control
var _last_play := {}
var _type_tween: Tween
var _busy := false


func setup(args: Dictionary) -> void:
	if args.has("start"):
		var r: Dictionary = args["start"]
		duel = r.get("duel", {})
		scen = r.get("scen", {})
		_opening = str(r.get("opening", ""))
	else:
		duel = main.state.get("duel", {})
		scen = main.scenario(str(duel.get("scenario", "")))
		_opening = "(She is still waiting.)"

var _opening := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	portrait.show_character(str(scen.get("who", "mara")))
	_goal.text = str(scen.get("goal", ""))
	_brief.text = str(scen.get("story", ""))
	_say(str(scen.get("name", "")), _opening, "her", true)
	render(true)


# --- layout -----------------------------------------------------------------------------------
func _build() -> void:
	# HUD strip
	var hud := PanelContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_bottom = 60
	var hs := StudioTheme.flat(Color(Palette.PANEL_TOP, 0.92), Palette.ACCENT, 0, 0, Vector2(14, 6))
	hs.border_width_bottom = 1
	hs.border_width_left = 4
	hs.border_color = Palette.ACCENT
	hud.add_theme_stylebox_override("panel", hs)
	add_child(hud)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 16)
	hud.add_child(hrow)
	var goalbox := VBoxContainer.new()
	goalbox.add_theme_constant_override("separation", 0)
	goalbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_goal = StudioTheme.serif_label("", 17, Palette.TEXT, true)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goalbox.add_child(_goal)
	goalbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hrow.add_child(goalbox)
	var counters := VBoxContainer.new()
	counters.add_theme_constant_override("separation", 2)
	counters.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var c1 := HBoxContainer.new()
	_turns = StudioTheme.mono_label("TURNS 0/15", 11, Palette.MUTED)
	_turn_pips = Control.new()
	_turn_pips.custom_minimum_size = Vector2(150, 12)
	_turn_pips.draw.connect(_draw_turn_pips)
	c1.add_child(_turns)
	c1.add_child(_turn_pips)
	var c2 := HBoxContainer.new()
	var nl := StudioTheme.mono_label("NERVE", 11, Palette.MUTED)
	_nerve_pips = Control.new()
	_nerve_pips.custom_minimum_size = Vector2(46, 12)
	_nerve_pips.draw.connect(_draw_nerve_pips)
	_deck_left = StudioTheme.mono_label("DECK 15", 11, Palette.MUTED)
	c2.add_child(nl)
	c2.add_child(_nerve_pips)
	c2.add_child(_deck_left)
	counters.add_child(c1)
	counters.add_child(c2)
	hrow.add_child(counters)
	var leave := Button.new()
	leave.text = "LEAVE"
	leave.focus_mode = Control.FOCUS_NONE
	leave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	StudioTheme.style_button(leave, "quiet")
	leave.pressed.connect(func(): Sfx.play("ui_click"); leave_confirm())
	hrow.add_child(leave)

	# stage floor
	var stage := Panel.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top = 72
	stage.offset_bottom = -262
	stage.offset_left = 10
	stage.offset_right = -10
	stage.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.GROUND_DEEP, Palette.PANEL_EDGE, 12, 1, Vector2(0, 0)))
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	# portrait
	portrait = Portrait.new()
	portrait.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	portrait.offset_left = 11
	portrait.offset_right = 471
	portrait.offset_top = 73
	portrait.offset_bottom = -263
	add_child(portrait)

	# talk column
	var talk := VBoxContainer.new()
	talk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	talk.offset_left = 486
	talk.offset_right = -24
	talk.offset_top = 84
	talk.offset_bottom = -272
	talk.add_theme_constant_override("separation", 8)
	talk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(talk)
	var grow := HBoxContainer.new()
	grow.add_child(StudioTheme.mono_label("MOMENTUM", 10, Palette.MUTED))
	gauge = MomentumGauge.new()
	gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.add_child(gauge)
	talk.add_child(grow)
	_needs = HBoxContainer.new()
	_needs.add_theme_constant_override("separation", 6)
	talk.add_child(_needs)
	_speech_panel = PanelContainer.new()
	_speech_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_speech_panel.add_theme_stylebox_override("panel", _paper(Palette.PAPER))
	talk.add_child(_speech_panel)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	_speech_panel.add_child(sv)
	_who = StudioTheme.mono_label("", 10, Palette.INK_SOFT)
	sv.add_child(_who)
	_speech = RichTextLabel.new()
	_speech.bbcode_enabled = false
	_speech.fit_content = false
	_speech.scroll_active = false
	_speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_speech.add_theme_color_override("default_color", Palette.INK)
	_speech.add_theme_font_override("normal_font", StudioTheme.font("italic"))
	_speech.add_theme_font_size_override("normal_font_size", 22)
	_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sv.add_child(_speech)
	var scene_panel := PanelContainer.new()
	scene_panel.add_theme_stylebox_override("panel", StudioTheme.flat(Color(Palette.PANEL, 0.7), Palette.LINE_SOFT, 10, 1, Vector2(14, 8)))
	talk.add_child(scene_panel)
	_brief = StudioTheme.serif_label("", 13, Palette.MUTED)
	_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_brief.max_lines_visible = 3
	_brief.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	scene_panel.add_child(_brief)

	# hand
	hand = Hand.new()
	hand.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand.offset_top = -270
	hand.offset_bottom = 0
	hand.card_chosen.connect(_on_card_chosen)
	hand.wild_opened.connect(_on_wild_opened)
	hand.wild_closed.connect(_on_wild_closed)
	add_child(hand)

	# wild bar (over the hand)
	_wild_bar = PanelContainer.new()
	_wild_bar.add_theme_stylebox_override("panel", StudioTheme.glow(StudioTheme.flat(Color(Palette.PANEL, 0.96), Palette.ACCENT, 14, 1, Vector2(14, 10)), Palette.ACCENT, 14, 0.45))
	_wild_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_wild_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_wild_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_wild_bar.offset_bottom = -150
	_wild_bar.custom_minimum_size.x = 720
	_wild_bar.visible = false
	_wild_bar.z_index = 60
	add_child(_wild_bar)
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 8)
	_wild_bar.add_child(wrow)
	var wl := StudioTheme.mono_label("WILD", 11, Palette.GOLD)
	wl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrow.add_child(wl)
	wild_input = LineEdit.new()
	wild_input.placeholder_text = "Say it in your own words — the engine reads it, nobody else does"
	wild_input.max_length = 400
	wild_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wild_input.text_submitted.connect(func(_t): _submit_wild())
	wrow.add_child(wild_input)
	var say := Button.new()
	say.text = "SAY IT"
	say.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(say, "primary")
	say.pressed.connect(_submit_wild)
	wrow.add_child(say)
	var cancel := Button.new()
	cancel.text = "✕"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(func(): hand.cancel_wild())
	wrow.add_child(cancel)
	resized.connect(_on_resized)
	call_deferred("_on_resized")


func _on_resized() -> void:
	hand.set_table_target(_speech_panel.global_position + _speech_panel.size * 0.5)


func _draw_turn_pips() -> void:
	var n := int(duel.get("max_turns", 15))
	var used := int(duel.get("turns", 0))
	for i in n:
		var x := 4 + i * 9.0
		_turn_pips.draw_circle(Vector2(x, 6), 3.2, Palette.GOLD if i < used else Palette.LINE_STRONG)


func _draw_nerve_pips() -> void:
	var cap := int(duel.get("nerve_cap", 3))
	var have := int(duel.get("nerve", 1))
	for i in cap:
		var x := 6 + i * 14.0
		_nerve_pips.draw_circle(Vector2(x, 6), 4.5, Palette.HEAT if i < have else Palette.PANEL_RAISED)
		_nerve_pips.draw_arc(Vector2(x, 6), 4.5, 0, TAU, 16, Palette.HEAT, 1.0)


# --- render from the backend's view ----------------------------------------------------------
func render(instant: bool = false) -> void:
	if duel.is_empty():
		return
	var harms: Array = duel.get("harms", [])
	var closed: bool = not harms.is_empty() and not duel.get("won", false)
	portrait.set_phase(str(duel.get("phase", "guarded")), closed, instant)
	gauge.closed = closed
	if instant:
		gauge.snap(float(duel.get("momentum", 0.0)))
	else:
		gauge.animate_to(float(duel.get("momentum", 0.0)))
	_turns.text = "TURNS %d/%d" % [int(duel.get("turns", 0)), int(duel.get("max_turns", 15))]
	_turn_pips.queue_redraw()
	_nerve_pips.queue_redraw()
	_deck_left.text = "DECK %d" % int(duel.get("deck_left", 0))
	_render_needs(harms)
	hand.set_hand(duel.get("hand", []), int(duel.get("nerve", 1)), int(duel.get("wild_left", 0)))
	if duel.get("over", false):
		hand.lock()


func _render_needs(harms: Array) -> void:
	var ev := {}
	for e in duel.get("evidence", []):
		ev[str(e)] = true
	var needs: Dictionary = duel.get("needs", {})
	var wanted := []
	var paths: Array = needs.get("paths", [])
	if not paths.is_empty():
		for s in paths[0]:
			wanted.append([str(s), false])
	for s in needs.get("help", []):
		wanted.append([str(s), true])
	# keep chips across renders so a newly-lit one can swell
	var existing := {}
	for c in _needs.get_children():
		if c is Chip:
			existing[c.name] = c
	for w in wanted:
		var key: String = w[0]
		var help: bool = w[1]
		var text := ("+ " if help else "") + Palette.glyph(key) + " " + Palette.label(key)
		if existing.has(key):
			(existing[key] as Chip).set_lit(ev.has(key))
			existing.erase(key)
		else:
			var chip := Chip.make(text, ev.has(key), help, false, 11)
			chip.name = key
			_needs.add_child(chip)
	for h in harms:
		var hk := "harm_" + str(h)
		if existing.has(hk):
			existing.erase(hk)
		else:
			var chip := Chip.make("× %s — closed" % Palette.label(str(h)), false, false, true, 11)
			chip.name = hk
			_needs.add_child(chip)
	for k in existing:
		existing[k].queue_free()


## Warm paper at 92%, a hairline of gold.
func _paper(bg: Color) -> StyleBoxFlat:
	var s := StudioTheme.flat(Color(bg, Palette.PAPER_ALPHA), Color(Palette.GOLD, 0.5), 12, 1, Vector2(18, 12))
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 12
	return s


## `voice` = the line is spoken (hers, or the player's own typed words): Playfair Italic.
## A printed card line the player plays is read out in the UI face — it is the card's,
## not a voice.
func _say(who: String, text: String, style: String, instant: bool = false, voice: bool = true) -> void:
	_who.text = who.to_upper()
	var bg := Palette.PAPER
	if style == "player":
		bg = Palette.PAPER_PLAYER
	elif style == "gray":
		bg = Palette.PAPER_GRAY
	_speech_panel.add_theme_stylebox_override("panel", _paper(bg))
	_speech.add_theme_font_override("normal_font", StudioTheme.font("italic" if voice else "ui"))
	_speech.add_theme_font_size_override("normal_font_size", 22 if voice else 20)
	_speech.text = text
	if _type_tween:
		_type_tween.kill()
	if instant:
		_speech.visible_ratio = 1.0
		return
	_speech.visible_ratio = 0.0
	var secs := clampf(text.length() * 0.018, 0.25, 1.6)
	_type_tween = create_tween()
	_type_tween.tween_property(_speech, "visible_ratio", 1.0, secs)
	for i in int(secs / 0.09):
		get_tree().create_timer(i * 0.09).timeout.connect(func(): Sfx.play("type", -22.0))


# --- a turn -----------------------------------------------------------------------------------
func _on_card_chosen(id: String, text: String) -> void:
	_play_turn(id, text)


func _play_turn(id: String, text: String) -> void:
	if _busy or ended:
		return
	_busy = true
	main.busy = true
	var line := text
	if id != "wild":
		for c in duel.get("hand", []):
			if c.get("id") == id:
				line = str(c.get("line", ""))
	_say("You", line, "player", true, id == "wild")
	var r := await Api.play(id, text)
	_last_play = r
	if r.has("error"):
		main.toast(str(r["error"]))
		if r.has("duel"):
			duel = r["duel"]
			render(true)
		hand.unlock()
		_busy = false
		main.busy = false
		turn_resolved.emit(r)
		return
	var before := duel
	duel = r.get("duel", {})
	var read: Dictionary = r.get("read", {})
	# let the card land first
	await get_tree().create_timer(0.42).timeout
	portrait.react(1.0)
	var harmed: bool = not read.get("harms", []).is_empty()
	var pb := int(PHASE_ORDER.get(str(read.get("phase_before", "guarded")), 0))
	var pa := int(PHASE_ORDER.get(str(read.get("phase_after", "guarded")), 0))
	if harmed:
		Sfx.play("coerce")
	elif pa > pb:
		Sfx.play("phase_up")
	elif str(read.get("kind", "")) == "stale":
		Sfx.play("phase_down", -14.0)
	else:
		Sfx.play("reply")
	_say(str(scen.get("name", "")), str(r.get("reply", "")), "gray" if harmed else "her")
	render(false)
	if r.has("end"):
		ended = true
		hand.lock()
		await get_tree().create_timer(1.1).timeout
		_show_end(r)
	else:
		hand.unlock()
	_busy = false
	main.busy = false
	turn_resolved.emit(r)


## Driver entry: play by id through the hand's own state machine, await the turn.
func drive_play(id: String, text: String = "") -> Dictionary:
	if not hand.choose(id, text):
		return {"error": "cannot play %s (state %d, nerve %d)" % [id, hand.state, int(duel.get("nerve", 0))]}
	var r: Dictionary = await turn_resolved
	return r


func drive_wild_submit() -> Dictionary:
	if hand.state != Hand.State.WILD:
		return {"error": "wild not open"}
	if not hand.submit_wild(wild_input.text):
		return {"error": "empty line"}
	_wild_bar.visible = false
	var r: Dictionary = await turn_resolved
	return r


func _on_wild_opened() -> void:
	_wild_bar.visible = true
	wild_input.text = ""
	wild_input.grab_focus()


func _on_wild_closed() -> void:
	_wild_bar.visible = false


func _submit_wild() -> void:
	if hand.submit_wild(wild_input.text):
		_wild_bar.visible = false


# --- the end ----------------------------------------------------------------------------------
func _show_end(r: Dictionary) -> void:
	var e: Dictionary = r.get("end", {})
	var won := bool(e.get("won", false))
	var harmed := bool(e.get("harmed", false))
	Sfx.play("win" if won else "lose")
	_banner = Control.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.z_index = 70
	_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_banner)
	var dim := TextureRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.set_color(0, Color(Palette.PLUM, 0.94))
	g.set_color(1, Color(Palette.GROUND_DEEP, 0.97))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.4)
	gt.fill_to = Vector2(1.0, 0.4)
	dim.texture = gt
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(dim)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.custom_minimum_size.x = 640
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	_banner.add_child(col)
	var title := "PERSUADED" if won else ("CLOSED" if harmed else "OUT OF WORDS")
	var tl := StudioTheme.display_label(title, 60, Palette.GOLD if won else Palette.HEAT)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tl)
	# the word lands: over-size, then settles
	tl.pivot_offset = Vector2(320, 36)
	tl.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(tl, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sub := "in %d card%s" % [int(e.get("turns", 0)), "" if int(e.get("turns", 0)) == 1 else "s"]
	if not won:
		sub = "Coercion. She kept talking; nothing opened." if harmed else "The turns ran out."
	var sl := StudioTheme.serif_label(sub, 16, Palette.MUTED)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sl)
	if won:
		var rw: Dictionary = e.get("reward", {})
		var rrow := HBoxContainer.new()
		rrow.alignment = BoxContainer.ALIGNMENT_CENTER
		rrow.add_theme_constant_override("separation", 22)
		col.add_child(rrow)
		var stats := VBoxContainer.new()
		stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# the numbers count up in the display face: affection in coral, gold in gold
		stats.add_theme_constant_override("separation", 2)
		stats.add_child(StudioTheme.mono_label("♥ AFFECTION  (+%d)" % int(rw.get("affection_gain", 0)), 11, Palette.HEAT))
		var aff_n := _counter(Palette.HEAT)
		stats.add_child(aff_n)
		stats.add_child(StudioTheme.mono_label("◆ GOLD", 11, Palette.GOLD))
		var gold_n := _counter(Palette.GOLD)
		gold_n.prefix = "+"
		stats.add_child(gold_n)
		stats.add_child(StudioTheme.mono_label("DROP →", 11, Palette.MUTED))
		var ct := create_tween()
		ct.tween_interval(0.35)
		ct.tween_callback(func(): aff_n.set_target(float(int(rw.get("affection", 0))), 0.8))
		ct.tween_interval(0.25)
		ct.tween_callback(func(): gold_n.set_target(float(int(rw.get("gold", 0))), 0.9))
		rrow.add_child(stats)
		var drop := Card.new()
		drop.interactive = false
		drop.custom_minimum_size = Vector2(Card.W, Card.H)
		rrow.add_child(drop)
		drop.setup(rw.get("drop", {}), true)
		drop.set_face_down(true)
		_flip(drop, 0.5)
		Sfx.play("gold", -12.0)
		var pct := StudioTheme.mono_label("", 12, Palette.SUCCESS)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(pct)
		if e.get("daily", false):
			_daily_percentile(pct)
	var beat := StudioTheme.serif_label(str(e.get("beat", "")), 15, Palette.TEXT)
	beat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	beat.custom_minimum_size.x = 600
	col.add_child(beat)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 10)
	col.add_child(brow)
	var back := Button.new()
	back.text = "BACK TO THE BAR"
	back.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(back, "primary")
	back.pressed.connect(func(): Sfx.play("ui_click"); leave())
	brow.add_child(back)
	if won:
		var aff := Button.new()
		aff.text = "AFFECTION"
		aff.focus_mode = Control.FOCUS_NONE
		aff.pressed.connect(func(): Sfx.play("ui_click"); main.go("affection"))
		brow.add_child(aff)
		var keys: Array = e.get("reward", {}).get("cg_unlocked", [])
		if not keys.is_empty():
			var see := Button.new()
			see.text = "SEE THE PLATE"
			see.focus_mode = Control.FOCUS_NONE
			StudioTheme.style_button(see, "free")
			see.pressed.connect(func(): Sfx.play("ui_click"); _show_plate(str(keys[0])))
			brow.add_child(see)
	# The board: offered on an explicit press only, and only on the web (Gate no-ops
	# elsewhere). Never a popup, never a redirect — board.js draws in the page.
	if Gate.is_web():
		var more := Button.new()
		more.text = "MORE LIKE THIS"
		more.focus_mode = Control.FOCUS_NONE
		StudioTheme.style_button(more, "quiet")
		more.pressed.connect(func(): Sfx.play("board"); offer_board())
		brow.add_child(more)
	_banner.modulate.a = 0.0
	create_tween().tween_property(_banner, "modulate:a", 1.0, 0.4)


func _counter(color: Color) -> Counter:
	var n := Counter.new()
	n.add_theme_font_override("font", StudioTheme.font("display"))
	n.add_theme_font_size_override("font_size", 34)
	n.add_theme_color_override("font_color", color)
	n.set_now(0)
	return n


func _flip(c: Card, delay: float) -> void:
	c.pivot_offset = Vector2(Card.W / 2, Card.H / 2)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "scale:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		c.set_face_down(false)
		Sfx.play("flip")
		var rar := str(c.data.get("rarity", "common"))
		if rar == "epic":
			Sfx.play("epic")
		elif rar == "rare":
			Sfx.play("rare"))
	tw.tween_property(c, "scale:x", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "glow", 1.0, 0.25)
	tw.tween_property(c, "glow", 0.0, 1.2)


func _daily_percentile(label: Label) -> void:
	var d := await Api.daily()
	if d.has("percentile") and d["percentile"] != null:
		label.text = "You have beaten %d%% of players today." % int(d["percentile"])


func _show_plate(key: String) -> void:
	var tex := await Api.plate_texture(key)
	if tex == null:
		main.toast("Plate not available offline.")
		return
	var cap := str(scen.get(key.substr(0, 3) + "_caption", ""))
	PlateView.open(self, tex, cap, key.to_upper())


func offer_board() -> void:
	Gate.board_offer_more("adult")


func leave_confirm() -> void:
	if ended:
		leave()
		return
	# leaving a live duel forfeits it; the energy was spent when it started
	var r := await Api.forfeit()
	if not r.has("error"):
		leave()


func leave() -> void:
	main.refresh()
	main.go("home")

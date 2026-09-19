## The console: the op in progress.
##
## Everything the prototype's #screen-play had, laid out as an instrument panel rather than
## a web page. The rules are GCRules and nothing here decides anything — this reads
## `state.panel`, `state.hud`, `state.log` and `GCRules.roster_rows(state)` and draws them,
## which is precisely the split tests/run_tests.gd asserts against 300 recorded games.
##
## Layout, 1280×720:
##   head   op name and subtitle | the codebook card under the lamp | TIME / FF / SCORE
##   left   the live plot (plot_view.gd), on the console's own steel
##   right  the roster: five faces, clickable — pin a suspect, or name the ghost
##   bottom INCOMING: the speaker, the request, the line, and the three verdict keys
##   far right  the net log, newest first
##
## The one piece of sequencing that is not in the rules is the prototype's 650 ms beat
## between a verdict and the next voice. It lives here because it is presentation: the
## conformance test drives `resolve()` then `next_request()` back to back, and the beat is
## the console taking a breath.
extends Control

var main: Control

var state: Dictionary = {}
var _op_index := 0

var _plot: Control
var _log: VBoxContainer
var _log_scroll: ScrollContainer
var _roster_rows := []             # [{btn, portrait, name, status}]
var _head_name: Label
var _head_sub: Label
var _book: Label
var _book_note: Label
var _hud := {}
var _clock: ProgressBar
var _panel_who: Label
var _panel_type: Label
var _panel_body: RichTextLabel
var _panel_extra: Label
var _panel_face: Control
var _btn_auth: Button
var _btn_deny: Button
var _btn_q: Button
var _verdicts: HBoxContainer
var _names: HBoxContainer
var _labels := {}
var _tick := 0.0
var _busy := false                 # the 650 ms beat, or the op is over


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_process(true)


# ---- construction -------------------------------------------------------------------------
func _build() -> void:
	_build_head()
	_build_plot()
	_build_roster()
	_build_log()
	_build_panel()
	relocalise()


func _tag(text: String) -> Label:
	var l := StudioTheme.serif_label(text, 11, Palette.MUTED, true)
	return l


func _build_head() -> void:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "Glass"
	bar.position = Vector2(20, 14)
	bar.custom_minimum_size = Vector2(1240, 82)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	bar.add_child(row)

	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.custom_minimum_size = Vector2(300, 0)
	row.add_child(names)
	_head_name = StudioTheme.display_label("", 22, Palette.TEXT)
	names.add_child(_head_name)
	_head_sub = StudioTheme.mono_label("", 11, Palette.MUTED)
	names.add_child(_head_sub)

	# the codebook: the one warm surface on the console. A card under the lamp.
	var paper := PanelContainer.new()
	paper.theme_type_variation = "Paper"
	paper.custom_minimum_size = Vector2(420, 0)
	row.add_child(paper)
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 1)
	paper.add_child(pcol)
	_labels["todayCode"] = StudioTheme.serif_label("", 10, Palette.INK, true)
	pcol.add_child(_labels["todayCode"])
	_book = StudioTheme.mono_label("", 22, Palette.INK)
	pcol.add_child(_book)
	_book_note = StudioTheme.serif_label("", 10, Color(Palette.INK, 0.72))
	_book_note.custom_minimum_size = Vector2(400, 0)
	_book_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pcol.add_child(_book_note)

	var gauges := HBoxContainer.new()
	gauges.add_theme_constant_override("separation", 22)
	row.add_child(gauges)
	for key in ["time", "ff", "score"]:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		_labels[key] = _tag("")
		box.add_child(_labels[key])
		var v := StudioTheme.mono_label("0", 26, Palette.SUCCESS if key != "ff" else Palette.MUTED)
		box.add_child(v)
		_hud[key] = v
		gauges.add_child(box)

	_clock = ProgressBar.new()
	_clock.show_percentage = false
	_clock.position = Vector2(20, 98)
	_clock.custom_minimum_size = Vector2(1240, 3)
	_clock.size = Vector2(1240, 3)
	_clock.max_value = 1.0
	add_child(_clock)


func _build_plot() -> void:
	var box := PanelContainer.new()
	box.theme_type_variation = "Card"
	box.position = Vector2(20, 110)
	box.custom_minimum_size = Vector2(618, 388)
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	box.add_child(col)
	_labels["mapLabel"] = _tag("")
	col.add_child(_labels["mapLabel"])
	_plot = preload("res://scripts/plot_view.gd").new()
	_plot.custom_minimum_size = Vector2(586, 344)
	col.add_child(_plot)


func _build_roster() -> void:
	var box := PanelContainer.new()
	box.theme_type_variation = "Card"
	box.position = Vector2(650, 110)
	box.custom_minimum_size = Vector2(354, 388)
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	box.add_child(col)
	_labels["roster"] = _tag("")
	col.add_child(_labels["roster"])
	for i in range(GCRules.AGENTS.size()):
		var btn := Button.new()
		btn.theme_type_variation = "Ghost"
		btn.custom_minimum_size = Vector2(322, 62)
		btn.flat = true
		var idx := i
		btn.pressed.connect(func(): _roster_pressed(idx))
		col.add_child(btn)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(hb)
		var face := preload("res://scripts/portrait.gd").new()
		face.custom_minimum_size = Vector2(54, 58)
		hb.add_child(face)
		var meta := VBoxContainer.new()
		meta.add_theme_constant_override("separation", 0)
		hb.add_child(meta)
		var nm := StudioTheme.serif_label("", 16, Palette.TEXT, true)
		meta.add_child(nm)
		var st := StudioTheme.mono_label("", 11, Palette.MUTED)
		meta.add_child(st)
		var qt := StudioTheme.serif_label("", 12, Palette.DIM)
		qt.custom_minimum_size = Vector2(246, 0)
		qt.clip_text = true
		meta.add_child(qt)
		_roster_rows.append({"btn": btn, "face": face, "nm": nm, "st": st, "qt": qt})


func _build_log() -> void:
	var box := PanelContainer.new()
	box.theme_type_variation = "Card"
	box.position = Vector2(1016, 110)
	box.custom_minimum_size = Vector2(244, 590)
	box.size = Vector2(244, 590)
	# A ScrollContainer's minimum size still counts its child's, so a long net log grew the
	# panel down through the incoming panel instead of scrolling inside it. The panel is a
	# hole cut in the console: it is this size, and what does not fit is scrolled.
	box.clip_contents = true
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	box.add_child(col)
	_labels["logLabel"] = _tag("")
	col.add_child(_labels["logLabel"])
	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(212, 546)
	_log_scroll.size = Vector2(212, 546)
	_log_scroll.clip_contents = true
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_log_scroll)
	_log = VBoxContainer.new()
	_log.add_theme_constant_override("separation", 7)
	_log.custom_minimum_size = Vector2(208, 0)
	_log_scroll.add_child(_log)


func _build_panel() -> void:
	var box := PanelContainer.new()
	box.theme_type_variation = "Glass"
	box.position = Vector2(20, 508)
	box.custom_minimum_size = Vector2(984, 192)
	add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	_panel_face = preload("res://scripts/portrait.gd").new()
	_panel_face.custom_minimum_size = Vector2(120, 156)
	row.add_child(_panel_face)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.custom_minimum_size = Vector2(810, 0)
	row.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	_panel_who = StudioTheme.serif_label("", 17, Palette.ACCENT, true)
	head.add_child(_panel_who)
	_panel_type = StudioTheme.mono_label("", 12, Palette.MUTED)
	head.add_child(_panel_type)

	_panel_body = RichTextLabel.new()
	_panel_body.theme_type_variation = "Say"
	_panel_body.bbcode_enabled = true
	_panel_body.fit_content = true
	_panel_body.scroll_active = false
	_panel_body.custom_minimum_size = Vector2(806, 72)
	col.add_child(_panel_body)

	_panel_extra = StudioTheme.serif_label("", 13, Palette.GOLD)
	_panel_extra.custom_minimum_size = Vector2(806, 0)
	_panel_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_panel_extra)

	_verdicts = HBoxContainer.new()
	_verdicts.add_theme_constant_override("separation", 10)
	col.add_child(_verdicts)
	_btn_auth = _verdict_button("Primary", func(): _resolve("auth"))
	_btn_deny = _verdict_button("Alarm", func(): _resolve("deny"))
	_btn_q = _verdict_button("Amber", func(): _interrogate())

	_names = HBoxContainer.new()
	_names.add_theme_constant_override("separation", 6)
	_names.visible = false
	col.add_child(_names)
	for i in range(GCRules.AGENTS.size()):
		var b := Button.new()
		b.theme_type_variation = "Alarm"
		# five of these share the panel's width, and the names are player-visible strings in
		# two languages: fix the width and let the label clip rather than let one long name
		# push the fifth button off the console.
		b.custom_minimum_size = Vector2(154, 44)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 15)
		var idx := i
		b.pressed.connect(func(): _accuse(idx))
		_names.add_child(b)


func _verdict_button(variation: String, cb: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(250, 44)
	b.pressed.connect(func():
		Sfx.click()
		cb.call())
	_verdicts.add_child(b)
	return b


# ---- running an op ------------------------------------------------------------------------
func start_op(index: int) -> void:
	_op_index = index
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	state = GCRules.start_op(GCRules.OPS[index], func() -> float: return rng.randf(),
		Game.lang, Game.wins, Game.best.duplicate())
	state.on_tel = func(n: String, v: Dictionary): Game.tel(n, v)
	_plot.state = state
	_busy = false
	_tick = 0.0
	main.show_screen("play")
	_render_all()
	_announce()


## Everything the prototype re-rendered on every change.
func _render_all() -> void:
	if state.is_empty():
		return
	_head_name.text = str(state.opName)
	_head_sub.text = Game.t("opSub")
	_book.text = str(state.codebook)
	_book_note.text = str(state.note)
	_hud["time"].text = str(state.hud.time)
	_hud["ff"].text = str(state.hud.ff)
	_hud["ff"].add_theme_color_override("font_color",
		Palette.HEAT if int(state.ff) > 0 else Palette.MUTED)
	_hud["score"].text = str(state.hud.score)
	_clock.value = clampf(float(state.time) / float(state.op.time), 0.0, 1.0)
	_clock.get_theme_stylebox("fill").bg_color = (
		Palette.HEAT if state.time <= 20 else (Palette.GOLD if state.time <= 45 else Palette.ACCENT))
	_render_panel()
	_render_roster()
	_render_log()


func _render_panel() -> void:
	var p: Dictionary = state.panel
	_panel_who.text = str(p.who)
	_panel_type.text = str(p.type)
	_panel_body.text = str(p.body)
	_panel_extra.text = str(p.extra)
	var naming: bool = p.naming
	_verdicts.visible = not naming
	_names.visible = naming
	if naming:
		for i in range(_names.get_child_count()):
			var b: Button = _names.get_child(i)
			if i < p.name_btns.size():
				b.text = str(p.name_btns[i][0])
				b.disabled = bool(p.name_btns[i][1])
		_panel_who.add_theme_color_override("font_color", Palette.HEAT)
		# nobody is on the air in the naming round: an empty portrait frame would read as a
		# sixth person
		_panel_face.visible = false
	else:
		_panel_face.visible = true
		var locked: bool = p.locked
		_btn_auth.disabled = locked
		_btn_deny.disabled = locked
		_btn_q.disabled = locked
		if state.request != null:
			var a := GCRules.agent_by_id(state, str(state.request.speaker))
			_panel_who.add_theme_color_override("font_color", Palette.callsign(str(a.id)))
			_panel_face.setup(str(a.id), GCRules.who(state, a))
			_panel_face.live = not locked
			_panel_face.alive = true


func _render_roster() -> void:
	var rows := GCRules.roster_rows(state)
	for i in range(_roster_rows.size()):
		var r: Dictionary = _roster_rows[i]
		var a: Dictionary = state.agents[i]
		var row: Array = rows[i]
		r.face.setup(str(a.id), GCRules.who(state, a))
		r.face.alive = bool(a.alive)
		r.face.suspect = bool(a.suspect)
		r.face.live = state.request != null and str(state.request.speaker) == str(a.id)
		r.nm.text = str(row[1])
		r.nm.add_theme_color_override("font_color",
			Palette.callsign(str(a.id)) if a.alive else Palette.DIM)
		r.st.text = str(row[2])
		r.st.add_theme_color_override("font_color",
			Palette.HEAT if bool(a.suspect) or not bool(a.alive) else Palette.MUTED)
		r.qt.text = "「" + str(GCStrings.agent(Game.lang, str(a.id)).quote) + "」"
		r.btn.theme_type_variation = "Active" if state.awaitingName and a.alive else "Ghost"


func _render_log() -> void:
	for c in _log.get_children():
		c.queue_free()
	var n := 0
	for row in state.log:
		if n >= 16:
			break
		n += 1
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.custom_minimum_size = Vector2(202, 0)
		l.add_theme_font_override("normal_font", StudioTheme.font("ui"))
		l.add_theme_font_size_override("normal_font_size", 12)
		l.add_theme_color_override("default_color", Palette.log_color(str(row[0])))
		# the prototype's log strings carry HTML emphasis ("Today's code is <b>…</b>"), which
		# is literal text to a RichTextLabel. Translated, not stripped: the emphasis is the
		# point of the row. (tests/run_tests.gd compares the rows with the tags removed, so
		# this is view-only and cannot drift the conformance.)
		l.text = str(row[1]).replace("<b>", "[b]").replace("</b>", "[/b]")
		_log.add_child(l)
	_log_scroll.scroll_vertical = 0


# ---- the voice on the air ------------------------------------------------------------------
## The console reacting to a transmission: squelch, this channel's call-sign tone, the
## station's spill turning that colour, the noise floor lifting, and — when the bake is in
## the build — the person actually speaking.
func _announce() -> void:
	if state.is_empty() or state.request == null:
		return
	var req: Dictionary = state.request
	var a := GCRules.agent_by_id(state, str(req.speaker))
	Sfx.squelch_open()
	Sfx.callsign(float(a.freq))
	main.station.channel_live(Palette.callsign(str(a.id)))
	main.crt.set_floor(0.16)
	# a tell the player can *hear*: a borrowed tic is another person's words in this throat
	var borrowed := ""
	if req.tells.has("tic"):
		# the prototype appended "……<other's tic>." to the phrase; find whose it is
		for other in state.agents:
			if str(other.id) == str(a.id):
				continue
			if str(req.phrase).ends_with("……" + str(GCStrings.agent(state.lang, str(other.id)).tic) + "."):
				borrowed = str(other.id)
				break
	Voice.transmit(Game.lang, str(a.id), str(req.type), borrowed)


# ---- the verbs -----------------------------------------------------------------------------
func _resolve(choice: String) -> void:
	if _busy or state.is_empty() or state.ended or state.request == null:
		return
	var before_ff: int = int(state.ff)
	var before_book: String = str(state.codebook)
	var r := GCRules.resolve(state, choice)
	main.crt.set_floor(0.08)
	match str(r.cue):
		"auth": Sfx.auth()
		"deny": Sfx.deny()
		"warn": Sfx.warn()
	if int(state.ff) > before_ff or str(state.codebook) != before_book:
		main.crt.tear(true)          # the two moments that are supposed to hurt
	Sfx.squelch_close()
	_render_all()
	if state.ended:
		_finish()
		return
	if not bool(r.next):
		return
	_busy = true
	# the prototype's 650 ms beat between a verdict and the next voice
	await get_tree().create_timer(0.65).timeout
	if state.is_empty() or state.ended:
		return
	_busy = false
	GCRules.next_request(state)
	_render_all()
	if state.awaitingName:
		main.crt.tear(false)
		Sfx.warn()
	else:
		_announce()


func _interrogate() -> void:
	if _busy or state.is_empty() or state.ended or state.request == null:
		return
	var a := GCRules.agent_by_id(state, str(state.request.speaker))
	var failed := GCRules.interrogate(state)
	Sfx.click()
	Voice.say(Game.lang, str(a.id), "qfail" if failed else "qpass")
	if failed:
		Sfx.warn()
		main.crt.tear(false)
	_render_all()


func _roster_pressed(i: int) -> void:
	if state.is_empty() or state.ended:
		return
	Sfx.click()
	if state.awaitingName:
		_accuse(i)
		return
	state.agents[i].suspect = not state.agents[i].suspect
	_render_roster()


func _accuse(i: int) -> void:
	if state.is_empty() or state.ended or not state.awaitingName:
		return
	if not bool(state.agents[i].alive):
		Sfx.warn()
		return
	GCRules.accuse(state, str(state.agents[i].id))
	_render_all()
	_finish()


func _finish() -> void:
	_busy = true
	Voice.stop()
	Game.wins = int(state.wins)
	Game.best = state.best.duplicate()
	Game.persist()
	if bool(state.win):
		Sfx.win_sting()
	else:
		Sfx.warn()
		main.crt.tear(true)
	main.screens["debrief"].show_result(state, _op_index)


# ---- the clock -------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not visible or state.is_empty() or state.ended or _busy:
		return
	_tick += delta
	while _tick >= 1.0:
		_tick -= 1.0
		var was := int(state.time)
		GCRules.tick(state)
		if was > 10 and int(state.time) <= 10:
			main.crt.set_floor(0.2)
		_render_all()
		if state.ended:
			_finish()
			return


func on_key(k: InputEventKey) -> bool:
	if state.is_empty() or state.ended:
		return false
	if state.awaitingName:
		var n := k.keycode - KEY_1
		if n >= 0 and n < state.agents.size():
			_accuse(n)
			return true
		return false
	match k.keycode:
		KEY_A:
			_resolve("auth")
			return true
		KEY_D:
			_resolve("deny")
			return true
		KEY_Q:
			_interrogate()
			return true
	return false


func relocalise() -> void:
	for key in _labels:
		_labels[key].text = Game.t(key)
	_btn_auth.text = Game.t("auth")
	_btn_deny.text = Game.t("deny")
	_btn_q.text = Game.t("q")
	if not state.is_empty():
		GCRules.relocalise(state, Game.lang)
		_render_all()

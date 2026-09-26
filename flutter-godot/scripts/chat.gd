extends Control
class_name Chat

## PORT_PLAN.md step 1 — the chat loop: portrait, name, streaming reply, the affection
## bar, the mood badge, the chat log, the input row. This is "the game proper" the plan
## calls out as the 3-day, no-library piece, and it is the first thing built here.
##
## Talks to the same backend the HTML build does (Api.say_stream -> POST /say_stream),
## streamed rather than buffered — see scripts/api.gd for why plain HTTPRequest cannot
## do this. Editions (PORT_PLAN.md step 3) are ported: lang is Edition.content_set(), which
## means only the three en-langed routes (ethan, liam, adrian) are reachable through
## route_select.gd today, the same way the HTML build only shows a route once its
## `langs` matches the active edition. Chapters/choices/endings (the `_story` engine) and
## the memory archive are not ported either — see PUNCHLIST.md.

signal back()

const FONT_REG := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/WorkSans-Bold.ttf")
const FONT_CJK := preload("res://assets/fonts/wqy-microhei.ttc")
## Colour emoji for the route cards and portraits (🥃🔥🎸…), subset to the glyphs the cast
## and these scripts use (23 KB); without it they drew as tofu boxes.
const FONT_EMOJI := preload("res://assets/fonts/NotoColorEmoji-subset.ttf")
var _fonts := [FONT_REG, FONT_BOLD]

const ERROR_LINE := "(connection hiccup... try again?)"
const GREETINGS := {
	"ethan": "(looks up, one brow lifting) You made it.",
	"liam": "(easy grin) There you are. Long day?",
	"adrian": "(sets the guitar aside) I was wondering when you'd show.",
}
const MOOD_DEFAULT := "💗"  # 💗

var route: Dictionary = {}
var hist: Array = []
var aff: int = 0
var story_state: Dictionary = {}
## Story engine (PORT_PLAN.md step 6 + the _story engine): the chapter line under the header,
## the beat card, and the three overlays -- a choice, a chapter clear, an ending. What the
## backend returns is rendered exactly as index.html renders it; nothing is decided here.
var _chap: Label
var _overlay: Control
var story_done := false
var _pending_clear: Dictionary = {}
var busy := false
var _reply_bubble: RichTextLabel = null

var _name_label: Label
var _mood_label: Label
var _aff_bar: ProgressBar
var _aff_num: Label
var _portrait: Label
var _log_box: VBoxContainer
var _log_scroll: ScrollContainer
var _input: LineEdit
var _back_btn: ShapedButton
var _send_btn: ShapedButton
var _milestone: Label
var _milestone_timer: Timer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_wire_fonts()
	_build()


func _wire_fonts() -> void:
	for f in _fonts:
		var fb: Array = f.fallbacks.duplicate()
		if not fb.has(FONT_CJK):
			fb.append(FONT_CJK)
		if not fb.has(FONT_EMOJI):
			fb.append(FONT_EMOJI)
		f.fallbacks = fb


func _build() -> void:
	var hue := float(route.get("hue", 280)) / 360.0 if not route.is_empty() else 0.7

	var bg := ColorRect.new()
	bg.color = Color("#1c0a16")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.offset_left = 32
	root_vb.offset_right = -32
	root_vb.offset_top = 20
	root_vb.offset_bottom = -20
	root_vb.add_theme_constant_override("separation", 10)
	add_child(root_vb)

	# --- header: back, name, mood, affection ---------------------------------------------
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root_vb.add_child(header)
	_chap = Label.new()
	_chap.add_theme_font_override("font", FONT_REG)
	_chap.add_theme_font_size_override("font_size", 15)
	_chap.add_theme_color_override("font_color", Color(0.93, 0.84, 0.80, 0.9))
	_chap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chap.hide()
	root_vb.add_child(_chap)

	var back_btn := ShapedButton.new()
	back_btn.shape = ShapedButton.Shape.FOLD
	back_btn.compact = true
	back_btn.custom_minimum_size = Vector2(96, 32)
	back_btn.tint = Color.from_hsv(hue, 0.4, 0.30)
	back_btn.ink = Color(0.97, 0.93, 0.89)
	back_btn.add_theme_font_override("font", FONT_REG)
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.label = "< " + Edition.ui("back", "back")
	back_btn.pressed.connect(func(): back.emit())
	header.add_child(back_btn)
	_back_btn = back_btn

	_name_label = Label.new()
	_name_label.add_theme_font_override("font", FONT_BOLD)
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", Color(0.97, 0.93, 0.89))
	header.add_child(_name_label)

	var aff_col := VBoxContainer.new()
	aff_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aff_col.add_theme_constant_override("separation", 2)
	header.add_child(aff_col)

	_aff_num = Label.new()
	_aff_num.add_theme_font_override("font", FONT_REG)
	_aff_num.add_theme_font_size_override("font_size", 12)
	_aff_num.add_theme_color_override("font_color", Color(0.85, 0.78, 0.74))
	_aff_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	aff_col.add_child(_aff_num)

	_aff_bar = ProgressBar.new()
	_aff_bar.min_value = 0
	_aff_bar.max_value = 100
	_aff_bar.show_percentage = false
	_aff_bar.custom_minimum_size = Vector2(0, 8)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color.from_hsv(hue, 0.55, 0.85)
	fg.set_corner_radius_all(4)
	_aff_bar.add_theme_stylebox_override("fill", fg)
	var bgsb := StyleBoxFlat.new()
	bgsb.bg_color = Color(0, 0, 0, 0.35)
	bgsb.set_corner_radius_all(4)
	_aff_bar.add_theme_stylebox_override("background", bgsb)
	aff_col.add_child(_aff_bar)

	_mood_label = Label.new()
	_mood_label.text = MOOD_DEFAULT
	_mood_label.add_theme_font_override("font", FONT_REG)   # carries the emoji fallback
	_mood_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_mood_label)

	# --- portrait -------------------------------------------------------------------------
	var portrait_wrap := CenterContainer.new()
	portrait_wrap.custom_minimum_size = Vector2(0, 130)
	root_vb.add_child(portrait_wrap)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(110, 110)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color.from_hsv(hue, 0.4, 0.24)
	psb.border_color = Color.from_hsv(hue, 0.5, 0.6)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(55)
	portrait_panel.add_theme_stylebox_override("panel", psb)
	portrait_wrap.add_child(portrait_panel)

	_portrait = Label.new()
	_portrait.text = str(route.get("emoji", "✦"))
	_portrait.add_theme_font_override("font", FONT_REG)   # carries the emoji fallback
	_portrait.add_theme_font_size_override("font_size", 48)
	_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_panel.add_child(_portrait)

	# --- chat log --------------------------------------------------------------------------
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vb.add_child(_log_scroll)

	_log_box = VBoxContainer.new()
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_box.add_theme_constant_override("separation", 10)
	_log_scroll.add_child(_log_box)

	# --- input row ---------------------------------------------------------------------------
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root_vb.add_child(row)

	_input = LineEdit.new()
	_input.placeholder_text = Edition.ui("ph", "say something...")
	_input.add_theme_font_override("font", FONT_REG)
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(func(_t): _send())
	row.add_child(_input)

	_send_btn = ShapedButton.new()
	_send_btn.shape = ShapedButton.Shape.FOLD
	_send_btn.compact = true
	_send_btn.custom_minimum_size = Vector2(52, 40)
	_send_btn.tint = Color.from_hsv(hue, 0.5, 0.5)
	_send_btn.ink = Color(0.98, 0.93, 0.95)
	_send_btn.add_theme_font_size_override("font_size", 16)
	_send_btn.label = "♡"
	_send_btn.pressed.connect(_send)
	row.add_child(_send_btn)

	# --- milestone toast ---------------------------------------------------------------------
	_milestone = Label.new()
	_milestone.hide()
	_milestone.add_theme_font_override("font", FONT_BOLD)
	_milestone.add_theme_font_size_override("font_size", 30)
	_milestone.add_theme_color_override("font_color", Color.from_hsv(hue, 0.5, 0.95))
	_milestone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milestone.set_anchors_preset(Control.PRESET_CENTER)
	_milestone.offset_left = -220
	_milestone.offset_right = 220
	add_child(_milestone)

	_milestone_timer = Timer.new()
	_milestone_timer.one_shot = true
	_milestone_timer.wait_time = 1.8
	_milestone_timer.timeout.connect(func(): _milestone.hide())
	add_child(_milestone_timer)


## Enter (or re-enter) a route's conversation. Mirrors index.html:startRoute() — restores
## the saved thread if there is one, shows a reunion line that is NOT added to history if
## so, otherwise the scripted first-meeting line that IS.
func start(r: Dictionary) -> void:
	route = r
	_name_label.text = str(r.get("name", "?"))
	_portrait.text = str(r.get("emoji", "✦"))
	var hue := float(r.get("hue", 280)) / 360.0
	(_aff_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color.from_hsv(hue, 0.55, 0.85)
	(_portrait.get_parent().get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color.from_hsv(hue, 0.4, 0.24)
	_back_btn.tint = Color.from_hsv(hue, 0.4, 0.30)
	_back_btn.queue_redraw()
	_send_btn.tint = Color.from_hsv(hue, 0.5, 0.5)
	_send_btn.queue_redraw()

	_load_saved()
	for c in _log_box.get_children():
		c.queue_free()
	var greeting: String = GREETINGS.get(r.get("id", ""), "...")
	if hist.size() > 0:
		for m in hist:
			_add_bubble(str(m.get("content", "")), m.get("role", "") == "user")
		_add_bubble(greeting, false)
	else:
		_add_bubble(greeting, false)
	_update_affection_ui()
	_input.grab_focus()


## QA-only: drive a real send() without a mouse, for main.gd's --goto=chat --say= hook.
## Nothing in the game calls this.
func debug_send(text: String) -> void:
	_input.text = text
	_send()


func _send() -> void:
	if busy:
		return
	var msg := _input.text.strip_edges()
	if msg == "":
		return
	_input.text = ""
	busy = true
	_send_btn.disabled = true
	_add_bubble(msg, true)
	var payload := {
		"route": route.get("id", ""),
		# duplicated, not the live array — hist.append() below must not retroactively
		# mutate the request we are about to send (GDScript Arrays are references).
		"history": hist.duplicate(true),
		"memory": "",
		"message": msg,
		"affection": aff,
		"lang": Edition.content_set(),
		"pid": Api.pid,
		"story_state": story_state,
	}
	hist.append({"role": "user", "content": msg})
	_reply_bubble = null
	var result: Dictionary = await Api.say_stream(payload, _on_token)
	busy = false
	_send_btn.disabled = false
	if not is_inside_tree():
		return
	if result.has("error"):
		# Matches index.html:say()'s catch — the user's turn stays in hist even though
		# it got no reply, so the next message still carries that context.
		if _reply_bubble == null:
			_add_bubble(ERROR_LINE, false)
		else:
			_reply_bubble.text = ERROR_LINE
		return
	var reply := str(result.get("reply", ""))
	hist.append({"role": "assistant", "content": reply})
	if _reply_bubble == null:
		_add_bubble(reply, false)
	else:
		_reply_bubble.text = reply
	aff = int(result.get("affection", aff))
	_mood_label.text = str(result.get("mood", MOOD_DEFAULT))
	_update_affection_ui()
	Tel.chat(msg, reply, {"route": route.get("id", ""), "aff": aff})   # = index.html:1725
	if result.has("story_state") and result["story_state"] is Dictionary:
		story_state = result["story_state"]
	var milestone = result.get("milestone")
	if milestone != null and str(milestone) != "":
		_show_milestone(str(milestone))
	_apply_story(result)
	_save()


func _on_token(tok: String) -> void:
	if _reply_bubble == null:
		_reply_bubble = _add_bubble("", false)
	_reply_bubble.text += tok
	_scroll_to_bottom()


func _add_bubble(text: String, mine: bool) -> RichTextLabel:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bubble := RichTextLabel.new()
	bubble.bbcode_enabled = false
	bubble.text = text
	bubble.fit_content = true
	bubble.scroll_active = false
	bubble.add_theme_font_override("normal_font", FONT_REG)
	bubble.add_theme_font_size_override("normal_font_size", 15)
	bubble.custom_minimum_size = Vector2(280, 0)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if mine:
		sb.bg_color = Color(0.42, 0.16, 0.28)
		bubble.add_theme_color_override("default_color", Color(0.98, 0.93, 0.95))
	else:
		sb.bg_color = Color(0.16, 0.14, 0.22)
		bubble.add_theme_color_override("default_color", Color(0.92, 0.90, 0.96))
	bubble.add_theme_stylebox_override("normal", sb)
	if mine:
		row.add_child(spacer)
		row.add_child(bubble)
	else:
		row.add_child(bubble)
		row.add_child(spacer)
	_log_box.add_child(row)
	_scroll_to_bottom()
	return bubble


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _update_affection_ui() -> void:
	_aff_bar.value = aff
	_aff_num.text = "%d / 100" % aff


func _show_milestone(text: String) -> void:
	_milestone.text = text
	_milestone.show()
	_milestone_timer.start()


# --- persistence: user://flutter_saves/<route id>.json, mirrors index.html:save() -----------
func _save_path() -> String:
	return "user://flutter_saves/%s.json" % route.get("id", "unknown")


func _save() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("flutter_saves"):
		dir.make_dir("flutter_saves")
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f == null:
		return
	var trimmed: Array = hist.slice(max(0, hist.size() - 24), hist.size())
	f.store_string(JSON.stringify({"hist": trimmed, "aff": aff, "story_state": story_state}))
	f.close()


func _load_saved() -> void:
	hist = []
	aff = 0
	story_state = {}
	if not FileAccess.file_exists(_save_path()):
		return
	var f := FileAccess.open(_save_path(), FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.get("hist") is Array:
		hist = parsed["hist"]
	aff = int(parsed.get("aff", 0))
	if parsed.get("story_state") is Dictionary:
		story_state = parsed["story_state"]


# --- story engine --------------------------------------------------------------------------
## index.html say(): story -> chapter card, attach -> icon, beat -> card, story.choice -> the
## choice overlay (after the beat has had its moment).
func _apply_story(r: Dictionary) -> void:
	if r.get("story") is Dictionary:
		_render_chapter(r["story"])
	if r.get("attach") is Dictionary:
		var t := str(r["attach"].get("type", ""))
		if Edition.attach_icons.has(t):
			_mood_label.text = str(Edition.attach_icons[t]) + " " + _mood_label.text
	if str(r.get("beat", "")) != "":
		_show_beat(str(r["beat"]))
	if r.get("story") is Dictionary and r["story"].get("choice") is Dictionary and not story_done:
		var choice: Dictionary = r["story"]["choice"]
		get_tree().create_timer(2.4 if str(r.get("beat", "")) != "" else 1.2).timeout.connect(func(): _show_choice(choice))


func _render_chapter(s: Dictionary) -> void:
	var idx := int(s.get("chapter_index", 0))
	if idx <= 0:
		_chap.hide()
		return
	var head := ("第%d章" if Edition.current in ["zh", "ja"] else "Ch. %d") % idx
	var title := Edition.field(s, "title")
	var goal := Edition.field(s, "goal")
	_chap.text = "%s / %d   %s%s" % [head, int(s.get("chapter_total", 0)), title, ("   ·   " + goal) if goal != "" else ""]
	_chap.show()


func _show_beat(txt: String) -> void:
	var b := _add_bubble("◈ " + txt, false)
	b.modulate = Color(1.0, 0.86, 0.9, 1.0)
	get_tree().create_timer(7.0).timeout.connect(func():
		if is_instance_valid(b):
			var tw := b.create_tween()
			tw.tween_property(b, "modulate:a", 0.0, 0.6)
			tw.tween_callback(b.queue_free))


func _open_overlay() -> VBoxContainer:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.04, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2a1422")
	sb.border_color = Color("#d59a82")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(26)
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(520, 0)
	card.position = Vector2(-260, -180)
	_overlay.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card.add_child(vb)
	return vb


func _close_overlay() -> void:
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _card_label(vb: VBoxContainer, text: String, size: int, bold := false) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.97, 0.93, 0.89))
	vb.add_child(l)


func _card_button(vb: VBoxContainer, text: String, cb: Callable) -> void:
	var b := ShapedButton.new()
	b.shape = ShapedButton.Shape.CARD
	b.tint = Color("#572033")
	b.ink = Color(0.98, 0.93, 0.95)
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_override("font", FONT_BOLD)
	b.label = text
	b.pressed.connect(cb)
	vb.add_child(b)


## The end-of-chapter choice. index.html pickChoice(): the chosen line goes into the history
## as the player's turn, then /choose answers with reply/affection/chapter_clear/ending.
func _show_choice(c: Dictionary) -> void:
	var vb := _open_overlay()
	_card_label(vb, str(c.get("prompt", "")), 20, true)
	for o in c.get("options", []):
		var opt: Dictionary = o
		_card_button(vb, str(opt.get("text", "")), func(): _pick_choice(c, opt))


func _pick_choice(c: Dictionary, opt: Dictionary) -> void:
	_close_overlay()
	var text := str(opt.get("text", ""))
	hist.append({"role": "user", "content": text})
	_add_bubble(text, true)
	var r := await Api.post_json("/choose", {"route": route.get("id", ""), "chapter": c.get("chapter"),
		"choice": c.get("id"), "option": int(opt.get("index", 0)), "affection": aff,
		"story_state": story_state, "lang": Edition.content_set()})
	if r.has("error"):
		_add_bubble(ERROR_LINE, false)
		return
	if r.get("story_state") is Dictionary:
		story_state = r["story_state"]
	if r.has("affection"):
		aff = int(r["affection"])
		_update_affection_ui()
	if str(r.get("reply", "")) != "":
		hist.append({"role": "assistant", "content": str(r["reply"])})
		_add_bubble(str(r["reply"]), false)
	_save()
	if r.get("chapter_clear") is Dictionary:
		_pending_clear = r["chapter_clear"]
		get_tree().create_timer(0.9).timeout.connect(func(): _show_chapter_clear(_pending_clear))
	if r.get("ending") is Dictionary:
		var end: Dictionary = r["ending"]
		get_tree().create_timer(1.4).timeout.connect(func(): _show_ending(end))


func _show_chapter_clear(clear: Dictionary) -> void:
	var reward: Dictionary = clear.get("reward", {}) if clear.get("reward") is Dictionary else {}
	Archive.collect("reward", reward if not reward.is_empty() else {"title": str(clear.get("title", ""))})
	var vb := _open_overlay()
	_card_label(vb, "%s · %d/%d" % [Edition.story("chapter", "CHAPTER COMPLETE"), int(clear.get("chapter_index", 0)), int(clear.get("chapter_total", 0))], 14)
	_card_label(vb, str(clear.get("title", "")), 24, true)
	_card_label(vb, "%s · %s" % [Edition.story("reward", "MEMORY UNLOCKED"), str(reward.get("kind", "memory")).to_upper()], 13)
	_card_label(vb, str(reward.get("title", "")), 18, true)
	_card_label(vb, str(reward.get("text", "")), 16)
	_card_button(vb, Edition.story("next", "ENTER NEXT CHAPTER"), _continue_chapter)


## index.html continueChapter(): chapter 1 is free, every later chapter is behind the gate
## (ops/DUAL_TRACK.md). On a desktop download Gate.require() says yes without asking.
func _continue_chapter() -> void:
	var next_idx := int(_pending_clear.get("chapter_index", 1)) + 1
	if next_idx >= 2 and not await Gate.require("ch%d" % next_idx, "Chapter %d" % next_idx, "chapter"):
		return
	var r := await Api.post_json("/continue", {"route": route.get("id", ""), "story_state": story_state,
		"lang": Edition.content_set()})
	if r.has("error"):
		return
	if r.get("story_state") is Dictionary:
		story_state = r["story_state"]
	_pending_clear = {}
	_save()
	_close_overlay()
	if r.get("story") is Dictionary:
		_render_chapter(r["story"])
	if str(r.get("opening", "")) != "":
		hist.append({"role": "assistant", "content": str(r["opening"])})
		_add_bubble(str(r["opening"]), false)


## index.html showEnding(): the run is over, so this is where the rest of the catalogue is
## offered -- board.js through the bridge, which refuses the adult board where it is not
## allowed.
func _show_ending(end: Dictionary) -> void:
	story_done = true
	Archive.collect("ending", end)
	var label: String = {"zh": "结 局", "en": "ENDING", "ja": "結 末", "es": "FINAL", "pt-BR": "FINAL"}.get(Edition.current, "ENDING")
	var vb := _open_overlay()
	_card_label(vb, label, 14)
	_card_label(vb, str(end.get("title", "")), 24, true)
	_card_label(vb, str(end.get("text", "")), 16)
	_card_button(vb, Edition.ui("back", "back"), func():
		_close_overlay()
		back.emit())
	get_tree().create_timer(0.9).timeout.connect(func(): Gate.board_offer_more("adult"))


## QA: open each overlay without playing to it (engine shots on the GPU box).
func debug_story(kind: String) -> void:
	match kind:
		"choice":
			_show_choice({"prompt": "He waits for your answer.", "options": [{"index": 0, "text": "Stay a little longer"}, {"index": 1, "text": "It's late — I should go"}]})
		"clear":
			_show_chapter_clear({"chapter_index": 1, "chapter_total": 5, "title": "The first coffee", "reward": {"kind": "memory", "title": "Two sugars", "text": "He remembered how you take it."}})
		"ending":
			_show_ending({"title": "He remembers you", "text": "Some people stay in the details."})

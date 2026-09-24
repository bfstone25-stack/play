## Campaign — THE NIGHT LEDGER (Nutaku F2P only). Six chapters down the left, the chosen
## chapter's twelve nights in the middle, the chosen night on the right with its story, its
## rules and the PLAY button. Across the bottom: today's reward, missions, the free
## rematch and the night pass. Everything here is read from /suasion/state; the only thing
## this screen decides is which stage to show.
extends Control

var main: Node
var _chapters: VBoxContainer
var _stages: VBoxContainer
var _detail: VBoxContainer
var _daily_row: HBoxContainer
var _head: Label
var _ch := 0
var _mode := "story"                 # story | last_call
var _sel := ""


func setup(_args: Dictionary) -> void:
	pass


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 18
	col.offset_right = -18
	col.offset_top = 10
	col.offset_bottom = -10
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	col.add_child(top)
	top.add_child(StudioTheme.display_label("THE NIGHT LEDGER", 30, Palette.GOLD))
	_head = StudioTheme.mono_label("", 12, Palette.MUTED)
	_head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_head)
	var story := Button.new()
	story.text = "STORY SO FAR"
	story.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(story, "quiet")
	story.pressed.connect(func(): Sfx.play("ui_click"); _show_story())
	top.add_child(story)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	col.add_child(body)
	_chapters = VBoxContainer.new()
	_chapters.custom_minimum_size.x = 230
	_chapters.add_theme_constant_override("separation", 6)
	body.add_child(_chapters)
	var mid := PanelContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.GROUND_DEEP, Palette.PANEL_EDGE, 12, 1, Vector2(10, 10)))
	body.add_child(mid)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(sc)
	_stages = VBoxContainer.new()
	_stages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stages.add_theme_constant_override("separation", 5)
	sc.add_child(_stages)
	var right := PanelContainer.new()
	right.custom_minimum_size.x = 420
	right.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PANEL, Palette.ACCENT, 12, 1, Vector2(14, 12)))
	body.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	rs.add_child(_detail)
	_daily_row = HBoxContainer.new()
	_daily_row.add_theme_constant_override("separation", 8)
	col.add_child(_daily_row)
	F2P.suasion_changed.connect(func(_s): if is_inside_tree(): _render())
	await F2P.refresh()
	# the chapter the player is in, not chapter one, on every visit
	var f := int(F2P.su.get("frontier", 0))
	_ch = clampi(f / 12, 0, 5)
	_render()
	_prologue_once()


func _render() -> void:
	var su: Dictionary = F2P.su
	if su.is_empty():
		return
	var e: Dictionary = Nutaku.state.get("energy", {})
	_head.text = "STANDING ★%d   ·   CHARM %d/%d   ·   %d CHIPS   ·   %d TICKET%s" % [int(su.get("standing", 0)),
		int(e.get("now", 0)), int(e.get("max", 8)), int(Nutaku.state.get("tokens", {}).get("chips", 0)),
		int(Nutaku.state.get("tokens", {}).get("ticket", 0)),
		"" if int(Nutaku.state.get("tokens", {}).get("ticket", 0)) == 1 else "S"]
	for c in _chapters.get_children():
		c.queue_free()
	var chs: Array = su.get("chapters", [])
	for i in chs.size():
		var ch: Dictionary = chs[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%d · %s\n   %s  ★%d%s" % [i + 1, str(ch["title"]).to_upper(), str(ch["house"]),
			int(ch["stars"]), "  ✓" if ch["cleared"] else ""]
		b.disabled = not bool(ch["open"])
		StudioTheme.style_button(b, "active" if i == _ch else "quiet")
		b.pressed.connect(func(): Sfx.play("ui_click"); _ch = i; _mode = "story"; _sel = ""; _render())
		_chapters.add_child(b)
	var ch: Dictionary = chs[_ch]
	var lc: Dictionary = ch.get("last_call", {})
	var tabs := HBoxContainer.new()
	var t1 := Button.new()
	t1.text = "THE NIGHTS"
	var t2 := Button.new()
	t2.text = "LAST CALL" + ("" if lc.get("open", false) else " (after the boss)")
	t2.disabled = not bool(lc.get("open", false))
	for pair in [[t1, "story"], [t2, "last_call"]]:
		var bt: Button = pair[0]
		bt.focus_mode = Control.FOCUS_NONE
		StudioTheme.style_button(bt, "active" if _mode == pair[1] else "quiet")
		var m: String = pair[1]
		bt.pressed.connect(func(): Sfx.play("ui_click"); _mode = m; _sel = ""; _render())
		tabs.add_child(bt)
	for c in _stages.get_children():
		c.queue_free()
	_stages.add_child(tabs)
	var list: Array = ch["stages"] if _mode == "story" else lc.get("stages", [])
	if _mode == "last_call" and str(lc.get("intro", "")) != "":
		var li := StudioTheme.serif_label(str(lc["intro"]), 13, Palette.MUTED)
		li.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_stages.add_child(li)
	var first_open := ""
	for s in list:
		_stages.add_child(_stage_row(s))
		if first_open == "" and s["open"] and int(s["stars"]) == 0:
			first_open = str(s["id"])
	if _sel == "":
		_sel = first_open if first_open != "" else str(list[0]["id"])
	_render_detail(F2P.stage(_sel))
	_render_daily()


func _stage_row(s: Dictionary) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 40
	var stars := "★".repeat(int(s["stars"])) + "☆".repeat(3 - int(s["stars"]))
	var tag := ""
	if s["boss"]:
		tag = "  BOSS"
	elif s.get("rival", false):
		tag = "  RIVAL"
	var lock := ""
	if not s["open"]:
		var g = s.get("gate")
		if typeof(g) == TYPE_DICTIONARY:
			match str(g.get("kind", "")):
				"bond":
					lock = "  · needs bond %d with %s (%d)" % [int(g["need"]), str(g["who"]).capitalize(), int(g["have"])]
				"standing":
					lock = "  · needs standing ★%d (%d)" % [int(g["need"]), int(g["have"])]
				_:
					lock = "  · locked"
	b.text = "%s   %s%s   ·   %s%s" % [stars, str(s["title"]), tag, str(s["who"]).capitalize(), lock]
	b.disabled = not bool(s["open"]) and int(s["stars"]) == 0
	StudioTheme.style_button(b, "active" if str(s["id"]) == _sel else ("pull" if s["boss"] else "quiet"))
	b.pressed.connect(func(): Sfx.play("card_hover"); _sel = str(s["id"]); _render())
	return b


func _render_detail(s: Dictionary) -> void:
	for c in _detail.get_children():
		c.queue_free()
	if s.is_empty():
		return
	var who := str(s["who"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_detail.add_child(row)
	var face := "res://assets/faces/%s.webp" % who
	if ResourceLoader.exists(face):
		var tr := TextureRect.new()
		tr.texture = load(face)
		tr.custom_minimum_size = Vector2(84, 84)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(tr)
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_child(StudioTheme.display_label(str(s["title"]), 22, Palette.GOLD if s["boss"] else Palette.TEXT))
	tb.add_child(StudioTheme.mono_label("%s · %s · RESOLVE %d · %d TURNS" % [who.capitalize(), str(s["difficulty"]).to_upper(),
		int(s.get("resolve", 0)), int(s.get("mods", {}).get("turns", 15))], 11, Palette.HEAT))
	row.add_child(tb)
	var goal := StudioTheme.serif_label(str(s["goal"]), 16, Palette.TEXT, true)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(goal)
	if s.has("intro") and str(s["intro"]) != "":
		var intro := StudioTheme.serif_label(str(s["intro"]), 13, Palette.MUTED)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(intro)
	var mods: Dictionary = s.get("mods", {})
	var rules := []
	if mods.has("boss"):
		rules.append(str(mods["boss"]))
	if int(mods.get("muted", 0)) > 0 and not mods.has("boss"):
		rules.append("She talks over your first card.")
	if int(mods.get("steal_every", 0)) > 0 and not mods.has("boss"):
		rules.append("Every %d turns she takes your costliest card." % int(mods["steal_every"]))
	if int(mods.get("hand", 0)) > 0 and not mods.has("boss"):
		rules.append("You hold %d cards." % int(mods["hand"]))
	if int(mods.get("stale_cost", 0)) > 1 and not mods.has("boss"):
		rules.append("A card that adds nothing new costs two turns.")
	for r in rules:
		var rl := StudioTheme.mono_label("◆ " + r, 12, Palette.ACCENT_SOFT)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(rl)
	var play := StudioTheme.card_button("PLAY · 1 CHARM" if int(s["stars"]) == 0 else "PLAY AGAIN · 1 CHARM", "primary")
	play.custom_minimum_size = Vector2(260, 48)
	play.focus_mode = Control.FOCUS_NONE
	play.disabled = not bool(s["open"])
	play.pressed.connect(func(): _play(str(s["id"])))
	_detail.add_child(play)
	var deckb := Button.new()
	deckb.text = "BUILD THE DECK FOR THIS NIGHT"
	deckb.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(deckb, "quiet")
	deckb.pressed.connect(func(): Sfx.play("ui_click"); F2P.stage_id = str(s["id"]); main.go("deck"))
	_detail.add_child(deckb)


func _play(id: String) -> void:
	Sfx.play("ui_click")
	F2P.stage_id = id
	var r: Dictionary = await main.start_duel(id, false)
	if r.has("error") and "charm" in str(r["error"]):
		main.go("store")


func _render_daily() -> void:
	for c in _daily_row.get_children():
		c.queue_free()
	var st: Dictionary = Nutaku.state
	var daily: Dictionary = st.get("daily", {})
	var cal: Dictionary = daily.get("calendar", {})
	if not bool(cal.get("claimed_today", true)):
		_daily_row.add_child(_chip("CLAIM TODAY'S REWARD", "free", func(): _claim("daily")))
	var su: Dictionary = F2P.su
	if bool(su.get("daily_duel", {}).get("available", false)):
		_daily_row.add_child(_chip("TONIGHT'S REMATCH · FREE", "free", func():
			Sfx.play("ui_click")
			main.start_duel("", true)))
	for m in daily.get("missions", []):
		var done: bool = m["done"]
		var txt := "%s  %d/%d" % [str(m["text"]), int(m["progress"]), int(m["goal"])]
		if m["claimed"]:
			txt += "  ✓"
		var slot := int(m["slot"])
		var b := _chip(txt, "free" if done and not m["claimed"] else "quiet", func(): _claim("mission", slot))
		b.disabled = not done or m["claimed"]
		_daily_row.add_child(b)
	var np: Dictionary = su.get("night_pass", {})
	if bool(np.get("active", false)) and not bool(np.get("claimed_today", true)):
		_daily_row.add_child(_chip("NIGHT PASS · CLAIM", "free", func(): _claim("pass")))


func _chip(text: String, kind: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	StudioTheme.style_button(b, kind)
	b.pressed.connect(cb)
	return b


func _claim(kind: String, slot: int = -1) -> void:
	Sfx.play("gold")
	var r := await F2P.claim(kind, slot)
	if not r["ok"]:
		main.toast(str(r["error"]))
	else:
		var ms: Array = Nutaku.state.get("daily", {}).get("missions", [])
		if kind == "mission" and ms.all(func(m): return m["claimed"]) and not Nutaku.state["daily"].get("all_missions_bonus_claimed", true):
			await F2P.claim("bonus")
		main.toast("Claimed.", 1.6, Palette.SUCCESS)
	_render()


# --- the words ------------------------------------------------------------------------------
func _prologue_once() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://suasion.cfg")
	if bool(cfg.get_value("seen", "prologue", false)):
		return
	cfg.set_value("seen", "prologue", true)
	cfg.save("user://suasion.cfg")
	_reader("VELL, AFTER TWO", str(F2P.su.get("prologue", "")))


func _show_story() -> void:
	var r := await Nutaku.api("GET", "/suasion/story")
	var parts := []
	for p in r["body"].get("story", []):
		var t := str(p.get("title", "")).to_upper()
		parts.append(("%s\n\n" % t if t != "" else "") + str(p["text"]))
	_reader("THE STORY SO FAR", "\n\n* * *\n\n".join(parts))


func _reader(title: String, text: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(Palette.GROUND_DEEP, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -380
	box.offset_right = 380
	box.offset_top = -290
	box.offset_bottom = 290
	box.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.PAPER, Palette.GOLD, 10, 2, Vector2(28, 22)))
	dim.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(StudioTheme.display_label(title, 26, Palette.INK))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var l := StudioTheme.serif_label(text, 17, Palette.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 690
	sc.add_child(l)
	var ok := StudioTheme.card_button("CONTINUE", "primary")
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(func(): Sfx.play("ui_click"); dim.queue_free())
	v.add_child(ok)

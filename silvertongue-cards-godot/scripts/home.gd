## Home — tonight's roster. Five people, one evening each. A card per character with her
## portrait, what she needs, affection, and the DUEL / DAILY buttons. Rank picker top.
extends Control

var main: Node
var _roster: HBoxContainer
var _rank_buttons := {}


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
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 0)
	tbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbox.add_child(StudioTheme.display_label("TONIGHT", 30, Palette.LAMP))
	var sub := StudioTheme.serif_label("Five people, one evening each. Bring a deck; every card is a sentence. The engine reads it. She answers. A duel costs 3 energy; today's is free and pays double affection.", 13, Palette.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tbox.add_child(sub)
	head.add_child(tbox)
	var rank := HBoxContainer.new()
	rank.add_theme_constant_override("separation", 6)
	rank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rank.add_child(StudioTheme.mono_label("RANK", 11, Palette.MUTED))
	for pair in [["gentle", "GENTLE · 18"], ["silver", "SILVER · 15"], ["gold", "GOLD · 10"]]:
		var b := Button.new()
		b.text = pair[1]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): Sfx.play("ui_click"); _set_rank(pair[0]))
		rank.add_child(b)
		_rank_buttons[pair[0]] = b
	head.add_child(rank)
	_set_rank(main.difficulty)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_roster = HBoxContainer.new()
	_roster.add_theme_constant_override("separation", 14)
	_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_roster)
	_render()
	var foot := StudioTheme.mono_label("Nothing sold changes the turn count or what she needs.", 10, Palette.DIM)
	col.add_child(foot)


func _set_rank(r: String) -> void:
	main.difficulty = r
	for k in _rank_buttons:
		var b: Button = _rank_buttons[k]
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_color_override("font_color")
		if k == r:
			StudioTheme.style_button(b, "active")


func _render() -> void:
	for c in _roster.get_children():
		c.queue_free()
	var st: Dictionary = main.state
	var daily: Dictionary = st.get("daily", {})
	var aff: Dictionary = st.get("affection", {})
	var i := 0
	for sc in st.get("scenarios", []):
		var who := str(sc.get("who", ""))
		var is_daily: bool = daily.get("scenario", "") == sc.get("id", "")
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(220, 0)
		var s := StudioTheme.flat(Palette.PANEL_RAISED, Palette.AMBER if is_daily else Color("4a3c30"), 12, 1, Vector2(0, 0))
		if is_daily:
			s.shadow_color = Color(Palette.AMBER, 0.25)
			s.shadow_size = 14
		card.add_theme_stylebox_override("panel", s)
		_roster.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		card.add_child(v)
		var pw := Control.new()
		pw.custom_minimum_size = Vector2(0, 250)
		pw.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pw.clip_contents = true
		v.add_child(pw)
		var img := TextureRect.new()
		img.texture = load("res://assets/portraits/%s.webp" % who)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pw.add_child(img)
		var shade := TextureRect.new()
		var g := Gradient.new()
		g.set_color(0, Color(Palette.PANEL_RAISED, 0.0))
		g.set_color(1, Palette.PANEL_RAISED)
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0.5, 0.55)
		gt.fill_to = Vector2(0.5, 1.0)
		shade.texture = gt
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pw.add_child(shade)
		if is_daily:
			var tag := PanelContainer.new()
			tag.add_theme_stylebox_override("panel", StudioTheme.flat(Palette.AMBER, Palette.AMBER, 6, 0, Vector2(7, 3)))
			tag.add_child(StudioTheme.mono_label("TODAY · FREE · ×2 AFFECTION", 9, Color("1e1408")))
			tag.position = Vector2(10, 10)
			pw.add_child(tag)
		var meta := VBoxContainer.new()
		meta.add_theme_constant_override("separation", 4)
		var mm := MarginContainer.new()
		for side in ["left", "right", "bottom"]:
			mm.add_theme_constant_override("margin_" + side, 12)
		mm.add_child(meta)
		v.add_child(mm)
		meta.add_child(StudioTheme.display_label(str(sc.get("name", "")), 20, Palette.PARCHMENT))
		var role := StudioTheme.serif_label(str(sc.get("character", "")), 12, Palette.MUTED)
		role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		role.max_lines_visible = 2
		meta.add_child(role)
		var wins := int(aff.get(who, {}).get("wins", 0))
		meta.add_child(StudioTheme.mono_label("♥ %d   %s" % [wins, "★".repeat(int(sc.get("stars", 3)))], 11, Palette.AMBER))
		var needs := HFlowContainer.new()
		needs.add_theme_constant_override("h_separation", 4)
		needs.add_theme_constant_override("v_separation", 4)
		var nd: Dictionary = sc.get("needs", {})
		var paths: Array = nd.get("paths", [])
		if not paths.is_empty():
			for k in paths[0]:
				needs.add_child(Chip.make(Palette.glyph(str(k)) + " " + Palette.label(str(k)), false, false, false, 9))
		for k in nd.get("help", []):
			needs.add_child(Chip.make("+ " + Palette.label(str(k)), false, true, false, 9))
		meta.add_child(needs)
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 6)
		meta.add_child(btns)
		var duel := Button.new()
		duel.text = "DUEL · 3⚡"
		duel.focus_mode = Control.FOCUS_NONE
		StudioTheme.style_button(duel, "primary")
		duel.pressed.connect(func(): Sfx.play("ui_click"); main.start_duel(str(sc.get("id", "")), false))
		btns.add_child(duel)
		if is_daily:
			var d := Button.new()
			d.focus_mode = Control.FOCUS_NONE
			var avail := bool(daily.get("available", false))
			d.text = "DAILY · FREE" if avail else "DAILY DONE"
			d.disabled = not avail
			StudioTheme.style_button(d, "free")
			d.pressed.connect(func(): Sfx.play("ui_click"); main.start_duel(str(sc.get("id", "")), true))
			btns.add_child(d)
		# stagger in
		card.modulate.a = 0.0
		card.position.y = 20
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(0.06 * i)
		i += 1

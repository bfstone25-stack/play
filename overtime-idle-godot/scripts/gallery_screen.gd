class_name GalleryScreen
extends Overlay
## Two ladders, one CG set. Skill: a board you built, never from time. Affection: shifts
## worked on a solvent floor — this one is time, and says so.

signal view_plate(id: String, caption: String, gated: bool, slot: String)
signal need_gold

var skill_grid: GridContainer
var aff_grid: GridContainer


func build() -> void:
	card_width = 1040
	card.custom_minimum_size = Vector2(1040, 0)
	tag("PLATES")
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := Label.new()
	t.text = "Gallery"
	t.theme_type_variation = "Title"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(button("CLOSE", "Ghost", close))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	var l1 := Label.new()
	l1.text = "SKILL — A BOARD YOU BUILT. NEVER FROM TIME."
	l1.theme_type_variation = "Tag"
	l1.add_theme_color_override("font_color", Look.AMBER)
	v.add_child(l1)
	skill_grid = GridContainer.new()
	skill_grid.columns = 5
	skill_grid.add_theme_constant_override("h_separation", 8)
	skill_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(skill_grid)
	var l2 := Label.new()
	l2.text = "AFFECTION — SHIFTS WORKED ON A SOLVENT FLOOR. THIS ONE IS TIME, AND SAYS SO."
	l2.theme_type_variation = "Tag"
	l2.add_theme_color_override("font_color", Look.ROSE)
	v.add_child(l2)
	aff_grid = GridContainer.new()
	aff_grid.columns = 6
	aff_grid.add_theme_constant_override("h_separation", 8)
	aff_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(aff_grid)


func on_open() -> void:
	render()


func _tile(art_id: String, name: String, hint: String, got: bool, on: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 168)
	b.pressed.connect(on)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_top = 6
	v.offset_right = -6
	v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var im := TextureRect.new()
	im.custom_minimum_size = Vector2(0, 100)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	im.texture = Look.art(art_id if got else "plate_unearned")
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not got:
		im.modulate = Color(0.6, 0.6, 0.65)
	v.add_child(im)
	var n := Label.new()
	n.text = name if got else "???"
	n.add_theme_font_override("font", Look.font_ui_bold)
	n.add_theme_font_size_override("font_size", 13)
	n.add_theme_color_override("font_color", Look.AMBER if got else Look.MUTED)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var h := Label.new()
	h.text = hint
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_theme_font_size_override("font_size", 11)
	h.add_theme_color_override("font_color", Look.MUTED)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	return b


func render() -> void:
	clear(skill_grid)
	clear(aff_grid)
	for p in Ticker.PLATES:
		var slot: String = p["slot"]
		var got := Ticker.earned(slot)
		var free_or_open := bool(p.get("free", false)) or not Gate.is_web() or Gate.has(slot)
		skill_grid.add_child(_tile(slot if free_or_open else slot + "_locked", p["who"], p["en"], got, func() -> void:
			if got:
				view_plate.emit(slot, "%s — %s" % [p["who"], p["en"]], not bool(p.get("free", false)), slot)))
	for p in Roster.ROSTER:
		var id: String = p["id"]
		var tier := Economy.affection_tier(id)
		for k in range(1, 5):
			var open_k: bool = tier >= k or (k == 4 and Economy.can_see_scene(id))
			var label := "%s · cg%d" % [str(p["name"]).split(",")[0], k]
			var hint := ("%d shifts" % int(Economy.AFF_TIERS[k - 1])) if k < 4 else ("TIER 4 · PLACEHOLDER" if Economy.can_see_scene(id) else "300 shifts · or scene_skip at 150 (80 Gold)")
			aff_grid.add_child(_tile(Ticker.aff_plate(id, k), label, hint, open_k, func() -> void:
				if open_k:
					view_plate.emit(Ticker.aff_plate(id, k), label + (" (tier-4 scene: placeholder, Blaze's own)" if k == 4 else ""), false, "")
				elif k == 4 and tier >= 3:
					var r := Economy.buy("scene_skip_" + id)
					if not r["ok"]:
						need_gold.emit()
					render()))

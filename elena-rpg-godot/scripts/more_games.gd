## "More from Flat 404": cover + title + one-line hook for the studio's other games.
## Data: res://data/more_games.json (tools/build_more.py), which holds NO URL.
##
## Two editions, one script:
##  - desktop (the DLsite build): text-only credits. No links, no URLs, no store names --
##    DLsite forbids 他サイトへの誘導 (help article 4408257160345). Tiles are not clickable.
##  - web (our own site): each tile opens that game's page. The URL is assembled by the
##    host page (window.ElenaMore.open), so it never exists inside the .pck.
extends Control

var _done := false


func run(main, _args: Dictionary) -> String:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := FileAccess.open("res://data/more_games.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text()) if f else {}
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.05, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var h := NRSkin.heading(Loc.t("mg_title"), 36)
	h.position = Vector2(48, 22)
	add_child(h)
	var sub := NRSkin.label(Loc.t("mg_sub"), 18, Color(0.75, 0.7, 0.65))
	sub.position = Vector2(52, 72)
	sub.custom_minimum_size = Vector2(900, 0)
	sub.size = Vector2(900, 30)
	add_child(sub)
	var back := NRSkin.button(Loc.t("mg_back"), func(): _done = true, 22)
	back.position = Vector2(1100, 26)
	add_child(back)
	var sc := ScrollContainer.new()
	sc.position = Vector2(40, 110)
	sc.size = Vector2(1200, 596)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(1180, 0)
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)
	var web := OS.has_feature("web")
	for world in ["adult", "regular"]:
		col.add_child(NRSkin.heading(Loc.t("mg_" + world), 24))
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		col.add_child(grid)
		for g in data.get(world, []):
			grid.add_child(_tile(g, world, web))
	if main != null and main.auto:
		return "ok"
	while not _done:
		await get_tree().process_frame
	return "ok"


func _tile(g: Dictionary, world: String, web: bool) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(282, 0)
	p.add_theme_stylebox_override("panel", NRSkin.box("modal", 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var img := TextureRect.new()
	img.texture = load(str(g.get("cover", "")))
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.custom_minimum_size = Vector2(262, 147)
	v.add_child(img)
	v.add_child(NRSkin.heading(str(g.get("name", "")), 20))
	var hook := NRSkin.label(str(g.get("hook", "")), 14, Color(0.8, 0.75, 0.7))
	hook.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hook.custom_minimum_size = Vector2(262, 40)
	v.add_child(hook)
	if web:
		var slug := str(g.get("slug", ""))
		var b := NRSkin.button(Loc.t("mg_open"), func(): _open(slug, world), 16)
		v.add_child(b)
	return p


func _open(slug: String, world: String) -> void:
	# guard, then call, as two evals (memory: godot-js-bridge-promise)
	if int(JavaScriptBridge.eval("(window.ElenaMore && window.ElenaMore.open) ? 1 : 0")) == 1:
		JavaScriptBridge.eval("window.ElenaMore.open(%s, %s); 0" % [JSON.stringify(slug), JSON.stringify(world)])

extends Node
## Click-through smoke test with real mouse events (Input.parse_input_event), headless:
## disclosure -> title -> New game -> click through the opening -> click a hotspot -> open
## a standoff and win it by clicking action buttons -> save to slot 2 -> load it.
## Run: godot --headless --path . res://tests/ui_smoke.tscn
## Asserts on game state, never on pixels or remembered coordinates (buttons are found by text).

var main
var _t0 := 0
var fails := 0


func _ready() -> void:
	print("RENDER DEVICE: ", RenderingServer.get_video_adapter_name(), " / ", RenderingServer.get_current_rendering_driver_name())
	for f in DirAccess.get_files_at("user://saves"):
		DirAccess.remove_absolute("user://saves/" + f)
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	add_child(main)
	await wait(0.3)
	check(_find_button(Loc.t("ds_continue")) != null, "disclosure shown at launch")
	await click_text(Loc.t("ds_continue"))
	await click_text(Loc.t("t_new"))
	await wait(3.2)   # night card
	var n := 0
	while not main.hud.visible and n < 200:
		await click_at(Vector2(640, 640))
		n += 1
	check(main.hud.visible and RPG.s["room"] == "study", "opening clicked through to the study (%d clicks)" % n)
	await click_text(Loc.t("hs_search") + " " + Loc.t("hs_desk"))
	n = 0
	while not main.hud.visible and n < 50:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.has("override_key"), "clicking the desk hotspot gave the override key")
	# walk to the corridor and fight Cobb with clicks
	await click_text("→ " + Loc.t("r_corridor"))
	n = 0
	while not main.hud.visible and n < 50:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.s["room"] == "corridor", "door click moved to the corridor")
	await click_text("! " + Loc.t("e_cobb"))
	n = 0
	while not main.battle.visible and n < 60:
		await click_at(Vector2(640, 640))
		n += 1
	check(main.battle.visible, "standoff screen opened")
	var acts := 0
	while (main.battle.visible or _find_button(Loc.t("lose_reload")) != null) and acts < 160:
		var lr = _find_button(Loc.t("lose_reload"))
		if lr != null:
			print("lost a standoff; reloading by click")
			await click_node(lr)
			await wait(0.5)
			await click_text("! " + Loc.t("e_cobb"))
			var k := 0
			while not main.battle.visible and k < 60:
				await click_at(Vector2(640, 640))
				k += 1
			continue
		var b = _find_button(Loc.t("ds_continue"), main.battle)
		if b != null:
			await click_node(b)
			break
		# decide like a normal player (NRPolicy), then click that button for real
		var bt = main.battle.b
		var mi := 0
		for i in bt["party"].size():
			if main.battle.actor_lbl.text.begins_with(Loc.t("n_" + bt["party"][i]["id"])):
				mi = i
		var want: Array = NRPolicy.choose(bt, mi)
		var pick = _find_button_prefix(Loc.t("a_" + want[0]), main.battle.action_box)
		if pick != null:
			await click_node(pick)
			acts += 1
			if want[0] == "item":
				await wait(0.2)
				var ib = _find_button_prefix(Loc.t("i_" + want[1]), main.battle.item_box)
				if ib != null:
					await click_node(ib)
		await wait(0.7)
	n = 0
	while not main.hud.visible and n < 80:
		if main.overlay.get_child_count() > 0:
			var c = _find_button(Loc.t("lv_confirm"), main.overlay)
			if c != null:
				for st in RPG.game["stats"]:
					var sb = _find_button_prefix(Loc.t("s_" + st), main.overlay)
					if sb != null:
						await click_node(sb)
						break
				var sk = _find_button_prefix(Loc.t("sk_footnote"), main.overlay)
				if sk == null:
					sk = _find_button_prefix(Loc.t("sk_palm"), main.overlay)
				if sk != null:
					await click_node(sk)
				await click_node(c)
				continue
		await click_at(Vector2(640, 640))
		n += 1
	check(main.hud.visible, "back in the room after the standoff")
	check(acts > 0 and "corridor/cobb" in RPG.s["done"], "standoff won by clicking actions (%d clicks)" % acts)
	check(int(RPG.s["level"]) >= 2, "level-up screen clicked through (level %d)" % int(RPG.s["level"]))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_save"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	check(RPG.slot_info(2).get("room", "") == "corridor", "saved to slot 2 by clicking")
	RPG.s["room"] = "study"
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_load"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	await wait(0.3)
	check(RPG.s["room"] == "corridor", "loaded slot 2 by clicking")
	print("ui_smoke: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func check(c: bool, what: String) -> void:
	print(("ok   " if c else "FAIL ") + what)
	if not c:
		fails += 1


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func click_at(p: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	get_viewport().push_input(mm)
	await get_tree().process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		get_viewport().push_input(e)
		await get_tree().process_frame
	await get_tree().process_frame


func click_node(c: Control) -> void:
	if OS.get_cmdline_user_args().has("--debug"):
		print("click ", c.text if c is Button else c, " rect=", c.get_global_rect())
	await click_at(c.get_global_rect().get_center())
	if OS.get_cmdline_user_args().has("--debug"):
		print("  hovered=", get_viewport().gui_get_hovered_control())
	await wait(0.15)


func click_text(t: String) -> void:
	var b = _find_button(t)
	if b == null:
		check(false, "button '%s' not found" % t)
		return
	await click_node(b)


func click_text_prefix(t: String) -> void:
	var b = _find_button_prefix(t, main)
	if b == null:
		check(false, "button '%s…' not found" % t)
		return
	await click_node(b)


func _all_buttons(root: Node) -> Array:
	var out := []
	for c in root.get_children():
		if c is BaseButton and c.is_visible_in_tree() and not c.is_queued_for_deletion():
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


func _find_button(t: String, root: Node = null):
	for b in _all_buttons(root if root != null else main):
		if b is Button and b.text == t and not b.disabled:
			return b
	return null


func _find_button_prefix(t: String, root: Node):
	for b in _all_buttons(root):
		if b is Button and b.text.begins_with(t) and not b.disabled:
			return b
	return null


func _first_enabled(box: Node, keys: Array):
	for k in keys:
		var b = _find_button_prefix(Loc.t(k), box)
		if b != null:
			return b
	return null

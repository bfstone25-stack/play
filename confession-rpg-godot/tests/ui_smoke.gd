extends Node
## Click-through smoke test with real mouse events (Input.parse_input_event):
## disclosure -> title -> New game -> click through the opening -> search the case file ->
## walk to the corridor and into interview room 1 -> click an Ask -> Press Nikolai and win the
## standoff by clicking action buttons -> level up -> save to slot 2 -> load it.
## Run (needs a window; headless routes no GUI input): tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke
## Asserts on game state, never on pixels or remembered coordinates (buttons are found by text).

var main
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
	check(main.hud.visible and RPG.s["room"] == "precinct", "opening clicked through to the desk (%d clicks)" % n)
	await click_text(Loc.t("hs_search") + " " + Loc.t("hs_drawer"))
	n = 0
	while not main.hud.visible and n < 50:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.has("notebook"), "clicking the drawer hotspot gave the notebook")
	await click_text("→ " + Loc.t("r_corridor"))
	n = 0
	while not main.hud.visible and n < 60:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.s["room"] == "corridor", "door click moved to the corridor")
	await click_text("→ " + Loc.t("r_interview_nikolai"))
	n = 0
	while not main.hud.visible and n < 60:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.s["room"] == "interview_nikolai", "door click moved into interview room 1")
	await click_text(Loc.t("hs_ask_nik_keys"))
	n = 0
	while not main.hud.visible and n < 60:
		await click_at(Vector2(640, 640))
		n += 1
	check(RPG.flag("heard_nik_keys"), "an Ask hotspot put the testimony on the board")
	# press Nikolai: the standoff, won by clicking
	await click_text("! " + Loc.t("hs_press_nikolai_1"))
	n = 0
	while not main.battle.visible and n < 60:
		await click_at(Vector2(640, 640))
		n += 1
	check(main.battle.visible, "standoff screen opened")
	var acts := 0
	while (main.battle.visible or _find_button(Loc.t("lose_reload")) != null) and acts < 200:
		var lr = _find_button(Loc.t("lose_reload"))
		if lr != null:
			print("lost a standoff; reloading by click")
			await click_node(lr)
			await wait(0.5)
			await click_text("! " + Loc.t("hs_press_nikolai_1"))
			var k := 0
			while not main.battle.visible and k < 60:
				await click_at(Vector2(640, 640))
				k += 1
			continue
		var b = _find_button(Loc.t("ds_continue"), main.battle)
		if b != null:
			await click_node(b)
			break
		var bt = main.battle.b
		var want: Array = NRPolicy.choose(bt, 0)
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
				var sk = _find_button_prefix(Loc.t("sk_paperwork"), main.overlay)
				if sk == null:
					sk = _find_button_prefix(Loc.t("sk_cheap"), main.overlay)
				if sk != null:
					await click_node(sk)
				await click_node(c)
				continue
		await click_at(Vector2(640, 640))
		n += 1
	check(main.hud.visible, "back in the room after the standoff")
	check(acts > 0 and RPG.flag("c1_nikolai_p1"), "standoff won by clicking actions (%d clicks); pressure 1 set" % acts)
	check(RPG.trust("nikolai") >= 1, "Nikolai's trust rose with the win (%d)" % RPG.trust("nikolai"))
	check(int(RPG.s["level"]) >= 2, "level-up screen clicked through (level %d)" % int(RPG.s["level"]))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_save"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	check(RPG.slot_info(2).get("room", "") == "interview_nikolai", "saved to slot 2 by clicking")
	RPG.s["room"] = "precinct"
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_load"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	await wait(0.3)
	check(RPG.s["room"] == "interview_nikolai", "loaded slot 2 by clicking")
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
	await click_at(c.get_global_rect().get_center())
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

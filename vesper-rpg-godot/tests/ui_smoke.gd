extends Node
## Click-through smoke test with real mouse events (Input.parse_input_event):
## disclosure -> title -> New game -> the prologue -> pick Gu Yan's route by clicking it ->
## search the wardrobe -> equip the dress from the Party menu -> plan the evening -> walk to the city -> win the
## doorman standoff by clicking action buttons -> level-up -> the café -> save to slot 2 -> load it.
## Run under Xvfb for real input (tools/remote_shots.sh res://tests/ui_smoke.tscn shots/smoke).
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
	while _find_button_prefix("Gu Yan", main) == null and _find_button_prefix("顧言", main) == null and n < 40:
		await click_at(Vector2(640, 640))
		n += 1
	var pick = _find_button_prefix("Gu Yan", main)
	if pick == null:
		pick = _find_button_prefix("顧言", main)
	check(pick != null, "route select offered (%d clicks of prologue)" % n)
	await click_node(pick)
	await wait(3.4)   # chapter card
	n = await click_through(60)
	check(RPG.flag("r_guyan") and RPG.s["night"] == "guyan_c1" and main.hud.visible and RPG.s["room"] == "home", "picked Gu Yan by clicking; in your flat (%d clicks)" % n)
	await click_text(Loc.t("hs_search") + " " + Loc.t("hs_wardrobe"))
	await click_through(50)
	check(RPG.has("dress"), "the wardrobe gave the little black dress")
	await click_text(Loc.t("m_party"))
	await wait(0.3)
	var tabs = main.overlay.find_children("*", "TabContainer", true, false)
	if tabs.size() > 0:
		tabs[0].current_tab = 1
	await wait(0.3)
	await click_text_prefix(Loc.t("m_equip_to") % Loc.t("n_you"))
	await wait(0.3)
	check(RPG.s["members"]["you"]["equip"]["outfit"] == "dress", "equipped the dress from the Party menu by clicking")
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("hs_plan"))
	await click_through(60)
	check(RPG.flag("c1_planned"), "planned the evening by clicking (stop, approach, outfit)")
	await click_text("→ " + Loc.t("r_street"))
	await click_through(50)
	check(RPG.s["room"] == "street", "door click moved to the city")
	await click_text("! " + Loc.t("e_doorman_guyan"))
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
			await click_text("! " + Loc.t("e_doorman_guyan"))
			var k := 0
			while not main.battle.visible and k < 60:
				await click_at(Vector2(640, 640))
				k += 1
			continue
		var b = _find_button(Loc.t("ds_continue"), main.battle)
		if b != null:
			await click_node(b)
			break
		var want: Array = NRPolicy.choose(main.battle.b, 0)
		var pk = _find_button_prefix(Loc.t("a_" + want[0]), main.battle.action_box)
		if pk != null:
			await click_node(pk)
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
				var sb = _find_button_prefix(Loc.t("s_cha"), main.overlay)
				if sb != null:
					await click_node(sb)
				var sk = _find_button_prefix(Loc.t("sk_warm"), main.overlay)
				if sk == null:
					sk = _find_button_prefix(Loc.t("sk_quick"), main.overlay)
				if sk != null:
					await click_node(sk)
				await click_node(c)
				continue
		await click_at(Vector2(640, 640))
		n += 1
	check(main.hud.visible, "back in the city after the standoff")
	check(acts > 0 and RPG.flag("c1_street"), "standoff won by clicking actions (%d clicks)" % acts)
	check(int(RPG.s["level"]) >= 2, "level-up screen clicked through (level %d)" % int(RPG.s["level"]))
	await click_text("→ " + Loc.t("r_cafe"))
	await click_through(50)
	await click_text(Loc.t("hs_search") + " " + Loc.t("hs_counter"))
	await click_through(50)
	check(RPG.has("macarons"), "the café counter gave macarons")
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_save"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	check(RPG.slot_info(2).get("room", "") == "cafe", "saved to slot 2 by clicking")
	RPG.s["room"] = "home"
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_load"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	await wait(0.3)
	check(RPG.s["room"] == "cafe", "loaded slot 2 by clicking")
	print("ui_smoke: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


## Click through dialogue until the room HUD is back; a choice is answered with its first option.
func click_through(limit: int) -> int:
	var n := 0
	while not main.hud.visible and n < limit:
		if main.event.visible and main.event.choices.get_child_count() > 0:
			var first = main.event.choices.get_child(0)
			if first is Button and not first.disabled:
				await click_node(first)
			else:
				await click_node(main.event.choices.get_child(main.event.choices.get_child_count() - 1))
		else:
			await click_at(Vector2(640, 640))
		n += 1
	return n


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

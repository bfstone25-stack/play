extends Node
## Click-through smoke test with real mouse events (Input.parse_input_event):
## disclosure -> title -> New game -> the opening (Mirei, the free recruit) -> the office: place
## pieces on desks, suggest, run the shift, recruit, buy -> dress Mara from the party menu ->
## save -> load -> the rent crisis paid and its standoff won by clicking actions.
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
	# the opening: Mirei, the lease, Mara, the free first recruit (Priya) -- all by clicking
	var n := await advance([Loc.t("n1_c_how")], 600)
	check(main.hud.visible and RPG.s["room"] == "lobby", "opening clicked through to the lobby (%d clicks)" % n)
	check(RPG.flag("hired_priya") and RPG.in_party("priya") and RPG.in_party("mara"), "Priya recruited free and in the party with Mara")
	check(RPG.persist["gallery"].has("cg_mirei_lease"), "the opening CG went into the gallery")
	await click_text("→ " + Loc.t("r_open_plan"))
	await advance([], 60)
	# and what those rooms give (the reception desk's sign-in sheet, the courier's parking pass)
	RPG.give("sign_in_sheet")
	RPG.give("voucher")
	check(RPG.s["room"] == "open_plan", "door click moved to the open plan")
	# the office (the second genre), by clicking
	var coin0 := int(RPG.s["items"].get("coin", 0))
	await click_text(Loc.t("hs_console"))
	await wait(0.6)
	var off = _office()
	check(off != null, "the floor console opened the office")
	if off != null:
		await click_prefix_any(Loc.t("pc_dan") + " ×")
		await click_node(off.grid.get_child(7))
		await click_prefix_any(Loc.t("pc_coffee") + " ×")
		await click_node(off.grid.get_child(8))
		check(off.cells[7] == "dan" and off.cells[8] == "coffee", "placed Dan and a coffee by clicking desks")
		check("coffee-dan" in off.settle(off.cells)["events"], "coffee beside Dan linked (×3) on the live preview")
		var v0: int = off.shift_value(off.cells)
		await click_text(Loc.t("of_auto"))
		var v1: int = off.shift_value(off.cells)
		check(v1 >= v0, "suggested layout is no worse (%d -> %d a shift)" % [v0, v1])
		await click_text(Loc.t("of_run"))
		await wait(0.3)
		var coin1 := int(RPG.s["items"].get("coin", 0))
		check(RPG.flag("ran_n1") and coin1 == coin0 + v1 * 8, "ran the night shift by clicking: fund %d -> %d" % [coin0, coin1])
		check(RPG.trust("priya") >= 1 and RPG.trust("mara") >= 1, "the women who worked the floor gained trust")
		await click_text(Loc.t("of_done"))
		await wait(0.4)
	check(main.hud.visible, "office closed back to the floor")
	# dress-up: Mara's after-hours dress, equipped from the party menu
	RPG.give("mara_after")
	await click_text(Loc.t("m_party"))
	await wait(0.3)
	var tabs = main.overlay.find_children("*", "TabContainer", true, false)
	if tabs.size() > 0:
		var tb2: TabBar = tabs[0].get_tab_bar()
		await click_at(tb2.get_global_rect().position + tb2.get_tab_rect(1).get_center())
		await wait(0.3)
	var eq = _find_button(Loc.t("m_equip_to") % Loc.t("n_mara"))
	if eq != null:
		await click_node(eq)
	check(RPG.s["members"]["mara"]["equip"]["outfit"] == "mara_after" and RPG.heroine_sprite() == "mara_after", "dressed Mara in the black dress by clicking; her figure follows")
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_save"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	check(RPG.slot_info(2).get("room", "") == "open_plan", "saved to slot 2 by clicking")
	RPG.s["room"] = "lobby"
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_load"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	await wait(0.3)
	check(RPG.s["room"] == "open_plan" and RPG.flag("ran_n1"), "loaded slot 2 by clicking (the shift is remembered)")
	main.render_room()
	await wait(0.3)
	# the rent crisis: pay, then win the standoff by clicking actions. A player arrives at it
	# after the courier and the cleaning supervisor (the sim plays those): level 4 as the sim arrives, as state
	RPG.add_xp(NRRules.xp_to_next(1) + NRRules.xp_to_next(2) + NRRules.xp_to_next(3) + 10)
	await advance([], 60)
	await click_text(Loc.t("hs_crisis_pryce"))
	var na := await advance([Loc.t("ah_home")], 1500, true)
	print("state: battle %s res %s ev %s hud %s overlay %d actor %s btns %s" % [str(main.battle.visible), str(main.battle.b.get("result","")), str(main.event.visible), str(main.hud.visible), main.overlay.get_child_count(), main.battle.actor_lbl.text, str(_all_buttons(main).map(func(x): return x.text).slice(0, 12))])
	print("crisis: %d steps, paid %s, done %s, losses %d, level %d" % [na, str(RPG.flag("n1_paid")), str(RPG.flag("n1_done")), int(main.stats["losses"]), int(RPG.s["level"])])
	check(RPG.flag("n1_paid"), "the rent was paid from the fund the shift filled")
	check(battles_won >= 1 and RPG.flag("n1_done"), "the crisis standoff was won by clicking actions (%d action clicks)" % acts)
	# night two's console (navigation by state), recruiting and supplies by clicking
	# play on into night two the way a player does (after-hours menu: go home; the night card)
	var guard := 0
	while not (RPG.s.get("night", "") == "n2" and main.hud.visible and main.overlay.get_child_count() == 0) and guard < 20:
		await advance([Loc.t("ah_home")], 60)
		guard += 1
	check(RPG.s.get("night", "") == "n2", "night one ended into night two by clicking")
	RPG.s["room"] = "sublet"
	RPG.s["done"]["visited/sublet"] = true
	main.render_room()
	await wait(0.3)
	await click_text(Loc.t("hs_console"))
	await wait(0.6)
	off = _office()
	check(off != null, "night two's console opened the office")
	if off != null:
		var coin1 := int(RPG.s["items"].get("coin", 0))
		if coin1 < 700:
			RPG.give("coin", 700 - coin1)
			coin1 = 700
		var tb: TabBar = off.tabs.get_tab_bar()
		await click_at(tb.get_global_rect().position + tb.get_tab_rect(1).get_center())
		await wait(0.3)
		var pulls0 := int(RPG.s["office"]["pulls"])
		await click_prefix_any(Loc.t("of_recruit") % 400)
		await wait(0.3)
		check(int(RPG.s["office"]["pulls"]) == pulls0 + 1 and int(RPG.s["items"].get("coin", 0)) == coin1 - 400, "recruited once by clicking, paid from the rent fund")
		await click_at(tb.get_global_rect().position + tb.get_tab_rect(2).get_center())
		await wait(0.3)
		var esp := int(RPG.s["items"].get("espresso", 0))
		await click_prefix_any(Loc.t("i_espresso") + " —")
		check(int(RPG.s["items"].get("espresso", 0)) == esp + 1, "bought an espresso in Supplies by clicking")
		await click_text(Loc.t("of_done"))
		await wait(0.4)
	print("ui_smoke: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


var acts := 0
var battles_won := 0


## Click through dialogue until the room HUD is back: choices by preferred text, standoffs by
## the policy's action (clicked as a button), level-ups by the first stat and skill offered.
func advance(prefer: Array, limit: int, until_done := false) -> int:
	var n := 0
	while n < limit:
		n += 1
		if until_done and RPG.flag("n1_done") and ("n1" in RPG.s.get("nights_cleared", []) or _find_button(Loc.t("end_title")) != null):
			return n
		if main.hud.visible and not main.battle.visible and main.overlay.get_child_count() == 0 and not main.event.visible:
			return n
		if main.battle.visible:
			await battle_click()
			continue
		var lr = _find_button(Loc.t("lose_reload"))
		if lr != null:
			await click_node(lr)
			continue
		if main.overlay.get_child_count() > 0:
			var c = _find_button(Loc.t("lv_confirm"), main.overlay)
			if c != null:
				for st in RPG.game["stats"]:
					var sb = _find_button_prefix(Loc.t("s_" + st), main.overlay)
					if sb != null:
						await click_node(sb)
						break
				for skb in _all_buttons(main.overlay):
					if skb is Button and skb.text.contains("\n") and not skb.disabled:
						await click_node(skb)
						break
				await click_node(c)
				continue
		var od = _find_button(Loc.t("of_done"), main.overlay)
		if od != null:
			await click_node(od)
			continue
		var clicked := false
		for t in prefer:
			var pb = _find_button_prefix(t, main.event)
			if pb != null:
				await click_node(pb)
				clicked = true
				break
		if clicked:
			continue
		await click_at(Vector2(640, 640))
	return n


func battle_click() -> void:
	var b = _find_button(Loc.t("ds_continue"), main.battle)
	if b != null:
		await click_node(b)
		battles_won += 1
		return
	var bt = main.battle.b
	if bt.is_empty() or bt.get("result", "") != "":
		await wait(0.3)
		return
	var mi := 0
	for k in bt["party"].size():
		if main.battle.actor_lbl.text.begins_with(Loc.t("n_" + bt["party"][k]["id"]) + " —"):
			mi = k
	var want: Array = NRPolicy.choose(bt, mi)
	var pick = _find_button_prefix(Loc.t("a_" + want[0]), main.battle.action_box)
	if pick == null:
		# the policy's pick is not on offer for this member: take the first enabled action
		for c in _all_buttons(main.battle.action_box):
			if c is Button and not c.disabled and not c.text.begins_with(Loc.t("a_item")):
				pick = c
				want = ["", ""]
				break
	if acts < 12:
		print("click: actor '%s' mi %d want %s found %s susp %d" % [main.battle.actor_lbl.text, mi, str(want), str(pick != null), int(bt["suspicion"])])
	if pick != null:
		var before: String = main.battle.actor_lbl.text
		await click_node(pick)
		acts += 1
		# wait for the next member's turn (or the enemy's) so a stale button is never clicked
		var w := 0
		while main.battle.visible and main.battle.actor_lbl.text == before and w < 40 and _find_button(Loc.t("ds_continue"), main.battle) == null:
			await wait(0.1)
			w += 1
		if want[0] == "item":
			await wait(0.2)
			var ib = _find_button_prefix(Loc.t("i_" + want[1]), main.battle.item_box)
			if ib != null:
				await click_node(ib)
	await wait(0.6)


func _office():
	for c in main.overlay.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("office.gd"):
			return c
	return null


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


func click_prefix_any(t: String) -> void:
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

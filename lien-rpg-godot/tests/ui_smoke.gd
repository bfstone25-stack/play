extends Node
## Click-through smoke test with real mouse events (Input.parse_input_event):
## disclosure -> title -> New game -> the opening with Tamsin: a talk choice, the reading
## choice, the reading standoff won by clicking action buttons, the FAIR price -> walk to the
## stock room -> search the safe -> equip the lantern from the party menu -> save -> load.
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
	# the opening: Tamsin at the counter -- talk, read (a standoff), price FAIR, all by clicking
	var prefer := [Loc.t("h1_talk_flat"), Loc.t("h1_read"), Loc.t("price_finial_fair")]
	var n := await advance(prefer, 600)
	check(main.hud.visible and RPG.s["room"] == "shop", "opening clicked through to the shop (%d clicks)" % n)
	check(battles_won >= 1 and RPG.flag("read_finial"), "the reading standoff was won by clicking actions (%d action clicks)" % acts)
	check(RPG.flag("price_finial_fair") and int(RPG.s["items"].get("coin", 0)) == 238, "priced FAIR by clicking: till 260 - 22 = %d" % int(RPG.s["items"].get("coin", 0)))
	check(RPG.trust("tamsin") >= 2, "Tamsin's trust rose with the talk and the fair price (%d)" % RPG.trust("tamsin"))
	check(RPG.persist["gallery"].has("cg_tamsin"), "the reading's CG went into the gallery")
	await click_text("→ " + Loc.t("r_stockroom"))
	await advance([], 60)
	check(RPG.s["room"] == "stockroom", "door click moved to the stock room")
	await click_text(Loc.t("hs_search") + " " + Loc.t("hs_safe"))
	await advance([], 60)
	check(RPG.has("lantern"), "clicking Elsa's safe gave the stair lantern")
	await click_text(Loc.t("m_party"))
	await wait(0.3)
	# the Items tab, by clicking its tab title
	var tabs = main.overlay.find_children("*", "TabContainer", true, false)
	if tabs.size() > 0:
		var tb: TabBar = tabs[0].get_tab_bar()
		await click_at(tb.get_global_rect().position + tb.get_tab_rect(1).get_center())
		await wait(0.3)
	var eq = _find_button(Loc.t("m_equip_to") % Loc.t("n_nara"))
	if eq != null:
		await click_node(eq)
	check(RPG.s["members"]["nara"]["equip"]["tool"] == "lantern", "equipped the lantern from the party menu by clicking")
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_save"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	check(RPG.slot_info(2).get("room", "") == "stockroom", "saved to slot 2 by clicking")
	RPG.s["room"] = "shop"
	await click_text(Loc.t("m_close"))
	await click_text(Loc.t("m_system"))
	await click_text(Loc.t("m_load"))
	await click_text_prefix(Loc.t("sv_slot") % 2)
	await wait(0.3)
	check(RPG.s["room"] == "stockroom", "loaded slot 2 by clicking")
	# the counter (the second genre), by clicking: touch + lend on the first walk-in, buy the second
	RPG.s["room"] = "shop"
	main.render_room()
	await wait(0.3)
	var till0 := int(RPG.s["items"].get("coin", 0))
	await click_text(Loc.t("hs_counter"))
	await wait(0.5)
	var k0 := 0
	while _find_button_prefix(Loc.t("sh_touch"), main) == null and k0 < 30:
		await click_at(Vector2(400, 610))   # Nara's greeting line, then the counter opens
		k0 += 1
	await click_prefix_any(Loc.t("sh_touch"))
	await wait(0.3)
	await click_prefix_any(Loc.t("sh_lend").split("£")[0] + "£" + str(int(round(34 * 0.7))))
	await wait(0.3)
	check(RPG.s.get("shop", {}).get("pledges", []).size() == 1, "lent against the locket by clicking (pledge in the book)")
	await click_prefix_any(Loc.t("ds_continue"))
	await click_prefix_any(Loc.t("sh_buy").split("£")[0] + "£" + str(int(round(20 * 1.0))))
	await wait(0.3)
	check(RPG.has("stock_key"), "bought the key outright by clicking (it is stock now)")
	check(int(RPG.s["items"].get("coin", 0)) == till0 - 24 - 20, "till moved by both deals: %d -> %d" % [till0, int(RPG.s["items"].get("coin", 0))])
	var n2 := 0
	while not main.hud.visible and n2 < 20:
		await click_prefix_any(Loc.t("ds_continue"))
		n2 += 1
	check(main.hud.visible, "counter closed back to the shop")
	# the Market stalls: put the run in hour two at Ossian's (navigation by state), then click
	RPG.start_night("h2")
	RPG.s["room"] = "bone_arcade"
	RPG.set_flag("haggler_done")
	RPG.s["done"]["visited/bone_arcade"] = true
	main.render_room()
	await wait(0.3)
	var till1 := int(RPG.s["items"].get("coin", 0))
	await click_text(Loc.t("hs_stalls"))
	await wait(0.5)
	await click_prefix_any(Loc.t("sh_sell").split("%s")[0] + Loc.t("i_stock_key"))
	await wait(0.2)
	await click_prefix_any(Loc.t("sh_buy_good").split("%s")[0] + Loc.t("i_bone_charm"))
	await wait(0.2)
	check(not RPG.has("stock_key") and int(RPG.s["items"].get("coin", 0)) == till1 + 4 - 8, "sold stock and bought a charm at the stalls by clicking")
	await click_prefix_any(Loc.t("sh_leave"))
	await wait(0.3)
	check(main.hud.visible, "left the stalls back to the arcade")
	print("ui_smoke: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


var acts := 0
var battles_won := 0


## Click through dialogue until the room HUD is back: choices by preferred text, standoffs by
## the policy's action (clicked as a button), level-ups by the first stat and skill offered.
func advance(prefer: Array, limit: int) -> int:
	var n := 0
	while n < limit:
		n += 1
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
				for sk in ["tally", "steady", "patter", "open_hand"]:
					var skb = _find_button_prefix(Loc.t("sk_" + sk), main.overlay)
					if skb != null:
						await click_node(skb)
						break
				await click_node(c)
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
	await wait(0.6)


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

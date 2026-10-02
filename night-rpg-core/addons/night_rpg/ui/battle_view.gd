class_name NRBattleView
extends Control
## The standoff screen. All numbers come from NRRules; this only shows them and collects
## the player's choices. `policy` (a Callable(b, member_index) -> [action, item_id]) lets
## the tests and screenshot runs play it without clicks.

signal finished(result: String)
signal picked(action: String, item: String)

var b: Dictionary
var enemy_tex: TextureRect
var e_name: Label
var e_comp: TextureProgressBar
var e_susp: TextureProgressBar
var e_susp_lbl: Label
var e_comp_lbl: Label
var weak_lbl: Label
var log_lbl: Label
var party_box: VBoxContainer
var action_box: GridContainer
var actor_lbl: Label
var item_box: VBoxContainer
var policy: Callable
var action_panel: PanelContainer
var delay := 0.55


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_tex = TextureRect.new()
	enemy_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# below the stat panel and bottom-anchored, so the head is never under a panel
	enemy_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_tex.position = Vector2(780, 196)
	enemy_tex.size = Vector2(470, 524)
	enemy_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enemy_tex)
	var top := PanelContainer.new()
	top.position = Vector2(760, 18)
	top.custom_minimum_size = Vector2(500, 0)
	add_child(top)
	var tv := VBoxContainer.new()
	top.add_child(tv)
	e_name = NRSkin.heading("", 30)
	tv.add_child(e_name)
	e_comp_lbl = NRSkin.label("", 18)
	tv.add_child(e_comp_lbl)
	e_comp = NRSkin.meter("bar_fill_gold")
	e_comp.custom_minimum_size = Vector2(460, 16)
	tv.add_child(e_comp)
	e_susp_lbl = NRSkin.label("", 18)
	tv.add_child(e_susp_lbl)
	e_susp = NRSkin.meter("bar_fill")
	e_susp.custom_minimum_size = Vector2(460, 22)
	tv.add_child(e_susp)
	weak_lbl = NRSkin.label("", 17, Color(0.87, 0.74, 0.52))
	tv.add_child(weak_lbl)
	# left column: log, party, actions stacked so nothing overlaps whatever the text length
	var col := VBoxContainer.new()
	col.position = Vector2(24, 18)
	col.size = Vector2(700, 690)
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var lp := PanelContainer.new()
	lp.custom_minimum_size = Vector2(700, 110)
	col.add_child(lp)
	log_lbl = NRSkin.label("", 19)
	log_lbl.custom_minimum_size = Vector2(660, 0)
	lp.add_child(log_lbl)
	var pp := PanelContainer.new()
	pp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pp.custom_minimum_size = Vector2(420, 0)
	col.add_child(pp)
	party_box = VBoxContainer.new()
	party_box.add_theme_constant_override("separation", 10)
	pp.add_child(party_box)
	var ap := PanelContainer.new()
	ap.custom_minimum_size = Vector2(700, 0)
	col.add_child(ap)
	action_panel = ap
	var av := VBoxContainer.new()
	ap.add_child(av)
	actor_lbl = NRSkin.heading("", 24)
	av.add_child(actor_lbl)
	action_box = GridContainer.new()
	action_box.columns = 3
	action_box.add_theme_constant_override("h_separation", 8)
	action_box.add_theme_constant_override("v_separation", 8)
	av.add_child(action_box)
	item_box = VBoxContainer.new()
	av.add_child(item_box)


func start(enemy_id: String) -> String:
	var e: Dictionary = RPG.game["enemies"][enemy_id].duplicate(true)
	b = NRRules.new_battle(enemy_id, e, RPG.battle_party(), int(Time.get_ticks_usec()) % 100000 + 7)
	for a in RPG.s["known"].get(enemy_id, []):
		b["revealed"].append(a)
	enemy_tex.texture = NRArt.tex("enemies", e.get("sprite", enemy_id))
	e_name.text = Loc.t(e["name_key"])
	log_lbl.text = Loc.t(e.get("intro_key", "b_intro"))
	Sound.play_music("boss" if e.get("boss", false) else "battle")
	_refresh()
	action_panel.visible = not policy.is_valid()
	visible = true
	var result := await _loop()
	if not policy.is_valid():
		# let the player read how it ended before the screen goes
		for c in action_box.get_children():
			c.queue_free()
		for c in item_box.get_children():
			c.queue_free()
		action_panel.visible = true
		actor_lbl.text = Loc.t("b_won") if result == "win" else Loc.t("b_lost")
		action_box.add_child(NRSkin.button(Loc.t("ds_continue"), func(): picked.emit("_done", ""), 20))
		await picked
	RPG.absorb_battle(b)
	visible = false
	return result


func _loop() -> String:
	while b["result"] == "":
		for mi in b["party"].size():
			if b["result"] != "":
				break
			var m: Dictionary = b["party"][mi]
			if m["comp"] <= 0:
				continue
			var pick: Array
			if policy.is_valid():
				pick = policy.call(b, mi)
			else:
				_offer(mi)
				pick = await _wait_pick()
			var action: String = pick[0]
			var adef: Dictionary = RPG.game["actions"][action]
			var item := {}
			if action == "item":
				item = RPG.item_def(pick[1])
				RPG.take(pick[1])
			elif adef.get("needs_kind", "") == "cash":
				RPG.take(RPG.first_of_kind("cash"))
			var ev := NRRules.party_act(b, mi, action, adef, item)
			_say_event(ev)
			_refresh()
			if delay > 0:
				await get_tree().create_timer(delay).timeout
		if b["result"] != "":
			break
		var eev := NRRules.enemy_act(b)
		_say_event(eev)
		_refresh()
		if delay > 0:
			await get_tree().create_timer(delay).timeout
	return b["result"]


func _wait_pick() -> Array:
	var r = await picked
	return r


func _offer(mi: int) -> void:
	var m: Dictionary = b["party"][mi]
	actor_lbl.text = Loc.t("n_" + m["id"]) + " — " + Loc.t("b_choose")
	for c in action_box.get_children():
		c.queue_free()
	for c in item_box.get_children():
		c.queue_free()
	var kinds := RPG.kinds()
	for a in RPG.actions_for(m["id"]):
		var adef: Dictionary = RPG.game["actions"][a]
		var label := Loc.t("a_" + a)
		if int(adef.get("cost", 0)) > 0:
			label += "  " + str(adef["cost"])
		if a in b["revealed"]:
			label += "  " + Loc.t("b_" + NRRules.affinity(b["enemy"], a))
		var why := NRRules.can_use(m, adef, kinds)
		if a == "item" and RPG.kinds().get("consumable", 0) == 0:
			why = "r_needs_consumable"
		var btn := NRSkin.button(label, func():
			if a == "item":
				_offer_items()
			else:
				picked.emit(a, ""), 19)
		btn.custom_minimum_size = Vector2(220, 46)
		btn.disabled = why != ""
		btn.tooltip_text = Loc.t("ad_" + a) + ("" if why == "" else "\n" + Loc.t(why))
		action_box.add_child(btn)


func _offer_items() -> void:
	for c in item_box.get_children():
		c.queue_free()
	for id in RPG.s["items"].keys():
		if RPG.item_def(id).get("kind", "") != "consumable":
			continue
		var btn := NRSkin.button("%s ×%d" % [Loc.t("i_" + id), int(RPG.s["items"][id])], func(): picked.emit("item", id), 18)
		item_box.add_child(btn)


func _say_event(ev: Dictionary) -> void:
	var e: Dictionary = b["enemy"]
	var who := Loc.t(e["name_key"]) if ev["who"] == "enemy" else Loc.t("n_" + ev["who"])
	var txt := ""
	if ev["who"] == "enemy":
		var bark_n := int(e.get("barks", 0))
		var bark := ""
		if bark_n > 0:
			bark = Loc.t("bark_%s_%d" % [e.get("bark_set", b["enemy_id"]), (int(b["round"]) % bark_n) + 1]) + "\n"
		txt = bark + Loc.t("b_enemy_turn") % [who, int(ev["susp"]), Loc.t("n_" + str(ev["target"])) if ev["target"] != "" else "", int(ev["dmg"])]
	else:
		txt = Loc.t("b_used") % [who, Loc.t("a_" + ev["action"])]
		if ev["dmg"] > 0:
			txt += " " + Loc.t("b_dmg") % int(ev["dmg"])
		if ev["aff"] == "weak":
			txt += " " + Loc.t("b_weak_hit")
		elif ev["aff"] == "resist":
			txt += " " + Loc.t("b_resist_hit")
		if int(ev["susp"]) != 0:
			txt += " " + Loc.t("b_susp") % ("%+d" % int(ev["susp"]))
		if int(ev.get("heal", 0)) > 0:
			txt += " " + Loc.t("b_heal") % int(ev["heal"])
		if ev["action"] == "threaten":
			txt += "\n" + Loc.t("b_threat_mark")
		Sound.play_sfx("page_flip" if ev["dmg"] > 0 else "click")
	if b["result"] == "win":
		txt += "\n" + Loc.t(e.get("win_key", "b_win"))
	elif b["result"] == "lose":
		txt += "\n" + Loc.t("b_lose")
	log_lbl.text = txt


func _refresh() -> void:
	e_comp.max_value = b["e_comp_max"]
	e_comp.value = b["e_comp"]
	e_comp_lbl.text = Loc.t("b_resolve") % [b["e_comp"], b["e_comp_max"]]
	e_susp.max_value = 100
	e_susp.value = b["suspicion"]
	e_susp_lbl.text = Loc.t("b_suspicion") % b["suspicion"] + ("   " + Loc.t("b_marked") if b["threatened"] else "")
	var ws := []
	for a in b["revealed"]:
		ws.append(Loc.t("a_" + a) + " " + Loc.t("b_" + NRRules.affinity(b["enemy"], a)))
	weak_lbl.text = Loc.t("b_known") + " " + (", ".join(ws) if ws.size() > 0 else "—")
	for c in party_box.get_children():
		c.queue_free()
	for p in b["party"]:
		var row := VBoxContainer.new()
		row.add_child(NRSkin.label("%s   Lv %d" % [Loc.t("n_" + p["id"]), int(RPG.s["level"])], 20))
		var c := NRSkin.meter("bar_fill_gold")
		c.max_value = p["comp_max"]
		c.value = p["comp"]
		row.add_child(c)
		row.add_child(NRSkin.label(Loc.t("b_comp_nerve") % [p["comp"], p["comp_max"], p["nerve"], p["nerve_max"]], 16))
		party_box.add_child(row)

extends Control
## OCCUPANCY's second genre: the office (management + staff recruiting). Opened by the step
## {"screen": "res://scripts/office.gd", "args": {"floor": "n1", "plate": "open_plan"}}.
##
## The loop, numbers in game.json "office" (tools/build_data.py), run state RPG.s["office"]:
##   floor     Overtime Landlord's 5x4 board. Staff you have recruited (each once) and the
##             objects you own (as many as you have) go on desks; Roster.settle_idle() -- the
##             committed landlord.gd/roster.gd, unchanged -- scores it, links and chain and all.
##             The preview is live, so the layout is the skill. Run the night shift ONCE per
##             night: the board settles `shifts` times into the rent fund. The night's rent is
##             paid at its crisis (the standoff); short, and the crisis is the hard row.
##             A party woman who worked the shift gets +1 Trust (once a night).
##   recruit   the staff gacha, in-game rent fund only: common/rare/epic with a pity of 10.
##             A new woman joins the party; a repeat raises her overtime bonus (the board's
##             dupe bonus) and one of her stats.
##   supplies  objects for the board, consumables and kit for the standoffs, one gift each.
## The sim plays it with the same code (main.auto). `--office=ignore` on the command line is
## the player who never uses it; `--office=random` places at random (the board-matters check).

signal _picked(v)

var main
var cfg: Dictionary
var st: Dictionary
var auto := false
var mode := "smart"
var floor_id := ""
var plate := "open_plan"
var sel := ""          # the piece picked in the palette
var cells: Array = []
var msg: Label
var info: VBoxContainer
var grid: GridContainer
var palette: VBoxContainer
var recruit_box: VBoxContainer
var supplies_box: VBoxContainer
var cards: HBoxContainer
var tabs: TabContainer
var run_btn: Button
var rng := RandomNumberGenerator.new()


static func state() -> Dictionary:
	var c: Dictionary = RPG.game.get("office", {})
	if not RPG.s.has("office"):
		RPG.s["office"] = {"owned": c.get("start_owned", {}).duplicate(), "objects": c.get("start_objects", {}).duplicate(),
			"pulls": 0, "since_epic": 0, "ran": {}, "board": [], "bought": [], "seed": 7331, "earned": 0}
	return RPG.s["office"]


func run(m, args: Dictionary) -> String:
	main = m
	auto = bool(main.auto)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--office="):
			mode = a.trim_prefix("--office=")
	cfg = RPG.game.get("office", {})
	st = state()
	floor_id = str(args.get("floor", RPG.s.get("night", "")))
	plate = str(args.get("plate", "open_plan"))
	rng.seed = int(st.get("seed", 7331)) + int(st["pulls"]) * 7919
	var md := str(args.get("mode", "office"))
	if md == "hire" or md == "join":
		# the story's free recruit (Priya, night one) and the fallbacks that bring Nia and Sol
		# if the recruit pool has not: the gacha widens the party, it never gates it
		var id := str(args.get("id", ""))
		if md == "join" and int(st["owned"].get(id, 0)) > 0:
			return "ok"
		_build()
		tabs.current_tab = 1
		_grant(id, true)
		await _pause(1.6)
		if not auto:
			await _wait_done()
		RPG.changed.emit()
		return "ok"
	_build()
	cells = _start_cells()
	_refresh()
	if auto:
		await _auto_play()
	else:
		await _wait_done()
	st["board"] = cells.duplicate()
	RPG.changed.emit()
	return "ok"


# ------------------------------------------------------------------ rules (pure, used by the sim)

func rent_due() -> int:
	return int(cfg.get("rent", {}).get(floor_id, 0))


func pieces() -> Dictionary:
	## what can go on the board: each recruited staffer once, each object as many as owned
	var out := {}
	for id in st["owned"].keys():
		if int(st["owned"][id]) > 0:
			out[id] = 1
	for id in st["objects"].keys():
		if int(st["objects"][id]) > 0:
			out[id] = int(st["objects"][id])
	return out


func dupes() -> Dictionary:
	var d := {}
	for id in st["owned"].keys():
		d[id] = max(0, int(st["owned"][id]) - 1)
	return d


func settle(c: Array) -> Dictionary:
	return Roster.settle_idle(c, [], dupes())


func shift_value(c: Array) -> int:
	return int(settle(c)["shift"])


func placed_count(c: Array, id: String) -> int:
	var n := 0
	for v in c:
		if v != null and str(v) == id:
			n += 1
	return n


func can_place(c: Array, id: String) -> bool:
	return placed_count(c, id) < int(pieces().get(id, 0))


## Greedy layout: keep dropping the piece/desk pair that raises the shift most.
func best_layout(start: Array) -> Array:
	var c := start.duplicate()
	var avail := pieces()
	for _guard in range(Landlord.SIZE):
		var base := shift_value(c)
		var best := 0
		var pick := []
		for id in avail.keys():
			if placed_count(c, id) >= int(avail[id]):
				continue
			for i in range(Landlord.SIZE):
				if c[i] != null:
					continue
				c[i] = id
				var v := shift_value(c) - base
				c[i] = null
				if v > best:
					best = v
					pick = [id, i]
		if pick.is_empty():
			break
		c[pick[1]] = pick[0]
	# a second pass: try swapping every pair once; links depend on neighbours
	var improved := true
	var rounds := 0
	while improved and rounds < 3:
		improved = false
		rounds += 1
		var cur := shift_value(c)
		for i in range(Landlord.SIZE):
			for j in range(i + 1, Landlord.SIZE):
				if c[i] == c[j]:
					continue
				var t = c[i]
				c[i] = c[j]
				c[j] = t
				var v := shift_value(c)
				if v > cur:
					cur = v
					improved = true
				else:
					c[j] = c[i]
					c[i] = t
	return c


func random_layout() -> Array:
	var c := Landlord.empty_cells()
	var bag := []
	var avail := pieces()
	for id in avail.keys():
		for _k in int(avail[id]):
			bag.append(id)
	var free := range(Landlord.SIZE)
	var r := RandomNumberGenerator.new()
	r.seed = 99 + int(st["pulls"]) + floor_id.hash()
	for id in bag:
		if free.is_empty():
			break
		var k := r.randi() % free.size()
		c[free[k]] = id
		free.remove_at(k)
	return c


func ran_tonight() -> bool:
	return st["ran"].has(floor_id)


func run_shift() -> int:
	if ran_tonight():
		return 0
	var shifts := int(cfg.get("shifts", 8))
	var earned := shift_value(cells) * shifts
	RPG.give("coin", earned)
	st["ran"][floor_id] = earned
	RPG.set_flag("ran_" + floor_id)
	st["earned"] = int(st.get("earned", 0)) + earned
	RPG.spend_turns(2)
	main.pace["choice"] += 20.0
	# the women who worked it
	var tn := int(cfg.get("trust_on_shift", 1))
	for mid in cfg.get("party", []):
		if placed_count(cells, mid) > 0 and RPG.in_party(mid) and tn > 0:
			RPG.add_trust(tn, mid)
			_note(Loc.t("of_trust") % Loc.t("n_" + mid))
	return earned


func pull_one() -> String:
	var rates: Dictionary = cfg.get("rates", {"common": 70, "rare": 25, "epic": 5})
	var pity := int(cfg.get("pity", 10))
	var rar := "common"
	if int(st["since_epic"]) >= pity - 1:
		rar = "epic"
	else:
		var roll := rng.randi() % (int(rates["common"]) + int(rates["rare"]) + int(rates["epic"]))
		if roll < int(rates["epic"]):
			rar = "epic"
		elif roll < int(rates["epic"]) + int(rates["rare"]):
			rar = "rare"
	var pool := []
	for id in cfg.get("pool", {}).get(rar, []):
		var need: String = cfg.get("pool_flags", {}).get(id, "")
		if need == "" or RPG.flag(need):
			pool.append(id)
	if pool.is_empty():
		pool = cfg.get("pool", {}).get("common", ["dan"])
	var id: String = pool[rng.randi() % pool.size()]
	st["pulls"] = int(st["pulls"]) + 1
	st["since_epic"] = 0 if rar == "epic" else int(st["since_epic"]) + 1
	return id


func rarity_of(id: String) -> String:
	for r in ["epic", "rare", "common"]:
		if id in cfg.get("pool", {}).get(r, []):
			return r
	return "common"


## Add a recruit to the roster; a party woman joins (or, again, grows).
func _grant(id: String, story := false) -> void:
	var had := int(st["owned"].get(id, 0))
	st["owned"][id] = had + 1
	var is_party: bool = id in cfg.get("party", [])
	var line := ""
	if had == 0:
		if is_party:
			var jf: String = RPG.member_def(id).get("join_flag", "")
			if jf != "":
				RPG.set_flag(jf)
			RPG.restore_party()
			line = Loc.t("of_joined") % Loc.t("n_" + id)
		else:
			line = Loc.t("of_got") % [Loc.t("pc_" + id), Loc.t("of_rarity_" + rarity_of(id))]
	else:
		if is_party and had <= 5:
			var g: String = RPG.member_def(id).get("grow", ["wit"])[0]
			RPG.s["members"][id]["base"][g] = int(RPG.s["members"][id]["base"].get(g, 0)) + 1
			line = Loc.t("of_dupe") % [Loc.t("pc_" + id), Loc.t("s_" + g)]
		else:
			line = Loc.t("of_dupe_board") % Loc.t("pc_" + id)
	_card(id)
	_note(line)
	Sound.play_sfx("sting" if rarity_of(id) == "epic" else "page_flip")


func pull(n: int) -> void:
	var cost := int(cfg.get("pull_cost", 40)) if n == 1 else int(cfg.get("pull10_cost", 360))
	if int(RPG.s["items"].get("coin", 0)) < cost:
		_note(Loc.t("of_broke"))
		return
	RPG.take("coin", cost)
	_clear_cards()
	for _i in n:
		_grant(pull_one())
	main.pace["choice"] += 6.0 * n
	_refresh()


func buy(id: String) -> bool:
	var objs: Dictionary = cfg.get("objects", {})
	var sup: Dictionary = cfg.get("supplies", {})
	var cost := int(objs.get(id, sup.get(id, 0)))
	if cost <= 0 or int(RPG.s["items"].get("coin", 0)) < cost:
		_note(Loc.t("of_broke"))
		return false
	if id in cfg.get("once", []) and id in st["bought"]:
		return false
	RPG.take("coin", cost)
	if objs.has(id):
		st["objects"][id] = int(st["objects"].get(id, 0)) + 1
	else:
		RPG.give(id)
		if id in cfg.get("once", []):
			st["bought"].append(id)
	Sound.play_sfx("click")
	_refresh()
	return true


func _start_cells() -> Array:
	var c := Landlord.empty_cells()
	var prev: Array = st.get("board", [])
	if prev.size() == Landlord.SIZE:
		for i in range(Landlord.SIZE):
			if prev[i] != null and can_place(c, str(prev[i])):
				c[i] = str(prev[i])
	return c


# ------------------------------------------------------------------ the scripted player

func _auto_play() -> void:
	if mode == "ignore":
		return
	var shot: bool = main.shot_hook.is_valid()
	if shot:
		await _pause(0.4)
		await main.shot_hook.call("office")
	# furniture first, if it pays for itself within the nights left
	var nights_left: int = max(1, RPG.game["nights"].size() - RPG.game["nights"].find(floor_id))
	var shifts := int(cfg.get("shifts", 8))
	for _k in 4:
		if mode != "smart":
			break
		var base := shift_value(best_layout(cells))
		var pick := ""
		var gain := 0
		for id in cfg.get("objects", {}).keys():
			var cost := int(cfg["objects"][id])
			if int(RPG.s["items"].get("coin", 0)) < cost:
				continue
			st["objects"][id] = int(st["objects"].get(id, 0)) + 1
			var after := shift_value(best_layout(cells))
			var g := (after - base) * shifts * nights_left - cost
			st["objects"][id] = int(st["objects"][id]) - 1
			# never spend tonight's rent: the fund after buying plus the shift must still cover it
			if int(RPG.s["items"].get("coin", 0)) - cost + after * shifts < rent_due():
				continue
			if g > gain:
				gain = g
				pick = id
		if pick == "":
			break
		buy(pick)
	cells = random_layout() if mode == "random" else best_layout(cells)
	_refresh()
	if shot:
		await _pause(0.4)
		await main.shot_hook.call("office_built")
	run_shift()
	_refresh()
	# recruit with what is left over the rent still due tonight
	var reserve := rent_due()
	var pc := int(cfg.get("pull_cost", 40))
	var p10 := int(cfg.get("pull10_cost", 360))
	if mode == "smart":
		while int(RPG.s["items"].get("coin", 0)) - p10 >= reserve:
			pull(10)
			if shot:
				tabs.current_tab = 1
				await _pause(0.5)
				await main.shot_hook.call("recruit10")
		while int(RPG.s["items"].get("coin", 0)) - pc >= reserve:
			pull(1)
			if shot:
				tabs.current_tab = 1
				await _pause(0.4)
				await main.shot_hook.call("recruit")
		# a gift for whoever is closest to her next after-hours, if it is cheap enough
		for g in ["whisky", "craft_beer", "ink", "first_edition", "orchid", "mara_after", "priya_after", "nia_after", "sol_after"]:
			var cost := int(cfg.get("supplies", {}).get(g, 999))
			if g in st["bought"] or int(RPG.s["items"].get("coin", 0)) - cost < reserve:
				continue
			buy(g)
		cells = best_layout(cells)
	_refresh()
	if shot:
		tabs.current_tab = 2
		await _pause(0.4)
		await main.shot_hook.call("supplies")
		tabs.current_tab = 0


# ------------------------------------------------------------------ ui

func _tex(p: String) -> Texture2D:
	return load(p) if ResourceLoader.exists(p) else null


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := TextureRect.new()
	bg.texture = NRArt.tex("rooms", plate)
	bg.size = Vector2(1280, 720)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var scrim := ColorRect.new()
	scrim.color = Color(0.06, 0.04, 0.08, 0.42)
	scrim.size = Vector2(1280, 720)
	add_child(scrim)
	# left: the floor
	var lp := PanelContainer.new()
	lp.position = Vector2(20, 16)
	lp.custom_minimum_size = Vector2(640, 140)
	add_child(lp)
	info = VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	lp.add_child(info)
	grid = GridContainer.new()
	grid.columns = Landlord.COLS
	grid.position = Vector2(28, 172)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	var mp := PanelContainer.new()
	mp.add_theme_stylebox_override("panel", NRSkin.box("textbox", 12))
	mp.position = Vector2(20, 640)
	mp.custom_minimum_size = Vector2(640, 64)
	add_child(mp)
	msg = NRSkin.label(Loc.t("of_run_hint"), 16)
	msg.custom_minimum_size = Vector2(610, 0)
	mp.add_child(msg)
	# right: tabs
	tabs = TabContainer.new()
	tabs.position = Vector2(680, 16)
	tabs.size = Vector2(580, 620)
	tabs.add_theme_font_size_override("font_size", 20)
	add_child(tabs)
	var fl := VBoxContainer.new()
	fl.name = Loc.t("of_tab_floor")
	tabs.add_child(fl)
	var fs := ScrollContainer.new()
	fs.custom_minimum_size = Vector2(560, 440)
	fl.add_child(fs)
	palette = VBoxContainer.new()
	palette.add_theme_constant_override("separation", 4)
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs.add_child(palette)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	fl.add_child(row)
	row.add_child(NRSkin.button(Loc.t("of_auto"), func():
		cells = best_layout(cells)
		_refresh(), 17))
	row.add_child(NRSkin.button(Loc.t("of_clear"), func():
		cells = Landlord.empty_cells()
		_refresh(), 17))
	run_btn = NRSkin.button(Loc.t("of_run"), func():
		var e := run_shift()
		_note(Loc.t("of_ran") % e)
		Sound.play_sfx("sting")
		_refresh(), 20)
	fl.add_child(run_btn)
	var rc := VBoxContainer.new()
	rc.name = Loc.t("of_tab_recruit")
	rc.add_theme_constant_override("separation", 6)
	tabs.add_child(rc)
	recruit_box = VBoxContainer.new()
	rc.add_child(recruit_box)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 4)
	rc.add_child(cards)
	var sp := ScrollContainer.new()
	sp.name = Loc.t("of_tab_supplies")
	sp.custom_minimum_size = Vector2(560, 560)
	tabs.add_child(sp)
	supplies_box = VBoxContainer.new()
	supplies_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies_box.add_theme_constant_override("separation", 4)
	sp.add_child(supplies_box)
	var done := NRSkin.button(Loc.t("of_done"), func(): _picked.emit("done"), 22)
	done.position = Vector2(980, 650)
	done.custom_minimum_size = Vector2(280, 52)
	add_child(done)


func _wait_done() -> void:
	await _picked


func _pause(t: float) -> void:
	if auto and not main.shot_hook.is_valid():
		return
	await get_tree().create_timer(t).timeout


func _note(t: String) -> void:
	if msg != null:
		msg.text = t


func _clear_cards() -> void:
	if cards == null:
		return
	for c in cards.get_children():
		c.queue_free()


func _card(id: String) -> void:
	if cards == null:
		return
	if cards.get_child_count() >= 10:
		cards.get_child(0).queue_free()
	var p := PanelContainer.new()
	var rar := rarity_of(id)
	p.add_theme_stylebox_override("panel", NRSkin.box("slot_hover" if rar != "common" else "slot_idle", 4))
	var v := VBoxContainer.new()
	p.add_child(v)
	var t := TextureRect.new()
	t.texture = _tex("res://assets/board/%s.png" % id)
	t.custom_minimum_size = Vector2(50, 66) if cards.get_child_count() > 3 else Vector2(120, 160)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	v.add_child(t)
	var col := Color(1.0, 0.82, 0.35) if rar == "epic" else (Color(0.65, 0.85, 1.0) if rar == "rare" else Color(0.9, 0.86, 0.8))
	v.add_child(NRSkin.label(Loc.t("pc_" + id), 13, col))
	cards.add_child(p)


func _refresh() -> void:
	if info == null:
		return
	for c in info.get_children():
		c.queue_free()
	var r := settle(cells)
	var shifts := int(cfg.get("shifts", 8))
	var nt: String = RPG.night().get("title_key", "")
	info.add_child(NRSkin.heading(Loc.t("of_title") % (Loc.t(nt) if nt != "" else ""), 24))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	info.add_child(top)
	for lt in [NRSkin.label(Loc.t("of_fund") % int(RPG.s["items"].get("coin", 0)), 19, Color(1.0, 0.85, 0.45)),
			NRSkin.label(Loc.t("of_rent") % rent_due(), 19, Color(1.0, 0.6, 0.55))]:
		lt.autowrap_mode = TextServer.AUTOWRAP_OFF
		top.add_child(lt)
	var pl: Label
	if ran_tonight():
		pl = NRSkin.label(Loc.t("of_ran_short") % int(st["ran"][floor_id]), 18, Color(0.6, 1.0, 0.7))
	else:
		pl = NRSkin.label(Loc.t("of_preview") % [int(r["shift"]), shifts, int(r["shift"]) * shifts], 18)
	pl.custom_minimum_size = Vector2(610, 0)
	info.add_child(pl)
	var evs := {}
	for e in r["events"]:
		evs[e] = int(evs.get(e, 0)) + 1
	var parts := []
	for e in evs.keys():
		parts.append(("%s ×%d" % [Loc.t("ev_" + e), evs[e]]) if evs[e] > 1 else Loc.t("ev_" + e))
	var el := NRSkin.label((Loc.t("of_chain") % [int(r["chain"]), float(r["mult"])]) + "   " + (Loc.t("of_events") % (", ".join(parts) if parts.size() else Loc.t("of_none"))), 14, Color(0.85, 0.8, 0.9))
	el.custom_minimum_size = Vector2(620, 0)
	# two lines at most: the full list is on hover (German and CJK run longer than English)
	el.max_lines_visible = 2
	el.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	el.tooltip_text = el.text
	el.mouse_filter = Control.MOUSE_FILTER_PASS
	el.add_theme_constant_override("line_spacing", -2)
	info.add_child(el)
	# the board
	for c in grid.get_children():
		c.queue_free()
	for i in range(Landlord.SIZE):
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 88)
		b.clip_contents = true
		var id: String = "" if cells[i] == null else str(cells[i])
		if id != "":
			var tr := TextureRect.new()
			tr.texture = _tex("res://assets/board/%s.png" % id)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tr)
			var sc := NRSkin.label("+%d" % int(r["cellScore"][i]), 18, Color(1.0, 0.9, 0.5))
			sc.position = Vector2(4, 62)
			sc.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			sc.add_theme_constant_override("outline_size", 6)
			sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(sc)
			b.tooltip_text = Loc.t("pc_" + id) + " — " + Loc.t("pr_" + id)
		var idx := i
		b.pressed.connect(func(): _cell_clicked(idx))
		b.disabled = ran_tonight()
		grid.add_child(b)
	# palette
	for c in palette.get_children():
		c.queue_free()
	palette.add_child(NRSkin.label(Loc.t("of_pieces"), 16, Color(0.87, 0.74, 0.52)))
	var av := pieces()
	for id in av.keys():
		var left := int(av[id]) - placed_count(cells, id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var ic := TextureRect.new()
		ic.texture = _tex("res://assets/board/%s.png" % id)
		ic.custom_minimum_size = Vector2(44, 44)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(ic)
		var t := "%s ×%d — %s" % [Loc.t("pc_" + id), left, Loc.t("pr_" + id)]
		var pid: String = id
		var bb := NRSkin.button(t, func():
			sel = pid
			_refresh(), 14)
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.disabled = left <= 0 or ran_tonight()
		bb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if sel == id:
			bb.modulate = Color(1.3, 1.15, 0.8)
		row.add_child(bb)
		palette.add_child(row)
	run_btn.disabled = ran_tonight()
	# recruit
	for c in recruit_box.get_children():
		c.queue_free()
	recruit_box.add_child(NRSkin.label(Loc.t("of_fund") % int(RPG.s["items"].get("coin", 0)), 20, Color(1.0, 0.85, 0.45)))
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	recruit_box.add_child(rr)
	rr.add_child(NRSkin.button(Loc.t("of_recruit") % int(cfg.get("pull_cost", 40)), func(): pull(1), 18))
	rr.add_child(NRSkin.button(Loc.t("of_recruit10") % int(cfg.get("pull10_cost", 360)), func(): pull(10), 18))
	recruit_box.add_child(NRSkin.label(Loc.t("of_pity") % (int(cfg.get("pity", 10)) - int(st["since_epic"])), 15, Color(1.0, 0.82, 0.35)))
	var rates: Dictionary = cfg.get("rates", {})
	for rar in ["epic", "rare", "common"]:
		var names := []
		for id in cfg.get("pool", {}).get(rar, []):
			var need: String = cfg.get("pool_flags", {}).get(id, "")
			if need == "" or RPG.flag(need):
				names.append(Loc.t("pc_" + id))
		recruit_box.add_child(NRSkin.label("%s %d%% — %s" % [Loc.t("of_rarity_" + rar), int(rates.get(rar, 0)), ", ".join(names)], 15))
	recruit_box.add_child(NRSkin.label(Loc.t("of_no_money_note"), 13, Color(0.75, 0.7, 0.65)))
	# supplies
	for c in supplies_box.get_children():
		c.queue_free()
	var all := {}
	for id in cfg.get("objects", {}).keys():
		all[id] = int(cfg["objects"][id])
	for id in cfg.get("supplies", {}).keys():
		all[id] = int(cfg["supplies"][id])
	for id in all.keys():
		if id in st["bought"]:
			continue
		var nm := Loc.t("pc_" + id) if cfg.get("objects", {}).has(id) else Loc.t("i_" + id)
		var have := int(st["objects"].get(id, 0)) if cfg.get("objects", {}).has(id) else int(RPG.s["items"].get(id, 0))
		var desc := Loc.t("pr_" + id) if cfg.get("objects", {}).has(id) else Loc.t("id_" + id)
		var bid: String = id
		var b2 := NRSkin.button("%s   (%s)   %s" % [Loc.t("of_buy") % [nm, int(all[id])], Loc.t("of_owned") % have, desc], func(): buy(bid), 14)
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b2.custom_minimum_size = Vector2(540, 0)
		b2.disabled = int(RPG.s["items"].get("coin", 0)) < int(all[id])
		supplies_box.add_child(b2)


func _cell_clicked(i: int) -> void:
	if ran_tonight():
		return
	if cells[i] != null:
		cells[i] = null
	elif sel != "" and can_place(cells, sel):
		cells[i] = sel
	Sound.play_sfx("click")
	_refresh()

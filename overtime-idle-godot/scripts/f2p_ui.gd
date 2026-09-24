class_name F2PPanel
extends Overlay
## The Nutaku free-to-play office: six tabs over the server's state (F2P.st()).
##
##   STORY     the campaign: the chapter, its rival, its goals (checked by the server), the
##             rival's bid (a 48 h window on the server clock), complete -> the next chapter
##   STAFF     affection ladder per character (talk once a day, today's board request,
##             gifts, gift boxes), the
##             tier rewards (a line, then a scene), rank-ups (character evolution)
##   DAILY     login calendar + streak, three daily missions + bonus, five weekly goals,
##             the Night Shift Pass, the daily floor
##   UPGRADES  fit-outs per floor, relics, objects, time skips, selling the building
##   SHOP      Nutaku gold SKUs (the platform's own confirm dialog does the charging)
##   SCENES    every scene the server has unlocked for this player, fetched from it
##   BOARD     the leaderboards (lifetime rent, today's daily floor)
##
## Nothing here decides a number. Every button is an F2P.act() or F2P.buy(), and the panel
## redraws from whatever state the server answers with.

signal daily_floor_requested
signal view_scene(id: String, title: String)
signal juice(kind: String, data: Dictionary)

const TABS := ["story", "staff", "daily", "upgrades", "shop", "scenes", "board"]
const TAB_NAME := {"story": "STORY", "staff": "STAFF", "daily": "DAILY", "upgrades": "UPGRADES", "shop": "SHOP",
	"scenes": "SCENES", "board": "BOARD"}
const OBJ_NAME := {"coffee": "Coffee", "mute": "Headphones", "printer": "Printer", "corner": "Corner desk"}
const RELIC_NAME := {"severance": "Severance", "quiet": "Quiet Floor", "pto": "PTO", "glass": "Glass Office",
	"badge": "Badge", "army": "Intern Army"}
const SHOP_ORDER := ["starter", "pass_30", "ticket_1", "ticket_10", "boost_3d", "boost_7d", "night_manager",
	"timeskip_4", "timeskip_12", "gift_box_3", "shield_3"]

var tab := "staff"
var tab_row: HBoxContainer
var content: VBoxContainer
var status_l: Label
var _board: Dictionary = {}


func build() -> void:
	card_width = 1040
	card.custom_minimum_size = Vector2(1040, 0)
	tag("OCCUPANCY · THE OFFICE")
	var head := HBoxContainer.new()
	body.add_child(head)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tab_row)
	var cb := StudioTheme.stub("CLOSE", "Ghost", true)
	cb.pressed.connect(close)
	cb.custom_minimum_size = Vector2(96, 38)
	head.add_child(cb)
	status_l = Label.new()
	status_l.theme_type_variation = "Value"
	status_l.add_theme_color_override("font_color", Palette.GOLD)
	body.add_child(status_l)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(990, 0)
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	F2P.ot_changed.connect(func() -> void:
		if is_open():
			render())


func open_tab(t: String) -> void:
	tab = t if TABS.has(t) else "staff"
	if is_open():
		render()
	open()
	if tab == "board":
		_load_board()


func on_open() -> void:
	render()


# ---------------------------------------------------------------------- drawing

func render() -> void:
	clear(tab_row)
	for t in TABS:
		var key: String = t
		var b := StudioTheme.stub(TAB_NAME[t], "Active" if t == tab else "", true)
		b.pressed.connect(func() -> void:
			tab = key
			if key == "board":
				_load_board()
			render())
		b.custom_minimum_size = Vector2(112, 38)
		b.add_theme_font_size_override("font_size", 13)
		tab_row.add_child(b)
	var s := F2P.st()
	if s.is_empty():
		status_l.text = "Connecting to the building…"
		return
	status_l.text = "Bank %s  ·  %s/h  ·  %d tickets  ·  %d time skips  ·  %d gift boxes%s" % [
		RollingLabel._fmt(float(s["bank"])), RollingLabel._fmt(float(s["income_h"])), int(s["tickets"]),
		int(s["timeskips"]), int(s["gift_boxes"]), ("  ·  DOUBLE PAY" if bool(s["boost"]["active"]) else "")]
	clear(content)
	match tab:
		"story": _story(s)
		"staff": _staff(s)
		"daily": _daily(s)
		"upgrades": _upgrades(s)
		"shop": _shop(s)
		"scenes": _scenes(s)
		"board": _board_tab()


func _row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	content.add_child(h)
	return h


func _label(parent: Control, txt: String, color: Color = Palette.TEXT, size: int = 14, expand: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	# wrap only where the label owns the width (a column, or the stretchy cell of a row);
	# a wrapping label in a row cell with no width of its own collapses to one letter wide
	var in_row := parent is HBoxContainer
	if expand or not in_row:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


func _small(txt: String, variation: String, on: Callable, disabled: bool = false) -> Button:
	var b := StudioTheme.stub(txt, variation, true)
	if on.is_valid():
		b.pressed.connect(on)
	b.custom_minimum_size = Vector2(maxf(96.0, 8.5 * txt.length() + 28.0), 36)
	b.add_theme_font_size_override("font_size", 12)
	b.disabled = disabled
	return b


func _section(txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = "Tag"
	content.add_child(l)


func _money(v) -> String:
	return RollingLabel._fmt(float(v))


# ------------------------------------------------------------------------- STORY

func _story(s: Dictionary) -> void:
	var cp: Dictionary = s["campaign"]
	if bool(cp["done"]):
		_section("THE STORY IS COMPLETE · the tower is yours")
		para_into("Weekly events and the daily floor carry on; new chapters arrive with content updates.")
		return
	var ch: Dictionary = cp["chapter"]
	_section("CHAPTER %d OF %d · BUILDING %d · %s" % [int(cp["index"]) + 1, int(cp["of"]), int(ch["building"]), str(ch["title"]).to_upper()])
	if ch.get("rival") != null:
		_label(content, "Rival: " + str(ch["rival"]), Palette.HEAT, 14)
	_label(content, str(ch["intro"]), Palette.TEXT, 15)
	_section("GOALS")
	for g in cp["goals"]:
		var h := _row()
		var have = g["have"]
		var prog := ""
		if typeof(have) == TYPE_DICTIONARY:
			prog = "%d taxed, %d thin" % [int(have["taxed"]), int(have["thin"])]
		elif str(g["kind"]) != "no_tax":
			prog = "%s / %s" % [_money(have), _money(g["need"])]
		_label(h, ("DONE · " if bool(g["done"]) else "• ") + str(g["text"]) + ("   " + prog if prog != "" else ""),
				Palette.SUCCESS if bool(g["done"]) else Palette.TEXT, 14, true)
	var bs = ch.get("boss")
	if bs != null:
		var bst = cp.get("boss")
		_section("THE RIVAL'S BID · " + str(bs["title"]).to_upper())
		_label(content, str(bs["text"]), Palette.ACCENT_SOFT, 14)
		var h2 := _row()
		if bst == null:
			_label(h2, "Target %s in %d hours of the server clock." % [_money(bs["target"]), int(bs["hours"])], Palette.TEXT, 13, true)
			h2.add_child(_small("ACCEPT THE BID", "Primary", func() -> void: _act_juice("/chapter/boss", {}, "boss"),
					int(ch["building"]) != int(s["building"]["no"])))
		else:
			var left := maxi(0, int(bst["deadline_ms"]) - int(s["server_ms"])) / 60000
			var status := str(bst["status"])
			_label(h2, "%s  ·  %s / %s%s" % [status.to_upper(), _money(bst["earned"]), _money(bst["target"]),
					("  ·  %dh %02dm left" % [left / 60, left % 60]) if status == "active" else ""],
					Palette.SUCCESS if status == "won" else (Palette.HEAT if status == "failed" else Palette.GOLD), 14, true)
			if status == "failed":
				h2.add_child(_small("TAKE IT AGAIN", "Primary", func() -> void: _act_juice("/chapter/boss", {}, "boss")))
	var fin := _row()
	_label(fin, "Reward: " + _reward_text(ch["reward"]), Palette.GOLD, 13, true)
	fin.add_child(_small("COMPLETE CHAPTER", "Amber", func() -> void: _act_juice("/chapter/complete", {}, "chapter"),
			not bool(cp["complete"])))
	if bool(cp.get("blocks_sale", false)):
		para_into("This building cannot be sold until its chapters are complete.")


# ------------------------------------------------------------------------- STAFF

func _staff(s: Dictionary) -> void:
	for ch in s["roster"]:
		var id := str(ch["id"])
		var owned := int(ch.get("owned", 1)) > 0
		var panel := PanelContainer.new()
		panel.theme_type_variation = "Glass"
		content.add_child(panel)
		var v := VBoxContainer.new()
		panel.add_child(v)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		v.add_child(top)
		var who := "%s, %d" % [ch["name"], int(ch["age"])]
		if ch.has("rank"):
			who += "   ·   rank %d   ·   %d slot%s" % [int(ch["rank"]), int(ch["slots"]), "" if int(ch["slots"]) == 1 else "s"]
		_label(top, who, Palette.GOLD_PALE if owned else Palette.MUTED, 16, true)
		_label(top, "TIER %d / 5" % int(ch["tier"]), Palette.HEAT, 15)
		var nxt = ch.get("next_at")
		_label(top, ("%d / %d" % [int(ch["aff"]), int(nxt)]) if nxt != null else "all tiers", Palette.TEXT, 13)
		if not owned:
			_label(v, "Not on the roster yet. Pull on the staff board to meet them.", Palette.MUTED, 13)
			continue
		var acts := HBoxContainer.new()
		acts.add_theme_constant_override("separation", 6)
		v.add_child(acts)
		acts.add_child(_small("TALK", "Primary", func() -> void: _talk(id), bool(ch["talked_today"])))
		acts.add_child(_small("GIFT (%d/3 today)" % int(ch["gifts_today"]), "", func() -> void: _gift(id, false), int(ch["gifts_today"]) >= 3))
		acts.add_child(_small("GIFT BOX (%d)" % int(s["gift_boxes"]), "Amber", func() -> void: _gift(id, true), int(s["gift_boxes"]) < 1))
		if ch.has("rank"):
			var rc = ch.get("rank_cost")
			var need := int(ch.get("rank_needs_tier", 0))
			var ok: bool = rc != null and int(ch["tier"]) >= need and int(s["bank"]) >= int(rc)
			var lbl := "MAX RANK" if rc == null else ("RANK UP · %s" % _money(rc) if int(ch["tier"]) >= need else "RANK UP needs tier %d" % need)
			acts.add_child(_small(lbl, "Pull", func() -> void: _rank(id), not ok))
		for rq in s.get("requests", []):
			if str(rq["char"]) != id:
				continue
			var rh := HBoxContainer.new()
			v.add_child(rh)
			var mark := "DONE · " if bool(rq["claimed"]) else ("READY · " if bool(rq["done"]) else "• ")
			_label(rh, mark + "TODAY'S REQUEST · " + str(rq["text"]), Palette.SUCCESS if bool(rq["done"]) else Palette.ACCENT_SOFT, 13, true)
			rh.add_child(_small("DONE" if bool(rq["claimed"]) else "CLAIM +20", "Primary",
					func() -> void: _act_juice("/request/claim", {"char": id}, "talk"), bool(rq["claimed"]) or not bool(rq["done"])))
		for t in ch["tiers"]:
			if not bool(t["reached"]):
				continue
			if str(t["kind"]) == "line":
				_label(v, "Tier %d · \"%s\"" % [int(t["tier"]), str(t["text"])], Palette.TEXT, 13)
			else:
				var sid := str(t["scene"])
				var ttl := str(t["title"])
				var h := HBoxContainer.new()
				v.add_child(h)
				_label(h, "Tier %d · SCENE · %s" % [int(t["tier"]), ttl], Palette.GOLD, 13, true)
				h.add_child(_small("VIEW", "Amber", func() -> void: view_scene.emit(sid, ttl)))


func _talk(id: String) -> void:
	var r := await F2P.act("/talk", {"char": id})
	if r["ok"]:
		Sfx.combo()
		juice.emit("talk", {"char": id})


func _gift(id: String, box: bool) -> void:
	var r := await F2P.act("/gift", {"char": id, "box": box})
	if r["ok"]:
		Sfx.shop()
		juice.emit("gift", {"char": id, "points": int(r["body"].get("points", 0))})


func _rank(id: String) -> void:
	var r := await F2P.act("/rank", {"char": id})
	if r["ok"]:
		juice.emit("levelup", {"char": id, "rank": int(r["body"].get("rank", 0))})


# ------------------------------------------------------------------------- DAILY

func _daily(s: Dictionary) -> void:
	var d: Dictionary = s["f2p"]["daily"]
	var ev: Dictionary = s["weekly"]["event"]
	_section("THIS WEEK · " + str(ev["title"]).to_upper())
	_label(content, "%s  Affection from %s counts x%d this week." % [str(ev["text"]),
			str(F2P.char_row(str(ev["char"])).get("name", ev["char"])), int(ev["mult"])], Palette.ACCENT_SOFT, 14)
	_section("LOGIN CALENDAR · streak %d (best %d)" % [int(d["streak"]), int(d["streak_best"])])
	var cal: Dictionary = d["calendar"]
	var row := _row()
	for i in range(int(cal["length"])):
		var got: bool = i < int(cal["index"]) or (i == int(cal["index"]) and bool(cal["claimed_today"]))
		var today: bool = i == int(cal["index"])
		var l := _label(row, "Day %d\n%s" % [i + 1, _reward_text(cal["rewards"][i])],
				Palette.MUTED if got else (Palette.GOLD if today else Palette.TEXT), 12)
		l.custom_minimum_size = Vector2(128, 0)
	var cr := _row()
	cr.add_child(_small("CLAIM TODAY", "Primary", func() -> void: _claim("/daily/claim", {}), bool(cal["claimed_today"])))
	var ps: Dictionary = s["pass"]
	if bool(ps["active"]):
		cr.add_child(_small("NIGHT SHIFT PASS · CLAIM", "Amber", func() -> void: _claim("/pass/claim", {}), bool(ps["claimed_today"])))
	_section("DAILY MISSIONS")
	for m in d["missions"]:
		var h := _row()
		_label(h, "%s   %d/%d   · %s" % [m["text"], int(m["progress"]), int(m["goal"]), _reward_text(m["reward"])],
				Palette.MUTED if bool(m["claimed"]) else Palette.TEXT, 13, true)
		var slot := int(m["slot"])
		h.add_child(_small("CLAIMED" if bool(m["claimed"]) else "CLAIM", "Primary",
				func() -> void: _claim("/mission/claim", {"slot": slot}), bool(m["claimed"]) or not bool(m["done"])))
	var bh := _row()
	_label(bh, "All three · %s" % _reward_text(d["all_missions_bonus"]), Palette.GOLD, 13, true)
	var all_done := true
	for m in d["missions"]:
		all_done = all_done and bool(m["claimed"])
	bh.add_child(_small("BONUS", "Amber", func() -> void: _claim("/mission/claim", {"bonus": true}),
			bool(d["all_missions_bonus_claimed"]) or not all_done))
	var w: Dictionary = s["weekly"]
	_section("WEEKLY GOALS")
	for g in w["goals"]:
		var h := _row()
		_label(h, "%s   %d/%d   · %s" % [g["text"], int(g["progress"]), int(g["goal"]), _reward_text(g["reward"])],
				Palette.MUTED if bool(g["claimed"]) else Palette.TEXT, 13, true)
		var gid := str(g["id"])
		h.add_child(_small("CLAIMED" if bool(g["claimed"]) else "CLAIM", "Primary",
				func() -> void: _claim("/weekly/claim", {"goal": gid}), bool(g["claimed"]) or not bool(g["done"])))
	var wall := true
	for g in w["goals"]:
		wall = wall and bool(g["claimed"])
	var wb := _row()
	_label(wb, "All six · %s" % _reward_text(w["all_bonus"]), Palette.GOLD, 13, true)
	wb.add_child(_small("BONUS", "Amber", func() -> void: _claim("/weekly/claim", {"bonus": true}),
			bool(w["all_bonus_claimed"]) or not wall))
	_section("THE DAILY FLOOR · same twelve pieces for everyone today")
	var df: Dictionary = s["daily_floor"]
	var dh := _row()
	_label(dh, "Best today %d  ·  attempts %d/%d" % [int(df["best"]), int(df["attempts"]), int(df["attempts_max"])], Palette.TEXT, 13, true)
	dh.add_child(_small("PLAY", "Primary", func() -> void:
		close()
		daily_floor_requested.emit(), int(df["attempts"]) >= int(df["attempts_max"])))


func _claim(path: String, body: Dictionary) -> void:
	var r := await F2P.act(path, body)
	if r["ok"]:
		Sfx.win()
		juice.emit("claim", r["body"].get("applied", {}))


func _reward_text(r) -> String:
	if typeof(r) != TYPE_DICTIONARY:
		return ""
	var parts: Array = []
	for k in (r.get("tokens", {}) as Dictionary).keys():
		var n := int(r["tokens"][k])
		match str(k):
			"ticket": parts.append("%d ticket%s" % [n, "" if n == 1 else "s"])
			"timeskip": parts.append("%dh skip" % n)
			"gift_box": parts.append("%d gift box%s" % [n, "" if n == 1 else "es"])
			"shield": parts.append("%d shield%s" % [n, "" if n == 1 else "s"])
			_: parts.append("%d %s" % [n, k])
	if r.has("coins_h"):
		parts.append("%dh of rent" % int(r["coins_h"]))
	return ", ".join(parts)


# ---------------------------------------------------------------------- UPGRADES

func _upgrades(s: Dictionary) -> void:
	var b: Dictionary = s["building"]
	_section("BUILDING %d OF %d · %s · pays ×%s" % [int(b["no"]), int(b["of"]), b["name"], str(b["mult"])])
	var h := _row()
	var need = b.get("prestige_need")
	if need != null:
		_label(h, "Earned here %s / %s  ·  floors %d / %d" % [_money(b["earned"]), _money(need), s["floors"].size(), int(b["floors_max"])], Palette.TEXT, 13, true)
		h.add_child(_small("SELL & MOVE UP", "Primary", func() -> void: _act_juice("/prestige", {}, "prestige"), not bool(b["can_prestige"])))
	else:
		_label(h, "The last building. Fill all nine floors.", Palette.TEXT, 13, true)
	if b.get("next_floor_cost") != null:
		var fh := _row()
		_label(fh, "Floor %d" % (s["floors"].size() + 1), Palette.TEXT, 13, true)
		fh.add_child(_small("BUILD · %s" % _money(b["next_floor_cost"]), "Amber", func() -> void: _act_juice("/build_floor", {}, "floor"),
				int(s["bank"]) < int(b["next_floor_cost"])))
	_section("FIT-OUTS · +30% per level on that floor")
	for f in s["floors"]:
		var fr := _row()
		var n := int(f["n"])
		_label(fr, "Floor %d · level %d · %s a shift" % [n, int(f["fit"]), _money(f["pay"])], Palette.TEXT, 13, true)
		var fc = f.get("fit_cost")
		fr.add_child(_small("MAX" if fc == null else "FIT OUT · %s" % _money(fc), "",
				func() -> void: _act_juice("/fitout", {"floor": n}, "fit"), fc == null or int(s["bank"]) < int(fc)))
	_section("OBJECTS · go into your tray")
	var orow := _row()
	for o in ["coffee", "mute", "printer", "corner"]:
		var oid: String = o
		var price := int(s["object_prices"][o])
		orow.add_child(_small("%s · %s (%d)" % [OBJ_NAME[o], _money(price), int(s["inventory"].get(o, 0))], "",
				func() -> void: _act_juice("/buy_object", {"id": oid}, "object"), int(s["bank"]) < price))
	var rp = s.get("relic_price")
	_section("RELICS · building-wide rules" + ("" if rp == null else " · next %s" % _money(rp)))
	var rrow := _row()
	for rid in RELIC_NAME.keys():
		var owned: bool = (s["relics"] as Array).has(rid)
		var rk: String = rid
		rrow.add_child(_small(RELIC_NAME[rid] + (" · OWNED" if owned else ""), "", func() -> void: _act_juice("/buy_relic", {"id": rk}, "relic"),
				owned or rp == null or int(s["bank"]) < int(rp)))
	_section("TIME SKIPS · %d held · each is one hour of shifts now" % int(s["timeskips"]))
	var trow := _row()
	for n in [1, 4, 12]:
		var hrs: int = n
		trow.add_child(_small("SKIP %dh" % n, "Amber", func() -> void: _act_juice("/timeskip", {"hours": hrs}, "skip"), int(s["timeskips"]) < n))


func _act_juice(path: String, body: Dictionary, kind: String) -> void:
	var r := await F2P.act(path, body)
	if r["ok"]:
		juice.emit(kind, r["body"])


# -------------------------------------------------------------------------- SHOP

func _shop(s: Dictionary) -> void:
	_section("PAID WITH NUTAKU GOLD · the platform asks you to confirm every purchase")
	para_into("Everything here only makes things sooner. Every character, line and scene can be reached without paying.")
	for id in SHOP_ORDER:
		var sk := Nutaku.sku(id)
		if sk.is_empty():
			continue
		var h := _row()
		_label(h, "%s — %s" % [sk.get("name", id), sk.get("description", "")], Palette.TEXT, 13, true)
		var sid: String = id
		h.add_child(_small("%d GOLD" % int(sk.get("price", 0)), "Primary", func() -> void: _buy(sid)))
	_section("STAFF BOARD ODDS · common 70% · rare 25% · epic 5% · the 30th pull without an epic is always one · pity "
			+ str(int(s["pity"]["since_epic"])) + "/30")


func para_into(txt: String) -> void:
	_label(content, txt, Palette.MUTED, 13)


func _buy(id: String) -> void:
	var r := await F2P.buy(id)
	var st := str(r.get("status", ""))
	if st == "success":
		Sfx.win()
		juice.emit("bought", {"sku": id})
	elif st != "cancel":
		F2P.refused.emit("purchase not completed (%s); any gold taken is returned by Nutaku" % st)


# ------------------------------------------------------------------------ SCENES

func _scenes(s: Dictionary) -> void:
	_section("SCENES · affection tiers 3 and 5, and each new building")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for sid in (s["scenes"] as Dictionary).keys():
		var sc: Dictionary = s["scenes"][sid]
		var id: String = sid
		var ttl := str(sc["title"])
		var b := _small(("VIEW · " + ttl) if bool(sc["unlocked"]) else "LOCKED · " + ttl, "Amber" if bool(sc["unlocked"]) else "Ghost",
				func() -> void: view_scene.emit(id, ttl), not bool(sc["unlocked"]))
		b.custom_minimum_size = Vector2(320, 40)
		grid.add_child(b)


# ------------------------------------------------------------------------- BOARD

func _load_board() -> void:
	var a := await Nutaku.api("GET", "/ot/leaderboard?board=earned")
	var b := await Nutaku.api("GET", "/ot/leaderboard?board=daily")
	_board = {"earned": a["body"], "daily": b["body"]}
	if is_open() and tab == "board":
		render()


func _board_tab() -> void:
	if _board.is_empty():
		para_into("Loading…")
		return
	for key in ["earned", "daily"]:
		var bd: Dictionary = _board[key]
		_section("LIFETIME RENT" if key == "earned" else "TODAY'S DAILY FLOOR")
		for row in bd.get("top", []):
			_label(content, "%2d.  %s   %s" % [int(row["rank"]), row["nickname"], _money(row["score"])],
					Palette.GOLD if bool(row["you"]) else Palette.TEXT, 13)
		var me = bd.get("you")
		if me != null and int(me["rank"]) > (bd.get("top", []) as Array).size():
			_label(content, "…  %d.  you   %s" % [int(me["rank"]), _money(me["score"])], Palette.GOLD, 13)


# ===================================================================== SceneView

## A server scene, full-bleed. The bytes come from /f2p/scene/<id>, which answers only a
## session whose user has unlocked it; nothing uncensored ships in the Nutaku pack.
class SceneView extends Overlay:
	var img: TextureRect
	var cap: Label

	func build() -> void:
		card_width = 1000
		card.custom_minimum_size = Vector2(1000, 0)
		img = TextureRect.new()
		img.custom_minimum_size = Vector2(960, 600)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.add_child(img)
		var row := HBoxContainer.new()
		body.add_child(row)
		cap = Label.new()
		cap.theme_type_variation = "Value"
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cap)
		row.add_child(button("CLOSE", "Ghost", close))

	func show_scene(id: String, title_txt: String) -> void:
		cap.text = title_txt + " · loading…"
		img.texture = null
		open()
		var data: PackedByteArray = await Nutaku.bytes("/f2p/scene/" + id)
		var im := Image.new()
		if data.size() > 0 and im.load_webp_from_buffer(data) == OK:
			img.texture = ImageTexture.create_from_image(im)
			cap.text = title_txt
		else:
			cap.text = title_txt + " · could not load"


# ======================================================================== Juice

## Level-up bursts, rarity flashes, floating "+rent" numbers: drawn on their own layer
## over everything, freed when done.
class Juice extends Control:
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func flash(color: Color, peak: float = 0.55, dur: float = 0.5) -> void:
		var r := ColorRect.new()
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.color = Color(color, 0.0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		var tw := r.create_tween()
		tw.tween_property(r, "color:a", peak, dur * 0.25)
		tw.tween_property(r, "color:a", 0.0, dur * 0.75)
		tw.tween_callback(r.queue_free)

	func burst(at: Vector2, color: Color, n: int = 26) -> void:
		for i in range(n):
			var p := ColorRect.new()
			p.size = Vector2(7, 7)
			p.position = at
			p.color = color.lightened(randf() * 0.4)
			p.rotation = randf() * TAU
			p.pivot_offset = Vector2(3.5, 3.5)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(p)
			var ang := randf() * TAU
			var dist := 90.0 + randf() * 170.0
			var tw := p.create_tween()
			tw.set_parallel(true)
			tw.tween_property(p, "position", at + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, 60), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(p, "rotation", p.rotation + randf_range(-6, 6), 0.9)
			tw.tween_property(p, "modulate:a", 0.0, 0.9).set_delay(0.3)
			tw.chain().tween_callback(p.queue_free)

	func float_text(at: Vector2, txt: String, color: Color, size: int = 30) -> void:
		var l := Label.new()
		l.text = txt
		l.position = at - Vector2(120, 20)
		l.custom_minimum_size = Vector2(240, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", Look.font_display)
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("outline_size", 6)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.pivot_offset = Vector2(120, 20)
		l.scale = Vector2(0.4, 0.4)
		add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "scale", Vector2(1, 1), 0.1)
		tw.tween_property(l, "position:y", l.position.y - 70, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.4)
		tw.tween_callback(l.queue_free)

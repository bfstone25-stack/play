class_name F2PPanel
extends Overlay
## The Nutaku free-to-play office: six tabs over the server's state (F2P.st()).
##
##   STORY     the campaign: the chapter, its rival, its goals (checked by the server), the
##             rival's bid (a 48 h window on the server clock), complete -> the next chapter;
##             the chapter's beats so far, and which update pack brings the next chapters
##   STAFF     affection ladder per character (talk once a day, today's board request,
##             gifts, gift boxes), the
##             tier rewards (a line, then a scene), rank-ups (character evolution)
##   DAILY     login calendar + streak, three daily missions + bonus, five weekly goals,
##             the Night Shift Pass, staff stories, the tenant crisis, the daily floor and
##             the night floor
##   (STAFF also carries an update pack's limited banner and event while they run, and
##   UPGRADES each floor's three build goals)
##   UPGRADES  fit-outs per floor, relics, objects, time skips, selling the building
##   SHOP      Nutaku gold SKUs (the platform's own confirm dialog does the charging)
##   SCENES    every scene the server has unlocked for this player, fetched from it
##   BOARD     the leaderboards (lifetime rent, today's daily floor)
##
## Nothing here decides a number. Every button is an F2P.act() or F2P.buy(), and the panel
## redraws from whatever state the server answers with.

signal daily_floor_requested
signal hard_floor_requested
signal story_requested(id: String, who: String)
signal view_scene(id: String, title: String)
signal juice(kind: String, data: Dictionary)

const TABS := ["story", "staff", "daily", "upgrades", "shop", "scenes", "board"]
## Every word below is an I18n key (f2p_* in scripts/i18n.gd, in en, zh and ja), and so is
## everything the server sends that a player reads (F2P.tx and friends look it up by id).
## ops/nutaku/overtime_f2p/check_i18n.py fails if a literal here reaches the screen.
const OBJ_KEY := {"coffee": "n_coffee", "mute": "n_mute", "printer": "n_printer", "corner": "n_corner"}
const RELICS := ["severance", "quiet", "pto", "glass", "badge", "army"]
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
	tag(I18n.t("f2p_tag"))
	var head := HBoxContainer.new()
	body.add_child(head)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tab_row)
	var cb := StudioTheme.stub(I18n.t("close"), "Ghost", true)
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
		var b := StudioTheme.stub(I18n.t("f2p_tab_" + key), "Active" if t == tab else "", true)
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
		status_l.text = I18n.t("f2p_connecting")
		return
	status_l.text = I18n.fmt("f2p_status", {"bank": _money(s["bank"]), "rate": _money(s["income_h"]),
		"tickets": int(s["tickets"]), "skips": int(s["timeskips"]), "boxes": int(s["gift_boxes"])}) \
		+ (I18n.t("f2p_double_pay") if bool(s["boost"]["active"]) else "")
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
		_section(I18n.t("f2p_story_done"))
		para_into(I18n.t("f2p_story_after"))
		_news(s)
		_next_pack(s, cp)
		return
	var ch: Dictionary = cp["chapter"]
	var cid := str(ch["id"])
	_section(I18n.fmt("f2p_chapter_hdr", {"i": int(cp["index"]) + 1, "of": int(cp["of"]), "b": int(ch["building"]),
			"title": F2P.chapter_text(cid, "title", ch["title"]).to_upper()}))
	if ch.get("rival") != null:
		_label(content, I18n.fmt("f2p_rival", {"name": F2P.rival_name(ch)}), Palette.HEAT, 14)
	_label(content, F2P.chapter_text(cid, "intro", ch["intro"]), Palette.TEXT, 15)
	var beats: Array = cp.get("beats", [])
	if not beats.is_empty():
		_section(I18n.t("f2p_beats_hdr"))
		for bt in beats:
			var bh := _row()
			_label(bh, I18n.fmt("f2p_beat_line", {"title": F2P.beat_title(bt), "text": F2P.beat_text(bt)}), Palette.ACCENT_SOFT, 13, true)
			if bt.get("scene") != null:
				var bsid := str(bt["scene"])
				var bttl := F2P.scene_title(bsid, bt.get("title", ""))
				bh.add_child(_small(I18n.t("f2p_view"), "Amber", func() -> void: view_scene.emit(bsid, bttl)))
	_news(s)
	_section(I18n.t("f2p_goals"))
	var gi := 0
	for g in cp["goals"]:
		var h := _row()
		var have = g["have"]
		var prog := ""
		if typeof(have) == TYPE_DICTIONARY:
			prog = I18n.fmt("f2p_prog_inspect", {"taxed": int(have["taxed"]), "thin": int(have["thin"])})
		elif str(g["kind"]) != "no_tax":
			prog = "%s / %s" % [_money(have), _money(g["need"])]
		_label(h, (I18n.t("f2p_done_mark") if bool(g["done"]) else "• ") + F2P.goal_text(cid, gi, g) + ("   " + prog if prog != "" else ""),
				Palette.SUCCESS if bool(g["done"]) else Palette.TEXT, 14, true)
		gi += 1
	var bs = ch.get("boss")
	if bs != null:
		var bst = cp.get("boss")
		_section(I18n.fmt("f2p_bid_hdr", {"title": F2P.chapter_text(cid, "boss_title", bs["title"]).to_upper()}))
		_label(content, F2P.boss_text(cid, bs), Palette.ACCENT_SOFT, 14)
		var h2 := _row()
		if bst == null:
			_label(h2, I18n.fmt("f2p_bid_target", {"target": _money(bs["target"]), "hours": int(bs["hours"])}), Palette.TEXT, 13, true)
			h2.add_child(_small(I18n.t("f2p_bid_accept"), "Primary", func() -> void: _act_juice("/chapter/boss", {}, "boss"),
					int(ch["building"]) != int(s["building"]["no"])))
		else:
			var left := maxi(0, int(bst["deadline_ms"]) - int(s["server_ms"])) / 60000
			var status := str(bst["status"])
			var st_word := I18n.t("f2p_bid_" + status) if I18n.has("f2p_bid_" + status) else status.to_upper()
			_label(h2, "%s  ·  %s / %s%s" % [st_word, _money(bst["earned"]), _money(bst["target"]),
					I18n.fmt("f2p_bid_left", {"h": left / 60, "m": "%02d" % (left % 60)}) if status == "active" else ""],
					Palette.SUCCESS if status == "won" else (Palette.HEAT if status == "failed" else Palette.GOLD), 14, true)
			if status == "failed":
				h2.add_child(_small(I18n.t("f2p_bid_retry"), "Primary", func() -> void: _act_juice("/chapter/boss", {}, "boss")))
	var fin := _row()
	_label(fin, I18n.fmt("f2p_reward", {"r": _reward_text(ch["reward"])}), Palette.GOLD, 13, true)
	fin.add_child(_small(I18n.t("f2p_complete_ch"), "Amber", func() -> void: _act_juice("/chapter/complete", {}, "chapter"),
			not bool(cp["complete"])))
	if bool(cp.get("blocks_sale", false)):
		para_into(I18n.t("f2p_blocks_sale"))
	_next_pack(s, cp)


## The live packs' dispatches: dated news from their cities, newest first.
func _news(s: Dictionary) -> void:
	var news: Array = s.get("news", [])
	if news.is_empty():
		return
	_section(I18n.t("f2p_news_hdr"))
	for nw in news:
		_label(content, I18n.fmt("f2p_beat_line", {"title": F2P.beat_title(nw), "text": F2P.beat_text(nw)}), Palette.TEXT, 13)


## Which update pack brings the next chapters, and when (the server's release date).
func _next_pack(s: Dictionary, cp: Dictionary) -> void:
	var np = cp.get("next_pack")
	if np == null:
		if bool(cp["done"]):
			para_into(I18n.t("f2p_all_packs"))
		return
	var at = np.get("at")
	if at == null:
		para_into(I18n.fmt("f2p_next_pack_soon", {"title": F2P.pack_title(np)}))
		return
	var secs := maxi(0, int(float(at) - float(s["server_ms"]) / 1000.0))
	para_into(I18n.fmt("f2p_next_pack", {"title": F2P.pack_title(np), "d": secs / 86400}))


func _left(until: float, s: Dictionary) -> String:
	var secs := maxi(0, int(until - float(s["server_ms"]) / 1000.0))
	return I18n.fmt("f2p_left_dh", {"d": secs / 86400, "h": (secs % 86400) / 3600})


# ------------------------------------------------------------------------- STAFF

func _staff(s: Dictionary) -> void:
	_pack_rows(s)
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
		var pp := "res://assets/f2p_portraits/%s.webp" % id
		if ResourceLoader.exists(pp):
			var tr := TextureRect.new()
			tr.texture = load(pp)
			tr.custom_minimum_size = Vector2(56, 72)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			top.add_child(tr)
		var who := I18n.fmt("f2p_who_age", {"name": F2P.char_name(id), "age": int(ch["age"])})
		if I18n.has("n_" + id):
			who = I18n.t("n_" + id)            # "Dan, 41" / "丹，41" / "ダン、41"
		if ch.has("rank"):
			who += I18n.fmt("f2p_rank_1" if int(ch["slots"]) == 1 else "f2p_rank_n", {"rank": int(ch["rank"]), "slots": int(ch["slots"])})
		_label(top, who, Palette.GOLD_PALE if owned else Palette.MUTED, 16, true)
		_label(top, I18n.fmt("f2p_tier_of", {"t": int(ch["tier"])}), Palette.HEAT, 15)
		var nxt = ch.get("next_at")
		_label(top, ("%d / %d" % [int(ch["aff"]), int(nxt)]) if nxt != null else I18n.t("f2p_all_tiers"), Palette.TEXT, 13)
		if not owned:
			_label(v, I18n.t("f2p_not_owned"), Palette.MUTED, 13)
			continue
		var acts := HBoxContainer.new()
		acts.add_theme_constant_override("separation", 6)
		v.add_child(acts)
		acts.add_child(_small(I18n.t("f2p_talk"), "Primary", func() -> void: _talk(id), bool(ch["talked_today"])))
		acts.add_child(_small(I18n.fmt("f2p_gift", {"n": int(ch["gifts_today"])}), "", func() -> void: _gift(id, false), int(ch["gifts_today"]) >= 3))
		acts.add_child(_small(I18n.fmt("f2p_gift_box", {"n": int(s["gift_boxes"])}), "Amber", func() -> void: _gift(id, true), int(s["gift_boxes"]) < 1))
		if ch.has("rank"):
			var rc = ch.get("rank_cost")
			var need := int(ch.get("rank_needs_tier", 0))
			var ok: bool = rc != null and int(ch["tier"]) >= need and int(s["bank"]) >= int(rc)
			var lbl := I18n.t("f2p_max_rank") if rc == null else (I18n.fmt("f2p_rank_up", {"cost": _money(rc)}) if int(ch["tier"]) >= need
					else I18n.fmt("f2p_rank_needs", {"t": need}))
			acts.add_child(_small(lbl, "Pull", func() -> void: _rank(id), not ok))
		for rq in s.get("requests", []):
			if str(rq["char"]) != id:
				continue
			var rh := HBoxContainer.new()
			v.add_child(rh)
			var mark := I18n.t("f2p_done_mark") if bool(rq["claimed"]) else (I18n.t("f2p_ready_mark") if bool(rq["done"]) else "• ")
			_label(rh, mark + I18n.fmt("f2p_request", {"text": F2P.request_text(id, rq)}), Palette.SUCCESS if bool(rq["done"]) else Palette.ACCENT_SOFT, 13, true)
			rh.add_child(_small(I18n.t("f2p_done") if bool(rq["claimed"]) else I18n.t("f2p_claim_20"), "Primary",
					func() -> void: _act_juice("/request/claim", {"char": id}, "talk"), bool(rq["claimed"]) or not bool(rq["done"])))
		for t in ch["tiers"]:
			if not bool(t["reached"]):
				continue
			if str(t["kind"]) == "line":
				_label(v, I18n.fmt("f2p_tier_line", {"t": int(t["tier"]), "text": F2P.tier_line(id, int(t["tier"]), t["text"])}), Palette.TEXT, 13)
			else:
				var sid := str(t["scene"])
				var ttl := F2P.scene_title(sid, t["title"])
				var h := HBoxContainer.new()
				v.add_child(h)
				_label(h, I18n.fmt("f2p_tier_scene", {"t": int(t["tier"]), "title": ttl}), Palette.GOLD, 13, true)
				h.add_child(_small(I18n.t("f2p_view"), "Amber", func() -> void: view_scene.emit(sid, ttl)))


## An update pack's limited banner and its week-long event, while they run.
func _pack_rows(s: Dictionary) -> void:
	var bn = s.get("banner")
	if bn != null:
		var name := F2P.char_name(str(bn["char"]))
		_section(I18n.fmt("f2p_bn_hdr", {"title": F2P.banner_title(bn).to_upper(), "name": name}))
		var odds := {"name": name, "pct": int(bn["pct"]), "pity": int(bn["pity"]), "since": int(bn["since"]), "n": int(bn["aff"])}
		var ends = bn.get("ends")
		var line := I18n.fmt("f2p_bn_odds", odds)
		if ends != null:
			line += I18n.fmt("f2p_bn_ends", {"left": _left(float(ends), s)})
		var br := _row()
		_label(br, line, Palette.ACCENT_SOFT, 13, true)
		br.add_child(_small(I18n.t("f2p_bn_pull1"), "Pull", func() -> void: _banner(1), int(s["tickets"]) < 1))
		br.add_child(_small(I18n.t("f2p_bn_pull10"), "Pull", func() -> void: _banner(10), int(s["tickets"]) < 10))
	var pe = s.get("pack_event")
	if pe != null:
		var pname := F2P.char_name(str(pe["char"]))
		_section(I18n.fmt("f2p_pe_hdr", {"title": F2P.tx("f2p_ev_%s_title" % pe["id"], pe["title"]).to_upper()}))
		_label(content, I18n.fmt("f2p_pe_line", {"text": F2P.tx("f2p_ev_%s_text" % pe["id"], pe["text"]), "name": pname,
				"mult": int(pe["mult"])}), Palette.ACCENT_SOFT, 13)
		var er := _row()
		_label(er, I18n.fmt("f2p_pe_goal", {"n": int(pe["goal"]), "name": pname, "p": mini(int(pe["progress"]), int(pe["goal"])),
				"r": _reward_text(pe["reward"])}), Palette.TEXT, 13, true)
		er.add_child(_small(I18n.t("f2p_claimed") if bool(pe["claimed"]) else I18n.t("f2p_claim"), "Primary",
				func() -> void: _claim("/event/claim", {}), bool(pe["claimed"]) or int(pe["progress"]) < int(pe["goal"])))


func _banner(n: int) -> void:
	var r := await F2P.act("/banner/pull", {"n": n})
	if not r["ok"]:
		return
	var got := 0
	for x in r["body"].get("results", []):
		if bool(x.get("featured", false)):
			got += 1
	Sfx.combo()
	var bn = F2P.st().get("banner")
	var bchar := str(bn["char"]) if bn != null else ""
	var per := int(bn["aff"]) if bn != null else 0
	juice.emit("banner", {"featured": got, "char": bchar, "n": n, "aff": got * per})


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
	_section(I18n.fmt("f2p_week_hdr", {"title": F2P.tx("f2p_ev_%s_title" % ev["id"], ev["title"]).to_upper()}))
	_label(content, I18n.fmt("f2p_week_mult", {"text": F2P.tx("f2p_ev_%s_text" % ev["id"], ev["text"]),
			"name": F2P.char_name(str(ev["char"])), "mult": int(ev["mult"])}), Palette.ACCENT_SOFT, 14)
	_section(I18n.fmt("f2p_cal_hdr", {"s": int(d["streak"]), "b": int(d["streak_best"])}))
	var cal: Dictionary = d["calendar"]
	var row := _row()
	for i in range(int(cal["length"])):
		var got: bool = i < int(cal["index"]) or (i == int(cal["index"]) and bool(cal["claimed_today"]))
		var today: bool = i == int(cal["index"])
		var l := _label(row, I18n.fmt("f2p_day", {"n": i + 1}) + "\n" + _reward_text(cal["rewards"][i]),
				Palette.MUTED if got else (Palette.GOLD if today else Palette.TEXT), 12, true)
		# seven equal cells that wrap: a two-reward day in ja ("ギフトボックス×1、チケット×2")
		# on one line widened the whole office card to 1109 px (2026-09-25)
		l.custom_minimum_size = Vector2(100, 0)
	var cr := _row()
	cr.add_child(_small(I18n.t("f2p_claim_today"), "Primary", func() -> void: _claim("/daily/claim", {}), bool(cal["claimed_today"])))
	var ps: Dictionary = s["pass"]
	if bool(ps["active"]):
		cr.add_child(_small(I18n.t("f2p_pass_claim"), "Amber", func() -> void: _claim("/pass/claim", {}), bool(ps["claimed_today"])))
	_section(I18n.t("f2p_missions"))
	for m in d["missions"]:
		var h := _row()
		_label(h, "%s   %d/%d   · %s" % [F2P.mission_text(m), int(m["progress"]), int(m["goal"]), _reward_text(m["reward"])],
				Palette.MUTED if bool(m["claimed"]) else Palette.TEXT, 13, true)
		var slot := int(m["slot"])
		h.add_child(_small(I18n.t("f2p_claimed") if bool(m["claimed"]) else I18n.t("f2p_claim"), "Primary",
				func() -> void: _claim("/mission/claim", {"slot": slot}), bool(m["claimed"]) or not bool(m["done"])))
	var bh := _row()
	_label(bh, I18n.fmt("f2p_all_three", {"r": _reward_text(d["all_missions_bonus"])}), Palette.GOLD, 13, true)
	var all_done := true
	for m in d["missions"]:
		all_done = all_done and bool(m["claimed"])
	bh.add_child(_small(I18n.t("f2p_bonus"), "Amber", func() -> void: _claim("/mission/claim", {"bonus": true}),
			bool(d["all_missions_bonus_claimed"]) or not all_done))
	var w: Dictionary = s["weekly"]
	_section(I18n.t("f2p_weekly"))
	for g in w["goals"]:
		var h := _row()
		_label(h, "%s   %d/%d   · %s" % [F2P.weekly_text(g, ev), int(g["progress"]), int(g["goal"]), _reward_text(g["reward"])],
				Palette.MUTED if bool(g["claimed"]) else Palette.TEXT, 13, true)
		var gid := str(g["id"])
		h.add_child(_small(I18n.t("f2p_claimed") if bool(g["claimed"]) else I18n.t("f2p_claim"), "Primary",
				func() -> void: _claim("/weekly/claim", {"goal": gid}), bool(g["claimed"]) or not bool(g["done"])))
	var wall := true
	for g in w["goals"]:
		wall = wall and bool(g["claimed"])
	var wb := _row()
	_label(wb, I18n.fmt("f2p_all_six", {"r": _reward_text(w["all_bonus"])}), Palette.GOLD, 13, true)
	wb.add_child(_small(I18n.t("f2p_bonus"), "Amber", func() -> void: _claim("/weekly/claim", {"bonus": true}),
			bool(w["all_bonus_claimed"]) or not wall))
	_stories(s)
	_crisis(s)
	_section(I18n.t("f2p_df_hdr"))
	var df: Dictionary = s["daily_floor"]
	var dh := _row()
	_label(dh, I18n.fmt("f2p_df_best", {"best": int(df["best"]), "a": int(df["attempts"]), "max": int(df["attempts_max"])}), Palette.TEXT, 13, true)
	dh.add_child(_small(I18n.t("f2p_play"), "Primary", func() -> void:
		close()
		daily_floor_requested.emit(), int(df["attempts"]) >= int(df["attempts_max"])))
	var hf = s.get("hard_floor")
	if hf != null:
		_section(I18n.t("f2p_hf_hdr"))
		var hh := _row()
		if not bool(hf["open"]):
			_label(hh, I18n.t("f2p_hf_closed"), Palette.MUTED, 13, true)
		else:
			var hl := I18n.fmt("f2p_hf_line", {"par": int(hf["par"]), "best": int(hf["best"]), "a": int(hf["attempts"]),
					"max": int(hf["attempts_max"]), "r": _reward_text(hf["par_reward"])})
			if bool(hf["par_beaten"]):
				hl += I18n.t("f2p_hf_par_done")
			_label(hh, hl, Palette.TEXT, 13, true)
			hh.add_child(_small(I18n.t("f2p_play"), "Primary", func() -> void:
				close()
				hard_floor_requested.emit(), int(hf["attempts"]) >= int(hf["attempts_max"])))


## Staff stories waiting (two a day on the server clock), each read once.
func _stories(s: Dictionary) -> void:
	var ss = s.get("stories")
	if ss == null:
		return
	_section(I18n.fmt("f2p_st_hdr", {"read": int(ss["read"]), "of": int(ss["of"])}))
	var pend: Array = ss.get("pending", [])
	if pend.is_empty():
		para_into(I18n.fmt("f2p_st_none", {"left": _left(float(ss["next_slot_at"]), s)}))
		return
	for st in pend:
		var sid := str(st["id"])
		var h := _row()
		_label(h, I18n.fmt("f2p_st_row", {"name": F2P.char_name(str(st["char"])), "title": F2P.story_title(sid, st["title"]),
				"n": int(ss["points"])}), Palette.TEXT, 13, true)
		h.add_child(_small(I18n.t("f2p_st_read"), "Primary", func() -> void: _read(sid, str(st["char"]))))


func _read(sid: String, who: String) -> void:
	var r := await F2P.act("/story/read", {"id": sid})
	if r["ok"]:
		story_requested.emit(sid, who)
		juice.emit("talk", {"char": who, "points": int(r["body"].get("points", 0))})


## Today's tenant crisis on one floor, checked on the board.
func _crisis(s: Dictionary) -> void:
	var cr = s.get("crisis")
	_section(I18n.t("f2p_cr_hdr") if cr == null else I18n.fmt("f2p_cr_hdr_n", {"floor": int(cr["floor"])}))
	if cr == null:
		para_into(I18n.t("f2p_cr_none"))
		return
	_label(content, F2P.crisis_text(cr), Palette.ACCENT_SOFT, 13)
	var h := _row()
	var st := I18n.t("f2p_cr_done") if bool(cr["claimed"]) else I18n.fmt("f2p_cr_now", {"now": RollingLabel._fmt(float(cr["now"])),
			"r": _reward_text(cr["reward"]), "n": int(cr["aff"])})
	_label(h, st, Palette.SUCCESS if bool(cr["done"]) else Palette.TEXT, 13, true)
	h.add_child(_small(I18n.t("f2p_claimed") if bool(cr["claimed"]) else I18n.t("f2p_claim"), "Primary",
			func() -> void: _claim("/crisis/claim", {}), bool(cr["claimed"]) or not bool(cr["done"])))


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
			"ticket": parts.append(I18n.fmt("f2p_rw_ticket" if n == 1 else "f2p_rw_tickets", {"n": n}))
			"timeskip": parts.append(I18n.fmt("f2p_rw_timeskip", {"n": n}))
			"gift_box": parts.append(I18n.fmt("f2p_rw_gift_box" if n == 1 else "f2p_rw_gift_boxes", {"n": n}))
			"shield": parts.append(I18n.fmt("f2p_rw_shield" if n == 1 else "f2p_rw_shields", {"n": n}))
			_: parts.append("%d %s" % [n, k])
	if r.has("coins_h"):
		parts.append(I18n.fmt("f2p_rw_rent", {"n": int(r["coins_h"])}))
	return I18n.t("f2p_list_sep").join(parts)


# ---------------------------------------------------------------------- UPGRADES

func _upgrades(s: Dictionary) -> void:
	var b: Dictionary = s["building"]
	_section(I18n.fmt("f2p_bld_hdr", {"no": int(b["no"]), "of": int(b["of"]), "name": F2P.building_name(int(b["no"])), "mult": str(b["mult"])}))
	var h := _row()
	var need = b.get("prestige_need")
	if need != null:
		_label(h, I18n.fmt("f2p_earned_here", {"e": _money(b["earned"]), "need": _money(need), "f": s["floors"].size(), "max": int(b["floors_max"])}), Palette.TEXT, 13, true)
		h.add_child(_small(I18n.t("f2p_sell"), "Primary", func() -> void: _act_juice("/prestige", {}, "prestige"), not bool(b["can_prestige"])))
	else:
		_label(h, I18n.fmt("f2p_last_bld", {"n": int(b["floors_max"])}), Palette.TEXT, 13, true)
	if b.get("next_floor_cost") != null:
		var fh := _row()
		_label(fh, I18n.fmt("f2p_floor_n", {"n": s["floors"].size() + 1}), Palette.TEXT, 13, true)
		fh.add_child(_small(I18n.fmt("f2p_build", {"cost": _money(b["next_floor_cost"])}), "Amber", func() -> void: _act_juice("/build_floor", {}, "floor"),
				int(s["bank"]) < int(b["next_floor_cost"])))
	_section(I18n.t("f2p_fit_hdr"))
	for f in s["floors"]:
		var fr := _row()
		var n := int(f["n"])
		_label(fr, I18n.fmt("f2p_fit_row", {"n": n, "l": int(f["fit"]), "pay": _money(f["pay"])}), Palette.TEXT, 13, true)
		var fc = f.get("fit_cost")
		fr.add_child(_small(I18n.t("max") if fc == null else I18n.fmt("f2p_fit_out", {"cost": _money(fc)}), "",
				func() -> void: _act_juice("/fitout", {"floor": n}, "fit"), fc == null or int(s["bank"]) < int(fc)))
		var dg: Array = f.get("decor", [])
		if not dg.is_empty():
			var dr := _row()
			var words: Array = []
			for g in dg:
				words.append((I18n.t("f2p_done_mark") if bool(g["claimed"]) else ("✓ " if bool(g["done"]) else "• ")) + F2P.decor_text(g))
			_label(dr, I18n.fmt("f2p_dc_row", {"n": n, "goals": "   ".join(words)}), Palette.ACCENT_SOFT, 12, true)
			for g in dg:
				if bool(g["done"]) and not bool(g["claimed"]):
					var gk := str(g["kind"])
					dr.add_child(_small(I18n.fmt("f2p_dc_claim", {"r": _reward_text(g["reward"])}), "Primary",
							func() -> void: _claim("/decor/claim", {"floor": n, "goal": gk})))
	_section(I18n.t("f2p_obj_hdr"))
	var orow := _row()
	for o in ["coffee", "mute", "printer", "corner"]:
		var oid: String = o
		var price := int(s["object_prices"][o])
		orow.add_child(_small("%s · %s (%d)" % [I18n.t(OBJ_KEY[o]), _money(price), int(s["inventory"].get(o, 0))], "",
				func() -> void: _act_juice("/buy_object", {"id": oid}, "object"), int(s["bank"]) < price))
	var rp = s.get("relic_price")
	_section(I18n.t("f2p_relic_hdr") + ("" if rp == null else I18n.fmt("f2p_relic_next", {"p": _money(rp)})))
	var rrow := _row()
	for rid in RELICS:
		var owned: bool = (s["relics"] as Array).has(rid)
		var rk: String = rid
		rrow.add_child(_small(I18n.t("rl_" + rk) + ((" · " + I18n.t("owned")) if owned else ""), "", func() -> void: _act_juice("/buy_relic", {"id": rk}, "relic"),
				owned or rp == null or int(s["bank"]) < int(rp)))
	_section(I18n.fmt("f2p_skip_hdr", {"n": int(s["timeskips"])}))
	var trow := _row()
	for n in [1, 4, 12]:
		var hrs: int = n
		trow.add_child(_small(I18n.fmt("f2p_skip", {"n": n}), "Amber", func() -> void: _act_juice("/timeskip", {"hours": hrs}, "skip"), int(s["timeskips"]) < n))


func _act_juice(path: String, body: Dictionary, kind: String) -> void:
	var r := await F2P.act(path, body)
	if r["ok"]:
		juice.emit(kind, r["body"])


# -------------------------------------------------------------------------- SHOP

func _shop(s: Dictionary) -> void:
	_section(I18n.t("f2p_shop_hdr"))
	para_into(I18n.t("f2p_shop_para"))
	for id in SHOP_ORDER:
		var sk := Nutaku.sku(id)
		if sk.is_empty():
			continue
		var h := _row()
		_label(h, "%s — %s" % [F2P.sku_name(id), F2P.sku_desc(id)], Palette.TEXT, 13, true)
		var sid: String = id
		h.add_child(_small(I18n.fmt("f2p_gold_price", {"n": int(sk.get("price", 0))}), "Primary", func() -> void: _buy(sid)))
	_section(I18n.fmt("f2p_odds", {"p": int(s["pity"]["since_epic"])}))


func para_into(txt: String) -> void:
	_label(content, txt, Palette.MUTED, 13)


func _buy(id: String) -> void:
	var r := await F2P.buy(id)
	var st := str(r.get("status", ""))
	if st == "success":
		Sfx.win()
		juice.emit("bought", {"sku": id})
	elif st != "cancel":
		F2P.refused.emit(I18n.fmt("f2p_buy_fail", {"st": st}))


# ------------------------------------------------------------------------ SCENES

func _scenes(s: Dictionary) -> void:
	_section(I18n.t("f2p_scenes_hdr"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for sid in (s["scenes"] as Dictionary).keys():
		var sc: Dictionary = s["scenes"][sid]
		var id: String = sid
		var ttl := F2P.scene_title(id, sc["title"])
		var b := _small(I18n.fmt("f2p_view_t" if bool(sc["unlocked"]) else "f2p_locked_t", {"t": ttl}), "Amber" if bool(sc["unlocked"]) else "Ghost",
				func() -> void: view_scene.emit(id, ttl), not bool(sc["unlocked"]))
		b.custom_minimum_size = Vector2(320, 40)
		grid.add_child(b)


# ------------------------------------------------------------------------- BOARD

func _load_board() -> void:
	var a := await Nutaku.api("GET", "/ot/leaderboard?board=earned")
	var b := await Nutaku.api("GET", "/ot/leaderboard?board=daily")
	var c := await Nutaku.api("GET", "/ot/leaderboard?board=hard")
	_board = {"earned": a["body"], "daily": b["body"], "hard": c["body"]}
	if is_open() and tab == "board":
		render()


func _board_tab() -> void:
	if _board.is_empty():
		para_into(I18n.t("f2p_loading"))
		return
	for key in ["earned", "daily", "hard"]:
		if not _board.has(key):
			continue
		var bd: Dictionary = _board[key]
		_section(I18n.t("f2p_lb_" + key))
		for row in bd.get("top", []):
			_label(content, "%2d.  %s   %s" % [int(row["rank"]), _nick(str(row["nickname"])), _money(row["score"])],
					Palette.GOLD if bool(row["you"]) else Palette.TEXT, 13)
		var me = bd.get("you")
		if me != null and int(me["rank"]) > (bd.get("top", []) as Array).size():
			_label(content, "…  %d.  %s   %s" % [int(me["rank"]), I18n.t("f2p_you"), _money(me["score"])], Palette.GOLD, 13)


## The server's placeholder nickname ("landlord 3") is the building's word, not a player's.
func _nick(n: String) -> String:
	if n.begins_with("landlord ") and n.substr(9).is_valid_int():
		return I18n.fmt("f2p_landlord", {"n": n.substr(9)})
	return n


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
		row.add_child(button(I18n.t("close"), "Ghost", close))

	func show_scene(id: String, title_txt: String) -> void:
		cap.text = I18n.fmt("f2p_sc_loading", {"t": title_txt})
		img.texture = null
		open()
		var data: PackedByteArray = await Nutaku.bytes("/f2p/scene/" + id)
		var im := Image.new()
		if data.size() > 0 and im.load_webp_from_buffer(data) == OK:
			img.texture = ImageTexture.create_from_image(im)
			cap.text = title_txt
		else:
			cap.text = I18n.fmt("f2p_sc_fail", {"t": title_txt})


# ===================================================================== StoryView

## A staff side-story, read in full once the server has marked it read: three lines, the
## character, you, the character. The words come from the i18n table by the story's id.
class StoryView extends Overlay:
	var head: Label
	var lines: VBoxContainer

	func build() -> void:
		card_width = 760
		card.custom_minimum_size = Vector2(760, 0)
		head = Label.new()
		head.theme_type_variation = "Tag"
		body.add_child(head)
		lines = VBoxContainer.new()
		lines.add_theme_constant_override("separation", 10)
		body.add_child(lines)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		body.add_child(row)
		row.add_child(button(I18n.t("close"), "Ghost", close))

	func show_story(id: String, who: String) -> void:
		head.text = I18n.fmt("f2p_st_view_hdr", {"name": F2P.char_name(who).to_upper(), "title": F2P.story_title(id, "").to_upper()})
		for c in lines.get_children():
			c.queue_free()
		for i in range(3):
			var l := Label.new()
			var speaker := I18n.t("f2p_st_you") if i == 1 else F2P.char_name(who)
			l.text = I18n.fmt("f2p_st_says", {"name": speaker, "text": F2P.story_line(id, i)})
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(720, 0)
			l.add_theme_color_override("font_color", Palette.ACCENT_SOFT if i == 1 else Palette.TEXT)
			l.add_theme_font_size_override("font_size", 16)
			lines.add_child(l)
		open()


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

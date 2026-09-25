class_name F2PUI
## The Nutaku F2P panels for FOLD: After Dark: the cards the board shows (out of candles,
## out of moves, undo/hint, a refused result), the shop, and the map's right column
## (candles, login calendar, missions, streak, leaderboard). Everything shown is what the
## server said (F2P / Nutaku autoloads); nothing here computes a reward.
##
## Every word on screen goes through I18n (the F2P rows are data/i18n_f2p.json); what the
## server sends in English (mission text, event titles, refusal reasons) is mapped from its
## ids by I18n.mission/event_title/reason. ops/nutaku/fold_f2p/check_i18n.py fails on a
## literal or a raw server string shown here.

## Fill an overlay's Centre with one card. `buttons` = [[text, variation, Callable], ...].
static func card(overlay: Control, title: String, lines: Array, buttons: Array) -> PanelContainer:
	var centre := overlay.get_node("Centre") as CenterContainer
	for c in centre.get_children():
		c.queue_free()
	var card := PanelContainer.new()
	card.name = "F2PCard"
	card.theme_type_variation = "Glass"
	card.custom_minimum_size = Vector2(460, 0)
	centre.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var h := StudioTheme.display_label(title, 34, Palette.GOLD)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	for ln in lines:
		var l := StudioTheme.serif_label(str(ln), 16, Palette.TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(420, 0)
		col.add_child(l)
	var status := StudioTheme.mono_label("", 12, Palette.MUTED)
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(420, 0)
	col.add_child(status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	for b in buttons:
		var btn := Button.new()
		btn.text = str(b[0])
		btn.name = str(b[3]) if b.size() > 3 else btn.text.validate_node_name()
		btn.theme_type_variation = str(b[1])
		var cb: Callable = b[2]
		btn.pressed.connect(func():
			btn.disabled = true
			await cb.call(status)
			if is_instance_valid(btn):
				btn.disabled = false)
		row.add_child(btn)
	overlay.visible = true
	return card


static func gold(sku_id: String) -> String:
	return I18n.f("gold", F2P.price(sku_id))


## The shop as a card on `overlay`. on_done is called after any purchase or on close.
static func shop(overlay: Control, on_done: Callable) -> void:
	var lines := [F2P.candle_text()]
	var buttons := []
	var e := F2P.energy()
	var full := int(e.get("now", 0)) >= int(e.get("max", 5))
	var offers := [[F2P.SKU_CANDLE, "offer_candle"], [F2P.SKU_REFILL, "offer_refill"],
		[F2P.SKU_HINTS, "offer_hints"], [F2P.SKU_UNDOS, "offer_undos"], [F2P.SKU_MOVES, "offer_moves"],
		[F2P.SKU_STARTER, "offer_starter"], ["nights_7", "offer_nights"], ["all_scenes", "offer_all_scenes"]]
	for o in offers:
		if o[0] == F2P.SKU_REFILL and full:
			continue
		if Nutaku.sku(o[0]).is_empty():
			continue
		var sku_id: String = o[0]
		var cb := func(status: Label):
			status.text = I18n.t("waiting_nutaku")
			var r := await Nutaku.buy(sku_id)
			status.text = _pay_text(r)
			await on_done.call()
		buttons.append(["%s · %s" % [I18n.t(o[1]), gold(sku_id)], "Amber", cb, "Buy_" + sku_id])
	var close := func(_s: Label):
		await on_done.call()
	buttons.append([I18n.t("close"), "Ghost", close, "Close"])
	var c := card(overlay, I18n.t("shop"), lines, [])
	# a column of offers reads better than a row of seven
	var col := c.get_child(0) as VBoxContainer
	var row := col.get_child(col.get_child_count() - 1)
	row.queue_free()
	var status := col.get_node("Status") as Label
	for b in buttons:
		var btn := Button.new()
		btn.text = str(b[0])
		btn.name = str(b[3])
		btn.theme_type_variation = str(b[1])
		var cb: Callable = b[2]
		btn.pressed.connect(func():
			btn.disabled = true
			await cb.call(status)
			if is_instance_valid(btn):
				btn.disabled = false)
		col.add_child(btn)


static func _pay_text(r: Dictionary) -> String:
	match str(r.get("status", "")):
		"success":
			return I18n.t("pay_done")
		"cancel":
			return I18n.t("pay_cancel")
		"errorFromGPHS":
			return I18n.t("pay_refunded")
	return I18n.t("pay_failed")


## Why F2P.use() failed, in the player's language: the payment's outcome if buying the
## token was the problem, else the server's refusal mapped through I18n.reason.
static func use_fail(r: Dictionary) -> String:
	if r.has("payment"):
		return _pay_text(r["payment"])
	return I18n.reason(r.get("reason", ""))


# ---- the map's right column --------------------------------------------------------------

static func _panel(title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "Card"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(StudioTheme.display_label(title, 16, Palette.ACCENT))
	v.set_meta("panel", p)
	return v


static func side(rebuild: Callable, open_shop: Callable) -> Array:
	var s: Dictionary = Nutaku.state
	var out := []
	var daily: Dictionary = s.get("daily", {})

	# the daily challenge (F2P.fetch_challenge ran before this): today's board, the reward
	# if it is still unclaimed, the challenge streak, the countdown to the next one
	var ch: Dictionary = F2P.challenge
	if not ch.is_empty():
		var dc := _panel(I18n.f("dc_title", int(ch.get("number", 0))))
		dc.name = "DailyChallenge"
		if bool(ch.get("claimed", false)):
			dc.add_child(StudioTheme.mono_label(I18n.f("dc_done", int(ch.get("streak", 0))), 13, Palette.SUCCESS))
		else:
			dc.add_child(StudioTheme.serif_label(I18n.f("dc_reward", _reward_text(ch.get("reward", {}))), 14, Palette.TEXT))
			if int(ch.get("streak", 0)) > 0:
				dc.add_child(StudioTheme.mono_label(I18n.t("dc_streak") % [int(ch["streak"]),
					int(ch.get("streak_every", 7)), _reward_text(ch.get("streak_bonus", {}))], 12, Palette.MUTED))
		var cd := StudioTheme.mono_label(I18n.f("next_in", F2P.challenge_countdown()), 12, Palette.GOLD)
		cd.name = "ChallengeCountdown"
		dc.add_child(cd)
		var play := Button.new()
		play.name = "PlayDaily"
		play.text = I18n.t("dc_play_again") if bool(ch.get("claimed", false)) else I18n.t("dc_play")
		play.theme_type_variation = "Ghost" if bool(ch.get("claimed", false)) else "Primary"
		play.pressed.connect(func(): F2P.daily_requested.emit())
		dc.add_child(play)
		# today's scores (the server's replay score of each player's best accepted win)
		var lbv := VBoxContainer.new()
		lbv.name = "DailyBoard"
		dc.add_child(lbv)
		_fill_daily_board(lbv)
		out.append(dc.get_meta("panel"))

	# the weekly event: one woman featured, a seven-board bonus track, her keepsake. While an
	# update pack's limited event is on, the weekly rotation runs alongside it (event_all.weekly)
	var ev: Dictionary = F2P.event_all
	if not ev.is_empty():
		out.append(_event_panel(ev, false))
		if typeof(ev.get("weekly")) == TYPE_DICTIONARY:
			out.append(_event_panel(ev["weekly"], true))

	# the crane letters: each woman's crane, how far it is open, the last fold read
	if not F2P.cranes().is_empty():
		out.append(cranes_panel())

	# hard mode: the finished chapters' boards turned a quarter turn (F2P.fetch_hard ran first)
	if not F2P.hard.is_empty():
		out.append(hard_panel())

	# candles + shop
	var c := _panel(I18n.t("candles_title"))
	var cl := StudioTheme.mono_label(F2P.candle_text(), 14, Palette.GOLD)
	cl.name = "CandleText"
	c.add_child(cl)
	var shop := Button.new()
	shop.name = "Shop"
	shop.text = I18n.t("shop")
	shop.theme_type_variation = "Amber"
	shop.pressed.connect(func(): open_shop.call())
	c.add_child(shop)
	out.append(c.get_meta("panel"))

	# login calendar + streak
	var cal: Dictionary = daily.get("calendar", {})
	var d := _panel(I18n.t("tonight") % [int(daily.get("streak", 0)), int(daily.get("streak_best", 0))])
	var rewards: Array = cal.get("rewards", [])
	var idx := int(cal.get("index", 0))
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	for i in range(rewards.size()):
		var lab := StudioTheme.mono_label("%d" % (i + 1), 13,
			Palette.GOLD if i == idx else (Palette.MUTED if i < idx else Palette.FAINT))
		lab.tooltip_text = _reward_text(rewards[i])
		strip.add_child(lab)
	d.add_child(strip)
	if not bool(cal.get("claimed_today", false)) and rewards.size() > 0:
		d.add_child(StudioTheme.serif_label(I18n.t("cal_day") % [idx + 1, _reward_text(rewards[idx])], 14, Palette.TEXT))
		var claim := Button.new()
		claim.name = "ClaimDaily"
		claim.text = I18n.t("cal_claim")
		claim.theme_type_variation = "Primary"
		claim.pressed.connect(func():
			claim.disabled = true
			await Nutaku.claim_daily()
			rebuild.call())
		d.add_child(claim)
	else:
		d.add_child(StudioTheme.mono_label(I18n.f("cal_claimed", int(fmod(float(daily.get("reset_at", 0)) / 3600.0, 24.0))), 12, Palette.MUTED))
	out.append(d.get_meta("panel"))

	# missions
	var m := _panel(I18n.t("missions"))
	var all_claimed := true
	for mi in daily.get("missions", []):
		var line := StudioTheme.mono_label("%s  %d/%d" % [I18n.mission(mi), int(mi["progress"]), int(mi["goal"])], 13,
			Palette.SUCCESS if bool(mi["claimed"]) else (Palette.GOLD if bool(mi["done"]) else Palette.TEXT))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m.add_child(line)
		all_claimed = all_claimed and bool(mi["claimed"])
		if bool(mi["done"]) and not bool(mi["claimed"]):
			var slot := int(mi["slot"])
			var b := Button.new()
			b.name = "ClaimMission%d" % slot
			b.text = I18n.f("claim", _reward_text(mi["reward"]))
			b.theme_type_variation = "Primary"
			b.pressed.connect(func():
				b.disabled = true
				await Nutaku.claim_mission(slot)
				rebuild.call())
			m.add_child(b)
	if all_claimed and not bool(daily.get("all_missions_bonus_claimed", false)):
		var bb := Button.new()
		bb.name = "ClaimBonus"
		bb.text = I18n.f("all_three", _reward_text(daily.get("all_missions_bonus", {})))
		bb.theme_type_variation = "Primary"
		bb.pressed.connect(func():
			bb.disabled = true
			await Nutaku.claim_bonus()
			rebuild.call())
		m.add_child(bb)
	out.append(m.get_meta("panel"))

	# leaderboard (filled after the request comes back)
	var lb := _panel(I18n.t("leaderboard"))
	lb.name = "Board"
	var wait := StudioTheme.mono_label("…", 13, Palette.MUTED)
	lb.add_child(wait)
	out.append(lb.get_meta("panel"))
	_fill_board(lb, wait)
	return out


## The Cranes panel: every woman's crane and how many of its folds are open (a tap rereads
## them), and the last fold opened. Coco's own crane reads "Not yet" until its last fold.
static func cranes_panel() -> Control:
	var cp := _panel(I18n.t("cranes_title"))
	cp.name = "Cranes"
	for c in F2P.cranes():
		var who := str(c["who"])
		var n := int(c.get("opened", 0))
		var of := int(c.get("of", 0))
		var b := Button.new()
		b.name = "Crane_" + who
		b.text = "%s  %d/%d" % [I18n.cast(who), n, of]
		if who == "coco" and n < of:
			b.text += "  ·  " + I18n.t("cranes_not_yet")
		b.theme_type_variation = "Ghost"
		b.disabled = n == 0
		b.pressed.connect(func(): F2P.crane_requested.emit(who))
		cp.add_child(b)
	var last := F2P.last_letter()
	if last.is_empty():
		var none := StudioTheme.mono_label(I18n.t("cranes_none"), 12, Palette.MUTED)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cp.add_child(none)
	else:
		cp.add_child(StudioTheme.mono_label(I18n.t("cranes_last") + "  ·  " + I18n.t("crane_fold") % [I18n.cast(str(last["who"])),
			int(last["fold"]), int(last["of"])], 12, Palette.GOLD))
		var txt := StudioTheme.serif_label(I18n.letter(str(last["id"])), 13, Palette.TEXT)
		txt.name = "CranesLast"
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cp.add_child(txt)
		var tap := StudioTheme.mono_label(I18n.t("cranes_tap"), 11, Palette.MUTED)
		tap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cp.add_child(tap)
	return cp.get_meta("panel")


## Reread `who`'s opened folds on `overlay`, one at a time (‹ ›), starting at the last.
static func crane_reader(overlay: Control, who: String, at: int, on_close: Callable) -> void:
	var folds := F2P.opened_folds(who)
	if folds.is_empty():
		on_close.call()
		return
	var i := clampi(at if at >= 0 else folds.size() - 1, 0, folds.size() - 1)
	var lt: Dictionary = folds[i]
	var lines := [I18n.letter(str(lt["id"]))]
	if lt.has("hook"):
		lines.append(I18n.letter(str(lt["hook"])))
	var prev := func(_s: Label): crane_reader(overlay, who, i - 1, on_close)
	var shut := func(_s: Label): on_close.call()
	var nxt := func(_s: Label): crane_reader(overlay, who, i + 1, on_close)
	var buttons := []
	if i > 0:
		buttons.append(["‹", "Ghost", prev, "Prev"])
	buttons.append([I18n.t("close"), "Amber", shut, "Close"])
	if i < folds.size() - 1:
		buttons.append(["›", "Ghost", nxt, "Next"])
	var c := card(overlay, I18n.t("crane_fold") % [I18n.cast(who), int(lt["fold"]), int(lt["of"])], lines, buttons)
	c.name = "CraneReader"


## Hard mode on the map: each finished chapter's hard progress, the reward rule, and Play
## for the next uncleared hard board of the first open chapter. Locked text until a
## chapter is done.
static func hard_panel() -> Control:
	var hp := _panel(I18n.t("hard_title"))
	hp.name = "HardMode"
	var rule := StudioTheme.serif_label(I18n.t("hard_rule"), 13, Palette.TEXT)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hp.add_child(rule)
	var open := F2P.hard_open_chapters()
	if open.is_empty():
		var lk := StudioTheme.mono_label(I18n.t("hard_locked"), 12, Palette.MUTED)
		lk.name = "HardLocked"
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hp.add_child(lk)
		return hp.get_meta("panel")
	for c in open:
		var done := int(c.get("cleared", 0)) >= int(c.get("total", 0))
		var row := StudioTheme.mono_label(I18n.t("hard_row") % [I18n.chapter(str(c["id"])), int(c.get("cleared", 0)),
			int(c.get("total", 0))], 13, Palette.SUCCESS if done else Palette.GOLD)
		row.name = "HardRow_" + str(c["id"])
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hp.add_child(row)
	hp.add_child(StudioTheme.mono_label(I18n.t("hard_every") % [int(F2P.hard.get("per_n", 5)),
		_reward_text(F2P.hard.get("per_n_reward", {}))], 12, Palette.MUTED))
	var nxt := F2P.hard_next()
	if nxt < 0:
		hp.add_child(StudioTheme.mono_label(I18n.t("hard_all"), 12, Palette.SUCCESS))
	else:
		var hb := Button.new()
		hb.name = "PlayHard"
		hb.text = I18n.f("hard_play", nxt + 1)
		hb.theme_type_variation = "Primary"
		hb.pressed.connect(func(): F2P.hard_requested.emit())
		hp.add_child(hb)
	return hp.get_meta("panel")


static func _fill_daily_board(v: VBoxContainer) -> void:
	var r := await F2P.daily_leaderboard()
	if not is_instance_valid(v) or not r["ok"]:
		return
	var shown := 0
	for row in r["body"].get("top", []):
		if shown >= 3:
			break
		shown += 1
		v.add_child(StudioTheme.mono_label("%d.  %-12s %6d" % [int(row["rank"]), str(row["nickname"]).left(12), int(row["score"])],
			12, Palette.GOLD if bool(row["you"]) else Palette.TEXT))
	var me = r["body"].get("you")
	if typeof(me) == TYPE_DICTIONARY and int(me["rank"]) > shown:
		v.add_child(StudioTheme.mono_label("%d.  %-12s %6d" % [int(me["rank"]), I18n.t("you"), int(me["score"])], 12, Palette.GOLD))
	if shown == 0:
		v.add_child(StudioTheme.mono_label(I18n.t("no_scores"), 12, Palette.MUTED))


static func _fill_board(v: VBoxContainer, placeholder: Label) -> void:
	var r := await Nutaku.leaderboard()
	if not is_instance_valid(v):
		return
	placeholder.queue_free()
	if not r["ok"]:
		v.add_child(StudioTheme.mono_label(I18n.t("unavailable"), 13, Palette.RED_TEXT))
		return
	var shown := 0
	for row in r["body"].get("top", []):
		if shown >= 5:
			break
		shown += 1
		v.add_child(StudioTheme.mono_label("%d.  %-12s %6d" % [int(row["rank"]), str(row["nickname"]).left(12), int(row["score"])],
			13, Palette.GOLD if bool(row["you"]) else Palette.TEXT))
	var me = r["body"].get("you")
	if typeof(me) == TYPE_DICTIONARY and int(me["rank"]) > shown:
		v.add_child(StudioTheme.mono_label("%d.  %-12s %6d" % [int(me["rank"]), I18n.t("you"), int(me["score"])], 13, Palette.GOLD))
	v.add_child(StudioTheme.mono_label(I18n.f("players", int(r["body"].get("players", 0))), 11, Palette.MUTED))


static func _reward_text(r) -> String:
	if typeof(r) != TYPE_DICTIONARY:
		return ""
	var parts := []
	if r.get("energy_fill", false):
		parts.append(I18n.t("rw_full"))
	if int(r.get("energy", 0)) > 0:
		parts.append(I18n.f("rw_candles", int(r["energy"])))
	for k in (r.get("tokens", {}) as Dictionary).keys():
		if I18n.has("rw_" + str(k)):
			parts.append(I18n.f("rw_" + str(k), int(r["tokens"][k])))
	if int(r.get("unlimited_s", 0)) > 0:
		parts.append(I18n.f("rw_unlimited", int(r["unlimited_s"]) / 3600))
	return I18n.t("rw_sep").join(parts)


## One event's panel. `weekly`: the weekly rotation running alongside a pack's limited event.
static func _event_panel(ev: Dictionary, weekly: bool) -> Control:
	var ep := _panel(I18n.f("event_limited" if bool(ev.get("limited", false)) else "event_panel", I18n.event_title(ev)))
	ep.name = "WeeklyEvent"
	if weekly:
		ep.name = "AlongsideEvent"
	if I18n.event_blurb(ev) != "":
		var bl := StudioTheme.serif_label(I18n.event_blurb(ev), 13, Palette.TEXT)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ep.add_child(bl)
	var n := F2P.event_main_boards(ev)
	ep.add_child(StudioTheme.mono_label(I18n.t("event_boards") % [int(ev.get("cleared", 0)), n,
		_reward_text(ev.get("per_board", {}))], 13, Palette.GOLD))
	# a pack's daily boards: one more opens each day of its limited event
	var nd := (ev.get("boards", []) as Array).size() - n
	if nd > 0:
		var opened := 0
		for b in ev.get("boards", []):
			if b.has("daily") and bool(b["open"]):
				opened += 1
		var dl := StudioTheme.mono_label(I18n.t("event_daily") % [int(ev.get("daily_cleared", 0)), opened, nd], 12, Palette.GOLD)
		dl.name = "EventDaily"
		ep.add_child(dl)
	ep.add_child(StudioTheme.mono_label(I18n.f("event_won" if bool(ev.get("exclusive_claimed", false)) else "event_all",
		I18n.event_reward(ev)), 12,
		Palette.SUCCESS if bool(ev.get("exclusive_claimed", false)) else Palette.MUTED))
	var ends := StudioTheme.mono_label(I18n.f("ends_in", F2P.event_ends_text(ev)), 12, Palette.MUTED)
	ends.name = "EventEnds"
	if weekly:
		ends.name = "WeeklyEnds"
	ep.add_child(ends)
	var eb := Button.new()
	eb.name = "PlayEvent"
	if weekly:
		eb.name = "PlayWeekly"
	eb.text = I18n.f("event_play", F2P.event_next_board(ev) + 1)
	eb.theme_type_variation = "Primary"
	eb.pressed.connect(func():
		F2P.pick_event(weekly)
		F2P.event_requested.emit())
	ep.add_child(eb)
	return ep.get_meta("panel")

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

	# the weekly event: one woman featured, a seven-board bonus track, her keepsake
	var ev: Dictionary = F2P.event
	if not ev.is_empty():
		var ep := _panel(I18n.f("event_panel", I18n.event_title(ev)))
		ep.name = "WeeklyEvent"
		if I18n.event_blurb(ev) != "":
			var bl := StudioTheme.serif_label(I18n.event_blurb(ev), 13, Palette.TEXT)
			bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ep.add_child(bl)
		var n := (ev.get("boards", []) as Array).size()
		ep.add_child(StudioTheme.mono_label(I18n.t("event_boards") % [int(ev.get("cleared", 0)), n,
			_reward_text(ev.get("per_board", {}))], 13, Palette.GOLD))
		ep.add_child(StudioTheme.mono_label(I18n.f("event_won" if bool(ev.get("exclusive_claimed", false)) else "event_all",
			I18n.event_reward(ev)), 12,
			Palette.SUCCESS if bool(ev.get("exclusive_claimed", false)) else Palette.MUTED))
		var ends := StudioTheme.mono_label(I18n.f("ends_in", F2P.event_ends_text()), 12, Palette.MUTED)
		ends.name = "EventEnds"
		ep.add_child(ends)
		var eb := Button.new()
		eb.name = "PlayEvent"
		eb.text = I18n.f("event_play", F2P.event_next_board() + 1)
		eb.theme_type_variation = "Primary"
		eb.pressed.connect(func(): F2P.event_requested.emit())
		ep.add_child(eb)
		out.append(ep.get_meta("panel"))

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

class_name F2PUI
## The Nutaku F2P panels for FOLD: After Dark: the cards the board shows (out of candles,
## out of moves, undo/hint, a refused result), the shop, and the map's right column
## (candles, login calendar, missions, streak, leaderboard). Everything shown is what the
## server said (F2P / Nutaku autoloads); nothing here computes a reward.
##
## English only for now: the F2P strings are not in scripts/i18n.gd yet (Nutaku's shelf is
## the English one). See ops/nutaku/fold_f2p/README.md "left before submission".

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
	return "%d gold" % F2P.price(sku_id)


## The shop as a card on `overlay`. on_done is called after any purchase or on close.
static func shop(overlay: Control, on_done: Callable) -> void:
	var lines := [F2P.candle_text()]
	var buttons := []
	var e := F2P.energy()
	var full := int(e.get("now", 0)) >= int(e.get("max", 5))
	var offers := [[F2P.SKU_CANDLE, "One candle now"], [F2P.SKU_REFILL, "Refill candles"],
		[F2P.SKU_HINTS, "3 hints"], [F2P.SKU_UNDOS, "5 undos"], [F2P.SKU_MOVES, "+5 moves token"],
		[F2P.SKU_STARTER, "Starter pack (once)"], ["nights_7", "Seven Nights: unlimited candles"]]
	for o in offers:
		if o[0] == F2P.SKU_REFILL and full:
			continue
		if Nutaku.sku(o[0]).is_empty():
			continue
		var sku_id: String = o[0]
		var cb := func(status: Label):
			status.text = "Waiting for Nutaku…"
			var r := await Nutaku.buy(sku_id)
			status.text = _pay_text(r)
			await on_done.call()
		buttons.append(["%s · %s" % [o[1], gold(sku_id)], "Amber", cb, "Buy_" + sku_id])
	var close := func(_s: Label):
		await on_done.call()
	buttons.append(["Close", "Ghost", close, "Close"])
	var c := card(overlay, "Shop", lines, [])
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
			return "Done."
		"cancel":
			return "Cancelled. No gold was spent."
		"errorFromGPHS":
			return "The game server could not deliver it; Nutaku refunded your gold."
	return "Not bought: %s" % str(r.get("error", r.get("status", "error")))


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

	# candles + shop
	var c := _panel("Candles")
	var cl := StudioTheme.mono_label(F2P.candle_text(), 14, Palette.GOLD)
	cl.name = "CandleText"
	c.add_child(cl)
	var shop := Button.new()
	shop.name = "Shop"
	shop.text = "Shop"
	shop.theme_type_variation = "Amber"
	shop.pressed.connect(func(): open_shop.call())
	c.add_child(shop)
	out.append(c.get_meta("panel"))

	# login calendar + streak
	var cal: Dictionary = daily.get("calendar", {})
	var d := _panel("Tonight · streak %d (best %d)" % [int(daily.get("streak", 0)), int(daily.get("streak_best", 0))])
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
		d.add_child(StudioTheme.serif_label("Day %d: %s" % [idx + 1, _reward_text(rewards[idx])], 14, Palette.TEXT))
		var claim := Button.new()
		claim.name = "ClaimDaily"
		claim.text = "Light tonight's candle"
		claim.theme_type_variation = "Primary"
		claim.pressed.connect(func():
			claim.disabled = true
			await Nutaku.claim_daily()
			rebuild.call())
		d.add_child(claim)
	else:
		d.add_child(StudioTheme.mono_label("Claimed. Next at the %02d:00 UTC reset." % int(fmod(float(daily.get("reset_at", 0)) / 3600.0, 24.0)), 12, Palette.MUTED))
	out.append(d.get_meta("panel"))

	# missions
	var m := _panel("Missions")
	var all_claimed := true
	for mi in daily.get("missions", []):
		var line := StudioTheme.mono_label("%s  %d/%d" % [str(mi["text"]), int(mi["progress"]), int(mi["goal"])], 13,
			Palette.SUCCESS if bool(mi["claimed"]) else (Palette.GOLD if bool(mi["done"]) else Palette.TEXT))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m.add_child(line)
		all_claimed = all_claimed and bool(mi["claimed"])
		if bool(mi["done"]) and not bool(mi["claimed"]):
			var slot := int(mi["slot"])
			var b := Button.new()
			b.name = "ClaimMission%d" % slot
			b.text = "Claim: " + _reward_text(mi["reward"])
			b.theme_type_variation = "Primary"
			b.pressed.connect(func():
				b.disabled = true
				await Nutaku.claim_mission(slot)
				rebuild.call())
			m.add_child(b)
	if all_claimed and not bool(daily.get("all_missions_bonus_claimed", false)):
		var bb := Button.new()
		bb.name = "ClaimBonus"
		bb.text = "All three: " + _reward_text(daily.get("all_missions_bonus", {}))
		bb.theme_type_variation = "Primary"
		bb.pressed.connect(func():
			bb.disabled = true
			await Nutaku.claim_bonus()
			rebuild.call())
		m.add_child(bb)
	out.append(m.get_meta("panel"))

	# leaderboard (filled after the request comes back)
	var lb := _panel("Leaderboard")
	lb.name = "Board"
	var wait := StudioTheme.mono_label("…", 13, Palette.MUTED)
	lb.add_child(wait)
	out.append(lb.get_meta("panel"))
	_fill_board(lb, wait)
	return out


static func _fill_board(v: VBoxContainer, placeholder: Label) -> void:
	var r := await Nutaku.leaderboard()
	if not is_instance_valid(v):
		return
	placeholder.queue_free()
	if not r["ok"]:
		v.add_child(StudioTheme.mono_label("unavailable", 13, Palette.RED_TEXT))
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
		v.add_child(StudioTheme.mono_label("%d.  %-12s %6d" % [int(me["rank"]), "you", int(me["score"])], 13, Palette.GOLD))
	v.add_child(StudioTheme.mono_label("%d players" % int(r["body"].get("players", 0)), 11, Palette.MUTED))


static func _reward_text(r) -> String:
	if typeof(r) != TYPE_DICTIONARY:
		return ""
	var parts := []
	if r.get("energy_fill", false):
		parts.append("full candles")
	if int(r.get("energy", 0)) > 0:
		parts.append("%d candle%s" % [int(r["energy"]), "" if int(r["energy"]) == 1 else "s"])
	for k in (r.get("tokens", {}) as Dictionary).keys():
		var n := int(r["tokens"][k])
		var word: String = {"hint": "hint", "undo": "undo", "moves": "+5 moves"}.get(k, k)
		parts.append("%d× %s" % [n, word])
	return ", ".join(parts)

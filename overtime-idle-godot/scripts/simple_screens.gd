class_name SimpleScreens
## The small dialogs: intro, daily floor (start + result), prestige, eviction notice.
## Each is an Overlay subclass built here so scenes/*.tscn can carry one root each.


class Intro extends Overlay:
	signal start
	func build() -> void:
		card_width = 720
		card.custom_minimum_size = Vector2(720, 0)
		var t := tag("18+ · ADULTS ONLY")
		t.add_theme_color_override("font_color", Palette.HEAT)
		title("Overtime Landlord: Idle")
		para("A 5×4 floor that keeps working after you close the tab. Every ten minutes each floor you built pays a shift — the board you place sets the rent per hour. Rent is due per floor, per day; a floor that cannot cover it is evicted and its people walk back to the roster. Staff are the gacha. Objects are bought with rent. Two ladders of plates: the skill ladder is a board you built and never comes from time; the affection ladder is time, and says so. Everyone in this building is an adult.", 15)
		var b := button("OPEN THE BUILDING", "Primary", func() -> void:
			start.emit()
			close())
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		body.add_child(b)


class Daily extends Overlay:
	signal start
	var best: Label
	func build() -> void:
		tag("DAILY FLOOR")
		title("Everyone gets the same pieces today")
		para("One layout, the same for every landlord today. Score is your best single settle. The pieces are the building's, not your roster's.", 15)
		best = Label.new()
		best.theme_type_variation = "Value"
		best.add_theme_color_override("font_color", Palette.GOLD)
		body.add_child(best)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		row.add_child(button("CLOSE", "Ghost", close))
		row.add_child(button("PLAY TODAY'S FLOOR", "Primary", func() -> void:
			start.emit()
			close()))
	func on_open() -> void:
		var b := int(Ticker.B["daily"].get(Ticker.daily_key(), 0))
		best.text = ("Today's best: %d" % b) if b > 0 else "Not played today."


class DailyResult extends Overlay:
	signal back
	var t1: RollingLabel
	var t2: Label
	var pct: RollingLabel
	func build() -> void:
		tag("DAILY FLOOR · SETTLED")
		t1 = RollingLabel.new()
		t1.theme_type_variation = "Big"
		t1.add_theme_font_size_override("font_size", 44)
		t1.suffix = " / shift"
		t1.set_now(0)
		body.add_child(t1)
		t2 = Label.new()
		t2.theme_type_variation = "Value"
		t2.add_theme_color_override("font_color", Palette.HEAT)
		body.add_child(t2)
		pct = RollingLabel.new()
		pct.theme_type_variation = "Big"
		pct.add_theme_color_override("font_color", Palette.ACCENT_SOFT)
		pct.prefix = "You beat "
		pct.suffix = "% of landlords."
		pct.set_now(0)
		body.add_child(pct)
		var b := button("BACK TO THE BUILDING", "Primary", func() -> void:
			back.emit()
			close())
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		body.add_child(b)
	func show_result(res: Dictionary) -> void:
		t1.set_now(0)
		pct.set_now(0)
		t2.text = "Today's best %d · chain %d" % [int(res["best"]), int(res["chain"])]
		open()
		await get_tree().create_timer(0.2).timeout
		t1.set_target(float(int(res["shift"])), 0.9)
		pct.set_target(float(int(res["pct"])), 1.1)


class Prestige extends Overlay:
	signal sign
	func build() -> void:
		tag("ACQUISITION")
		title("A second building")
		para("Seven days with every floor solvent. Mirei has found a bigger building. You start it empty — the roster comes with you — and every shift in it pays ×1.5.", 15)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		row.add_child(button("NOT YET", "Ghost", close))
		row.add_child(button("SIGN", "Primary", func() -> void:
			sign.emit()
			close()))


class Notice extends Overlay:
	signal understood
	var msg: RichTextLabel
	func build() -> void:
		tag("NOTICE")
		title("Evicted")
		msg = para("", 15)
		var b := button("UNDERSTOOD", "Amber", func() -> void:
			understood.emit()
			close())
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		body.add_child(b)
	func show_evictions(floors: Array) -> void:
		var names: Array = []
		for n in floors:
			names.append(str(n))
		msg.text = "Floor %s did not cover the day's rent. Cleared. The people are back in the roster; the objects are gone." % ", ".join(names)
		open()

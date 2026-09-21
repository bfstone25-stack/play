class_name SimpleScreens
## The small dialogs: daily floor (start + result), prestige, eviction notice.
## Each is an Overlay subclass built here so scenes/*.tscn can carry one root each.
##
## `Intro` used to live here and is gone: a card with a Tag, a Title, a 90-word
## paragraph and one themed Button was the game's title screen, and it broke four
## lines of ops/adult_forks/TITLE_SCREENS.md at once. It is replaced by
## scripts/title_screen.gd, which keeps the same Overlay contract — open/close/
## is_open and a `start` signal — so building.gd and the web dev bridge did not move.


class Daily extends Overlay:
	signal start
	var best: Label
	func build() -> void:
		tag(I18n.t("daily_tag"))
		title(I18n.t("daily_title"))
		para(I18n.t("daily_para"), 15)
		best = Label.new()
		best.theme_type_variation = "Value"
		best.add_theme_color_override("font_color", Palette.GOLD)
		body.add_child(best)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		row.add_child(button(I18n.t("close"), "Ghost", close))
		row.add_child(button(I18n.t("daily_play"), "Primary", func() -> void:
			start.emit()
			close()))
	func on_open() -> void:
		var b := int(Ticker.B["daily"].get(Ticker.daily_key(), 0))
		best.text = I18n.f("daily_best", b) if b > 0 else I18n.t("daily_none")


class DailyResult extends Overlay:
	signal back
	var t1: RollingLabel
	var t2: Label
	var pct: RollingLabel
	func build() -> void:
		tag(I18n.t("daily_settled"))
		t1 = RollingLabel.new()
		t1.theme_type_variation = "Big"
		t1.add_theme_font_size_override("font_size", 44)
		t1.suffix = I18n.t("daily_per_shift")
		t1.set_now(0)
		body.add_child(t1)
		t2 = Label.new()
		t2.theme_type_variation = "Value"
		t2.add_theme_color_override("font_color", Palette.HEAT)
		body.add_child(t2)
		pct = RollingLabel.new()
		pct.theme_type_variation = "Big"
		pct.add_theme_color_override("font_color", Palette.ACCENT_SOFT)
		pct.prefix = I18n.t("daily_beat")
		pct.suffix = I18n.t("daily_beat_end")
		pct.set_now(0)
		body.add_child(pct)
		var b := button(I18n.t("daily_back"), "Primary", func() -> void:
			back.emit()
			close())
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		body.add_child(b)
	func show_result(res: Dictionary) -> void:
		t1.set_now(0)
		pct.set_now(0)
		t2.text = I18n.f("daily_result", [int(res["best"]), int(res["chain"])])
		open()
		await get_tree().create_timer(0.2).timeout
		t1.set_target(float(int(res["shift"])), 0.9)
		pct.set_target(float(int(res["pct"])), 1.1)


class Prestige extends Overlay:
	signal sign
	func build() -> void:
		tag(I18n.t("pres_tag"))
		title(I18n.t("pres_title"))
		para(I18n.t("pres_para"), 15)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_theme_constant_override("separation", 8)
		body.add_child(row)
		row.add_child(button(I18n.t("pres_no"), "Ghost", close))
		row.add_child(button(I18n.t("pres_yes"), "Primary", func() -> void:
			sign.emit()
			close()))


class Notice extends Overlay:
	signal understood
	var msg: RichTextLabel
	func build() -> void:
		tag(I18n.t("notice_tag"))
		title(I18n.t("notice_title"))
		msg = para("", 15)
		var b := button(I18n.t("understood"), "Amber", func() -> void:
			understood.emit()
			close())
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		body.add_child(b)
	func show_evictions(floors: Array) -> void:
		var names: Array = []
		for n in floors:
			names.append(str(n))
		msg.text = I18n.f("notice_body", ", ".join(names))
		open()

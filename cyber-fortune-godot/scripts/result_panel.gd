class_name ResultPanel
extends PanelContainer
## The read: a slip on paper (East) or a card's reading on parchment (West). Four lines —
## rank, 签文, plain reading, one thing to do today — then keep / burn / resolve (化解 or
## integrate: the same timed conversion, named in its own tradition).

signal done

var result: Dictionary
var buttons: Dictionary = {}


func setup(r: Dictionary) -> void:
	result = r
	var west: bool = r["kind"] == "card"
	theme_type_variation = "Parchment" if west else "Paper"
	var ink := Palette.PARCHMENT_INK if west else Palette.PAPER_INK
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var rank: String = r["rank"]
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)
	var stamp := StudioTheme.label(Tx.t("rank." + rank), 40 if Tx.lang == "zh" else 28, Palette.rank_color(rank) if rank != "moji" else Palette.GOLD_DEEP, "serif")
	head.add_child(stamp)
	if west:
		var c := Fortune.card(r["id"])
		var sub := StudioTheme.label("%s · %s · %s" % [Tx.field(c, "name"), Tx.t("deck.reversed" if r["reversed"] else "deck.upright"), Tx.t("deck.position", {"p": Tx.t("pos." + r["position"])})], 15, Palette.SILVER_DIM, "bold")
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sub)
		var read := StudioTheme.wrapped(Tx.field(c, "rev" if r["reversed"] else "up"), 20, ink, "serif" if Tx.lang == "zh" else "italic")
		v.add_child(read)
		v.add_child(_rule(Palette.SILVER_DIM))
		v.add_child(StudioTheme.label(Tx.t("slip.today"), 13, Palette.CANDLE_DEEP, "bold"))
		v.add_child(StudioTheme.wrapped(Tx.field(c, "rev_do" if r["reversed"] else "up_do"), 19, ink, "bold"))
	else:
		var s := Fortune.slip(r["id"])
		var subj := StudioTheme.label(Tx.t("subj." + r["subject"]), 15, Palette.LACQUER, "bold")
		subj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(subj)
		var verse := StudioTheme.label(Tx.field(s, "verse"), 44 if Tx.lang == "zh" else 26, ink, "serif" if Tx.lang == "zh" else "italic")
		verse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		verse.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(verse)
		if Tx.lang == "zh":
			var en := StudioTheme.label(str(s["verse_en"]), 14, Palette.GOLD_DEEP, "italic")
			en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(en)
		v.add_child(_rule(Palette.PAPER_LINE))
		v.add_child(StudioTheme.wrapped(Tx.field(s, "read"), 19, ink, "serif" if Tx.lang == "zh" else "ui"))
		v.add_child(_rule(Palette.PAPER_LINE))
		v.add_child(StudioTheme.label(Tx.t("slip.today"), 13, Palette.LACQUER, "bold"))
		v.add_child(StudioTheme.wrapped(Tx.field(s, "do"), 19, ink, "bold"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var keep := StudioTheme.button(Tx.t("slip.keep"), "Candle" if west else "Lacquer")
	keep.pressed.connect(func():
		Fortune.keep()
		_finish())
	row.add_child(keep)
	buttons["keep"] = keep
	var burn := StudioTheme.button(Tx.t("slip.burn", {"n": Fortune.BURN[rank]}), "Silver" if west else "Gold")
	burn.pressed.connect(func():
		Fortune.burn()
		_finish())
	row.add_child(burn)
	buttons["burn"] = burn
	if Fortune.is_ill(rank):
		var cost: int = Fortune.RESOLVE_COST[rank]
		var res := StudioTheme.button(Tx.t("slip.integrate" if west else "slip.resolve", {"n": cost}), "Silver" if west else "Gold")
		res.disabled = Fortune.merit.merit < cost or Fortune.rack.size() >= Fortune.rack_slots
		res.pressed.connect(func():
			if Fortune.resolve():
				_finish())
		row.add_child(res)
		buttons["resolve"] = res
		var hint := StudioTheme.wrapped(Tx.t("slip.integrate.hint" if west else "slip.resolve.hint", {"t": Tx.minutes(int(Fortune.RESOLVE_MS[rank]))}), 13, Palette.MUTED, "ui")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hint)


func _rule(c: Color) -> Control:
	var r := ColorRect.new()
	r.color = Color(c, 0.6)
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _finish() -> void:
	var was_free: bool = result.get("free", false)
	done.emit()
	if was_free:
		var main := get_tree().current_scene
		if main and main.has_method("after_daily_read"):
			main.after_daily_read()
	queue_free()


## The dev bridge's click on one of the three buttons.
func choose(choice: String) -> bool:
	if not buttons.has(choice) or buttons[choice].disabled:
		return false
	buttons[choice].pressed.emit()
	return true

extends Control
## Offerings — the four SKUs, mocked (PLAN.md: commerce stubs grant locally). The copy
## says the one thing that matters: a paid draw is never a luckier draw.

func _ready() -> void:
	relayout()


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var bg := Backdrop.new()
	bg.mode = "east"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 84
	v.offset_left = 40
	v.offset_right = -40
	v.offset_bottom = -30
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var title := StudioTheme.label(Tx.t("shop.title"), 30, Palette.GOLD_PALE, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var honest := PanelContainer.new()
	honest.theme_type_variation = "Paper"
	var hl := StudioTheme.wrapped(Tx.t("shop.honest"), 18, Palette.PAPER_INK, "serif" if Tx.lang == "zh" else "italic")
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	honest.add_child(hl)
	v.add_child(honest)
	for sku in ["merit_s", "merit_m", "merit_l", "extra_draw", "resolve_now", "rack_slot"]:
		var p := PanelContainer.new()
		p.theme_type_variation = "Glass"
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		p.add_child(h)
		var l := StudioTheme.wrapped(Tx.t("sku." + sku), 18, Palette.TEXT, "ui")
		h.add_child(l)
		var b := StudioTheme.button(str(Fortune.SKUS[sku]["price"]), "Gold")
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func():
			if Fortune.buy(sku):
				Sfx.chime(1.4)
				get_parent().toast(Tx.t("sku." + sku).split(" · ")[0]))
		h.add_child(b)
		v.add_child(p)
	var mock := StudioTheme.label(Tx.t("shop.mock"), 13, Palette.MUTED, "bold")
	mock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(mock)

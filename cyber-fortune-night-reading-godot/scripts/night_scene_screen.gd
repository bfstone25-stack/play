extends Control
## The night — the payoff for the loop, and the only place the fork shows tier 3.
##
## The gate is real. `Gate.require` hands the decision to gate.js on the page: an ad that
## actually rendered a creative, or a purchase. Anything else and the censored plate stays
## and the beats are not shown — and a refusal is not remembered, so the next press asks
## again rather than treating the "no" as an answer for the session.

var unlocked := false
var asking := false
var beat := 0
var root: VBoxContainer


func _ready() -> void:
	unlocked = Gate.has(_key())
	relayout()


func _key() -> String:
	return "night_" + str(Night.current)


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var cl := Night.client()
	var bg := Backdrop.new()
	bg.mode = "night"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 26)
	m.add_theme_constant_override("margin_right", 26)
	m.add_theme_constant_override("margin_top", 84)
	m.add_theme_constant_override("margin_bottom", 26)
	add_child(m)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	m.add_child(root)

	root.add_child(StudioTheme.label(Tx.field(cl, "name"), 34, Palette.HOT_PALE, "serif"))
	var plate := NightPlate.new()
	plate.slot = str(cl["id"]) + ("_night" if unlocked else "_night_locked")
	plate.custom_minimum_size = Vector2(0, 420)
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(plate)

	var scene: Dictionary = cl["scene"]
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Glass"
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(mm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	mm.add_child(v)
	v.add_child(StudioTheme.wrapped(Tx.field(scene, "invite"), 18, Palette.TEXT, "serif"))
	if unlocked:
		var beats: Array = scene.get("beats_" + Tx.lang, scene.get("beats_en", []))
		for i in range(mini(beat + 1, beats.size())):
			v.add_child(StudioTheme.wrapped(str(beats[i]), 17, Palette.SMOKE, "serif"))
		if beat + 1 < beats.size():
			var more := StudioTheme.button("…", "Hot")
			more.pressed.connect(func():
				beat += 1
				relayout())
			v.add_child(more)
		else:
			v.add_child(StudioTheme.wrapped(Tx.field(scene, "after"), 17, Palette.HOT_PALE, "serif"))
			var done := StudioTheme.button(Tx.t("night.next"), "Gold")
			done.pressed.connect(_finish)
			v.add_child(done)
	else:
		var b := StudioTheme.button(Tx.t("night.scene.locked"), "Hot")
		b.disabled = asking
		b.pressed.connect(_ask)
		v.add_child(b)
		if asking:
			v.add_child(StudioTheme.label("…", 20, Palette.MUTED, "bold"))
	root.add_child(panel)


## The gate. Desktop (the paid package) is open; on the web the page decides, and only an
## "unlocked" answer opens anything.
func _ask() -> void:
	if asking:
		return
	asking = true
	relayout()
	var ok: bool = await Gate.require(_key(), Tx.field(Night.client(), "name"), "scene")
	asking = false
	if ok:
		unlocked = true
		beat = 0
	else:
		# Not remembered: nothing is written, and the next press asks the page again.
		Fortune.toast.emit(Tx.t("night.scene.denied"))
	relayout()


func _finish() -> void:
	Night.mark_seen()
	get_parent().open("home")
	if Night.cleared():
		Gate.board_offer_more("adult")
	else:
		Gate.board_offer_break()


func dev_state() -> Dictionary:
	return {"scene": {"client": Night.current, "unlocked": unlocked, "beat": beat,
		"asking": asking, "key": _key()}}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	match str(cmd.get("op", "")):
		"ask":
			_ask()
			return {"ok": true}
		"beat":
			beat += 1
			relayout()
			return {"ok": true, "beat": beat}
		"finish":
			if not unlocked:
				return {"ok": false, "why": "locked"}
			_finish()
			return {"ok": true}
	return {"ok": false, "why": "scene_has_no_" + str(cmd.get("op", ""))}


## The payoff plate. Two files, and which one is on screen is the whole of the gate's
## effect: <id>_night_locked (censored) until the page says unlocked, <id>_night after.
## A placeholder in either slot is labelled on its face.
class NightPlate extends Control:
	var slot := ""

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var tex := Night.art(slot)
		if tex:
			var ts := tex.get_size()
			var sc: float = minf(size.x / ts.x, size.y / ts.y)
			var box := Rect2((size - ts * sc) * 0.5, ts * sc)
			draw_texture_rect(tex, box, false)
			draw_rect(box, Color(Palette.HOT_DEEP, 0.6), false, 1.0)
			if Night.is_placeholder(slot):
				_label(box)
		else:
			draw_rect(r, Palette.PLUM_SOFT)
			draw_rect(r, Color(Palette.HOT_DEEP, 0.5), false, 1.0)
			_label(r)

	func _label(r: Rect2) -> void:
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 26, r.size.x, 26), Color(0, 0, 0, 0.7))
		draw_string(StudioTheme.font("bold"), Vector2(r.position.x + 10, r.position.y + r.size.y - 8),
			Tx.t("night.placeholder") + "  ·  " + slot, HORIZONTAL_ALIGNMENT_LEFT,
			r.size.x - 20, 14, Palette.HEAT)

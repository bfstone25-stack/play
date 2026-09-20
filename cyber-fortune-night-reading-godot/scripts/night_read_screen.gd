extends Control
## The reading — her room, her three tracks, the instrument, the draw, and her answer.
##
## The order is the rule: you draw for real (Fortune's ladder, not the scene's choice),
## the draw names one of her tracks, and then she answers. Only what she takes is written.

var root: VBoxContainer
var panel: Control
var reply := ""
var reply_hot := false
var last_event: Dictionary = {}


func _ready() -> void:
	Night.changed.connect(_refresh)
	relayout()


func _refresh() -> void:
	if is_inside_tree():
		relayout()


func relayout() -> void:
	for c in get_children():
		c.queue_free()
	var c := Night.client()
	var bg := Backdrop.new()
	bg.mode = str(c.get("room", "west"))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 84)
	m.add_theme_constant_override("margin_bottom", 28)
	add_child(m)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	m.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var plate := PlateView.new()
	plate.slot = str(c["id"]) + ("_turn" if not Night.offer.is_empty() else "_calm")
	plate.custom_minimum_size = Vector2(150, 190)
	head.add_child(plate)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	names.add_child(StudioTheme.label(Tx.field(c, "name"), 34, Palette.HOT_PALE, "serif"))
	names.add_child(StudioTheme.wrapped(Tx.field(c, "who"), 15, Palette.MAUVE,
		"italic" if Tx.lang == "en" else "serif"))
	names.add_child(_tracks_box(c))

	if reply != "":
		root.add_child(_reply_panel())

	if Night.offer.is_empty():
		root.add_child(_instruments())
		root.add_child(_draw_row())
	else:
		root.add_child(_offer_panel())

	# The column is top-aligned; without this the buttons float in the middle of an empty
	# lower half on a tall phone.
	var tail := Control.new()
	tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tail)

	if Night.scene_ready() and not Night.scene_seen() and Night.offer.is_empty():
		var stay := StudioTheme.button(Tx.t("night.scene"), "Gold")
		stay.pressed.connect(func(): get_parent().open("scene"))
		root.add_child(stay)


func _tracks_box(c: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var t: Array = Night.tracks()
	for i in range(t.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tr: Dictionary = c["tracks"][i]
		var lit: bool = int(t[i]) >= Night.TRACK_MAX
		var nm := StudioTheme.label(Tx.field(tr, "name"), 15,
			Palette.HOT_PALE if lit else Palette.TEXT, "bold")
		nm.custom_minimum_size = Vector2(96, 0)
		row.add_child(nm)
		var bar := TrackBar.new()
		bar.value = int(t[i])
		bar.custom_minimum_size = Vector2(120, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		v.add_child(row)
	return v


func _instruments() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(StudioTheme.label(Tx.t("night.instrument"), 15, Palette.MUTED, "bold"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for kind in ["slip", "card", "force"]:
		var b := StudioTheme.button(Tx.t("inst." + kind), "Gold" if Night.instrument == kind else "")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			Night.instrument = kind
			Night.save_state()
			relayout())
		row.add_child(b)
	v.add_child(row)
	return v


func _draw_row() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var free: bool = Fortune.free_available()
	var can: bool = Fortune.can_draw()
	var b := StudioTheme.button(Tx.t("night.draw.free" if free else "night.draw"), "Hot")
	b.disabled = not can
	b.custom_minimum_size = Vector2(0, 62)
	b.pressed.connect(_do_draw)
	v.add_child(b)
	if not free:
		var need: int = maxi(0, Fortune.TUBE - Fortune.merit.merit)
		var l := StudioTheme.label(Tx.t("night.need", {"n": need}) if need > 0 else "", 14, Palette.MUTED, "bold")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var tap := StudioTheme.button(Tx.t("night.tap"))
	tap.pressed.connect(func():
		Fortune.tap()
		relayout())
	v.add_child(tap)
	return v


func _do_draw() -> void:
	reply = ""
	var o := Night.read_her()
	if o.is_empty():
		return
	Sfx.rattle()
	Sfx.drop()
	relayout()


## What was drawn, which of her it is about, and the two things the player can do with it.
func _offer_panel() -> Control:
	var o := Night.offer
	var r: Dictionary = o["result"]
	var c := Night.client()
	var tr: Dictionary = c["tracks"][int(o["track"])]
	var p := PanelContainer.new()
	p.theme_type_variation = "Glass"
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 16)
	p.add_child(mm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mm.add_child(v)
	var rank := str(r["rank"])
	var head := HBoxContainer.new()
	head.add_child(StudioTheme.label(Tx.t("rank." + rank), 26, Palette.rank_color(rank), "serif"))
	var s: int = int(o["strength"])
	head.add_child(StudioTheme.label("   " + Tx.t("rank.strength", {"n": ("+%d" % s) if s > 0 else str(s)}),
		14, Palette.MUTED, "bold"))
	v.add_child(head)
	v.add_child(StudioTheme.wrapped(_text_of(r), 17, Palette.TEXT, "serif"))
	v.add_child(StudioTheme.label("→ " + Tx.field(tr, "name"), 16, Palette.HOT, "bold"))
	v.add_child(StudioTheme.wrapped(Tx.field(tr, "belief"), 14, Palette.MAUVE,
		"italic" if Tx.lang == "en" else "serif"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var say := StudioTheme.button(Tx.t("night.speak"), "Hot")
	say.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	say.pressed.connect(_do_speak)
	row.add_child(say)
	var keep := StudioTheme.button(Tx.t("night.hold"))
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep.pressed.connect(func():
		var back := Night.hold()
		reply = Tx.t("night.held", {"n": back})
		reply_hot = false
		relayout())
	row.add_child(keep)
	v.add_child(row)
	v.add_child(StudioTheme.label(Tx.t("night.consent"), 13, Palette.MUTED, "bold"))
	return p


func _do_speak() -> void:
	var o := Night.offer
	var c := Night.client()
	var tr: Dictionary = c["tracks"][int(o["track"])]
	var ev := Night.speak()
	last_event = ev
	reply_hot = bool(ev.get("accepted", false))
	if not ev["accepted"]:
		reply = Tx.field(tr, "refuse") + "\n" + Tx.t("night.refused")
	elif ev["locked"]:
		reply = Tx.field(tr, "locked") + "\n" + Tx.t("night.locked", {"track": Tx.field(tr, "name")})
	elif int(ev["strength"]) >= 2:
		reply = Tx.field(tr, "open_strong")
	elif int(ev["strength"]) > 0:
		reply = Tx.field(tr, "open_weak")
	else:
		reply = Tx.field(tr, "open_weak") + "\n" + Tx.t("night.back",
			{"track": Tx.field(tr, "name"), "n": int(ev["after"])})
	if ev.get("ready", false):
		reply += "\n" + Tx.t("night.all")
	relayout()


func _reply_panel() -> Control:
	var p := PanelContainer.new()
	p.theme_type_variation = "Glass"
	var mm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side, 14)
	p.add_child(mm)
	mm.add_child(StudioTheme.wrapped(reply, 17,
		Palette.HOT_PALE if reply_hot else Palette.SMOKE, "serif"))
	return p


func _text_of(r: Dictionary) -> String:
	if str(r["kind"]) == "slip":
		var s := Fortune.slip(str(r["id"]))
		return Tx.field(s, "verse") + "  —  " + Tx.field(s, "read")
	var card := Fortune.card(str(r["id"]))
	var rev: bool = bool(r.get("reversed", false))
	var nm := Tx.field(card, "name") + ("  " + Tx.t("deck.reversed") if rev else "")
	return nm + "  —  " + Tx.field(card, "rev" if rev else "up")


# ---- the dev bridge: every one of these is a click a player can make -------------------
func dev_state() -> Dictionary:
	return {"reply": reply, "last": last_event}


func dev_cmd(cmd: Dictionary) -> Dictionary:
	match str(cmd.get("op", "")):
		"instrument":
			Night.instrument = str(cmd.get("kind", "slip"))
			relayout()
			return {"ok": true}
		"read":
			var o := Night.read_her(str(cmd.get("kind", Night.instrument)))
			relayout()
			return {"ok": not o.is_empty(), "offer": o}
		"speak":
			if Night.offer.is_empty():
				return {"ok": false, "why": "nothing_drawn"}
			_do_speak()
			return {"ok": true, "event": last_event, "reply": reply}
		"hold":
			var back := Night.hold()
			relayout()
			return {"ok": true, "back": back}
	return {"ok": false, "why": "read_has_no_" + str(cmd.get("op", ""))}


## Three segments: the track, 0..3.
class TrackBar extends Control:
	var value := 0

	func _draw() -> void:
		var w := size.x / 3.0
		for k in range(3):
			var r := Rect2(k * w, 0, w - 5.0, size.y)
			draw_rect(r, Palette.HOT if value > k else Color(Palette.SMOKE, 0.16))
			if value > k:
				draw_rect(r.grow(2.0), Color(Palette.HOT, 0.18))


## One plate slot: the art if it is there, a labelled placeholder frame if it is not.
## Nothing in this game ever shows an unlabelled placeholder — a plate that is not real
## says so on its face (memory: verification-that-lies, where placeholder art passed a
## check by file size).
class PlateView extends Control:
	var slot := ""

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var tex := Night.art(slot)
		if tex:
			draw_texture_rect(tex, r, false)
			if Night.is_placeholder(slot):
				_label(r)
			draw_rect(r, Color(Palette.HOT_DEEP, 0.55), false, 1.0)
		else:
			draw_rect(r, Palette.PLUM_SOFT)
			draw_rect(r, Color(Palette.HOT_DEEP, 0.5), false, 1.0)
			_label(r)

	func _label(r: Rect2) -> void:
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 22, r.size.x, 22),
			Color(0, 0, 0, 0.65))
		draw_string(StudioTheme.font("bold"), Vector2(r.position.x + 6, r.position.y + r.size.y - 7),
			Tx.t("night.placeholder"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 12, Palette.HEAT)

extends Control
## The title screen — ops/adult_forks/TITLE_SCREENS.md, all six items.
##
##  1. key visual     assets/art/key.png, composed right-of-centre, with bg_far and bg_mid
##                    behind it as separate parallax planes (ops/fold_art/fold_gen.py)
##  2. logotype       scripts/vector_mark.gd draws the page's own designed mark — the
##                    Latin FOLD or the Chinese 归一 — as vector strokes. Never a Label.
##  3. motion         three planes drifting at different rates against a slow camera and
##                    the pointer; a hanging lamp that flickers; dust in the light cone;
##                    the logotype drawing itself on over ~2.2 s, grid first, crease last
##  4. styled menu    Primary / Amber / Ghost from scripts/studio_theme.gd, set in the
##                    left third of the composition where the key visual is quiet, not
##                    stacked down the middle
##  5. rating + mark  ALL AGES and blazeCore Play, bottom left, small
##  6. sound          Sfx.logo() as the sting, the ambient bed under it
##
## The lit half of the screen is a CanvasLayer of its own with a CanvasModulate and a
## PointLight2D in it, because that is how the light gets to be real light: everything in
## that canvas is darkened to the room's level and the lamp adds back. The UI is on a
## second CanvasLayer so the text is not dimmed along with the room.

const GAME := "res://scenes/game.tscn"
const ROOM_DIM := 0.78
const DEMO_LEVEL := 5           # 八合 / Octet — two rows of four, folds into one piece
const DEMO_TILT := 0.80
const DEMO_STEP := 1.15         # seconds between folds in the attract loop


var _stage: CanvasLayer
var _planes: Array[TextureRect] = []          # far -> near, with their parallax depths
var _depths := [0.012, 0.035, 0.075]
var _lamp: Node2D
var _mark: VectorMark
var _sub: Label
var _menu: VBoxContainer
var _rules: VBoxContainer
var _t := 0.0
var _aim := Vector2.ZERO
var _lamp_base := 1.25
var _demo: Node2D
var _demo_pieces := {}
var _demo_cs := 62.0
var _demo_clock := 0.0
var _demo_i := 0
const DEMO_DIRS := [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE    # see the note in scenes/game.gd
	_build_stage()
	_build_ui()
	I18n.changed.connect(func(_l): _sync())
	_sync()
	_enter()
	Tel.ev("intro_shown", {"language": I18n.lang})


# --- the lit half -------------------------------------------------------------------------

func _build_stage() -> void:
	_stage = CanvasLayer.new()
	_stage.layer = -1
	add_child(_stage)

	# A Control, not a Node2D: TextureRect is a Control, and a Control whose parent is not
	# a Control has no layout parent — the first build put the planes under a Node2D and
	# every one of them sat at its own texture size in the top-left corner instead of
	# covering the screen. A Control directly under a CanvasLayer lays out against the
	# viewport, which is what the planes need; the lights are Node2Ds under it and are
	# unaffected.
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(root)

	# No CanvasModulate — see the note in scenes/game.gd. The room is dark because the
	# planes are drawn dark and the lamp is additive on top.

	# three planes: the room, the drifting paper, the key visual itself
	for slot in ["bg_far", "bg_mid", "key"]:
		var tr := TextureRect.new()
		tr.texture = Art.plate_or_stand_in(slot, Palette.GROUND if slot != "key" else Palette.PANEL, 40.0)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		# each plane is drawn oversize so it has room to move without showing an edge
		tr.offset_left = -90
		tr.offset_top = -70
		tr.offset_right = 90
		tr.offset_bottom = 70
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if slot == "bg_far":
			tr.modulate = Color(ROOM_DIM, ROOM_DIM, ROOM_DIM, 0.9)
		elif slot == "bg_mid":
			tr.modulate = Color(ROOM_DIM, ROOM_DIM, ROOM_DIM, 0.5 if Art.has("bg_mid") else 0.2)
		else:
			tr.modulate = Color(ROOM_DIM, ROOM_DIM, ROOM_DIM, 1.0 if Art.has("key") else 0.0)
		root.add_child(tr)
		_planes.append(tr)

	# The key visual is a composition, not a wallpaper: it sits right of centre and the
	# left third is pulled down so the logotype and the menu have a ground to sit on.
	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.94), Color(Palette.GROUND_DEEP, 0.55), Color(Palette.GROUND_DEEP, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var scrim_tex := TextureRect.new()
	scrim_tex.texture = gt
	scrim_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim_tex.stretch_mode = TextureRect.STRETCH_SCALE
	scrim_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim_tex)

	# the hanging lamp, over the right third where the board is
	_lamp = PieceView.lamp(1500.0, Palette.GOLD_PALE, _lamp_base)
	root.add_child(_lamp)

	# dust in the cone
	var dust := GPUParticles2D.new()
	dust.amount = 90
	dust.lifetime = 9.0
	dust.preprocess = 6.0
	dust.texture = PieceView.falloff(16, 0.1)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(420, 300, 1)
	pm.gravity = Vector3(0, -3, 0)
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 9.0
	pm.scale_min = 0.12
	pm.scale_max = 0.4
	pm.color = Color(Palette.GOLD_PALE, 0.5)
	dust.process_material = pm
	root.add_child(dust)
	dust.position = Vector2(880, 380)

	# The right of the composition is where the key visual goes. Until that plate lands —
	# and after it lands, in front of it — the strongest thing a puzzle game can show on
	# its title screen is itself, quietly playing: a real board, real pieces, folding on a
	# loop under the lamp. The page's intro does the same with a four-tile demo. It uses
	# the same Fold rules and the same PieceView as the game, so it cannot drift into
	# being a picture of a game that no longer exists.
	_demo = Node2D.new()
	root.add_child(_demo)
	_demo_start()


# --- the UI half ---------------------------------------------------------------------------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)

	var pad := MarginContainer.new()
	# The theme has to be set here too: a Theme propagates down the *Control* tree, and a
	# CanvasLayer is not a Control, so nothing under this layer inherits the one on the
	# scene root. The first build's buttons came out in default Godot grey for exactly
	# this reason.
	pad.theme = StudioTheme.build()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 64)
	pad.add_theme_constant_override("margin_top", 48)
	pad.add_theme_constant_override("margin_right", 48)
	pad.add_theme_constant_override("margin_bottom", 40)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(pad)

	var col = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size = Vector2(520, 0)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)

	var kicker := StudioTheme.mono_label("", 11, Palette.GOLD)
	kicker.name = "Kicker"
	col.add_child(kicker)

	_mark = VectorMark.new()
	_mark.custom_minimum_size = Vector2(420, 132)
	_mark.reveal = 0.0
	col.add_child(_mark)

	_sub = StudioTheme.serif_label("", 16, Palette.MUTED)
	_sub.name = "Tagline"
	_sub.custom_minimum_size = Vector2(0, 26)
	col.add_child(_sub)

	_rules = VBoxContainer.new()
	_rules.add_theme_constant_override("separation", 4)
	_rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_rules)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	col.add_child(spacer)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 10)
	_menu.custom_minimum_size = Vector2(300, 0)
	col.add_child(_menu)

	var play := Button.new()
	play.name = "Play"
	play.theme_type_variation = "Primary"
	play.pressed.connect(_play)
	play.mouse_entered.connect(Sfx.slide)
	_menu.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_menu.add_child(row)

	var levels := Button.new()
	levels.name = "Levels"
	levels.theme_type_variation = "Amber"
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.pressed.connect(func(): _play(true))
	levels.mouse_entered.connect(Sfx.slide)
	row.add_child(levels)

	var lang := Button.new()
	lang.name = "Lang"
	lang.theme_type_variation = "Ghost"
	lang.pressed.connect(func():
		I18n.toggle()
		Sfx.slide()
		Tel.ev("language_selected", {"language": I18n.lang}))
	row.add_child(lang)

	var sound := Button.new()
	sound.name = "Sound"
	sound.theme_type_variation = "Ghost"
	sound.pressed.connect(func():
		Sfx.set_music(not Sfx.music_on)
		Sfx.set_sfx(Sfx.music_on)
		_sync())
	row.add_child(sound)

	# --- 5. the rating and the studio mark, bottom left ----------------------------------
	var foot := HBoxContainer.new()
	foot.name = "Foot"
	foot.theme = StudioTheme.build()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(64, 0)
	foot.offset_top = -46
	foot.offset_bottom = -22
	foot.add_theme_constant_override("separation", 14)
	ui.add_child(foot)

	var rating := Label.new()
	rating.name = "Rating"
	rating.theme_type_variation = "Tag"
	rating.add_theme_color_override("font_color", Palette.FAINT)
	foot.add_child(rating)

	var bar := ColorRect.new()
	bar.color = Color(Palette.GOLD, 0.35)
	bar.custom_minimum_size = Vector2(1, 12)
	foot.add_child(bar)

	var studio := StudioTheme.display_label("blazeCore Play", 13, Color(Palette.MUTED, 0.85))
	foot.add_child(studio)

	# what is still a stand-in rather than a rendered plate — visible in a debug build so
	# that "the art is queued" cannot quietly become "the art is done"
	if OS.is_debug_build() and not Art.missing().is_empty():
		var warn := StudioTheme.mono_label("plates pending: " + ", ".join(Art.missing()), 10, Color(Palette.RED_TEXT, 0.8))
		warn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		warn.position = Vector2(-340, 12)
		ui.add_child(warn)


func _sync() -> void:
	var col := _mark.get_parent()
	(col.get_node("Kicker") as Label).text = I18n.t("kicker")
	_mark.mark = I18n.lang
	_sub.text = I18n.t("tagline")
	for c in _rules.get_children():
		c.queue_free()
	for line in I18n.list("rules"):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var dot := StudioTheme.display_label("◆", 10, Color(Palette.GOLD, 0.75))
		h.add_child(dot)
		h.add_child(StudioTheme.serif_label(str(line), 13, Color(Palette.MUTED, 0.9)))
		_rules.add_child(h)
	var seen := Save.completed_count() > 0
	(_menu.get_node("Play") as Button).text = I18n.t("continue") if seen else I18n.t("play")
	var row := _menu.get_child(1)
	(row.get_node("Levels") as Button).text = I18n.t("levels_btn")
	(row.get_node("Lang") as Button).text = "中文" if I18n.lang == "en" else "EN"
	(row.get_node("Sound") as Button).text = ("♪ " + I18n.t("on")) if Sfx.music_on else ("♪ " + I18n.t("off"))
	var foot := get_node("CanvasLayer2/Foot") if has_node("CanvasLayer2/Foot") else null
	if foot == null:
		for c in get_children():
			if c is CanvasLayer and c.has_node("Foot"):
				foot = c.get_node("Foot")
	if foot:
		(foot.get_node("Rating") as Label).text = I18n.t("rating")


# --- motion ---------------------------------------------------------------------------------

func _enter() -> void:
	Sfx.logo()
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_mark, "reveal", 1.0, 2.2)
	# the menu and the copy arrive after the mark, not with it
	for node in [_sub, _rules, _menu]:
		node.modulate.a = 0.0
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(_sub, "modulate:a", 1.0, 0.7).set_delay(1.3)
	tw2.tween_property(_rules, "modulate:a", 1.0, 0.7).set_delay(1.6)
	tw2.tween_property(_menu, "modulate:a", 1.0, 0.7).set_delay(1.9)


func _process(delta: float) -> void:
	_t += delta
	# the pointer moves the planes a little; the camera breathes on its own always
	var vp := get_viewport_rect().size
	var m := get_viewport().get_mouse_position()
	var want := (m / maxf(1.0, vp.x) - Vector2(0.5, 0.35)) * 2.0
	_aim = _aim.lerp(want, clampf(delta * 2.2, 0.0, 1.0))
	var breathe := Vector2(sin(_t * 0.17), cos(_t * 0.11) * 0.45)
	for i in range(_planes.size()):
		var d: float = _depths[i]
		_planes[i].position = (_aim * 140.0 + breathe * 30.0) * d * 10.0

	_demo_tick(delta)

	# a lamp that is never quite still: two slow waves and a rare dip
	if _lamp:
		var f := 1.0 + 0.045 * sin(_t * 2.3) + 0.03 * sin(_t * 0.7 + 1.1)
		if fmod(_t, 7.3) < 0.09:
			f *= 0.82
		(_lamp.get_node("Light") as PointLight2D).energy = _lamp_base * f
		(_lamp.get_node("Glow") as Sprite2D).modulate.a = 0.26 * f
		_lamp.position = Vector2(get_viewport_rect().size.x * 0.66, get_viewport_rect().size.y * 0.34) + _aim * 18.0


# --- going in ---------------------------------------------------------------------------------

func _play(pick: bool = false) -> void:
	Sfx.slide()
	Save.mark_intro_seen()
	Tel.ev("intro_closed", {"language": I18n.lang})
	Tel.ev("game_started", {"language": I18n.lang, "level": Save.continue_level() + 1})
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	await tw.finished
	var scene: PackedScene = load(GAME)
	var node := scene.instantiate()
	node.set("open_picker", pick)
	node.set("start_level", Save.continue_level())
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventKey and e.pressed and e.keycode == KEY_SPACE):
		_play()


# --- the attract board ----------------------------------------------------------------------

func _demo_start() -> void:
	Fold.load_level(DEMO_LEVEL)
	_demo_i = 0
	_demo_clock = 0.0
	_demo_build()


func _demo_pos(r: int, c: int) -> Vector2:
	var vp := get_viewport_rect().size
	# on the table in the key visual, not floating up the wall behind it
	var origin := Vector2(vp.x * 0.685, vp.y * 0.60)
	var gap := 9.0
	return origin + Vector2(
		(c - (Fold.cols - 1) * 0.5) * (_demo_cs + gap),
		(r - (Fold.rows - 1) * 0.5) * (_demo_cs + gap) * DEMO_TILT)


func _demo_build() -> void:
	for c in _demo.get_children():
		c.queue_free()
	_demo_pieces.clear()
	var vp := get_viewport_rect().size
	_demo_cs = clampf(vp.x * 0.24 / maxf(1, Fold.cols), 30.0, 62.0)
	# the wells the pieces sit in
	for r in range(Fold.rows):
		for c in range(Fold.cols):
			var s := Sprite2D.new()
			var tex := Art.plate_or_stand_in("wall" if Fold.is_wall(r, c) else "table",
				Palette.WALL if Fold.is_wall(r, c) else Palette.CELL)
			s.texture = tex
			s.scale = Vector2(_demo_cs, _demo_cs * DEMO_TILT) / Vector2(tex.get_width(), tex.get_height())
			s.position = _demo_pos(r, c)
			s.modulate = Color((Palette.WALL if Fold.is_wall(r, c) else Palette.CELL) * ROOM_DIM, 0.85)
			_demo.add_child(s)
			# the same hairline the board draws, so the demo grid reads as a grid
			var edge := Line2D.new()
			var hw := _demo_cs * 0.5
			var hh := _demo_cs * DEMO_TILT * 0.5
			edge.points = PackedVector2Array([
				s.position + Vector2(-hw, -hh), s.position + Vector2(hw, -hh),
				s.position + Vector2(hw, hh), s.position + Vector2(-hw, hh),
				s.position + Vector2(-hw, -hh)])
			edge.width = 1.0
			edge.default_color = Color(Palette.GOLD, 0.22)
			_demo.add_child(edge)
	for t in Fold.tiles:
		_demo_add(t)


func _demo_add(t: Dictionary) -> void:
	var holder := PieceView.make(int(t["v"]), _demo_cs, DEMO_TILT, ROOM_DIM, false)
	holder.position = _demo_pos(int(t["r"]), int(t["c"]))
	holder.z_index = 10 + int(t["r"])
	_demo.add_child(holder)
	_demo_pieces[int(t["id"])] = holder


func _demo_tick(delta: float) -> void:
	if _demo == null:
		return
	_demo_clock += delta
	if _demo_clock < DEMO_STEP:
		return
	_demo_clock = 0.0
	if Fold.done or _demo_i > 9:
		_demo_start()
		return
	var d: Vector2i = DEMO_DIRS[_demo_i % DEMO_DIRS.size()]
	_demo_i += 1
	if Fold.move(d.x, d.y) < 0:
		return                       # refused: try the next direction on the next beat
	var alive := {}
	for t in Fold.tiles:
		alive[int(t["id"])] = t
	for id in _demo_pieces.keys():
		if not alive.has(id):
			var gone: Node2D = _demo_pieces[id]
			var tw := create_tween().set_parallel(true)
			tw.tween_property(gone, "modulate:a", 0.0, 0.16)
			tw.tween_property(gone, "scale", Vector2(0.4, 0.4), 0.16)
			tw.chain().tween_callback(gone.queue_free)
			_demo_pieces.erase(id)
	for t in Fold.tiles:
		var id := int(t["id"])
		if not _demo_pieces.has(id):
			_demo_add(t)
			continue
		var node: Node2D = _demo_pieces[id]
		node.z_index = 10 + int(t["r"])
		var tw2 := create_tween()
		tw2.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw2.tween_property(node, "position", _demo_pos(int(t["r"]), int(t["c"])), 0.18)
		if bool(t.get("merged", false)):
			t["merged"] = false
			PieceView.repaint(node, int(t["v"]), _demo_cs, ROOM_DIM, false)
			var pop := create_tween()
			pop.tween_property(node, "scale", Vector2(1.14, 1.14), 0.1).set_delay(0.1)
			pop.tween_property(node, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

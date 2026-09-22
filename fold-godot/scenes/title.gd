extends Control
## The title screen — ops/adult_forks/TITLE_SCREENS.md, all six items.
##
##  1. key visual     assets/art/key.png, composed right-of-centre, with bg_far and bg_mid
##                    behind it as separate parallax planes (ops/fold_art/fold_gen.py)
##  2. logotype       scripts/vector_mark.gd draws the page's own designed mark — the
##                    Latin FOLD or the Chinese 归一 — as vector strokes. Never a Label.
##  3. motion         three planes drifting at different rates against a slow camera and
##                    the pointer; a sun that pulses; sparkles rising through it; the
##                    logotype drawing itself on over ~2.2 s, then breathing and taking a
##                    shine sweep every few seconds
##  4. styled menu    Primary / Amber / Ghost from scripts/studio_theme.gd, set in the
##                    left third of the composition where the key visual is quiet, not
##                    stacked down the middle
##  5. rating + mark  ALL AGES and blazeCore Play, bottom left, small
##  6. sound          Sfx.logo() as the sting, the ambient bed under it
##
## The lit half of the screen is a CanvasLayer of its own with a PointLight2D in it, and
## the UI is on a second CanvasLayer so the text is never dimmed along with the scene.
##
## 2026-09-19 — this screen is the thing Blaze sent back. It was a dim brown study: the
## planes were multiplied by ROOM_DIM 0.78, the left third was covered by a near-opaque
## black scrim so the menu would read, and the only light in it was a hanging lamp. Every
## one of those was a correct decision for a lamplit room and the wrong room.
##
## What changed, in order of how much it mattered:
##
##   * ROOM_DIM is gone. The planes are drawn at full brightness (PLANE_LIT), because the
##     plates behind them are now daylight plates and dimming daylight is just fog.
##   * the scrim flipped. It was black-at-94%-alpha on the left; it is now warm cream, so
##     the left column is a *lit* ground for dark text rather than a hole for pale text.
##   * the lamp became the sun: same PieceView.lamp node, high and warm, pulsing slowly
##     instead of flickering, with no 7-second dip (a flicker is a horror-movie cue).
##   * the dust became sparkles: gold, rising rather than falling, and drawn additively.
##   * the mark breathes and takes a shine sweep every SHINE_EVERY seconds.

const GAME := "res://scenes/game.tscn"
## What the parallax planes are multiplied by. 1.0 — see the note above; this stays a
## named constant rather than being deleted so the next person can see it was decided.
const PLANE_LIT := 1.0
## How often the logotype takes a shine sweep, and how long one takes.
const SHINE_EVERY := 4.2
const SHINE_TIME := 0.85
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
var _lamp_base := 1.45
var _shine_clock := 0.0
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
		tr.texture = Art.plate_or_stand_in(slot, Palette.GROUND_DEEP if slot != "key" else Palette.TABLE, 40.0)
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
			tr.modulate = Color(PLANE_LIT, PLANE_LIT, PLANE_LIT, 1.0)
		elif slot == "bg_mid":
			tr.modulate = Color(PLANE_LIT, PLANE_LIT, PLANE_LIT, 0.75 if Art.has("bg_mid") else 0.25)
		else:
			tr.modulate = Color(PLANE_LIT, PLANE_LIT, PLANE_LIT, 1.0 if Art.has("key") else 0.0)
		root.add_child(tr)
		_planes.append(tr)

	# The key visual is a composition, not a wallpaper: it sits right of centre and the
	# left third is washed *up* — a warm cream veil — so the logotype and the menu have a
	# lit ground to sit on. This gradient used to run the other way, to near-black, which
	# is how a bright key visual still ended up looking like a study.
	var grad := Gradient.new()
	# 2026-09-20, the saturation pass. The captured frame measured 0.90 brightness and
	# **0.20 saturation** against the shelf floor of 0.45/0.30 — the "bright and washed"
	# failure named in ops/adult_forks/UI_DIRECTION.md, which is the same kind of miss as
	# a frame that is too dark, arrived at from the other side. Half the screen was a flat
	# near-opaque field of GROUND (#FFF1D6, a cream two points off white), so half the
	# pixels contributed almost no chroma at all and dragged the mean down on their own.
	#
	# Two changes, both aimed at that number rather than at the mood:
	#
	#   the scrim is tinted, not bleached. GROUND_DEEP (#FFE0A8) is the warm end of the
	#   same daylight gradient and carries real chroma while staying a lit ground for dark
	#   text — the copy column loses none of its contrast (MUTED and TEXT are both
	#   measured against GROUND, and GROUND_DEEP is the darker of the pair, so both ratios
	#   go up rather than down).
	#
	#   the falloff is tighter. 0.34 instead of 0.45 for the midpoint, so the opaque zone
	#   covers the copy column and stops, and the key visual keeps a third more of the
	#   frame. The picture is the most saturated thing on the screen; giving it area is
	#   the cheapest chroma there is.
	grad.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	grad.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.96), Color(Palette.GROUND_DEEP, 0.55), Color(Palette.GROUND_DEEP, 0.0)])
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

	# the sun, high over the right third where the board is
	_lamp = PieceView.lamp(1700.0, Palette.LAMP, _lamp_base)
	root.add_child(_lamp)

	# sparkles rising through the light
	var dust := GPUParticles2D.new()
	dust.amount = 110
	dust.lifetime = 7.0
	dust.preprocess = 6.0
	dust.texture = PieceView.falloff(16, 0.1)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(520, 320, 1)
	pm.gravity = Vector3(0, -14, 0)
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 22.0
	pm.scale_min = 0.18
	pm.scale_max = 0.7
	pm.color = Color(Palette.GOLD, 0.85)
	dust.process_material = pm
	# additive, so a sparkle on a bright plate still reads as light and not as a grey dot
	var dust_mat := CanvasItemMaterial.new()
	dust_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	dust.material = dust_mat
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

	var kicker := StudioTheme.mono_label("", 12, Palette.ACCENT_DEEP)
	kicker.name = "Kicker"
	col.add_child(kicker)

	_mark = VectorMark.new()
	# bigger than the old lockup: the mark is the key visual's partner, not a caption
	_mark.custom_minimum_size = Vector2(470, 150)
	_mark.reveal = 0.0
	_mark.pivot_offset = Vector2(235, 75)
	col.add_child(_mark)

	_sub = StudioTheme.serif_label("", 17, Palette.TEXT, true)
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

	var play := StudioTheme.fold_button("Play", Palette.ACCENT, Palette.PAPER, 22)
	play.custom_minimum_size = Vector2(300, 60)
	play.pressed.connect(_play)
	play.mouse_entered.connect(Sfx.slide)
	_menu.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_menu.add_child(row)

	var levels := StudioTheme.fold_button("Levels", Palette.GOLD, Palette.INK, 18)
	levels.custom_minimum_size = Vector2(160, 52)
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
	rating.add_theme_color_override("font_color", Palette.MUTED)
	foot.add_child(rating)

	var bar := ColorRect.new()
	bar.color = Color(Palette.ACCENT, 0.6)
	bar.custom_minimum_size = Vector2(1, 12)
	foot.add_child(bar)

	var studio := StudioTheme.display_label("blazeCore Play", 14, Palette.MUTED)
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
		# A drawn dot, not a glyph. "◆" was set in the display face and came out as a
		# missing-glyph box in the captured frame once the face changed to Lilita One,
		# which has no such character and whose CJK fallback does not either. A bullet
		# is a shape; asking a font for it is what broke.
		var dot := ColorRect.new()
		dot.color = Palette.ACCENT
		dot.custom_minimum_size = Vector2(9, 9)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
		h.add_child(StudioTheme.serif_label(str(line), 14, Palette.TEXT))
		_rules.add_child(h)
	var seen := Save.completed_count() > 0
	(_menu.get_node("Play") as Button).text = I18n.t("continue") if seen else I18n.t("play")
	var row := _menu.get_child(1)
	(row.get_node("Levels") as Button).text = I18n.t("levels_btn")
	(row.get_node("Lang") as Button).text = I18n.next_lang_label()
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
	# The greeting rides a timer rather than the sting: spoken over the logo tone they
	# fight, and the first thing a player hears should be the game, not a voice.
	get_tree().create_timer(1.1).timeout.connect(func() -> void: Sfx.bark("greet"))
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

	# The sun: two slow waves and no dip. The old lamp had a rare 0.82x flicker, which is
	# a good cue in a thriller and reads as a fault in a children's game.
	if _lamp:
		var f := 1.0 + 0.05 * sin(_t * 1.1) + 0.03 * sin(_t * 0.43 + 1.1)
		(_lamp.get_node("Light") as PointLight2D).energy = _lamp_base * f
		(_lamp.get_node("Glow") as Sprite2D).modulate.a = 0.34 * f
		_lamp.position = Vector2(get_viewport_rect().size.x * 0.70, get_viewport_rect().size.y * 0.22) + _aim * 18.0

	# The mark, once it has finished drawing on: a slow breath, and a shine sweeping
	# across it every SHINE_EVERY seconds. Both are idle motion — the screen is never
	# completely still, which is most of what separates a casual title from a poster.
	if _mark and _mark.reveal >= 1.0:
		var s := 1.0 + 0.012 * sin(_t * 1.35)
		_mark.scale = Vector2(s, s)
		_mark.rotation = 0.006 * sin(_t * 0.9 + 0.6)
		_shine_clock += delta
		if _shine_clock >= SHINE_EVERY:
			_shine_clock = 0.0
			var sw := create_tween()
			sw.tween_method(func(v): _mark.shine = v, 0.0, 1.0, SHINE_TIME)
			sw.tween_callback(func(): _mark.shine = -1.0)


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
	# 2026-09-20, the saturation pass. This was `vp.x * 0.24` capped at 62, which on a
	# 1280-wide frame clamped a four-column board to 62 px cells — a small dark postage
	# stamp floating on the right of the picture.
	#
	# It is worth making big for two separate reasons that happen to agree. The composition
	# one: this board is the only place the title screen shows the player what the game
	# actually is, and it was reading as a decoration rather than as the subject. The
	# measured one: the captured frame failed the shelf on SATURATION (0.20 against 0.30),
	# and the three rendered plates behind it are all washed too (0.24-0.29 measured), so
	# the chroma cannot come from the picture. It has to come from the board — the deep
	# teal tray and the candy tile ramp are by a wide margin the most saturated pixels on
	# the screen, and the cheapest way to raise a mean is to give those pixels area.
	#
	# 0.34 of the width at a 92 px ceiling. Still clamped, because the attract board must
	# never grow into the copy column on a wide window, and still floored at 30 for the
	# phone read.
	_demo_cs = clampf(vp.x * 0.34 / maxf(1, Fold.cols), 30.0, 92.0)
	# the wells the pieces sit in
	for r in range(Fold.rows):
		for c in range(Fold.cols):
			var s := Sprite2D.new()
			var wall := Fold.is_wall(r, c)
			var tex := Art.surface_stand_in("wall" if wall else "table")
			s.texture = tex
			s.scale = Vector2(_demo_cs, _demo_cs * DEMO_TILT) / Vector2(tex.get_width(), tex.get_height())
			s.position = _demo_pos(r, c)
			# surface_stand_in averages white, so this modulate is the colour it says it
			# is — plate_or_stand_in would have multiplied it darker (see art.gd's note)
			#
			# 2026-09-20: this was Palette.TABLE — the *tray* colour, the darkest value the
			# board owns — for every empty cell. Palette.WELL exists precisely for this and
			# its own note says why: "a well is now a lit recess: lighter than the tray,
			# desaturated against the candy... the board stopped looking perforated." That
			# fix was made for the playfield and never reached the title screen, so the
			# attract board went on drawing its empty cells as holes. It shows worst late
			# in the loop, when most tiles have merged away and the composition is eight
			# dark squares and one candy one punched into the key visual.
			s.modulate = Color(Palette.WALL_FACE if wall else Palette.WELL, 1.0)
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
			edge.default_color = Color(Palette.TABLE_RAIL, 0.55)
			_demo.add_child(edge)
	for t in Fold.tiles:
		_demo_add(t)


func _demo_add(t: Dictionary) -> void:
	var holder := PieceView.make(int(t["v"]), _demo_cs, DEMO_TILT, PLANE_LIT, false)
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
			PieceView.repaint(node, int(t["v"]), _demo_cs, DEMO_TILT, PLANE_LIT, false)
			var pop := create_tween()
			pop.tween_property(node, "scale", Vector2(1.14, 1.14), 0.1).set_delay(0.1)
			pop.tween_property(node, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

extends Control
## The title screen — ops/adult_forks/TITLE_SCREENS.md, all six items. FOLD: After Dark:
## the parent's screen with the lights down (see scripts/palette.gd). Play goes to the tier
## map, because the loop here starts at a locked scene card, not at level 1.
##
##  1. key visual     assets/art/key.png, composed right-of-centre, with bg_far and bg_mid
##                    behind it as separate parallax planes (ops/fold_art/fold_gen.py)
##  2. logotype       scripts/vector_mark.gd draws the page's own designed mark — the
##                    Latin FOLD or the Chinese 归一 — as vector strokes. Never a Label.
##  3. motion         three planes drifting at different rates against a slow camera and
##                    the pointer; a low pink lamp that breathes; motes falling through
##                    it; the
##                    logotype drawing itself on over ~2.2 s, then breathing and taking a
##                    shine sweep every few seconds
##  4. styled menu    Primary / Amber / Ghost from scripts/studio_theme.gd, set in the
##                    left third of the composition where the key visual is quiet, not
##                    stacked down the middle
##  5. rating + mark  18+ · ADULTS ONLY and Flat 404, bottom left, small. Flat 404 is the
##                    ADULT label and is correct here; ops/adult_forks/TITLE_SCREENS.md
##                    reserves "blazeCore Play alone, no 18+ badge" for the mainstream
##                    parent, which is a different tree (play/fold-godot)
##  6. sound          Sfx.logo() as the sting, the ambient bed under it
##
## The lit half of the screen is a CanvasLayer of its own with a PointLight2D in it, and
## the UI is on a second CanvasLayer so the text is never dimmed along with the scene.
##
## 2026-09-19 — the PARENT's screen was the thing Blaze sent back. It was a dim brown
## study: the
## planes were multiplied by ROOM_DIM 0.78, the left third was covered by a near-opaque
## black scrim so the menu would read, and the only light in it was a hanging lamp. Every
## one of those was a correct decision for a lamplit room and the wrong room.
##
## What changed, in order of how much it mattered:
##
##   * ROOM_DIM is gone. The planes are drawn at full brightness (PLANE_LIT), because
##     dimming a plate that was rendered dark is just fog — the light belongs in the
##     render, not in a multiply.
##   * the mark breathes and takes a shine sweep every SHINE_EVERY seconds.
##
## 2026-09-20 — and this fork then inherited that screen wholesale, which is how an adult
## title came to be lit by a SUN. The palette, the scrim and the mark had all been carried
## over to night; three things had not, and each of them was a cue written on purpose for
## a children's game:
##
##   * the sun became a lamp again — low, pink (Palette.LAMP is already #FF9AC4), and
##     dimmer. It sat at 22% of the screen height at energy 1.15, which is where you put
##     a sun; a room at 1 a.m. has a light source in it, not above it.
##   * the sparkles became motes. Gold sparks RISING is the single most legible "this game
##     is for children" cue on the screen, and it was drawn additively over an adult key
##     visual. They now fall, slowly, in the lamp's own pink and gold, the way dust does
##     in a beam.
##   * the comments. Four of them still explained decisions in terms of "a children's
##     game" and "daylight plates", and one line of the header still said ALL AGES while
##     the code rendered 18+ · ADULTS ONLY. A comment that contradicts its own code is
##     worse than no comment: it is the next person's false premise.

const GAME := "res://scenes/map.tscn"      # the tier map, not the board: the loop starts at a locked card
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
var _lamp_base := 0.96        # a lamp in a room, not a sun over one (was 1.15)
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
	# Her voice, once, after the logotype has drawn itself on -- ops/STANDARD.md item 5.
	# Under the sting rather than over it: Sfx.logo() fires in _enter(), and two cues in
	# the same instant is one cue nobody hears.
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(self):
		Sfx.bark("greet")


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

	# Three planes: the room, the drifting paper, the key visual itself — and a finding
	# worth writing down rather than quietly restructuring at 03:00.
	#
	# **The parallax is currently defeated by the key plane.** `key` is drawn last, at
	# alpha 1.0, with STRETCH_KEEP_ASPECT_COVERED over a rect oversized by 90x70 — so it
	# is opaque and it covers the whole viewport, and bg_far and bg_mid are behind it
	# where nothing can see them. The depth the pointer-parallax produces is real in the
	# code and invisible on the screen; what reads as depth in a capture is the bokeh
	# inside the key plate itself.
	#
	# Both plates are still worth having and both are now After Dark's own: bg_far is
	# used by the PLAYFIELD (scenes/game.gd:127), where it is not covered, and bg_mid
	# completes the slot set. Making the parallax actually visible means either a key
	# plate with real transparency or drawing `key` inset rather than full-bleed — and
	# full-bleed is what ops/adult_forks/TITLE_SCREENS.md requires of a key visual, so
	# that is a composition decision for Blaze rather than a bug to fix in passing.
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

	# The key visual is a kaleidoscope (Blaze's own render, 2026-09-21), so it turns.
	#
	# Rotation rather than the pan this screen used to do: panning a plate shows its edge
	# the moment it moves further than the oversize margin, which is exactly the black
	# border Blaze saw. A rotation about the centre never reaches an edge at all, provided
	# the plate is scaled past the frame's diagonal -- for 16:9 that is 1.16, so 1.2 with
	# a little to spare. The cost is one Tween and no per-frame work.
	_spin_key()

	# The key visual is a composition, not a wallpaper: it sits right of centre and the
	# left third is veiled so the logotype and the menu have a ground to sit on.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	# After Dark: the veil is plum-black, not the parent's cream. The key visual stays full bleed and
	# visible through the left column (TITLE_SCREENS.md, "the surface must not eat the
	# picture") — 0.90 at the edge, gone by the right third.
		# 0.82 / 0.46, not 0.90 / 0.55. Measured: the composed frame sat at 0.32 brightness
	# against a 0.45 shelf floor, and roughly half of what it was spending on darkness was
	# this veil over a picture that is already dark in its top-left. Every line of copy
	# was re-read in the capture at the lower value and none of them lost contrast — the
	# text is white with a shadow over a plum plate, and the veil was never what was
	# carrying it.
	grad.colors = PackedColorArray([Color(Palette.GROUND, 0.82), Color(Palette.GROUND, 0.46), Color(Palette.GROUND, 0.0)])
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

	# The lamp, low over the right third where the board is. Not high: a light source at
	# 22% of the screen height reads as the sun, which is what this was before the fork
	# was looked at.
	_lamp = PieceView.lamp(1400.0, Palette.LAMP, _lamp_base)
	root.add_child(_lamp)

	# Motes falling through the lamp. See the header: rising gold sparks are a children's
	# game cue, and they were being drawn additively over an adult key visual.
	var dust := GPUParticles2D.new()
	dust.amount = 74
	dust.lifetime = 11.0
	dust.preprocess = 6.0
	dust.texture = PieceView.falloff(16, 0.1)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(520, 320, 1)
	pm.gravity = Vector3(0, 9, 0)           # falling, like dust in a beam — not rising
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 11.0
	pm.scale_min = 0.14
	pm.scale_max = 0.5
	pm.color = Color(Palette.LAMP, 0.55)    # the lamp's own pink, at half the old alpha
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

	var kicker := StudioTheme.mono_label("", 12, Palette.GOLD)
	kicker.name = "Kicker"
	col.add_child(kicker)

	_mark = VectorMark.new()
	# The same designed mark as FOLD's — the fork keeps the parent's skeleton — drawn as
	# neon: magenta body, gold plane, pink gloss, a plum shadow with body. Never a Label.
	_mark.ink = Palette.ACCENT
	_mark.accent = Palette.GOLD
	_mark.gloss = Color("FFD6E8")
	_mark.shadow = Color(Palette.GROUND_DEEP, 0.95)
	_mark.custom_minimum_size = Vector2(470, 150)
	_mark.reveal = 0.0
	_mark.unfold = 0.0               # the sheet starts folded shut; see `_enter`
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

	var play := _fold_button("Play", Palette.ACCENT, 26, true)
	play.pressed.connect(_play)
	_menu.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_menu.add_child(row)

	var levels := _fold_button("Levels", Palette.GOLD, 20, false)
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.pressed.connect(func(): _play(true))
	row.add_child(levels)

	var lang := _fold_button("Lang", Palette.MUTED, 16, false)
	lang.custom_minimum_size = Vector2(88, 46)
	lang.pressed.connect(func():
		I18n.toggle()
		Sfx.slide()
		Tel.ev("language_selected", {"language": I18n.lang}))
	row.add_child(lang)

	var sound := _fold_button("Sound", Palette.MUTED, 16, false)
	sound.custom_minimum_size = Vector2(96, 46)
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

	var studio := StudioTheme.display_label("Flat 404", 14, Palette.MUTED)
	foot.add_child(studio)

	# The "key visual: Room 704 plate, stand-in" label that used to sit here is gone, and
	# so is the stand-in: assets/art/key.png is now After Dark's OWN render, out of
	# ops/fold_art/fold_gen.py's DARK_PLATES (--fork). The label was honest and it was
	# load-bearing — Art.missing() cannot see a slot that is present but belongs to
	# another game, so a foreign plate is invisible to every check in this project. If a
	# borrowed plate is ever dropped in here again, put the label back with it.

	# what is still a stand-in rather than a rendered plate — visible in a debug build so
	# that "the art is queued" cannot quietly become "the art is done"
	if OS.is_debug_build() and not Art.missing().is_empty():
		var warn := StudioTheme.mono_label("plates pending: " + ", ".join(Art.missing()), 10, Color(Palette.RED_TEXT, 0.8))
		warn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		warn.position = Vector2(-340, 12)
		ui.add_child(warn)


func _sync() -> void:
	var col := _mark.get_parent()
	(col.get_node("Kicker") as Label).text = I18n.t("rating_18") + "  ·  " + I18n.t("kicker")
	_mark.mark = VectorMark.NAME     # a name is not translated; see vector_mark.gd
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
		h.add_child(StudioTheme.serif_label(str(line), 16, Palette.TEXT))
		_rules.add_child(h)
	var seen := Save.completed_count() > 0
	# `label`, not `text`: a ShapedButton draws its own word so the shape can decide where
	# the word sits, and it clears Button.text in _ready. Setting .text here would have set
	# an invisible string on four buttons and left them blank — the same silent failure
	# Ghost Channel's first three dials shipped with.
	_set_label(_menu.get_node("Play"), I18n.t("continue") if seen else I18n.t("play"))
	var row := _menu.get_child(1)
	_set_label(row.get_node("Levels"), I18n.t("levels_btn"))
	_set_label(row.get_node("Lang"), I18n.next_lang_label())
	_set_label(row.get_node("Sound"), ("♪ " + I18n.t("on")) if Sfx.music_on else ("♪ " + I18n.t("off")))
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
	# The mark arrives in two beats, and the order matters. First the strokes draw on
	# while the sheet is still PLEATED (`unfold = 0`), so what you watch being written is
	# a concertina of paper standing on the baseline — unreadable as a word, and meant to
	# be. Then the sheet opens left to right and the word is there.
	#
	# That is ops/STANDARD.md's ask for this title, literally: "letters folded from a
	# single sheet, creases catching the light, unfolding as the title settles". Doing
	# both beats at once was tried and it is mush: a stroke drawing on across a panel that
	# is itself moving reads as a glitch rather than as paper.
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_mark, "reveal", 1.0, 1.6)
	tw.tween_property(_mark, "unfold", 1.0, 1.25).set_trans(Tween.TRANS_QUINT)
	# the menu and the copy arrive after the mark, not with it
	for node in [_sub, _rules, _menu]:
		node.modulate.a = 0.0
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(_sub, "modulate:a", 1.0, 0.7).set_delay(2.0)
	tw2.tween_property(_rules, "modulate:a", 1.0, 0.7).set_delay(2.3)
	tw2.tween_property(_menu, "modulate:a", 1.0, 0.7).set_delay(2.6)


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

	# Two slow waves and no dip. A filament lamp warms and cools; it does not flicker on a
	# timer, and a periodic dip reads as a fault rather than as a room. (The parent's note
	# here argued the opposite way round — "a flicker is a good cue in a thriller and reads
	# as a fault in a children's game" — and concluded the same thing, which is the tell
	# that the dip was never what made the difference.)
	if _lamp:
		var f := 1.0 + 0.05 * sin(_t * 1.1) + 0.03 * sin(_t * 0.43 + 1.1)
		(_lamp.get_node("Light") as PointLight2D).energy = _lamp_base * f
		(_lamp.get_node("Glow") as Sprite2D).modulate.a = 0.34 * f
		_lamp.position = Vector2(get_viewport_rect().size.x * 0.70, get_viewport_rect().size.y * 0.36) + _aim * 18.0

	# The mark, once it has finished drawing on: a slow breath, and a shine sweeping
	# across it every SHINE_EVERY seconds. Both are idle motion — the screen is never
	# completely still, which is most of what separates a casual title from a poster.
	# `unfold` as well as `reveal`: the shine sweep is a highlight travelling across FLAT
	# paper, and running it over a half-open concertina puts a white band across panels
	# that are meant to be edge-on to the light.
	if _mark and _mark.reveal >= 1.0 and _mark.unfold >= 1.0:
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


## The menu buttons are folded paper, drawn — shared/godot/shaped_button.gd, Shape.FOLD.
##
## What was here before was a pair of nine-patch PNG tabs (ops/fold_dark_title.py), and
## the argument for them was sound: a plate is art, a StyleBoxFlat is not. The captured
## title frame settled it anyway. Stretched across a 520-wide menu column, the plate's
## folded corner shrank to a 20 px notch in the top-right and everything between the
## nine-patch margins was flat field, so PLAY read as a magenta rectangle and TIER MAP as
## a gold one — studio rule 4, with a render to pay for it.
##
## Drawn, the corner is a fixed fraction of the button at any width, it OPENS on hover
## (the whole game is folding, so the button folds), and the label stays a real Label-ish
## draw_string so zh and ja keep working. assets/art/btn_play.png and btn_second.png are
## left on disk and still listed in Art.SLOTS: they are the ad-track fallback nothing else
## claims, and deleting a plate to prove a point is how a slot silently becomes missing.
func _fold_button(name: String, tint: Color, size: int, lead: bool) -> ShapedButton:
	var b := ShapedButton.new()
	b.name = name
	b.shape = ShapedButton.Shape.FOLD
	b.tint = tint
	# The ink is the paper's own dark, not the theme's off-white: FOLD is a FILLED shape,
	# and pale type on a hot magenta fill is the one combination this palette cannot carry.
	b.ink = Palette.INK
	b.add_theme_font_override("font", StudioTheme.font("display"))
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(300 if lead else 180, 58 if lead else 52)
	b.mouse_entered.connect(Sfx.slide)
	return b


## Set the word on a ShapedButton and make it redraw. Plain Buttons would take `text`;
## these draw their own, so the property is `label`.
func _set_label(node: Node, word: String) -> void:
	if node is ShapedButton:
		(node as ShapedButton).label = word
		(node as ShapedButton).queue_redraw()
	elif node is Button:
		(node as Button).text = word


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
	node.set("focus_tier", Tier.current())
	node.set("from_title", not pick)
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
			var wall := Fold.is_wall(r, c)
			var tex := Art.surface_stand_in("wall" if wall else "table")
			s.texture = tex
			s.scale = Vector2(_demo_cs, _demo_cs * DEMO_TILT) / Vector2(tex.get_width(), tex.get_height())
			s.position = _demo_pos(r, c)
			# surface_stand_in averages white, so this modulate is the colour it says it
			# is — plate_or_stand_in would have multiplied it darker (see art.gd's note)
			s.modulate = Color(Palette.WALL_FACE if wall else Palette.TABLE, 1.0)
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
			PieceView.repaint(node, int(t["v"]), _demo_cs, PLANE_LIT, false)
			var pop := create_tween()
			pop.tween_property(node, "scale", Vector2(1.14, 1.14), 0.1).set_delay(0.1)
			pop.tween_property(node, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Turn the kaleidoscope, slowly, forever.
##
## 44 seconds for a full sweep either way: fast enough that the screen is alive while the
## menu is read, slow enough that it is never the thing being looked at. The scale is set
## once and not animated -- a breathing zoom on top of the rotation reads as drift, and
## the plate is a pattern, so drift looks like a rendering fault rather than a choice.
func _spin_key() -> void:
	if _planes.is_empty():
		return
	var key: TextureRect = _planes[_planes.size() - 1]
	if not Art.has("key"):
		return
	key.pivot_offset = key.size / 2.0
	# 1.16 is the diagonal ratio of a 16:9 rect; past it no rotation can expose a corner.
	key.scale = Vector2(1.2, 1.2)
	key.rotation_degrees = -1.6
	var tw := create_tween().set_loops()
	tw.tween_property(key, "rotation_degrees", 1.6, 44.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(key, "rotation_degrees", -1.6, 44.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

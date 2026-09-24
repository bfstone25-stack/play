extends Control
## The board — FOLD: After Dark.
##
## The parent's board (play/fold-godot/scenes/game.gd) with the juice tuned for speed and
## the win rewired: inside a tier a solved level auto-advances after a beat and feeds the
## streak; the last level of a tier stops on a trophy card whose one button unlocks the
## scene — through the page gate and the server-ticket path — and then returns to the map.
## "Click click click", not contemplation.
##
## Every rule here comes from the Fold autoload and nothing else — this file decides what
## a fold looks like, never what it does. If a tile ends up somewhere, Fold put it there
## and tests/conformance.json says the JavaScript puts it in the same place.
##
## 2.5D, per the brief. Three things make it, and none of them is a 3D scene:
##
##  - **A tilted plane.** The board is drawn as a shallow trapezoid: rows further back are
##    narrower and closer together (`_row_k`), so the grid recedes. A square grid drawn
##    square is the flat web build; this is the same grid on a table.
##  - **Real light.** A PointLight2D hangs over the tray, so the near edge of a piece is
##    lit and the far edge is not, and a piece that has climbed the ramp
##    (Palette.tile_glow) carries its own small light and throws it on its neighbours.
##  - **Lit pieces, not rectangles.** A piece is the `piece` plate — folded paper with a
##    crease in it — tinted to its value, with a drop shadow under it and a rim along the
##    top edge. Walls are the `wall` plate. Neither is a rounded rect drawn in code.
##
## 2026-09-19 — the bright repaint, and the juice. Two things changed here:
##
##   * the room came up. `ROOM_DIM` is gone: the page behind the tray is daylight, the
##     lamp is a soft sun rather than a 2.1-energy spot, and the vignette went from a
##     0.88 dark ring to a light warm one. The tray itself is deep teal, which is what
##     keeps the candy pieces reading against it (the measured targets live in
##     palette.gd) — a bright game with a dark board, like the reference build.
##   * every interaction now answers. A slide squashes the pieces along the axis of the
##     fold and springs back; a merge pops, sparkles and flashes its cell; a solved level
##     throws a burst across the whole tray. `_sparkle()` is the one helper behind all of
##     it. This is the difference Blaze named between a casual title and a static board.
##
## Kept from the web build, because they are the product and not the presentation: the ad
## gate at level 51 (Gate autoload, shared/godot/gate.gd), the casual promo board at the
## end of a run, the telemetry event names, en + zh.

const CELL_GAP := 10.0
const TILT := 0.80          # how flat the board lies: 1.0 is straight down, 0 is edge-on
const RECEDE := 0.14        # how much narrower the back row is than the front
# No ROOM_DIM any more — see the note above. The page is lit; the tray is the dark thing.

var open_picker := false
var start_level := 0

var _stage: CanvasLayer
var _table: TextureRect
var _table_edge: Sprite2D
var _rail: Line2D
var _vignette: TextureRect
var _board: Node2D
var _lamp: Node2D
var _cells: Node2D
var _pieces: Node2D
var _crease: Line2D
var _sprites := {}          # tile id -> Node2D

var _hud: CanvasLayer
var _goal: Label
## The diagram step the tallest piece has just reached, and the value it was last said
## at. See `_announce_step`.
var _step: Label
var _high := 0
var _moves: Label
var _lvname: Label
var _stars_row: HBoxContainer
var _undo_btn: Button
var _reset_btn: Button
var _hint: Label
var _win: Control
var _picker: Control

var _cs := 84.0
var _origin := Vector2.ZERO
var _t := 0.0
var _drag_from := Vector2.ZERO
var _dragging := false
var _board_offered := false
var _streak_lbl: Label
## Bark bookkeeping: seconds since the last fold, and whether the tease line has been
## spent on this level. See _on_moved and _process.
const IDLE_AFTER := 24.0
var _idle_clock := 0.0
var _said_near := false
var _tier_lbl: Label
var _viewer: Control
var _ticket_for := ""
var _swipe_px := 26.0

# --- juice (2026-09-23): combo, score, results, start card, Coco --------------------------
var _score_lbl: Label
var _stars_total: Label
var _fx: CanvasLayer
var _combo_lbl: Label
var _start_card: PanelContainer
var _results: Control
var _results_open := false
var _results_skip := false
var _coco_box: Control
var _coco_pic: TextureRect
var _coco_bubble: PanelContainer
var _coco_text: Label
var _coco_hide_at := 0.0
var _near_fail_said := false
var _held := false


func _ready() -> void:
	theme = StudioTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# A Control's default mouse_filter is STOP, so this node swallowed every click and
	# drag over empty space before _unhandled_input ever saw it: the keyboard worked and
	# dragging the board did nothing at all, which is the *only* way to play on a phone.
	# The buttons are separate Controls further down and keep their own STOP.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stage()
	_build_hud()
	_build_overlays()
	_build_fx()
	Coco.said.connect(_on_coco_said)
	Fold.moved.connect(_on_moved)
	Fold.refused.connect(_on_refused)
	Fold.solved.connect(_on_solved)
	I18n.changed.connect(func(_l): _sync(); _relayout())
	get_viewport().size_changed.connect(_relayout)
	_open(start_level)
	if open_picker:
		_show_picker(true)


# --- the lit board ---------------------------------------------------------------------------

func _build_stage() -> void:
	_stage = CanvasLayer.new()
	_stage.layer = -1
	add_child(_stage)
	# a Control, so the full-rect planes actually lay out against the viewport (see the
	# same note in scenes/title.gd)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(root)

	# No CanvasModulate. The first build darkened the room with one, and it dimmed the HUD
	# and the menu along with the table — the gold Primary button came out olive — because
	# a CanvasModulate is not confined to the CanvasLayer it sits in the way the docs read
	# as implying. Nothing global tints this scene; the lamp is an ADDITIVE Light2D.

	# the room, well behind the table
	var far := TextureRect.new()
	far.texture = Art.plate_or_stand_in("bg_far", Palette.GROUND_DEEP, 50.0)
	far.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	far.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	far.set_anchors_preset(Control.PRESET_FULL_RECT)
	# full daylight: the page behind the tray is the brightest thing on the screen, and
	# the tray reads because it is deep teal, not because everything else is dark
	far.modulate = Color(1.0, 1.0, 1.0, 1.0)
	far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(far)

	# A cream wash over the room, and it is not decoration — it is the playfield rule.
	# The bg_far plate that landed is a dense, high-contrast candy sky, and in the first
	# captured frame of the bright build it was the loudest thing on the screen while the
	# tray sat in the middle of it looking like a postage stamp. Atmosphere belongs to the
	# title screen; here the room is a ground and has to behave like one, so it is washed
	# back to about a third of its contrast and the board is what the eye lands on.
	var wash := ColorRect.new()
	wash.color = Color(Palette.GROUND, 0.70)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)

	# The shadow the tray casts into the room. It is added BEFORE the tray, because it has
	# to be under it: in the first build this node came after and drew on top, which is
	# also why its alpha had been turned down to zero — the only way to stop it darkening
	# the very surface it was meant to seat.
	_table_edge = Sprite2D.new()
	_table_edge.texture = PieceView.falloff(256, 0.2)
	# a warm shadow under the tray, not a black one (same note as StudioTheme.drop)
	_table_edge.modulate = Color(Palette.WALL_EDGE, 0.40)
	root.add_child(_table_edge)

	# The table the board sits on — the tray. TITLE_SCREENS.md's playfield rule asks for a
	# surface of the board's own, in the game's idiom rather than a grey panel, and this is
	# it: a deep teal tray with a bright mint lip around it. `surface_stand_in` rather than
	# `plate_or_stand_in` so that Palette.TABLE is the colour that actually reaches the
	# screen (see the note in art.gd); when ops/fold_art finally lands a `table` plate,
	# both return the plate and nothing here changes.
	_table = TextureRect.new()
	_table.texture = Art.surface_stand_in("table", 0.16)
	_table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_table.stretch_mode = TextureRect.STRETCH_SCALE
	_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_table)

	# the lit lip of the tray: where the board stops and the room starts
	_rail = Line2D.new()
	_rail.width = 5.0
	_rail.closed = true
	_rail.default_color = Palette.TABLE_RAIL
	root.add_child(_rail)

	_board = Node2D.new()
	root.add_child(_board)
	_cells = Node2D.new()
	_board.add_child(_cells)
	_pieces = Node2D.new()
	_board.add_child(_pieces)

	# the fold line: a bright crease that flashes across the board on the axis of the move
	_crease = Line2D.new()
	_crease.width = 5.0
	_crease.default_color = Color(Palette.CREAM, 0.0)
	_crease.z_index = 40
	_board.add_child(_crease)

	# soft, not a spotlight: on a lit page a 2.1-energy lamp blows the near tiles out
	_lamp = PieceView.lamp(1400.0, Palette.LAMP, 0.85)
	root.add_child(_lamp)

	# the page warms at the edges: a light ring over everything, under the HUD. It used to
	# be a dark ring at 0.88 alpha, which is a cinema framing and read as grime here.
	_vignette = TextureRect.new()
	var vt := GradientTexture2D.new()
	var vg := Gradient.new()
	# The stops start later and stay clear for longer than they did: the old ramp put
	# a 10% wash of GROUND_DEEP over the middle of the screen, which is exactly where
	# the board is. A vignette frames the playfield; it does not tint it.
	vg.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	vg.colors = PackedColorArray([Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.0), Color(Palette.GROUND_DEEP, 0.55)])
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5)
	vt.fill_to = Vector2(1.0, 0.5)
	vt.width = 256
	vt.height = 256
	_vignette.texture = vt
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.z_index = 60
	root.add_child(_vignette)


## How wide a row is, relative to the front row: the back of the board recedes.
func _row_k(r: int) -> float:
	if Fold.rows <= 1:
		return 1.0
	var f := float(r) / float(Fold.rows - 1)     # 0 at the back, 1 at the front
	return 1.0 - RECEDE * (1.0 - f)


## The centre of cell (r, c) on the tilted plane.
func _cell_pos(r: float, c: float) -> Vector2:
	var k := _row_k(int(round(r)))
	var span := (Fold.cols - 1) * 0.5
	var x := (c - span) * (_cs + CELL_GAP) * k
	var y := (r - (Fold.rows - 1) * 0.5) * (_cs + CELL_GAP) * TILT
	return _origin + Vector2(x, y)


func _relayout() -> void:
	var vp := get_viewport_rect().size
	# 0.78 / 0.78, up from 0.62 / 0.70: measured off the captured frame, where the tray
	# occupied about an eighth of the screen and the background the rest. The board is the
	# product; it gets the middle of the picture.
	var avail := Vector2(vp.x * 0.78, vp.y * 0.72)
	_cs = maxf(34.0, minf(
		(avail.x - CELL_GAP * (Fold.cols - 1)) / maxf(1, Fold.cols),
		(avail.y / TILT - CELL_GAP * (Fold.rows - 1)) / maxf(1, Fold.rows)))
	_cs = minf(_cs, 112.0)
	_origin = Vector2(vp.x * 0.5, vp.y * 0.55)
	_swipe_px = maxf(18.0, _cs * 0.3)

	# The table is a table, not a backdrop: it reaches a little past the board and stops.
	# The first pass made it 1.9x the board wide and 2.3x tall, which at 1280x720 is most
	# of the screen — a hard-edged grey rectangle with the game inside it.
	var w := (Fold.cols * (_cs + CELL_GAP)) * 1.34
	# 1.40, not 1.55. Growing the board to 0.78 of the frame made the tray tall enough to
	# ride up over the HUD — the captured zh frame has the stars row and the move counter
	# cut in half by the tray's top edge. The tray's padding is what gave way, not the
	# board: the pieces are the thing that had to get bigger.
	var h := (Fold.rows * (_cs + CELL_GAP)) * TILT * 1.40
	_table.size = Vector2(w, h)
	_table.position = _origin - Vector2(w, h) * 0.5
	# Palette.TABLE, undimmed. This line used to read PANEL_RAISED * ROOM_DIM, which is
	# #161A19 — measured off the captured frame, the table and the room came out at a
	# contrast ratio of 1.01:1, i.e. the same colour. There was no table.
	_table.modulate = Color(Palette.TABLE, 1.0)
	var tl := _table.position
	_rail.points = PackedVector2Array([
		tl, tl + Vector2(w, 0), tl + Vector2(w, h), tl + Vector2(0, h)])

	_lamp.position = _origin - Vector2(0, (Fold.rows * (_cs + CELL_GAP)) * TILT * 0.30)
	# the pool of light has to be wider than the board or the far corners fall out of it
	_table_edge.position = _origin
	_table_edge.scale = Vector2(w, h) * 1.6 / 256.0
	var pool := maxf(1500.0, (Fold.cols * (_cs + CELL_GAP)) * 3.2)
	(_lamp.get_node("Light") as PointLight2D).texture_scale = pool / 512.0
	(_lamp.get_node("Glow") as Sprite2D).scale = Vector2.ONE * (pool / 512.0)

	_draw_cells()
	_rebuild_pieces()


func _draw_cells() -> void:
	for c in _cells.get_children():
		c.queue_free()
	for r in range(Fold.rows):
		for c in range(Fold.cols):
			var wall := Fold.is_wall(r, c)
			var s := Sprite2D.new()
			# Both are surfaces that get tinted, so both take the neutral stand-in — the
			# old call tinted an already-dark gradient and lost a third of the value it
			# asked for on top of asking for too little.
			s.texture = Art.surface_stand_in("wall" if wall else "table", 0.10)
			var k := _row_k(r)
			var px := _cs * k
			s.scale = Vector2(px, px * TILT) / Vector2(s.texture.get_width(), s.texture.get_height())
			s.position = _cell_pos(r, c)
			# An empty cell is a shadow cut into the tray (WELL, 2.38:1 under the table);
			# a wall is a slate block standing proud of it (WALL_FACE, 3.70:1 over the
			# table and 7.16:1 over a well). Before, both were near-black on near-black:
			# an empty cell scored 1.01:1 against the table and a player could not see the
			# grid at all, never mind tell a blocked cell from a free one.
			s.modulate = Palette.WALL_FACE if wall else Palette.WELL
			s.z_index = 0
			_cells.add_child(s)
			var hw := px * 0.5
			var hh := px * TILT * 0.5
			# a hairline around every well, so the grid reads as a grid under the light
			var edge := Line2D.new()
			edge.points = PackedVector2Array([
				s.position + Vector2(-hw, -hh), s.position + Vector2(hw, -hh),
				s.position + Vector2(hw, hh), s.position + Vector2(-hw, hh),
				s.position + Vector2(-hw, -hh)])
			edge.width = maxf(1.0, px * 0.02)
			edge.default_color = Color(Palette.WALL_EDGE if wall else Palette.TABLE_DEEP, 0.9)
			edge.z_index = 1
			_cells.add_child(edge)
			# The lit lip. A recess is legible because light catches the edge nearest the
			# lamp and the inside stays dark; a flat dark square is just a dark square. The
			# lip goes on the *near* edge of a well and along the *top* of a wall, which is
			# what tells the two apart at a glance even before their fills do.
			var lip := Line2D.new()
			var ly := hh if not wall else -hh
			lip.points = PackedVector2Array([
				s.position + Vector2(-hw, ly), s.position + Vector2(hw, ly)])
			lip.width = maxf(1.5, px * 0.05)
			# A well's lip is WELL_LIP (light caught on the near edge of a recess); a
			# wall's is white, because a wall is a block standing proud and the light
			# lands on its top. Using the dark outline colour here, as the first pass
			# did, lit the block from underneath.
			lip.default_color = Color(Palette.WELL_LIP if not wall else Palette.PAPER, 0.95)
			lip.z_index = 2
			_cells.add_child(lip)


func _rebuild_pieces() -> void:
	for c in _pieces.get_children():
		c.queue_free()
	_sprites.clear()
	for t in Fold.tiles:
		_sprites[int(t["id"])] = _make_piece(t)


## One playing piece, through scripts/piece_view.gd so the board and the title screen's
## attract loop draw the same object.
func _make_piece(t: Dictionary) -> Node2D:
	var r := int(t["r"])
	var px := _cs * _row_k(r)
	# 1.0, not ROOM_DIM: see PieceView.make. The attract loop in scenes/title.gd still
	# passes ROOM_DIM, because that board is scenery and this one is the game.
	var holder := PieceView.make(int(t["v"]), px, TILT, 1.0, true)
	holder.position = _cell_pos(r, int(t["c"]))
	holder.z_index = 10 + r
	_pieces.add_child(holder)
	return holder


## A one-shot burst of sparks at a board position. This is the whole juice budget: a
## merge, a solved level and the promo board all call it, so there is one look for "good
## thing happened" instead of three.
##
## GPUParticles2D with one_shot and explosiveness 1.0 fires the whole amount on the frame
## it is added and then sits idle, so the node frees itself on a timer rather than being
## pooled — at a dozen sparks a merge that is cheaper than keeping emitters around.
func _sparkle(at: Vector2, color: Color, amount: int = 14, spread: float = 1.0, parent: Node = null) -> void:
	if Juice.reduced_motion:
		amount = maxi(3, amount / 3)
		spread *= 0.6
	var ps := GPUParticles2D.new()
	ps.amount = maxi(1, amount)
	ps.lifetime = 0.62
	ps.one_shot = true
	ps.explosiveness = 1.0
	ps.texture = PieceView.falloff(24, 0.25)
	ps.position = at
	ps.z_index = 50
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = _cs * 0.22 * spread
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, 260, 0)
	pm.initial_velocity_min = 90.0 * spread
	pm.initial_velocity_max = 260.0 * spread
	pm.scale_min = 0.25
	pm.scale_max = 0.85
	pm.color = color
	# a spark should die out, not blink off
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	fade.colors = PackedColorArray([Color(color, 1.0), Color(color, 0.9), Color(color, 0.0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	ps.process_material = pm
	# additive, so sparks read as light over both the tray and a candy tile
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ps.material = mat
	(parent if parent != null else _board).add_child(ps)
	# The cleanup rides on the particles' own tween, so it dies with them. A SceneTree
	# timer whose lambda captured `ps` fired after the board was freed (leave a level
	# within 1.4 s of a merge) and logged "Lambda capture at index 0 was freed" per spark.
	var tw := ps.create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(ps.queue_free)


# --- the HUD ------------------------------------------------------------------------------------

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 1
	add_child(_hud)

	var pad := MarginContainer.new()
	pad.theme = StudioTheme.build()     # CanvasLayer breaks Theme propagation; see title.gd
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(m, 36)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_bottom", 26)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(pad)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)

	# top row: the mark, the level name, the controls
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 14)
	col.add_child(top)

	var mark := VectorMark.new()
	mark.mark = VectorMark.NAME
	# 116x38 at weight 1.15, up from 104x34 at 0.8. The small lockup is drawn from the
	# same skeleton as the title mark, so at this size a sub-1.0 weight put the strokes
	# under two pixels and the HUD logo came out of the capture as a thin orange outline
	# rather than as the chunky mark it is on the title screen.
	mark.custom_minimum_size = Vector2(116, 38)
	mark.weight = 1.15
	mark.shadow = Color(Palette.INK, 0.35)
	top.add_child(mark)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 1)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(mid)

	# Every size in this block went up, and the dimmest colours came off it. The rule in
	# TITLE_SCREENS.md asks that the HUD read "without effort": at 15/14/13/12 px in sage
	# grey over a photographic room, none of these did, and at 390 px wide they were gone.
	# ACCENT_DEEP, not GOLD_PALE. Pale gold on a pale sky is the same mistake as pale grey
	# on walnut, and in the captured frame the level name was the one unreadable thing.
	_lvname = StudioTheme.display_label("", 20, Palette.ACCENT_DEEP)
	_lvname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_lvname)

	_goal = StudioTheme.serif_label("", 21, Palette.TEXT, true)
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_goal)

	# The diagram step. Small and MUTED at rest, because it is a caption and not the goal;
	# it lifts to ACCENT_DEEP for a beat when a merge reaches the next step
	# (`_announce_step`). This is the line that says WHICH part moved and where -- "Rolled
	# to the knee" -- and in the her band it is the whole of what makes the board legible
	# as folding her rather than as arithmetic with a photograph behind it.
	_step = StudioTheme.serif_label("", 14, Palette.MUTED, true)
	_step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_step)

	var back := Button.new()
	back.theme_type_variation = "Ghost"
	back.text = "‹"
	back.tooltip_text = I18n.t("back")
	back.pressed.connect(_to_title)
	top.add_child(back)

	var langb := Button.new()
	langb.name = "Lang"
	langb.theme_type_variation = "Ghost"
	langb.pressed.connect(func():
		I18n.toggle()
		mark.mark = VectorMark.NAME     # a name is not translated; see vector_mark.gd
		Tel.ev("language_selected", {"language": I18n.lang}))
	top.add_child(langb)

	var soundb := Button.new()
	soundb.name = "Sound"
	soundb.theme_type_variation = "Ghost"
	soundb.pressed.connect(func():
		Sfx.set_sfx(not Sfx.sfx_on)
		Sfx.set_music(Sfx.sfx_on)
		_sync())
	top.add_child(soundb)

	# Coco's voice, separate from the SFX/music switch; and reduced motion
	var voiceb := Button.new()
	voiceb.name = "Voice"
	voiceb.theme_type_variation = "Ghost"
	voiceb.pressed.connect(func():
		Juice.set_voice(not Juice.voice_on)
		if not Juice.voice_on:
			Coco.stop()
		_sync())
	top.add_child(voiceb)

	var motionb := Button.new()
	motionb.name = "Motion"
	motionb.theme_type_variation = "Ghost"
	motionb.pressed.connect(func():
		Juice.set_reduced_motion(not Juice.reduced_motion)
		_sync())
	top.add_child(motionb)

	# the star row and the move counter sit just under the title block
	var sub := HBoxContainer.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	sub.add_theme_constant_override("separation", 16)
	col.add_child(sub)

	_stars_row = HBoxContainer.new()
	_stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars_row.add_theme_constant_override("separation", 3)
	sub.add_child(_stars_row)

	_moves = StudioTheme.mono_label("", 17, Palette.TEXT)
	sub.add_child(_moves)

	_tier_lbl = StudioTheme.mono_label("", 15, Palette.GOLD)
	sub.add_child(_tier_lbl)

	# the score for this board, and every star ever earned: the results card pays into it
	_score_lbl = StudioTheme.display_label("", 22, Palette.EPIC)
	_score_lbl.pivot_offset = Vector2(40, 14)
	sub.add_child(_score_lbl)
	_stars_total = StudioTheme.display_label("", 22, Palette.GOLD)
	_stars_total.name = "StarsTotal"
	_stars_total.pivot_offset = Vector2(30, 14)
	sub.add_child(_stars_total)

	# the streak: coral, display type, pops when it climbs
	_streak_lbl = StudioTheme.display_label("", 22, Palette.HEAT)
	_streak_lbl.pivot_offset = Vector2(40, 14)
	sub.add_child(_streak_lbl)

	# bottom: undo / reset / levels, and the one-line rule
	var bottom := VBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.theme = StudioTheme.build()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -108
	bottom.offset_left = 36
	bottom.offset_right = -36
	bottom.offset_bottom = -26
	bottom.alignment = BoxContainer.ALIGNMENT_END
	_hud.add_child(bottom)

	var btns := HBoxContainer.new()
	btns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 12)
	bottom.add_child(btns)

	_undo_btn = Button.new()
	_undo_btn.theme_type_variation = "Amber"
	_undo_btn.pressed.connect(func():
		if await _try_undo():
			Juice.on_undo()
			Sfx.slide()
			_rebuild_pieces()
			_sync())
	btns.add_child(_undo_btn)

	_reset_btn = Button.new()
	_reset_btn.theme_type_variation = "Amber"
	_reset_btn.pressed.connect(func():
		if F2P.on():
			_f2p_retry()
			return
		Fold.reset()
		Tier.streak_break()
		Sfx.slide()
		_said_near = false
		Juice.reset_board()
		_near_fail_said = false
		_high = _tallest()   # a reset unfolds the sheet; the step caption goes back with it
		_rebuild_pieces()
		_sync())
	btns.add_child(_reset_btn)

	if F2P.on():
		var hint := Button.new()
		hint.name = "Hint"
		hint.text = "Hint"
		hint.theme_type_variation = "Amber"
		hint.pressed.connect(_f2p_hint)
		btns.add_child(hint)
		var shop := Button.new()
		shop.name = "Shop"
		shop.text = "Shop"
		shop.theme_type_variation = "Amber"
		var shop_done := func():
			_win.visible = false
			_sync()
		shop.pressed.connect(func(): F2PUI.shop(_win, shop_done))
		btns.add_child(shop)

	var lv := Button.new()
	lv.name = "Levels"
	lv.theme_type_variation = "Amber"
	lv.pressed.connect(_to_map)
	btns.add_child(lv)

	_hint = StudioTheme.serif_label("", 15, Palette.TEXT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_hint)


func _build_overlays() -> void:
	_win = _overlay()
	_picker = _overlay()
	_hud.add_child(_win)
	_hud.add_child(_picker)


func _overlay() -> Control:
	var c := Control.new()
	c.theme = StudioTheme.build()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(Palette.GROUND_DEEP, 0.82)
	c.add_child(bg)
	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(centre)
	return c


func _sync() -> void:
	_goal.text = I18n.f("goal", Fold.target())
	var alt := Juice.goal_text(Fold.level_index)
	if alt != "":
		_goal.text += "  +  " + alt
		var g := Juice.goal_for(Fold.level_index)
		if str(g["type"]) == "combo":
			_goal.text += "  (best x%d)" % Juice.max_combo
	_moves.text = I18n.f("moves", Fold.moves) + "   ·   " + I18n.f("parhint", Fold.par())
	if F2P.on() and F2P.active_for(Fold.level_index):
		_moves.text += "   ·   %d left" % F2P.moves_left()
	# THE MODEL, in the header. ops/fold/BRIDGE.md: the level's name IS the thing it folds,
	# and the fold count is log2(target) because the tile value is the layer count. In this
	# fork the first two tiers fold paper and every tier after folds her (scripts/origami.gd,
	# `band`), so the same header carries "Envelope · 3 folds" early and "The sash · 3 folds"
	# later without changing a rule. A level the model data does not cover falls back to the
	# shipped level name rather than showing an empty header.
	var model := Origami.model_for(Fold.level_index)
	if Origami.has_model(Fold.level_index):
		_lvname.text = "%d · %s · %s" % [Fold.level_index + 1,
			Origami.model_name(model, I18n.lang),
			I18n.f("folds", Origami.folds_to_finish(Fold.level_index))]
	else:
		_lvname.text = "%d · %s" % [Fold.level_index + 1, Fold.level_name(Fold.level_index, I18n.lang)]
	_step.text = Origami.step_text(model, _high, I18n.lang)
	_undo_btn.text = I18n.t("undo")
	_undo_btn.disabled = Fold.history.is_empty() or Fold.done
	_reset_btn.text = I18n.t("reset")
	_hint.text = I18n.t("hint")
	var top := _hud.get_child(0).get_child(0).get_child(0)
	(top.get_node("Lang") as Button).text = "中文" if I18n.lang == "en" else "EN"
	(top.get_node("Sound") as Button).text = "♪" if Sfx.sfx_on else "✕"
	(top.get_node("Voice") as Button).text = "Voice ✓" if Juice.voice_on else "Voice ✕"
	(top.get_node("Motion") as Button).text = "Motion ✓" if not Juice.reduced_motion else "Motion ✕"
	(top.get_node("Voice") as Button).tooltip_text = "Coco's voice (subtitles stay on)"
	(top.get_node("Motion") as Button).tooltip_text = "Reduced motion: no shake, no flying rewards"
	_score_lbl.text = "%s %d" % ["SCORE", Juice.score]
	if not _results_open:
		_stars_total.text = "★ %d" % _star_sum()
	var lvb := _undo_btn.get_parent().get_node("Levels") as Button
	lvb.text = I18n.t("map_btn")
	var t := Tier.of_level(Fold.level_index)
	_tier_lbl.text = "%s %d · %d/%d" % [I18n.t("tier").to_upper(), t + 1, Tier.cleared_in(t), Tier.length(t)]
	_streak_lbl.text = "%s %d" % [I18n.t("streak"), Tier.streak] if Tier.streak > 0 else ""
	# the three stars: how well this level has ever been done
	for c in _stars_row.get_children():
		c.queue_free()
	var best := Save.stars_at(Fold.level_index)
	for i in range(3):
		var s := StudioTheme.display_label("★" if i < best else "☆", 20, Palette.star_color(i < best))
		_stars_row.add_child(s)


# --- opening a level ------------------------------------------------------------------------------

func _open(i: int) -> void:
	# Nutaku F2P: no ad gate, no page gate. The server opens the attempt (and takes the
	# candle) or says why not; see scripts/f2p.gd.
	if F2P.on():
		_win.visible = false
		if not await F2P.ensure():
			_f2p_error("Could not reach the game server. " + Nutaku.last_error)
			return
		var r := await F2P.begin(i)
		if not r["ok"]:
			if int(r["status"]) == 402:
				_f2p_no_candles(i)
			elif int(r["status"]) == 403:
				_to_map()
			else:
				_f2p_error(str(r["reason"]))
			return
	# The ad gate. Levels 1-50 are free on every track; past that the page decides —
	# a price on itch, a sponsor clip on free.blazecore.dev. shared/godot/gate.gd returns
	# true off the web and on a page with no gate.js, so a local build never bricks.
	elif i >= Fold.FREE_LEVELS and has_node("/root/Gate"):
		var gate := get_node("/root/Gate")
		if not gate.has("lv%d" % i):
			var okay: bool = await gate.require("lv%d" % i, "%s %d" % [I18n.t("level"), i + 1], "level")
			if not okay:
				return
	Fold.load_level(i)
	# The starting board is already folded: a level that opens with 2s on it has had one
	# fold done for you. `_tallest`, not 0 -- seeding 0 would make the first merge announce
	# a step the player did not perform.
	_high = _tallest()
	_said_near = false
	_idle_clock = 0.0
	Juice.reset_board()
	_near_fail_said = false
	_hide_combo()
	Save.set_current_level(i)
	_win.visible = false
	_relayout()
	_sync()
	_show_start_card()
	if not Coco.daily():
		Coco.say("start")
	Tel.level_ev("level_opened")
	# The server ticket for this tier's scene is asked for now, so the gateway's minimum
	# wait runs under the tier instead of after it. Off the web this is a no-op.
	var scene := Tier.scene_for(Tier.of_level(i))
	var sid := str(scene["id"])
	if not F2P.on() and not bool(scene.get("placeholder", false)) and _ticket_for != sid and not Unlock.ready_for(sid):
		_ticket_for = sid
		Unlock.start(sid)


func _to_title() -> void:
	Sfx.slide()
	var scene: PackedScene = load("res://scenes/title.tscn")
	var node := scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


# --- a fold ------------------------------------------------------------------------------------

## The tallest piece on the board: the deepest-folded sheet in play.
func _tallest() -> int:
	var best := 0
	for t in Fold.tiles:
		best = maxi(best, int(t["v"]))
	return best


## A merge that reached the next layer count has completed a real diagram step, so say
## which one. Everything below the first named step (a lone 2, which is one fold of a
## square and not yet a shape) passes silently, and so does a model the data does not
## cover -- an empty caption is better than a wrong one.
func _announce_step() -> void:
	var v := _tallest()
	if v <= _high:
		return
	_high = v
	var text := Origami.step_text(Origami.model_for(Fold.level_index), v, I18n.lang)
	if text == "":
		return
	_step.text = text
	_step.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	var tw := create_tween()
	tw.tween_property(_step, "modulate:a", 1.0, 0.18).from(0.0)
	tw.tween_callback(func():
		if is_instance_valid(_step):
			_step.add_theme_color_override("font_color", Palette.MUTED)).set_delay(1.4)


func _on_moved(direction: Vector2i, merge_count: int) -> void:
	if F2P.on():
		F2P.on_move(direction)
		_f2p_check_budget.call_deferred()
	var jr := Juice.on_move()
	if merge_count > 0:
		# a merge doubled the layer count, which is one more fold: say which one it was
		_announce_step()
		Sfx.merge(merge_count)
		if Juice.combo >= 2:
			Sfx.combo(Juice.combo)
			_show_combo(Juice.combo)
		if Juice.combo >= 3 or merge_count >= 2:
			Juice.shake(_board, 3.0 + 1.5 * mini(Juice.combo, 5))
		if Juice.combo >= 3:
			Coco.say("combo")
		elif randf() < 0.3:
			Coco.say("good")
		_score_pop(int(jr["points"]))
	else:
		Sfx.slide()
		_hide_combo()
	# The tease slot, one fold from the end: two tiles left and both of them half the
	# target, which is the only board state from which the next merge finishes the model.
	# Said once per level -- a line that fires on every shuffle around a near-miss stops
	# being a tease within about thirty seconds.
	_idle_clock = 0.0
	if not _said_near and _one_fold_left():
		_said_near = true
		Coco.say("good")
	_check_near_fail()
	_flash_crease(direction)
	_fold_squash(direction)
	_animate(direction)
	_sync()
	Tel.level_ev("move_made", {"move": Fold.moves, "direction": [direction.x, direction.y]})


func _on_refused(direction: Vector2i) -> void:
	Sfx.invalid()
	# the board leans into the wall and comes back — the page's "boardFollow" nudge
	var d := Vector2(direction.y, direction.x * TILT) * 7.0
	var tw := create_tween()
	tw.tween_property(_board, "position", d, 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_board, "position", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## The pieces that survived slide to where Fold says they are; the ones that did not are
## taken off the board as their target pops.
func _animate(direction: Vector2i) -> void:
	var alive := {}
	for t in Fold.tiles:
		alive[int(t["id"])] = t
	for id in _sprites.keys():
		if not alive.has(id):
			var gone: Node2D = _sprites[id]
			var tw := create_tween().set_parallel(true)
			tw.tween_property(gone, "scale", Vector2(0.4, 0.4), 0.09)
			tw.tween_property(gone, "modulate:a", 0.0, 0.09)
			tw.chain().tween_callback(gone.queue_free)
			_sprites.erase(id)
	for t in Fold.tiles:
		var id := int(t["id"])
		var want := _cell_pos(int(t["r"]), int(t["c"]))
		if not _sprites.has(id):
			_sprites[id] = _make_piece(t)
			continue
		var node: Node2D = _sprites[id]
		var tw := create_tween()
		# TRANS_BACK, not CUBIC: a piece overshoots its cell by a hair and settles into
		# it. That tiny bounce is most of what makes the board feel physical rather than
		# animated, and it costs one enum.
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var travelled := node.position.distance_to(want) > 1.0
		tw.tween_property(node, "position", want, 0.11)
		node.z_index = 10 + int(t["r"])
		# stretch along the fold while it travels, squash as it lands, spring back
		if travelled and not bool(t.get("merged", false)) and not Juice.reduced_motion:
			var along := Vector2(0.88, 1.12) if direction.x != 0 else Vector2(1.12, 0.88)
			var st := create_tween()
			st.tween_property(node, "scale", along, 0.05)
			st.tween_property(node, "scale", Vector2(along.y, along.x), 0.06)
			st.tween_property(node, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		if bool(t.get("merged", false)):
			t["merged"] = false
			PieceView.repaint(node, int(t["v"]), _cs * _row_k(int(t["r"])), 1.0, true)
			var pop := create_tween()
			pop.tween_property(node, "scale", Vector2(1.22, 1.22), 0.06).set_delay(0.05)
			pop.tween_property(node, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			# and it throws sparks in its own colour, so a merge is visible even if the
			# player's eye was somewhere else on the board
			var face := Palette.tile_face(int(t["v"]))
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(self) and is_instance_valid(node):
					_sparkle(node.position, face, 16))


## The crease: a bright line sweeping across the board along the axis of the fold. This is
## the single most "folded" thing on the screen and it is why the move reads as a fold and
## not as a slide.
func _flash_crease(direction: Vector2i) -> void:
	var half_w := (Fold.cols * (_cs + CELL_GAP)) * 0.55
	var half_h := (Fold.rows * (_cs + CELL_GAP)) * TILT * 0.55
	if direction.x != 0:
		_crease.points = PackedVector2Array([_origin + Vector2(-half_w, 0), _origin + Vector2(half_w, 0)])
	else:
		_crease.points = PackedVector2Array([_origin + Vector2(0, -half_h), _origin + Vector2(0, half_h)])
	_crease.default_color = Color(Palette.CREAM, 0.0)
	var from := Vector2(0, -half_h) if direction.x != 0 else Vector2(-half_w, 0)
	var to := -from
	_crease.position = from * float(direction.x + direction.y) * -1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_crease, "position", to * float(direction.x + direction.y) * -1.0, 0.14)
	tw.tween_property(_crease, "default_color", Color(Palette.CREAM, 0.95), 0.06)
	tw.chain().tween_property(_crease, "default_color", Color(Palette.CREAM, 0.0), 0.12)


## The win: a burst across the whole tray, one volley per star, in the ramp's own hot
## colours. It fires before the win panel slides in, so the board is the thing celebrating
## and the panel is the thing reporting.
func _win_burst(stars: int) -> void:
	var colors := [Palette.GOLD, Palette.ACCENT, Palette.HEAT, Palette.EPIC]
	for i in range(maxi(1, stars) + 1):
		var delay := 0.10 * i
		var col: Color = colors[i % colors.size()]
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(self):
				return
			for r in range(Fold.rows):
				for c in range(Fold.cols):
					if Fold.is_wall(r, c):
						continue
					_sparkle(_cell_pos(r, c), col, 7, 1.3))


## The fold: the whole board squashes along the axis of the move and springs back. A fold
## is a thing that happens to the *sheet*, not to eight independent tiles, and this is the
## cheapest way to say so — it is also the motion Blaze asked for when he said the pieces
## should feel foldable.
func _fold_squash(direction: Vector2i) -> void:
	var squash := Vector2(0.965, 1.035) if direction.x != 0 else Vector2(1.035, 0.965)
	_board.scale = squash
	var tw := create_tween()
	tw.tween_property(_board, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## True when the next merge would finish the model: two tiles, each half the target.
func _one_fold_left() -> bool:
	if Fold.tiles.size() != 2:
		return false
	var half := Fold.target() / 2
	return int(Fold.tiles[0]["v"]) == half and int(Fold.tiles[1]["v"]) == half


# --- winning -------------------------------------------------------------------------------------

func _on_solved(stars: int, move_count: int, p: int) -> void:
	# An alternate goal (data/goals.json) sits on top of the win. Missing it is a miss, not
	# a clear: the server would refuse the log for the same reason (fold_rules.goal_met).
	var gm := Juice.goal_met(Fold.level_index, move_count)
	if not bool(gm["ok"]):
		if F2P.on():
			await F2P.give_up()
		Tier.streak_break()
		Coco.say("near_fail", true)
		var again := func(_s: Label): _open(Fold.level_index)
		var home := func(_s: Label): _to_map()
		F2PUI.card(_win, "So close!", ["The board is folded, but the bonus goal was missed.", str(gm["why"])],
			[["Try again", "Primary", again, "Retry"], ["Map", "Amber", home, "Map"]])
		return
	if F2P.on():
		# the server replays the fold log; only its answer clears the level
		var res := await F2P.finish(move_count)
		if not res["ok"]:
			var again := func(_s: Label): _open(Fold.level_index)
			var home := func(_s: Label): _to_map()
			F2PUI.card(_win, "Not counted", ["The server did not accept this result: %s" % res["reason"]],
				[["Try again", "Primary", again, "Retry"], ["Map", "Amber", home, "Map"]])
			return
		stars = int(res["stars"])
	if not Sfx.cue("win"):
		Sfx.unity(stars)
	_hide_combo()
	# One voice, one line: Coco drops a line while another is playing, so the order here
	# is the priority. A streak milestone is the rarer thing to have earned, so it wins
	# over a three-star clear, which wins over an ordinary one.
	if Tier.streak > 0 and (Tier.streak + 1) % 3 == 0:
		Coco.say("streak", true)
	elif stars >= 3:
		Coco.say("win3", true)
	else:
		Coco.say("win", true)
	_win_burst(stars)
	var gained := maxi(0, stars - Save.stars_at(Fold.level_index))
	var before := _star_sum()
	Save.record(Fold.level_index, stars)
	Tier.streak_hit()
	Tel.level_ev("level_completed", {"moves": move_count, "stars": stars, "par": p})
	_results_open = true              # keeps the HUD star total at `before` until it is paid
	_stars_shown = before
	_stars_total.text = "★ %d" % before
	_sync()
	var pop := create_tween()
	pop.tween_property(_streak_lbl, "scale", Vector2(1.5, 1.5), 0.08)
	pop.tween_property(_streak_lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# The results card: stars one by one, the score counting up, the new stars flying into
	# the HUD. Tap (or Enter/Space) skips to the end; a second tap moves on.
	await _show_results(stars, move_count, p, gained, before)
	if not is_instance_valid(self):
		return
	var t := Tier.of_level(Fold.level_index)
	if Fold.level_index < Tier.last_level(t):
		# inside the tier: no button — the next board arrives on its own
		if not _win.visible:
			_open(Fold.level_index + 1)
		return
	_show_trophy(t, stars, move_count, p)


## The end of a tier: the trophy, and the one button that matters.
func _show_trophy(t: int, stars: int, move_count: int, p: int) -> void:
	var centre := _win.get_node("Centre") as CenterContainer
	for c in centre.get_children():
		c.queue_free()
	var scene := Tier.scene_for(t)
	var placeholder := bool(scene.get("placeholder", false))

	var card := PanelContainer.new()
	card.theme_type_variation = "Glass"
	card.custom_minimum_size = Vector2(440, 0)
	centre.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	var h := StudioTheme.display_label(I18n.t("trophy"), 40, Palette.GOLD)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var sub := StudioTheme.mono_label("%s %d   ·   %s %d" % [I18n.t("tier").to_upper(), t + 1, I18n.t("streak"), Tier.streak], 13, Palette.HEAT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	# the scene card, teaser dimmed, as on the map
	if not placeholder:
		var pic := TextureRect.new()
		pic.texture = load(Tier.teaser_path(str(scene["id"])))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(400, 200)
		pic.modulate = Color(0.55, 0.4, 0.5, 1)
		col.add_child(pic)
	var st := StudioTheme.serif_label(str(scene["title"]), 15, Palette.TEXT, true)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(st)
	if placeholder:
		var ph := StudioTheme.mono_label(I18n.t("placeholder_scene"), 11, Palette.RED_TEXT)
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(ph)

	var status := StudioTheme.mono_label("", 12, Palette.MUTED)
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(400, 0)
	col.add_child(status)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	var to_map := Button.new()
	to_map.name = "Map"
	to_map.text = I18n.t("back_to_map")
	to_map.theme_type_variation = "Amber"
	to_map.pressed.connect(_to_map)
	btns.add_child(to_map)
	if not placeholder:
		var unlock := Button.new()
		unlock.name = "Unlock"
		unlock.text = I18n.t("unlock_scene")
		unlock.theme_type_variation = "Primary"
		unlock.pressed.connect(func(): _unlock(scene, unlock, status))
		btns.add_child(unlock)

	_win.visible = true
	card.modulate.a = 0.0
	create_tween().tween_property(card, "modulate:a", 1.0, 0.2)
	Tel.ev("tier_cleared", {"tier": t + 1, "stars": stars, "moves": move_count, "par": p})


## The unlock: page gate first (a sponsor clip on the ad track, a price on itch; a page
## with no gate.js says yes), then the server ticket. No delivered bytes, no scene — the
## card stays and says so.
func _unlock(scene: Dictionary, btn: Button, status: Label) -> void:
	var id := str(scene["id"])
	btn.disabled = true
	status.text = I18n.t("delivering")
	var ok := true
	if F2P.on():
		ok = F2P.server_unlocked(id) and await F2P.deliver(id)
	elif not Unlock.ready_for(id):
		var gate := get_node("/root/Gate")
		ok = await gate.require("scene_" + id, str(scene["title"]), "cg")
		if ok and not (str(_ticket_for) == id) :
			ok = await Unlock.start(id)
		elif ok and Unlock._ticket.is_empty():
			ok = await Unlock.start(id)
		if ok:
			ok = false
			for _i in range(6):
				if await Unlock.redeem(id):
					ok = true
					break
				if Unlock.last_status != 425:
					break
				status.text = I18n.t("delivering") + " (%d)" % (6 - _i)
				await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(btn):
		return
	if not ok or not Unlock.ready_for(id):
		status.text = I18n.t("not_delivered")
		btn.text = I18n.t("retry_fetch")
		btn.disabled = false
		Tel.ev("scene_not_delivered", {"scene": id})
		return
	Tier.mark_unlocked(id)
	Tel.ev("scene_unlocked", {"scene": id})
	Coco.say("unlock", true)
	Sfx.cue("win")
	_viewer = SceneView.open(_hud, scene, func():
		_viewer = null
		_offer_board()
		_to_map())


func _to_map() -> void:
	Sfx.slide()
	var scene: PackedScene = load("res://scenes/map.tscn")
	var node := scene.instantiate()
	node.set("focus_tier", Tier.current())
	node.set("from_title", false)
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


func _show_win(stars: int, move_count: int, p: int) -> void:
	var centre := _win.get_node("Centre") as CenterContainer
	for c in centre.get_children():
		c.queue_free()

	var card := PanelContainer.new()
	card.theme_type_variation = "Glass"
	card.custom_minimum_size = Vector2(400, 0)
	centre.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	var h := StudioTheme.display_label(I18n.t("win"), 44, Palette.ACCENT_DEEP)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)

	# WHAT YOU JUST FOLDED. ops/fold/BRIDGE.md's whole point: the player did not clear a
	# grid, they finished a model, and the win card is the only place that can say so with
	# the finished thing in front of them. The last fold was the winning merge, so the
	# count here is the model's own depth, not the move count.
	#
	# What it does NOT do is show a picture. The parent pays this out with a plate of the
	# finished crane; this fork's payout is the gated CG at the end of a TIER
	# (scripts/tiers.gd -> scripts/unlock.gd, kind "cg"), and putting a second reveal on
	# every level would spend the thing the tier is saving up for. So the card names the
	# fold and the tier card pays it.
	if Origami.has_model(Fold.level_index):
		var done := StudioTheme.serif_label("%s · %s" % [
			Origami.level_model_name(Fold.level_index, I18n.lang),
			I18n.f("folds", Origami.folds_to_finish(Fold.level_index))],
			15, Palette.ACCENT_DEEP, true)
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(done)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	for i in range(3):
		var s := StudioTheme.display_label("★" if i < stars else "☆", 30, Palette.star_color(i < stars))
		s.modulate.a = 0.0
		row.add_child(s)
		var tw := create_tween()
		tw.tween_property(s, "modulate:a", 1.0, 0.22).set_delay(0.12 * i)
		tw.parallel().tween_property(s, "scale", Vector2.ONE, 0.22).from(Vector2(1.7, 1.7)).set_delay(0.12 * i)

	# the coach's line, on paper, in the one italic
	var paper := PanelContainer.new()
	paper.theme_type_variation = "Paper"
	var say := StudioTheme.say_label(16)
	say.text = "[center]“%s”[/center]" % I18n.coach_line(p)
	paper.add_child(say)
	col.add_child(paper)

	var stat := StudioTheme.serif_label("%s   ·   %s" % [I18n.f("moves", move_count), I18n.f("parhint", p)],
		13, Palette.MUTED)
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(stat)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)

	var retry := Button.new()
	retry.text = I18n.t("retry")
	retry.theme_type_variation = "Amber"
	retry.pressed.connect(func():
		_offer_board()
		_open(Fold.level_index))
	btns.add_child(retry)

	if Fold.level_index < Fold.level_count() - 1:
		var next := Button.new()
		next.name = "Next"
		next.text = I18n.t("next") + " →"
		next.theme_type_variation = "Primary"
		next.pressed.connect(func():
			_offer_board()
			_open(Fold.level_index + 1))
		btns.add_child(next)

	var share := Button.new()
	share.text = I18n.t("share")
	share.theme_type_variation = "Ghost"
	share.pressed.connect(func(): _share(stars, move_count))
	share.visible = not F2P.on()     # the share text carries a URL; Nutaku bans outbound links
	col.add_child(share)

	_win.visible = true
	card.modulate.a = 0.0
	create_tween().tween_property(card, "modulate:a", 1.0, 0.25)


## The end of a run is where this catalogue offers the rest of itself — offered, never
## forced, once a session, and always the CASUAL board: FOLD is mainstream and lives on
## the AdSense domain, where play/_shared/board.js vetoes the adult one anyway.
##
## It fires when the player LEAVES a solved level, not when the level is solved. The first
## build followed the web page and offered it 0.9 s after the win, and the board — a
## full-screen panel at z-index 100000 — landed straight on top of the win card, so the
## player never saw their own stars. Three seconds of result, then the offer.
func _offer_board() -> void:
	# Nutaku: no cross-promotion and no outbound links in the platform build.
	if F2P.on() or _board_offered or not has_node("/root/Gate"):
		return
	_board_offered = true
	get_node("/root/Gate").board_offer_more("adult")


func _share(stars: int, move_count: int) -> void:
	var name := Fold.level_name(Fold.level_index, I18n.lang)
	var txt := "%s · %s\n%s%s  %s\nfold-after-dark.flat404.workers.dev" % [
		# The name, and only the name. This used to append " FOLD" in zh -- a share card
		# from the renamed fork that read "PLICATA FOLD" and pointed players at the parent.
		str(I18n.WORDMARK.get(I18n.lang, "PLICATA")),
		name, "★".repeat(stars), "☆".repeat(3 - stars),
		I18n.f("moves", move_count)]
	DisplayServer.clipboard_set(txt)
	Tel.level_ev("result_shared", {"moves": move_count, "stars": stars})
	Sfx.slide()


# --- the level picker -------------------------------------------------------------------------------

func _show_picker(show: bool) -> void:
	if not show:
		_picker.visible = false
		return
	var centre := _picker.get_node("Centre") as CenterContainer
	for c in centre.get_children():
		c.queue_free()

	var card := PanelContainer.new()
	card.theme_type_variation = "Glass"
	card.custom_minimum_size = Vector2(620, 460)
	centre.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := StudioTheme.display_label("%s · %d %s" % [I18n.t("level"), Save.completed_count(), I18n.t("done")], 20, Palette.ACCENT_DEEP)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var x := Button.new()
	x.text = "✕"
	x.theme_type_variation = "Ghost"
	x.pressed.connect(func(): _show_picker(false))
	head.add_child(x)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(580, 380)
	col.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)

	for group in [["curated", 0, mini(Fold.CURATED, Fold.level_count())],
			["endless", Fold.CURATED, Fold.level_count()]]:
		if group[1] >= group[2]:
			continue
		inner.add_child(StudioTheme.mono_label(I18n.t(group[0]).to_upper(), 11, Palette.MUTED))
		var grid := GridContainer.new()
		grid.columns = 12
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		inner.add_child(grid)
		for i in range(group[1], group[2]):
			var b := Button.new()
			b.text = str(i + 1)
			b.custom_minimum_size = Vector2(40, 34)
			var best := Save.stars_at(i)
			if i == Fold.level_index:
				b.theme_type_variation = "Active"
			elif best > 0:
				b.theme_type_variation = "Amber"
			else:
				b.theme_type_variation = "Ghost"
			if i >= Fold.FREE_LEVELS:
				b.tooltip_text = "🔒"
			b.pressed.connect(func():
				_show_picker(false)
				_open(i))
			grid.add_child(b)
	_picker.visible = true


# --- input -----------------------------------------------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if _results_open and _results != null and _results.visible:
		if (e is InputEventKey and e.pressed and (e as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]) \
				or (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_results_skip = true
			get_viewport().set_input_as_handled()
		return
	if _win.visible or _picker.visible or _viewer != null:
		if e is InputEventKey and e.pressed:
			var k := (e as InputEventKey).keycode
			if k == KEY_ESCAPE and _viewer == null:
				_show_picker(false)
			elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
				# Enter: the one button that matters on whatever card is up
				var host: Node = _viewer if _viewer != null else _win
				# Enter presses the card's primary button. On Nutaku the primary can be a
				# purchase (Refill, +5 moves); the platform then shows its own confirm.
				for name in ["Close", "Unlock", "Refill", "MoreMoves", "Retry", "Map"]:
					var b := host.find_child(name, true, false)
					if b is Button and not (b as Button).disabled:
						(b as Button).pressed.emit()
						break
		return
	if e.is_action_pressed("fold_up"):
		Fold.move(-1, 0)
	elif e.is_action_pressed("fold_down"):
		Fold.move(1, 0)
	elif e.is_action_pressed("fold_left"):
		Fold.move(0, -1)
	elif e.is_action_pressed("fold_right"):
		Fold.move(0, 1)
	elif e.is_action_pressed("fold_undo"):
		if await _try_undo():
			Juice.on_undo()
			_rebuild_pieces()
			_sync()
	elif e.is_action_pressed("fold_reset"):
		if F2P.on():
			_f2p_retry()
			return
		Fold.reset()
		Juice.reset_board()
		_rebuild_pieces()
		_sync()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_to_map()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_drag_from = (e as InputEventMouseButton).position
			_dragging = true
			_pickup(true)
		elif _dragging:
			_dragging = false
			_pickup(false)
			_swipe((e as InputEventMouseButton).position - _drag_from)
			_board_home()
	elif e is InputEventMouseMotion and _dragging:
		var d: Vector2 = (e as InputEventMouseMotion).position - _drag_from
		# the board leans with the drag, capped, so it is clear the whole grid is pushed
		var ax := absf(d.x) > absf(d.y)
		_board.position = Vector2(clampf(d.x / 4.0, -10, 10) if ax else 0.0,
			0.0 if ax else clampf(d.y / 4.0, -10, 10))
		if _swipe(d):
			_dragging = false
			_pickup(false)
			_board_home()


func _board_home() -> void:
	var tw := create_tween()
	tw.tween_property(_board, "position", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _swipe(d: Vector2) -> bool:
	if maxf(absf(d.x), absf(d.y)) < _swipe_px:
		return false
	if absf(d.x) > absf(d.y):
		Fold.move(0, 1 if d.x > 0 else -1)
	else:
		Fold.move(1 if d.y > 0 else -1, 0)
	return true


func _process(delta: float) -> void:
	_t += delta
	# The idle line, after IDLE_AFTER seconds without a fold. The clock is reset by every
	# move and by every level load, and it re-arms rather than repeating immediately, so a
	# player who walks away hears her every IDLE_AFTER seconds and not once a frame.
	if not Fold.done and not _win.visible:
		_idle_clock += delta
		if _idle_clock >= IDLE_AFTER:
			_idle_clock = 0.0
			Sfx.bark("idle")
	if _coco_box != null and (_viewer != null) != (_coco_box.position.y < 40.0):
		_place_coco()
	if _coco_bubble != null and _coco_bubble.visible and _t >= _coco_hide_at:
		_coco_bubble.visible = false
	if _coco_pic != null and not Juice.reduced_motion:
		_coco_pic.position.y = 2.0 * sin(_t * 1.7)
	if _lamp:
		var f := 1.0 + 0.035 * sin(_t * 2.1) + 0.02 * sin(_t * 0.63)
		(_lamp.get_node("Light") as PointLight2D).energy = 2.1 * f
		(_lamp.get_node("Glow") as Sprite2D).modulate.a = 0.30 * f
	_publish()


## A read-only view of the board on window.__fold_state, for tests/headless_web.py.
##
## Read-only on purpose: the headless driver plays with real key and pointer events on the
## canvas, the way a player does, and uses this only to see what happened. A command
## channel would let the test drive the rules directly and pass while the input handling
## was broken — which is the shape of failure the memory note `verification-that-lies`
## describes, and the one thing a "does it work in a browser" test exists to catch.
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	var vals := []
	for t in Fold.tiles:
		vals.append(int(t["v"]))
	vals.sort()
	JavaScriptBridge.eval("window.__fold_state=%s;" % JSON.stringify({
		"level": Fold.level_index + 1,
		"name": Fold.level_name(Fold.level_index, "en"),
		"moves": Fold.moves,
		"tiles": Fold.tiles.size(),
		"values": vals,
		"target": Fold.target(),
		"par": Fold.par(),
		"done": Fold.done,
		"stars": Fold.stars() if Fold.done else 0,
		"lang": I18n.lang,
		"win_visible": _win.visible,
		"picker_visible": _picker.visible,
		"screen": "game",
		"tier": Tier.of_level(Fold.level_index) + 1,
		"tier_last": Fold.level_index == Tier.last_level(Tier.of_level(Fold.level_index)),
		"streak": Tier.streak,
		"scene_visible": _viewer != null,
		"plates_missing": Art.missing(),
		"f2p": F2P.on(),
		"moves_left": F2P.moves_left() if F2P.on() else -1,
		"attempt": F2P.active_for(Fold.level_index),
		"energy": F2P.energy(),
		"card_buttons": _card_buttons(),
		"results_visible": _results_open,
		"combo": Juice.combo,
		"score": Juice.score,
		"coco_line": _coco_text.text if _coco_bubble != null and _coco_bubble.visible else "",
		"reduced_motion": Juice.reduced_motion,
	}), true)


## Names of the buttons on whatever card is up (read-only, for the browser driver).
func _card_buttons() -> Array:
	var out := []
	if _win.visible:
		for b in _win.find_children("*", "Button", true, false):
			out.append(str(b.name))
	return out


# --- Nutaku F2P (scripts/f2p.gd holds the attempt; the server holds everything else) --------

## Undo: one free per attempt on Nutaku, more cost an undo token (bought on the spot).
func _try_undo() -> bool:
	if not F2P.on():
		return Fold.undo()
	if Fold.history.is_empty() or Fold.done:
		return false
	if not F2P.can_undo():
		var r := await F2P.use("undo")
		if not r["ok"]:
			_hint.text = "No undo: %s" % r["reason"]
			return false
	if Fold.undo():
		F2P.on_undo()
		return true
	return false


## Out of moves is checked a frame after the move, once Fold has had its chance to call
## the level solved.
func _f2p_check_budget() -> void:
	if not is_instance_valid(self) or Fold.done or not F2P.out_of_moves():
		return
	var more := func(status: Label):
		status.text = "…"
		var r := await F2P.use("moves")
		if r["ok"]:
			_win.visible = false
			_sync()
		else:
			status.text = str(r["reason"])
	var retry := func(_s: Label): _f2p_retry()
	var home := func(_s: Label):
		await F2P.give_up()
		_to_map()
	var cost := "1 token" if F2P.tokens("moves") > 0 else F2PUI.gold(F2P.SKU_MOVES)
	F2PUI.card(_win, "Out of moves", ["%d moves spent. Five more keep this board as it is." % F2P.spent()],
		[["+5 moves · %s" % cost, "Primary", more, "MoreMoves"],
		 ["Retry (1 candle)", "Amber", retry, "Retry"],
		 ["Map", "Ghost", home, "Map"]])


## Reset on Nutaku is a new attempt: the old one is given up, the new one costs a candle
## (unless the level is already cleared, when replays are free).
func _f2p_retry() -> void:
	await F2P.give_up()
	Tier.streak_break()
	_open(Fold.level_index)


func _f2p_no_candles(level: int) -> void:
	var refill := func(status: Label):
		status.text = "Waiting for Nutaku…"
		var r := await Nutaku.buy(F2P.SKU_REFILL)
		status.text = F2PUI._pay_text(r)
		if str(r.get("status", "")) == "success":
			_open(level)
	var one := func(status: Label):
		status.text = "Waiting for Nutaku…"
		var r := await Nutaku.buy(F2P.SKU_CANDLE)
		status.text = F2PUI._pay_text(r)
		if str(r.get("status", "")) == "success":
			_open(level)
	var wait := func(_s: Label): _to_map()
	F2PUI.card(_win, "Out of candles",
		["No candles left. " + F2P.candle_text(), "Candles come back on their own; the level waits."],
		[["Refill · %s" % F2PUI.gold(F2P.SKU_REFILL), "Primary", refill, "Refill"],
		 ["One candle · %s" % F2PUI.gold(F2P.SKU_CANDLE), "Amber", one, "Candle"],
		 ["Wait", "Ghost", wait, "Map"]])


func _f2p_hint() -> void:
	if not F2P.active_for(Fold.level_index) or Fold.done:
		return
	var r := await F2P.use("hint")
	if not r["ok"]:
		_hint.text = "No hint: %s" % r["reason"]
		return
	var mv := str((r["hint"] as Dictionary).get("move", ""))
	var word: String = {"U": "UP", "D": "DOWN", "L": "LEFT", "R": "RIGHT"}.get(mv, "?")
	_sync()
	_hint.text = "Hint: fold %s" % word


func _f2p_error(msg: String) -> void:
	var home := func(_s: Label): _to_map()
	F2PUI.card(_win, "Server", [msg], [["Map", "Amber", home, "Map"]])


# --- juice (2026-09-23) ---------------------------------------------------------------------------
#
# The feel layer: the combo counter, the score pop, the level-start card, the results card
# and Coco's corner. It never decides anything: Fold says what happened, Juice counts the
# score from it (deterministically, see scripts/juice.gd), and this draws it. Everything
# motion-heavy checks Juice.reduced_motion. No Light2D is added here (the lamp predates
# this pass).

func _star_sum() -> int:
	var n := 0
	for i in range(Fold.level_count()):
		n += Save.stars_at(i)
	return n


func _build_fx() -> void:
	_fx = CanvasLayer.new()
	_fx.layer = 3
	add_child(_fx)
	var root := Control.new()
	root.theme = StudioTheme.build()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.add_child(root)

	_combo_lbl = StudioTheme.display_label("", 44, Palette.EPIC)
	_combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_lbl.add_theme_color_override("font_outline_color", Palette.INK)
	_combo_lbl.add_theme_constant_override("outline_size", 10)
	_combo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_lbl.visible = false
	root.add_child(_combo_lbl)

	# the level-start card: non-blocking, the board takes input underneath it
	_start_card = PanelContainer.new()
	_start_card.theme_type_variation = "Glass"
	_start_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_card.visible = false
	var sc := VBoxContainer.new()
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.add_theme_constant_override("separation", 2)
	_start_card.add_child(sc)
	var l1 := StudioTheme.display_label("", 40, Palette.GOLD)
	l1.name = "Head"
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.add_child(l1)
	var l2 := StudioTheme.serif_label("", 20, Palette.TEXT, true)
	l2.name = "Goal"
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.add_child(l2)
	root.add_child(_start_card)

	# the results overlay (tap anywhere skips; see _unhandled_input)
	_results = Control.new()
	_results.theme = StudioTheme.build()
	_results.set_anchors_preset(Control.PRESET_FULL_RECT)
	_results.visible = false
	_results.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Palette.GROUND_DEEP, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_results.add_child(dim)
	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_results.add_child(centre)
	root.add_child(_results)

	# Coco's corner: her portrait (the key visual's lead, cropped) and a subtitle bubble
	var coco_layer := CanvasLayer.new()
	coco_layer.layer = 6
	add_child(coco_layer)
	_coco_box = Control.new()
	_coco_box.theme = StudioTheme.build()
	_coco_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coco_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	coco_layer.add_child(_coco_box)
	var ring := Panel.new()
	var rs := StudioTheme.flat(Palette.ACCENT, Palette.GOLD, 60, 4)
	ring.add_theme_stylebox_override("panel", rs)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2(104, 104)
	ring.position = Vector2(-4, -4)
	_coco_box.add_child(ring)
	_coco_pic = TextureRect.new()
	if ResourceLoader.exists("res://assets/companion/coco.png"):
		_coco_pic.texture = load("res://assets/companion/coco.png")
	_coco_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coco_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_coco_pic.size = Vector2(96, 96)
	_coco_pic.pivot_offset = Vector2(48, 96)
	_coco_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coco_box.add_child(_coco_pic)
	var name_tag := StudioTheme.display_label("Coco", 16, Palette.ACCENT_DEEP)
	name_tag.position = Vector2(26, 98)
	name_tag.add_theme_color_override("font_outline_color", Palette.INK)
	name_tag.add_theme_constant_override("outline_size", 6)
	_coco_box.add_child(name_tag)
	_coco_bubble = PanelContainer.new()
	_coco_bubble.theme_type_variation = "Paper"
	_coco_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coco_bubble.position = Vector2(108, 14)
	_coco_bubble.visible = false
	_coco_text = StudioTheme.serif_label("", 17, Palette.INK, true)
	_coco_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coco_text.custom_minimum_size = Vector2(230, 0)
	_coco_bubble.add_child(_coco_text)
	_coco_box.add_child(_coco_bubble)
	get_viewport().size_changed.connect(_place_coco)
	_place_coco()


func _place_coco() -> void:
	if _coco_box == null:
		return
	var vp := get_viewport_rect().size
	var small := vp.x < 760
	_coco_box.scale = Vector2.ONE * (0.7 if small else 1.0)
	# over a scene she moves to the top-left, off the plate's caption and its buttons
	if _viewer != null:
		_coco_box.position = Vector2(18, 18)
	else:
		_coco_box.position = Vector2(18, vp.y - (170.0 if small else 236.0))


func _on_coco_said(_slot: String, text: String, secs: float) -> void:
	if _coco_text == null:
		return
	_coco_text.text = text
	_coco_bubble.visible = true
	_coco_hide_at = _t + secs + 1.4
	if Juice.reduced_motion:
		return
	_coco_bubble.pivot_offset = Vector2(0, 30)
	var tw := create_tween()
	tw.tween_property(_coco_bubble, "scale", Vector2.ONE, 0.22).from(Vector2(0.6, 0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var hop := create_tween()
	hop.tween_property(_coco_pic, "scale", Vector2(1.08, 0.94), 0.08)
	hop.tween_property(_coco_pic, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Pickup: every piece squashes a little under the finger; drop springs it back.
func _pickup(down: bool) -> void:
	if down:
		Sfx.cue("select", 1.0, -4.0)
	if Juice.reduced_motion or Fold.done:
		return
	for id in _sprites.keys():
		var node: Node2D = _sprites[id]
		if not is_instance_valid(node):
			continue
		var tw := create_tween()
		if down:
			tw.tween_property(node, "scale", Vector2(1.07, 0.93), 0.07).set_trans(Tween.TRANS_SINE)
		else:
			tw.tween_property(node, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _show_combo(c: int) -> void:
	var word := Juice.combo_word(c)
	if word == "":
		return
	_combo_lbl.text = word
	_combo_lbl.visible = true
	_combo_lbl.add_theme_font_size_override("font_size", 38 + 6 * mini(c, 6))
	var vp := get_viewport_rect().size
	_combo_lbl.size = Vector2(vp.x, 80)
	# over the top rows of the tray: above it is the HUD's goal line, which it must not hide
	_combo_lbl.position = Vector2(0, _table.position.y + 36.0)
	_combo_lbl.pivot_offset = Vector2(vp.x * 0.5, 40)
	_combo_lbl.modulate = Color(1, 1, 1, 1)
	var col: Color = [Palette.EPIC, Palette.GOLD, Palette.HEAT, Palette.ACCENT][mini(c, 5) - 2]
	_combo_lbl.add_theme_color_override("font_color", col)
	if Juice.reduced_motion:
		return
	var tw := create_tween()
	tw.tween_property(_combo_lbl, "scale", Vector2.ONE, 0.25).from(Vector2(1.6, 1.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_combo_lbl, "rotation", 0.0, 0.25).from(deg_to_rad(-6.0 if c % 2 == 0 else 6.0))


func _hide_combo() -> void:
	if _combo_lbl == null or not _combo_lbl.visible:
		return
	var tw := create_tween()
	tw.tween_property(_combo_lbl, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): _combo_lbl.visible = false)


## "+48" rising off the board, and the HUD score bumps.
func _score_pop(points: int) -> void:
	if points <= 0:
		return
	var l := StudioTheme.display_label("+%d" % points, 26 + mini(Juice.combo, 5) * 3, Palette.EPIC)
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_fx.get_child(0) as Control).add_child(l)
	l.position = _origin + Vector2(-30, -40)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - (0.0 if Juice.reduced_motion else 60.0), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.tween_callback(l.queue_free)
	_bump(_score_lbl)


func _bump(c: Control, k: float = 1.3) -> void:
	if c == null or Juice.reduced_motion:
		return
	c.pivot_offset = c.size * 0.5
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(k, k), 0.07)
	tw.tween_property(c, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Near-fail: once per board, when the move budget is nearly spent (Nutaku) or the next
## move costs a star. The move counter pulses and Coco reassures.
func _check_near_fail() -> void:
	if _near_fail_said or Fold.done:
		return
	var low := false
	if F2P.on() and F2P.active_for(Fold.level_index):
		low = F2P.moves_left() <= 3 and F2P.moves_left() > 0
	else:
		low = Fold.moves == Fold.par() + 2 and Fold.tiles.size() > 1
	if not low:
		return
	_near_fail_said = true
	Coco.say("near_fail", true)
	_moves.add_theme_color_override("font_color", Palette.HEAT)
	if not Juice.reduced_motion:
		var tw := create_tween().set_loops(3)
		tw.tween_property(_moves, "modulate", Color(1.4, 0.8, 0.8), 0.18)
		tw.tween_property(_moves, "modulate", Color.WHITE, 0.18)
	var back := create_tween()
	back.tween_interval(2.4)
	back.tween_callback(func():
		if is_instance_valid(_moves):
			_moves.add_theme_color_override("font_color", Palette.TEXT))


func _show_start_card() -> void:
	var head := _start_card.find_child("Head", true, false) as Label
	var goal := _start_card.find_child("Goal", true, false) as Label
	head.text = "%s %d" % [I18n.t("level"), Fold.level_index + 1]
	goal.text = "%s   ·   %s" % [I18n.f("goal", Fold.target()), I18n.f("parhint", Fold.par())]
	var alt := Juice.goal_text(Fold.level_index)
	if alt != "":
		head.text += "  ·  BONUS GOAL"
		goal.text = "%s   +   %s" % [I18n.f("goal", Fold.target()), alt]
	_start_card.visible = true
	_start_card.modulate = Color(1, 1, 1, 1)
	_start_card.reset_size()
	var vp := get_viewport_rect().size
	_start_card.position = Vector2((vp.x - _start_card.size.x) * 0.5, vp.y * 0.36)
	_start_card.pivot_offset = _start_card.size * 0.5
	Sfx.cue("start", 1.0, -3.0)
	var tw := create_tween()
	if not Juice.reduced_motion:
		tw.tween_property(_start_card, "scale", Vector2.ONE, 0.22).from(Vector2(0.7, 0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.85)
	tw.tween_property(_start_card, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): _start_card.visible = false)


## Wait `t` seconds, or less if the player tapped to skip.
func _wait(t: float) -> void:
	var end := Time.get_ticks_msec() + int(t * 1000.0)
	while is_instance_valid(self) and Time.get_ticks_msec() < end and not _results_skip:
		await get_tree().process_frame


func _show_results(stars: int, move_count: int, p: int, gained: int, before: int) -> void:
	_start_card.visible = false
	var centre := _results.get_node("Centre") as CenterContainer
	for c in centre.get_children():
		c.queue_free()
	var card := PanelContainer.new()
	card.theme_type_variation = "Glass"
	card.custom_minimum_size = Vector2(380, 0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var cheer: String = ["", "Cleared!", "Great!", "Perfect!"][clampi(stars, 1, 3)]
	var h := StudioTheme.display_label(cheer, 46, Palette.ACCENT_DEEP)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(h)
	var lv := StudioTheme.mono_label("%s %d" % [I18n.t("level").to_upper(), Fold.level_index + 1], 14, Palette.MUTED)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lv)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var star_nodes: Array[Label] = []
	for i in range(3):
		var s := StudioTheme.display_label("☆", 54, Palette.star_color(false))
		s.pivot_offset = Vector2(24, 30)
		row.add_child(s)
		star_nodes.append(s)
	var score := StudioTheme.display_label("0", 40, Palette.EPIC)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(score)
	var stat := StudioTheme.serif_label("%s   ·   %s" % [I18n.f("moves", move_count), I18n.f("parhint", p)], 14, Palette.MUTED)
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(stat)
	var tap := StudioTheme.mono_label("tap to continue", 12, Palette.FAINT)
	tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tap)

	_results_skip = false
	_results.visible = true
	var rm := Juice.reduced_motion
	card.pivot_offset = Vector2(190, 120)
	if not rm:
		create_tween().tween_property(card, "scale", Vector2.ONE, 0.2).from(Vector2(0.85, 0.85)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(0.0 if rm else 0.18)

	# 1. the stars, one at a time, each a note higher
	for i in range(stars):
		if not is_instance_valid(self) or _results_skip:
			break
		_light_star(star_nodes[i], i, not rm)
		await _wait(0.0 if rm else 0.26)

	# 2. the score counts up, ticking
	var final_score := Juice.score
	if not rm and not _results_skip and final_score > 0:
		var steps := 12
		for k in range(1, steps + 1):
			if not is_instance_valid(self) or _results_skip:
				break
			score.text = str(int(round(final_score * float(k) / steps)))
			Sfx.cue("tick", 1.0 + 0.5 * float(k) / steps, -6.0)
			await _wait(0.05)

	# 3. the new stars fly into the HUD counter, which bumps as each lands
	if not is_instance_valid(self):
		return
	if gained > 0 and not rm and not _results_skip:
		Sfx.cue("fly", 1.0, -3.0)
		var root := _fx.get_child(0) as Control
		var dest := _stars_total.get_global_rect().get_center()
		for i in range(gained):
			var from := star_nodes[stars - gained + i].get_global_rect().get_center()
			var fl := StudioTheme.display_label("★", 40, Palette.GOLD)
			fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(fl)
			fl.position = from - Vector2(18, 26)
			var mid := (from + dest) * 0.5 + Vector2(0, -90)
			var tw := create_tween()
			tw.tween_method(_fly_step.bind(fl, from, mid, dest), 0.0, 1.0, 0.45).set_delay(0.08 * i).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(_fly_land.bind(fl, before + i + 1, i))
		await _wait(0.45 + 0.08 * gained + 0.1)

	# the end state, whether it was reached or skipped to
	if not is_instance_valid(self):
		return
	for i in range(stars):
		if star_nodes[i].text != "★":
			_light_star(star_nodes[i], i, false)
	score.text = str(final_score)
	_stars_shown = _star_sum()
	_stars_total.text = "★ %d" % _stars_shown

	# 4. hold for a beat; a tap moves on at once
	_results_skip = false
	_results_open = true
	await _wait(0.6 if rm else 0.9)
	if not is_instance_valid(self):
		return
	_results_open = false
	_results_skip = false
	_results.visible = false


var _stars_shown := 0


func _fly_step(u: float, fl: Label, from: Vector2, mid: Vector2, dest: Vector2) -> void:
	if not is_instance_valid(fl):
		return
	var a := from.lerp(mid, u)
	var b := mid.lerp(dest, u)
	fl.position = a.lerp(b, u) - Vector2(18, 26)
	fl.scale = Vector2.ONE * lerpf(1.0, 0.6, u)


func _fly_land(fl: Label, total: int, i: int) -> void:
	if is_instance_valid(fl):
		fl.queue_free()
	if not is_instance_valid(_stars_total):
		return
	_stars_shown = maxi(_stars_shown, total)
	_stars_total.text = "★ %d" % _stars_shown
	_bump(_stars_total, 1.5)
	Sfx.cue("bump", 1.0 + 0.1 * i, -2.0)


func _light_star(s: Label, i: int, animate: bool) -> void:
	s.text = "★"
	s.add_theme_color_override("font_color", Palette.star_color(true))
	if animate:
		Sfx.star(i + 1)
		var tw := create_tween()
		tw.tween_property(s, "scale", Vector2.ONE, 0.3).from(Vector2(2.0, 2.0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(s, "rotation", 0.0, 0.3).from(deg_to_rad(-25.0))
		_sparkle(s.get_global_rect().get_center(), Palette.GOLD, 12, 0.8, _fx.get_child(0))

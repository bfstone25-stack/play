extends Control
## The board.
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
var _swipe_px := 26.0


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
	wash.color = Color(Palette.GROUND, 0.62)
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
	vg.colors = PackedColorArray([Color(Palette.GOLD_PALE, 0.0), Color(Palette.GOLD_PALE, 0.0), Color(Palette.GOLD_PALE, 0.35)])
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
func _sparkle(at: Vector2, color: Color, amount: int = 14, spread: float = 1.0) -> void:
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
	_board.add_child(ps)
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_instance_valid(ps):
			ps.queue_free())


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
	mark.mark = I18n.lang
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
		mark.mark = I18n.lang
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
		if Fold.undo():
			Sfx.slide()
			_rebuild_pieces()
			_sync())
	btns.add_child(_undo_btn)

	_reset_btn = Button.new()
	_reset_btn.theme_type_variation = "Amber"
	_reset_btn.pressed.connect(func():
		Fold.reset()
		Sfx.slide()
		_rebuild_pieces()
		_sync())
	btns.add_child(_reset_btn)

	var lv := Button.new()
	lv.name = "Levels"
	lv.theme_type_variation = "Amber"
	lv.pressed.connect(func(): _show_picker(true))
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
	_moves.text = I18n.f("moves", Fold.moves) + "   ·   " + I18n.f("parhint", Fold.par())
	_lvname.text = "%d · %s" % [Fold.level_index + 1, Fold.level_name(Fold.level_index, I18n.lang)]
	_undo_btn.text = I18n.t("undo")
	_undo_btn.disabled = Fold.history.is_empty() or Fold.done
	_reset_btn.text = I18n.t("reset")
	_hint.text = I18n.t("hint")
	var top := _hud.get_child(0).get_child(0).get_child(0)
	(top.get_node("Lang") as Button).text = "中文" if I18n.lang == "en" else "EN"
	(top.get_node("Sound") as Button).text = "♪" if Sfx.sfx_on else "✕"
	var lvb := _undo_btn.get_parent().get_node("Levels") as Button
	lvb.text = "%s %d/%d" % [I18n.t("level"), Fold.level_index + 1, Fold.level_count()]
	# the three stars: how well this level has ever been done
	for c in _stars_row.get_children():
		c.queue_free()
	var best := Save.stars_at(Fold.level_index)
	for i in range(3):
		var s := StudioTheme.display_label("★" if i < best else "☆", 20, Palette.star_color(i < best))
		_stars_row.add_child(s)


# --- opening a level ------------------------------------------------------------------------------

func _open(i: int) -> void:
	# The ad gate. Levels 1-50 are free on every track; past that the page decides —
	# a price on itch, a sponsor clip on free.blazecore.dev. shared/godot/gate.gd returns
	# true off the web and on a page with no gate.js, so a local build never bricks.
	if i >= Fold.FREE_LEVELS and has_node("/root/Gate"):
		var gate := get_node("/root/Gate")
		if not gate.has("lv%d" % i):
			var okay: bool = await gate.require("lv%d" % i, "%s %d" % [I18n.t("level"), i + 1], "level")
			if not okay:
				return
	Fold.load_level(i)
	Save.set_current_level(i)
	_win.visible = false
	_relayout()
	_sync()
	Tel.level_ev("level_opened")


func _to_title() -> void:
	Sfx.slide()
	var scene: PackedScene = load("res://scenes/title.tscn")
	var node := scene.instantiate()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	queue_free()


# --- a fold ------------------------------------------------------------------------------------

func _on_moved(direction: Vector2i, merge_count: int) -> void:
	if merge_count > 0:
		Sfx.merge(merge_count)
	else:
		Sfx.slide()
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
			tw.tween_property(gone, "scale", Vector2(0.4, 0.4), 0.13)
			tw.tween_property(gone, "modulate:a", 0.0, 0.13)
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
		tw.tween_property(node, "position", want, 0.17)
		node.z_index = 10 + int(t["r"])
		if bool(t.get("merged", false)):
			t["merged"] = false
			PieceView.repaint(node, int(t["v"]), _cs * _row_k(int(t["r"])), 1.0, true)
			var pop := create_tween()
			pop.tween_property(node, "scale", Vector2(1.22, 1.22), 0.09).set_delay(0.08)
			pop.tween_property(node, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			# and it throws sparks in its own colour, so a merge is visible even if the
			# player's eye was somewhere else on the board
			var face := Palette.tile_face(int(t["v"]))
			get_tree().create_timer(0.09).timeout.connect(func():
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
	tw.tween_property(_crease, "position", to * float(direction.x + direction.y) * -1.0, 0.22)
	tw.tween_property(_crease, "default_color", Color(Palette.CREAM, 0.95), 0.06)
	tw.chain().tween_property(_crease, "default_color", Color(Palette.CREAM, 0.0), 0.18)


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
	tw.tween_property(_board, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# --- winning -------------------------------------------------------------------------------------

func _on_solved(stars: int, move_count: int, p: int) -> void:
	Sfx.unity(stars)
	_win_burst(stars)
	Save.record(Fold.level_index, stars)
	Tel.level_ev("level_completed", {"moves": move_count, "stars": stars, "par": p})
	_sync()
	await get_tree().create_timer(0.55).timeout
	_show_win(stars, move_count, p)


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
	if _board_offered or not has_node("/root/Gate"):
		return
	_board_offered = true
	get_node("/root/Gate").board_offer_more("casual")


func _share(stars: int, move_count: int) -> void:
	var name := Fold.level_name(Fold.level_index, I18n.lang)
	var txt := "%s · %s\n%s%s  %s\napps.blazecore.dev/fold/" % [
		I18n.WORDMARK[I18n.lang] + (" FOLD" if I18n.lang == "zh" else ""),
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
	if _win.visible or _picker.visible:
		if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
			_show_picker(false)
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
		if Fold.undo():
			_rebuild_pieces()
			_sync()
	elif e.is_action_pressed("fold_reset"):
		Fold.reset()
		_rebuild_pieces()
		_sync()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_to_title()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_drag_from = (e as InputEventMouseButton).position
			_dragging = true
		elif _dragging:
			_dragging = false
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
		"plates_missing": Art.missing(),
	}), true)

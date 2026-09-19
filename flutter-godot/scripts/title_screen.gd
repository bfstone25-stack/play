extends Control
class_name TitleScreen

## Flutter's title screen, in the engine — ops/adult_forks/TITLE_SCREENS.md, mainstream
## track. This is the first thing of Flutter's that is not HTML.
##
## Why the composition is not Floor 13's. That title screen gives the right 38% of the
## frame to an ink column and puts every piece of type in it, because its key visual is a
## corridor with an empty wall in it. Flutter's key visual is a face at a café table:
## there is no empty third to take, and taking one would mean cropping him out of his own
## title. So the type is arranged the other way round —
##
##   the mark     centred, in the upper third, over the quietest band of the picture
##   the menu     a RAIL along the foot, left to right, on a baked lit band
##   the marks    bottom right, small
##
## which is also what item 4 asks for in the first place: "positioned in the composition
## rather than stacked in a column".
##
## Layers, back to front:
##
##   ink        a flat plum floor, so a webp that fails to load is still a designed screen
##   kv         the key visual: a slow drift, a ~1.5% swell, and a little of the pointer.
##              Landscape and portrait are two different crops and the aspect chooses.
##   glow       the table lamp's warmth, breathing out of phase with the drift — the
##              "light moves" half of item 3. A baked radial texture added over the
##              picture: not a shader, because on the WEB export the fork's shaders drew
##              nothing at all (title_logotypes.py), and not a ColorRect, because an
##              additive ColorRect is a visible rectangle, which is what it was until the
##              first frame of this screen was captured and looked at.
##   motes      dust in the lamplight, two sheets at different speeds — the parallax
##   overlay    ONE baked RGBA plate (ops/title_logotypes_mainstream.py: overlay_flutter)
##              carrying the vignette and the foot band the menu sits on
##   logotype   the designed mark, settling in from below over ~1.4 s
##   rail       the menu, and the studio line
##
## Sound is assets/sfx/, rendered by ops/title_sfx_flutter.py: a sting on arrival, a tick
## on hover and a lower one on press.
##
## MAINSTREAM. The studio line is "blazeCore Play" alone — no 18+ badge, and no Flat 404,
## which is the adult label. Nothing on this screen may name or imply the fork.

const KV_LAND := "res://assets/title/keyvisual.webp"
const KV_PORT := "res://assets/title/keyvisual_portrait.webp"
const LOGO_PATH := "res://assets/title/logotype.png"
const OVERLAY_PATH := "res://assets/title/overlay.png"
const LAMP_PATH := "res://assets/title/lamp.png"

## The faces ship inside the export and are held for the life of the node.
##
## `_fonts` is not decoration. A FontFile that nothing holds a reference to is freed on the
## web export, and a fallback set on a freed FontFile takes the fallback with it — that is
## the `godot-web-font-fallback` defect, and it shows up as Chinese rendering to boxes on
## the web build and nowhere else. So: preload, keep, and set the CJK fallback on the kept
## object.
const FONT_MENU := preload("res://assets/fonts/WorkSans-Regular.ttf")
const FONT_MENU_B := preload("res://assets/fonts/WorkSans-Bold.ttf")
const FONT_CJK := preload("res://assets/fonts/wqy-microhei.ttc")

## The design canvas — TWO of them, and the aspect picks.
##
## One base size does not work here. Godot's "expand" stretch scales by the SMALLER of
## window/base on the two axes, so a 1280x720 base on a 390x844 phone scales everything by
## 390/1280 = 0.30: the captured portrait frame came back with a menu roughly six pixels
## tall, unreadable, while the same build was fine on the desktop. That is the defect the
## 390 px check in TITLE_SCREENS.md exists to find, and it found it.
##
## So the base is swapped with the orientation. 540x1080 is a phone's canvas: at 390 wide
## the scale is 0.72 and the menu comes out at a readable size instead of a sixth of one.
const BASE_LAND := Vector2i(1280, 720)
const BASE_PORT := Vector2i(540, 1080)

## Framing of the key visual. 1.06 is the room the drift and the swell need; any less and
## the picture's own edge walks into frame at the extremes of the breath.
const KV_SCALE := 1.06

## The foot rail. RAIL_Y is where the type sits; the baked band in overlay.png starts
## fading in at 0.68 of the height and is solid by 0.82, so the rail has to live below
## that or it floats on the picture instead of on its surface.
const RAIL_Y := 0.845
const RAIL_X := 0.068

var bg: TextureRect
var glow: TextureRect
var logo: TextureRect
var overlay: TextureRect
var rail: Control
var motes_far: CPUParticles2D
var motes_near: CPUParticles2D

var _fonts := [FONT_MENU, FONT_MENU_B, FONT_CJK]
var _t := 0.0
var _ptr := Vector2.ZERO        # where the pointer is pulling, in canvas units
var _ptr_at := Vector2.ZERO     # where the picture has actually got to (eased)
var _portrait := false
var _sfx := {}

signal chose(action: String)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	# Gate.require() pauses the tree, and a node on PROCESS_MODE_INHERIT gets no _process
	# at all while paused. That is how the fork's web title once shipped frozen at frame
	# one — measured there, not guessed. This screen keeps breathing regardless.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wire_fonts()
	_build()
	_layout()
	get_viewport().size_changed.connect(_layout)
	call_deferred("play_in")


func _wire_fonts() -> void:
	## One CJK fallback, set on the held objects. 怦然 in the subtitle and every zh/ja
	## edition of the menu comes through here; without it they are boxes on the web build
	## and correct everywhere else, which is the worst way for a bug to behave.
	for f in [FONT_MENU, FONT_MENU_B]:
		var fb: Array = f.fallbacks.duplicate()
		if not fb.has(FONT_CJK):
			fb.append(FONT_CJK)
			f.fallbacks = fb


# --------------------------------------------------------------------------------------
func _build() -> void:
	var ink := ColorRect.new()
	ink.color = Color("#1c0a16")
	ink.set_anchors_preset(Control.PRESET_FULL_RECT)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)

	bg = TextureRect.new()
	bg.name = "KeyVisual"
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cooled a touch and pulled down. These renders come back high-key — the checkpoint
	# blows its own highlights on a warm interior — and a title screen wants dusk.
	bg.modulate = Color(0.90, 0.86, 0.93)
	add_child(bg)

	# The lamp. Additive, off-centre left where the table lamp is in the frame, breathing
	# on a slower period than the drift so the two never sync into a single pulse.
	#
	# This was an additive ColorRect until the first frame was captured and looked at, and
	# an additive ColorRect is a hard-edged pale BOX across the top left of the screen — a
	# code-drawn shape, which is the second of the studio rules of 2026-09-18. The falloff
	# is baked now (ops/title_logotypes_mainstream.py: lamp_flutter) and the only thing
	# animated is how much of it there is.
	glow = TextureRect.new()
	glow.name = "LampGlow"
	if ResourceLoader.exists(LAMP_PATH):
		glow.texture = load(LAMP_PATH)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.modulate = Color(1, 1, 1, 0.10)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = gm
	add_child(glow)

	motes_far = _motes(46, 5.0, 1.6, 0.11)
	add_child(motes_far)
	motes_near = _motes(26, 11.0, 3.4, 0.20)
	add_child(motes_near)

	overlay = TextureRect.new()
	overlay.name = "Overlay"
	if ResourceLoader.exists(OVERLAY_PATH):
		overlay.texture = load(OVERLAY_PATH)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	logo = TextureRect.new()
	logo.name = "Logotype"
	if ResourceLoader.exists(LOGO_PATH):
		logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	# A plain Control, not an HBoxContainer: the rail is one row of four in landscape and
	# a 2x2 block in portrait, and no box container wraps. _layout() places the children.
	rail = Control.new()
	rail.name = "Rail"
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rail)
	for spec in _menu_items():
		rail.add_child(_rail_item(spec[0], spec[1]))

	var marks := Label.new()
	marks.name = "StudioMark"
	# Mainstream: the studio line and nothing else. No rating badge, no Flat 404.
	marks.text = "blazeCore Play"
	marks.add_theme_font_override("font", FONT_MENU_B)
	marks.add_theme_font_size_override("font_size", 15)
	marks.add_theme_color_override("font_color", Color(0.94, 0.84, 0.71, 0.74))
	marks.add_theme_constant_override("outline_size", 5)
	marks.add_theme_color_override("font_outline_color", Color(0.09, 0.03, 0.08, 0.85))
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marks)

	for key in ["title_sting", "hover", "press"]:
		var p := "res://assets/sfx/%s.wav" % key
		if not ResourceLoader.exists(p):
			continue
		var pl := AudioStreamPlayer.new()
		pl.stream = load(p)
		pl.process_mode = Node.PROCESS_MODE_ALWAYS
		pl.bus = "Master"
		add_child(pl)
		_sfx[key] = pl


func _menu_items() -> Array:
	## The rail, left to right, in the order a returning player wants them. These are the
	## four things the web title actually offers (frontend/index.html #select): the route
	## cards, the memory archive, the opening replay and the edition switch.
	##
	## Localisation is deliberately NOT here yet. The web build carries five editions and
	## the port has to inherit all five from one place, not grow a second copy of the
	## strings in GDScript — PORT_PLAN.md step 3. English is the fallback locale and this
	## is what ships until that step lands.
	return [
		["begin", "BEGIN"],
		["memories", "MEMORIES"],
		["opening", "OPENING"],
		["language", "LANGUAGE"],
	]


func _rail_item(action: String, label: String) -> Control:
	## One menu item: the word, a gold rule that grows under it on hover, and a hit area
	## big enough for a thumb. Not a Button — a Button brings a StyleBox, a focus ring and
	## a default font with it, and every one of those would have to be overridden away.
	var item := Control.new()
	item.name = action
	item.custom_minimum_size = Vector2(0, 54)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var text := Label.new()
	text.name = "Text"
	text.text = label
	text.add_theme_font_override("font", FONT_MENU_B)
	text.add_theme_font_size_override("font_size", 21)
	text.add_theme_color_override("font_color", Color(0.95, 0.87, 0.74, 0.86))
	# The outline is the legibility insurance. TITLE_SCREENS.md §"The playfield is not the
	# title screen": the baked band is the surface, and this is what keeps the word
	# readable at the right-hand end of the rail where the band has thinned out.
	text.add_theme_constant_override("outline_size", 7)
	text.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.07, 0.90))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Work Sans has no tracking control in Godot's theme, and a menu of un-tracked bold
	# caps reads as a web nav bar. A space between the letters is what stands in for
	# letter-spacing. Built with a loop rather than split("") — an empty delimiter is not
	# a documented way to split a String in Godot 4 and it is not worth finding out what
	# it does on the web export specifically.
	var spaced := ""
	for ch in label:
		spaced += ch + " "
	text.text = spaced.strip_edges()
	item.add_child(text)

	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.color = Color(0.86, 0.71, 0.44, 0.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(rule)

	item.resized.connect(func() -> void:
		var w: float = item.size.x
		rule.position = Vector2(w * 0.5, item.size.y - 13.0)
		rule.size = Vector2(0.0, 2.0))

	item.mouse_entered.connect(func() -> void: _hover(item, true))
	item.mouse_exited.connect(func() -> void: _hover(item, false))
	item.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			_press(item, action))
	return item


func _hover(item: Control, on: bool) -> void:
	var text: Label = item.get_node("Text")
	var rule: ColorRect = item.get_node("Rule")
	var w: float = item.size.x * 0.62
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(text, "theme_override_colors/font_color",
		Color(1.0, 0.94, 0.82, 1.0) if on else Color(0.95, 0.87, 0.74, 0.86), 0.18)
	# The rule grows from the middle out, so it reads as underlining the word rather than
	# sliding in from one side.
	tw.tween_property(rule, "size:x", w if on else 0.0, 0.22)
	tw.tween_property(rule, "position:x", item.size.x * 0.5 - (w * 0.5 if on else 0.0), 0.22)
	tw.tween_property(rule, "color:a", 0.95 if on else 0.0, 0.18)
	if on:
		_play("hover")


func _press(item: Control, action: String) -> void:
	_play("press")
	var text: Label = item.get_node("Text")
	var rule: ColorRect = item.get_node("Rule")
	# A flare and a thickening, not a move. The Text label is anchored to the item's full
	# rect, so tweening its position is a fight with the layout that the layout wins the
	# next time the window is resized — and on the web export that is every orientation
	# change. Colour and the rule's height are nobody else's to reset.
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(text, "theme_override_colors/font_color", Color(1, 1, 0.95, 1), 0.06)
	tw.chain().tween_property(text, "theme_override_colors/font_color",
		Color(1.0, 0.94, 0.82, 1.0), 0.22)
	tw.tween_property(rule, "size:y", 4.0, 0.06)
	tw.chain().tween_property(rule, "size:y", 2.0, 0.22)
	chose.emit(action)


func _play(key: String) -> void:
	if _sfx.has(key):
		_sfx[key].play()


func _motes(count: int, speed: float, scale_px: float, alpha: float) -> CPUParticles2D:
	## Dust in the lamplight. Two sheets, different speeds and sizes — that difference is
	## the parallax of item 3, and it is also what guarantees no two frames of this screen
	## are identical, which is the cheap proof that the motion is actually running.
	var p := CPUParticles2D.new()
	p.amount = count
	p.lifetime = 9.0
	p.preprocess = 9.0            # already drifting when the screen arrives
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(-0.25, -1.0)
	p.spread = 34.0
	p.gravity = Vector2(0, -3.0)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = scale_px * 0.5
	p.scale_amount_max = scale_px
	p.color = Color(1.0, 0.90, 0.72, alpha)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	return p


# --------------------------------------------------------------------------------------
func _layout() -> void:
	## Everything is placed here, in canvas units, and re-placed when the window changes
	## aspect. Containers would be less code, but the mark and the rail are positioned
	## against the *picture* (his face, the lamp), not against each other, and a container
	## cannot know where his face is.
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	# The base canvas is swapped before anything is measured, because changing it changes
	# what get_viewport_rect() returns — so this runs, then the size is read again below.
	var want := BASE_PORT if vp.x < vp.y * 0.95 else BASE_LAND
	var win := get_window()
	if win != null and win.content_scale_size != want:
		win.content_scale_size = want
		# The new canvas size lands next frame; come back then and lay out against it
		# rather than against the size we are halfway through replacing.
		call_deferred("_layout")
		return
	vp = get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return

	var portrait := vp.x < vp.y * 0.95
	if portrait != _portrait or bg.texture == null:
		_portrait = portrait
		var path := KV_PORT if portrait else KV_LAND
		if ResourceLoader.exists(path):
			bg.texture = load(path)
		elif ResourceLoader.exists(KV_LAND):
			bg.texture = load(KV_LAND)

	bg.size = vp
	bg.pivot_offset = vp * 0.5
	bg.scale = Vector2(KV_SCALE, KV_SCALE)

	# Sized off the HEIGHT in both axes so the round falloff stays round; a lamp that is
	# an ellipse because the window is wide reads as a smear.
	var gs: float = vp.y * 1.30
	glow.size = Vector2(gs, gs)
	glow.position = Vector2(vp.x * 0.16 - gs * 0.5, vp.y * 0.42 - gs * 0.5)

	for p in [motes_far, motes_near]:
		p.emission_rect_extents = Vector2(vp.x * 0.5, vp.y * 0.5)
		p.position = Vector2(vp.x * 0.5, vp.y * 0.62)

	overlay.size = vp
	overlay.position = Vector2.ZERO

	# The mark. Wider on a phone, because on a phone it is competing with nothing.
	#
	# The aspect is read off the texture, never written down here. The plate grew from
	# 1600x620 to 1900x860 the moment its baked ground needed margin to fade out in, and a
	# hardcoded ratio would have silently stretched the mark instead of saying so. A
	# logotype is the one thing on this screen that must never be distorted.
	var la := 620.0 / 1600.0
	if logo.texture != null:
		var ts := logo.texture.get_size()
		if ts.x > 0.0:
			la = ts.y / ts.x
	# The plate is bigger than the ink on it, so the on-screen width is a fraction of the
	# viewport chosen for the PLATE — the visible mark comes out narrower than this.
	var lw: float = vp.x * (0.98 if portrait else 0.62)
	var lh: float = lw * la
	logo.size = Vector2(lw, lh)
	# Off-centre in landscape. The installed frame has him left of centre with his head
	# high, and the quiet part of the picture is the dark café window on the RIGHT — so a
	# centred mark lands squarely across his eyes, which is where it was until this frame
	# was captured and read. 0.60 puts the mark over the window and leaves his face clear,
	# which is also item 4's "positioned in the composition" rather than centred by
	# default. Portrait stays centred: that crop is his face, with no quiet side to use.
	var lcx: float = 0.5 if portrait else 0.60
	# The portrait crop is a tight face with no quiet side, so the mark goes ABOVE the eyes
	# rather than beside them — at 0.14 it sat straight across them. The plate carries deep
	# margins (the ink occupies roughly the middle half of it), so this is nearer the top
	# of the frame than the number looks.
	logo.position = Vector2(vp.x * lcx - lw * 0.5, vp.y * (0.03 if portrait else 0.09))
	logo.pivot_offset = Vector2(lw * 0.5, lh * 0.5)

	# The rail. Left-anchored in landscape, where the baked band is heaviest; centred in
	# portrait, where there is no room to be off-centre and the band spans the width.
	var rw: float = vp.x * (1.0 - RAIL_X * 2.0)
	var kids := rail.get_children()
	var cols: int = 2 if portrait else kids.size()
	var rows: int = int(ceil(float(kids.size()) / float(max(1, cols))))
	var cell := Vector2(rw / float(max(1, cols)), 54.0)
	# In portrait the block is two rows, so it has to start higher than the single-row
	# rail or the second row runs off the bottom of the screen.
	var top: float = vp.y * (RAIL_Y - 0.075 * float(rows - 1))
	rail.position = Vector2(vp.x * RAIL_X, top)
	rail.size = Vector2(rw, cell.y * float(rows))
	for i in kids.size():
		var c := kids[i] as Control
		c.size = cell
		c.position = Vector2(cell.x * float(i % cols), cell.y * float(i / cols))

	var marks: Label = get_node("StudioMark")
	marks.size = Vector2(240, 22)
	marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	marks.position = Vector2(vp.x - 240.0 - vp.x * 0.02, vp.y - 34.0)


# --------------------------------------------------------------------------------------
func play_in() -> void:
	## Item 3: two to four seconds of life before anything is pressed. The mark settles up
	## from below and out of a blur; the rail comes in behind it, one word at a time, left
	## to right, so the eye is led along the rail instead of being handed four words at once.
	_play("title_sting")
	logo.modulate.a = 0.0
	logo.position.y += 26.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo, "modulate:a", 1.0, 1.10).set_delay(0.30)
	tw.tween_property(logo, "position:y", logo.position.y - 26.0, 1.40).set_delay(0.30)
	var i := 0
	for c in rail.get_children():
		var node := c as Control
		node.modulate.a = 0.0
		tw.tween_property(node, "modulate:a", 1.0, 0.55).set_delay(1.05 + i * 0.12)
		i += 1
	var marks := get_node("StudioMark") as Label
	marks.modulate.a = 0.0
	tw.tween_property(marks, "modulate:a", 1.0, 0.7).set_delay(1.7)


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	if vp.x <= 0.0:
		return
	# The breath: two sines on different periods, so the drift never repeats on a beat the
	# eye can catch. The pointer contribution is eased toward, not followed — a title
	# screen that tracks the cursor exactly feels like a web page, which is the whole
	# complaint this screen exists to answer.
	_ptr_at = _ptr_at.lerp(_ptr, 1.0 - pow(0.02, delta))
	var drift := Vector2(sin(_t * 0.17) * 11.0, cos(_t * 0.13) * 7.0)
	var swell := 1.0 + 0.015 * sin(_t * 0.21)
	bg.position = _ptr_at + drift
	bg.scale = Vector2(KV_SCALE * swell, KV_SCALE * swell)
	# The lamp breathes out of phase with the picture.
	glow.modulate.a = 0.085 + 0.045 * (0.5 + 0.5 * sin(_t * 0.29 + 1.1))
	# The near mote sheet takes a little of the same push, the far one almost none.
	motes_near.position.x = vp.x * 0.5 + _ptr_at.x * 0.5
	motes_far.position.x = vp.x * 0.5 + _ptr_at.x * 0.15


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport_rect().size
		if vp.x <= 0.0:
			return
		# Inverted and small: the picture moves *against* the pointer, a few pixels, the
		# way a parallax layer behind glass would.
		_ptr = Vector2(
			(event.position.x / vp.x - 0.5) * -26.0,
			(event.position.y / vp.y - 0.5) * -15.0)

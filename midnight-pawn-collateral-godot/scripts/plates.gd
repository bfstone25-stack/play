extends Control
class_name PlateLayer

## The plate layer. Ported from play/overnight-clause/scripts/plates.gd, which is where
## this pattern was first made to work in Godot; the only real change is that it sits over
## the 300x240 pixel stage rather than over a full-screen NVL root, so a reading is a
## picture that fills the scene window the shop was already drawn in.
##
## Written to fail safe: a missing plate file degrades to the scene playing with no
## picture, never to a crash and never to a black rectangle over the counter.

const DIR := "res://assets/plates/"
const PIXEL_DIR := "res://assets/pixel/"
const GALLERY_PATH := "user://gallery.cfg"

## What pick() resolved to. "real" and "open" are art; "locked" is the censored stand-in;
## "pixel" is the floor — a card built out of the game's own pixel assets, drawn when the
## slot has no PNG at all.
enum { SRC_OPEN, SRC_REAL, SRC_LOCKED, SRC_PIXEL }

var art: TextureRect
var badge: Label
var unlock: Unlock
var seen: Dictionary = {}
var current := ""
var current_locked := false
var current_source := SRC_OPEN
var treatment: ShaderMaterial


## The reading treatment.
##
## Blaze's question was whether a 1152x768 painted illustration dropped into a 300x240
## authored pixel room reads as the psychometry vision or as two art styles colliding.
## Looked at running: the *painted* part is not the problem — bg_shop.png sits behind the
## whole frame at 22% and reads as the same world, because it is dark and amber like the
## pixel art. What collides is value and saturation. cg_finial is a bright high-key
## daylight bedroom in white and cyan; the game is near-black and one oil lamp. Side by
## side they are two photographs, not one place.
##
## So the fix is a grade, not a re-render: desaturate a little, push the whole thing under
## the lamp, lift the blacks onto the shop's own ink, vignette the edges, and lay a
## two-line scanline on the plate at the pixel canvas's own 240-row grid so it sits on the
## same lattice as everything else. It costs one shader and it applies to every plate that
## has landed and every plate that has not been rendered yet.
## Added with the 2026-09-18 re-do: the treatment now *runs*.
##
## A plate is a psychometry vision, and a still painting hung in a moving room reads as a
## painting. The motion is deliberately not a Ken Burns drift — a slow zoom resamples the
## image every frame and softens exactly the grid the rest of the re-do fought for. It is
## instead the same layered-deformation idea the pixel stage uses, done in UV:
##
## * **the waver** — a slow sine in x whose amplitude is a couple of pixels, snapped to the
##   canvas lattice with floor(), so the picture shifts by whole pixels and never blurs.
##   Two sines at 0.31 Hz and 0.11 Hz, so it breathes rather than oscillates.
## * **the lamp** — the amber multiply flickers on the same two-period beat as the room's
##   oil lamp (pixel_stage.gd::_draw_lamp), which is what ties the vision to the shop it is
##   being seen in.
## * **the read band** — one soft bright horizontal band drifting up the frame every eleven
##   seconds. It is the only element that says *this is happening now, in her hand*, and it
##   is what makes the plate read as psychometry rather than as a CG.
## * the vignette now breathes a little with the lamp, so the edges of the frame move.
const TREATMENT := """
shader_type canvas_item;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float motion : hint_range(0.0, 1.0) = 1.0;
uniform vec2 canvas = vec2(640.0, 360.0);
uniform vec3 ink = vec3(0.063, 0.051, 0.094);
uniform vec3 lamp = vec3(1.0, 0.80, 0.52);
void fragment() {
	// Whole-pixel waver: compute the offset in canvas pixels, floor it, convert back.
	float px = (sin(TIME * 1.95) * 1.6 + sin(TIME * 0.69) * 1.1) * motion;
	float py = (sin(TIME * 1.31 + 1.7) * 1.2) * motion;
	vec2 off = vec2(floor(px) / canvas.x, floor(py) / canvas.y);
	vec4 src = texture(TEXTURE, UV + off);
	vec3 col = src.rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), 0.28 * amount);
	float flick = 1.0 + (0.055 * sin(TIME * 3.7) + 0.030 * sin(TIME * 14.6)) * motion;
	col = mix(col, col * lamp * flick, 0.55 * amount);
	col = mix(ink, col * 0.88, mix(1.0, 0.90, amount));
	// The read band: one soft rise travelling up the frame, eleven seconds a pass.
	float band = fract(-TIME * 0.09);
	float g = smoothstep(0.09, 0.0, abs(UV.y - band));
	col += vec3(0.055, 0.046, 0.030) * g * motion * amount;
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.80 + 0.02 * sin(TIME * 0.8) * motion, 0.28, length(d) * 1.30);
	col = mix(ink, col, mix(1.0, v, amount));
	col *= 1.0 - 0.09 * amount * step(1.0, mod(floor(UV.y * canvas.y), 2.0));
	COLOR = vec4(col, src.a);
}
"""


func _init() -> void:
	name = "PlateLayer"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	art = TextureRect.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Linear, and this is not a lapse in a pixel-art pass. A plate is a 1152x768 painting
	# shown in a 640x360 frame, so it is *downscaled* 1.8x; nearest downsampling of a
	# painting throws away five pixels in nine and returns aliasing and colour fringes —
	# which is exactly what the first full-bleed screenshot showed. The pixel lattice on a
	# plate comes from the treatment's scanline and its whole-pixel waver, not from the
	# sampler. The pixel floor, which *is* game art at game resolution, sets NEAREST back
	# in show_plate().
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = TREATMENT
	treatment = ShaderMaterial.new()
	treatment.shader = shader
	art.material = treatment
	add_child(art)
	badge = Label.new()
	badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_left = 4.0
	badge.offset_top = -16.0
	badge.offset_right = -4.0
	badge.offset_bottom = -2.0
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.78, 0.66, 0.5, 0.9))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	# The instance half of the gate: only the web track ever calls start()/redeem(), and a
	# desktop download therefore makes no network request of any kind.
	unlock = Unlock.new()
	add_child(unlock)
	_load_seen()


# ---- textures -------------------------------------------------------------

static func _from_disk(path: String) -> Texture2D:
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is Texture2D:
				return res
		if not FileAccess.file_exists(path):
			return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)


## The one decision this layer makes, and the mirror of cg_pick() in 09_dist.rpy:141.
## Returns [texture, locked]. Locked is true when the player is looking at the censored
## plate because the real one is not in this package.
func pick(id: String) -> Array:
	if Collateral.is_gated(id):
		var src := Unlock.source_for(id)
		if src != "":
			var tex := _from_disk(src)
			if tex != null:
				return [tex, false, SRC_REAL]
		var stand_in := _from_disk(DIR + id + "_locked.png")
		if stand_in != null:
			return [stand_in, true, SRC_LOCKED]
		# No censored stand-in either. ops/adult_forks/STATUS.md has carried empty slots
		# all day and cg_veil/cg_veil_locked are blocked on a reference only Blaze can
		# pick, so this is not a transient state to be tidied up later: it is the
		# permanent floor, and it has to be a picture.
		return [_pixel_fallback(id), true, SRC_PIXEL]
	var open_tex := _from_disk(DIR + id + ".png")
	if open_tex != null:
		return [open_tex, false, SRC_OPEN]
	# An ungated slot has no _locked partner by definition, so the pixel card is its floor
	# too. cg_tamsin is the one that matters: it is the free plate every browser player
	# sees first, and it has no art today.
	return [_pixel_fallback(id), false, SRC_PIXEL]


## The floor: the object, in the game's own pixel idiom, on the shop it is standing in.
##
## Built rather than loaded, so it cannot itself be a missing file. Nothing here can return
## null — a plate slot with no art shows the curio the client just put on the counter, 4x,
## over the darkened shop, which is a picture of exactly what is true: she is holding the
## thing and the vision did not come.
static func _pixel_fallback(id: String) -> Texture2D:
	var item := str(Collateral.PLATES.get(id, {}).get("item", ""))
	var ground := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	ground.fill(Color(0.063, 0.051, 0.094))
	var shop := _image_at(PIXEL_DIR + "scene_shop.png")
	if shop != null:
		# 22% of the shop, so it reads as the room she is standing in and never competes
		# with the object in front of it.
		for y in range(min(360, shop.get_height())):
			for x in range(min(640, shop.get_width())):
				ground.set_pixel(x, y, shop.get_pixel(x, y) * Color(0.22, 0.22, 0.26, 1.0))
	var curios := _image_at(PIXEL_DIR + "curios.png")
	var col: int = int(PixelStage.CURIO_COLUMNS.get(item, -1))
	if curios != null and col >= 0:
		var cell := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		cell.blit_rect(curios, Rect2i(col * 32, 32, 32, 32), Vector2i.ZERO)
		cell.resize(192, 192, Image.INTERPOLATE_NEAREST)
		ground.blend_rect(cell, Rect2i(0, 0, 192, 192), Vector2i(224, 60))
	return ImageTexture.create_from_image(ground)


static func _image_at(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var res := load(path)
	if res is Texture2D:
		return (res as Texture2D).get_image()
	return null


func show_plate(id: String) -> bool:
	var picked := pick(id)
	current = id
	current_locked = bool(picked[1])
	current_source = int(picked[2])
	if picked[0] == null:
		# Unreachable now that _pixel_fallback() cannot fail, and kept as the belt to its
		# braces: the scene still plays, the layer stays out of the way, never a hole.
		visible = false
		return false
	art.texture = picked[0]
	# The pixel floor is already the shop's own palette at the shop's own resolution, so it
	# gets the vignette and none of the grade.
	treatment.set_shader_parameter("amount", 0.35 if current_source == SRC_PIXEL else 1.0)
	treatment.set_shader_parameter("motion", 0.0 if current_source == SRC_PIXEL else 1.0)
	art.texture_filter = (CanvasItem.TEXTURE_FILTER_NEAREST if current_source == SRC_PIXEL
		else CanvasItem.TEXTURE_FILTER_LINEAR)
	visible = true
	match current_source:
		SRC_LOCKED: badge.text = "CENSORED IN THIS BUILD"
		SRC_PIXEL: badge.text = "The object goes quiet in her hand."
		_: badge.text = ""
	if current_source != SRC_PIXEL:
		# A slot with no art was never looked at, so the Ledger must not claim it was.
		_mark_seen(id)
	return not current_locked


func hide_plate() -> void:
	visible = false
	current = ""
	art.texture = null


# ---- gallery persistence --------------------------------------------------

func _load_seen() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GALLERY_PATH) != OK:
		return
	if not cfg.has_section("seen"):
		return
	for id in cfg.get_section_keys("seen"):
		seen[id] = bool(cfg.get_value("seen", id, false))


func _mark_seen(id: String) -> void:
	if bool(seen.get(id, false)):
		return
	seen[id] = true
	var cfg := ConfigFile.new()
	cfg.load(GALLERY_PATH)
	cfg.set_value("seen", id, true)
	cfg.save(GALLERY_PATH)


## What the Reading Ledger draws: every slot in story order, with the condition that earns
## it and whether this run has earned it. Refused slots stay greyed — that is the
## completionist hook and it is also the mitigation for hoarding, because the ledger is
## shown once while there is still an appraisal left to spend on.
func ledger_rows(run: CollateralCore.Run) -> Array:
	var conds := CollateralCore.cg_conditions(run)
	var rows: Array = []
	for item in Collateral.LEDGER_ORDER:
		var id := Collateral.plate_for(item)
		var spec: Dictionary = Collateral.PLATES[id]
		var cond: Array = conds.get(item, [false, ""])
		rows.append({
			"id": id,
			"item": item,
			"title": str(spec["title"]),
			"earned": bool(cond[0]),
			"why": str(cond[1]),
			"seen": bool(seen.get(id, false)),
			"gated": bool(spec["gated"]),
			"unlocked": Unlock.ready_for(id) if bool(spec["gated"]) else true,
		})
	return rows

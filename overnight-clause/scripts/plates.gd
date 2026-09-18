extends Control
class_name PlateLayer

## The plate layer. Flat 404 ships zero human art on purpose — assets/ is two bitmap-font
## files and nothing in hud.gd ever loaded a texture — so this whole layer is new, and it
## is written to fail safe: a missing plate file degrades to the scene playing with no
## picture, never to a crash and never to a black screen over the text.
##
## It hangs inside VnChrome's NVL root, under the text and over the veil, because the
## authored moments are already full-screen NVL in the base game. A plate is a picture
## behind a scene that was going to play anyway.

const DIR := "res://assets/plates/"
const GALLERY_PATH := "user://gallery.cfg"

var art: TextureRect
var scrim: ColorRect
var badge: Label
var unlock: Unlock
var seen: Dictionary = {}
var current := ""
var current_locked := false


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
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	scrim = ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.03, 0.02, 0.02, 0.42)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	badge = Label.new()
	badge.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	badge.offset_left = 28.0
	badge.offset_top = -46.0
	badge.offset_right = 620.0
	badge.offset_bottom = -22.0
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color(0.78, 0.66, 0.5, 0.85))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.apply_label(badge)
	add_child(badge)
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
	if Overnight.is_gated(id):
		var src := Unlock.source_for(id)
		if src != "":
			var tex := _from_disk(src)
			if tex != null:
				return [tex, false]
		return [_from_disk(DIR + id + "_locked.png"), true]
	return [_from_disk(DIR + id + ".png"), false]


func show_plate(id: String) -> bool:
	var picked := pick(id)
	current = id
	current_locked = bool(picked[1])
	if picked[0] == null:
		# No art yet. The scene still plays; the plate layer simply stays out of the way.
		visible = false
		return false
	art.texture = picked[0]
	visible = true
	badge.text = "PLATE LOCKED — CENSORED IN THIS BUILD" if current_locked else ""
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
	for id in cfg.get_section_keys("seen") if cfg.has_section("seen") else []:
		seen[id] = bool(cfg.get_value("seen", id, false))


func _mark_seen(id: String) -> void:
	if seen.get(id, false):
		return
	seen[id] = true
	var cfg := ConfigFile.new()
	cfg.load(GALLERY_PATH)
	cfg.set_value("seen", id, true)
	cfg.save(GALLERY_PATH)


func gallery_rows() -> Array:
	## What the gallery screen draws: every plate in story order, with the three states
	## it can be in — not seen, seen, seen-but-censored-in-this-build.
	var rows: Array = []
	for id in Overnight.PLATES.keys():
		var spec: Dictionary = Overnight.PLATES[id]
		rows.append({
			"id": id,
			"title": str(spec["title"]),
			"seen": bool(seen.get(id, false)),
			"gated": bool(spec["gated"]),
			"unlocked": Unlock.ready_for(id) if bool(spec["gated"]) else true,
		})
	return rows

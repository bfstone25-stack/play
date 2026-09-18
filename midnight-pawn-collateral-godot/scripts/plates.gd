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
const GALLERY_PATH := "user://gallery.cfg"

var art: TextureRect
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
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	badge.text = "CENSORED IN THIS BUILD" if current_locked else ""
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

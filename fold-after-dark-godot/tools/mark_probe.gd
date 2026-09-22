extends Node2D
## Renders scripts/vector_mark.gd on its own, to a PNG, in about two seconds:
##
##   ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path . --resolution 960x380 \
##       res://tools/mark_probe.tscn
##   # -> shots/mark-probe.png (gitignored; it is a look-at-it artefact, not a fixture)
##
## It exists because the logotype's faults are only ever visible in a frame, and the frame
## that proves them used to cost a full web export plus a headless Chromium run. Three
## rounds of that missed a parser bug that this probe showed on the first look: every
## multi-`M` letter was being drawn as one polyline with diagonals connecting the strokes.
## Big mark, HUD-size mark and the zh mark together, because a fix that reads at 470 px
## can still be mud at 116.
const OUT_PATH := "res://shots/mark-probe.png"

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.PAPER
	bg.size = Vector2(960, 380)
	add_child(bg)
	_add(VectorMark.NAME, Vector2(40, 30), Vector2(470, 150), 1.0)
	_add(VectorMark.NAME, Vector2(40, 210), Vector2(116, 38), 1.15)   # the HUD lockup's real size
	_add(VectorMark.NAME, Vector2(540, 210), Vector2(380, 120), 1.0)
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(OUT_PATH)
	print("wrote ", OUT_PATH)
	get_tree().quit()


func _add(which: String, at: Vector2, sz: Vector2, w: float) -> void:
	var m := VectorMark.new()
	m.mark = which
	m.size = sz
	m.position = at
	m.weight = w
	m.reveal = 1.0
	add_child(m)

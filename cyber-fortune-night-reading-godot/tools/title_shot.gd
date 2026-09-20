## Capture 夜读's title screen alone, in both languages, without playing the game.
##
## Why this exists as its own thing, and why it is not ops/capture_title.sh. That script
## runs the real window and grabs a frame out of a --write-movie AVI, and on this desktop
## the window is CLAMPED by the screen height: a 720x1280 portrait game comes back in a
## ~616 px-wide window, ffmpeg then writes a 720-wide file out of it, and every frame is
## a picture that looks plausible and is measurably wrong — the mark's left end and the
## first letter of every menu row sat off the edge of two captures before this was found.
## The picture is fine; every measurement taken off it is a lie. (The sibling title's
## tools/title_shot.gd records the same clamp, in the same words, and this pass re-learned
## it the expensive way because the fork had no such tool.)
##
## A SubViewport is not clamped by anything, so the canvas is exactly the canvas.
##
##     DISPLAY=:0 ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
##         --path . res://tools/title_shot.tscn --out shots
##
## Then LOOK at both, and measure the en one:
##
##     ops/check_brightness.py shots/00-title-en.png      # the shelf floor, 0.45 / 0.30
##
## The zh frame is the one that most needs looking at and the one nothing else can
## produce. Switching language on this screen rebuilds only the strings (see
## _on_lang) precisely so that the sibling's bug cannot happen here — that title shipped
## a Chinese screen with a mark and NO MENU, because its chip's handler queue_freed the
## node the handler belonged to and the intro tween died holding modulate.a = 0. This is
## how "the zh screen still has a menu" stays a thing anyone can look at in thirty
## seconds rather than a claim in a commit message.
extends Node

const DEFAULT_OUT := "user://title_shots"

var main: Control
var sub: SubViewport
var out_dir: String = DEFAULT_OUT


func _ready() -> void:
	out_dir = _arg("--out", DEFAULT_OUT)
	if not out_dir.begins_with("user://") and not out_dir.begins_with("res://"):
		out_dir = ProjectSettings.globalize_path("res://") + out_dir
	DirAccess.make_dir_recursive_absolute(out_dir)

	sub = SubViewport.new()
	sub.size = Vector2i(720, 1280)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)

	main = load("res://scenes/main.tscn").instantiate()
	sub.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(720, 1280)

	# Long enough that play_in has finished. A frame caught mid-intro is a frame of the
	# animation and not of the screen, and it is the whole difference between "the menu is
	# missing" and "the menu had not arrived yet".
	await _settle(3.8)
	_save("00-title-en.png")

	Tx.set_lang("zh")
	await _settle(1.2)
	_save("00-title-zh.png")

	get_tree().quit(0)


func _settle(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var img := sub.get_texture().get_image()
	var p := out_dir.path_join(name)
	img.save_png(p)
	print("  ", p, "  ", img.get_width(), "x", img.get_height())


func _arg(flag: String, fallback: String) -> String:
	var a := OS.get_cmdline_user_args()
	var all := OS.get_cmdline_args()
	for list in [a, all]:
		for i in list.size():
			if list[i] == flag and i + 1 < list.size():
				return list[i + 1]
	return fallback

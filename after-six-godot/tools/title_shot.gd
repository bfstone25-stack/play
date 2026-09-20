## Capture the title screen alone, in both languages, at 2x — without playing the game.
##
## Why this exists as its own thing. The only other way to get a title frame was
## tests/night_web.py, which builds the web export, plays the whole five-step route and
## **deletes shots/*.png on the way in**. Using it to look at one screen means rebuilding,
## replaying, and clobbering whatever another pass had captured. It also cannot show the
## zh title at all: the language chip is mid-route and the harness never presses it.
##
## The zh frame is the one that has to be looked at. Switching language re-enters
## show_title from the chip's own signal handler, which queue_frees the node that handler
## belongs to; an intro tween that writes modulate.a = 0 up front then leaves the Chinese
## title screen as a picture with no menu, and nothing errors. as_title.gd animates every
## property with .from() so the resting state is visible — this is how that stays true.
##
##     DISPLAY=:0 ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
##         --path . res://tools/title_shot.tscn --out /tmp/shots
##
## The game is rendered into a SubViewport at 840x1280 rather than into the window,
## because the window is clamped by the desktop's screen height and comes back at ~616 px
## wide: the picture is fine and every measurement taken off it is wrong. Then:
##
##     ops/check_brightness.py /tmp/shots/*.png
extends Node

const DEFAULT_OUT := "user://title_shots"

var main: Control
var sub: SubViewport
var out_dir: String = DEFAULT_OUT


func _ready() -> void:
	out_dir = _arg("--out", DEFAULT_OUT)
	DirAccess.make_dir_recursive_absolute(out_dir)

	sub = SubViewport.new()
	sub.size = Vector2i(840, 1280)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	# The project's stretch mode scales canvas items at the *window*, and a SubViewport
	# gets none of it: the title lays itself out in 420x640 units, so it is scaled here by
	# hand instead of being left to draw in one corner.
	var wrap := Control.new()
	wrap.size = Vector2(420, 640)
	wrap.scale = Vector2(2, 2)
	sub.add_child(wrap)

	main = load("res://scenes/main.tscn").instantiate()
	wrap.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(420, 640)

	# Long enough that play_in has finished: a frame caught mid-intro is a frame of the
	# animation, not of the screen, and it is the difference between "the menu is missing"
	# and "the menu had not arrived yet".
	await _settle(3.6)
	_save("title-en.png")

	Game.set_lang("zh")
	main.show_title()
	await _settle(3.6)
	_save("title-zh.png")

	# set_lang writes the profile. Leave the save file as it was found.
	Game.set_lang("en")
	get_tree().quit()


func _arg(name: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var i := args.find(name)
	return args[i + 1] if i != -1 and i + 1 < args.size() else fallback


func _settle(seconds: float) -> void:
	# `true, false, true` — process-always, ignore-time-scale, and crucially it keeps
	# running while the tree is paused, which is the state Gate.require() leaves it in.
	await get_tree().create_timer(seconds, true, false, true).timeout
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var img := sub.get_texture().get_image()
	var path := out_dir.path_join(name)
	var err := img.save_png(path)
	if err != OK:
		push_error("title_shot: could not write %s (%d)" % [path, err])
		return
	print("saved ", path, " ", img.get_size())

## Capture the title screen alone, without the backend and without playing the game.
##
## tests/shots.gd is the project's shot harness and it cannot do this. It seeds a winning
## deck through the real /cards/* endpoints, so it needs `play/silvertongue-cards/run.sh`
## up on 127.0.0.1:8929; it drives the whole route; and it opens `d01_home` first. Looking
## at one screen should not require a FastAPI process and a full playthrough.
##
## This instantiates res://scenes/title.tscn on its own, with `main` left null — which the
## title screen is written to survive (_start and _go both guard on it), because a title
## screen that cannot be looked at without a server is a title screen nobody looks at.
##
## It renders into a SubViewport rather than into the window. The window is clamped by the
## desktop and comes back smaller than the canvas, and every coordinate measured off such
## a frame is wrong while the picture still looks plausible — the sibling fork shipped two
## captures laid out against a canvas that was not the canvas before this was found.
##
##     DISPLAY=:0 ~/bin/godot/Godot_v4.7-stable_linux.x86_64 \
##         --path . res://tools/title_shot.tscn --out shots
##     ops/check_brightness.py shots/00-title.png      # the shelf floor, 0.45 / 0.30
extends Node

var sub: SubViewport


func _ready() -> void:
	var out := "user://title_shots"
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			out = args[i + 1]
	if not out.begins_with("user://") and not out.begins_with("res://"):
		out = ProjectSettings.globalize_path("res://") + out
	DirAccess.make_dir_recursive_absolute(out)

	Symbols.install()
	sub = SubViewport.new()
	sub.size = Vector2i(1280, 720)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)

	var host := Control.new()
	host.theme = StudioTheme.build()
	host.size = Vector2(1280, 720)
	sub.add_child(host)

	# Typed explicitly. `var t := load(...).instantiate()` cannot be inferred and is a
	# PARSE error — and a parse error in a tool scene's script does not fail the run, it
	# HANGS it: the script never loads, _ready never fires, and Godot sits in its main loop
	# until the shell's `timeout` kills it. Three runs were spent looking for a deadlock
	# that was a type annotation. (memory: verification-that-lies — the check reported
	# nothing rather than reporting a problem.)
	var t: Node = load("res://scenes/title.tscn").instantiate()
	host.add_child(t)
	t.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	t.size = Vector2(1280, 720)

	# Long enough that play_in has finished. A frame caught mid-intro is a frame of the
	# animation and not of the screen.
	await get_tree().create_timer(3.6).timeout
	await RenderingServer.frame_post_draw
	var img := sub.get_texture().get_image()
	var p := out.path_join("00-title.png")
	img.save_png(p)
	print("  ", p, "  ", img.get_width(), "x", img.get_height())
	get_tree().quit(0)

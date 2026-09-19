## title_shot.gd — photograph the title screen and prove it is alive.
##
##   xvfb-run -a "$GODOT" --path . --resolution 1280x720 -s res://tests/title_shot.gd
##   xvfb-run -a "$GODOT" --path . --resolution 1280x720 -s res://tests/title_shot.gd -- --locale=zh
##
## The other tests walk the game. This one photographs the first second of it, which is
## the thing ops/adult_forks/TITLE_SCREENS.md is about. Two frames are taken 1.2 s apart:
## if they are byte-identical then the damp is not falling, the torch is not guttering and
## the camera is not breathing, and a still that draws is still a failure of this pass.
##
## The shot name carries the locale, so en and zh do not overwrite each other.
extends SceneTree

const OUT := "user://shots"


func _init() -> void:
	call_deferred("_run")


func _shot(name: String) -> Image:
	for _f in 3:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("  shot %s %dx%d" % [name, img.get_width(), img.get_height()])
	return img


## Is the screen we are about to photograph actually the title screen?
##
## 2026-09-19: this harness printed TITLE_SHOT_OK on a run whose title_en_00.png was the
## in-game chapter card over the 3D corridor — the splash had gone away during the wait,
## and every check below ran against nodes that still EXISTED off-screen. One run in four.
##
## The cause is the capture environment, not the game: xvfb-run is not installed on this
## box, so these shots are taken on the live desktop (DISPLAY=:0) in a real window, and a
## stray click anywhere on that window reaches game.gd's _unhandled_input, which dismisses
## the splash exactly as a player's click would. Nothing to fix in the game. What had to
## be fixed is that the harness said OK about it.
## That is the failure mode this repo keeps meeting: a check that reports fine because it
## asked an easier question than the one it claims to answer. It now asks whether the
## panel is on screen at the moment of the exposure.
func _splash_up(hud: Node, when: String) -> bool:
	if hud.title_panel == null or not hud.title_panel.is_visible_in_tree():
		push_error("the title panel is not on screen %s — this shot would be of the game" % when)
		quit(1)
		return false
	return true


func _wait(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var loc := Loc.current()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var hud: Node = game.get_node("HUD")
	if hud.title_panel == null:
		push_error("no title panel on the HUD")
		quit(1)
		return
	if not hud.title_panel.visible:
		hud.title_panel.visible = true
	if hud.title_screen:
		hud.title_screen.play_in()

	await _wait(1900)
	if not _splash_up(hud, "before title_%s_00" % loc):
		return
	var a := await _shot("title_%s_00" % loc)
	await _wait(1200)
	if not _splash_up(hud, "before title_%s_01" % loc):
		return
	var b := await _shot("title_%s_01" % loc)

	if hud.title_screen == null:
		push_error("no title screen built")
		quit(1)
		return
	var ts: Node = hud.title_screen
	if ts.get_node_or_null("KeyVisual") == null or ts.get_node("KeyVisual").texture == null:
		push_error("no key visual on the title screen")
		quit(1)
		return
	if ts.get_node_or_null("Logotype") == null or ts.get_node("Logotype").texture == null:
		push_error("no logotype on the title screen")
		quit(1)
		return
	if ts.get_node_or_null("Overlay") == null or ts.get_node("Overlay").texture == null:
		push_error("no baked overlay on the title screen")
		quit(1)
		return
	## The form sheet is the type's ground since 2026-09-19. Without it the type is
	## floating on the corridor and the screen is unreadable, so it is a hard check and
	## not a matter of taste.
	if ts.get_node_or_null("FormSheet") == null or ts.get_node("FormSheet").texture == null:
		push_error("no form sheet on the title screen")
		quit(1)
		return
	if ts.get_node_or_null("Stamp") == null:
		push_error("no condition stamp on the title screen")
		quit(1)
		return
	if a.get_data() == b.get_data():
		push_error("the title screen is a still: two frames 1.2 s apart are identical")
		quit(1)
		return
	## And the card the player sees after the door closes: the same mark, not the two-line
	## Label that made the opening look like a document.
	hud.hide_splash()
	hud.show_title(Loc.t("title.card"))
	await _wait(1100)
	await _shot("card_%s" % loc)
	if hud.title_mark == null or hud.title_mark.texture == null:
		push_error("the in-game title card has no mark")
		quit(1)
		return

	print("TITLE_SHOT_OK locale=%s moving=true" % loc)
	quit(0)

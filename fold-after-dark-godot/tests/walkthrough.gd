extends Node
## Scripted walkthrough for the Nutaku walkthrough video (ops/nutaku/walkthroughs/plicata/).
## Drives the REAL scenes (title -> map -> tier 1 -> scene unlock -> map -> daily challenge
## -> weekly event) against the title server + mock platform, pressing the game's own
## buttons, while `godot --write-movie` records. Run by ops/nutaku/walkthroughs/make_plicata.sh:
##   godot --path . --write-movie out.avi --fixed-fps 30 res://tests/walkthrough.tscn --
##       --nutaku-mock=<mock> --nutaku-api=<server> --nutaku-user=<id> [--lang=en|zh|ja]
## Prints `CAP <seconds> <caption id>` (movie time) for the caption track, `SHOT <name>`
## after saving shots/walk/<name>.png, and WALK_OK / WALK_FAIL at the end.
## Only tier 1's scene (coco_a1, art tier 1, clothed) is ever opened.

const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
const FPS := 30.0
var fails := 0
var shot_dir := "res://shots/walk"
var said_combo := false


func cap(id: String) -> void:
	print("CAP %.2f %s" % [Engine.get_frames_drawn() / FPS, id])


func fail(why: String) -> void:
	print("WALK_STEP_FAIL " + why)
	fails += 1


func sleep(s: float) -> void:
	await get_tree().create_timer(s).timeout


func until(cond: Callable, timeout := 15.0) -> bool:
	var t := 0.0
	while t < timeout:
		if cond.call():
			return true
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	return false


func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT %.2f %s (headless, not saved)" % [Engine.get_frames_drawn() / FPS, name])
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))
	img.save_png(ProjectSettings.globalize_path(shot_dir + "/" + name + ".png"))
	print("SHOT %.2f %s" % [Engine.get_frames_drawn() / FPS, name])


func current() -> Node:
	return get_tree().current_scene


func find(name: String) -> Node:
	var cs := current()
	return cs.find_child(name, true, false) if cs else null


func press(name: String, timeout := 15.0) -> bool:
	var ok := await until(func(): return find(name) is BaseButton and (find(name) as BaseButton).is_visible_in_tree(), timeout)
	if not ok:
		fail("no button " + name)
		return false
	(find(name) as BaseButton).pressed.emit()
	return true


func is_scene(path: String) -> bool:
	return current() != null and current().scene_file_path == path


func play_moves(moves: Array, gap: float) -> void:
	await sleep(1.4)                          # the server refuses an impossibly fast solve
	for d in moves:
		Fold.move(d.x, d.y)
		await sleep(0.12)
		var g := current()
		if not said_combo and g != null and g.get("_combo_lbl") is Label and (g.get("_combo_lbl") as Label).visible:
			said_combo = true
			cap("combo")
			await shot("04_combo")
		await sleep(maxf(0.0, gap - 0.12))


func log_moves(s: String) -> Array:
	var out := []
	for ch in s:
		out.append(DIRS[ch])
	return out


func _ready() -> void:
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	# `--lang=zh` records the game itself in that language (the zh video shows the zh UI)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			I18n.set_lang(a.split("=", true, 1)[1])
	print("WALK_LANG " + I18n.lang)
	get_tree().create_timer(420.0).timeout.connect(func():
		print("WALK_FAIL watchdog: the walkthrough did not finish in 420 s of game time")
		get_tree().quit(2))
	await run()
	print("WALK_OK" if fails == 0 else "WALK_FAIL %d" % fails)
	await sleep(0.5)
	get_tree().quit(1 if fails else 0)


func run() -> void:
	# ---- title ------------------------------------------------------------------------
	await get_tree().process_frame            # root is still adding this node; wait a frame
	var title := (load("res://scenes/title.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(title)
	get_tree().current_scene = title
	cap("title")
	await sleep(5.0)
	await shot("01_title")
	await sleep(1.0)
	title.call("_play")                       # the fan: PLAY, which opens the map

	# ---- map --------------------------------------------------------------------------
	if not await until(func(): return is_scene("res://scenes/map.tscn") and find("Standing") != null, 30.0):
		fail("map did not load from the server")
		return
	cap("map")
	await sleep(3.0)
	await shot("02_map_chapters")
	cap("map_side")
	await sleep(3.5)

	# ---- tier 1, played at real speed ------------------------------------------------------
	var map := current()
	map.call("_play", 0)
	var sols = JSON.parse_string(FileAccess.get_file_as_string("res://tests/solutions.json"))
	for lv in range(5):
		if not await until(func(): return F2P.active_for(lv) and Fold.level_index == lv and not Fold.done, 20.0):
			fail("level %d did not open" % (lv + 1))
			return
		if lv == 0:
			cap("level")
			await sleep(1.0)
			await shot("03_level_board")
		elif lv == 1:
			cap("levels_flow")
		var moves := []
		for d in sols[str(lv)]["dirs"]:
			moves.append(Vector2i(int(d[0]), int(d[1])))
		await play_moves(moves, 0.7)
		var g := current()
		if lv == 0:
			await until(func(): return bool(g.get("_results_open")), 10.0)
			cap("results")
			await sleep(1.6)
			await shot("05_results_coco")
			cap("coco")
		if not await until(func(): return int(Nutaku.state["progress"]["stars"][lv]) > 0, 20.0):
			fail("level %d not accepted" % (lv + 1))
			return
	# the trophy card at the end of tier 1
	if not await until(func(): return find("Unlock") is Button and (find("Unlock") as Button).is_visible_in_tree(), 30.0):
		fail("no trophy card")
		return
	cap("trophy")
	await sleep(2.5)
	await shot("06_tier_cleared")
	await press("Unlock")
	if not await until(func(): return find("SceneView") != null, 30.0):
		fail("scene viewer did not open")
		return
	cap("scene")
	await sleep(4.5)
	await shot("07_scene_unlocked_tier1")
	await press("Close")

	# ---- the map again: chapters, daily, event -------------------------------------------
	if not await until(func(): return is_scene("res://scenes/map.tscn") and find("PlayDaily") != null, 30.0):
		fail("map (after scene) missing the daily panel")
		return
	cap("map_after")
	await sleep(3.0)
	await shot("08_map_daily_event")
	var gsols = JSON.parse_string(FileAccess.get_file_as_string("res://tests/gen_solutions.json"))

	# daily challenge
	cap("daily")
	await press("PlayDaily")
	if not await until(func(): return F2P.active_for(Fold.DAILY) and Fold.is_daily() and not Fold.done, 20.0):
		fail("daily did not open")
		return
	await sleep(1.0)
	await shot("09_daily_challenge")
	var idx := str(int(F2P.challenge.get("index", -1)))
	await play_moves(log_moves(str(gsols["daily"][idx])), 0.45)
	if not await until(func(): return find("Again") is Button, 25.0):
		fail("daily result card")
		return
	cap("daily_done")
	await sleep(3.0)
	await press("Map")

	# weekly event board
	if not await until(func(): return is_scene("res://scenes/map.tscn") and find("PlayEvent") != null, 30.0):
		fail("map missing the event panel")
		return
	cap("event")
	await sleep(2.5)
	await press("PlayEvent")
	if not await until(func(): return F2P.active_for(Fold.EVENT) and Fold.is_special() and not Fold.is_daily() and not Fold.done, 20.0):
		fail("event board did not open")
		return
	await sleep(0.8)
	var who := str(F2P.event.get("who", ""))
	await play_moves(log_moves(str(gsols["event"][who][F2P.event_board])), 0.45)
	if not await until(func(): return find("Map") is Button and int(F2P.event.get("cleared", 0)) >= 1, 25.0):
		fail("event result card")
		return
	cap("event_done")
	await sleep(1.0)
	await shot("10_weekly_event")
	await sleep(2.5)
	await press("Map")
	await until(func(): return is_scene("res://scenes/map.tscn") and find("Standing") != null, 30.0)
	cap("end")
	await sleep(4.0)

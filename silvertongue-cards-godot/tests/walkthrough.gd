## The recorded walkthrough (ops/nutaku/suasion_f2p/walkthrough.py drives it under Xvfb on
## the GPU box with --write-movie). Not a test: a scripted player, paced for a viewer.
## Prints "CAP <frame> <key>" at each beat; the driver turns those into captions.
##
##   segment a  a fresh account: title, the map, the first night won card by card
##   segment b  an ACCELERATED save (chapter 1 played to the boss by the driver over HTTP):
##              the map with stars, the boss and its rule, deck-building, a ten-pull, the
##              boss duel under its rule
##
##   godot --path . res://tests/walkthrough.tscn --write-movie a.avi --fixed-fps 30 -- \
##       --walk-seg=a [--walk-lang=zh] --nutaku-mock=... --nutaku-api=... --nutaku-user=...
extends Node

var seg := "a"
var m: Node
var shots := ""       # --shots=<abs dir>: a still at every caption beat (ops/nutaku/lang_shots.py)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--walk-seg="):
			seg = a.get_slice("=", 1)
		elif a.begins_with("--shots="):
			shots = a.get_slice("=", 1)
		elif a.begins_with("--walk-lang="):
			# the zh cut is recorded with the game itself in Chinese, not only its captions
			Loc.set_code(a.get_slice("=", 1))
	call_deferred("_run")


func cap(key: String) -> void:
	print("CAP %d %s" % [Engine.get_frames_drawn(), key])
	if shots != "" and DisplayServer.get_name() != "headless":
		_still.call_deferred(key)


## A still a moment after the caption beat (the screen has settled), plus the text-fit scan.
func _still(key: String) -> void:
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	DirAccess.make_dir_recursive_absolute(shots)
	var name := "%s_%s" % [seg, key]
	img.save_png(shots.path_join(name + ".png"))
	print("SHOT %d %s" % [Engine.get_frames_drawn(), name])
	for w in preload("res://tests/text_fit.gd").scan(get_tree().root):
		print("FIT %s %s" % [name, w])


func hold(secs: float) -> void:
	await get_tree().create_timer(secs).timeout


func _wait(cond: Callable, frames: int = 900) -> bool:
	var n := 0
	while not cond.call() and n < frames:
		await get_tree().process_frame
		n += 1
	return cond.call()


func _run() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	await _wait(func(): return m.current != "")
	if seg == "a":
		await _seg_a()
	else:
		await _seg_b()
	cap("end")
	await hold(0.4)
	print("WALK_DONE")
	m.queue_free()
	await hold(0.3)
	get_tree().quit(0)


func _drop_reader() -> void:
	for c in m.screen.get_children():
		if c is ColorRect:
			c.queue_free()


func _select(id: String) -> void:
	m.screen._sel = id
	m.screen._render()


## Play one duel card by card, with a hover beat before each card so a viewer can read it.
## Returns the last turn's result.
func _duel(max_turns: int, caps: Dictionary) -> Dictionary:
	var duel = m.screen
	await _wait(func(): return not duel.hand.cards.is_empty())
	var last := {}
	var turns := 0
	while not duel.ended and turns < max_turns:
		await _wait(func(): return duel.hand.state == Hand.State.IDLE or duel.ended)
		if duel.ended:
			break
		if caps.has(turns):
			cap(caps[turns])
		var d: Dictionary = duel.duel
		var want := {}
		for p in d["needs"]["paths"]:
			for s in p:
				want[str(s)] = true
		for s in d["needs"]["help"]:
			want[str(s)] = true
		var pick := ""
		var best := -1
		for card in d["hand"]:
			if int(card["cost"]) > int(d["nerve"]) or not card["harms"].is_empty():
				continue
			var hit := 0
			for s in card["signals"]:
				if want.has(str(s)):
					hit += 1
			if hit > best:
				best = hit
				pick = str(card["id"])
		await hold(0.5)
		if pick == "" or best <= 0:
			last = await duel.drive_pass()
		else:
			var c: Card = duel.hand.card_by_id(pick)
			if c:
				duel.hand._on_hovered(c, true)
			await hold(0.8)
			last = await duel.drive_play(pick)
		turns += 1
		await hold(1.9)      # her line types out
	return last


func _seg_a() -> void:
	cap("title")
	await hold(3.0)
	await F2P.claim("daily")
	m.go("home")
	await hold(0.4)
	cap("prologue")
	await hold(3.0)
	_drop_reader()
	cap("map")
	await hold(3.5)
	var r: Dictionary = await m.start_duel("c1s01", false)
	if not r.get("ok", false):
		print("WALK_FAIL start c1s01 ", r)
		return
	cap("hand")
	var last := await _duel(20, {1: "phases", 3: "resolve"})
	cap("win" if last.get("end", {}).get("won", false) else "lost")
	await hold(3.0)
	await m.screen.leave_confirm()
	await hold(0.3)


func _seg_b() -> void:
	cap("accel")
	m.go("home")
	await hold(0.3)
	_drop_reader()
	await hold(2.0)
	_select("c1s12")
	cap("boss")
	await hold(5.0)
	F2P.stage_id = "c1s12"
	m.go("deck")
	cap("deck")
	await hold(2.0)
	await _wait(func(): return m.screen._grid.get_child_count() > 0)
	# take one card out and put one in, the way a player tunes for a night
	for i in 2:
		var pick: Card = null
		for w in m.screen._grid.get_children():
			var c = w.get_child(0) if w.get_child_count() > 0 else null
			var ok_live: bool = m.screen.live == null or m.screen.live.has(str(c.data.get("id", ""))) if c is Card else false
			if c is Card and ((i == 0 and c._selected) or (i == 1 and not c._selected and ok_live and str(c.data.get("kind", "")) != "coercion")):
				pick = c
				break
		if pick:
			pick.pressed.emit(pick)
		await hold(1.0)
	m.screen._save()
	await hold(1.2)
	m.go("gacha")
	await hold(1.0)
	cap("pull10")
	var g: Dictionary = await m.screen.drive_pull(10)
	if g.has("error"):
		print("WALK_NOTE ten-pull: ", g)
		await m.screen.drive_pull(1)
	await hold(1.5)
	var r: Dictionary = await m.start_duel("c1s12", false)
	if not r.get("ok", false):
		print("WALK_FAIL start boss ", r)
		return
	cap("bossduel")
	var last := await _duel(10, {2: "bossturns"})
	cap("win" if last.get("end", {}).get("won", false) else "lost")
	await hold(2.5)
	await m.screen.leave_confirm()
	await hold(0.5)
	await F2P.refresh()
	m.go("home")
	await hold(0.3)
	_drop_reader()
	cap("after")
	await hold(3.0)

## Desktop screenshots of the Nutaku F2P screens (campaign, a duel mid-way, a pull, the
## store). Run by ops/nutaku/suasion_f2p/shots.py through ops/on_game_monitor.sh; writes
## shots/f2p_*.png. Not a pass/fail test: a picture to look at.
extends Node


func _ready() -> void:
	Sfx.muted = true
	call_deferred("_run")


func _snap(name: String) -> void:
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://shots/f2p_%s.png" % name)
	print("SHOT ", name)


func _run() -> void:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	while m.current == "":
		await get_tree().process_frame
	await F2P.claim("daily")
	m.go("home")
	await get_tree().create_timer(1.5).timeout
	# close the one-time prologue so the map shows; shoot the prologue first
	await _snap("prologue")
	for c in m.screen.get_children():
		if c is ColorRect:
			c.queue_free()
	await _snap("campaign")
	var r: Dictionary = await m.start_duel("c1s01", false)
	var duel = m.screen
	while duel.hand.cards.is_empty():
		await get_tree().process_frame
	for i in 2:
		while duel.hand.state != Hand.State.IDLE:
			await get_tree().process_frame
		var best := ""
		for c in duel.duel["hand"]:
			if int(c["cost"]) <= int(duel.duel["nerve"]) and c["harms"].is_empty():
				best = str(c["id"])
		if best != "":
			await duel.drive_play(best)
	await _snap("duel")
	await duel.leave_confirm()
	m.go("gacha")
	await get_tree().create_timer(0.5).timeout
	await m.screen.drive_pull(1)
	await _snap("gacha")
	m.go("store")
	await _snap("store")
	F2P.stage_id = "c1s02"
	m.go("deck")
	await _snap("deck")
	# the same screens in Chinese and Japanese (the campaign's own words, not only chrome)
	for lang in ["zh", "ja"]:
		Loc.set_code(lang)
		await get_tree().create_timer(0.6).timeout
		m.go("home")
		await _snap("campaign_" + lang)
		var r2: Dictionary = await m.start_duel("c1s01", false)
		if r2.get("ok", false):
			var d2 = m.screen
			while d2.hand.cards.is_empty():
				await get_tree().process_frame
			await _snap("duel_" + lang)
			await d2.leave_confirm()
		m.go("deck")
		await _snap("deck_" + lang)
	Loc.set_code("en")
	get_tree().quit(0)

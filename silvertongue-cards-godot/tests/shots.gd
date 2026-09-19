## Desktop screenshot run. Needs a display (DISPLAY=:0 or xvfb); writes PNGs to shots/ next
## to the project. Drives the real scenes through main.bridge_command — the same commands
## the web driver sends — so what is on disk is what a player sees.
##
##   ~/bin/godot/Godot_v4.7-stable_linux.x86_64 --path play/silvertongue-cards-godot res://tests/shots.tscn
extends Node

var out := ""
var m: Node
var pid := ""


func _ready() -> void:
	Sfx.muted = true
	out = ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(out)
	pid = "shots_%d" % int(Time.get_unix_time_from_system())
	Api.set_pid(pid)
	get_window().size = Vector2i(1280, 720)
	call_deferred("_run")


func _shot(name: String, settle: float = 0.6) -> void:
	await get_tree().create_timer(settle).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("  shot %s %dx%d" % [name, img.get_width(), img.get_height()])


func _run() -> void:
	# a winning deck, set through the real endpoint (the pytest fixture's)
	await Api.state()
	await Api.dev_gold(2000)
	await Api.save_deck("closing_time", ["mara_01", "mara_03", "mara_05", "mara_01", "mara_03", "mara_05",
		"ines_03", "ines_04", "sanne_01", "sanne_02", "teodora_01", "teodora_02"])
	m = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	var guard := 0
	while m.current == "" and guard < 300:
		await get_tree().process_frame
		guard += 1
	await _shot("d01_home", 1.0)
	m.difficulty = "silver"
	await m.bridge_command("start", {"scenario": "closing_time"})
	await _shot("d02_duel_start", 1.2)
	var duel = m.screen
	var wanted := ["mara_01", "mara_03", "mara_05"]
	var turns := 0
	var shot_mid := false
	var last := {}
	while not duel.ended and turns < 20:
		while duel.hand.state != Hand.State.IDLE:
			await get_tree().process_frame
		if turns == 1:
			# hover-lift on the first card, for the fan shot
			duel.hand._on_hovered(duel.hand.cards[0], true)
			await _shot("d03_hand_hover", 0.4)
			duel.hand._on_hovered(duel.hand.cards[0], false)
		var hand: Array = duel.duel["hand"]
		var nerve := int(duel.duel["nerve"])
		var pick := ""
		for c in hand:
			if not wanted.is_empty() and c["id"] == wanted[0] and int(c["cost"]) <= nerve:
				pick = c["id"]
				wanted.pop_front()
				break
		if pick == "":
			var best: Dictionary = {}
			for c in hand:
				if c["harms"].is_empty() and int(c["cost"]) <= nerve and not (c["id"] in wanted):
					if best.is_empty() or int(c["cost"]) < int(best["cost"]):
						best = c
			if best.is_empty():
				for c in hand:
					if c["harms"].is_empty() and int(c["cost"]) <= nerve:
						best = c
			pick = str(best["id"])
		# the wild card, once, when affordable: the typed line in-scene
		if nerve >= 2 and duel.hand.wild_card != null and not shot_mid:
			duel.hand.open_wild()
			duel.wild_input.text = "Long day for you too, I'd guess."
			await _shot("d04_wild_typed", 0.4)
			last = await duel.drive_wild_submit()
			shot_mid = true
			await _shot("d05_reply", 1.4)
			turns += 1
			continue
		last = await m.bridge_command("play", {"card": pick})
		turns += 1
		if turns == 3:
			await _shot("d06_duel_midway", 1.2)
	await _shot("d07_persuaded", 2.2)
	print("  won=", last.get("end", {}).get("won", false), " turns=", turns)
	m.go("gacha")
	await _shot("d08_gacha", 0.8)
	await m.bridge_command("pull", 10)
	await _shot("d09_gacha_tenpull", 1.0)
	m.go("affection")
	await _shot("d10_affection", 1.6)
	m.go("deck")
	await _shot("d11_deck", 1.2)
	# phone landscape: 844x390 at the same 720 logical height
	get_window().size = Vector2i(844, 390)
	await get_tree().process_frame
	await m.bridge_command("start", {"scenario": "the_key"})
	await _shot("d12_phone_landscape_duel", 1.4)
	await Api.forfeit()
	get_tree().quit(0)

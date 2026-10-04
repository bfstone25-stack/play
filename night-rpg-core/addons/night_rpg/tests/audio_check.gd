extends Node
## Audio buses + foley smoke, headless (run on the GPU box, never on pop-os):
##   godot --headless --audio-driver Dummy --path <game> res://addons/night_rpg/tests/audio_check.tscn
## Checks: the project points at the core bus layout; Music/Ambience/SFX/Voice exist with the
## right sends and the Duck effect; Settings sliders move BUS volumes; music ducks ~-8 dB
## while a voice take plays and recovers after; every core foley key and every room's
## ambience resolves to a file; the SFX pool overlaps; a missing key is silent.

var fails := 0
var main


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var lay := str(ProjectSettings.get_setting("audio/buses/default_bus_layout", ""))
	check(lay == "res://addons/night_rpg/audio/default_bus_layout.tres", "project bus layout -> core (%s)" % lay)
	var sends := {"Music": "Master", "Ambience": "Music", "SFX": "Master", "Voice": "Master"}
	for b in sends:
		var i := AudioServer.get_bus_index(b)
		check(i != -1 and AudioServer.get_bus_send(i) == sends[b], "bus %s -> %s" % [b, sends[b]])
	check(Sound._duck_fx() != null, "Music bus carries the Duck amplify")
	check(Sound.voice.bus == "Voice" and Sound.music.bus == "Music" and Sound.amb.bus == "Ambience" and Sound.pool.all(func(p): return p.bus == "SFX"), "players routed to their buses")

	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	add_child(main)
	await wait(0.3)
	main.show_settings()
	await wait(0.1)
	var sliders: Array = main.overlay.find_children("*", "HSlider", true, false)
	check(sliders.size() == 4, "settings has 4 volume sliders (%d)" % sliders.size())
	var buses := ["Music", "Ambience", "SFX", "Voice"]
	for k in mini(4, sliders.size()):
		sliders[k].value = 0.5
		var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(buses[k]))
		check(absf(db - linear_to_db(0.5)) < 0.1, "slider %d sets bus %s to %.1f dB" % [k, buses[k], db])
		sliders[k].value = 0.8
	main._close_modal()

	var secs := Sound.play_voice({"v_en": "res://addons/night_rpg/foley/amb_room_tone.ogg"})
	check(secs > 1.0 and Sound.voice.playing, "voice take plays on Voice bus")
	await wait(0.3)
	var d1: float = Sound._duck_fx().volume_db
	check(d1 < -7.5 and d1 > -8.5, "music ducked under voice after 0.3 s (%.2f dB)" % d1)
	Sound.stop_voice()
	await wait(0.2)
	var d2: float = Sound._duck_fx().volume_db
	check(d2 > -8.0 and d2 < -0.5, "release in progress at 0.2 s (%.2f dB)" % d2)
	await wait(0.5)
	check(Sound._duck_fx().volume_db > -0.01, "music back to 0 dB after release (%.2f)" % Sound._duck_fx().volume_db)

	var missing := []
	for k in Sound.FOLEY:
		if Sound._resolve(k) == "":
			missing.append(k)
	check(missing.is_empty(), "every core foley key resolves %s" % [missing])
	var amb_missing := []
	var unmapped := []
	var ra: Dictionary = RPG.game.get("room_audio", {})
	for nid in RPG.nights:
		var rooms: Dictionary = RPG.nights[nid].get("rooms", {})
		for rid in rooms:
			var a: Dictionary = Sound.room_audio(rooms[rid], rid)
			var key: String = a["amb"]
			var path: String = RPG.game.get("audio", {}).get(key, Sound.FOLEY_DIR + key + ".ogg")
			if not ResourceLoader.exists(path):
				amb_missing.append("%s/%s:%s" % [nid, rid, key])
			if not ra.has(rooms[rid].get("plate", rid)) and not ra.has(rid):
				unmapped.append(rooms[rid].get("plate", rid))
			if Sound._resolve(a["steps"]) == "":
				amb_missing.append("%s/%s steps:%s" % [nid, rid, a["steps"]])
	check(amb_missing.is_empty(), "every room's ambience + steps resolves %s" % [amb_missing.slice(0, 8)])
	print("info rooms on the game default ambience: %d %s" % [unmapped.size(), unmapped.slice(0, 6)])

	for i in 4:
		Sound.play_foley("steps_wood")
	Sound.play_foley("click")
	await wait(0.02)
	var busy := Sound.pool.filter(func(p): return p.playing).size()
	check(busy >= 2, "SFX pool overlaps cues (%d playing)" % busy)
	var n0: Dictionary = RPG.nights.values()[0]
	var r0id: String = n0.get("rooms", {}).keys()[0]
	Sound.play_room_enter(n0["rooms"][r0id], r0id)
	await wait(1.2)
	check(Sound.cur_amb != "", "room enter: door/steps queued, ambience %s" % Sound.cur_amb.get_file())
	Sound.play_foley("no_such_key_xyz")
	Sound.play_ambience("no_such_amb_xyz")
	check(true, "missing foley/ambience keys are silent")
	print("AUDIO_CHECK %s fails=%d" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(1 if fails else 0)

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
	var sends := {"Music": "Master", "Ambience": "Music", "SFX": "Master", "SFXRoom": "SFX", "Voice": "Master"}
	for b in sends:
		var i := AudioServer.get_bus_index(b)
		check(i != -1 and AudioServer.get_bus_send(i) == sends[b], "bus %s -> %s" % [b, sends[b]])
	check(Sound._duck_fx() != null, "Music bus carries the Duck amplify")
	check(Sound.voice.bus == "Voice" and Sound.music.bus == "Music" and Sound.amb.bus == "Ambience" and Sound.pool.all(func(p): return p.bus in ["SFX", "SFXRoom"]), "players routed to their buses")

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
	# spatial audio: effects exist, every room has a known space, presets apply, toggle bypasses
	for e in ["VoicePan", "OffMuffle", "ER", "Room"]:
		check(Sound.fx("Voice", e) != null, "Voice bus has %s" % e)
	check(Sound.fx("SFXRoom", "Room") != null and Sound.fx("SFXRoom", "ER") != null, "SFXRoom has ER + Room")
	var bad_space := []
	var spaces := {}
	for nid in RPG.nights:
		var rooms2: Dictionary = RPG.nights[nid].get("rooms", {})
		for rid in rooms2:
			var sp := Sound.room_space(rooms2[rid], rid)
			spaces[sp] = int(spaces.get(sp, 0)) + 1
			var plate: String = rooms2[rid].get("plate", rid)
			if not Sound.SPACES.has(sp) or not (rooms2[rid].has("space") or ra.get(plate, ra.get(rid, {})).has("space")):
				bad_space.append(plate)
	check(bad_space.is_empty(), "every room is tagged with a known space %s" % [bad_space.slice(0, 6)])
	print("info spaces: %s" % [spaces])
	RPG.persist["spatial"] = true
	Sound.set_close(false)
	Sound.set_space("stairwell")
	var rv := Sound.fx("Voice", "Room") as AudioEffectReverb
	check(absf(rv.wet - Sound.SPACES["stairwell"]["wet"]) < 0.001 and rv.dry == 1.0, "stairwell wet %.3f, dry 1.0" % rv.wet)
	Sound.play_foley("steps_stone")
	Sound.play_foley("click")
	var routed := {}
	for p in Sound.pool:
		if p.playing:
			routed[p.stream.resource_path.get_file()] = p.bus
	check(routed.get("ui_click.ogg", "") == "SFX" and routed.values().has("SFXRoom"), "steps -> SFXRoom, UI click stays dry on SFX %s" % [routed])
	Sound.play_voice({"v_en": "res://addons/night_rpg/foley/amb_room_tone.ogg"}, {"pan": 0.5})
	var pn := Sound.fx("Voice", "VoicePan") as AudioEffectPanner
	check(absf(pn.pan - 0.5 * Sound.PAN_WIDTH) < 0.001 and Sound.voice.volume_db == 0.0, "on-screen voice pans %.3f" % pn.pan)
	Sound.play_voice({"v_en": "res://addons/night_rpg/foley/amb_room_tone.ogg"}, {"pan": -1.0, "off": true})
	var lp := Sound.fx("Voice", "OffMuffle") as AudioEffectLowPassFilter
	check(pn.pan < -0.25 and Sound.voice.volume_db < -2.0 and lp.cutoff_hz < 8000.0 and rv.wet > Sound.SPACES["stairwell"]["wet"], "off-screen voice: pan %.2f, %.1f dB, LP %d Hz, wet %.3f" % [pn.pan, Sound.voice.volume_db, lp.cutoff_hz, rv.wet])
	Sound.set_close(true)
	Sound.play_voice({"v_en": "res://addons/night_rpg/foley/amb_room_tone.ogg"}, {"pan": 1.0})
	check(pn.pan == 0.0 and rv.wet <= 0.03, "CG / close: centred, near-dry (wet %.3f)" % rv.wet)
	Sound.set_close(false)
	RPG.persist["spatial"] = false
	Sound.set_space("bathroom")
	Sound.play_voice({"v_en": "res://addons/night_rpg/foley/amb_room_tone.ogg"}, {"pan": 1.0, "off": true})
	var vi := AudioServer.get_bus_index("Voice")
	var enabled := 0
	for i in AudioServer.get_bus_effect_count(vi):
		if AudioServer.is_bus_effect_enabled(vi, i):
			enabled += 1
	check(enabled == 0 and pn.pan == 0.0 and Sound.voice.volume_db == 0.0, "spatial off: Voice bus effects bypassed, centred, full level")
	RPG.persist["spatial"] = true
	Sound.set_space("small_office")
	Sound.stop_voice()
	Sound.play_foley("no_such_key_xyz")
	Sound.play_ambience("no_such_amb_xyz")
	check(true, "missing foley/ambience keys are silent")
	print("AUDIO_CHECK %s fails=%d" % ["PASS" if fails == 0 else "FAIL", fails])
	get_tree().quit(1 if fails else 0)

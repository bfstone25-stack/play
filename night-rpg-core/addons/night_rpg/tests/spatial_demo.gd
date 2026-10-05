extends Node
## Spatial audio demo: the same voice lines played in two or three rooms through the real
## runtime buses (Sound.set_space / place_voice), recorded off the Master bus to a WAV.
## Run on the GPU box only (never Godot on pop-os), headless, real time:
##   godot --headless --path <game> res://addons/night_rpg/tests/spatial_demo.tscn -- --demo=/abs/job.json
## job.json: {"out": "/abs/out.wav", "rooms": [{"label", "space", "amb", "steps", "close"?}],
##            "lines": [{"wav": "/abs/x.ogg", "pan": -1..1, "off": bool}], "gap": 0.6}
## Writes out.wav and out.json (timeline: room spans and each line's start/end, for the meters).

var rec: AudioEffectRecord
var vrec: AudioEffectRecord   # the Voice bus alone (after its effects): for the meters


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var job_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--demo="):
			job_path = a.substr(7)
	var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(job_path))
	RPG.persist["spatial"] = bool(job.get("spatial", true))
	RPG.persist["vol_ambience"] = 0.8
	RPG.persist["vol_sfx"] = 0.8
	RPG.persist["vol_voice"] = 1.0
	Sound.apply_volumes()
	rec = AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, rec)
	vrec = AudioEffectRecord.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Voice"), vrec)
	rec.set_recording_active(true)
	vrec.set_recording_active(true)
	var t0 := Time.get_ticks_msec()
	var tl := {"rooms": [], "lines": []}
	var streams := []
	for ln in job["lines"]:
		streams.append(AudioStreamOggVorbis.load_from_file(ln["wav"]))
	await wait(0.3)
	for room in job["rooms"]:
		var r0 := (Time.get_ticks_msec() - t0) / 1000.0
		Sound.play_ambience(room["amb"])
		Sound.set_close(bool(room.get("close", false)))
		Sound.set_space(room["space"])
		Sound.play_room_enter({"steps": room.get("steps", "steps_wood")}, "")
		await wait(1.6)
		for i in job["lines"].size():
			var ln: Dictionary = job["lines"][i]
			Sound.place_voice(float(ln.get("pan", 0.0)), bool(ln.get("off", false)))
			Sound.voice.stream = streams[i]
			Sound.voice.play()
			var s0 := (Time.get_ticks_msec() - t0) / 1000.0
			var dur: float = streams[i].get_length()
			await wait(dur)
			tl["lines"].append({"room": room["label"], "space": room["space"], "i": i, "start": s0, "end": s0 + dur,
				"pan": float((Sound.fx("Voice", "VoicePan") as AudioEffectPanner).pan), "off": ln.get("off", false),
				"wet": (Sound.fx("Voice", "Room") as AudioEffectReverb).wet})
			await wait(float(job.get("gap", 0.6)))
		await wait(0.6)
		tl["rooms"].append({"label": room["label"], "space": room["space"], "start": r0, "end": (Time.get_ticks_msec() - t0) / 1000.0})
	Sound.play_ambience("no_such_amb")   # fade the bed out
	await wait(0.8)
	rec.set_recording_active(false)
	vrec.set_recording_active(false)
	var w := rec.get_recording()
	var out: String = job["out"]
	if w == null or w.data.size() < 1000:
		print("SPATIAL_DEMO FAIL no audio recorded")
		get_tree().quit(1)
		return
	w.save_to_wav(out)
	var vw := vrec.get_recording()
	if vw != null:
		vw.save_to_wav(out.get_basename() + "_voicebus.wav")
	var f := FileAccess.open(out.get_basename() + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(tl, " "))
	f.close()
	print("SPATIAL_DEMO PASS %s %.1f s, %d bytes" % [out, (Time.get_ticks_msec() - t0) / 1000.0, w.data.size()])
	get_tree().quit(0)

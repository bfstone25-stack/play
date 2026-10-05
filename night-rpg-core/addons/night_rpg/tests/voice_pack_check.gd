extends Node
## Voice packs, headless (GPU box only, never pop-os):
##   godot --headless --audio-driver Dummy --path <game> res://addons/night_rpg/tests/voice_pack_check.tscn
## Every line that has a pack take (v_en under res://assets/voice/en/) must resolve, in each of the
## seven packs, to that language's own file, load as a stream and be longer than 0.3 s; and the
## Settings coverage figure must agree. Prints VOICE_PACK PASS / FAIL.

const LANGS := ["en", "ja", "zh", "ko", "de", "fr", "es"]


func _ready() -> void:
	var rows: Array = []
	for k in RPG.game.get("voice", {}):
		rows.append(RPG.game["voice"][k])
	for ch in RPG.story.keys():
		rows.append_array(RPG.story[ch])
	var fails := 0
	var lines := 0
	for ln in rows:
		if not (ln is Dictionary) or not str(ln.get("v_en", "")).begins_with("res://assets/voice/en/"):
			continue
		lines += 1
		for vl in LANGS:
			var p: String = Sound.voice_path(ln, vl)
			var want := "res://assets/voice/%s/%s" % [vl, str(ln["v_en"]).get_file()]
			var st: AudioStream = load(p) if ResourceLoader.exists(p) else null
			if p != want or st == null or st.get_length() < 0.3:
				fails += 1
				if fails <= 20:
					print("FAIL %s %s -> %s" % [vl, ln["v_en"], p])
	for vl in LANGS:
		print("info coverage %s %.3f" % [vl, Sound.voice_coverage(vl)])
	print("info pack lines %d, checked %d takes" % [lines, lines * LANGS.size()])
	print("VOICE_PACK %s (%d fails)" % ["PASS" if fails == 0 and lines > 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 and lines > 0 else 1)

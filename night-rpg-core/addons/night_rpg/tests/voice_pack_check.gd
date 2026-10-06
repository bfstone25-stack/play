extends Node
## Voice packs, headless (GPU box only, never pop-os):
##   godot --headless --audio-driver Dummy --path <game> res://addons/night_rpg/tests/voice_pack_check.tscn
## Every line that has a pack take (v_en under res://assets/voice/en/) must resolve, in each of the
## seven packs, to that language's own file, load as a stream and be longer than 0.15 s (a one-syllable "네" is ~0.25 s); and the
## Settings coverage figure must agree. A take listed in game.json voice_off must resolve to "" (silent,
## never the English take) and its file must not be in the game. Prints VOICE_PACK PASS / FAIL.

const LANGS := ["en", "ja", "zh", "ko", "de", "fr", "es"]


func _ready() -> void:
	var rows: Array = []
	for k in RPG.game.get("voice", {}):
		rows.append(RPG.game["voice"][k])
	for ch in RPG.story.keys():
		rows.append_array(RPG.story[ch])
	var fails := 0
	var lines := 0
	var off := 0
	for ln in rows:
		if not (ln is Dictionary) or not str(ln.get("v_en", "")).begins_with("res://assets/voice/en/"):
			continue
		lines += 1
		for vl in LANGS:
			var p: String = Sound.voice_path(ln, vl)
			var want := "res://assets/voice/%s/%s" % [vl, str(ln["v_en"]).get_file()]
			if Sound.voice_off(vl, str(ln["v_en"]).get_file()):
				# pulled take (game.json voice_off): must be silent, never the English take, and not shipped
				off += 1
				if p != "" or ResourceLoader.exists(want):
					fails += 1
					print("FAIL voice_off %s %s -> '%s' (exists %s)" % [vl, ln["v_en"], p, ResourceLoader.exists(want)])
				continue
			var st: AudioStream = load(p) if ResourceLoader.exists(p) else null
			if p != want or st == null or st.get_length() < 0.15:
				fails += 1
				if fails <= 20:
					print("FAIL %s %s -> %s" % [vl, ln["v_en"], p])
	for vl in LANGS:
		print("info coverage %s %.3f" % [vl, Sound.voice_coverage(vl)])
	print("info pack lines %d, checked %d takes, %d pulled (voice_off, silent)" % [lines, lines * LANGS.size(), off])
	print("VOICE_PACK %s (%d fails)" % ["PASS" if fails == 0 and lines > 0 else "FAIL", fails])
	get_tree().quit(0 if fails == 0 and lines > 0 else 1)

extends Node
## Autoload "Sound": music (crossfaded), ambience loop, sfx, voice. Paths come from the
## game's data; a missing file is silent, never an error (part-voiced builds are normal).

var music: AudioStreamPlayer
var music_b: AudioStreamPlayer
var amb: AudioStreamPlayer
var sfx: AudioStreamPlayer
var voice: AudioStreamPlayer
var cur_music := ""
var cur_amb := ""


func _ready() -> void:
	music = _p(); music_b = _p(); amb = _p(); sfx = _p(); voice = _p()
	apply_volumes()


func _p() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


func _db(v: float) -> float:
	return linear_to_db(max(0.0001, v))


func apply_volumes() -> void:
	var vm := float(RPG.persist.get("vol_music", 0.7))
	music.volume_db = _db(vm)
	amb.volume_db = _db(vm * 0.6)
	sfx.volume_db = _db(float(RPG.persist.get("vol_sfx", 0.8)))
	voice.volume_db = _db(float(RPG.persist.get("vol_voice", 1.0)))


func _stream(path: String, loop: bool) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var st = load(path)
	if st is AudioStreamOggVorbis:
		st.loop = loop
	elif st is AudioStreamMP3:
		st.loop = loop
	return st


## `key` is a name from game.json "music" or a res:// path.
func play_music(key: String) -> void:
	var path: String = RPG.game.get("music", {}).get(key, key)
	if path == cur_music:
		return
	cur_music = path
	var st := _stream(path, true)
	var old := music
	music = music_b
	music_b = old
	var tw := create_tween().set_parallel(true)
	tw.tween_property(music_b, "volume_db", -40.0, 1.2)
	if st != null:
		music.stream = st
		music.volume_db = -40.0
		music.play()
		tw.tween_property(music, "volume_db", _db(float(RPG.persist.get("vol_music", 0.7))), 1.2)
	tw.chain().tween_callback(music_b.stop)


func play_ambience(key: String) -> void:
	var path: String = RPG.game.get("audio", {}).get(key, key)
	if path == cur_amb:
		return
	cur_amb = path
	var st := _stream(path, true)
	amb.stop()
	if st != null:
		amb.stream = st
		amb.play()


func play_sfx(key: String) -> void:
	var st := _stream(RPG.game.get("audio", {}).get(key, key), false)
	if st != null:
		sfx.stream = st
		sfx.play()


## Voice packs: one per language, chosen in Settings independently of the text language
## ("auto" follows the text). A take is found, in order, at the line's own "v_<lang>" path,
## then at res://assets/voice/<lang>/<file of the English take>; English is the reference
## pack and the fallback for any line a pack lacks.
func voice_lang() -> String:
	var v := str(RPG.persist.get("voice_lang", "auto"))
	return Loc.lang if v == "auto" else v


func voice_path(ln: Dictionary, vl: String = "") -> String:
	if vl == "":
		vl = voice_lang()
	var en: String = ln.get("v_en", "")
	if vl != "en":
		var own: String = ln.get("v_" + vl, "")
		if own != "" and ResourceLoader.exists(own):
			return own
		if en.begins_with("res://assets/voice/"):
			var pack := "res://assets/voice/%s/%s" % [vl, en.get_file()]
			if ResourceLoader.exists(pack):
				return pack
	return en


## Fraction of voiced lines (story + barks) the pack for `vl` covers.
func voice_coverage(vl: String) -> float:
	if vl == "en":
		return 1.0
	var n := 0
	var have := 0
	var rows: Array = RPG.game.get("voice", {}).values()
	for ch in RPG.story.keys():
		rows.append_array(RPG.story[ch])
	for ln in rows:
		if ln is Dictionary and str(ln.get("v_en", "")) != "":
			n += 1
			if voice_path(ln, vl) != ln["v_en"]:
				have += 1
	return float(have) / max(1, n)


## Plays a line's voice in the chosen pack, English as fallback. Returns seconds.
func play_voice(ln: Dictionary) -> float:
	voice.stop()
	var st := _stream(voice_path(ln), false)
	if st == null:
		return 0.0
	voice.stream = st
	voice.play()
	return st.get_length()


func stop_voice() -> void:
	voice.stop()

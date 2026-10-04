extends Node
## Autoload "Sound": music (crossfaded), ambience loop, foley/SFX pool, voice. Paths come
## from the game's data; a missing file is silent, never an error (part-voiced builds are
## normal).
##
## Buses (audio/default_bus_layout.tres, also rebuilt here if a project lacks it):
##   Master <- Music <- Ambience      (Music carries the "Duck" amplify: -8 dB under voice)
##   Master <- SFX                    (foley + UI, a pool of players so steps never cut clicks)
##   Master <- Voice                  (clean dialogue only — never bake foley into a take)
## Settings sliders set BUS volumes (vol_music, vol_ambience, vol_sfx, vol_voice).

const BUSES := [["Music", "Master"], ["Ambience", "Music"], ["SFX", "Master"], ["Voice", "Master"]]
const DUCK_DB := -8.0
const DUCK_ATTACK := 0.15    # s to reach DUCK_DB once the voice starts
const DUCK_RELEASE := 0.40   # s to come back after it stops
const POOL := 6
const FOLEY_DIR := "res://addons/night_rpg/foley/"
## Core foley: key -> variants (one picked at random, never the same twice in a row).
## A game overrides or adds keys in game.json "foley" (key -> path or [paths]).
const FOLEY := {
	"steps_wood": ["steps_wood_1", "steps_wood_2", "steps_wood_3"],
	"steps_stone": ["steps_stone_1", "steps_stone_2", "steps_stone_3"],
	"steps_carpet": ["steps_carpet_1", "steps_carpet_2"],
	"door": ["door_open_1", "door_open_2"],
	"door_close": ["door_close_1", "door_close_2", "door_close_3"],
	"door_metal": ["door_metal"],
	"paper": ["paper_1", "paper_2", "paper_3"],
	"paper_place": ["paper_place_1", "paper_place_2"],
	"book_close": ["book_close"],
	"writing": ["writing_1", "writing_2"],
	"search": ["search_1", "search_2"],
	"cloth": ["cloth_1", "cloth_2", "cloth_3"],
	"cloth_soft": ["cloth_soft_1", "cloth_soft_2"],
	"embrace": ["embrace_1", "embrace_2"],
	"belt": ["belt"],
	"hit": ["hit_1", "hit_2", "hit_3"],
	"hit_heavy": ["hit_heavy_1", "hit_heavy_2"],
	"hit_soft": ["hit_soft_1", "hit_soft_2"],
	"desk_slam": ["desk_slam"],
	"click": ["ui_click"],
	"page_flip": ["paper_1", "paper_2", "paper_3"],
	"ui_open": ["ui_open"],
	"ui_close": ["ui_close"],
	"ui_confirm": ["ui_confirm"],
	"coins": ["coins"],
}
## Core ambience loops; game.json "room_audio" maps a room plate -> {"amb": key, "steps": key}.
const AMB := ["amb_rain_window", "amb_rain_street", "amb_office", "amb_server", "amb_hotel_hall",
	"amb_cellar", "amb_library", "amb_street_night", "amb_club", "amb_wind", "amb_boiler",
	"amb_room_tone", "amb_cafe"]

var music: AudioStreamPlayer
var music_b: AudioStreamPlayer
var amb: AudioStreamPlayer
var sfx: AudioStreamPlayer          # first of the pool (kept for old callers)
var pool: Array[AudioStreamPlayer] = []
var voice: AudioStreamPlayer
var cur_music := ""
var cur_music_key := ""
var cur_amb := ""
var duck_db := 0.0
var _pool_i := 0
var _last := {}


func _ready() -> void:
	_ensure_buses()
	music = _p("Music"); music_b = _p("Music"); amb = _p("Ambience"); voice = _p("Voice")
	for i in POOL:
		pool.append(_p("SFX"))
	sfx = pool[0]
	apply_volumes()


## The layout comes from project.godot [audio] buses/default_bus_layout; anything missing
## (a project not yet pointed at it, a test scene) is created so routing never falls to Master.
func _ensure_buses() -> void:
	for pair in BUSES:
		if AudioServer.get_bus_index(pair[0]) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, pair[0])
		AudioServer.set_bus_send(AudioServer.get_bus_index(pair[0]), pair[1])
	var mi := AudioServer.get_bus_index("Music")
	if _duck_fx() == null:
		var a := AudioEffectAmplify.new()
		a.resource_name = "Duck"
		AudioServer.add_bus_effect(mi, a, 0)


func _duck_fx() -> AudioEffectAmplify:
	var mi := AudioServer.get_bus_index("Music")
	for i in AudioServer.get_bus_effect_count(mi):
		var e := AudioServer.get_bus_effect(mi, i)
		if e is AudioEffectAmplify and e.resource_name == "Duck":
			return e
	return null


func _p(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Music (and the ambience under it) dips DUCK_DB while a voice take plays.
func _process(delta: float) -> void:
	var target := DUCK_DB if voice != null and voice.playing else 0.0
	if duck_db != target:
		var rate := absf(DUCK_DB) / (DUCK_ATTACK if target < duck_db else DUCK_RELEASE)
		duck_db = move_toward(duck_db, target, rate * delta)
		var fx := _duck_fx()
		if fx != null:
			fx.volume_db = duck_db


func _db(v: float) -> float:
	return linear_to_db(max(0.0001, v))


func _set_bus(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i != -1:
		AudioServer.set_bus_volume_db(i, _db(v))
		AudioServer.set_bus_mute(i, v <= 0.001)


func apply_volumes() -> void:
	_set_bus("Music", float(RPG.persist.get("vol_music", 0.7)))
	_set_bus("Ambience", float(RPG.persist.get("vol_ambience", 0.8)))
	_set_bus("SFX", float(RPG.persist.get("vol_sfx", 0.8)))
	_set_bus("Voice", float(RPG.persist.get("vol_voice", 1.0)))


func _stream(path: String, loop: bool) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var st = load(path)
	if st is AudioStreamOggVorbis:
		st.loop = loop
	elif st is AudioStreamMP3:
		st.loop = loop
	elif st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	return st


## `key` is a name from game.json "music" or a res:// path.
func play_music(key: String) -> void:
	var path: String = RPG.game.get("music", {}).get(key, key)
	cur_music_key = key
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
		tw.tween_property(music, "volume_db", 0.0, 1.2)
	tw.chain().tween_callback(music_b.stop)


## `key`: game.json "audio" key, a core ambience key (amb_*), or a res:// path.
func play_ambience(key: String) -> void:
	var path: String = RPG.game.get("audio", {}).get(key, key)
	if key in AMB and not RPG.game.get("audio", {}).has(key):
		path = FOLEY_DIR + key + ".ogg"
	if path == cur_amb:
		return
	cur_amb = path
	var st := _stream(path, true)
	var old := amb
	if st == null:
		old.stop()
		return
	var tw := create_tween()
	tw.tween_property(old, "volume_db", -40.0, 0.6)
	tw.tween_callback(func():
		old.stream = st
		old.play()
		old.volume_db = -40.0)
	tw.tween_property(old, "volume_db", 0.0, 0.8)


## The room's ambience: data/game.json "room_audio"[plate].amb, else the room's own
## "ambience", else the game's "ambience".
func room_audio(room: Dictionary, room_id: String = "") -> Dictionary:
	var ra: Dictionary = RPG.game.get("room_audio", {})
	var d: Dictionary = ra.get(room.get("plate", room_id), ra.get(room_id, {}))
	return {"amb": room.get("ambience", d.get("amb", "ambience")), "steps": room.get("steps", d.get("steps", ra.get("_steps", "steps_wood")))}


func play_room(room: Dictionary, room_id: String = "") -> void:
	play_ambience(room_audio(room, room_id)["amb"])


func _pool_next() -> AudioStreamPlayer:
	for i in POOL:   # prefer an idle voice; else steal the oldest (round-robin)
		var p := pool[(_pool_i + i) % POOL]
		if not p.playing:
			_pool_i = (_pool_i + i + 1) % POOL
			return p
	var p2 := pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL
	return p2


func _resolve(key: String) -> String:
	var a: Dictionary = RPG.game.get("audio", {})
	var f: Dictionary = RPG.game.get("foley", {})
	var cand = f.get(key, a.get(key, null))
	var paths: Array = []
	if cand is Array:
		paths = cand
	elif cand is String:
		paths = [cand]
	elif FOLEY.has(key):
		for n in FOLEY[key]:
			paths.append(FOLEY_DIR + n + ".ogg")
	else:
		paths = [key]
	paths = paths.filter(func(x): return ResourceLoader.exists(str(x)))
	if paths.is_empty():
		if cand != null and FOLEY.has(key):   # the game's own file is missing: core fallback
			for n in FOLEY[key]:
				if ResourceLoader.exists(FOLEY_DIR + n + ".ogg"):
					paths.append(FOLEY_DIR + n + ".ogg")
		if paths.is_empty():
			return ""
	if paths.size() == 1:
		return paths[0]
	var pick: String = paths[randi() % paths.size()]
	if pick == _last.get(key, ""):
		pick = paths[(paths.find(pick) + 1) % paths.size()]
	_last[key] = pick
	return pick


## One-shot on the SFX bus from the pool. `db` trims this cue; `delay` in seconds.
func play_foley(key: String, db: float = 0.0, delay: float = 0.0) -> void:
	var path := _resolve(key)
	if path == "":
		return
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(func(): play_foley(key, db))
		return
	var st := _stream(path, false)
	if st == null:
		return
	var p := _pool_next()
	p.stream = st
	p.volume_db = db
	p.pitch_scale = randf_range(0.96, 1.04)
	p.play()


## Old name: same pool.
func play_sfx(key: String) -> void:
	play_foley(key)


## Walking into a room: door, a few steps on that room's floor, the door settling behind.
func play_room_enter(room: Dictionary, room_id: String = "") -> void:
	var steps: String = room_audio(room, room_id)["steps"]
	play_foley(str(room.get("door_sfx", "door")), -2.0)
	play_foley(steps, -4.0, 0.35)
	play_foley(steps, -5.0, 0.75)
	play_foley("door_close", -6.0, 1.05)


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

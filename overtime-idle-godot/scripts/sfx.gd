extends Node
## Sfx autoload — the cue points of the prototype's audio.js, one method each, with
## synthesised placeholder tones (the same oscillator recipes as the JS: a triangle glide
## for a placement, a rising pentatonic note per chain link, a sawtooth drop for an
## eviction). Swap any cue for a real sample by dropping an AudioStream into SAMPLES.

var muted := false
var chain := 0
var master: AudioStreamPlayer
var _players: Array = []
var _cache: Dictionary = {}
var drone: AudioStreamPlayer
const RATE := 22050
const PENTA := [196.0, 220.0, 261.63, 293.66, 329.63, 392.0]
## Real samples go here, keyed by cue name; a missing key falls back to the tone.
var SAMPLES: Dictionary = {}


func _ready() -> void:
	for _i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	drone = AudioStreamPlayer.new()
	drone.volume_db = -26.0
	add_child(drone)
	_bark_ready()
func set_muted(on: bool) -> void:
	muted = on
	if muted:
		drone.stop()
	else:
		start_drone()


func set_chain(n: int) -> void:
	chain = clamp(n, 0, 5)


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(clamp(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	s.data = bytes
	return s


## tone(): freq, type (sine|triangle|square|sawtooth), duration s, volume, glide target.
func _tone(freq: float, type: String, dur: float, vol: float, glide_to: float = 0.0) -> AudioStreamWAV:
	var key := "%s:%d:%d:%d:%d" % [type, int(freq), int(dur * 1000), int(vol * 100), int(glide_to)]
	if _cache.has(key):
		return _cache[key]
	var n := int(RATE * (dur + 0.04))
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var f := freq
		if glide_to > 0.0:
			f = freq * pow(max(glide_to, 1.0) / freq, min(1.0, t / dur))
		phase += f / RATE
		var x := fmod(phase, 1.0)
		var v := 0.0
		match type:
			"sine": v = sin(x * TAU)
			"triangle": v = 4.0 * abs(x - 0.5) - 1.0
			"square": v = 1.0 if x < 0.5 else -1.0
			"sawtooth": v = 2.0 * x - 1.0
		var env: float = (min(1.0, t / 0.014) * exp(-4.5 * t / dur)) if t < dur else 0.0
		out[i] = v * env * vol
	var s := _wav(out)
	_cache[key] = s
	return s


func _noise(dur: float, vol: float) -> AudioStreamWAV:
	var key := "noise:%d:%d" % [int(dur * 1000), int(vol * 100)]
	if _cache.has(key):
		return _cache[key]
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(n):
		out[i] = (rng.randf() * 2.0 - 1.0) * (1.0 - float(i) / n) * vol
	var s := _wav(out)
	_cache[key] = s
	return s


func _play(stream: AudioStream, delay: float = 0.0) -> void:
	if muted or stream == null:
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = -6.0
			p.play()
			return


func _cue(name: String) -> bool:
	if SAMPLES.has(name):
		_play(SAMPLES[name])
		return true
	return false


func start_drone() -> void:
	if muted or drone.playing:
		return
	if drone.stream == null:
		var n := RATE * 2
		var out := PackedFloat32Array()
		out.resize(n)
		for i in range(n):
			out[i] = sin(float(i) / RATE * 78.0 * TAU) * 0.6
		var s := _wav(out)
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = n
		drone.stream = s
	drone.play()


func unlock() -> void:
	start_drone()


# ---- the cue points, one per audio.js method -------------------------------------

func place() -> void:
	if _cue("place"): return
	_play(_tone(420.0, "triangle", 0.07, 0.5, 280.0))
	_play(_noise(0.03, 0.15))


func reroll() -> void:
	if _cue("reroll"): return
	_play(_tone(180.0, "square", 0.08, 0.25))
	_play(_tone(240.0, "triangle", 0.1, 0.3), 0.05)


func settle(n: int) -> void:
	if _cue("settle"): return
	var step: int = min(5, n)
	var notes := [261.0, 329.0, 392.0].slice(0, 1 + min(2, step))
	for i in range(notes.size()):
		_play(_tone(notes[i], "triangle", 0.2, 0.45), i * 0.05)
	_play(_noise(0.08, 0.2))


func combo() -> void:
	if _cue("combo"): return
	var f: float = PENTA[chain]
	_play(_tone(f, "sine", 0.16, 0.5, f * 1.25))


func shop() -> void:
	if _cue("shop"): return
	_play(_tone(330.0, "triangle", 0.12, 0.4))


func evict() -> void:
	if _cue("evict"): return
	_play(_tone(140.0, "sawtooth", 0.28, 0.35, 70.0))
	_play(_tone(98.0, "sine", 0.36, 0.45), 0.04)


func win() -> void:
	if _cue("win"): return
	var notes := [261.0, 329.0, 392.0, 523.0]
	for i in range(notes.size()):
		_play(_tone(notes[i], "triangle", 0.2, 0.4), i * 0.07)


## New in the Godot shell: the gacha flip and the rolling counter tick.
func flip(rarity: String) -> void:
	if _cue("flip_" + rarity): return
	match rarity:
		"epic": _play(_tone(523.0, "sine", 0.35, 0.5, 1046.0))
		"rare": _play(_tone(392.0, "triangle", 0.2, 0.4, 523.0))
		_: _play(_tone(261.0, "triangle", 0.09, 0.3))


func tick() -> void:
	if _cue("tick"): return
	_play(_tone(1200.0, "square", 0.015, 0.08))

# --- barks -------------------------------------------------------------------------------
#
# The spoken lines (ops/barks/lines.json, rendered by ops/barks/render_barks.py). They ride
# the same mute switch as every other cue here, because a player who muted the game meant
# all of it, and they get their own AudioStreamPlayer so a bark never steals a cue's voice.
#
# Three rules, each one the reason a bark set stops being charming:
#   * rotate, and never repeat back to back;
#   * never overlap a bark with a bark -- the second is DROPPED, not queued, because by
#     the time the first ends the moment it belonged to is gone;
#   * one voice per game, so the title has an identity.
const BARKS := "res://assets/voice/"

var _bark: AudioStreamPlayer
var _bark_map: Dictionary = {}
var _bark_last: Dictionary = {}


func _bark_ready() -> void:
	_bark = AudioStreamPlayer.new()
	_bark.bus = "Master"
	_bark.volume_db = 2.0
	add_child(_bark)
	var f := FileAccess.open(BARKS + "barks.json", FileAccess.READ)
	if f == null:
		return                      # no barks installed in this build; stay silent
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_bark_map = parsed


## Say one line from `slot`. False when nothing was said, so a caller can fall back.
func bark(slot: String) -> bool:
	if _bark == null or not _bark_map.has(slot):
		return false
	if _muted():
		return false
	if _bark.playing:
		return false                # one voice at a time; see the header
	var files: Array = _bark_map[slot]
	if files.is_empty():
		return false
	var i := randi() % files.size()
	if files.size() > 1 and i == int(_bark_last.get(slot, -1)):
		i = (i + 1) % files.size()
	_bark_last[slot] = i
	var path: String = BARKS + str(files[i])
	if not ResourceLoader.exists(path):
		return false
	_bark.stream = load(path)
	_bark.play()
	return true


## Whatever this game calls "the player turned sound off".
func _muted() -> bool:
	return muted

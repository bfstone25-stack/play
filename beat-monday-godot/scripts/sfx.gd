extends Node
## Sfx autoload — synthesised placeholder cues (the same oscillator recipes as
## play/overtime-idle-godot/scripts/sfx.gd). One method per cue; drop an AudioStream into
## SAMPLES under the cue's name to replace a tone with a real sample. No music yet.

var muted := false
var _players: Array = []
var _cache: Dictionary = {}
var _last: Dictionary = {}
const RATE := 22050
var SAMPLES: Dictionary = {}


func _ready() -> void:
	for _i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_bark_ready()
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


func _tone(freq: float, type: String, dur: float, vol: float, glide_to: float = 0.0) -> AudioStreamWAV:
	var key := "%s:%d:%d:%d:%d" % [type, int(freq), int(dur * 1000), int(vol * 100), int(glide_to)]
	if _cache.has(key):
		return _cache[key]
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var f := freq if glide_to <= 0.0 else lerpf(freq, glide_to, t / dur)
		phase += TAU * f / RATE
		var v := 0.0
		match type:
			"sine": v = sin(phase)
			"triangle": v = 2.0 / PI * asin(sin(phase))
			"square": v = 1.0 if sin(phase) > 0.0 else -1.0
			_: v = 2.0 * (fmod(phase / TAU, 1.0)) - 1.0
		var env := minf(1.0, t / 0.008) * (1.0 - t / dur)
		out[i] = v * vol * env
	var s := _wav(out)
	_cache[key] = s
	return s


func _noise(dur: float, vol: float, lowpass := 0.5) -> AudioStreamWAV:
	var key := "noise:%d:%d:%d" % [int(dur * 1000), int(vol * 100), int(lowpass * 100)]
	if _cache.has(key):
		return _cache[key]
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in range(n):
		var t := float(i) / RATE
		last = lerpf(last, randf_range(-1.0, 1.0), lowpass)
		out[i] = last * vol * (1.0 - t / dur)
	var s := _wav(out)
	_cache[key] = s
	return s


func _play(stream: AudioStream, delay: float = 0.0, db := 0.0) -> void:
	if muted:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = db
			if delay > 0.0:
				get_tree().create_timer(delay).timeout.connect(p.play)
			else:
				p.play()
			return


## A sample overrides the tone; returns true when it played one. `gap` rate-limits a cue.
func _cue(name: String, gap := 0.0) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if gap > 0.0 and now - float(_last.get(name, -10.0)) < gap:
		return true
	_last[name] = now
	if SAMPLES.has(name):
		_play(SAMPLES[name])
		return true
	return false


func fire() -> void:
	if _cue("fire", 0.09):
		return
	_play(_tone(880.0, "triangle", 0.05, 0.18, 1400.0), 0.0, -8.0)


func rant() -> void:
	if _cue("rant", 0.09):
		return
	_play(_tone(330.0, "square", 0.08, 0.16, 520.0), 0.0, -8.0)


func hit() -> void:
	if _cue("hit", 0.05):
		return
	_play(_noise(0.06, 0.4, 0.35), 0.0, -6.0)


func hurt() -> void:
	if _cue("hurt", 0.25):
		return
	_play(_tone(240.0, "sawtooth", 0.18, 0.35, 90.0))


func pickup() -> void:
	if _cue("pickup"):
		return
	_play(_tone(660.0, "sine", 0.09, 0.3))
	_play(_tone(990.0, "sine", 0.12, 0.3), 0.08)


func levelup() -> void:
	if _cue("levelup"):
		return
	for i in 3:
		_play(_tone([523.25, 659.25, 783.99][i], "triangle", 0.16, 0.35), i * 0.09)


func clear() -> void:
	if _cue("clear"):
		return
	for i in 4:
		_play(_tone([392.0, 523.25, 659.25, 783.99][i], "triangle", 0.22, 0.4), i * 0.11)


func dead() -> void:
	if _cue("dead"):
		return
	_play(_tone(220.0, "sawtooth", 0.5, 0.4, 60.0))
	_play(_noise(0.3, 0.3, 0.2), 0.1)


func tap() -> void:
	if _cue("tap"):
		return
	_play(_tone(1200.0, "sine", 0.03, 0.2), 0.0, -10.0)

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

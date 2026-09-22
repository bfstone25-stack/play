extends Node
## Sfx autoload — the cue points, synthesised placeholders (the kernel's sfx.js recipe:
## short oscillator tones). knock: the wooden fish, a damped low triangle. rattle: sticks
## in the tube, a burst of short noisy clicks. drop: one stick falling out. chime: a
## reveal. hush: the reader's beat. Drop an AudioStream into SAMPLES to replace any cue.

const RATE := 22050
var muted := false
var _players: Array = []
var _cache: Dictionary = {}
var SAMPLES: Dictionary = {}
var _next := 0


func _ready() -> void:
	for _i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bark_ready()
func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	s.data = bytes
	return s


func _tone(freq: float, kind: String, dur: float, vol: float, glide: float = 1.0, decay: float = 6.0) -> AudioStreamWAV:
	var key := "%s:%d:%d:%d:%d" % [kind, int(freq), int(dur * 1000), int(glide * 100), int(decay)]
	if _cache.has(key):
		return _cache[key]
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / RATE
		var f := freq * lerpf(1.0, glide, t / dur)
		phase += f / RATE
		var v := 0.0
		match kind:
			"sine": v = sin(phase * TAU)
			"tri": v = 2.0 * absf(2.0 * (phase - floor(phase + 0.5))) - 1.0
			"noise": v = randf() * 2.0 - 1.0
			_: v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		var env := exp(-decay * t / dur) * minf(1.0, t * 400.0)
		out[i] = v * env * vol
	var w := _wav(out)
	_cache[key] = w
	return w


func _play(stream: AudioStream, db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or stream == null:
		return
	var p: AudioStreamPlayer = _players[_next % _players.size()]
	_next += 1
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


func knock() -> void:
	_play(SAMPLES.get("knock", _tone(180.0, "tri", 0.16, 0.7, 0.6, 8.0)), -4.0, randf_range(0.96, 1.04))


func rattle() -> void:
	_play(SAMPLES.get("rattle", _tone(2400.0, "noise", 0.05, 0.35, 1.0, 5.0)), -8.0, randf_range(0.7, 1.3))


func drop() -> void:
	_play(SAMPLES.get("drop", _tone(900.0, "tri", 0.12, 0.6, 0.5, 10.0)), -6.0)


func chime(pitch: float = 1.0) -> void:
	_play(SAMPLES.get("chime", _tone(880.0, "sine", 1.2, 0.5, 1.0, 4.0)), -8.0, pitch)


func hush() -> void:
	_play(SAMPLES.get("hush", _tone(110.0, "sine", 1.6, 0.3, 0.9, 3.0)), -14.0)


func flip() -> void:
	_play(SAMPLES.get("flip", _tone(1400.0, "noise", 0.08, 0.3, 1.0, 6.0)), -12.0)

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

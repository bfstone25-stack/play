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

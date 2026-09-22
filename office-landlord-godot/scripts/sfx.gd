extends Node
## Sfx autoload — Office Landlord's cue points, structured after
## play/overtime-idle-godot/scripts/sfx.gd: synthesised placeholder tones (an oscillator
## recipe per cue, no sample files required) PLUS the bark() machinery reading
## res://assets/voice/barks.json, one voice at a time, never repeating a slot back-to-back.
##
## A smaller cue set than Overtime's (no drone, no gacha `flip`) because this is the small
## all-ages sibling: place a symbol, collect rent, get evicted, buy in the shop, a UI tick.

var muted := false
var _players: Array = []
var _cache: Dictionary = {}
const RATE := 22050

func _ready() -> void:
	for _i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_bark_ready()

func set_muted(on: bool) -> void:
	muted = on

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

## tone(): freq, type (sine|triangle|square|sawtooth), duration s, volume, optional glide.
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

# ---- the cue points, one per moment in grid.gd's loop -----------------------------------

func place() -> void:
	_play(_tone(420.0, "triangle", 0.07, 0.5, 280.0))

func settle(payout: int) -> void:
	var step: int = min(3, payout)
	for i in range(max(1, step)):
		_play(_tone(261.0 + i * 68.0, "triangle", 0.16, 0.4), i * 0.05)

func rent_paid() -> void:
	var notes := [261.0, 329.0, 392.0, 523.0]
	for i in range(notes.size()):
		_play(_tone(notes[i], "triangle", 0.18, 0.4), i * 0.06)

func evict() -> void:
	_play(_tone(150.0, "sawtooth", 0.24, 0.32, 80.0))

func buy() -> void:
	_play(_tone(330.0, "triangle", 0.1, 0.35))

func tick() -> void:
	_play(_tone(1200.0, "square", 0.015, 0.08))

# --- barks -------------------------------------------------------------------------------
# Same contract as Overtime's: res://assets/voice/barks.json maps slot -> Array[filename],
# one voice at a time (a second bark call while one is playing is dropped, not queued),
# never the same file twice in a row within a slot.
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

func bark(slot: String) -> bool:
	if _bark == null or not _bark_map.has(slot):
		return false
	if muted:
		return false
	if _bark.playing:
		return false
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

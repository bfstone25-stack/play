extends Node
## Sfx autoload — the cabinet's voice. Synthesised cues built on the same oscillator
## recipes as play/beat-monday-godot/scripts/sfx.gd and play/overtime-idle-godot; one
## method per cue, and dropping an AudioStream into SAMPLES under a cue's name replaces
## that tone with a real sample without touching a call site.
##
## The set is a pinball cabinet's: a plunger release, a bumper thump, a chime that climbs
## with the combo, an intercom for the drop targets, the water cannon, a drain, and the
## title sting the first screen needs (ops/adult_forks/TITLE_SCREENS.md item 6).

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


func tap() -> void:
	if _cue("tap"):
		return
	_play(_tone(1200.0, "sine", 0.03, 0.2), 0.0, -10.0)


## The plunger letting go — a spring, not a beep. Pitch rises with the charge.
func launch(charge: float) -> void:
	if _cue("launch", 0.08):
		return
	_play(_tone(180.0 + charge * 140.0, "sawtooth", 0.12, 0.28, 620.0 + charge * 400.0), 0.0, -5.0)
	_play(_noise(0.09, 0.22, 0.6), 0.02, -9.0)


## A flipper. Short, mechanical, rate-limited so a held key does not machine-gun.
func flip() -> void:
	if _cue("flip", 0.06):
		return
	_play(_tone(140.0, "square", 0.04, 0.22, 90.0), 0.0, -9.0)


## A bumper thump: low body, bright click on top.
func bumper() -> void:
	if _cue("bumper", 0.04):
		return
	_play(_tone(120.0, "sine", 0.09, 0.42, 70.0), 0.0, -4.0)
	_play(_noise(0.04, 0.3, 0.5), 0.0, -8.0)


## The coin chime. Climbs a pentatonic ladder with the combo, so eight in a row is a run
## up the scale rather than the same ping eight times.
func coin(combo: int) -> void:
	if _cue("coin", 0.03):
		return
	const LADDER := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98]
	var f: float = LADDER[clampi(combo, 0, LADDER.size() - 1)]
	_play(_tone(f, "triangle", 0.08, 0.26), 0.0, -7.0)


## A drop target / the gate jackpot: the booth intercom.
func intercom() -> void:
	if _cue("intercom", 0.08):
		return
	_play(_tone(740.0, "square", 0.07, 0.16), 0.0, -10.0)
	_play(_tone(560.0, "square", 0.09, 0.16), 0.07, -10.0)


## The saucer firing the ball back out: water under pressure.
func cannon() -> void:
	if _cue("cannon", 0.15):
		return
	_play(_noise(0.34, 0.34, 0.75), 0.0, -4.0)
	_play(_tone(200.0, "sine", 0.3, 0.24, 900.0), 0.0, -7.0)


## A ball down the drain.
func drain() -> void:
	if _cue("drain", 0.2):
		return
	_play(_tone(330.0, "sawtooth", 0.34, 0.32, 80.0), 0.0, -5.0)


## The doorman caught it.
func save_ball() -> void:
	if _cue("save_ball", 0.2):
		return
	_play(_tone(440.0, "triangle", 0.1, 0.3), 0.0, -7.0)
	_play(_tone(880.0, "triangle", 0.14, 0.3), 0.09, -7.0)


## A purchase in the ledger.
func buy() -> void:
	if _cue("buy", 0.08):
		return
	_play(_tone(660.0, "sine", 0.08, 0.28), 0.0, -8.0)
	_play(_tone(990.0, "sine", 0.11, 0.24), 0.07, -8.0)


## The night ends.
func nightover() -> void:
	if _cue("nightover"):
		return
	for i in 3:
		_play(_tone([392.0, 311.13, 261.63][i], "sawtooth", 0.3, 0.33), i * 0.14, -5.0)


## Prestige: the booth is left behind, the gold is kept.
func prestige() -> void:
	if _cue("prestige"):
		return
	for i in 4:
		_play(_tone([392.0, 523.25, 659.25, 830.61][i], "triangle", 0.26, 0.4), i * 0.11, -4.0)


## The title sting — the cabinet waking up. Two seconds of life before anything is pressed
## (TITLE_SCREENS.md item 3/6): a low hum, a brass swell, one coin.
func title_sting() -> void:
	if _cue("title_sting", 3.0):
		return
	_play(_tone(98.0, "sine", 1.6, 0.22), 0.0, -8.0)
	_play(_tone(146.83, "triangle", 1.2, 0.18, 196.0), 0.18, -10.0)
	_play(_tone(1046.5, "sine", 0.5, 0.22), 0.9, -9.0)


## The night's ambient bed: a slow sodium-lamp hum under the title, restarted by the caller.
func ambient() -> void:
	if muted:
		return
	_play(_tone(58.0, "sine", 4.0, 0.1), 0.0, -16.0)
	_play(_tone(87.0, "sine", 4.0, 0.06), 0.4, -20.0)

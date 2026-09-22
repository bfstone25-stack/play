## Sfx — FOLD's sound, ported from the page's FOLD_AUDIO closure. Autoloaded as "Sfx".
##
## The web game has no audio files: every cue is a Web Audio oscillator with an
## exponential pitch fall and an exponential gain envelope. That is the game's voice —
## paper, wood, metal and silence — and swapping it for a folder of samples would be a
## different game to listen to. So the same synthesis is done here, into AudioStreamWAV
## buffers built once at boot, and the cues play those.
##
## The JS envelope, reproduced term for term:
##   f(t) = freq * (fall ^ (t/dur))                      exponentialRampToValueAtTime
##   g(t) = 0.0001 -> gain over the first 8 ms, then 0.0001 by t = dur, both exponential
## with a phase accumulated from f(t) rather than a fixed frequency, or the pitch fall
## does not bend and the whole thing sounds like a beep instead of a fold.
##
## Six cues, exactly the page's six:
##   slide    a move that went somewhere
##   invalid  a move that did not
##   merge(n) one to three pieces landing, a rising third each
##   unity(s) the level solved — a four-note chord, plus a high bell on three stars
##   logo     the title sting
##   ambience a slow two-oscillator bed under everything, off by default if the player
##            turned music off last time
extends Node

const SR := 44100.0
const BUS_MASTER := 0.7

var sfx_on := true
var music_on := true

var _cues := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _amb: AudioStreamPlayer


func _ready() -> void:
	sfx_on = Save.sfx_on()
	music_on = Save.music_on()
	_build()
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Master"
	_amb.volume_db = linear_to_db(0.5)
	_amb.stream = _cues["ambience"]
	add_child(_amb)
	_bark_ready()
	if music_on:
		_amb.play()


# --- synthesis ---------------------------------------------------------------------------

## One JS `tone()` mixed into `buf` starting at `when` seconds.
func _tone(buf: PackedFloat32Array, freq: float, dur: float, gain: float, kind: String,
		when: float, fall: float) -> void:
	var start := int(when * SR)
	var n := int(dur * SR)
	var phase := 0.0
	var attack := 0.008
	for i in range(n):
		var idx := start + i
		if idx < 0 or idx >= buf.size():
			continue
		var tt := float(i) / SR
		var f: float = freq * pow(maxf(40.0 / freq, fall), tt / dur)
		phase += TAU * f / SR
		# exponential attack to `gain`, then exponential decay back to silence
		var env: float
		if tt < attack:
			env = 0.0001 * pow(gain / 0.0001, tt / attack)
		else:
			var k: float = (tt - attack) / maxf(0.001, dur - attack)
			env = gain * pow(0.0001 / gain, k)
		var s: float
		if kind == "triangle":
			s = asin(sin(phase)) * (2.0 / PI)
		else:
			s = sin(phase)
		buf[idx] += s * env * BUS_MASTER


func _wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	pcm.resize(buf.size() * 2)
	for i in range(buf.size()):
		var v := int(clampf(buf[i], -1.0, 1.0) * 32000.0)
		pcm.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(SR)
	w.stereo = false
	w.data = pcm
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


func _blank(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * SR))
	b.fill(0.0)
	return b


func _build() -> void:
	# slide: tone(118, .075, .018, 'triangle', 0, .62)
	var b := _blank(0.16)
	_tone(b, 118.0, 0.075, 0.018, "triangle", 0.0, 0.62)
	_cues["slide"] = _wav(b)

	# invalid: tone(74, .1, .02, 'sine', 0, .86)
	b = _blank(0.2)
	_tone(b, 74.0, 0.1, 0.02, "sine", 0.0, 0.86)
	_cues["invalid"] = _wav(b)

	# merge(n): for i < min(n,3): tone(196 * 1.22^i, .16, .032, 'sine', i*.025, 1.42)
	for n in range(1, 4):
		b = _blank(0.42)
		for i in range(n):
			_tone(b, 196.0 * pow(1.22, i), 0.16, 0.032, "sine", i * 0.025, 1.42)
		_cues["merge%d" % n] = _wav(b)

	# unity(stars): [196,247,330,494] staggered, plus a 988 bell on three stars
	for stars in range(1, 4):
		b = _blank(1.6)
		var notes := [196.0, 247.0, 330.0, 494.0]
		for i in range(4):
			var gain: float = 0.035 + (0.025 if i == 3 else 0.0)
			var kind := "sine" if i == 3 else "triangle"
			var fall: float = 0.98 if i == 3 else 1.12
			_tone(b, notes[i], 0.5, gain, kind, i * 0.105, fall)
		if stars == 3:
			_tone(b, 988.0, 0.8, 0.018, "sine", 0.42, 0.5)
		_cues["unity%d" % stars] = _wav(b)

	# logo: [164,220,294,392], .38 each, staggered .09
	b = _blank(1.2)
	var logo := [164.0, 220.0, 294.0, 392.0]
	for i in range(4):
		_tone(b, logo[i], 0.38, 0.023, "triangle" if i < 2 else "sine", i * 0.09, 1.02)
	_cues["logo"] = _wav(b)

	# ambience: the page runs two oscillators (55 Hz triangle, 82.5 Hz sine) through a
	# 420 Hz lowpass with a very slow LFO on the output gain. Rendered here as an 8 s loop
	# whose length is a whole number of cycles of both tones and of the LFO, so the seam
	# is inaudible — 55 and 82.5 Hz both close at 8 s, and .075 Hz does not, so the LFO is
	# rounded to .125 Hz (one cycle per 8 s) rather than left to click every loop.
	var secs := 8.0
	b = _blank(secs)
	for i in range(b.size()):
		var tt := float(i) / SR
		var a := asin(sin(TAU * 55.0 * tt)) * (2.0 / PI) * 0.32
		var c := sin(TAU * 82.5 * tt) * 0.22
		var lfo := 1.0 + 0.5 * sin(TAU * 0.125 * tt)
		b[i] = (a + c) * 0.012 * lfo * BUS_MASTER
	_cues["ambience"] = _wav(b, true)


# --- cues ---------------------------------------------------------------------------------

func _play(name: String) -> void:
	if not sfx_on or not _cues.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cues[name]
	p.play()


func slide() -> void:
	_play("slide")


func invalid() -> void:
	_play("invalid")


func merge(n: int = 1) -> void:
	_play("merge%d" % clampi(n, 1, 3))


func unity(stars: int = 3) -> void:
	_play("unity%d" % clampi(stars, 1, 3))


func logo() -> void:
	_play("logo")


func set_sfx(v: bool) -> void:
	sfx_on = v
	Save.set_sfx(v)


func set_music(v: bool) -> void:
	music_on = v
	Save.set_music(v)
	if v:
		if not _amb.playing:
			_amb.play()
	else:
		_amb.stop()


# --- barks -------------------------------------------------------------------------------
#
# The spoken lines (ops/barks/lines.json, rendered by ops/barks/render_barks.py). They ride
# the same `sfx_on` switch as everything else here, because a player who muted the game
# meant all of it, and they get their own AudioStreamPlayer so a bark never steals a cue's
# voice mid-merge.
#
# Three rules, each one the reason a bark set stops being charming:
#
#   * **Rotate, and never repeat back to back.** Two greetings heard twice in ten seconds
#     is worse than silence. `_bark_last` remembers the index just used per slot.
#   * **Never overlap a bark with a bark.** A win that fires while the streak line is still
#     talking sounds like two people. The second one is dropped, not queued -- by the time
#     the first finishes, the moment it belonged to is gone.
#   * **Duck the cues, do not silence them.** The bark player sits a little louder and the
#     cue bus is lowered while it speaks, so the fold sounds keep their rhythm underneath.
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
		return                      # no barks installed for this build; stay silent
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_bark_map = parsed


## Say one line from `slot`. Returns false when nothing was said, so a caller can fall
## back to a plain cue.
func bark(slot: String) -> bool:
	if not sfx_on or _bark == null or not _bark_map.has(slot):
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

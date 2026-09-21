## Sfx — the station's sound, and the two buses everything else plays through.
##
## TITLE_SCREENS.md item 6 asks for "a title sting and an ambient bed that match the room".
## The room is a relay station, so the bed is the sea and the carrier: band-limited noise
## with a slow swell, under a low mains hum and its third harmonic. It is synthesised here
## rather than shipped as a file on purpose — a loop point that is sample-exact cannot be
## heard to loop, and this one is built to be, which a 40-second ogg of rain is not.
##
## Everything with a *voice* in it goes to the Radio bus instead, which is where the
## band-pass, the noise floor and the compression live (see _build_buses). The five
## recorded voices are already processed when they are baked (ops/ghost_voice.py), so the
## bus is doing the second, lighter half: the thing that makes a line played *now* sit in
## the same room as the bed playing under it.
extends Node

const SR := 22050                     # the station is not hi-fi; this is a choice, not a cut

var _bed: AudioStreamPlayer
var _cue: AudioStreamPlayer
var _click: AudioStreamPlayer
var _cache := {}
var _enabled := true
var radio_bus := 0
var sfx_bus := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_buses()
	_bed = _player(sfx_bus, -14.0)
	_cue = _player(sfx_bus, -6.0)
	_click = _player(sfx_bus, -10.0)
	_bark_ready()
func _player(bus: int, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = AudioServer.get_bus_name(bus)
	p.volume_db = db
	add_child(p)
	return p


## Two buses under Master: "Sfx" for the room, "Radio" for anything with a voice in it.
## The chain on Radio is the one a real net-control position hears — the set is filtering
## the line, not the player's speakers — so it is a band-pass at speech intelligibility,
## a hard limiter, and a touch of distortion for the carrier's edge.
func _build_buses() -> void:
	sfx_bus = _ensure_bus("Sfx")
	radio_bus = _ensure_bus("Radio")
	if AudioServer.get_bus_effect_count(radio_bus) > 0:
		return
	var hp := AudioEffectHighPassFilter.new()
	hp.cutoff_hz = 320.0               # the low end of a communications channel
	hp.resonance = 0.6
	AudioServer.add_bus_effect(radio_bus, hp)
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 3400.0              # and the high end: 300-3400 Hz is the whole band
	lp.resonance = 0.7
	AudioServer.add_bus_effect(radio_bus, lp)
	var comp := AudioEffectCompressor.new()
	comp.threshold = -18.0
	comp.ratio = 6.0
	comp.attack_us = 2000.0
	comp.release_ms = 120.0
	comp.gain = 5.0
	AudioServer.add_bus_effect(radio_bus, comp)
	var dist := AudioEffectDistortion.new()
	dist.mode = AudioEffectDistortion.MODE_OVERDRIVE
	dist.drive = 0.12
	dist.post_gain = -2.0
	AudioServer.add_bus_effect(radio_bus, dist)


func _ensure_bus(name: String) -> int:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == name:
			return i
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, name)
	AudioServer.set_bus_send(idx, "Master")
	return idx


func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		_bed.stop()
	elif not _bed.playing:
		bed()


# ---- the generator ------------------------------------------------------------------------
## Build a 16-bit mono stream from a Callable(i, n) -> float in [-1, 1].
func _make(name: String, seconds: float, fn: Callable, loop: bool = false) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	var n := int(SR * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v: float = clampf(fn.call(i, n), -1.0, 1.0)
		var s := int(v * 32767.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	_cache[name] = w
	return w


## A fixed-seed value noise, so the bed is the same station every session.
static func _noise(i: int, seed_k: int) -> float:
	var x := (i * 1103515245 + seed_k * 12345 + 1013904223) & 0x7FFFFFFF
	return float((x >> 11) & 0xFFFF) / 32768.0 - 1.0


# ---- the room -------------------------------------------------------------------------------
## The ambient bed: 8 s, sample-exact loop. Sea-noise band-limited by a one-pole pair, a
## 50 Hz hum with its third, and a swell whose period divides the loop so the seam is silent.
func bed() -> void:
	if not _enabled:
		return
	var stream := _make("bed", 8.0, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var swell: float = 0.55 + 0.45 * sin(TAU * tt / 8.0)          # exactly one period
		var hiss: float = _noise(i, 7) * 0.22 * swell
		var hum: float = sin(TAU * 50.0 * tt) * 0.05 + sin(TAU * 150.0 * tt) * 0.02
		# a lazy carrier drift, very quiet: the set is not quite on frequency
		var carrier: float = sin(TAU * (210.0 + sin(tt * 0.31) * 6.0) * tt) * 0.012
		return hiss + hum + carrier, true)
	# (the trailing `true` above is _make's `loop`: the bed is the one stream that repeats)
	_bed.stream = stream
	_bed.play()


## The squelch opening: the click of the relay, then the channel's noise floor arriving.
func squelch_open() -> void:
	_play(_cue, _make("sq_open", 0.16, func(i: int, n: int) -> float:
		var e: float = float(i) / n
		var click: float = _noise(i, 3) * exp(-e * 60.0) * 0.8
		var floor_n: float = _noise(i, 11) * 0.3 * smoothstep(0.0, 0.25, e)
		return click + floor_n))


## And closing: the floor cut dead, leaving one short tail.
func squelch_close() -> void:
	_play(_cue, _make("sq_close", 0.11, func(i: int, n: int) -> float:
		var e: float = float(i) / n
		return _noise(i, 5) * (1.0 - e) * 0.35 + _noise(i, 2) * exp(-e * 40.0) * 0.5))


## The call-sign: each agent's own frequency (GCRules.AGENTS[].freq), two pips and the
## squelch under them. Five different pitches is the cheapest, clearest way to know who is
## on the air before a word is said — and the ghost borrows the pitch too, which is the
## point: the tone never lies about the *channel*, only the voice does.
func callsign(freq: float) -> void:
	_play(_cue, _make("cs_%d" % int(freq), 0.34, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var e: float = float(i) / n
		var pip: float = 0.0
		if tt < 0.09:
			pip = sin(TAU * freq * tt) * exp(-tt * 22.0)
		elif tt > 0.13 and tt < 0.24:
			pip = sin(TAU * freq * 1.5 * (tt - 0.13)) * exp(-(tt - 0.13) * 26.0)
		return pip * 0.55 + _noise(i, 13) * 0.10 * (1.0 - e)), radio_bus)


func click() -> void:
	_play(_click, _make("click", 0.045, func(i: int, n: int) -> float:
		var e: float = float(i) / n
		return (_noise(i, 17) * 0.6 + sin(TAU * 1400.0 * float(i) / SR) * 0.4) * exp(-e * 30.0)))


## AUTHORIZE: two rising pips, the console agreeing.
func auth() -> void:
	_play(_cue, _make("auth", 0.26, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var f: float = 520.0 if tt < 0.1 else 780.0
		var seg: float = tt if tt < 0.1 else tt - 0.12
		if tt >= 0.1 and tt < 0.12:
			return 0.0
		return sin(TAU * f * seg) * exp(-seg * 14.0) * 0.5))


## DENY: the same two pips, the other way up, and flatter.
func deny() -> void:
	_play(_cue, _make("deny", 0.26, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var f: float = 420.0 if tt < 0.1 else 280.0
		var seg: float = tt if tt < 0.1 else tt - 0.12
		if tt >= 0.1 and tt < 0.12:
			return 0.0
		return sin(TAU * f * seg) * exp(-seg * 12.0) * 0.5))


## The alarm: friendly fire, a poisoned book, the clock at zero.
func warn() -> void:
	_play(_cue, _make("warn", 0.7, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var gate: float = 1.0 if fmod(tt, 0.22) < 0.13 else 0.0
		var wob: float = 180.0 + sin(TAU * 7.0 * tt) * 40.0
		return sin(TAU * wob * tt) * gate * 0.45 * exp(-tt * 1.4)))


## The win sting: the carrier finally locking — a fifth resolving, with the noise dropping
## out from under it.
func win_sting() -> void:
	_play(_cue, _make("win", 1.5, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var e: float = float(i) / n
		var a: float = sin(TAU * 293.66 * tt)
		var b: float = sin(TAU * 440.0 * tt) * smoothstep(0.15, 0.45, tt)
		var c: float = sin(TAU * 587.33 * tt) * smoothstep(0.5, 0.9, tt)
		return (a + b + c) * 0.18 * exp(-tt * 1.1) + _noise(i, 23) * 0.12 * (1.0 - e) * (1.0 - e)))


## The title sting: the set being switched on. A thump, the carrier finding itself, and the
## station settling into the bed the menu then sits on.
func title_sting() -> void:
	_play(_cue, _make("title", 2.0, func(i: int, n: int) -> float:
		var tt: float = float(i) / SR
		var thump: float = sin(TAU * 58.0 * tt) * exp(-tt * 6.0) * 0.7
		var sweep: float = sin(TAU * (90.0 + 700.0 * exp(-tt * 2.2)) * tt) * exp(-tt * 1.6) * 0.22
		var settle: float = _noise(i, 29) * 0.16 * exp(-tt * 0.8)
		return thump + sweep + settle))


func _play(p: AudioStreamPlayer, s: AudioStream, bus: int = -1) -> void:
	if not _enabled:
		return
	p.stream = s
	p.bus = AudioServer.get_bus_name(bus if bus >= 0 else sfx_bus)
	p.play()

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
	return false

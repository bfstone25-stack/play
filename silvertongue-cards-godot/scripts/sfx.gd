## Sfx — audio cue hooks (autoload "Sfx"). Every cue the client fires has a name here;
## the sounds are placeholders synthesised at boot (short shaped sines) so the package
## carries no audio files yet. Replace a cue by dropping an .ogg at
## res://assets/sfx/<name>.ogg — `play()` prefers a file when one exists.
##
## Cue names are the contract the sibling title should reuse:
##   ui_click, card_hover, card_play, reply, phase_up, phase_down, win, lose, coerce,
##   flip, rare, epic, dupe, type, gold, energy, board
extends Node

const BUS := "Master"
const RATE := 22050

var muted := false
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var log: Array[String] = []          # every cue fired, in order — the tests read this


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		add_child(p)
		_pool.append(p)
	_streams = {
		"ui_click": _tone([[880, 0.04, 0.5]]),
		"card_hover": _tone([[1320, 0.03, 0.25]]),
		"card_play": _tone([[520, 0.05, 0.6], [780, 0.07, 0.5]]),
		"reply": _tone([[660, 0.05, 0.35], [990, 0.05, 0.3]]),
		"phase_up": _tone([[523, 0.08, 0.5], [659, 0.08, 0.5], [784, 0.14, 0.55]]),
		"phase_down": _tone([[440, 0.10, 0.5], [330, 0.16, 0.45]]),
		"win": _tone([[523, 0.10, 0.5], [659, 0.10, 0.5], [784, 0.10, 0.55], [1046, 0.32, 0.6]]),
		"lose": _tone([[392, 0.14, 0.5], [311, 0.16, 0.45], [233, 0.34, 0.4]]),
		"coerce": _tone([[180, 0.18, 0.6], [120, 0.30, 0.5]]),
		"flip": _tone([[1100, 0.03, 0.4], [1500, 0.04, 0.3]]),
		"rare": _tone([[740, 0.08, 0.5], [1108, 0.20, 0.5]]),
		"epic": _tone([[622, 0.08, 0.5], [932, 0.08, 0.5], [1244, 0.30, 0.6]]),
		"dupe": _tone([[500, 0.06, 0.4], [400, 0.10, 0.35]]),
		"type": _tone([[2400, 0.012, 0.12]]),
		"gold": _tone([[1760, 0.04, 0.35], [2217, 0.08, 0.3]]),
		"energy": _tone([[988, 0.06, 0.4]]),
		"board": _tone([[600, 0.06, 0.35], [900, 0.10, 0.3]]),
		# SUASION campaign (Nutaku build): a card landing on her resolve, a phase changing,
		# Celeste taking a card. Synthesised like every cue here -- no third-party audio.
		"hit": _tone([[220, 0.03, 0.7], [330, 0.05, 0.5]]),
		"flourish": _tone([[784, 0.06, 0.45], [988, 0.06, 0.45], [1175, 0.06, 0.45], [1568, 0.24, 0.5]]),
		"steal": _tone([[660, 0.05, 0.4], [494, 0.05, 0.4], [370, 0.14, 0.4]]),
	}
	_bark_ready()
func play(name: String, volume_db: float = -8.0) -> void:
	log.append(name)
	if log.size() > 200:
		log.pop_front()
	if muted:
		return
	var stream: AudioStream = null
	var file := "res://assets/sfx/%s.ogg" % name
	if ResourceLoader.exists(file):
		stream = load(file)
	else:
		stream = _streams.get(name)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	_pool[0].stream = stream
	_pool[0].volume_db = volume_db
	_pool[0].play()


## notes: [[hz, seconds, amplitude], ...] played back to back with a soft envelope.
static func _tone(notes: Array) -> AudioStreamWAV:
	var samples := PackedByteArray()
	for n in notes:
		var hz: float = n[0]
		var secs: float = n[1]
		var amp: float = n[2]
		var count := int(secs * RATE)
		for i in count:
			var t := float(i) / RATE
			var env := minf(1.0, float(i) / 40.0) * minf(1.0, float(count - i) / (count * 0.5))
			var v := sin(TAU * hz * t) * 0.7 + sin(TAU * hz * 2.0 * t) * 0.3
			var s := int(clampf(v * env * amp, -1.0, 1.0) * 32767.0)
			samples.append(s & 0xff)
			samples.append((s >> 8) & 0xff)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = samples
	return w

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

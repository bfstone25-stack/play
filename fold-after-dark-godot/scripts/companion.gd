extends Node
## Coco: the companion beside the board. Autoloaded as "Coco".
##
## A clearly adult woman (the key visual's lead, 25) who cheers the player on in short
## voiced lines. The lines, the voice and the ASR check live in
## ops/nutaku/fold_f2p/companion_voice.py; this file only chooses and plays them.
##
## Three rules:
##   * **No-repeat rotation.** Each slot is a shuffled bag; a line comes back only after
##     every other line in its slot has been said, and never twice in a row across a
##     refill.
##   * **One voice, with air between lines.** Nothing starts while she is speaking or
##     within GAP seconds of her last line ending. A line that cannot be said is DROPPED,
##     not queued: by then its moment has passed. `priority` lines (win, unlock) may cut
##     the gap short, never the line that is playing.
##   * **Subtitles always**, even with her voice muted: `said` carries the text, and the
##     board shows it in her bubble. Voice mute is Juice.voice_on, separate from SFX.

signal said(slot: String, text: String, seconds: float)

const DIR := "res://assets/voice/companion/"
const GAP := 4.0

var _player: AudioStreamPlayer
var _lines: Dictionary = {}          # slot -> [{file, text}]
var _bags: Dictionary = {}           # slot -> [indices left]
var _last: Dictionary = {}           # slot -> last index said
var _quiet_until := 0.0              # engine seconds
var _clock := 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = 1.0
	add_child(_player)
	var f := FileAccess.open(DIR + "lines.json", FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_lines = parsed


func _exit_tree() -> void:
	# a playing stream is still held by its playback; stop first or it leaks at quit
	_player.stop()
	_player.stream = null


func _process(delta: float) -> void:
	_clock += delta


func has_slot(slot: String) -> bool:
	return _lines.has(slot) and not (_lines[slot] as Array).is_empty()


func busy() -> bool:
	return _player.playing or _clock < _quiet_until


## The next index for `slot` from its bag, refilling (and never repeating the last) as needed.
func _next(slot: String) -> int:
	var n: int = (_lines[slot] as Array).size()
	var bag: Array = _bags.get(slot, [])
	if bag.is_empty():
		bag = range(n)
		bag.shuffle()
		if n > 1 and int(bag[0]) == int(_last.get(slot, -1)):
			bag.append(bag.pop_front())
	var i := int(bag.pop_front())
	_bags[slot] = bag
	_last[slot] = i
	return i


## Say a line from `slot`. False when nothing was said (busy, or no such slot).
func say(slot: String, priority: bool = false) -> bool:
	if not has_slot(slot):
		return false
	if _player.playing:
		return false
	if not priority and _clock < _quiet_until:
		return false
	var row: Dictionary = _lines[slot][_next(slot)]
	var text := str(row.get("text", ""))
	var secs := 1.8
	var path := DIR + str(row.get("file", ""))
	if ResourceLoader.exists(path):
		# uncached for the same reason as Sfx._load_files: a line playing at quit
		var stream: AudioStream = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		secs = maxf(0.8, stream.get_length())
		if Juice.voice_on and Sfx.sfx_on:
			_player.stream = stream
			_player.play()
	_quiet_until = _clock + secs + GAP
	said.emit(slot, text, secs)
	return true


## Once per calendar day: the first-login-of-the-day line. True if it was said.
func daily() -> bool:
	var today := Time.get_date_string_from_system()
	if str(Save.get_v("coco_day", "")) == today:
		return false
	if say("daily", true):
		Save.set_v("coco_day", today)
		return true
	return false


func stop() -> void:
	_player.stop()

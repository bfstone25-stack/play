## Voice — the five people on the net, as recorded audio.
##
## The whole game is "one of these five voices is not who it says it is", and for three
## years that sentence was carried entirely by printed text. It is carried here by sound.
##
## Clips are baked offline by ops/ghost_voice.py (CosyVoice2-0.5B, then radio processing:
## band-pass, noise floor, compression) into assets/voice/<lang>/<agent>/<key>.ogg with a
## manifest beside them. Nothing here generates anything at runtime; the engine's job is to
## pick the right clip, put it on the Radio bus, and stay silent when there isn't one.
##
## Three keys matter more than the rest:
##   type_<t>   what this person sounds like asking for a fire mission, an extract, ...
##   tic_<who>  this speaker saying *another* person's verbal tic. This is the deduction
##              cue, in audio: when the mimic borrows Su Wan's "eyes in the dark", the
##              player hears Su Wan's words in Gu Chen's throat. The text said so before;
##              now the ear gets there first.
##   quote      the character line, for the roster and the title screen's idle chatter.
##
## Missing clips are normal and must stay harmless: a build whose bake has not run yet, or
## a language whose pass was not made, plays the call-sign pips and the printed line, which
## is exactly the prototype. `have()` says which, so the credits screen can be honest about
## it rather than the player wondering whether their sound is broken.
extends Node

const DIR := "res://assets/voice"

var _manifest := {}                   # lang -> agent -> {key: path}
var _player: AudioStreamPlayer
var _tic_player: AudioStreamPlayer    # the borrowed tic lands under the tail of the line
var _enabled := true
var _loaded := {}                     # path -> AudioStream

signal line_finished


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_read_manifest()
	_player = AudioStreamPlayer.new()
	_player.bus = "Radio"
	_player.volume_db = -1.0
	_player.finished.connect(func(): line_finished.emit())
	add_child(_player)
	_tic_player = AudioStreamPlayer.new()
	_tic_player.bus = "Radio"
	_tic_player.volume_db = -2.0
	add_child(_tic_player)


func _read_manifest() -> void:
	var p := DIR + "/manifest.json"
	if not ResourceLoader.exists(p) and not FileAccess.file_exists(p):
		return
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_manifest = d


## Is there real recorded audio in this build at all, and for which languages?
func have() -> Array:
	var out := []
	for lang in _manifest:
		if not (_manifest[lang] as Dictionary).is_empty():
			out.append(lang)
	return out


func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		_player.stop()
		_tic_player.stop()


## The clip for (lang, agent, key), falling back to the en bake when a language has none —
## better a voice in the wrong language than a silent character, because the *identity* of
## the voice is the mechanic and the words are on screen anyway.
func _clip(lang: String, agent: String, key: String) -> AudioStream:
	for l in [lang, "en"]:
		var by_agent = _manifest.get(l, {})
		var keys = by_agent.get(agent, {})
		if keys.has(key):
			var path: String = DIR + "/" + str(keys[key])
			if _loaded.has(path):
				return _loaded[path]
			if ResourceLoader.exists(path):
				var s: AudioStream = load(path)
				_loaded[path] = s
				return s
	return null


func stop() -> void:
	_player.stop()
	_tic_player.stop()


## Speak one key in one person's voice. Returns true when there was actually a clip.
func say(lang: String, agent: String, key: String) -> bool:
	if not _enabled:
		return false
	var s := _clip(lang, agent, key)
	if s == null:
		return false
	_player.stream = s
	_player.play()
	return true


## A request going out on the air: this speaker's line for that request type, and — when
## the mimic borrowed someone's tic — that tic, in this speaker's voice, a beat later.
func transmit(lang: String, agent: String, type: String, borrowed_tic_of: String = "") -> void:
	if not _enabled:
		return
	var spoke := say(lang, agent, "type_" + type)
	if borrowed_tic_of == "":
		return
	var tic := _clip(lang, agent, "tic_" + borrowed_tic_of)
	if tic == null:
		return
	# after the line, not over it: the tic is a tag on the end, the way it reads on screen
	var wait := 0.25
	if spoke and _player.stream != null:
		wait = maxf(0.25, _player.stream.get_length() - 0.15)
	await get_tree().create_timer(wait, true, false, true).timeout
	if _enabled:
		_tic_player.stream = tic
		_tic_player.play()

extends Node
## ACROSS THE HALL — the voice layer.
##
## Why this file exists at all, and why it is nearly empty.
##
## Every other game in the studio keeps its cues in a `Sfx` autoload, and ops/bark_wire.py
## appends the spoken-bark layer to that file. This game never had one: its sound is
## generated in place — game.gd synthesises the drone, the clicks and the tape as
## AudioStreamWAVs, ambience.gd synthesises the knock, the drip and the far footstep, and
## both of those are POSITIONAL (AudioStreamPlayer3D, in the hallway, at a coordinate).
## That is the right shape for this game and none of it is moving here.
##
## So the 21 rendered lines in assets/voice/ had nowhere to land: bark_wire could not wire
## a game with no scripts/sfx.gd, and it reported exactly that and skipped it.
##
## This is the missing hook and nothing else. It holds ONE non-positional voice — a bark is
## the narrator, not an object in the hallway, and panning her to a coordinate in the
## corridor would make her a character the game does not have — and it carries the mute
## switch the layer asks for. The synthesised cues stay where they are.
##
## Autoloaded as "Sfx" (project.godot). Call sites are in game.gd and ath_title.gd.

## The player's sound switch. There is no options menu in Episode I, so nothing flips this
## yet; it exists because the bark layer asks a game "is the sound off?" in that game's own
## words, and a game that cannot answer gets a stub that lies. When a menu lands, it sets
## this.
var sfx_on := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bark_ready()


## Fire a bark only if this slot has not been used in the last `gap` seconds.
##
## The barks are tied to story beats here, not to a score, and story beats in a walk-sim
## arrive in clusters: opening 401 sets a chapter, plays a click, shows a note and moves
## the clock inside one frame. Without this, two lines fire at once, the second is dropped
## by the layer's own one-voice rule, and the one that survives is whichever won the race.
var _said: Dictionary = {}


func bark_once(slot: String, gap: float = 12.0) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_said.get(slot, -999.0)) < gap:
		return false
	_said[slot] = now
	return bark(slot)

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
	return not sfx_on

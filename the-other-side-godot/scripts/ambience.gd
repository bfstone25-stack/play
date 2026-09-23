extends Node

## Knocks, drips, 02:17. Most of the scare is waiting.

var knock_t := 6.5
var drip_t := 1.4
var clock_t := 0.0
var knock: AudioStreamPlayer3D
var drip: AudioStreamPlayer3D
var far: AudioStreamPlayer3D

func _ready() -> void:
	knock = _bus("Knock", Vector3(2.0, 1.2, 8.05), 18.0)
	drip = _bus("Drip", Vector3(8.25, 1.1, 11.4), 10.0)
	far = _bus("FarStep", Vector3(5.5, 0.1, 8.0), 16.0)
	knock.stream = _tone(88.0, 0.13, 0.95)
	drip.stream = _tone(1750.0, 0.035, 0.4)
	far.stream = _tone(64.0, 0.2, 0.85)
	_bark_ready()

func _bus(n: String, pos: Vector3, dist: float) -> AudioStreamPlayer3D:
	var a := AudioStreamPlayer3D.new()
	a.name = n
	a.position = pos
	a.max_distance = dist
	a.unit_size = 2.0
	add_child(a)
	return a

func _process(delta: float) -> void:
	var game := get_parent()
	if game.get("ending"):
		return
	clock_t += delta
	var hud := game.get_node_or_null("HUD")
	if hud and hud.has_method("set_clock"):
		hud.set_clock("02:%02d" % mini(17 + int(clock_t * 0.28), 59))
	var phase := int(game.get("phase"))
	var player := game.get_node_or_null("Player") as Node3D
	var in_402 := player != null and player.global_position.x > 2.0
	knock_t -= delta
	if knock_t <= 0.0 and phase < 3:
		knock.play()
		knock_t = randf_range(8.0, 15.0) if not in_402 else randf_range(16.0, 26.0)
	drip_t -= delta
	if drip_t <= 0.0:
		drip.play()
		drip_t = randf_range(0.85, 2.2)
	if (not in_402) and phase >= 1 and randf() < delta * 0.18:
		far.play()

func _tone(hz: float, dur: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / float(maxi(n, 1))
		var s := sin(TAU * hz * i / sr) * env * env * amp
		s += sin(TAU * (hz * 0.48) * i / sr) * env * amp * 0.35
		var v := int(clampf(s, -1.0, 1.0) * 28000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st

## --- the voice ---------------------------------------------------------------------
##
## This game has no scripts/sfx.gd -- ambience.gd IS its audio node -- so the shared bark
## layer (ops/bark_wire.py) is carried here verbatim rather than forked. Keep it identical
## to that file: eight games use this exact code and a ninth spelling of it helps nobody.


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

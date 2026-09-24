extends Node

## Knock at the door. Drip from the pipe. Waiting is the scare.

var knock_t := 5.5
var drip_t := 1.1
var hum_t := 8.0
var clock_t := 0.0
var knock: AudioStreamPlayer3D
var drip: AudioStreamPlayer3D
var hum: AudioStreamPlayer3D

func _ready() -> void:
	knock = _bus("Knock", Vector3(1.2, 1.2, 2.2), 16.0)
	drip = _bus("Drip", Vector3(7.45, 0.55, 5.15), 9.0)
	hum = _bus("Hum", Vector3(3.8, 2.2, 1.6), 11.0)
	knock.stream = _tone(92.0, 0.12, 0.95)
	drip.stream = _tone(1680.0, 0.03, 0.42)
	hum.stream = _rumble(38.0, 0.6, 0.32)
	hum.volume_db = -20.0
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
		var colon := ":" if int(clock_t * 2.0) % 2 == 0 else " "
		hud.set_clock("02%s04" % colon)
	knock_t -= delta
	if knock_t <= 0.0:
		knock.play()
		var stage := int(game.get("stage"))
		if stage >= 9:
			knock_t = randf_range(3.2, 5.5)
		elif stage >= 5:
			knock_t = randf_range(6.0, 10.0)
		else:
			knock_t = randf_range(11.0, 18.0)
	drip_t -= delta
	if drip_t <= 0.0:
		drip.play()
		drip_t = randf_range(0.7, 1.9)
	hum_t -= delta
	if hum_t <= 0.0:
		hum.play()
		hum_t = randf_range(8.0, 14.0)

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

func _rumble(hz: float, dur: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := sin(PI * float(i) / float(maxi(n, 1)))
		var s := sin(TAU * hz * i / sr) * env * amp
		s += (randf() - 0.5) * 0.04 * env
		var v := int(clampf(s, -1.0, 1.0) * 22000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st


# --- barks -------------------------------------------------------------------------------
#
# Mara Venn's lines (ops/barks/lines.json -> "overnight-clause", adult register). Rendered by ops/barks/render_barks.py into assets/voice/.
#
# This is ops/bark_wire.py's layer, written here by hand rather than by the tool: that tool
# appends to a game's `sfx.gd` autoload and this game has no sfx.gd -- its audio lives on
# this node, which is already a child of the game and already owns the mute-able cues.
#
# EVERYTHING BELOW NO-OPS UNTIL assets/voice/barks.json EXISTS. That is deliberate and is
# how the other titles in this wave are wired: the lines are written, the moments are
# chosen and called, and the GPU window only has to drop files in. It is also why
# `_bark_map` is loaded from the manifest rather than from a hardcoded list -- a bark set
# that is half-rendered must never pick a file that is not there.
#
# Three rules, each one the reason a bark set stops being charming:
#   * rotate, and never repeat back to back;
#   * never overlap a bark with a bark -- the second is DROPPED, not queued, because by
#     the time the first ends the moment it belonged to is gone;
#   * one voice per game.
const BARKS := "res://assets/voice/"

var _bark: AudioStreamPlayer
var _bark_map: Dictionary = {}
var _bark_last: Dictionary = {}


func _bark_ready() -> void:
	_bark = AudioStreamPlayer.new()
	_bark.name = "Bark"
	_bark.bus = "Master"
	_bark.volume_db = -4.0
	add_child(_bark)
	var path := BARKS + "barks.json"
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_bark_map = parsed


## Say one line from `slot`. Silent and harmless if the set was never rendered.
func bark(slot: String) -> void:
	if _bark == null or _bark.playing:
		return
	var files: Variant = _bark_map.get(slot)
	if not (files is Array) or (files as Array).is_empty():
		return
	var list: Array = files
	var pick: String = str(list[randi() % list.size()])
	# never twice running in the same slot, when there is another option
	if list.size() > 1 and pick == str(_bark_last.get(slot, "")):
		pick = str(list[(list.find(pick) + 1) % list.size()])
	_bark_last[slot] = pick
	var stream: AudioStream = load(BARKS + pick) as AudioStream
	if stream == null:
		return
	_bark.stream = stream
	_bark.play()

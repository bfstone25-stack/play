extends Node

## Knocks, drips, distant steps. Most of the scare is waiting.

var knock_t := 6.5
var drip_t := 1.4
var hum_t := 11.0
var clock_t := 0.0
var knock: AudioStreamPlayer3D
var drip: AudioStreamPlayer3D
var far: AudioStreamPlayer3D
var hum: AudioStreamPlayer3D

func _ready() -> void:
	knock = _bus("Knock", Vector3(2.0, 1.2, 8.05), 18.0)
	drip = _bus("Drip", Vector3(8.5, 1.05, 11.0), 10.0)
	far = _bus("FarStep", Vector3(5.5, 0.1, 8.0), 16.0)
	hum = _bus("Radiator", Vector3(5.3, 0.4, 4.1), 12.0)
	knock.stream = _tone(88.0, 0.13, 0.95)
	drip.stream = _tone(1750.0, 0.035, 0.4)
	far.stream = _tone(64.0, 0.2, 0.85)
	hum.stream = _rumble(42.0, 0.55, 0.35)
	hum.volume_db = -18.0

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
		# Episode I promise: the hallway clock will not leave 02:17.
		# Blink the colon so the second hand still feels alive / waiting.
		var colon := ":" if int(clock_t * 2.0) % 2 == 0 else " "
		hud.set_clock("02%s17" % colon)
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
	hum_t -= delta
	if hum_t <= 0.0:
		hum.play()
		hum_t = randf_range(9.0, 16.0)
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

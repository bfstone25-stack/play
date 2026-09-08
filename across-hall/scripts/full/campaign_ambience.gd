extends Node

## Sparse basement / office bed for Episodes II–V.

var creak_t := 7.0
var drip_t := 2.2
var pipe_t := 10.0
var creak: AudioStreamPlayer3D
var drip: AudioStreamPlayer3D
var pipe: AudioStreamPlayer3D

func _ready() -> void:
	creak = _bus("Creak", Vector3(1.2, 1.0, 6.0), 14.0)
	drip = _bus("Drip", Vector3(-2.0, 2.0, 5.0), 10.0)
	pipe = _bus("Pipe", Vector3(0.0, 2.1, 8.0), 16.0)
	creak.stream = _tone(72.0, 0.22, 0.7)
	drip.stream = _tone(1480.0, 0.04, 0.35)
	pipe.stream = _tone(110.0, 0.4, 0.45)
	creak.volume_db = -14.0
	drip.volume_db = -16.0
	pipe.volume_db = -18.0

func _bus(n: String, pos: Vector3, dist: float) -> AudioStreamPlayer3D:
	var a := AudioStreamPlayer3D.new()
	a.name = n
	a.position = pos
	a.max_distance = dist
	a.unit_size = 2.2
	add_child(a)
	return a

func _process(delta: float) -> void:
	var game := get_parent()
	if game.get("campaign_complete"):
		return
	creak_t -= delta
	if creak_t <= 0.0:
		creak.play()
		creak_t = randf_range(8.0, 18.0)
	drip_t -= delta
	if drip_t <= 0.0:
		drip.play()
		drip_t = randf_range(1.2, 3.5)
	pipe_t -= delta
	if pipe_t <= 0.0:
		pipe.play()
		pipe_t = randf_range(9.0, 20.0)

func _tone(hz: float, dur: float, amp: float) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / float(maxi(n, 1))
		var s := sin(TAU * hz * i / sr) * env * env * amp
		s += sin(TAU * (hz * 0.5) * i / sr) * env * amp * 0.3
		var v := int(clampf(s, -1.0, 1.0) * 26000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = sr
	st.stereo = false
	st.data = data
	return st

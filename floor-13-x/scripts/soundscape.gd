extends AudioStreamPlayer
class_name Soundscape

var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var active := false
var cue_ticks := 0
var cue_freq := 180.0
# Title sting: two detuned sines falling an octave over 2.4 s — the building's tone,
# heard once. UI ticks: a short sine burst, higher for hover, lower and longer for press.
var sting_ticks := 0
const STING_LEN := 52920
var ui_ticks := 0
var ui_len := 1
var ui_freq := 1240.0

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.35
	stream = generator
	volume_db = -31.0
	play()
	playback = get_stream_playback()
	active = true

func _process(_delta: float) -> void:
	if not active or playback == null:
		return
	var frames := playback.get_frames_available()
	for _i in frames:
		var hum := sin(phase * TAU) * 0.055 + sin(phase * TAU * 2.01) * 0.018
		var cue := 0.0
		if cue_ticks > 0:
			cue = sin(phase * TAU * cue_freq / 60.0) * min(0.22, cue_ticks / 1800.0)
			cue_ticks -= 1
		var sting := 0.0
		if sting_ticks > 0:
			var k := 1.0 - float(sting_ticks) / float(STING_LEN)
			var f := 220.0 * pow(0.5, k)
			var env := (1.0 - k) * (1.0 - k) * 0.30
			sting = (sin(phase * TAU * f / 60.0) + 0.6 * sin(phase * TAU * (f * 1.005) / 60.0)) * env
			sting_ticks -= 1
		var tick := 0.0
		if ui_ticks > 0:
			var u := float(ui_ticks) / float(ui_len)
			tick = sin(phase * TAU * ui_freq / 60.0) * u * u * 0.18
			ui_ticks -= 1
		var sample := hum + cue + sting + tick
		playback.push_frame(Vector2(sample, sample * 0.94))
		phase = fmod(phase + 60.0 / 22050.0, 1.0)

func cue(kind: String) -> void:
	match kind:
		"phone": cue_freq = 470.0
		"printer": cue_freq = 110.0
		"elevator": cue_freq = 620.0
		"scanner": cue_freq = 78.0
		"choice": cue_freq = 220.0
		"ending": cue_freq = 740.0
		_: cue_freq = 180.0
	cue_ticks = 2800

func sting() -> void:
	sting_ticks = STING_LEN

func ui(kind: String) -> void:
	match kind:
		"hover":
			ui_freq = 1240.0
			ui_len = 700
		_:
			ui_freq = 620.0
			ui_len = 1500
	ui_ticks = ui_len

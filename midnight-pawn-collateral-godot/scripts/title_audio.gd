extends AudioStreamPlayer
class_name TitleAudio

## Title sound with no asset: a bed, a sting, and two UI ticks, all from one generator.
## Placeholder synthesis is acceptable per TITLE_SCREENS.md until a house asset exists; the
## hooks (`sting()`, `ui("hover"|"press")`, `bed(on)`) are what the title screen calls, so
## a real recording drops in behind them without touching the screen.
##
##   bed     two low sines a fifth apart, slowly beating — a shop after closing,
##           tuned warmer and slower than the Overnight Clause copy this came from
##   sting   a low note falling a fifth over 2.6 s with a soft second voice
##   hover   a short high tick; press a lower, longer one

@export var bed_root := 41.0
@export var bed_gain := 0.055
@export var sting_root := 116.0
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var bed_on := true
var sting_ticks := 0
const STING_LEN := 57330
var ui_ticks := 0
var ui_len := 1
var ui_freq := 1200.0
const RATE := 22050.0


func _ready() -> void:
	var g := AudioStreamGenerator.new()
	g.mix_rate = RATE
	g.buffer_length = 0.35
	stream = g
	volume_db = -15.0
	play()
	playback = get_stream_playback()


func _process(_delta: float) -> void:
	if playback == null:
		return
	var frames := playback.get_frames_available()
	for _i in frames:
		var s := 0.0
		if bed_on:
			s += (sin(phase * TAU * bed_root / 60.0) + 0.55 * sin(phase * TAU * bed_root * 1.498 / 60.0)
				+ 0.25 * sin(phase * TAU * bed_root * 2.01 / 60.0)) * bed_gain
		if sting_ticks > 0:
			var k := 1.0 - float(sting_ticks) / float(STING_LEN)
			var f := sting_root * pow(0.667, k)
			var env := (1.0 - k) * (1.0 - k) * 0.28
			s += (sin(phase * TAU * f / 60.0) + 0.5 * sin(phase * TAU * f * 2.003 / 60.0)) * env
			sting_ticks -= 1
		if ui_ticks > 0:
			var u := float(ui_ticks) / float(ui_len)
			s += sin(phase * TAU * ui_freq / 60.0) * u * u * 0.16
			ui_ticks -= 1
		playback.push_frame(Vector2(s, s * 0.95))
		phase = fmod(phase + 60.0 / RATE, 1.0)


func sting() -> void:
	sting_ticks = STING_LEN


func ui(kind: String) -> void:
	if kind == "hover":
		ui_freq = 1200.0
		ui_len = 640
	else:
		ui_freq = 600.0
		ui_len = 1500
	ui_ticks = ui_len


func bed(on: bool) -> void:
	bed_on = on

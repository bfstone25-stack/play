extends AudioStreamPlayer
class_name Soundscape

var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var active := false
var cue_ticks := 0
var cue_freq := 180.0

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.35
	stream = generator
	volume_db = -31.0
	play()
	playback = get_stream_playback()
	active = true
	_bark_ready()

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
		var sample := hum + cue
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


# --- barks ---------------------------------------------------------------------------
#
# June's spoken lines (ops/barks/lines.json -> "floor-13", rendered by
# ops/barks/render_barks.py into assets/voice/). This is ops/bark_wire.py's layer, written
# in by hand because that tool wires a game's scripts/sfx.gd and Floor 13's audio is this
# generator node instead.
#
# Three rules, each the reason a bark set stops being charming:
#   * rotate, and never repeat back to back;
#   * never overlap a bark with a bark — the second is DROPPED, not queued, because by
#     the time the first ends the moment it belonged to is gone;
#   * one voice per game.
#
# Everything here is a no-op until the audio is rendered: assets/voice/barks.json does not
# exist in the build yet, _bark_map stays empty and bark() returns false. That is
# deliberate — the moments are chosen and called now, so the GPU window only has to drop
# files in.
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

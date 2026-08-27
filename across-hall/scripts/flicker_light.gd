extends OmniLight3D

var t := 0.0
var next_glitch := 0.4

func _process(delta: float) -> void:
	t += delta
	next_glitch -= delta
	var base := 1.6 + 0.5 * sin(t * 2.7)
	if next_glitch <= 0.0:
		light_energy = 0.05 if randf() < 0.45 else 4.2
		next_glitch = randf_range(0.05, 0.2) if light_energy < 0.2 else randf_range(0.5, 2.2)
	else:
		light_energy = lerpf(light_energy, base, delta * 6.0)

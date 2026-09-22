extends OmniLight3D

## A failing fluorescent: a slow swell, and a hard glitch that drops it out or punches it.
##
## `energy` is the lamp's nominal brightness and EVERY number below is a multiple of it.
## Ported from Late Inspection 2026-09-21 (a21a4c7): this file was a stale copy that still
## drove light_energy from hardcoded constants and threw away the `energy` world_builder
## handed it, which is the same bug that photographed the parent's six zones as one green
## corridor. Keeping `energy` as a multiplier rather than replacing the constants means the
## FLICKER still reads the way it did -- same swell, same rhythm, same dropout-to-punch
## ratio -- while the lamp sits where the level asked for it.

## Nominal brightness. The swell centres near this, the dropout goes far under it, and the
## glitch punches well over it.
@export var energy: float = 1.0

var t := 0.0
var next_glitch := 0.4


func _process(delta: float) -> void:
	t += delta
	next_glitch -= delta
	# the slow swell of a tube that is on its way out, +-30% around nominal
	var base: float = energy * (1.0 + 0.3 * sin(t * 2.7))
	if next_glitch <= 0.0:
		# a dropout is near-black and short; a punch is bright and lasts longer
		var dropout := randf() < 0.45
		light_energy = energy * (0.03 if dropout else 2.6)
		next_glitch = randf_range(0.05, 0.2) if dropout else randf_range(0.5, 2.2)
	else:
		light_energy = lerpf(light_energy, base, delta * 6.0)

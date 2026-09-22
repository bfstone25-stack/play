extends OmniLight3D

## A failing fluorescent: a slow swell, and a hard glitch that drops it out or punches it.
##
## `energy` is the lamp's nominal brightness and EVERY number below is a multiple of it.
## That is the fix, 2026-09-21, and it was a silent one of the worst kind.
##
## world_builder._fixture() takes an `energy` argument and, for a flickering lamp, threw it
## away -- it set `light_energy` only on the non-flicker branch, and this script then
## overwrote `light_energy` on its first frame from hardcoded constants. So the lobby's
## emergency lamp, asked for at 1.0, actually ran at a 1.6 baseline and punched to 4.2,
## while the steady amber lamps beside it honoured their 1.0-1.45 exactly.
##
## The map has three green lamps and ALL THREE of them flicker; of the four flickering
## lamps, three are green. So the silently-ignored energy landed almost entirely on one
## hue. Written out as the level asked for it, green is 2.52 of a 7.02 lamp budget (36%);
## with the bug it ran at a 1.6 baseline per lamp -- 4.8 against the warm lamps' 4.85, a
## dead heat -- and punched to 4.2 each on a glitch. The lobby and the bathroom, which had
## no warm lamp of their own at all, were therefore lit by nothing but an over-driven
## green. That is why six authored zones photographed as one green corridor.
##
## The lighting design was close to right; the renderer was not being told it.
##
## Keeping `energy` as a multiplier rather than replacing the constants means the FLICKER
## still reads the way it did -- same swell, same rhythm, same dropout-to-punch ratio --
## while the lamp sits where the level asked for it.

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

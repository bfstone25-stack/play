extends SceneTree

## Every lamp must burn at the brightness the level asked for, and the rooms must not all
## be one colour.
##
## This test exists because both of those were false and nothing said so.
##
## `world_builder._fixture()` takes an `energy` argument and, for a FLICKERING lamp, threw
## it away: it assigned `light_energy` only on the non-flicker branch, and
## `flicker_light.gd` then drove `light_energy` from hardcoded constants (a 1.6 baseline
## punching to 4.2). No error, no warning -- the lamp simply ignored its brief. And since
## every flickering lamp in this map is green and every steady one is amber, the one hue
## running two-to-four times over budget was the hue that ended up owning the picture: a
## 28-shot play matrix in which six authored zones all photographed as the same green
## corridor.
##
## So there are two assertions, and the second is the one that would have caught it from
## the outside rather than from the inside:
##
##   1. a flickering lamp's brightness stays in a sane band around its nominal energy;
##   2. the map's lamp energy is not concentrated in one hue. This is deliberately a
##      LIGHTING-BUDGET check rather than a screenshot check -- it runs headless, where
##      there is no renderer to photograph, and it fails for the reason the screenshots
##      looked wrong rather than merely noticing that they did.
##
##     godot --headless --path . -s res://tests/lighting.gd

var failures: Array[String] = []


func _init() -> void:
	await process_frame
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var lights: Array[OmniLight3D] = []
	_collect(game, lights)
	if lights.size() < 6:
		failures.append("found only %d omni lamps; the map builds more than that"
				% lights.size())

	# 1. a flickering lamp may not silently run at some other lamp's brightness.
	for l in lights:
		if l.get_script() == null:
			continue
		var nominal: float = float(l.get("energy"))
		if nominal <= 0.0:
			failures.append("%s flickers but has no nominal energy" % l.name)
			continue
		# let it run through several glitch cycles and watch the extremes
		var lo := 1e9
		var hi := -1e9
		for _f in 240:
			await process_frame
			lo = minf(lo, l.light_energy)
			hi = maxf(hi, l.light_energy)
		if hi > nominal * 4.0:
			failures.append("%s peaks at %.2f, over 4x its nominal %.2f -- it is ignoring "
					% [l.name, hi, nominal] + "the energy the level gave it")
		if lo > nominal * 1.4:
			failures.append("%s never drops below %.2f; it is not flickering"
					% [l.name, lo])

	# 2. the lighting budget must not be one hue.
	var warm := 0.0
	var cool := 0.0
	for l in lights:
		var e: float = float(l.get("energy")) if l.get_script() != null else l.light_energy
		var c := l.light_color
		if c.r > c.g:
			warm += e
		else:
			cool += e
	var total := warm + cool
	var share: float = maxf(warm, cool) / maxf(total, 0.001)
	print("lamps=%d  warm=%.2f  cool=%.2f  dominant hue holds %.0f%% of the budget"
			% [lights.size(), warm, cool, share * 100.0])
	if share > 0.75:
		failures.append("one hue holds %.0f%% of the lamp budget -- every room will "
				% (share * 100.0) + "photograph as that colour")

	game.free()
	await process_frame
	if failures.is_empty():
		print("LIGHTING_OK")
		quit(0)
	for f in failures:
		push_error(f)
	quit(1)


func _collect(n: Node, out: Array[OmniLight3D]) -> void:
	if n is OmniLight3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)

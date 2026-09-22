extends Node

## Load EVERY script in the project and exit non-zero if any of them fails to compile.
##
## Why this exists, 2026-09-21. `ops/godot_build.sh` boots the project headless and
## refuses to build on a script error — which catches a parse error in anything the main
## scene reaches. It does NOT catch a parse error in a script nothing loads yet, and this
## project shipped exactly that: `scripts/shaped_button.gd` referenced `Shape.SLIP`, an
## enum member its stale copy of the shared file did not have, and the headless boot was
## clean because no scene instantiated a ShapedButton. The moment the buttons were wired
## up, every control in the game would have done nothing — the SilverTongue/Ghost Channel
## failure, one commit later.
##
## CACHE_MODE_IGNORE is the whole trick and it was found the hard way: plain `load()`
## returns a cached script object even when the reload it just attempted failed, so a
## first draft of this file printed "shaped_button -> OK" on the same run in which the
## engine printed "Failed to load script ... Parse error". That is the studio's
## "verification that lies" in miniature. Ignoring the cache forces a real compile and
## returns null when it fails.
##
## Run as a SCENE, never with `-s`: script mode does not register the project's autoloads,
## so every script that mentions `Gate` fails to compile and the check reports two false
## failures. Booting a scene registers them.
##
##   godot --headless --path . res://tests/script_load.tscn
##
## Proven by temporarily breaking a script and watching it exit 1.

func _ready() -> void:
	var bad: Array[String] = []
	var checked := 0
	for path in _scripts("res://scripts"):
		var s := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
		checked += 1
		if s == null or not (s as Script).can_instantiate():
			bad.append(path)
	print("script_load: %d script(s) compiled, %d failed" % [checked, bad.size()])
	for path in bad:
		print("  FAILED  ", path)
	get_tree().quit(1 if bad.size() > 0 else 0)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var path := dir.path_join(name)
		if d.current_is_dir():
			out.append_array(_scripts(path))
		elif name.ends_with(".gd"):
			out.append(path)
		name = d.get_next()
	d.list_dir_end()
	out.sort()
	return out

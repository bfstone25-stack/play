## Does every script in this project actually PARSE?
##
## 2026-09-21, and this cost the game its board score twice. `scripts/offline.gd` held one
## line — `var roll := _rng.randi() % max(1, total)` — whose type GDScript cannot infer,
## which is a parse error. Everything downstream of that was silent:
##
##   * `ops/godot_build.sh` exported the project with no error and a normal-sized pck;
##   * the web build loaded, drew its title and animated it;
##   * the play driver reported "page errors: none", because a GDScript parse failure is
##     not a JS exception — it is a console line;
##   * and the only visible symptom was an empty roster, which reads exactly like "the
##     backend is down", which is the thing the offline engine was written to fix.
##
## So the autoload that IS the offline game never instantiated, and the one file whose job
## was to make the game playable without a server was the file that was not loaded.
##
## A parse error is the cheapest possible bug to catch and it shipped, so it gets a test
## rather than a promise. ResourceLoader.load() on a .gd returns null when it cannot parse;
## that is the whole check. It walks res://scripts recursively so a file added later is
## covered without anyone remembering to list it.
##
##   godot --headless --path play/rebound-tycoon-godot res://tests/parse.tscn
##   godot --headless --path . res://tests/parse.tscn -- --prove-it-fails
##
## `--prove-it-fails` points the loader at a deliberately broken script written to
## user://, so the harness is seen failing before it is trusted passing — the memory note
## `verification-that-lies`, which is exactly the trap this bug fell into.
extends Node

const DIR := "res://scripts"

var bad: Array[String] = []
var seen := 0


func _ready() -> void:
	for p in _walk(DIR):
		_check(p)
	if "--prove-it-fails" in OS.get_cmdline_user_args():
		# res://, not user://: the loader treats a user:// path differently and the first
		# version of this sabotage came back CLEAN, which would have certified a harness
		# that cannot fail. And a hard syntax error, not a type-inference one, so the
		# sabotage does not depend on the project's warning settings either.
		var broken := "res://tests/_broken_on_purpose.gd"
		var f := FileAccess.open(broken, FileAccess.WRITE)
		f.store_string("extends Node\nfunc x(:\n")
		f.close()
		_check(broken)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(broken))
		if bad.is_empty():
			print("!! --prove-it-fails: the broken script PARSED. This harness cannot fail;")
			print("   do not trust it passing.")
			get_tree().quit(1)
			return
		print("ok: --prove-it-fails caught %s — the harness can fail." % bad[0])
		get_tree().quit(0)
		return
	print("%d script(s) checked" % seen)
	if bad.is_empty():
		print("ok: every script parses")
		get_tree().quit(0)
	else:
		for p in bad:
			print("!! does not parse: %s" % p)
		get_tree().quit(1)


## Three wrong checks were tried before this one, and --prove-it-fails found every one:
##
##   * `ResourceLoader.load(path) == null` — the GDScript loader hands back a GDScript
##     object for a file it could not parse, so a null test passes on a broken script and
##     the harness prints "every script parses" while the engine prints parse errors two
##     lines above it.
##   * `load(path).reload()` — right for an ordinary script, wrong for an autoload:
##     reload() refuses while live instances exist, so all five autoloads (Gate, Api,
##     Offline, Sfx, Loc) came back as failures.
##   * compiling a detached `GDScript.new()` copy of the source — wrong for any file with
##     a `class_name`, because the detached copy re-declares a global class that is
##     already registered. Twelve of twenty-three files failed.
##
## Each of those was a check with false alarms on a healthy project, which gets switched
## off within a day and is therefore the same as no check at all.
##
## What is actually true of a script that failed to parse, and not true of any healthy
## one, is that the engine cannot make an object out of it: `can_instantiate()` is false
## and it reports no base type. That reads the loaded resource without reloading it,
## re-declaring anything, or caring whether it is an autoload.
func _check(path: String) -> void:
	seen += 1
	var res := ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
	var gd := res as GDScript
	if gd == null or not gd.can_instantiate() or gd.get_instance_base_type() == &"":
		bad.append(path)


func _walk(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir.path_join(n)
		if d.current_is_dir():
			out.append_array(_walk(p))
		elif n.ends_with(".gd"):
			out.append(p)
		n = d.get_next()
	d.list_dir_end()
	return out

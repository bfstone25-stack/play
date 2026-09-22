## Origami — which model a level folds, and which fold the board is on. Autoloaded as
## "Origami".
##
## ops/fold/BRIDGE.md is the argument and the parent game (play/fold-godot) is where it was
## built first; this is PLICATA's copy of the lookup, with the fork's own data underneath
## it. The bridge rests on one fact that was already true of both games and was never said
## out loud: **the number on a tile is the number of paper layers**, and a sheet folded k
## times is 2^k layers thick. A 2 is one fold, a 4 is two, a 256 is eight, and the level's
## `target` is the fold that finishes the model. Nothing in here is a rule — `Fold` decides
## what happens on the board and its conformance test pins it to the shipped JavaScript.
## Delete every line of this file and the game plays identically; it would just go back to
## being a merge puzzle that never folds anything.
##
## What makes this the FORK's file rather than a copy of the parent's:
##
##   * `band`. ops/STANDARD.md, 2026-09-21: "tiers 1-2 fold paper, tier 3+ folds her, and
##     the reveal is the CG the gate already protects." So every model carries a band, the
##     first two tiers draw from `paper` and every tier after from `her`, and the payout at
##     the end of a tier is the gated CG `scripts/unlock.gd` already fetches (kind: "cg")
##     — never a picture of a crane. `is_her()` is what the rest of the game asks.
##   * The her-band steps are written to the same rule as this game's barks
##     (ops/barks/lines.json): suggestive, never explicit. A step line is on screen while
##     a storefront reviewer at Nutaku or DLsite is looking at the build.
##
## Two data files, both generated rather than hand-typed:
##   data/models.json — level -> model, for all 201 levels
##   data/steps.json  — model -> {band, name per language, steps:[{at, en, zh, ja}]}
extends Node

const MODELS_PATH := "res://data/models.json"
const STEPS_PATH := "res://data/steps.json"

var _level_model := {}   # level index -> model key
var _models := {}        # model key -> {en, zh, ja, band, steps:[{at, en, zh, ja}]}


func _ready() -> void:
	load_data()


func load_data() -> void:
	var m = _read(MODELS_PATH)
	if m is Dictionary and m.has("levels"):
		for row in m["levels"]:
			_level_model[int(row["level"])] = str(row["model"])
	var s = _read(STEPS_PATH)
	if s is Dictionary and s.has("models"):
		_models = s["models"]


func _read(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Origami: %s missing" % path)
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed


## The model key this level folds, or "" if the data does not cover it. Every caller has
## to survive "" — a level with no model shows the board exactly as it always did, rather
## than a header reading "· · 0 folds".
func model_for(level: int) -> String:
	return str(_level_model.get(level, ""))


func has_model(level: int) -> bool:
	return model_for(level) != "" and _models.has(model_for(level))


## "腰带" / "The sash".
func model_name(model: String, lang: String) -> String:
	if not _models.has(model):
		return ""
	var d: Dictionary = _models[model]
	return str(d.get(lang, d.get("en", "")))


func level_model_name(level: int, lang: String) -> String:
	return model_name(model_for(level), lang)


## Which world this level is folding in: "paper" for the first two tiers, "her" after.
## Callers use it to decide how far a line or a light may go, never to change a rule.
func band_of(model: String) -> String:
	if not _models.has(model):
		return ""
	return str(_models[model].get("band", "paper"))


## True when this level is folding her rather than a sheet. The one question the rest of
## the game asks of this file.
func is_her(level: int) -> bool:
	return band_of(model_for(level)) == "her"


func steps_of(model: String) -> Array:
	if not _models.has(model):
		return []
	return _models[model].get("steps", [])


## How many folds a sheet of `v` layers has taken: log2. A tile is never 0 or 1 on this
## board, but a caller may ask about an empty cell, so guard rather than trust it.
static func folds_for_value(v: int) -> int:
	var n := 0
	var x := maxi(v, 1)
	while x > 1:
		x >>= 1
		n += 1
	return n


## The whole model, in folds: the fold count of the level's target.
func folds_to_finish(level: int) -> int:
	var st := steps_of(model_for(level))
	if st.is_empty():
		return 0
	return folds_for_value(int(st[-1]["at"]))


## The diagram step a tile of this value has just completed — "Rolled to the knee" — or {}
## when this value is not a step of this model. The steps do not start at 2: the first one
## is `at: 4`, because a single fold of a square is not yet a shape with a name. A 2 on the
## board is therefore mid-step and returns {}.
func step_at(model: String, v: int) -> Dictionary:
	for s in steps_of(model):
		if int(s["at"]) == v:
			return s
	return {}


func step_text(model: String, v: int, lang: String) -> String:
	var s := step_at(model, v)
	if s.is_empty():
		return ""
	return str(s.get(lang, s.get("en", "")))

class_name MeritCurve
extends RefCounted
## Port of play/catharsis/kernel/merit.js — the exponential merit curve, line for line.
## Clicker numbers live here, not in the scene. tests/run_tests.gd asserts this class
## against the JS on the same inputs (tests/merit_conformance.json).

var merit: int = 0
var clicks: int = 0
var level: int = 1
var auto: int = 0


func click() -> int:
	clicks += 1
	var gain := int(floor(pow(1.18, level - 1)))
	merit += gain
	return gain


func tick(dt: float) -> int:
	if auto <= 0:
		return 0
	var gain := int(floor(auto * dt * pow(1.08, level - 1)))
	merit += gain
	return gain


func upgrade_cost() -> int:
	return int(floor(20 * pow(1.35, level - 1)))


func try_upgrade() -> bool:
	var cost := upgrade_cost()
	if merit < cost:
		return false
	merit -= cost
	level += 1
	if level % 3 == 0:
		auto += 1
	return true


func snapshot() -> Dictionary:
	return {"merit": merit, "clicks": clicks, "level": level, "auto": auto, "upgradeCost": upgrade_cost()}


func load(data) -> Dictionary:
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return snapshot()
	merit = maxi(0, int(floor(float(data.get("merit", 0)))))
	clicks = maxi(0, int(floor(float(data.get("clicks", 0)))))
	level = maxi(1, int(floor(float(data.get("level", 1)))))
	auto = maxi(0, int(floor(float(data.get("auto", 0)))))
	return snapshot()

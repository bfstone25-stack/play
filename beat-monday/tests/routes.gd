extends SceneTree

const Game = preload("res://scripts/game.gd")
const Story = preload("res://scripts/story_data.gd")

func _init() -> void:
	var failures := PackedStringArray()
	var endings := {"CLOCK_OUT": 0, "NEW_MANAGER": 0, "MONDAY_FOREVER": 0}
	for eli in ["TRUST", "SUSPECT"]:
		for compliance in ["REFUSE", "OBEY"]:
			for route in ["STAIRS", "ELEVATOR"]:
				for contract in ["RESIGN", "SIGN"]:
					var flags := {
						"eli_stance": eli,
						"compliance": compliance,
						"escape_route": route,
						"contract": contract
					}
					var result: Dictionary = Game.simulate_route(flags)
					endings[result.ending] += 1
					if result.areas != 7:
						failures.append("route did not traverse seven areas")
					if result.hotspots != 28:
						failures.append("route did not expose 28 hotspots")
					if eli == "TRUST" and "stair_gate_open" not in result.delayed:
						failures.append("trust consequence missing")
					if eli == "SUSPECT" and "eli_phone_compliance" not in result.delayed:
						failures.append("suspect consequence missing")
					if compliance == "REFUSE" and "ledger_preserved" not in result.delayed:
						failures.append("refusal consequence missing")
					if compliance == "OBEY" and "permanent_badge" not in result.delayed:
						failures.append("obedience consequence missing")
					if route == "STAIRS" and "replacement_list" not in result.delayed:
						failures.append("stairs evidence missing")
					if route == "ELEVATOR" and "rusk_keycard" not in result.delayed:
						failures.append("elevator evidence missing")
	if endings.CLOCK_OUT != 1 or endings.NEW_MANAGER != 1 or endings.MONDAY_FOREVER != 14:
		failures.append("ending eligibility distribution incorrect: %s" % endings)
	var canonical_routes := [
		{"eli_stance": "TRUST", "compliance": "REFUSE", "escape_route": "STAIRS", "contract": "RESIGN"},
		{"eli_stance": "SUSPECT", "compliance": "OBEY", "escape_route": "ELEVATOR", "contract": "SIGN"},
		{"eli_stance": "TRUST", "compliance": "OBEY", "escape_route": "STAIRS", "contract": "SIGN"}
	]
	for route in canonical_routes:
		var words := Story.route_word_count(route)
		var estimated_minutes := float(words) / 180.0 + 4.8
		if estimated_minutes < 25.0 or estimated_minutes > 35.0:
			failures.append("first-read estimate outside gate: %d words / %.1f minutes" % [words, estimated_minutes])
		print("ROUTE ", Story.resolve(route), " words=", words, " estimated_first_read_minutes=", snapped(estimated_minutes, 0.1))
	if failures.is_empty():
		print("ROUTES_OK combinations=16 endings=", endings, " areas=", Story.AREAS.size(), " hotspots=", Story.total_hotspots())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

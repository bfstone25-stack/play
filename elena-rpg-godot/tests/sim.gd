extends Node
## Balance + pacing sim: plays nights with the real game code (main.gd in auto mode, the
## NRPolicy "normal player", an explorer that does every hotspot it can reach) and checks
##   * every night is winnable with no grinding (no repeatable fights exist; a loss = reload),
##   * night 1 takes 40-70 minutes at measured pacing (voice clip lengths, 16 chars/s reading).
## Run: godot --headless --path play/elena-rpg-godot res://tests/sim.tscn -- --nights=night1 --runs=10

var main
var fails := 0
var report := []
var reckless := false
var prefer: Array = []
var expect_flags: Array = []


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var nights: Array = str(args.get("nights", "night1")).split(",")
	var runs := int(args.get("runs", "5"))
	reckless = args.get("policy", "") == "reckless"
	if args.has("prefer"):
		prefer = str(args["prefer"]).split("|")
	if args.has("expect"):
		expect_flags = str(args["expect"]).split(",")   # a check must be able to fail: this player should lose
	var lo := float(args.get("min", "40"))
	var hi := float(args.get("max", "70"))
	await get_tree().process_frame
	for nid in nights:
		var mins := []
		var losses := 0
		var clean := 0
		for r in runs:
			var res = await play_night(nid, r)
			mins.append(res["minutes"])
			losses += res["losses"]
			if res["losses"] == 0 and res["cleared"]:
				clean += 1
			if r == 0:
				print(JSON.stringify(res, " "))
		var avg := 0.0
		for m in mins:
			avg += m
		avg /= mins.size()
		print("%s: %d/%d runs cleared with no loss; avg %.1f min (min %.1f, max %.1f); %d losses" % [nid, clean, runs, avg, mins.min(), mins.max(), losses])
		check(clean >= int(ceil(runs * 0.8)), "%s winnable by a normal player without a loss in >=80%% of runs" % nid)
		if nid == nights[-1]:
			for f in expect_flags:
				check(RPG.flag(f), "flag %s set at the end of %s" % [f, nid])
		if nid == "night1":
			check(avg >= lo and avg <= hi, "%s pacing %.1f min within %d-%d" % [nid, avg, lo, hi])
	print("sim: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func check(c: bool, what: String) -> void:
	print(("ok   " if c else "FAIL ") + what)
	if not c:
		fails += 1


func play_night(nid: String, run: int) -> Dictionary:
	if main != null:
		main.queue_free()
		await get_tree().process_frame
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	main.auto = true
	add_child(main)
	main.event.auto_mode = true
	main.stop_after = nid
	main.prefer_menu = prefer
	if reckless:
		main.policy_override = func(b, mi):
			var m: Dictionary = b["party"][mi]
			for a in ["threaten", "bluff", "flirt"]:
				if a in RPG.actions_for(m["id"]) and NRRules.can_use(m, RPG.game["actions"][a], RPG.kinds()) == "":
					return [a, ""]
			return ["deflect", ""]
	RPG.new_game()
	# later nights start from the state a normal player carries in: replay earlier nights
	var order: Array = RPG.game["nights"]
	for prev in order.slice(0, order.find(nid)):
		main.stop_after = prev
		await main.start_night(prev)
		await _explore(prev)
	for k in main.pace.keys():
		main.pace[k] = 0.0
	main.stats["losses"] = 0
	main.stats["battles"] = []
	main.stop_after = nid
	var lv0 := int(RPG.s["level"])
	await main.start_night(nid)
	var steps := await _explore(nid)
	var total := 0.0
	for k in main.pace.keys():
		total += main.pace[k]
	return {"night": nid, "run": run, "cleared": nid in RPG.s["nights_cleared"], "losses": main.stats["losses"],
		"minutes": total / 60.0, "pace_min": _mins(main.pace), "level": [lv0, int(RPG.s["level"])], "trust": int(RPG.s["trust"]),
		"turns_left": int(RPG.s["turns_left"]), "steps": steps, "battles": main.stats["battles"]}


func _mins(p: Dictionary) -> Dictionary:
	var o := {}
	for k in p.keys():
		o[k] = snappedf(p[k] / 60.0, 0.1)
	return o


func _explore(nid: String) -> int:
	var steps := 0
	while not (nid in RPG.s["nights_cleared"]) and steps < 400:
		steps += 1
		var h = _next_hotspot()
		if h == null:
			push_error("sim: stuck in %s/%s" % [nid, RPG.s["room"]])
			fails += 1
			break
		await main.on_hotspot(h)
		if main.stats["losses"] > 12:
			break
	return steps


## Do anything in this room that is not a door; else walk toward the nearest room that has something.
func _next_hotspot():
	var here: Array = main.visible_hotspots()
	for h in here:
		if h["kind"] != "door":
			return h
	var rooms: Dictionary = RPG.night()["rooms"]
	var seen := {RPG.s["room"]: null}
	var queue := []
	for h in here:
		if _usable_door(h) and not seen.has(h["to"]):
			seen[h["to"]] = h
			queue.append([h["to"], h])
	while not queue.is_empty():
		var cur = queue.pop_front()
		var rid: String = cur[0]
		var first: Dictionary = cur[1]
		for h in main.visible_hotspots_in(rid):
			if h["kind"] != "door":
				return first
		if not RPG.s["done"].has("visited/" + rid) and rid != RPG.night()["start_room"]:
			return first  # an unvisited room has an enter event worth walking to
		for h in main.visible_hotspots_in(rid):
			if _usable_door(h) and not seen.has(h["to"]):
				seen[h["to"]] = first
				queue.append([h["to"], first])
	return null


func _usable_door(h: Dictionary) -> bool:
	return h["kind"] == "door" and (not h.has("needs") or RPG.has(h["needs"]))

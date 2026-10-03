extends Node
## Balance + pacing sim on the real game code (main.gd in auto mode, the NRPolicy "normal
## player", an explorer that does every hotspot it can reach). Plays the prologue (picking the
## route), then the route's chapters in order, and checks
##   * every chapter is cleared, with no loss in >=80% of runs (runs >= 5) or at most one
##     reload per run (runs < 5); no grinding exists (no repeatable fights; a loss = reload);
##   * chapter 1 takes --min..--max minutes at measured pacing (16 chars/s reading);
##   * --expect flags are set at the end (route / ending coverage).
## Run: godot --headless --path play/vesper-rpg-godot res://tests/sim.tscn -- --route=guyan --upto=5 --runs=1

var main
var fails := 0
var reckless := false
var prefer: Array = []
var expect_flags: Array = []
var player := "warm"     # warm (the normal player) / middle (warm, never a best-ending flag) / cold
var avoid: Array = []


func _ready() -> void:
	get_tree().root.set_meta("nr_no_title", true)
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var route := str(args.get("route", "guyan"))
	var upto := int(args.get("upto", "5"))
	var runs := int(args.get("runs", "3"))
	reckless = args.get("policy", "") == "reckless"
	player = str(args.get("player", "warm"))
	if player == "middle":
		var idx = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_index.json"))
		for e in idx[route]["endings"]:
			if int(e["priority"]) == 1:
				avoid = e["flags_any"]
	prefer = [_pick_text(route)]
	if args.has("prefer"):
		prefer += Array(str(args["prefer"]).split("|"))
	if args.has("expect"):
		expect_flags = Array(str(args["expect"]).split(","))
	var lo := float(args.get("min", "0"))
	var hi := float(args.get("max", "999"))
	await get_tree().process_frame
	var per := {}
	for r in runs:
		var res: Dictionary = await play_route(route, upto, r)
		for k in res.keys():
			if not per.has(k):
				per[k] = []
			per[k].append(res[k])
	for c in range(1, upto + 1):
		var nid := "%s_c%d" % [route, c]
		var rs: Array = per.get(nid, [])
		var clean := 0
		var cleared := 0
		var losses := 0
		var mins := 0.0
		for x in rs:
			if x["cleared"]:
				cleared += 1
			if x["cleared"] and x["losses"] == 0:
				clean += 1
			losses += x["losses"]
			mins += x["minutes"]
		mins /= max(1, rs.size())
		print("%s: %d/%d cleared, %d/%d with no loss; avg %.1f min; %d losses; lv %s; trust %s" % [nid, cleared, runs, clean, runs, mins, losses,
			str(rs[0]["level"]) if rs.size() > 0 else "-", str(rs[0]["trust"]) if rs.size() > 0 else "-"])
		if runs >= 5:
			check(clean >= int(ceil(runs * 0.8)), "%s winnable by a normal player without a loss in >=80%% of runs" % nid)
		else:
			check(cleared == runs and losses <= runs, "%s finished with at most one reload per run" % nid)
		if c == 1:
			check(mins >= lo and mins <= hi, "%s pacing %.1f min within %d-%d" % [nid, mins, lo, hi])
	for f in expect_flags:
		check(RPG.flag(f), "flag %s set at the end of %s" % [f, route])
	print("sim: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func _pick_text(route: String) -> String:
	var t: String = Loc.table.get("pick_" + route, {}).get("en", route)
	return t.substr(0, 12)


func check(c: bool, what: String) -> void:
	print(("ok   " if c else "FAIL ") + what)
	if not c:
		fails += 1


func play_route(route: String, upto: int, run: int) -> Dictionary:
	if main != null:
		main.queue_free()
		await get_tree().process_frame
	main = load("res://addons/night_rpg/ui/main.tscn").instantiate()
	main.auto = true
	add_child(main)
	main.event.auto_mode = true
	main.prefer_menu = prefer
	if player != "warm":
		main.choice_override = _choose
	if player != "warm":
		# the middle and cold players are also less attentive on dates: they play like the
		# normal player but never stop to read him, so they win further away (less Trust)
		main.policy_override = func(b, mi):
			var pick: Array = NRPolicy.choose(b, mi)
			if pick[0] == "observe":
				var m: Dictionary = b["party"][mi]
				for a in ["tease", "banter"]:
					if NRRules.can_use(m, RPG.game["actions"][a], RPG.kinds()) == "":
						return [a, ""]
			return pick
	if reckless:
		main.policy_override = func(b, mi):
			var m: Dictionary = b["party"][mi]
			for a in ["push", "banter", "tease"]:
				if a in RPG.actions_for(m["id"]) and NRRules.can_use(m, RPG.game["actions"][a], RPG.kinds()) == "":
					return [a, ""]
			return ["deflect", ""]
	RPG.new_game()
	main.stop_after = "prologue"
	await main.start_night("prologue")
	var out := {}
	if not RPG.flag("r_" + route):
		push_error("sim: the prologue did not pick " + route)
		fails += 1
		return out
	for c in range(1, upto + 1):
		var nid := "%s_c%d" % [route, c]
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
		out[nid] = {"cleared": nid in RPG.s["nights_cleared"], "losses": main.stats["losses"], "minutes": total / 60.0,
			"level": [lv0, int(RPG.s["level"])], "trust": RPG.trust_shown(), "steps": steps, "turns_left": int(RPG.s["turns_left"])}
		if run == 0:
			out[nid]["battles"] = main.stats["battles"]
			print(JSON.stringify({"night": nid, "pace_min": _mins(main.pace), "res": out[nid]}))
		if not out[nid]["cleared"]:
			break
	return out


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
		_auto_equip()
		if main.stats["losses"] > 12:
			break
	return steps


## Do anything in this room that is not a door; else walk toward the nearest room that has something.
func _next_hotspot():
	var here: Array = main.visible_hotspots()
	for h in here:
		if h["kind"] != "door":
			return h
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
			return first
		for h in main.visible_hotspots_in(rid):
			if _usable_door(h) and not seen.has(h["to"]):
				seen[h["to"]] = first
				queue.append([h["to"], first])
	return null


func _usable_door(h: Dictionary) -> bool:
	return h["kind"] == "door" and (not h.has("needs") or RPG.has(h["needs"]))


## A normal player puts on what they find: per slot, the item with the larger stat bonus.
func _auto_equip() -> void:
	for id in RPG.s["items"].keys().duplicate():
		var d := RPG.item_def(id)
		var slot: String = d.get("slot", "")
		if slot == "":
			continue
		var cur: String = RPG.s["members"]["you"]["equip"][slot]
		if cur == "" or _worth(d) > _worth(RPG.item_def(cur)):
			RPG.equip("you", id)


func _worth(d: Dictionary) -> float:
	var v := 0.0
	for k in d.get("bonus", {}).values():
		v += float(k)
	for k in d.get("mult", {}).values():
		v += float(k) * 3.0
	return v


func _trust_of(o: Dictionary) -> int:
	var t := 0
	for d in o.get("do", []):
		if d is Dictionary:
			t += int(d.get("trust", 0))
	return t


func _sets_avoided(o: Dictionary) -> bool:
	for d in o.get("do", []):
		if d is Dictionary and d.has("flag") and str(d["flag"]) in avoid:
			return true
	return false


## The cold and middle players (ending coverage). Cold takes the option that costs the most
## Trust and always declines; middle plays warm but never sets a best-ending flag.
func _choose(opts: Array) -> int:
	for i in opts.size():
		for pm in prefer:
			if str(opts[i].get("menu", "")).contains(pm):
				return i
	var best := -1
	var best_v := -999.0
	for i in opts.size():
		var o: Dictionary = opts[i]
		if o.has("req_trust") and RPG.trust(o.get("req_track", "")) < int(o["req_trust"]):
			continue
		var v := float(_trust_of(o)) + float(o.get("auto_rank", 0)) * 0.1
		if player == "cold":
			v = -v
		elif player == "middle":
			v = -absf(float(_trust_of(o))) + float(o.get("auto_rank", 0)) * 0.1 - (100.0 if _sets_avoided(o) else 0.0)
		if v > best_v:
			best_v = v
			best = i
	return max(0, best)

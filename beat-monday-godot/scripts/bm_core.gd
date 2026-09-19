## BMCore — the loop, ported line for line from play/beat-monday/frontend/rpg/core.js plus
## the kernel functions it leans on (kernel/pool.js circleHit/moveToward, kernel/rant.js
## rantPattern/rantShotPower/rantDamage). Pure: no nodes, no drawing. The run and the
## profile are Dictionaries with the JS field names so tests/run_tests.gd can hold this
## file to the JS core over the same seeded inputs.
##
## Numeric notes for the conformance test:
##   - mulberry32 is emulated in uint32 arithmetic (masks stand in for |0 and >>>);
##   - JS Math.hypot is a scaled sum; here hypot is sqrt(dx*dx+dy*dy) and the JS harness
##     (tests/conformance_gen.cjs) installs the same definition into its Math before
##     loading the core, so both sides run identical arithmetic;
##   - toFixed(2) is printf("%.2f") — see js_fixed2().
class_name BMCore

const W := 420.0
const H := 640.0
const MASK := 0xFFFFFFFF


# ---------- mulberry32, bit-for-bit ------------------------------------------------------
static func imul(a: int, b: int) -> int:
	return (a * b) & MASK


static func rng(run: Dictionary) -> float:
	var a: int = (run["rng"] + 0x6D2B79F5) & MASK
	run["rng"] = a
	var t: int = imul(a ^ (a >> 15), 1 | a)
	t = ((t + imul(t ^ (t >> 7), 61 | t)) & MASK) ^ t
	return float((t ^ (t >> 14)) & MASK) / 4294967296.0


static func js_fixed2(x: float) -> float:
	return float("%.2f" % x)


static func hypot(dx: float, dy: float) -> float:
	return sqrt(dx * dx + dy * dy)


static func circle_hit(ax: float, ay: float, ar: float, bx: float, by: float, br: float) -> bool:
	var dx := ax - bx
	var dy := ay - by
	var r := ar + br
	return dx * dx + dy * dy < r * r


static func move_toward_pt(e: Dictionary, tx: float, ty: float, speed: float, dt: float) -> void:
	var dx: float = tx - e["x"]
	var dy: float = ty - e["y"]
	var d := hypot(dx, dy)
	if d == 0.0:
		d = 1.0
	e["x"] = e["x"] + dx / d * speed * dt
	e["y"] = e["y"] + dy / d * speed * dt


# ---------- kernel/rant.js -----------------------------------------------------------------
static func rant_damage(combo: Array, catalog: Array) -> float:
	var dmg := 12.0 * combo.size()
	for p in catalog:
		if combo.has(p["text"]):
			dmg += p.get("power", 0)
	return dmg


static func rant_pattern(ids: Array, catalog: Array) -> String:
	var load: Array = []
	for id in ids:
		for p in catalog:
			if p["id"] == id:
				load.append(p)
				break
	if load.is_empty():
		return "stream"
	var power := 0.0
	var legend := false
	for p in load:
		power += p.get("power", 0)
		if p["id"] == "legend":
			legend = true
	if legend or power >= 120:
		return "burst"
	if load.size() >= 3 or power >= 50:
		return "spread"
	return "stream"


static func rant_shot_power(combo: Array, catalog: Array) -> float:
	return maxf(3.0, rant_damage(combo, catalog) / 24.0)


static func rant_catalog() -> Array:
	var out: Array = []
	for r in BMData.RANT:
		out.append({"id": r["id"], "power": r["power"], "text": r["id"]})
	return out


# ---------- profile --------------------------------------------------------------------------
static func new_profile() -> Dictionary:
	return {
		"role": "ic", "week": 0, "day": 0, "level": 1, "xp": 0,
		"skills": [], "owned": [], "equipped": {"hand": null, "desk": null, "wear": null},
		"party": [], "rant": ["ok"], "cleared": [],
	}


static func xp_needed(level: int) -> int:
	return 10 + level * 9


static func compute_stats(profile: Dictionary) -> Dictionary:
	var role := BMData.find(BMData.ROLES, profile.get("role", "ic"))
	if role.is_empty():
		role = BMData.ROLES[0]
	var lv: int = maxi(1, int(profile.get("level", 1)))
	var s := {
		"hp": float(role["base"]["hp"] + role["growth"]["hp"] * (lv - 1)),
		"atk": float(role["base"]["atk"] + role["growth"]["atk"] * (lv - 1)),
		"rate": float(role["base"]["rate"]),
		"spd": float(role["base"]["spd"]),
		"flags": {},
	}
	var equipped: Dictionary = profile.get("equipped", {})
	for slot in ["hand", "desk", "wear"]:
		var item := BMData.find(BMData.EQUIP, equipped.get(slot))
		if not item.is_empty():
			_add_mods(s, item["mods"])
	for id in profile.get("skills", []):
		var sk := BMData.find(BMData.SKILLS, id)
		if sk.is_empty():
			continue
		_add_mods(s, sk["mods"])
		if sk.has("flag"):
			s["flags"][sk["flag"]] = s["flags"].get(sk["flag"], 0) + 1
	s["hp"] = maxi(20, int(round(s["hp"])))
	s["atk"] = maxf(1.0, js_fixed2(s["atk"]))
	s["rate"] = maxf(0.4, js_fixed2(s["rate"]))
	s["spd"] = maxi(40, int(round(s["spd"])))
	var dps := 0
	for id in profile.get("party", []):
		var p := BMData.find(BMData.PARTY, id)
		if not p.is_empty():
			dps += p["dps"]
	s["partyDps"] = dps
	return s


static func _add_mods(s: Dictionary, mods: Dictionary) -> void:
	# JS: `if (mods.hp)` — a 0 is skipped, a negative is applied
	for k in ["hp", "atk", "rate", "spd"]:
		if mods.has(k) and mods[k] != 0:
			s[k] = s[k] + mods[k]


# ---------- run --------------------------------------------------------------------------------
static func create_run(profile: Dictionary, day_index: int, seed = null) -> Dictionary:
	var day: Dictionary = BMData.DAYS[day_index]
	var week: Dictionary = BMData.WEEKS[mini(int(profile.get("week", 0)), BMData.WEEKS.size() - 1)]
	var stats := compute_stats(profile)
	var s: int = (day_index + 1) * 7919 if seed == null else int(seed)
	return {
		"day": day, "dayIndex": day_index, "week": week, "stats": stats, "profile": profile,
		"rng": s & MASK, "lang": "en",
		"t": 0.0, "spawnT": 0.0, "fireT": 0.0, "phase": "wave", "over": null,
		"hp": float(stats["hp"]), "maxHp": float(stats["hp"]),
		"level": int(profile["level"]), "xp": int(profile["xp"]), "pending": null,
		"px": W / 2, "py": H * 0.72,
		"foes": [], "shots": [], "foeShots": [], "picks": [],
		"boss": null, "kills": 0, "rantCombo": Array(profile.get("rant", [])).duplicate(),
		"lastPattern": "stream", "shotsFired": 0, "phrasesFired": 0, "reward": null,
		"hurtCd": 0.0, "elapsedFire": 0.0,
	}


static func spawn_foe(run: Dictionary) -> void:
	var kinds: Array = run["day"]["foes"]
	var kind: String = kinds[int(floor(rng(run) * kinds.size())) % kinds.size()]
	var base: Dictionary = BMData.FOES[kind]
	var edge := int(floor(rng(run) * 4))
	var x: float
	var y: float
	if edge == 0:
		x = rng(run) * W; y = -20.0
	elif edge == 1:
		x = rng(run) * W; y = H + 20.0
	elif edge == 2:
		x = -20.0; y = rng(run) * H
	else:
		x = W + 20.0; y = rng(run) * H
	var ramp: float = 1.0 + run["t"] / 90.0
	run["foes"].append({
		"kind": kind, "x": x, "y": y, "r": float(base["r"]), "color": base["color"],
		"hp": base["hp"] * ramp * run["week"]["hpMul"], "spd": float(base["spd"]), "xp": base["xp"],
		"dmg": base["dmg"] * run["week"]["dmgMul"], "hit": 0.0,
		"seed": rng_peek(run),
	})


## Presentation-only per-foe variety (bob phase, spin direction). Not an rng() call: it
## reads the state without advancing it, so the JS core's random sequence is untouched.
static func rng_peek(run: Dictionary) -> float:
	return float(run["rng"] & 0xFFFF) / 65536.0


static func spawn_boss(run: Dictionary) -> void:
	run["phase"] = "boss"
	var d: Dictionary = run["day"]
	var w: Dictionary = run["week"]
	run["boss"] = {
		"x": W / 2, "y": 110.0, "r": 34.0, "hp": d["bossHp"] * w["hpMul"],
		"maxHp": d["bossHp"] * w["hpMul"], "dmg": d["bossDmg"] * w["dmgMul"],
		"shotT": 0.0, "shotEvery": float(d["bossShot"]), "dir": 1, "hit": 0.0,
	}


static func nearest_foe(run: Dictionary) -> Dictionary:
	var best := {}
	var bd := INF
	var px: float = run["px"]
	var py: float = run["py"]
	for f in run["foes"]:
		var d: float = (f["x"] - px) * (f["x"] - px) + (f["y"] - py) * (f["y"] - py)
		if d < bd:
			bd = d; best = f
	if run["boss"] != null:
		var b: Dictionary = run["boss"]
		var d: float = (b["x"] - px) * (b["x"] - px) + (b["y"] - py) * (b["y"] - py)
		if d < bd:
			bd = d; best = b
	return best


static func fire(run: Dictionary) -> void:
	var target := nearest_foe(run)
	if target.is_empty():
		return
	var ang: float = atan2(target["y"] - run["py"], target["x"] - run["px"])
	var rant: bool = run["day"]["mode"] == "rant"
	var n := 1
	var spread := 0.0
	if rant:
		var pattern := rant_pattern(run["rantCombo"], rant_catalog())
		run["lastPattern"] = pattern
		if pattern == "spread":
			n = 3; spread = 0.26
		elif pattern == "burst":
			n = 5; spread = 0.34
	var flags: Dictionary = run["stats"]["flags"]
	if flags.has("multishot"):
		n += 1; spread = maxf(spread, 0.18)
	var combo: Array = run["rantCombo"].duplicate()
	var dmg: float = run["stats"]["atk"] * 0.6 + rant_shot_power(combo, rant_catalog()) if rant else float(run["stats"]["atk"])
	for i in n:
		var a: float = ang + ((i - (n - 1) / 2.0) * spread if n > 1 else 0.0)
		run["shots"].append({
			"x": run["px"], "y": run["py"], "vx": cos(a) * 420.0, "vy": sin(a) * 420.0,
			"r": 10.0 if rant else 5.0, "dmg": dmg, "life": 1.6, "pierce": 2 if flags.has("pierce") else 0,
			"text": phrase_for(run, i) if rant else "", "age": 0.0,
		})
		run["shotsFired"] = run["shotsFired"] + 1
		if rant:
			run["phrasesFired"] = run["phrasesFired"] + 1


static func phrase_for(run: Dictionary, i: int) -> String:
	var combo: Array = run["rantCombo"]
	var id = combo[(run["shotsFired"] + i) % combo.size()] if combo.size() else "ok"
	if id == null or str(id) == "":
		id = "ok"
	return BMPhrases.shot(run.get("lang", "en"), str(id))


static func gain_xp(run: Dictionary, n: int) -> void:
	run["xp"] = run["xp"] + n
	while run["xp"] >= xp_needed(run["level"]):
		run["xp"] = run["xp"] - xp_needed(run["level"])
		run["level"] = run["level"] + 1
		if run["pending"] == null:
			var c := skill_choices(run)
			run["pending"] = c if c.size() else null


static func skill_choices(run: Dictionary) -> Array:
	var have_skills: Array = run["profile"].get("skills", [])
	var bag: Array = []
	for s in BMData.SKILLS:
		var have := have_skills.count(s["id"])
		if (have < 1) if s.has("flag") else (have < 5):
			bag.append(s)
	var out: Array = []
	while out.size() < 3 and bag.size():
		var idx := int(floor(rng(run) * bag.size())) % bag.size()
		out.append(bag[idx]["id"])
		bag.remove_at(idx)
	return out


static func apply_skill(run: Dictionary, id: String) -> bool:
	if run["pending"] == null or not (run["pending"] as Array).has(id):
		return false
	run["profile"]["skills"].append(id)
	run["pending"] = null
	var before: float = run["maxHp"]
	var p: Dictionary = run["profile"].duplicate()
	p["level"] = run["level"]
	run["stats"] = compute_stats(p)
	run["maxHp"] = float(run["stats"]["hp"])
	run["hp"] = run["hp"] + maxf(0.0, run["maxHp"] - before)
	return true


## `target` is null or {x, y}. Returns the run (mutated in place, like the JS).
static func step(run: Dictionary, dt: float, target) -> Dictionary:
	if run["over"] != null or run["pending"] != null:
		return run
	run["t"] = run["t"] + dt
	run["hurtCd"] = maxf(0.0, run["hurtCd"] - dt)

	if target != null:
		var dx: float = target["x"] - run["px"]
		var dy: float = target["y"] - run["py"]
		var d := hypot(dx, dy)
		if d > 1.0:
			var m := minf(d, run["stats"]["spd"] * dt)
			run["px"] = run["px"] + dx / d * m
			run["py"] = run["py"] + dy / d * m
	run["px"] = maxf(12.0, minf(W - 12.0, run["px"]))
	run["py"] = maxf(60.0, minf(H - 12.0, run["py"]))

	if run["phase"] == "wave":
		run["spawnT"] = run["spawnT"] + dt
		if run["spawnT"] >= run["day"]["spawnEvery"]:
			run["spawnT"] = 0.0
			for i in int(run["day"]["perSpawn"]):
				spawn_foe(run)
		if run["t"] >= run["day"]["dur"]:
			spawn_boss(run)

	run["fireT"] = run["fireT"] + dt
	var period: float = 1.0 / run["stats"]["rate"]
	while run["fireT"] >= period:
		run["fireT"] = run["fireT"] - period
		fire(run)

	if run["stats"]["partyDps"]:
		var t := nearest_foe(run)
		if not t.is_empty():
			t["hp"] = t["hp"] - run["stats"]["partyDps"] * dt
			if not is_same(t, run["boss"]) and t["hp"] <= 0:
				kill_foe(run, _index_of(run["foes"], t))

	var slow: float = 0.7 if run["stats"]["flags"].has("slowfoes") else 1.0
	var foes: Array = run["foes"]
	for i in range(foes.size() - 1, -1, -1):
		var f: Dictionary = foes[i]
		move_toward_pt(f, run["px"], run["py"], f["spd"] * slow, dt)
		f["hit"] = maxf(0.0, f["hit"] - dt * 4)
		if circle_hit(f["x"], f["y"], f["r"], run["px"], run["py"], 11.0):
			damage_player(run, f["dmg"])
			f["hp"] = f["hp"] - 1e9
		if f["hp"] <= 0:
			kill_foe(run, i)

	if run["boss"] != null:
		var b: Dictionary = run["boss"]
		b["hit"] = maxf(0.0, b["hit"] - dt * 4)
		b["x"] = b["x"] + b["dir"] * 52.0 * dt
		if b["x"] < 60.0:
			b["x"] = 60.0; b["dir"] = 1
		if b["x"] > W - 60.0:
			b["x"] = W - 60.0; b["dir"] = -1
		b["y"] = b["y"] + sin(run["t"] * 1.4) * 14.0 * dt
		b["shotT"] = b["shotT"] + dt
		if b["shotT"] >= b["shotEvery"]:
			b["shotT"] = 0.0
			var n := 5
			var base: float = atan2(run["py"] - b["y"], run["px"] - b["x"])
			for i in n:
				var a: float = base + (i - (n - 1) / 2.0) * 0.22
				run["foeShots"].append({"x": b["x"], "y": b["y"], "vx": cos(a) * 150.0, "vy": sin(a) * 150.0,
					"r": 6.0, "dmg": b["dmg"] * 0.5, "life": 5.0})
		if circle_hit(b["x"], b["y"], b["r"], run["px"], run["py"], 11.0):
			damage_player(run, b["dmg"] * dt * 2.2)
		if b["hp"] <= 0:
			run["boss"] = null
			run["phase"] = "clear"
			run["over"] = "clear"
			run["reward"] = run["day"]["drop"]

	var shots: Array = run["shots"]
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		s["x"] = s["x"] + s["vx"] * dt
		s["y"] = s["y"] + s["vy"] * dt
		s["life"] = s["life"] - dt
		s["age"] = s.get("age", 0.0) + dt
		var dead: bool = s["life"] <= 0 or s["x"] < -30 or s["x"] > W + 30 or s["y"] < -30 or s["y"] > H + 30
		if not dead:
			for j in range(run["foes"].size() - 1, -1, -1):
				var f: Dictionary = run["foes"][j]
				if not circle_hit(s["x"], s["y"], s["r"], f["x"], f["y"], f["r"]):
					continue
				f["hp"] = f["hp"] - s["dmg"]
				f["hit"] = 1.0
				if f["hp"] <= 0:
					kill_foe(run, j)
				if s["pierce"] > 0:
					s["pierce"] = s["pierce"] - 1
				else:
					dead = true
				break
		if not dead and run["boss"] != null and circle_hit(s["x"], s["y"], s["r"], run["boss"]["x"], run["boss"]["y"], run["boss"]["r"]):
			run["boss"]["hp"] = run["boss"]["hp"] - s["dmg"]
			run["boss"]["hit"] = 1.0
			if s["pierce"] > 0:
				s["pierce"] = s["pierce"] - 1
			else:
				dead = true
		if dead:
			_on_shot_dead(run, s)
			shots.remove_at(i)

	var fs: Array = run["foeShots"]
	for i in range(fs.size() - 1, -1, -1):
		var s: Dictionary = fs[i]
		s["x"] = s["x"] + s["vx"] * dt
		s["y"] = s["y"] + s["vy"] * dt
		s["life"] = s["life"] - dt
		if circle_hit(s["x"], s["y"], s["r"], run["px"], run["py"], 10.0):
			damage_player(run, s["dmg"])
			fs.remove_at(i)
			continue
		if s["life"] <= 0 or s["x"] < -30 or s["x"] > W + 30 or s["y"] < -30 or s["y"] > H + 30:
			fs.remove_at(i)

	var picks: Array = run["picks"]
	for i in range(picks.size() - 1, -1, -1):
		var p: Dictionary = picks[i]
		p["life"] = p["life"] - dt
		if circle_hit(p["x"], p["y"], 16.0, run["px"], run["py"], 12.0):
			if not run["rantCombo"].has(p["id"]):
				run["rantCombo"].append(p["id"])
			picks.remove_at(i)
		elif p["life"] <= 0:
			picks.remove_at(i)
	return run


## Presentation hook: the arena listens for shattering phrases. Not part of the JS core.
static var on_shot_dead: Callable = Callable()

static func _on_shot_dead(run: Dictionary, s: Dictionary) -> void:
	if on_shot_dead.is_valid() and s.get("text", "") != "":
		on_shot_dead.call(run, s)


static func _index_of(arr: Array, item: Dictionary) -> int:
	for i in arr.size():
		if is_same(arr[i], item):
			return i
	return -1


static func kill_foe(run: Dictionary, idx: int) -> void:
	if idx < 0 or idx >= run["foes"].size():
		return
	var f: Dictionary = run["foes"][idx]
	run["foes"].remove_at(idx)
	run["kills"] = run["kills"] + 1
	if on_foe_killed.is_valid():
		on_foe_killed.call(run, f)
	gain_xp(run, int(f["xp"]))
	if run["day"]["mode"] == "rant" and rng(run) < 0.05:
		var pool: Array = []
		for r in BMData.RANT:
			if not run["rantCombo"].has(r["id"]):
				pool.append(r)
		if pool.size():
			run["picks"].append({"x": f["x"], "y": f["y"],
				"id": pool[int(floor(rng(run) * pool.size())) % pool.size()]["id"], "life": 10.0})

static var on_foe_killed: Callable = Callable()


static func damage_player(run: Dictionary, n: float) -> void:
	if run["over"] != null:
		return
	run["hp"] = run["hp"] - n
	if on_player_hurt.is_valid():
		on_player_hurt.call(run, n)
	if run["hp"] <= 0:
		run["hp"] = 0.0
		run["over"] = "dead"
		run["phase"] = "dead"

static var on_player_hurt: Callable = Callable()


# ---------- between days --------------------------------------------------------------------
static func commit_run(profile: Dictionary, run: Dictionary) -> Dictionary:
	profile["level"] = run["level"]
	profile["xp"] = run["xp"]
	profile["rant"] = run["rantCombo"].duplicate()
	if run["over"] != "clear":
		return profile
	var day: String = run["day"]["id"]
	if not profile["cleared"].has(day):
		profile["cleared"].append(day)
	if run["reward"] != null and not profile["owned"].has(run["reward"]):
		profile["owned"].append(run["reward"])
		var item := BMData.find(BMData.EQUIP, run["reward"])
		if not item.is_empty() and profile["equipped"].get(item["slot"]) == null:
			profile["equipped"][item["slot"]] = item["id"]
	for p in BMData.PARTY:
		if p["after"] == day and not profile["party"].has(p["id"]):
			profile["party"].append(p["id"])
	profile["day"] = run["dayIndex"] + 1
	if profile["day"] >= BMData.DAYS.size():
		profile["day"] = 0
		profile["week"] = profile["week"] + 1
		profile["weekend"] = true
	return profile


static func equip(profile: Dictionary, id: String) -> bool:
	var item := BMData.find(BMData.EQUIP, id)
	if item.is_empty() or not profile["owned"].has(id):
		return false
	var slot: String = item["slot"]
	profile["equipped"][slot] = null if profile["equipped"].get(slot) == id else id
	return true

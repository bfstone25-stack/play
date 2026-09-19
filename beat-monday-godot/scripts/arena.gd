## Arena — draws one day of the run: the office plate, the nuisances, the boss, the shots,
## the phrases, the colleagues and the player. Reads the core's run dictionary every frame
## and owns nothing but presentation state (clock, hit flashes, letter fragments).
extends Node2D

var run: Dictionary = {}
var clock := 0.0
var hurt := 0.0          # 0..1 player hit reaction
var face := 1.0
var moving := 0.0
var last_p := Vector2.ZERO
var frags: Array = []    # shattered phrase letters: {p, v, ch, life, rot}
var puffs: Array = []    # kill puffs: {p, life, kind}
var plate: Texture2D
var plate_day := ""
var display_font: Font
var placement: Dictionary = {}   # the deploy node's tiles (BMDeploy), drawn under the play


func _ready() -> void:
	display_font = StudioTheme.font("display")
	BMCore.on_shot_dead = _shatter
	BMCore.on_foe_killed = _puff
	BMCore.on_player_hurt = _hurt


func set_run(r: Dictionary) -> void:
	run = r
	frags.clear()
	puffs.clear()
	hurt = 0.0
	if not r.is_empty():
		_load_plate(r["day"]["id"])
		last_p = Vector2(r["px"], r["py"])
		_shots_seen = r["shotsFired"]
		_combo_seen = r["rantCombo"].size()


func _load_plate(day_id: String) -> void:
	if plate_day == day_id:
		return
	plate_day = day_id
	var path := "res://assets/art/plate_%s.webp" % day_id
	plate = load(path) if ResourceLoader.exists(path) else null


var _shots_seen := 0
var _combo_seen := 0

func _process(dt: float) -> void:
	clock += dt
	hurt = maxf(0.0, hurt - dt * 3.0)
	if not run.is_empty():
		if run["shotsFired"] != _shots_seen:
			_shots_seen = run["shotsFired"]
			if run["day"]["mode"] == "rant":
				Sfx.rant()
			else:
				Sfx.fire()
		if run["rantCombo"].size() > _combo_seen:
			Sfx.pickup()
		_combo_seen = run["rantCombo"].size()
		var p := Vector2(run["px"], run["py"])
		var v := (p - last_p) / maxf(dt, 1e-4)
		moving = lerpf(moving, clampf(v.length() / 80.0, 0.0, 1.0), 0.3)
		if absf(v.x) > 8.0:
			face = 1.0 if v.x > 0 else -1.0
		last_p = p
		# foe velocity for the paper plane's heading
		for f in run["foes"]:
			var fp := Vector2(f["x"], f["y"])
			f["vx"] = p.x - fp.x
			f["vy"] = p.y - fp.y
	for i in range(frags.size() - 1, -1, -1):
		var fr: Dictionary = frags[i]
		fr["life"] -= dt
		fr["v"].y += 520.0 * dt
		fr["p"] += fr["v"] * dt
		fr["rot"] += fr["spin"] * dt
		if fr["life"] <= 0:
			frags.remove_at(i)
	for i in range(puffs.size() - 1, -1, -1):
		puffs[i]["life"] -= dt
		if puffs[i]["life"] <= 0:
			puffs.remove_at(i)
	queue_redraw()


func _shatter(_run: Dictionary, s: Dictionary) -> void:
	var text: String = s["text"]
	var w := display_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var x0: float = s["x"] - w / 2
	var v := Vector2(s["vx"], s["vy"])
	for i in text.length():
		var ch := text.substr(i, 1)
		var cw := display_font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		frags.append({
			"p": Vector2(x0 + cw / 2, s["y"]), "ch": ch, "life": 0.55 + randf() * 0.25,
			"v": v * 0.15 + Vector2(randf_range(-90, 90), randf_range(-160, -40)),
			"rot": 0.0, "spin": randf_range(-6, 6),
		})
		x0 += cw
	if frags.size() > 160:
		frags = frags.slice(frags.size() - 160)


func _puff(_run: Dictionary, f: Dictionary) -> void:
	puffs.append({"p": Vector2(f["x"], f["y"]), "life": 0.32, "kind": f["kind"], "r": f["r"]})
	Sfx.hit()


func _hurt(_run: Dictionary, n: float) -> void:
	if n > 0.5:
		hurt = 1.0
		Sfx.hurt()


func _draw() -> void:
	var size := Vector2(BMCore.W, BMCore.H)
	var day_id: String = run["day"]["id"] if not run.is_empty() else "mon"
	if plate:
		# the plate is cooled and pushed back so the drawn things in front of it read
		draw_texture_rect(plate, Rect2(Vector2.ZERO, size), false, Color(0.78, 0.84, 0.95))
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.GROUND, 0.38))
	else:
		Sprites.office(self, size, day_id, clock)
	# vignette: the room falls off at the edges so the play reads in the middle
	for i in 3:
		var k := 1.0 - i * 0.3
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 8 * (i + 1))), Color(0, 0, 0, 0.12 * k))
		draw_rect(Rect2(Vector2(0, size.y - 8 * (i + 1)), Vector2(size.x, 8 * (i + 1))), Color(0, 0, 0, 0.12 * k))
	if run.is_empty():
		return
	# the deploy node's placement: colleagues at their tiles, gear as a lit tile
	for k in placement.get("tiles", {}):
		var it: Dictionary = placement["tiles"][k]
		var tp: Vector2 = BMDeploy.TILES[int(k)]
		draw_circle(tp + Vector2(0, 6), 26.0, Color(Palette.TUBE, 0.10))
		if it["kind"] == "party":
			if not Sprites.actor(self, it["id"], tp + Vector2(0, 14), 44.0, 1.0, Color(1, 1, 1), absf(sin(clock * 3.0)) * 1.5):
				Sprites.colleague(self, tp, clock, it["id"])
		else:
			Sprites.equip_icon(self, it["id"], tp, 30)
	for pk in run["picks"]:
		Sprites.pick(self, pk, clock)
	for pf in puffs:
		var k: float = 1.0 - pf["life"] / 0.32
		draw_arc(pf["p"], pf["r"] * (0.6 + k * 1.6), 0, TAU, 20, Color(1, 1, 1, 0.5 * (1.0 - k)), 2.0)
	# sort by y so nearer things overlap farther ones
	var foes: Array = run["foes"].duplicate()
	foes.sort_custom(func(a, b): return a["y"] < b["y"])
	for f in foes:
		Sprites.foe(self, f, clock)
	if run["boss"] != null:
		var b: Dictionary = run["boss"]
		var boss_id: String = run["day"]["boss"]
		if not Sprites.actor(self, boss_id, Vector2(b["x"], b["y"] + b["r"] * 0.9), b["r"] * 2.6, 1.0,
				Color(1, 1, 1).lerp(Palette.HEAT, b["hit"] * 0.8), absf(sin(clock * 2.0)) * 3.0):
			Sprites.boss(self, b, day_id, clock)
	for s in run["foeShots"]:
		Sprites.foe_shot(self, s, clock)
	var p := Vector2(run["px"], run["py"])
	var party: Array = run["profile"].get("party", [])
	var placed: Dictionary = placement.get("tiles", {})
	var placed_ids: Array = []
	for k in placed:
		placed_ids.append(placed[k]["id"])
	for i in party.size():
		if placed_ids.has(party[i]):
			continue
		var a := clock * 1.6 + i * 2.1
		var cp: Vector2 = p + Vector2(cos(a) * 34, sin(a) * 34)
		if not Sprites.actor(self, party[i], cp + Vector2(0, 14), 44.0, 1.0 if cos(a) < 0 else -1.0, Color(1, 1, 1), absf(sin(clock * 6.0 + i)) * 2.0):
			Sprites.colleague(self, cp, clock, party[i])
	var stats: Dictionary = run["stats"]
	var eq: Dictionary = run["profile"].get("equipped", {})
	if not Sprites.actor(self, "player", p + Vector2(0, 16), 52.0, face, Color(1, 1, 1).lerp(Palette.HEAT, hurt * 0.8), absf(sin(clock * 14.0)) * 2.0 * moving):
		Sprites.player(self, p, clock, moving, face, hurt, eq.get("wear") == "lanyard", eq.get("wear") == "headphones")
	for s in run["shots"]:
		if s["text"] != "":
			Sprites.rant_shot(self, s, display_font)
		else:
			Sprites.shot(self, s)
	for fr in frags:
		var a: float = clampf(fr["life"] / 0.4, 0.0, 1.0)
		draw_set_transform(fr["p"], fr["rot"], Vector2.ONE)
		draw_string_outline(display_font, Vector2(-6, 8), fr["ch"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(Palette.GROUND_DEEP, a))
		draw_string(display_font, Vector2(-6, 8), fr["ch"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(Palette.ACCENT_SOFT, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hurt > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.ACCENT, 0.18 * hurt))
	if stats["flags"].has("slowfoes"):
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.TUBE, 0.04))

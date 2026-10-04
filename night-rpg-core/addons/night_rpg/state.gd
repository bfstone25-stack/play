extends Node
## Autoload "RPG": the game's content (read from res://data/) and the run state (saved).
##
## Content is whatever the game project ships in res://data/game.json + nights/*.json +
## story/*.json; the core knows no game by name. The run state `s` is one plain Dictionary
## so a save is just JSON.

signal changed
signal toast(text: String)

const SAVE_DIR := "user://saves"
const PERSIST := "user://persist.json"
const SLOTS := 6          # slot 0 = autosave

var game: Dictionary = {}
var nights: Dictionary = {}
var story: Dictionary = {}    # "ch1" -> lines array
var menus: Dictionary = {}    # EN menu text -> {"ja": ...}
var s: Dictionary = {}
var persist: Dictionary = {"gallery": [], "lang": "en", "vol_music": 0.7, "vol_sfx": 0.8, "vol_voice": 1.0, "text_speed": 45}
var data_root := "res://data"


var trial_override := false


## Trial build: export feature "trial" (the trial preset), or --trial on the command line.
func is_trial() -> bool:
	return trial_override or OS.has_feature("trial") or "--trial" in OS.get_cmdline_user_args()


func _ready() -> void:
	load_content()
	_load_persist()


func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("night_rpg: cannot read " + path)
		return null
	return JSON.parse_string(f.get_as_text())


func load_content() -> void:
	var g = _read_json(data_root + "/game.json")
	if g == null:
		return
	game = g
	# Optional overlay a game ships in some builds only (Elena: the DLsite store link lives in
	# data/store.json, which the full presets exclude so that build carries no URL at all).
	if FileAccess.file_exists(data_root + "/store.json"):
		var sj = _read_json(data_root + "/store.json")
		if sj is Dictionary:
			game.merge(sj, true)
	for nid in game.get("nights", []):
		# the trial build ships without the later nights; their absence is expected there
		if not FileAccess.file_exists("%s/nights/%s.json" % [data_root, nid]):
			continue
		var n = _read_json("%s/nights/%s.json" % [data_root, nid])
		if n != null:
			nights[nid] = n
	for ch in game.get("story", []):
		if not FileAccess.file_exists("%s/story/%s.json" % [data_root, ch]):
			continue
		var st = _read_json("%s/story/%s.json" % [data_root, ch])
		if st != null:
			story[ch] = st["lines"]
			for en in st.get("menus", {}).keys():
				menus[en] = {"ja": st["menus"][en]}


# ------------------------------------------------------------------ new game / nights

func new_game() -> void:
	s = {
		"version": 1, "night": "", "room": "", "turns_left": 0, "level": 1, "xp": 0,
		"members": {}, "items": {}, "trust": 0, "trusts": {}, "flags": {}, "done": {}, "known": {},
		"play_seconds": 0.0, "pending_levels": 0, "nights_cleared": [], "saved_at": "",
	}
	for m in game["party"]:
		s["members"][m["id"]] = {
			"base": m["base"].duplicate(), "skills": [], "equip": {"outfit": "", "accessory": "", "tool": ""},
			"comp": 0, "nerve": 0,
		}
	for it in game.get("start_items", {}).keys():
		s["items"][it] = int(game["start_items"][it])
	for m in game["party"]:
		for slot in m.get("start_equip", {}).keys():
			s["members"][m["id"]]["equip"][slot] = m["start_equip"][slot]
	restore_party()


func start_night(nid: String) -> void:
	var n: Dictionary = nights[nid]
	s["night"] = nid
	s["room"] = n["start_room"]
	s["turns_left"] = int(n.get("turns", 30))
	s["done"] = {}
	restore_party()
	changed.emit()


func night() -> Dictionary:
	return nights.get(s.get("night", ""), {})


func room() -> Dictionary:
	return night().get("rooms", {}).get(s["room"], {})


func spend_turns(n: int) -> void:
	s["turns_left"] = max(0, int(s["turns_left"]) - n)
	changed.emit()


## Night clock: the turn budget shown as time before dawn.
func clock_text() -> String:
	var n := night()
	var start_min: int = int(n.get("clock_start", 23 * 60 + 40))
	var per: int = int(n.get("minutes_per_turn", 12))
	var used: int = int(n.get("turns", 30)) - int(s["turns_left"])
	var t := (start_min + used * per) % (24 * 60)
	var h := t / 60
	var ap := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, t % 60, ap]


# ------------------------------------------------------------------ party, stats, growth

func member_def(mid: String) -> Dictionary:
	for m in game["party"]:
		if m["id"] == mid:
			return m
	return {}


func stat(mid: String, st: String) -> int:
	var m: Dictionary = s["members"][mid]
	var v := int(m["base"].get(st, 0))
	for slot in m["equip"].keys():
		var it: String = m["equip"][slot]
		if it != "":
			v += int(game["items"].get(it, {}).get("bonus", {}).get(st, 0))
	for sk in m["skills"]:
		v += int(game["skills"].get(sk, {}).get("stat", {}).get(st, 0))
	return v


func comp_max(mid: String) -> int:
	var v := 24 + stat(mid, "grt") * 4 + int(s["level"]) * 3
	for sk in s["members"][mid]["skills"]:
		v += int(game["skills"].get(sk, {}).get("max_comp", 0))
	return v


func nerve_max(mid: String) -> int:
	return 8 + stat(mid, "wit") * 2 + int(s["level"])


func in_party(mid: String) -> bool:
	var jf: String = member_def(mid).get("join_flag", "")
	return jf == "" or flag(jf)


## The heroine: the party member who joins later (has a join_flag); "" in a solo game.
func heroine_id() -> String:
	for m in game["party"]:
		if m.get("join_flag", "") != "":
			return m["id"]
	return ""


## The heroine's sprite: her outfit's own art if it has some, else the default.
func heroine_sprite() -> String:
	for m in game["party"]:
		if m.get("join_flag", "") != "":
			var o: String = s["members"][m["id"]]["equip"].get("outfit", "")
			var sp: String = item_def(o).get("sprite", "") if o != "" else ""
			if sp != "" and NRArt.path("sprites", sp) != "":
				return sp
	return game.get("heroine_sprite", "")


func restore_party() -> void:
	for mid in s["members"].keys():
		s["members"][mid]["comp"] = comp_max(mid)
		s["members"][mid]["nerve"] = nerve_max(mid)


func actions_for(mid: String) -> Array:
	var out: Array = member_def(mid).get("actions", []).duplicate()
	for sk in s["members"][mid]["skills"]:
		var g: String = game["skills"].get(sk, {}).get("grant", "")
		if g != "" and not (g in out):
			out.insert(out.size() - 1, g)
	return out


func action_mult(mid: String) -> Dictionary:
	var out := {}
	var m: Dictionary = s["members"][mid]
	for sk in m["skills"]:
		var am: Dictionary = game["skills"].get(sk, {}).get("mult", {})
		for a in am.keys():
			out[a] = float(out.get(a, 0.0)) + float(am[a])
	for slot in m["equip"].keys():
		var it: String = m["equip"][slot]
		if it != "":
			var im: Dictionary = game["items"].get(it, {}).get("mult", {})
			for a in im.keys():
				out[a] = float(out.get(a, 0.0)) + float(im[a])
	return out


func battle_party() -> Array:
	var out := []
	for m in game["party"]:
		var mid: String = m["id"]
		if not in_party(mid):
			continue
		var stats := {}
		for st in game["stats"]:
			stats[st] = stat(mid, st)
		out.append({"id": mid, "stats": stats, "comp": int(s["members"][mid]["comp"]), "comp_max": comp_max(mid),
			"nerve": int(s["members"][mid]["nerve"]), "nerve_max": nerve_max(mid), "mult": action_mult(mid), "guard": false})
	return out


func absorb_battle(b: Dictionary) -> void:
	for p in b["party"]:
		var m: Dictionary = s["members"][p["id"]]
		# after a standoff the party catches its breath: a third of what was lost comes back
		m["comp"] = min(comp_max(p["id"]), p["comp"] + int((p["comp_max"] - p["comp"]) / 3))
		m["nerve"] = min(nerve_max(p["id"]), p["nerve"] + 4)
	var known: Array = s["known"].get(b["enemy_id"], [])
	for a in b["revealed"]:
		if not (a in known):
			known.append(a)
	s["known"][b["enemy_id"]] = known


func add_xp(n: int) -> int:
	s["xp"] = int(s["xp"]) + n
	var gained := 0
	while int(s["level"]) < int(game.get("level_cap", 20)) and int(s["xp"]) >= NRRules.xp_to_next(int(s["level"])):
		s["xp"] = int(s["xp"]) - NRRules.xp_to_next(int(s["level"]))
		s["level"] = int(s["level"]) + 1
		gained += 1
	if gained > 0:
		s["pending_levels"] = int(s["pending_levels"]) + gained
		restore_party()
	changed.emit()
	return gained


## Skills a member may take now: the next unlearned skill of each branch whose level is met.
func skill_offers(mid: String) -> Array:
	var out := []
	var md := member_def(mid)
	for br in md.get("branches", {}).keys():
		for sk in md["branches"][br]:
			if sk in s["members"][mid]["skills"]:
				continue
			if int(game["skills"][sk].get("req", 1)) <= int(s["level"]):
				out.append(sk)
			break
	return out


func apply_level_choice(mid: String, st: String, sk: String) -> void:
	if st != "":
		s["members"][mid]["base"][st] = int(s["members"][mid]["base"].get(st, 0)) + 1
	if sk != "":
		s["members"][mid]["skills"].append(sk)
	restore_party()
	changed.emit()


# ------------------------------------------------------------------ items, trust, flags

func item_def(id: String) -> Dictionary:
	return game["items"].get(id, {})


func has(id: String) -> bool:
	return int(s["items"].get(id, 0)) > 0


func give(id: String, n: int = 1) -> void:
	s["items"][id] = int(s["items"].get(id, 0)) + n
	changed.emit()


func take(id: String, n: int = 1) -> void:
	s["items"][id] = max(0, int(s["items"].get(id, 0)) - n)
	if int(s["items"][id]) == 0:
		s["items"].erase(id)
	changed.emit()


func kinds() -> Dictionary:
	var out := {}
	for id in s["items"].keys():
		var k: String = item_def(id).get("kind", "")
		out[k] = int(out.get(k, 0)) + int(s["items"][id])
	return out


func first_of_kind(kind: String) -> String:
	for id in s["items"].keys():
		if item_def(id).get("kind", "") == kind:
			return id
	return ""


func equip(mid: String, id: String) -> void:
	var slot: String = item_def(id).get("slot", "")
	if slot == "":
		return
	var cur: String = s["members"][mid]["equip"][slot]
	if cur != "":
		give(cur)
	take(id)
	s["members"][mid]["equip"][slot] = id
	changed.emit()


## Trust: one shared track (s["trust"], the heroine games) or named tracks (s["trusts"][track],
## a game with several people to win over; game.json "trust_tracks" lists them for the HUD).
func trust(track: String = "") -> int:
	if track == "":
		return int(s.get("trust", 0))
	return int(s.get("trusts", {}).get(track, 0))


## The number the summaries show: the shared track, or the highest named one.
func trust_shown() -> int:
	var best := int(s.get("trust", 0))
	for v in s.get("trusts", {}).values():
		best = max(best, int(v))
	return best


func add_trust(n: int, track: String = "") -> void:
	var before := trust(track)
	var after := clampi(before + n, 0, 10)
	if track == "":
		s["trust"] = after
	else:
		if not s.has("trusts"):
			s["trusts"] = {}
		s["trusts"][track] = after
	for th in game.get("trust_thresholds", [3, 5, 7, 9]):
		if before < int(th) and after >= int(th):
			if track != "" and Loc.has("toast_trust_track"):
				toast.emit(Loc.t("toast_trust_track") % [Loc.t("n_" + track), int(th)])
			else:
				toast.emit(Loc.t("toast_trust") % int(th))
	changed.emit()


func flag(f: String) -> bool:
	return bool(s["flags"].get(f, false))


func set_flag(f: String, v: Variant = true) -> void:
	s["flags"][f] = v
	changed.emit()


func unlock_cg(id: String) -> void:
	if not (id in persist["gallery"]):
		persist["gallery"].append(id)
		save_persist()


# ------------------------------------------------------------------ save / load

func save(slot: int) -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	s["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var f := FileAccess.open("%s/slot_%d.json" % [SAVE_DIR, slot], FileAccess.WRITE)
	f.store_string(JSON.stringify(s))


func autosave() -> void:
	save(0)


func load_slot(slot: int) -> bool:
	var p := "%s/slot_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(p):
		return false
	var d = _read_json(p)
	if d == null:
		return false
	s = d
	# JSON numbers come back as floats; the code casts at use sites.
	changed.emit()
	return true


func slot_info(slot: int) -> Dictionary:
	var p := "%s/slot_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(p):
		return {}
	var d = _read_json(p)
	return d if d != null else {}


func _load_persist() -> void:
	if FileAccess.file_exists(PERSIST):
		var d = _read_json(PERSIST)
		if d != null:
			for k in d.keys():
				persist[k] = d[k]


func save_persist() -> void:
	var f := FileAccess.open(PERSIST, FileAccess.WRITE)
	f.store_string(JSON.stringify(persist))


# ------------------------------------------------------------------ story lines

## Lines of a ported VN range, e.g. "ch1:29-48" -> every say line with src in [29, 48].
func story_range(spec: String) -> Array:
	var parts := spec.split(":")
	var lines: Array = story.get(parts[0], [])
	var ab := parts[1].split("-")
	var a := int(ab[0])
	var z := int(ab[1]) if ab.size() > 1 else a
	var out := []
	for ln in lines:
		if int(ln["src"]) >= a and int(ln["src"]) <= z:
			out.append(ln)
	return out

extends Node
## Fortune autoload — the one machine under both instruments (ops/adult_forks/
## cyber_merit_fortune.md §2.5). Merit (MeritCurve, the merit.js port) is the coin; the
## rank ladder with pity is gacha.js's ladder renamed to the real six; a 凶 slip and a
## reversed card go through the same timed conversion on the rack; one collection; one
## free draw a day per account; the four mocked SKUs. State persists in user://fortune.json.
##
## Time: every rule that reads the clock goes through now_ms(), so the tests and the web
## dev bridge can move it (clock_offset_ms) without waiting twenty real minutes.

signal changed
signal toast(text: String)

const SAVE_PATH := "user://fortune.json"
const RANKS := ["daji", "zhongji", "xiaoji", "moji", "xiong", "daxiong"]
const WEIGHTS := {"daji": 3, "zhongji": 12, "xiaoji": 25, "moji": 30, "xiong": 22, "daxiong": 8}
const PITY := 10                      # gacha.js: the 10th pull without a high rank forces one
const SUBJECTS := ["work", "money", "love", "body", "study", "traveler"]
const POSITIONS := ["past", "present", "helps", "blocks"]
const TUBE := 100                     # merit per draw — "the tube holds 100 at level 1"
const BURN := {"daji": 60, "zhongji": 40, "xiaoji": 25, "moji": 15, "xiong": 10, "daxiong": 10}
const RESOLVE_COST := {"xiong": 40, "daxiong": 80}
const RESOLVE_MS := {"xiong": 20 * 60 * 1000, "daxiong": 60 * 60 * 1000}
const RACK_SLOTS := 3
## rank -> which card tiers, and which way up. Every one of the 156 is reachable.
const RANK_TIERS := {
	"daji": {"tiers": ["bright"], "reversed": false},
	"zhongji": {"tiers": ["major", "court"], "reversed": false},
	"xiaoji": {"tiers": ["pip"], "reversed": false},
	"moji": {"tiers": ["hard"], "reversed": false},
	"xiong": {"tiers": ["pip", "court"], "reversed": true},
	"daxiong": {"tiers": ["major", "bright", "hard"], "reversed": true},
}
const SKUS := {
	"merit_s": {"price": "$0.99", "merit": 100},
	"merit_m": {"price": "$3.99", "merit": 600},
	"merit_l": {"price": "$9.99", "merit": 2000},
	"extra_draw": {"price": "$0.99"},
	"resolve_now": {"price": "$0.99"},
	"rack_slot": {"price": "$1.99"},
}

var merit := MeritCurve.new()
var slips: Array = []
var cards: Array = []
var reader: Dictionary = {}
var rng := RandomNumberGenerator.new()
var persist_enabled := true
var clock_offset_ms: int = 0

# ladder
var pity: int = 0
var pulls: int = 0
# daily
var free_day := ""                    # day key of the last free draw
var extra_draws: int = 0
var streak: int = 0
var last_day := ""
# rack / collection
var rack: Array = []                  # [{kind, id, rank, at, ready_at}]
var rack_slots: int = RACK_SLOTS
var resolved_bonus: int = 0           # +1 merit per tap per resolved 凶
var have_slips: Dictionary = {}       # id -> count
var have_cards: Dictionary = {}       # "slug:up"|"slug:rev" -> count
var purchases: Array = []
var pending: Dictionary = {}          # the drawn, unread result
var seen_reader_note := false
var seen_board_today := ""
var reader_plays: int = 0

var _slips_by: Dictionary = {}
var _cards_by_tier: Dictionary = {}
var _cards_by_slug: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	slips = Tx._load_json("res://pool/slips.json")
	cards = Tx._load_json("res://pool/tarot.json")
	reader = Tx._load_json("res://pool/reader.json")
	for s in slips:
		var k: String = s["rank"] + "/" + s["subject"]
		if not _slips_by.has(k):
			_slips_by[k] = []
		_slips_by[k].append(s)
	for c in cards:
		if not _cards_by_tier.has(c["tier"]):
			_cards_by_tier[c["tier"]] = []
		_cards_by_tier[c["tier"]].append(c)
		_cards_by_slug[c["slug"]] = c
	load_state()
	_touch_day()


# ---- time --------------------------------------------------------------------------------
func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) + clock_offset_ms


func day_key(ms: int = -1) -> String:
	if ms < 0:
		ms = now_ms()
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	return Time.get_date_string_from_unix_time(int(ms / 1000) + bias * 60)


func _touch_day() -> void:
	var d := day_key()
	if d == last_day:
		return
	if last_day != "":
		var yesterday := day_key(now_ms() - 86400000)
		streak = streak + 1 if last_day == yesterday else 1
	else:
		streak = 1
	last_day = d
	save_state()


func free_available() -> bool:
	return free_day != day_key() or extra_draws > 0


# ---- merit -------------------------------------------------------------------------------
## One tap of the fish: the merit.js gain plus the rack's permanent bonus.
func tap() -> int:
	var g := merit.click()
	if resolved_bonus > 0:
		merit.merit += resolved_bonus
		g += resolved_bonus
	changed.emit()
	return g


func tick(dt: float) -> int:
	var g := merit.tick(dt)
	if g > 0:
		changed.emit()
	return g


func upgrade() -> bool:
	var ok := merit.try_upgrade()
	if ok:
		save_state()
		changed.emit()
	return ok


func fill() -> float:
	return clampf(float(merit.merit) / TUBE, 0.0, 1.0)


func can_draw() -> bool:
	return pending.is_empty() and (free_available() or merit.merit >= TUBE)


# ---- the ladder ----------------------------------------------------------------------------
## gacha.js rollRarity(): weighted roll, or the pity force — the 10th draw without a
## 中吉-or-better lands 中吉 (大吉 on a 30-multiple), then the counter resets.
func roll_rank() -> String:
	pity += 1
	pulls += 1
	var force := pity >= PITY
	var rank: String
	if force:
		rank = "daji" if (pity % 30 == 0 and pity > 0) else "zhongji"
	else:
		var n := rng.randf()
		var total := 0
		for r in RANKS:
			total += WEIGHTS[r]
		var acc := 0.0
		rank = "moji"
		for r in RANKS:
			acc += float(WEIGHTS[r]) / total
			if n < acc:
				rank = r
				break
	if rank == "daji" or rank == "zhongji" or force:
		pity = 0
	return rank


## Which spoken line a finished draw deserves. One place, because the tube and the deck
## must not drift into two different opinions of what counts as a good day.
func bark_slot(r: Dictionary) -> String:
	var rank := str(r.get("rank", ""))
	if rank == "daji":
		return "win_big"
	if is_ill(rank):
		return "fail"
	if good_streak >= 3 and good_streak % 3 == 0:
		return "streak"
	return "win"


## Consecutive draws this session that were not 凶 / 大凶. Not saved; see draw().
var good_streak := 0


func is_ill(rank: String) -> bool:
	return rank == "xiong" or rank == "daxiong"


## Draw with the instrument. Spends the free draw first, then 100 merit. Returns the
## result (also held in `pending` until keep / burn / resolve) or {} when it cannot.
func draw(instrument: String, subject: String = "") -> Dictionary:
	if not pending.is_empty():
		return {}
	var free := false
	if free_day != day_key():
		free_day = day_key()
		free = true
	elif extra_draws > 0:
		extra_draws -= 1
		free = true
	elif merit.merit >= TUBE:
		merit.merit -= TUBE
	else:
		return {}
	var rank := roll_rank()
	# Session-only, deliberately: "three good readings" is something that happens while you
	# are sitting with the machine. Reloading tomorrow and being told you are on a streak
	# from last week would be the machine flattering you, and the first line in the shop
	# is that a paid draw is never a luckier draw.
	good_streak = 0 if is_ill(rank) else good_streak + 1
	var r := {"kind": instrument, "rank": rank, "free": free, "at": now_ms()}
	if instrument == "slip":
		if not (subject in SUBJECTS):
			subject = SUBJECTS[rng.randi() % SUBJECTS.size()]
		var bag: Array = _slips_by.get(rank + "/" + subject, slips)
		var s: Dictionary = bag[rng.randi() % bag.size()]
		r["subject"] = subject
		r["id"] = s["id"]
	else:
		var spec: Dictionary = RANK_TIERS[rank]
		var bag := []
		for t in spec["tiers"]:
			bag.append_array(_cards_by_tier.get(t, []))
		var c: Dictionary = bag[rng.randi() % bag.size()]
		r["id"] = c["slug"]
		r["reversed"] = spec["reversed"]
		r["position"] = POSITIONS[rng.randi() % POSITIONS.size()]
	pending = r
	save_state()
	changed.emit()
	return r


func slip(id: String) -> Dictionary:
	for s in slips:
		if s["id"] == id:
			return s
	return {}


func card(slug: String) -> Dictionary:
	return _cards_by_slug.get(slug, {})


func _collect(r: Dictionary) -> void:
	if r["kind"] == "slip":
		have_slips[r["id"]] = int(have_slips.get(r["id"], 0)) + 1
	else:
		var k: String = r["id"] + (":rev" if r.get("reversed", false) else ":up")
		have_cards[k] = int(have_cards.get(k, 0)) + 1


func keep() -> bool:
	if pending.is_empty():
		return false
	_collect(pending)
	pending = {}
	save_state()
	changed.emit()
	toast.emit(Tx.t("kept.toast"))
	return true


func burn() -> int:
	if pending.is_empty():
		return 0
	var back: int = BURN[pending["rank"]]
	merit.merit += back
	pending = {}
	save_state()
	changed.emit()
	toast.emit(Tx.t("burned.toast", {"n": back}))
	return back


## 化解 / integration: spend merit, tie the ill result to the rack; after RESOLVE_MS it is
## claimable, and claiming adds one permanent merit per tap. Same rule for both halves.
func resolve() -> bool:
	if pending.is_empty() or not is_ill(pending["rank"]):
		return false
	if rack.size() >= rack_slots:
		toast.emit(Tx.t("rack.full"))
		return false
	var cost: int = RESOLVE_COST[pending["rank"]]
	if merit.merit < cost:
		return false
	merit.merit -= cost
	var e := {"kind": pending["kind"], "id": pending["id"], "rank": pending["rank"],
		"reversed": pending.get("reversed", false), "at": now_ms(), "ready_at": now_ms() + int(RESOLVE_MS[pending["rank"]])}
	rack.append(e)
	pending = {}
	save_state()
	changed.emit()
	return true


func rack_ready(i: int) -> bool:
	return i >= 0 and i < rack.size() and now_ms() >= int(rack[i]["ready_at"])


func rack_remaining_ms(i: int) -> int:
	return maxi(0, int(rack[i]["ready_at"]) - now_ms())


func claim(i: int) -> bool:
	if not rack_ready(i):
		return false
	var e: Dictionary = rack[i]
	rack.remove_at(i)
	resolved_bonus += 1
	_collect(e)
	save_state()
	changed.emit()
	toast.emit(Tx.t("resolved.toast"))
	return true


func collection_counts() -> Dictionary:
	return {"slips": have_slips.size(), "slips_all": slips.size(),
		"cards": have_cards.size(), "cards_all": cards.size() * 2}


# ---- the shop: mocked, grants at once, never touches the ladder --------------------------
func buy(sku: String) -> bool:
	if not SKUS.has(sku):
		return false
	match sku:
		"merit_s", "merit_m", "merit_l":
			merit.merit += int(SKUS[sku]["merit"])
		"extra_draw":
			extra_draws += 1
		"resolve_now":
			if rack.is_empty():
				return false
			var oldest := 0
			for i in range(rack.size()):
				if int(rack[i]["at"]) < int(rack[oldest]["at"]):
					oldest = i
			rack[oldest]["ready_at"] = now_ms()
		"rack_slot":
			rack_slots += 1
	purchases.append({"sku": sku, "at": now_ms(), "mock": true})
	save_state()
	changed.emit()
	return true


# ---- persistence ---------------------------------------------------------------------------
func snapshot() -> Dictionary:
	return {"schema": 1, "merit": merit.snapshot(), "pity": pity, "pulls": pulls,
		"free_day": free_day, "extra_draws": extra_draws, "streak": streak, "last_day": last_day,
		"rack": rack, "rack_slots": rack_slots, "resolved_bonus": resolved_bonus,
		"have_slips": have_slips, "have_cards": have_cards, "purchases": purchases,
		"pending": pending, "seen_reader_note": seen_reader_note, "lang": Tx.lang,
		"reader_plays": reader_plays}


func load_from(d: Dictionary) -> void:
	merit.load(d.get("merit"))
	pity = int(d.get("pity", 0))
	pulls = int(d.get("pulls", 0))
	free_day = str(d.get("free_day", ""))
	extra_draws = int(d.get("extra_draws", 0))
	streak = int(d.get("streak", 0))
	last_day = str(d.get("last_day", ""))
	rack = d.get("rack", [])
	rack_slots = maxi(RACK_SLOTS, int(d.get("rack_slots", RACK_SLOTS)))
	resolved_bonus = int(d.get("resolved_bonus", 0))
	have_slips = d.get("have_slips", {})
	have_cards = d.get("have_cards", {})
	purchases = d.get("purchases", [])
	pending = d.get("pending", {})
	seen_reader_note = bool(d.get("seen_reader_note", false))
	reader_plays = int(d.get("reader_plays", 0))
	if d.has("lang"):
		Tx.set_lang(str(d["lang"]))


func load_state() -> void:
	if not persist_enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) == TYPE_DICTIONARY:
		load_from(v)


func save_state() -> void:
	if not persist_enabled:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(snapshot()))


func reset() -> void:
	merit = MeritCurve.new()
	pity = 0
	pulls = 0
	free_day = ""
	extra_draws = 0
	streak = 0
	last_day = ""
	rack = []
	rack_slots = RACK_SLOTS
	resolved_bonus = 0
	have_slips = {}
	have_cards = {}
	purchases = []
	pending = {}
	seen_reader_note = false
	reader_plays = 0
	clock_offset_ms = 0
	save_state()
	changed.emit()


# ---- web dev bridge -------------------------------------------------------------------------
## The headless run pushes JSON commands onto window.__cf_cmd and reads window.__cf_state.
## Every command is something a player can also do with a click; `advance` moves the
## clock, which a player does by waiting.
var bridge_handler: Callable


func _process(_dt: float) -> void:
	_poll_bridge()


func _poll_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("(function(){var q=window.__cf_cmd||[];if(!q.length)return '';var c=q.shift();return JSON.stringify(c);})()")
	if raw == null or str(raw) == "":
		return
	var cmd = JSON.parse_string(str(raw))
	if typeof(cmd) != TYPE_DICTIONARY:
		return
	var out := {"ok": true}
	match str(cmd.get("op", "")):
		"state":
			pass
		"reset":
			reset()
		"advance":
			clock_offset_ms += int(cmd.get("ms", 0))
			changed.emit()
		"merit":
			merit.merit = int(cmd.get("n", 0))
			changed.emit()
		"tap":
			for _i in range(int(cmd.get("n", 1))):
				tap()
		"draw":
			out["result"] = draw(str(cmd.get("kind", "slip")), str(cmd.get("subject", "")))
		"keep", "burn", "resolve":
			# through the open read panel when there is one (the player's click), else direct
			var h = bridge_handler.call({"op": "read", "choice": str(cmd["op"])}) if bridge_handler.is_valid() else {}
			if typeof(h) == TYPE_DICTIONARY and h.get("handled", false):
				out = h
			else:
				match str(cmd["op"]):
					"keep": out["ok"] = keep()
					"burn": out["back"] = burn()
					"resolve": out["ok"] = resolve()
		"claim":
			out["ok"] = claim(int(cmd.get("i", 0)))
		"buy":
			out["ok"] = buy(str(cmd.get("sku", "")))
		"lang":
			Tx.set_lang(str(cmd.get("lang", "en")))
			save_state()
		_:
			if bridge_handler.is_valid():
				out = bridge_handler.call(cmd)
			else:
				out = {"ok": false, "why": "no_handler"}
	out["seq"] = cmd.get("seq", 0)
	JavaScriptBridge.eval("window.__cf_result=%s;window.__cf_state=%s" % [JSON.stringify(out), JSON.stringify(dev_state())])


func dev_state() -> Dictionary:
	var s := snapshot()
	s["free_available"] = free_available()
	s["day"] = day_key()
	s["counts"] = collection_counts()
	s["rack_ready"] = []
	for i in range(rack.size()):
		s["rack_ready"].append(rack_ready(i))
	if bridge_handler.is_valid():
		var ui = bridge_handler.call({"op": "ui_state"})
		if typeof(ui) == TYPE_DICTIONARY:
			s.merge(ui, true)
	return s

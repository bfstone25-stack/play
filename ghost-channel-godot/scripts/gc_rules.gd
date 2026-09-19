## GCRules — the prototype's game.js, ported line for line: the codebook, the request
## planner, the tells, the three verdicts, the naming, the clock. Pure: everything lives
## in the state Dictionary `s`, every random draw goes through `s.rng` (a Callable
## returning [0,1), fed in the same order as the JS called Math.random), and nothing here
## touches a node. The scenes render `s.panel` / `s.hud` / `s.log` and call the verbs.
##
## The view-model (`panel`, `hud`, `roster_rows`, `end`) is part of the port on purpose:
## tests/run_tests.gd replays 300 seeded games recorded from the real game.js under a stub
## DOM (tests/conformance_gen.cjs) and asserts what the player would have seen — the
## incoming panel, the HUD, the log, the roster lines, the debrief — is identical.
class_name GCRules

const AGENTS := [
	{"id": "viper", "name": "VIPER", "color": "#2df0f0", "freq": 220, "grid0": [2, 2], "face": "scar"},
	{"id": "moth", "name": "MOTH", "color": "#ff3dad", "freq": 178, "grid0": [6, 1], "face": "moth"},
	{"id": "hex", "name": "HEX", "color": "#f5d031", "freq": 256, "grid0": [4, 5], "face": "glasses"},
	{"id": "raven", "name": "RAVEN", "color": "#7cff6b", "freq": 146, "grid0": [1, 6], "face": "raven"},
	{"id": "quill", "name": "QUILL", "color": "#ff8a3d", "freq": 198, "grid0": [7, 6], "face": "youth"},
]
const COLORS := ["BLUE", "IVORY", "ASH", "VIOLET", "COPPER"]
const WORDS := ["IVY", "HARBOR", "NEEDLE", "GLASS", "CINDER", "FENCE"]
const OPS := [
	{"id": 1, "requests": 7, "time": 150, "mapSpoof": false, "captured": false, "poison": false, "unlock": 0},
	{"id": 2, "requests": 9, "time": 165, "mapSpoof": false, "captured": true, "poison": false, "unlock": 1},
	{"id": 3, "requests": 10, "time": 180, "mapSpoof": true, "captured": false, "poison": true, "unlock": 2},
]
const TYPES := ["fire", "extract", "resupply", "move", "codebook", "accuse"]


# ---- the JS helpers ---------------------------------------------------------------------
static func pick(s: Dictionary, arr: Array):
	return arr[int(s.rng.call() * arr.size())]


static func grid_label(g: Array) -> String:
	return String.chr(65 + int(g[0])) + str(int(g[1]) + 1)


static func new_book(s: Dictionary) -> Dictionary:
	var color = pick(s, COLORS)
	var num := 2 + int(s.rng.call() * 7)
	var word = pick(s, WORDS)
	return {"color": color, "num": num, "word": word}


static func book_text(b: Dictionary) -> String:
	return "%s-%d-%s" % [b.color, int(b.num), b.word]


static func t(s: Dictionary, key: String, vars: Dictionary = {}) -> String:
	return GCStrings.t(s.lang, key, vars)


static func who(s: Dictionary, a: Dictionary) -> String:
	return str(GCStrings.agent(s.lang, a.id).local)


static func agent_by_id(s: Dictionary, id: String) -> Dictionary:
	for a in s.agents:
		if a.id == id:
			return a
	return {}


static func add_log(s: Dictionary, text: String, cls: String = "") -> void:
	s.log.push_front([cls, text])


static func tel(s: Dictionary, name: String, value: Dictionary) -> void:
	s.events.append({"name": name, "value": value})
	if s.has("on_tel") and s.on_tel is Callable and s.on_tel.is_valid():
		s.on_tel.call(name, value)


# ---- a run --------------------------------------------------------------------------------
## `rng` is the seeded stream; `lang` "en" | "zh"; `wins` the save's win count (telemetry
## only); `best` the save's per-op best (the debrief's BEST line).
static func start_op(op: Dictionary, rng: Callable, lang: String = "en", wins: int = 0, best: Dictionary = {}) -> Dictionary:
	var s := {"rng": rng, "lang": lang, "wins": wins, "best": best, "log": [], "events": []}
	var yesterday := new_book(s)
	var today := new_book(s)
	while today.word == yesterday.word and today.color == yesterday.color:
		today = new_book(s)
	var mimic: Dictionary = pick(s, AGENTS)
	var captured = null
	if op.captured:
		var others := AGENTS.filter(func(a): return a.id != mimic.id)
		captured = pick(s, others)
	s.merge({
		"op": op, "mimicId": mimic.id, "capturedId": captured.id if captured != null else null,
		"book": today, "yesterday": yesterday, "poisoned": false,
		"agents": [], "pending": [], "request": null, "awaitingName": false,
		"time": int(op.time), "ff": 0, "score": 0, "done": 0,
		"stats": {"auth": 0, "deny": 0, "q": 0, "correct": 0, "wrong": 0},
		"phase": "play", "ended": false, "win": false, "reason": "", "lead": "",
		"lead_key": "", "lead_vars": {},
		"panel": {"who": "", "type": "", "body": "", "extra": "", "locked": false, "naming": false, "name_btns": []},
		"hud": {"time": "", "ff": "", "score": ""},
		"codebook": "", "note": "", "end": null,
	})
	for a in AGENTS:
		var d: Dictionary = a.duplicate()
		d.merge(GCStrings.agent(lang, a.id), true)
		d.grid = [a.grid0[0], a.grid0[1]]
		d.alive = true
		d.wounded = false
		d.suspect = false
		d.lastPhrase = ""
		s.agents.append(d)
	s.pending = plan_requests(s)
	s.opName = str(GCStrings.op_meta(lang, int(op.id) - 1).name)
	s.codebook = book_text(s.book)
	s.note = t(s, "yestNote", {"book": book_text(s.yesterday)})
	set_naming_mode(s, false)
	add_log(s, t(s, "netOpen", {"book": book_text(s.book)}), "sys")
	if s.capturedId != null:
		add_log(s, t(s, "intelCap", {"who": who(s, agent_by_id(s, s.capturedId))}), "sys")
	tel(s, "play", {"op": op.id, "returning": wins > 0, "prior_wins": wins})
	next_request(s)
	update_hud(s)   # startTicker() paints the HUD once
	return s


static func plan_requests(s: Dictionary) -> Array:
	var queue := []
	var ids: Array = s.agents.map(func(a): return a.id)
	var friendlies: Array = ids.filter(func(id): return id != s.mimicId)
	queue.append({"speaker": friendlies[0], "type": "resupply", "forceClean": true})
	queue.append({"speaker": friendlies[1 % friendlies.size()], "type": "move", "forceClean": true})
	var rest: int = int(s.op.requests) - 2
	var mimic_left := 2 + (1 if int(s.op.id) > 1 else 0)
	for i in range(rest):
		var use_mimic := false
		if mimic_left > 0:
			use_mimic = (i == rest - 1) or (s.rng.call() < 0.38)
		var speaker = s.mimicId if use_mimic else pick(s, friendlies)
		if use_mimic:
			mimic_left -= 1
		queue.append({"speaker": speaker, "type": pick(s, TYPES), "forceClean": false})
	return queue


static func occupied_grids(s: Dictionary) -> Array:
	var out := []
	for a in s.agents:
		if a.alive:
			out.append(a.grid)
	return out


static func empty_grid(s: Dictionary) -> Array:
	for _n in range(40):
		var g := [int(s.rng.call() * 8), int(s.rng.call() * 8)]
		var taken := false
		for o in occupied_grids(s):
			if int(o[0]) == g[0] and int(o[1]) == g[1]:
				taken = true
				break
		if not taken:
			return g
	return [0, 0]


static func build_request(s: Dictionary, spec: Dictionary) -> Dictionary:
	var speaker := agent_by_id(s, spec.speaker)
	var is_mimic: bool = speaker.id == s.mimicId
	var is_captured: bool = s.capturedId != null and speaker.id == s.capturedId
	var type: String = spec.type
	var req := {
		"speaker": speaker.id, "type": type, "isMimic": is_mimic, "isCaptured": is_captured,
		"tells": [], "target": null, "targetId": null, "targetName": "",
		"auth": book_text(s.book), "phrase": "", "extra": "",
	}
	if type == "fire":
		if is_mimic and not spec.forceClean:
			var victim: Dictionary = pick(s, s.agents.filter(func(a): return a.id != speaker.id and a.alive))
			req.target = [victim.grid[0], victim.grid[1]]
			req.tells.append("friendly-fire")
		else:
			req.target = empty_grid(s)
	if type == "move":
		req.target = empty_grid(s)
	if type == "accuse":
		var tgt: Dictionary = pick(s, s.agents.filter(func(a): return a.id != speaker.id))
		req.targetId = tgt.id
		req.targetName = who(s, tgt)
	if (is_mimic or (is_captured and not spec.forceClean)) and not spec.forceClean:
		var pool := ["auth", "tic", "oldbook"]
		if type == "fire":
			pool.append("friendly-fire")
		if s.op.mapSpoof:
			pool.append("ghost-plot")
		var tell: String = pick(s, pool)
		if not req.tells.has(tell):
			req.tells.append(tell)
		if tell == "auth":
			req.auth = book_text(s.yesterday)
		if tell == "oldbook":
			req.auth = book_text(s.yesterday)
	if is_mimic and type == "codebook" and not spec.forceClean:
		req.tells.append("poison")
	req.phrase = write_line(s, req, speaker)
	if req.tells.has("tic"):
		var other: Dictionary = pick(s, s.agents.filter(func(a): return a.id != speaker.id))
		req.phrase += " ……" + str(GCStrings.agent(s.lang, other.id).tic) + "."
		req.extra = t(s, "borrowedTic")
	speaker.lastPhrase = req.phrase
	return req


static func write_line(s: Dictionary, req: Dictionary, speaker: Dictionary) -> String:
	var auth := t(s, "authWord", {"book": req.auth})
	var pool := GCStrings.lines(s.lang, req.type)
	var line: String = pick(s, pool)
	line = line.replace("{auth}", auth).replace("{who}", who(s, speaker))
	line = line.replace("{grid}", grid_label(req.target) if req.target != null else "")
	line = line.replace("{target}", str(req.targetName) if req.targetName else "")
	return line


static func next_request(s: Dictionary) -> void:
	if s.ended:
		return
	if s.pending.is_empty():
		begin_naming(s)
		return
	var spec: Dictionary = s.pending.pop_front()
	s.request = build_request(s, spec)
	s.done += 1
	var a := agent_by_id(s, s.request.speaker)
	var p: Dictionary = s.panel
	p.locked = false
	p.who = who(s, a) + " · " + str(a.name) + " · " + grid_label(a.grid)
	p.type = GCStrings.type_name(s.lang, s.request.type) + " · " + str(s.done) + "/" + str(int(s.op.requests))
	p.body = s.request.phrase
	var ag := GCStrings.agent(s.lang, a.id)
	p.extra = str(ag.role) + "  ·  「" + str(ag.quote) + "」"
	add_log(s, who(s, a) + " — " + s.request.phrase)


## Returns true when the answer failed — the scene needs to know which cue to play, and
## deriving that by matching the panel's sentence back against a translated template (which
## this did at first) is the kind of check that works until someone edits a string.
static func interrogate(s: Dictionary) -> bool:
	if s.request == null or s.ended:
		return false
	s.stats.q += 1
	s.time = maxi(0, s.time - 8)
	var req: Dictionary = s.request
	var a := agent_by_id(s, req.speaker)
	var fail: bool = req.isMimic
	if not fail and req.isCaptured:
		fail = s.rng.call() < 0.7
	tel(s, "q", {"op": s.op.id, "mimic": req.isMimic, "captured": req.isCaptured, "fail": fail, "type": req.type})
	if fail:
		var fake := book_text(s.yesterday)
		s.panel.extra = t(s, "qFail", {"who": who(s, a), "fake": fake})
		add_log(s, t(s, "qFailLog", {"who": who(s, a)}), "bad")
	else:
		s.panel.extra = t(s, "qPass", {"who": who(s, a), "book": book_text(s.book), "grid": grid_label(a.grid)})
		add_log(s, t(s, "qPassLog", {"who": who(s, a)}), "sys")
	return fail


## The verdict. Returns what the scene needs to react to: {"cue": ..., "next": bool}
## — `next` false means the op ended here; true means call next_request() after the
## prototype's 650 ms beat.
static func resolve(s: Dictionary, choice: String) -> Dictionary:
	if s.request == null or s.ended:
		return {"cue": "", "next": false}
	var req: Dictionary = s.request
	var a := agent_by_id(s, req.speaker)
	s.panel.locked = true
	var tells: Array = req.tells.slice(0, 6)
	tel(s, "radio", {"op": s.op.id, "choice": choice, "type": req.type, "mimic": req.isMimic, "captured": req.isCaptured, "tells": tells})
	var cue := ""
	if choice == "auth":
		s.stats.auth += 1
		cue = "auth"
		if req.tells.has("friendly-fire") and req.isMimic:
			var hit = null
			for x in s.agents:
				if x.alive and int(x.grid[0]) == int(req.target[0]) and int(x.grid[1]) == int(req.target[1]):
					hit = x
					break
			if hit != null:
				hit.alive = false
				s.ff += 1
				s.stats.wrong += 1
				s.score -= 150
				add_log(s, t(s, "ffLog", {"who": who(s, hit)}), "bad")
				cue = "warn"
		elif req.type == "codebook" and req.isMimic:
			s.poisoned = true
			var fake := new_book(s)
			s.yesterday = s.book
			s.book = fake
			s.codebook = book_text(s.book)
			s.note = t(s, "bookPoisonNote")
			s.stats.wrong += 1
			s.score -= 80
			add_log(s, t(s, "bookPoisonLog", {"who": who(s, a)}), "bad")
		elif req.type == "extract" and req.isMimic:
			s.stats.wrong += 1
			s.score -= 120
			add_log(s, t(s, "extractGhostLog"), "bad")
			end_op(s, false, "extractGhostEnd", {}, "extract")
			return {"cue": "warn", "next": false}
		elif req.type == "accuse" and not req.isMimic:
			var named := agent_by_id(s, str(req.targetId))
			if not named.is_empty() and named.id != s.mimicId:
				named.wounded = true
				s.score -= 40
				add_log(s, t(s, "falseAccuse", {"who": who(s, named)}), "bad")
			else:
				s.stats.correct += 1
				s.score += 90
				add_log(s, t(s, "accuseOk"), "sys")
		elif req.isMimic and not req.tells.is_empty():
			s.stats.wrong += 1
			s.score -= 40
			add_log(s, t(s, "authItch", {"who": who(s, a)}), "bad")
		else:
			if req.type == "move":
				a.grid = req.target
			s.stats.correct += 1
			s.score += 40
			add_log(s, t(s, "authOk", {"who": who(s, a)}), "sys")
	else:
		s.stats.deny += 1
		cue = "deny"
		if req.isMimic:
			s.stats.correct += 1
			s.score += 110
			add_log(s, t(s, "denyGhost", {"who": who(s, a)}), "sys")
		elif req.type == "extract":
			a.wounded = true
			s.stats.wrong += 1
			s.score -= 60
			add_log(s, t(s, "denyExtract", {"who": who(s, a)}), "bad")
		else:
			s.score -= 10
			add_log(s, t(s, "denySoft", {"who": who(s, a)}), "sys")
	update_hud(s)
	if s.ff >= 2:
		end_op(s, false, "twoFF", {}, "ff")
		return {"cue": cue, "next": false}
	return {"cue": cue, "next": true}


static func set_naming_mode(s: Dictionary, on: bool) -> void:
	s.panel.naming = on
	s.panel.name_btns = []
	if not on:
		return
	for i in range(s.agents.size()):
		var a: Dictionary = s.agents[i]
		s.panel.name_btns.append([t(s, "nameBtn", {"n": i + 1, "who": who(s, a)}), not a.alive])


static func begin_naming(s: Dictionary) -> void:
	s.awaitingName = true
	s.request = null
	s.time = maxi(s.time, 25)
	var p: Dictionary = s.panel
	p.locked = false
	p.who = t(s, "nameGhost")
	p.type = t(s, "finalCall")
	p.body = t(s, "nameBody")
	p.extra = t(s, "nameExtra")
	add_log(s, t(s, "nameLog"), "sys")
	set_naming_mode(s, true)
	tel(s, "naming", {"op": s.op.id, "score": s.score, "auth": s.stats.auth, "deny": s.stats.deny, "q": s.stats.q, "ff": s.ff})


## Name the ghost. Returns true when the accusation was accepted (win or lose).
static func accuse(s: Dictionary, id: String) -> bool:
	if not s.awaitingName or s.ended:
		return false
	var ghost := agent_by_id(s, s.mimicId)
	var picked := agent_by_id(s, id)
	if id == s.mimicId:
		s.score += 200
		s.wins += 1
		end_op(s, true, "winLead", {"who": who(s, ghost)}, "named-ok")
	else:
		end_op(s, false, "loseLead", {"who": who(s, picked), "ghost": who(s, ghost)}, "named-wrong")
	return true


## The op is over. `lead_key` / `lead_vars` are the string rather than the finished
## sentence, so `rebuild_end()` can set the whole debrief again in the other language when
## the player switches after the run — the sentence produced is identical either way, which
## is what tests/run_tests.gd checks against the prototype's recorded games.
static func end_op(s: Dictionary, win: bool, lead_key: String, lead_vars: Dictionary, reason: String) -> void:
	if s.ended:
		return
	s.ended = true
	s.win = win
	s.reason = reason
	s.lead_key = lead_key
	s.lead_vars = lead_vars
	var key := "op" + str(int(s.op.id))
	if win:
		s.best[key] = maxi(int(s.best.get(key, 0)), s.score)
	rebuild_end(s)
	set_naming_mode(s, false)
	tel(s, "win" if win else "lose", {
		"op": s.op.id, "reason": reason, "score": s.score,
		"auth": s.stats.auth, "deny": s.stats.deny, "q": s.stats.q,
		"correct": s.stats.correct, "wrong": s.stats.wrong, "ff": s.ff, "remaining": int(s.time),
	})


## Re-derive the debrief's strings in the current language. Called by end_op, and again by
## relocalise() when the player switches language on the debrief screen.
static func rebuild_end(s: Dictionary) -> void:
	if not s.ended:
		return
	var key := "op" + str(int(s.op.id))
	s.lead = t(s, str(s.lead_key), s.lead_vars)
	s.end = {
		"title": t(s, "winTitle") if s.win else t(s, "loseTitle"),
		"lead": s.lead,
		"stats": [
			[t(s, "statScore"), str(s.score)], [t(s, "statAuth"), str(s.stats.auth)],
			[t(s, "statDeny"), str(s.stats.deny)], [t(s, "statQ"), str(s.stats.q)],
			[t(s, "statFF"), str(s.ff)], [t(s, "statBest"), str(int(s.best.get(key, 0)))],
		],
	}


## One second of the op clock (the prototype's setInterval ticker).
static func tick(s: Dictionary) -> void:
	if s.ended:
		return
	s.time -= 1
	update_hud(s)
	if s.time <= 0:
		end_op(s, false, "clockZero", {}, "timeout")


static func update_hud(s: Dictionary) -> void:
	s.hud.time = str(maxi(0, int(s.time))).pad_zeros(2)
	s.hud.ff = str(s.ff)
	s.hud.score = str(s.score)


## The roster lines as the prototype rendered them: [class, "who · NAME", "role · grid"].
static func roster_rows(s: Dictionary) -> Array:
	var out := []
	for a in s.agents:
		var cls := "agent" + (" suspect" if a.suspect else "") + ("" if a.alive else " dead")
		var ag := GCStrings.agent(s.lang, a.id)
		var st := str(ag.role) + " · " + (grid_label(a.grid) if a.alive else t(s, "kia"))
		if a.wounded:
			st += " · " + t(s, "wounded")
		if a.suspect:
			st += " · " + t(s, "pinned")
		out.append([cls, who(s, a) + " · " + str(a.name), st])
	return out


## Re-localise a live run after a language switch (the prototype's GCOnLang).
static func relocalise(s: Dictionary, lang: String) -> void:
	s.lang = lang
	for a in s.agents:
		a.merge(GCStrings.agent(lang, a.id), true)
	s.opName = str(GCStrings.op_meta(lang, int(s.op.id) - 1).name)
	if s.awaitingName and not s.ended:
		set_naming_mode(s, true)
	if s.ended:
		rebuild_end(s)


## Is op `i` (0-based) locked by progress? The prototype: locked when the save has fewer
## wins than the op asks for and the previous op has no best score.
static func op_locked(i: int, wins: int, best: Dictionary) -> bool:
	var op: Dictionary = OPS[i]
	return wins < int(op.unlock) and i > 0 and not best.has("op" + str(int(op.id) - 1))

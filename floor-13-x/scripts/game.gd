## game.gd — Floor 13: Retention (adult fork of Floor 13: Night Shift).
##
## Forked from ~/floor13-src/scripts/game.gd. Three things are added and nothing is removed:
##
##   1. The derived evidence flags are *materialised*. In the base game they exist only
##      inside simulate_route(), a test helper — `stair_gate_open`, `ledger_preserved`,
##      `permanent_badge`, `replacement_list`, `rusk_keycard` and `eli_phone_compliance`
##      are computed there for the route tests and never written to `flags`, so the case
##      log's "evidence" line is a hotspot count and nothing reads them. The fork writes
##      them at the choice that produces them, using simulate_route()'s own mapping, so the
##      CG conditions hang on real state rather than on a re-derivation.
##   2. CG hooks at the seven points ops/adult_forks/floor-13.md §4 names. A ["CG", slot]
##      line inside any passage suspends the dialogue, presents the plate once, and resumes.
##      CgGate.earn() re-checks the conditions, so a plate cannot be shown by reaching a
##      line — only by having taken the stance. NOTHING here unlocks from playtime; that is
##      the house rule across every fork (ops/adult_forks/README.md).
##   3. The free slice ends after File 3, the break-room decision, matching this fork's
##      store copy. The mainstream title's own gate was moved to File 3 separately
##      (ops/godot_gate_leak.md); this is the fork's own boundary, not that fix.
extends Node2D

var area_index := 0
var flags := {
	"eli_stance": "",
	"compliance": "",
	"escape_route": "",
	"contract": "",
	# [fork] Derived evidence, written at the choice that produces it. Mapping is
	# simulate_route()'s, unchanged — see the bottom of this file.
	"stair_gate_open": false,
	"eli_phone_compliance": false,
	"ledger_preserved": false,
	"permanent_badge": false,
	"replacement_list": false,
	"rusk_keycard": false,
	# [fork] Whether the player went and looked. Set by hotspot completion, never by time.
	"seen_coat": false,
	"seen_coat_evidence": false,
	"seen_terminal_second": false,
	"ending": ""
}

## [fork] The free browser slice is Files 1-3, ending on the break-room decision.
const FREE_FILES := 3

## [fork] Hotspots that do not have to be inspected for the area to be complete. The coat
## is where the fork's rule is explained, and the plate it half-earns should cost the
## player the decision to go and look at a coat rather than be handed to everyone who
## clears a room.
const OPTIONAL_HOTSPOTS := {"breakroom/coat": true}

## [fork] The fork's writing, spliced into the base areas. Cached because patch() copies.
var _areas_cache: Array = []
var _areas_locale := ""
## [fork] CG presentation state. A ["CG", slot] line interrupts the queue; `pending` is
## deliberately left alone across the interruption so the branch that was running resumes.
var _cg_pending := ""
var _cg_resume: Array = []
var _cg_resume_nvl := false
## [fork] Mara's terminal opens a second time once Compliance has been answered.
var _terminal_second := false
## [fork] Set when every required hotspot in the area is done but an optional one is still
## uninspected. The area's choice waits behind one press of the route button so the
## optional hotspot stays reachable — without this, clearing the four required hotspots
## first makes the coat permanently unclickable, and a plate that depends on click order
## is not an earned plate, it is a trap.
var _awaiting_choice := false
var discoveries: Array[String] = []
var completed_hotspots: Dictionary = {}
var current_hotspot := ""
var pending := ""
var started := false
var ending_id := ""
var world: OfficeBuilder
var hud: HorrorHud
var hotspot_layer: Control
var soundscape: Soundscape

const NVL_HOTSPOTS := ["coffee", "drawer", "ledger", "camera", "intercom", "alarm"]

## [fork] The patched area list. StoryData.live() stays the source of truth; StoryX.patch()
## adds the fork's hotspot and extended branches on top of a copy of it.
func _areas() -> Array:
	if _areas_cache.is_empty() or _areas_locale != Loc.current():
		_areas_cache = StoryX.patch(StoryData.live())
		_areas_locale = Loc.current()
	return _areas_cache

func _ready() -> void:
	add_to_group("game")
	world = OfficeBuilder.new()
	world.name = "PixelWorld"
	add_child(world)
	soundscape = Soundscape.new()
	soundscape.name = "Soundscape"
	add_child(soundscape)
	hud = HorrorHud.new()
	hud.name = "HUD"
	add_child(hud)
	hud.choice_made.connect(_on_choice)
	hud.route_requested.connect(_on_route)
	hud.restart_requested.connect(restart)
	hud.title_requested.connect(start_game)
	await get_tree().process_frame
	hotspot_layer = Control.new()
	hotspot_layer.name = "Hotspots"
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.root_ui.add_child(hotspot_layer)
	hud.root_ui.move_child(hotspot_layer, 1)
	world.build("cubicle", flags)
	hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))

func start_game() -> void:
	if started:
		return
	started = true
	area_index = 0
	_load_area()

func restart() -> void:
	area_index = 0
	flags = {"eli_stance": "", "compliance": "", "escape_route": "", "contract": "",
		"stair_gate_open": false, "eli_phone_compliance": false,
		"ledger_preserved": false, "permanent_badge": false,
		"replacement_list": false, "rusk_keycard": false,
		"seen_coat": false, "seen_coat_evidence": false, "seen_terminal_second": false,
		"ending": ""}
	_cg_pending = ""
	_cg_resume.clear()
	_terminal_second = false
	_awaiting_choice = false
	CgGate.reset()
	discoveries.clear()
	completed_hotspots.clear()
	current_hotspot = ""
	pending = ""
	started = false
	ending_id = ""
	_clear_hotspots()
	hud.reset_ui()
	world.build("cubicle", flags)
	hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))

func _load_area() -> void:
	_clear_hotspots()
	var area: Dictionary = _areas()[area_index]
	# [fork] Files 1-3 are this fork's advertised free slice ("Files 1-3 of 7, ending on
	# the break-room decision"), so the gate opens on File 4. Keys are namespaced f13r_* so
	# a player's unlocks for the mainstream title do not open the fork, or the reverse —
	# both are served from the same origin on the ads site and share localStorage.
	if area_index >= FREE_FILES:
		Gate.block("f13r_area%d" % area_index, str(area.chapter))   # dual-track (ops/DUAL_TRACK.md)
	if area_index > 0:
		# The break offer, on a file boundary rather than on the gate: the gate only exists
		# from File 4, and the point of the offer is the crossing itself. It is silent on
		# the 1st and 3rd crossing of a session (shared/godot/gate.gd), so the player is
		# asked twice at most and never twice in a row.
		Gate.board_offer_break()
	world.build(area.id, flags)
	hud.set_header(area.chapter, area.place, area.clock, area.objective)
	_say(area.opening, false, "opening")

## [fork] `optional_only` redraws just the hotspots that are not required, for the window
## between finishing the room and taking its decision.
func _show_hotspots(optional_only := false) -> void:
	_clear_hotspots()
	var area: Dictionary = _areas()[area_index]
	var count := 0
	for hotspot in area.hotspots:
		var id := str(hotspot[0])
		if optional_only and not OPTIONAL_HOTSPOTS.has(_area_key(id)):
			count += 1
			continue
		var rect: Array = hotspot[2]
		var button := Button.new()
		button.name = "Hotspot_%s" % id
		button.position = Vector2(rect[0] * 2.0, rect[1] * 2.0)
		button.size = Vector2(rect[2] * 2.0, rect[3] * 2.0)
		button.text = ""
		button.tooltip_text = str(hotspot[1])
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color.TRANSPARENT
		var hover := normal.duplicate()
		hover.bg_color = Color("#1b405733")
		hover.border_color = Color("#84efff")
		hover.set_border_width_all(1)
		var pressed := normal.duplicate()
		pressed.bg_color = Color("#56242c55")
		pressed.border_color = Color("#ff5264")
		pressed.set_border_width_all(1)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		UiFont.apply_button(button)
		button.pressed.connect(_on_hotspot.bind(id))
		button.add_to_group("hotspot")
		hotspot_layer.add_child(button)
		var marker := Label.new()
		marker.position = Vector2(4, 4)
		marker.size = Vector2(26, 17)
		marker.text = "◆ %02d" % (count + 1)
		marker.add_theme_color_override("font_color", Color("#b8f4ff"))
		marker.add_theme_color_override("font_outline_color", Color("#05070d"))
		marker.add_theme_constant_override("outline_size", 3)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiFont.apply_label(marker)
		button.add_child(marker)
		count += 1

func _on_hotspot(id: String) -> void:
	if hud.is_busy() or completed_hotspots.has(_area_key(id)):
		return
	var area: Dictionary = _areas()[area_index]
	# [fork] Mara's terminal reads differently once Compliance has been answered. The base
	# game already carries a CONDITIONAL / MARA_ELI variant mechanism for exactly this
	# "second pass differs" case; this is the same idea one step further, as a whole
	# passage rather than a line. Going back to look is the player's decision, which is
	# what makes the plate behind it earned rather than issued.
	if id == "terminal" and str(area.id) == "server" and _terminal_second:
		_terminal_second = false
		flags.seen_terminal_second = true
		current_hotspot = id
		pending = "hotspot"
		soundscape.cue(_cue_for(id))
		_say(StoryX.terminal_second(flags), true, "hotspot")
		return
	for hotspot in area.hotspots:
		if hotspot[0] == id:
			current_hotspot = id
			pending = "hotspot"
			soundscape.cue(_cue_for(id))
			_say(hotspot[3], str(id) in NVL_HOTSPOTS, "hotspot")
			return

func on_dialogue_done() -> void:
	# [fork] A ["CG", slot] line suspends the passage. `pending` is deliberately untouched
	# across the interruption, so whatever branch was running resumes into its own case
	# below once the plate is dismissed and the remaining lines have played.
	if _cg_pending != "":
		var slot := _cg_pending
		_cg_pending = ""
		await _present_cg(slot)
		if not _cg_resume.is_empty():
			var rest: Array = _cg_resume.duplicate(true)
			_cg_resume.clear()
			_say_expanded(rest, _cg_resume_nvl)
			return
	match pending:
		"opening":
			pending = ""
			_show_hotspots()
		"hotspot":
			completed_hotspots[_area_key(current_hotspot)] = true
			# [fork] "Did the player go and look" is state, and the CG conditions read it.
			match _area_key(current_hotspot):
				"breakroom/coat":
					flags.seen_coat = true
				"stairs/coats":
					flags.seen_coat_evidence = true
			discoveries.append("%s — %s" % [_areas()[area_index].place, _hotspot_label(current_hotspot)])
			current_hotspot = ""
			pending = ""
			_show_hotspots()
			if _area_complete():
				var area: Dictionary = _areas()[area_index]
				# [fork] Optional hotspots stay on screen, with the choice one press away.
				if _optional_pending():
					_awaiting_choice = true
					_show_hotspots(true)
					hud.enable_route(Loc.t("route.next"))
				else:
					_clear_hotspots()
					# [fork] A decision already taken is not offered again. Completing the
					# reopened terminal re-runs this branch, and without the guard the
					# server floor asks for the ledger a second time.
					if area.has("choice") and str(flags.get(str(area.choice.id), "")) == "":
						hud.show_choice(area.choice)
					else:
						hud.enable_route(Loc.t("route.decision") if area.has("choice") else Loc.t("route.next"))
		"choice_after":
			pending = ""
			# [fork] On the server floor the terminal can be read a second time after the
			# decision. Both the hotspot and the route button are live: going back is
			# optional, and the plate behind it is the cost of choosing to.
			if _terminal_second:
				_show_hotspots()
			hud.enable_route(Loc.t("route.decision"))
		"transition":
			pending = ""
			area_index += 1
			_load_area()
		"ending":
			pending = ""
			hud.show_ending_card(StoryData.live_endings()[ending_id][-1][1])
			# End of the run: the rest of the adult catalogue, offered over the END card
			# so the player can read it, dismiss it, and still be looking at their ending.
			Gate.board_offer_more()

## [fork] Say a passage, honouring any ["CG", slot] marker inside it.
##
## `next_pending` is the value `pending` should carry while this passage plays; it is set
## before the queue starts so that a CG interruption in the middle cannot lose it.
func _say(lines: Array, use_nvl: bool, next_pending: String) -> void:
	pending = next_pending
	_say_expanded(_expand(lines), use_nvl)


func _say_expanded(lines: Array, use_nvl: bool) -> void:
	var before: Array = []
	var slot := ""
	var after: Array = []
	for line in lines:
		if slot == "" and str(line[0]) == "CG":
			slot = str(line[1])
			continue
		if slot == "":
			before.append(line)
		else:
			after.append(line)
	_cg_pending = slot
	_cg_resume = after
	_cg_resume_nvl = use_nvl
	if before.is_empty():
		# Nothing to read before the plate — go straight to it rather than flashing an
		# empty dialogue panel.
		if slot != "":
			_cg_pending = ""
			await _present_cg(slot)
			if not _cg_resume.is_empty():
				var rest: Array = _cg_resume.duplicate(true)
				_cg_resume.clear()
				_say_expanded(rest, use_nvl)
				return
		on_dialogue_done()
		return
	hud.show_dialogue(before, use_nvl)


## [fork] Earn, gate, show. In that order, and the order is the point.
##
## earn() re-checks the slot's story conditions against `flags`, so reaching the line is
## not sufficient — a plate a player did not earn is silently skipped and the passage
## continues around it. Nothing here consults elapsed time, session count or progress.
func _present_cg(slot: String) -> void:
	if not CgGate.earn(slot, flags):
		return
	discoveries.append("GALLERY — %s recovered" % CgGate.slot_title(slot))
	if not CgGate.is_unlocked(slot):
		var result := await CgGate.request_unlock(slot)
		if result == "unavailable":
			# The gate ran and no sponsor creative was served. The story continues — it is
			# never held hostage to an adblocker — and the plate stays censored, because
			# the uncensored art is the thing being sold and there is nothing to trade it
			# for. play/room-704/game/scripts/09_dist.rpy:280-299, memory ad-gate-rules.
			hud.set_cg_notice(true)
	await hud.show_cg(slot)


## [fork] The derived evidence, written at the choice that produces it.
##
## The mapping is simulate_route()'s own, at the bottom of this file, unchanged: the base
## game computes exactly these six for its route tests and then throws them away. Writing
## them into `flags` is what lets the CG conditions in CgGate.EARN name real state.
func _apply_derived(flag_name: String, value: String) -> void:
	match flag_name:
		"eli_stance":
			flags.stair_gate_open = value == "TRUST"
			flags.eli_phone_compliance = value != "TRUST"
		"compliance":
			flags.ledger_preserved = value == "REFUSE"
			flags.permanent_badge = value != "REFUSE"
		"escape_route":
			flags.replacement_list = value == "STAIRS"
			flags.rusk_keycard = value != "STAIRS"


func _on_choice(value: String) -> void:
	var area: Dictionary = _areas()[area_index]
	var flag_name := str(area.choice.id)
	flags[flag_name] = value
	_apply_derived(flag_name, value)
	if flag_name == "compliance":
		# [fork] Reopen Mara's terminal for its second read. The base game refuses a click
		# on a finished hotspot, so arming the flag alone left the passage unreachable for
		# a player as well as for the test — the completion has to be cleared too.
		_terminal_second = true
		completed_hotspots.erase("%s/terminal" % str(area.id))
	world.build(area.id, flags)
	discoveries.append(Loc.t("log.decision", [flag_name.to_upper().replace("_", " "), value]))
	soundscape.cue("choice")
	pending = "choice_after"
	_say(area.after[value], str(area.id) == "manager", "choice_after")

func _on_route() -> void:
	hud.hide_route()
	var area: Dictionary = _areas()[area_index]
	# [fork] First press closes the optional-hotspot window and opens the area's decision.
	if _awaiting_choice:
		_awaiting_choice = false
		_clear_hotspots()
		if area.has("choice"):
			hud.show_choice(area.choice)
		else:
			hud.enable_route(Loc.t("route.next"))
		return
	if area_index == _areas().size() - 1:
		_begin_ending()
		return
	pending = "transition"
	var lines: Array = (area.get("transition", []) as Array).duplicate(true)
	# [fork] The thirteenth landing, on the stairs route, carrying the replacement list and
	# having read what the coats' pockets actually held.
	if str(area.id) == "stairs" and flags.replacement_list and flags.seen_coat_evidence:
		lines = StoryX.landing(flags) + lines
	_say(lines, false, "transition")

func _begin_ending() -> void:
	ending_id = StoryData.resolve(flags)
	flags.ending = ending_id
	discoveries.append(Loc.t("log.ending", [ending_id.replace("_", " ")]))
	pending = "ending"
	soundscape.cue("ending")
	world.show_ending(ending_id)
	var lines: Array = StoryData.live_endings()[ending_id].duplicate(true)
	lines.pop_back()
	# [fork] One beat per ending, spliced inside the existing ending text rather than
	# tacked after the END card.
	lines = StoryX.ending_lines(ending_id, lines)
	_say(lines, true, "ending")

func _area_complete() -> bool:
	var area: Dictionary = _areas()[area_index]
	for hotspot in area.hotspots:
		var key := _area_key(str(hotspot[0]))
		if OPTIONAL_HOTSPOTS.has(key):
			continue   # [fork] the coat is there to be found, not to be cleared
		if not completed_hotspots.has(key):
			return false
	return true

## [fork] Is there an optional hotspot in this area the player has not looked at yet?
func _optional_pending() -> bool:
	for hotspot in _areas()[area_index].hotspots:
		var key := _area_key(str(hotspot[0]))
		if OPTIONAL_HOTSPOTS.has(key) and not completed_hotspots.has(key):
			return true
	return false


func _area_key(id: String) -> String:
	return "%s/%s" % [_areas()[area_index].id, id]

func _hotspot_label(id: String) -> String:
	for hotspot in _areas()[area_index].hotspots:
		if hotspot[0] == id:
			return hotspot[1]
	return id

func _clear_hotspots() -> void:
	if hotspot_layer == null:
		return
	for child in hotspot_layer.get_children():
		# [fork] remove_child before queue_free. A queue_freed node keeps its name and its
		# group membership until the end of the frame, so rebuilding the layer in the same
		# frame — which _show_hotspots() does after every hotspot — gave the new buttons
		# mangled names like @Hotspot_ticket@2 and left stale members in the "hotspot"
		# group. Harmless on screen, which is why it survived; not harmless to anything
		# that drives the game by node name, including the fork's own test.
		hotspot_layer.remove_child(child)
		child.queue_free()

func _cue_for(id: String) -> String:
	if "phone" in id or id == "intercom":
		return "phone"
	if id == "printer" or id == "ledger":
		return "printer"
	if id == "seal" or id == "directory":
		return "elevator"
	return "scanner"

func _expand(lines: Array) -> Array:
	var result: Array = []
	for raw in lines:
		if raw[0] != "CONDITIONAL":
			result.append(raw)
			continue
		result.append(StoryData.conditional_line(str(raw[1]), flags))
	return result

func on_locale_changed() -> void:
	if not started:
		hud.set_header(Loc.t("idle.chapter"), Loc.t("idle.place"), Loc.t("idle.clock"), Loc.t("idle.objective"))
		return
	if hud.is_busy():
		return
	var area: Dictionary = _areas()[area_index]
	hud.set_header(area.chapter, area.place, area.clock, area.objective)

func get_case_log_text() -> String:
	var pending := Loc.t("log.pending")
	var lines := PackedStringArray([
		Loc.t("log.objective", [_areas()[area_index].objective]),
		Loc.t("log.decisions"),
		Loc.t("log.eli", [flags.eli_stance if flags.eli_stance else pending]),
		Loc.t("log.compliance", [flags.compliance if flags.compliance else pending]),
		Loc.t("log.route", [flags.escape_route if flags.escape_route else pending]),
		Loc.t("log.contract", [flags.contract if flags.contract else pending]),
		Loc.t("log.evidence", [completed_hotspots.size()]),
		"PLATES RECOVERED: %d / %d" % [CgGate.earned_slots().size(), CgGate.SLOTS.size()]
	])
	for i in range(max(0, discoveries.size() - 8), discoveries.size()):
		lines.append("• " + discoveries[i])
	return "\n".join(lines)

static func simulate_route(route: Dictionary) -> Dictionary:
	var delayed := []
	delayed.append("stair_gate_open" if route.get("eli_stance") == "TRUST" else "eli_phone_compliance")
	delayed.append("ledger_preserved" if route.get("compliance") == "REFUSE" else "permanent_badge")
	delayed.append("replacement_list" if route.get("escape_route") == "STAIRS" else "rusk_keycard")
	return {"ending": StoryData.resolve(route), "delayed": delayed, "areas": StoryData.AREAS.size(), "hotspots": StoryData.total_hotspots()}

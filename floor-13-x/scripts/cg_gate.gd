## cg_gate.gd — CG unlock gate for the adult fork (autoload "CgGate").
##
## The chapter gate is shared/godot/gate.gd (autoload "Gate"), unchanged. This sits on top
## of it and owns the four things a chapter gate does not have to care about:
##
##   1. Earning.     A CG is *earned* by story state — never by playtime. earn() is called
##                   from game.gd at the points ops/adult_forks/floor-13.md §4 names, and
##                   the conditions are re-checked here so a caller cannot open a slot by
##                   calling the wrong function.
##   2. Unlocking.   An earned tier-3 CG still shows censored on the free web tracks until
##                   the player pays (itch) or watches one sponsor clip (ads site).
##   3. Sponsor-unavailable.  A missing ad script is NOT a watched ad. shared/gate.js
##                   resolves "unlocked" after its countdown even when no creative was
##                   served, which is exactly the hole ad_gate_finish() closes in Ren'Py
##                   (play/room-704/game/scripts/09_dist.rpy:280-299, memory ad-gate-rules).
##                   web/floor13x_gate.js reports whether a creative actually rendered; with
##                   no creative the story is never bricked, but the art stays censored,
##                   because there is nothing to trade it for.
##   4. Downloads carry no third-party calls at all. is_web() is false in the desktop
##                   export, and every branch below returns before touching JavaScriptBridge.
##                   An Adsterra popunder cost the studio its F95 account (memory
##                   f95-ban-direct-link-ads); the downloadable build cannot make a request.
##
## Track behaviour:
##   paid desktop download   everything earned is open, uncensored, offline, no network.
##   itch browser            earned tier-3 plates draw their _locked plate until purchase.
##   ads site                same, unlocked by one sponsor clip that actually ran.
##   portal builds           the fork is never submitted to a portal; see §4 of the design doc.
extends Node

## The plate slots, keyed exactly as ops/floor13_art/floor13_gen.py names them.
## tier follows ops/adult_forks/ART_DIRECTION.md: tier 3 ships a censored `_locked` plate on
## the free tracks, tier 2 has no censored counterpart and unlocks with one clip.
const SLOTS := {
	"cg_breakroom_x": {"tier": 3, "title": "Break room", "order": 1},
	"cg_terminal_x": {"tier": 3, "title": "The terminal", "order": 2},
	"cg_landing_x": {"tier": 3, "title": "The thirteenth landing", "order": 3},
	"cg_retention_x": {"tier": 3, "title": "Floor 0, Retention", "order": 4},
	"cg_desk_x": {"tier": 3, "title": "The chair", "order": 5},
	"cg_present_x": {"tier": 2, "title": "Present", "order": 6},
	"cg_monday_x": {"tier": 2, "title": "Monday forever", "order": 7},
}

## What each slot costs in story state. Checked here as well as at the call site, so the
## rule "no CG unlocks from playtime" is enforced by data rather than by discipline.
## Every key named here is a real flag that game.gd sets; nothing is time- or progress-based.
const EARN := {
	"cg_breakroom_x": {"eli_stance": "TRUST", "seen_coat": true},
	"cg_terminal_x": {"compliance": "REFUSE", "ledger_preserved": true, "seen_terminal_second": true},
	"cg_landing_x": {"escape_route": "STAIRS", "replacement_list": true, "seen_coat_evidence": true},
	"cg_retention_x": {"escape_route": "ELEVATOR", "rusk_keycard": true},
	"cg_desk_x": {"contract": "SIGN"},
	"cg_present_x": {"contract": "RESIGN", "ledger_preserved": true, "eli_stance": "TRUST"},
	"cg_monday_x": {"ending": "MONDAY_FOREVER"},
}

const ART_DIR := "res://assets/cg/"

signal earned(slot: String)

var _earned: Dictionary = {}
## Slots whose gate came back "sponsor unavailable" this session. Separate from "not
## unlocked" so telemetry and QA can tell a blocked ad from a player who said no.
var _unavailable: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset() -> void:
	_earned.clear()
	_unavailable.clear()

# ---- earning ---------------------------------------------------------------

func conditions_met(slot: String, flags: Dictionary) -> bool:
	if not EARN.has(slot):
		return false
	for key in EARN[slot]:
		var want = EARN[slot][key]
		if want is bool:
			if bool(flags.get(key, false)) != want:
				return false
		elif str(flags.get(key, "")) != str(want):
			return false
	return true

## Called from game.gd at a story beat. Returns true the first time the slot is earned,
## so the caller can show the plate exactly once, in the scene where it happens.
func earn(slot: String, flags: Dictionary) -> bool:
	if not SLOTS.has(slot) or _earned.has(slot):
		return false
	if not conditions_met(slot, flags):
		return false
	_earned[slot] = true
	earned.emit(slot)
	return true

func is_earned(slot: String) -> bool:
	return _earned.has(slot)

func earned_slots() -> Array:
	var out: Array = []
	for slot in SLOTS:
		if _earned.has(slot):
			out.append(slot)
	return out

# ---- unlocking -------------------------------------------------------------

func is_web() -> bool:
	return OS.has_feature("web")

## True when this build is the paid download: no gate, no network, everything open.
func is_paid_build() -> bool:
	return not is_web()

func is_unlocked(slot: String) -> bool:
	if not SLOTS.has(slot):
		return false
	if is_paid_build():
		return true
	return Gate.has(slot)

func was_unavailable(slot: String) -> bool:
	return _unavailable.has(slot)

## Ask the page to unlock this slot. Three outcomes, never two:
##   "unlocked"     paid, or a sponsor clip that actually showed a creative
##   "unavailable"  the gate ran but no creative was served — art stays censored
##   "closed"       the player declined
func request_unlock(slot: String) -> String:
	if not SLOTS.has(slot):
		return "closed"
	if is_paid_build() or Gate.has(slot):
		return "unlocked"
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return "closed"   # a page without gate.js (local test) reveals nothing extra
	var title: String = str(SLOTS[slot].title)
	var has_x: bool = bool(JavaScriptBridge.eval("window.Floor13xGate ? 1 : 0"))
	var js := ""
	if has_x:
		js = """
			window.__cggate = window.__cggate || {};
			window.__cggate[%s] = "";
			window.Floor13xGate.require(%s, {title: %s, kind: "cg"}).then(function (r) { window.__cggate[%s] = r; });
		""" % [JSON.stringify(slot), JSON.stringify(slot), JSON.stringify(title), JSON.stringify(slot)]
	else:
		# No fork gate script on the page. Fall back to the shared gate, but treat its
		# "unlocked" on the ad track as unverified: gate.js cannot tell us whether a
		# creative ran, and a missing ad script is not a watched ad.
		js = """
			window.__cggate = window.__cggate || {};
			window.__cggate[%s] = "";
			window.Gate.require(%s, {title: %s, kind: "cg"}).then(function (r) {
				window.__cggate[%s] = (r === "unlocked" && window.Gate.dist && window.Gate.dist() === "ads_web") ? "unavailable" : r;
			});
		""" % [JSON.stringify(slot), JSON.stringify(slot), JSON.stringify(title), JSON.stringify(slot)]
	JavaScriptBridge.eval(js)
	var result := ""
	while result == "":
		await get_tree().create_timer(0.4, true, false, true).timeout   # runs while paused
		var r = JavaScriptBridge.eval("(window.__cggate && window.__cggate[%s]) || ''" % JSON.stringify(slot))
		result = str(r) if r != null else ""
	if result == "unavailable":
		_unavailable[slot] = true
	elif result != "unlocked":
		result = "closed"
	return result

# ---- art -------------------------------------------------------------------

## Which file to draw for a slot right now.
##
## This checks the *file*, not a flag, because the free packages genuinely do not contain
## the uncensored plates — the same reason cg_pick() checks renpy.loadable() at
## play/room-704/game/scripts/09_dist.rpy:164-178. A .pck unzips in four lines of Python,
## so shipping the art and hiding it behind a boolean hides nothing.
## Returns "" when there is nothing to draw and the presenter should show its locked card.
func plate_path(slot: String) -> String:
	if not SLOTS.has(slot):
		return ""
	var open_path := ART_DIR + slot + ".png"
	if is_unlocked(slot) and ResourceLoader.exists(open_path):
		return open_path
	var locked_path := ART_DIR + slot + "_locked.png"
	if ResourceLoader.exists(locked_path):
		return locked_path
	# Tier 2 has no censored counterpart of its own — ART_DIRECTION.md puts it at "free web
	# after an ad watch", so there is nothing to censor, only something not yet earned the
	# clip for. A shared withheld card is better than an empty frame, which reads as a bug.
	var withheld := ART_DIR + "cg_withheld.png"
	if ResourceLoader.exists(withheld):
		return withheld
	return ""

func is_showing_censored(slot: String) -> bool:
	return not is_unlocked(slot)

func slot_title(slot: String) -> String:
	return str(SLOTS[slot].title) if SLOTS.has(slot) else slot

## Ordered slot list for the gallery, earned first.
func gallery_order() -> Array:
	var out: Array = SLOTS.keys()
	out.sort_custom(func(a, b): return int(SLOTS[a].order) < int(SLOTS[b].order))
	return out

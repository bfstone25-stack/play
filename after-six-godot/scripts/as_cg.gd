## as_cg.gd — the CG gate for After Six (autoload "AsCg"). The same gated path Floor 13 X
## uses (play/floor-13-x/scripts/cg_gate.gd), cut to what this prototype has: one slot.
##
##   1. Earning.     A plate is earned by STATE — the case won and the offer refused or put
##                   down (beat_monday_map.md §2.2) — never by playtime, and never by taking
##                   the deal. The conditions live here so a caller cannot open the slot by
##                   calling the wrong function.
##   2. Unlocking.   On the free web tracks an earned tier-3 plate shows its `_locked`
##                   partner until the player pays (itch) or one sponsor clip actually ran
##                   (ads site). web/aftersix_gate.js reports whether a creative rendered;
##                   no creative => "unavailable" => the plate stays censored. A missing ad
##                   script is not a watched ad (memory ad-gate-rules).
##   3. The pack.    The open tier-3 plate never ships in a web pack (export_presets.cfg
##                   excludes assets/cg_open/); a boolean hides nothing. Delivery of the open
##                   bytes through the gateway IS wired (2026-09-19): as_unlock.gd takes a
##                   ticket when the gate opens and fetches the real bytes when it clears,
##                   and `is_unlocked` on the web means those bytes are on this machine.
##                   A gate that clears against a gateway with nothing staged still answers
##                   "unavailable" and still draws the censored plate — the honest answer
##                   survives, it is only the *silent* failure that is gone.
##   4. Downloads carry no third-party call: every branch returns before touching
##                   JavaScriptBridge when OS.has_feature("web") is false.
extends Node

## Slot ids are the render slots (ops/beat_monday_art/beat_monday_gen.py). Tier per
## ops/adult_forks/ART_DIRECTION.md.
const SLOTS := {
	"cg_return_x": {"tier": 3, "title": "23:40 · she came back", "order": 1},
}

## What each slot costs in story state. `offer` is the choice made in the offer scene.
const EARN := {
	"cg_return_x": {"case_won": true, "offer": ["refuse", "drop"]},
}

const OPEN_DIR := "res://assets/cg_open/"
const LOCKED_DIR := "res://assets/art/"

signal earned(slot: String)

var _earned: Dictionary = {}
var _unavailable: Dictionary = {}
var _unlocked: Dictionary = {}
var unlock: AsUnlock


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	unlock = AsUnlock.new()
	unlock.name = "AsUnlock"
	add_child(unlock)


func reset() -> void:
	_earned.clear()
	_unavailable.clear()


# ---- earning ---------------------------------------------------------------------------
func conditions_met(slot: String, flags: Dictionary) -> bool:
	if not EARN.has(slot):
		return false
	for key in EARN[slot]:
		var want = EARN[slot][key]
		if want is bool:
			if bool(flags.get(key, false)) != want:
				return false
		elif want is Array:
			if not want.has(str(flags.get(key, ""))):
				return false
		elif str(flags.get(key, "")) != str(want):
			return false
	return true


## True the first time the slot is earned, so the caller shows the plate once, in the
## scene where it happens.
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


# ---- unlocking -------------------------------------------------------------------------
func is_web() -> bool:
	return OS.has_feature("web")


func is_paid_build() -> bool:
	return not is_web() and not AsUnlock.simulate_free


func has_open_plate(slot: String) -> bool:
	return ResourceLoader.exists(OPEN_DIR + slot + ".webp")


## "Unlocked" means the open bytes are available to this install. The paid download has
## them in the pack (when rendered); the web tracks would need the gateway delivery, which
## this prototype does not wire — so a cleared gate on the web is recorded, telemetered,
## and still draws the locked plate. Never a lie.
func is_unlocked(slot: String) -> bool:
	if not SLOTS.has(slot):
		return false
	if is_paid_build():
		return has_open_plate(slot)
	# On the web the open bytes are not in the pack at all, so the only thing that can make
	# this true is a real delivery. `_unlocked` (the page gate's answer) is deliberately NOT
	# consulted here: the gate clearing is the permission, the bytes arriving is the unlock.
	return AsUnlock.delivered(slot)


func was_unavailable(slot: String) -> bool:
	return _unavailable.has(slot)


## Ask the page. Three outcomes, never two: "unlocked" | "unavailable" | "closed".
func request_unlock(slot: String) -> String:
	if not SLOTS.has(slot):
		return "closed"
	if is_unlocked(slot):
		return "unlocked"
	if is_paid_build():
		return "unlocked" if has_open_plate(slot) else "unavailable"
	if not JavaScriptBridge.eval("window.Gate ? 1 : 0"):
		return "closed"   # a page without gate.js (local test) reveals nothing extra
	# The ticket is taken BEFORE the gate runs, so the gateway's dwell clock starts with
	# the gate rather than with the redeem. A failure here is not fatal: the gate still
	# runs, and redeem() below will simply find no ticket and answer "unavailable".
	await unlock.start(slot)
	var title: String = str(SLOTS[slot].title)
	var has_x: bool = bool(JavaScriptBridge.eval("window.AfterSixGate ? 1 : 0"))
	var js := ""
	if has_x:
		js = """
			window.__cggate = window.__cggate || {};
			window.__cggate[%s] = "";
			window.AfterSixGate.require(%s, {title: %s, kind: "cg"}).then(function (r) { window.__cggate[%s] = r; });
		""" % [JSON.stringify(slot), JSON.stringify(slot), JSON.stringify(title), JSON.stringify(slot)]
	else:
		# no fork gate on the page: the shared gate's "unlocked" on the ad track is
		# unverified — gate.js cannot say whether a creative ran
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
		await get_tree().create_timer(0.4, true, false, true).timeout
		var r = JavaScriptBridge.eval("(window.__cggate && window.__cggate[%s]) || ''" % JSON.stringify(slot))
		result = str(r) if r != null else ""
	if result == "unlocked":
		_unlocked[slot] = true
		# The gate said yes; now go and get the art. This is the step that was missing —
		# without it the next line found no bytes and every real unlock degraded to
		# "unavailable", which is how a cleared gate drew the locked plate.
		await unlock.redeem(slot)
		if not is_unlocked(slot):
			# the gate cleared and there are no bytes to show: that is not an unlock
			result = "unavailable"
	if result == "unavailable":
		_unavailable[slot] = true
	elif result != "unlocked":
		result = "closed"
	return result


# ---- art -------------------------------------------------------------------------------
## Which file to draw right now: the open plate only when the bytes are here and unlocked,
## else the `_locked` partner (a labelled placeholder card until the render lands).
func plate_path(slot: String) -> String:
	if not SLOTS.has(slot):
		return ""
	if is_unlocked(slot):
		# On the web the bytes live in user://, delivered by the gateway; in the paid build
		# they are in the pack. Both are "the open plate", and the caller must go through
		# plate_texture() rather than load(), because load() only understands res://.
		if not is_paid_build() and AsUnlock.delivered(slot):
			return AsUnlock.saved_path(slot)
		if has_open_plate(slot):
			return OPEN_DIR + slot + ".webp"
	var locked := LOCKED_DIR + slot + "_locked.webp"
	return locked if ResourceLoader.exists(locked) else ""


## The plate to draw right now, decoded. Use this rather than load(plate_path(...)): a
## delivered plate is a user:// file that ResourceLoader will not touch, and a silent null
## there is exactly the "cleared gate draws nothing" bug this all exists to prevent.
func plate_texture(slot: String) -> Texture2D:
	var path := plate_path(slot)
	if path == "":
		return null
	if path.begins_with("res://"):
		var res := load(path)
		return res if res is Texture2D else null
	return AsUnlock.delivered_texture(slot)


func is_showing_censored(slot: String) -> bool:
	return not is_unlocked(slot)


func slot_title(slot: String) -> String:
	return str(SLOTS[slot].title) if SLOTS.has(slot) else slot

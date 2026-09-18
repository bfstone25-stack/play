extends RefCounted
class_name Collateral

## Fork wiring: the plate table, the gate list, and the one question the refund rule turns
## on. The GDScript twin of GATED_CGS in the Ren'Py fork's 09_dist.rpy:22.

## Plate id -> {gated, title, condition}. "gated" means the uncensored bytes are NOT in
## the free package at all — see unlock.gd. `cg_tamsin` is deliberately not gated: one
## genuinely uncensored plate up front is what makes the rest legible as a purchase rather
## than as a bait screen (Room 704 gated both of its CGs and 75 browser plays bought
## nothing).
const PLATES := {
	"cg_tamsin": {
		"gated": false, "item": "tamsin",
		"title": "The finial — what the room looked like",
	},
	"cg_finial": {
		"gated": true, "item": "finial",
		"title": "The finial — what she was doing in it",
	},
	"cg_ring": {
		"gated": true, "item": "ring",
		"title": "The ring — eleven months after",
	},
	"cg_veil": {
		"gated": true, "item": "veil",
		"title": "The veil — the night before the funeral",
	},
	"cg_market": {
		"gated": true, "item": "market",
		"title": "Calder's proof — somebody else's night",
	},
	"cg_collateral": {
		"gated": true, "item": "collateral",
		"title": "The Black Ledger — your own hand",
	},
}

## GATED_CGS = ("finial", "ring", "veil", "market", "collateral"), exactly as the design's
## §4 first bullet specifies, with cg_tamsin ungated on every track.
const GATED := ["cg_finial", "cg_ring", "cg_veil", "cg_market", "cg_collateral"]

## Reading Ledger order — the six slots, in story order.
const LEDGER_ORDER := ["tamsin", "finial", "ring", "veil", "market", "collateral"]


static func is_gated(id: String) -> bool:
	return GATED.has(id)


static func plate_for(item: String) -> String:
	return "cg_" + item


## Did the player actually get the uncensored plate for `item`?
##
## This is the pivot of the fee-refund rule in reading_take(). A free-track player who
## pays shop cash and then declines the distribution gate must not be left poorer *and*
## looking at a silhouette — that is the exact shape of "a second paywall" that the design
## names as the riskiest part of the fork.
static func delivered(item: String) -> bool:
	var id := plate_for(item)
	if not is_gated(id):
		return true
	return Unlock.ready_for(id)

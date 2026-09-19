extends RefCounted
class_name Overnight

## Overnight Clause — fork wiring.
##
## Everything here sits *beside* the base episode rather than replacing it: stage() calls
## StoryContent.stage() and appends the fork's own evidence, and every plate hook is a line
## that already ran in Flat 404 (game.gd:334/364/393/401/409/412 and the resolver at :453).
## No new state machine, no new flags except the two the gallery needs.

## Plate id -> {gated, scene, free}. "gated" means the uncensored bytes are NOT in the
## free package at all — see unlock.gd. Only two are gated, deliberately:
## 09_dist.rpy:22-25 records that a wider gate promised something it never delivered
## across 75 browser plays and zero purchase clicks.
const PLATES := {
	"cg_mirror":   {"gated": false, "tier": 3, "scene": "ch3_mirror",  "title": "The cracked mirror"},
	"cg_hatch":    {"gated": true,  "tier": 3, "scene": "ch4_hatch",   "title": "Through the hatch"},
	"cg_cavity":   {"gated": false, "tier": 0, "scene": "ch5_cavity",  "title": "The cavity"},
	"cg_renewal":  {"gated": false, "tier": 0, "scene": "ch6_renewal", "title": "Renewal"},
	"cg_403":      {"gated": true,  "tier": 3, "scene": "ch6_403",     "title": "403, before light"},
	"cg_witness":  {"gated": false, "tier": 1, "scene": "ch7_witness",  "title": "Ending — Witness"},
	"cg_complicit":{"gated": false, "tier": 0, "scene": "ch7_complicit","title": "Ending — Complicit"},
	"cg_404":      {"gated": false, "tier": 0, "scene": "ch7_404",      "title": "Ending — 404"},
}

const GATED := ["cg_hatch", "cg_403"]

## Stand-ins for slots whose render has not landed. Only used when the slot's own file
## and its `_locked` partner are both absent, and only for open plates — a gated slot
## always falls to its censored partner, never to somebody else's picture.
##
## cg_complicit is the one that needed this. It is declared in PLATES above and in the
## design's ending table, but it was never a slot in late_inspection_gen.py and has no
## entry in picks.json, so the COMPLICIT ending — a whole third of the game's endings —
## was showing the player a placeholder card that read "OVERNIGHT CLAUSE — PLACEHOLDER
## PLATE". cg_renewal is the COMPLICIT route's own plate (the renewed flat, the morning
## that should not exist), so it is the honest stand-in until the render lands, at which
## point cg_complicit.png simply exists and the chain stops one step earlier.
const SUBSTITUTE := {
	"cg_complicit": "cg_renewal",
}


static func is_gated(id: String) -> bool:
	return GATED.has(id)


static func substitute(id: String) -> String:
	return str(SUBSTITUTE.get(id, ""))


static func gate_scene(id: String) -> String:
	return "gate_403" if id == "cg_403" else "gate_hatch"


## The fork's own evidence. Appended to the base stage tables so the base
## positions, prompts and ordering survive untouched.
static func extra(s: int, flags: Dictionary) -> Array[Dictionary]:
	match s:
		1:
			return [StoryContent.n("tickets", "Read the printouts taped to 403", Vector3(-2.72, 1.05, 5.52), """Six housing-authority tickets, printed and taped to the inside of 403's door frame where the tenant can see them from his own bed.

VC-4419 damp, 403/404 party wall — CLOSED, no fault found.
VC-4477 noise in stack, voice — CLOSED, tenant misuse.
VC-4502 welfare check, I. Vale — CLOSED, occupant surrendered unit.
---
The last two are annotated in the same hand, pressed hard enough to emboss the sheet beneath:

I DID NOT CLOSE THESE. THE SYSTEM CLOSED THEM AND THEN EMAILED ME TO ASK HOW IT DID.
---
The sixth has no number. It is a screenshot of a web form that returned: ADDRESS NOT RECOGNISED — VESPER COURT 403.

He printed it anyway. He printed the thing that said he does not live where he lives, and he taped it to his own door at eye height.""")]
		5:
			return [StoryContent.n("hatch", "Examine the service hatch bolts", Vector3(10.05, 0.32, 8.45), """A maintenance hatch at floor level, four bolts, and a pattern of scratches around the third one that only comes from being turned repeatedly by somebody working blind from the far side.

The dust inside the recess is disturbed in one direction: outward, into this bathroom, eleven times over.
---
MARA: Somebody has been crawling eighteen feet of service cavity to check whether a flat everyone calls empty is still empty.

Not to take anything. Nothing in here is missing. He came through, looked, and went back.""")]
		11:
			if bool(flags.get("clause_refused", false)):
				return [StoryContent.n("corridor_blue", "Look under the front door", Vector3(1.28, 0.12, 4.0), """Under the door, where a corridor should put a strip of yellow light on the floorboards, there is a strip of something closer to a colour than a light: black-blue, even, no bulb behind it, no shadow crossing it.

Put a hand in it and the hand feels the temperature of the outside of a window.
---
MARA: The corridor has stopped being a corridor and has not decided what to be instead. This is what refusing does. It does not make the building safe; it makes it unfinished.

The service hatch in the bathroom is still a hatch. That is the route now, and there is a man on the other end of it who has done it eleven times in the dark.""")]
			return []
	return []


static func stage(s: int, flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = StoryContent.stage(s, flags)
	out.append_array(extra(s, flags))
	return out


static func commentary(id: String) -> String:
	var pages := {
		"tickets": "MARA'S FIELD NOTE: A closed ticket is an outside record that says nothing happened. Six of them make a pattern that is easier to prove than a ghost: somebody with system access is resolving complaints about this wall without inspecting it. That is a disciplinary matter in daylight and it does not require anyone to believe me about the pipe.",
		"hatch": "MARA'S FIELD NOTE: Eleven trips through a service cavity and nothing removed from the flat. Whatever Dane Orlov is, he is not a man staging a scene — a man staging a scene brings props in. He has been checking on a room because no one else would.",
		"corridor_blue": "MARA'S FIELD NOTE: Tearing the clause did not restore the corridor; it suspended it. Note for the referral: the building's stable states are 'occupied by a tenant it acknowledges' and 'occupied by a custodian who signed'. Refusal is not a state it has a form for, which is the first good news tonight.",
	}
	if pages.has(id):
		return "\n---\n" + str(pages[id])
	return StoryContent.commentary(id)

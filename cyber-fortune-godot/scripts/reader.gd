class_name ReaderForces
extends RefCounted
## The reader's four forces — real mentalism, honestly performed. Pure logic: the scene
## performs it, tests/run_tests.gd proves each one lands for every input path.
##
##   binary     six cards, "is your number on this one?" -> any 1..63 (bit k on card k)
##   math       x -> 2x -> +8 -> /2 -> -x = 4, for every x -> the symbol at 4
##   princess   five cards shown; five *different* cards shown after; "yours is gone"
##   equivoque  four objects, two apparent free choices, always the candle

# ---- the binary force ------------------------------------------------------------------
static func binary_card(k: int) -> Array:
	var out := []
	for n in range(1, 64):
		if n & (1 << k):
			out.append(n)
	return out


## answers[k] is the player's yes/no for card k.
static func binary_result(answers: Array) -> int:
	var n := 0
	for k in range(mini(answers.size(), 6)):
		if answers[k]:
			n |= 1 << k
	return n


# ---- the mathematical force -------------------------------------------------------------
const MATH_ANSWER := 4


static func math_trace(x: float) -> Array:
	var a := x * 2.0
	var b := a + 8.0
	var c := b / 2.0
	var d := c - x
	return [x, a, b, c, d]


static func math_result(x: float) -> int:
	return int(round(math_trace(x)[4]))


# ---- the Princess card trick ---------------------------------------------------------------
## Five shown; the "after" set is four sibling cards: same ranks, different suits, none of
## the first five — so whichever one was remembered is gone, and the other four look
## close enough that nobody notices they all changed.
const PRINCESS_SHOW := ["queen-of-cups", "knight-of-swords", "nine-of-wands", "five-of-pentacles", "king-of-wands"]
const PRINCESS_AFTER := ["queen-of-swords", "knight-of-cups", "nine-of-pentacles", "king-of-cups"]


static func princess_gone(chosen: String) -> bool:
	return chosen in PRINCESS_SHOW and not (chosen in PRINCESS_AFTER)


# ---- equivoque ---------------------------------------------------------------------------
const EQUIV_ITEMS := ["candle", "key", "coin", "feather"]
const EQUIV_TARGET := "candle"


## Step one: the player pushed two items toward her. She keeps the pair with the candle.
## Returns the line she says and the pair that stays in play.
static func equivoque_push(pushed: Array) -> Dictionary:
	var rest := []
	for it in EQUIV_ITEMS:
		if not (it in pushed):
			rest.append(it)
	if EQUIV_TARGET in pushed:
		return {"line": "keep_pair", "pair": pushed.duplicate()}
	return {"line": "drop_pair", "pair": rest}


## Step two: from the pair, the player hands her one. Either way it is the candle.
static func equivoque_hand(pair: Array, handed: String) -> Dictionary:
	if handed == EQUIV_TARGET:
		return {"line": "gave", "result": EQUIV_TARGET}
	return {"line": "kept", "result": EQUIV_TARGET}


static func equivoque_pairs() -> Array:
	var out := []
	for i in range(EQUIV_ITEMS.size()):
		for j in range(i + 1, EQUIV_ITEMS.size()):
			out.append([EQUIV_ITEMS[i], EQUIV_ITEMS[j]])
	return out

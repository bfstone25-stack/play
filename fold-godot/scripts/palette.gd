## Palette — FOLD's colours, one place.
##
## The studio convention is play/overtime-idle-godot/scripts/palette.gd: a `Palette` class
## with role names, and `StudioTheme.build()` reading those roles, so the two files drop
## into any fork. The *roles* are shared; the hues are this title's own.
##
## 2026-09-19, Blaze's redirect. The previous version of this file opened "FOLD's world is
## a lacquered board in a dark room" and it was, faithfully: pine-black ground, one gold
## lamp, walnut. The craft was fine and the aim was wrong. FOLD is all-ages — children
## play it — and it ships next to CrazyGames and the phone stores, where the shelf is
## bright, saturated and sweet. A dim study is not a thing a ten-year-old taps.
##
## So the room is gone. FOLD's world is now a **toy box in the sun**: warm cream light,
## white cards, candy paper, one tangerine button and a sunny-yellow mark. Every role name
## below is unchanged, which is what makes this a repaint rather than a rewrite — the
## theme, the board and the HUD all read these names and moved with them.
##
## Two rules survived the repaint intact and are the reason the file still carries
## numbers rather than vibes:
##
##   * the playfield answers to legibility first (TITLE_SCREENS.md), and the contrast
##     targets at the bottom of this file are still measured, still asserted;
##   * text is never pure black on a bright ground any more than it was pure white on a
##     dark one — INK is a deep grape, which belongs to the candy palette.
class_name Palette

# ---- the studio's role table, in FOLD's hues ------------------------------------------
#
# GROUND is no longer "the room the board sits in" — it is daylight. Everything that used
# to get darker as it receded now gets *warmer*, because on a bright ground depth reads as
# warmth and shadow, not as black.
const GROUND := Color("FFF1D6")        # sunlit cream: the page's ground
const PANEL := Color("FFFFFF")         # a white card
const PANEL_EDGE := Color("E7D3AC")
# ACCENT is the one thing to press. Tangerine rather than gold: on a cream ground a yellow
# button is nearly invisible, and the whole point of the accent is that a child's eye lands
# on it before anything else. GOLD stays sunny yellow and does the *precious* half of the
# old accent's job — the mark, the stars, the sparkle.
const ACCENT := Color("FF7A3C")        # tangerine: the button, the thing to press
const GOLD := Color("FFC22E")          # sunny yellow: the mark, the stars, a win
const HEAT := Color("1FC8A9")          # mint: a merge landing, a hint, "closer"
const SUCCESS := Color("32C75A")
const TEXT := Color("2C1F45")          # deep grape, not black: body text on a bright card
const MUTED := Color("6E5D88")         # lilac-grey, measured 5.25:1 on cream
const COMMON := Color("59B7F5")        # the tile ramp's blue
const RARE := Color("FF9F2E")
const EPIC := Color("FF6FA8")

# derived, still on the same hues
const GROUND_DEEP := Color("FFE0A8")   # the warm end of the daylight gradient
const PANEL_RAISED := Color("FFFDF7")
const PANEL_TOP := Color("FFF7E4")
const ACCENT_DEEP := Color("E85C22")   # pressed: the tangerine pushed in
const ACCENT_SOFT := Color("FF9B63")   # hover: lifted
const GOLD_DEEP := Color("E09A00")
const GOLD_PALE := Color("FFE08A")
const HEAT_DEEP := Color("12A88C")
const INK := Color("241938")           # text on paper and on a tile
const INK_SOFT := Color("5B4A7A")
const PAPER := Color("FFFDF5")
const PAPER_ALPHA := 0.97

# ---- the sibling files' names, resolved onto the table above ---------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("CDB489")
const LINE_SOFT := Color("F0E2C6")
const LAMP := Color("FFF3C4")          # the sun, not a lamp
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("E0A62E")
const CREAM := PAPER
const PARCHMENT := PAPER
const DIM := MUTED
const FAINT := Color("9A8CB2")
const PAPER_PLAYER := PAPER
const PAPER_GRAY := Color("F2ECDD")
const GREEN := SUCCESS
const GREEN_DEEP := Color("1FA544")
const RARE_TEXT := Color("C25A00")
const EPIC_TEXT := Color("C2266E")
const RED := Color("FF5A6E")
const RED_TEXT := Color("C41E36")
const RED_DIM := Color("FFD3D8")
const PLUM := Color("FFF1D6")           # the theme-colour for the web page's chrome

## The board's own surfaces, which are not UI: the cell wells the pieces sit in, and the
## blocks that never move.
const CELL := Color("F6E6C4")
const CELL_DEEP := Color("EBD7AE")
const WALL := Color("7A6A94")
const WALL_ALT := Color("6B5C85")


# ---- the playfield ---------------------------------------------------------------------
#
# ops/adult_forks/TITLE_SCREENS.md, "The playfield is not the title screen": the board is
# furniture the player reads, and it answers to legibility first. That rule was written
# *because of this game* — the shipped board was so dim the tiles barely read, and the
# first Godot build's empty cell and its table came out at a contrast ratio of 1.01:1,
# which is to say the same colour.
#
# The bright repaint does not get to inherit that credit, and the first attempt at it
# earned none: a mint play surface under candy tiles measured 1.00:1 on the 4 — the exact
# same defect as the walnut build, in daylight. Bright is not the same property as legible.
#
# What fixed it is the shape of the thing rather than its lightness. The board is a *tray*
# of deep saturated teal set into a sunny cream page: the page stays bright, and the tray
# is dark enough that every candy tile on it reads as a lit object. That is also why the
# reference build works — Rebound Tycoon is a bright game with a dark board.
#
# Targets, and what these values actually score (WCAG contrast, sRGB luminance):
#
#   a tile against the tray         >= 3.0    worst is 3.51 (the 128)
#   a tile's number on its own tile >= 4.5    worst is 9.70
#   an empty well against the tray  >= 2.0    2.12, and it also carries a lit lip
#   a wall against the tray         >= 3.0    3.06
#   the tray against the page       >= 1.3    5.35
#   muted text on the page          >= 4.5    5.25
#
# One honest caveat, recorded rather than papered over: a pale wall block cannot also be
# separated from all eight candy tiles *by luminance* — against the sunny 32 it measures
# 1.15:1. Luminance is the wrong instrument there. A wall is told apart by hue (neutral
# grape against saturated candy), by carrying no number, and by WALL_EDGE, a dark outline
# no tile has. The target below is set at 1.1 to record that it is deliberate.
#
# One more correction that only appeared once the rendered plates landed. A tinted
# surface is a *plate multiplied by a Palette colour*, and the plate's own mean is
# therefore a gain on every value below. `derive --neutral` centres a tinted plate on
# 0.92 of white (it cannot centre on 1.0 and still have grain left to clip into), so the
# tray, the wells and the walls all render at 0.92 of what they say here. Measured with
# the ideal values, the board passed; measured with the plates actually installed, the
# empty well scored 1.99 against a target of 2.00 and the wall 2.93 against 3.00.
#
# So SURFACE_GAIN is a real number in the test rather than a footnote, and these two
# values were re-picked until they clear the targets *as rendered*. This is the third
# time this board has been caught by measuring the thing instead of the intention.
#
# The empty cell changed direction in the saturation pass, and the reason is worth a line.
# It used to be a shadow *darker* than the tray. Once the tray went deep enough to make a
# vivid ramp read on it, "darker than the tray" meant very nearly black, which clears the
# target by hundredths and looks like a hole punched in a children's game. So a well is
# now a **lit recess**: lighter than the tray, desaturated against the candy, 2.37:1 on
# the tray and never closer than 1.49:1 to any tile. Empty still cannot be mistaken for
# occupied, and the board stopped looking perforated.
#
# The idiom is the toy box: TABLE is the tray, RAIL its bright lip, WELL a lit recess in
# it and WELL_LIP the bright catch on that recess's near edge.
##
## What a tinted surface's plate multiplies every colour below by — see the note above,
## and ops/fold_art/fold_gen.py's NEUTRAL_MEAN, which is where the 0.92 comes from.
const SURFACE_GAIN := 0.92
const TABLE := Color("0F5446")         # the deep teal tray the board sits in
const TABLE_DEEP := Color("0A3F34")    # the same tray falling away at its far edge
const TABLE_RAIL := Color("7FF0D8")    # the bright mint lip that says where the board stops
const WELL := Color("2E9884")          # an empty cell: a lit recess in the tray
const WELL_LIP := Color("7FF0D8")      # the bright catch on that recess's near edge
const WALL_FACE := Color("CAC3E8")     # the block that never moves: pale grape, raised
const WALL_EDGE := Color("190F2A")     # its dark outline — what really separates it

## The tile ramp as the *board* draws it.
##
## Fold.tile_color is the shipped page's PAL, kept byte-exact because it is the rules
## file's and the conformance fixture's business. The view has always drawn its own ramp
## on top of that, for the same reason it always did: the page's ramp is built for a flat
## dark background and this is a lit board.
##
## The new ramp is candy, and it *climbs* — sky blue through mint and lime into sunshine,
## orange and finally pink at 256, so a player reads progress by hue alone before they
## read the number. Every step stays light enough for dark ink, which keeps the worst
## number/tile contrast at 6.0:1 across the whole ramp.
##
## Saturation was a second pass, off a captured frame. The first bright ramp ran from
## #C9ECFF to #FFB3D2 — pale enough to clear every contrast target comfortably, and in the
## shot the low tiles read as grey paper rather than as candy. There was headroom (the
## worst ink/tile was 8.19 against a target of 4.5), so the whole ramp was pushed a long
## way up in chroma and the tray went a shade deeper to pay for it.
const TILE_FACES := {
	2: Color("8BD8FF"), 4: Color("5FC4FF"), 8: Color("4FDCC4"), 16: Color("9AE85C"),
	32: Color("FFD52E"), 64: Color("FFAE4A"), 128: Color("FF8878"), 256: Color("FF7FB8"),
}


static func tile_face(v: int) -> Color:
	return TILE_FACES.get(v, TILE_FACES[256])


## Every tile is light, so every number on one is dark. One ink for the whole ramp now:
## the old file split blue-black from brown-black to keep each number "belonging" to its
## tile, and on a candy ramp that reads as an inconsistency rather than as care — the
## numbers are a single voice and the tile is what changes.
static func tile_number_ink(_v: int) -> Color:
	return INK


## The tile ramp lives with the rules (Fold.tile_color), because the conformance test
## reads it; these two forward to it so a view never has to know that.
static func tile(v: int) -> Color:
	return Fold.tile_color(v)


static func tile_ink(v: int) -> Color:
	return Fold.tile_ink(v)


## How much light a piece throws: the hot end of the ramp glows, the cool end does not.
static func tile_glow(v: int) -> float:
	if v >= 128:
		return 1.0
	if v >= 32:
		return 0.7
	if v >= 16:
		return 0.45
	return 0.12


## The three stars, lit and unlit. The unlit star is opaque and a colour of its own, so a
## one-star row still reads as "three slots, two to win" and not as "no stars here".
static func star_color(lit: bool) -> Color:
	return GOLD if lit else Color("D9CCB4")


# ---- measuring the above ------------------------------------------------------------------

## sRGB relative luminance, WCAG 2.1.
static func luminance(c: Color) -> float:
	var ch := [c.r, c.g, c.b]
	var lin := []
	for v in ch:
		lin.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


## WCAG contrast ratio between two opaque colours, 1.0 .. 21.0.
static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## A surface as it actually reaches the screen: the Palette colour times the plate's mean.
## Everything the board tints goes through here before it is measured, so the test is
## about the rendered board and not about the constants.
static func rendered(c: Color) -> Color:
	return Color(minf(1.0, c.r * SURFACE_GAIN), minf(1.0, c.g * SURFACE_GAIN),
		minf(1.0, c.b * SURFACE_GAIN), c.a)


## The playfield's legibility targets, as data, so run_tests.gd can assert them and a
## future repaint cannot quietly dim the board again. Each entry is
## [label, foreground, background, minimum ratio].
##
## Tiles, wells, walls and the tray are all `rendered()`; a number is a Label drawn by the
## engine over the top and takes no plate, which is why the ink is passed raw.
static func legibility_targets() -> Array:
	var out := []
	var tray := rendered(TABLE)
	for v in TILE_FACES.keys():
		out.append(["tile %d on the tray" % v, rendered(TILE_FACES[v]), tray, 3.0])
		out.append(["the %d's number on its tile" % v, tile_number_ink(v), rendered(TILE_FACES[v]), 4.5])
	out.append(["an empty well on the tray", rendered(WELL), tray, 2.0])
	out.append(["a wall on the tray", rendered(WALL_FACE), tray, 3.0])
	out.append(["a wall's outline on the tray", rendered(WALL_EDGE), tray, 1.5])
	# the deliberate one: see the caveat above. Asserted at 1.1 so that if a future ramp
	# edit pushes a tile *onto* the wall's exact value, a test still says so.
	out.append(["a wall against the brightest tile", rendered(WALL_FACE), rendered(TILE_FACES[32]), 1.1])
	out.append(["the tray against the page", tray, GROUND, 1.3])
	out.append(["body text on a card", TEXT, PANEL, 4.5])
	out.append(["muted text on the ground", MUTED, GROUND, 4.5])
	out.append(["HUD text on the ground", TEXT, GROUND, 4.5])
	return out

## Palette — FOLD's colours, one place.
##
## The studio convention is play/overtime-idle-godot/scripts/palette.gd: a `Palette` class
## with role names, and `StudioTheme.build()` reading those roles, so the two files drop
## into any fork. The *roles* are shared; the hues are this title's own, and they are not
## the adult forks' plum-and-magenta — FOLD is mainstream, quiet, and the wrong colour
## would be the loudest thing about it.
##
## FOLD's world is a lacquered board in a dark room: pine-black ground (green-black, warm
## in the shadows, never neutral grey), a gold leaf line that is the only bright thing,
## and paper. It is lifted from the shipped page's own CSS variables — --bg #0b0e0d,
## --gold #c7a45a, --paper #e8e2d3 — deepened a shade for a lit 2.5D board, where a flat
## web background has to become a floor with light falling on it.
##
## ACCENT is gold, not magenta: in this title the thing to press and the thing that is
## precious are the same thing, and there is no second accent competing with it. HEAT is
## jade — the colour a piece goes the instant it merges, the only cool note allowed.
class_name Palette

# ---- the studio's role table, in FOLD's hues ------------------------------------------
const GROUND := Color("0B0E0D")        # pine-black: the room the board sits in
const PANEL := Color("141816")
const PANEL_EDGE := Color("2A302C")
# The page's --gold is #c7a45a, and at button size on a dark ground it reads brown rather
# than gold. The web build knew this: its .btn.gold is a gradient from #e6bd63 down to
# #d09a3c, i.e. a good deal brighter than the line colour. ACCENT is that brighter gold;
# GOLD stays the page's value, which is right for a hairline and a small star.
const ACCENT := Color("E3B85C")        # gold leaf, lit: the button, the crease, the star
const GOLD := Color("C7A45A")        # the page's --gold: rules, hairlines, small marks
const HEAT := Color("6FB8A0")          # jade: a merge landing, a hint, "closer"
const SUCCESS := Color("7FBF8A")
const TEXT := Color("ECE9DF")          # warm off-white; never pure white
const MUTED := Color("92988F")         # sage-grey, the page's --dim
const COMMON := Color("5B7BBA")        # the tile ramp's blue
const RARE := Color("C98A3E")
const EPIC := Color("EFD98F")

# derived, still on the same hues
const GROUND_DEEP := Color("050706")
const PANEL_RAISED := Color("1C2220")
const PANEL_TOP := Color("232A27")
const ACCENT_DEEP := Color("B0842C")
const ACCENT_SOFT := Color("F0CE7E")
const GOLD_DEEP := Color("8E6F33")
const GOLD_PALE := Color("EFDCA8")
const HEAT_DEEP := Color("3E7C69")
const INK := Color("101411")           # text on paper
const INK_SOFT := Color("4A5248")
const PAPER := Color("E8E2D3")
const PAPER_ALPHA := 0.94

# ---- the sibling files' names, resolved onto the table above ---------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("3C443E")
const LINE_SOFT := Color("1E2421")
const LAMP := GOLD_PALE
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("8A6F3C")
const CREAM := TEXT
const PARCHMENT := PAPER
const DIM := MUTED
const FAINT := Color("5A625A")
const PAPER_PLAYER := PAPER
const PAPER_GRAY := Color("D8D3C4")
const GREEN := SUCCESS
const GREEN_DEEP := Color("4E8A5C")
const RARE_TEXT := Color("E0B356")
const EPIC_TEXT := GOLD_PALE
const RED := Color("B4604C")
const RED_TEXT := Color("D98A72")
const RED_DIM := Color("5A322A")
const PLUM := Color("1A2320")           # the theme-colour for the web page's chrome

## The board's own surfaces, which are not UI: the cell wells the pieces sit in, and the
## hatched blocks that never move.
const CELL := Color("202622")
const CELL_DEEP := Color("161A18")
const WALL := Color("2C313D")
const WALL_ALT := Color("262A34")


## The tile ramp lives with the rules (Fold.tile_color), because the conformance test
## reads it; these two forward to it so a view never has to know that.
static func tile(v: int) -> Color:
	return Fold.tile_color(v)


static func tile_ink(v: int) -> Color:
	return Fold.tile_ink(v)


## How much light a piece throws: the gold end of the ramp glows, the blue end does not.
## Used by the board's Light2D pass — a 256 tile is the brightest thing on the table.
static func tile_glow(v: int) -> float:
	if v >= 128:
		return 1.0
	if v >= 32:
		return 0.7
	if v >= 16:
		return 0.45
	return 0.12


## The three stars, lit and unlit.
static func star_color(lit: bool) -> Color:
	return GOLD if lit else Color(MUTED, 0.35)

## Palette — FOLD: After Dark's colours, one place.
##
## The fork of play/fold-godot/scripts/palette.gd. Same role table, same API, same
## measured-contrast discipline; a different world. FOLD is a toy box in the sun. After
## Dark is the same board after the lights went down: ops/adult_forks/UI_DIRECTION.md —
## dark ground, hot accents. Plum-black, magenta, gold, coral. The eye lands on skin, gold
## and magenta, in that order, and never on grey.
##
## A screenshot of the two must not be mistaken for each other. The ramp is the tell: FOLD
## climbs sky → mint → sunshine → pink; After Dark climbs violet → magenta → coral → gold →
## bone, a heat ramp, so the tile you are working toward is the hottest thing on the tray.
##
## Every target at the bottom is still asserted by tests/run_tests.gd. Dark is a choice,
## not a default, and the playfield still answers to legibility first
## (ops/adult_forks/TITLE_SCREENS.md).
class_name Palette

# ---- the studio's role table, in After Dark's hues -------------------------------------
const GROUND := Color("12080F")        # plum-black: warmth under everything, never neutral
const PANEL := Color("1E1017")
const PANEL_EDGE := Color("3A1F2E")
const ACCENT := Color("FF3D8A")        # hot magenta: the one thing to press
const GOLD := Color("FFB347")          # warm gold: the trophy, numbers that go up
const HEAT := Color("FF6F61")          # coral: the streak, "closer"
const SUCCESS := Color("4ADE80")       # only "earned / unlocked"
const TEXT := Color("FFF4EC")          # warm off-white; never pure white
const MUTED := Color("B78AA0")         # mauve, not grey — 6.7:1 on the ground
const COMMON := Color("9FB3C8")
const RARE := Color("C084FC")
const EPIC := Color("FFD166")

# derived, on the same hues
const GROUND_DEEP := Color("0B0409")
const PANEL_RAISED := Color("2A1622")
const PANEL_TOP := Color("321A2A")
const ACCENT_DEEP := Color("FF6FAE")   # on a dark ground "deep" means *hotter*, not darker:
                                       # it is used for hover text and the HUD level name
const ACCENT_SOFT := Color("FF7FB5")
const GOLD_DEEP := Color("FFC870")
const GOLD_PALE := Color("5A2E3E")     # the pressed button ground
const HEAT_DEEP := Color("FF8A7A")
const INK := Color("1A0812")           # text on paper and on a tile
const INK_SOFT := Color("4A2438")
const PAPER := Color("FFF4EC")         # her speech panel: warm paper, the one bright surface
const PAPER_ALPHA := 0.92

# ---- the sibling files' names, resolved onto the table above ---------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("5A2E3E")
const LINE_SOFT := Color("2A1622")
const LAMP := Color("FF9AC4")          # the lamp is pink now
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("E0A62E")
const CREAM := PAPER
const PARCHMENT := PAPER
const DIM := MUTED
const FAINT := Color("7A5A6C")
const PAPER_PLAYER := PAPER
const PAPER_GRAY := Color("2A1622")
const GREEN := SUCCESS
const GREEN_DEEP := Color("2FBF66")
const RARE_TEXT := Color("D9A6FF")
const EPIC_TEXT := Color("FFD166")
const RED := Color("FF5A6E")
const RED_TEXT := Color("FF8A98")
const RED_DIM := Color("4A1A24")
const PLUM := Color("12080F")          # the theme-colour for the web page's chrome

## The board's own surfaces.
const CELL := Color("3A1830")
const CELL_DEEP := Color("2A1022")
const WALL := Color("D9B8C9")
const WALL_ALT := Color("C4A2B5")


# ---- the playfield ---------------------------------------------------------------------
#
# The tray is a wine-dark table on a plum-black page. That is the hard case for the
# legibility rule — a dark board on a dark page — and it holds because (a) the tray is
# measurably lighter than the page (1.45:1 as picked, 1.37:1 as rendered through the
# plate's 0.92 gain), (b) it carries a hot magenta rail, and (c) every tile on it is a
# light, saturated object with dark ink on it. Targets and what they score are asserted
# in tests/run_tests.gd; the numbers below were re-picked until every one clears as
# rendered, the same way the parent's were.
const SURFACE_GAIN := 0.92
const TABLE := Color("52243F")         # the wine tray — lifted a step so its dark outline still clears 1.5:1
const TABLE_DEEP := Color("34152C")
const TABLE_RAIL := Color("FF3D8A")    # the magenta lip: where the board stops
const WELL := Color("9A5A88")          # an empty cell: a lit mauve recess — 2.6:1 on the tray as rendered
const WELL_LIP := Color("FF9AC4")
const WALL_FACE := Color("D9B8C9")     # the block that never moves: pale rose, raised
const WALL_EDGE := Color("0B0409")

## The update packs' board looks (a level's "look", ops/nutaku/fold_f2p/gen_levels.py PACKS):
## one bright, saturated key colour per pack. It lights the room plate and the tray's lip,
## and tints the room wash and the tray itself; the tray keeps TABLE's depth so every tile
## still clears 3:1 on it (asserted in tests/run_tests.gd `_looks`). Memory
## `bright-is-what-sells`: key colours at value >= 0.85 and saturation >= 0.45.
const LOOKS := {
	"greenhouse": Color("3DDC84"),     # leaf green
	"patisserie": Color("FF7EB6"),     # strawberry icing
	"rooftop": Color("29C5F6"),        # pool water in full sun
	"frost": Color("8AD8FF"),          # ice blue
	"observatory": Color("A78BFF"),    # violet dusk
	"music": Color("FFB547"),          # brass
}


static func has_look(look: String) -> bool:
	return LOOKS.has(look)


## The tray under a pack's boards: TABLE's darkness, the pack's hue.
static func look_tray(look: String) -> Color:
	if not LOOKS.has(look):
		return TABLE
	var k: Color = LOOKS[look]
	# 0.85 of the house tray's value: a green at TABLE.v is lighter than wine (2.90:1 under
	# the 3:1 tile floor, caught by run_tests `_looks`)
	return Color.from_hsv(k.h, clampf(k.s * 0.85, 0.45, 0.8), TABLE.v * 0.85)


## The room wash over bg_far under a pack's boards (GROUND's depth, the pack's hue).
static func look_wash(look: String) -> Color:
	if not LOOKS.has(look):
		return GROUND
	var k: Color = LOOKS[look]
	return Color.from_hsv(k.h, 0.7, 0.16)


## The room plate's tint and the tray's lip: the key colour itself, bright.
static func look_key(look: String) -> Color:
	return LOOKS.get(look, TABLE_RAIL)

## The heat ramp. Light enough for dark ink on every step (worst ink/tile is well over
## 4.5), and it climbs from cool violet through magenta and coral into gold and finally
## bone-white at 256 — the tile you are folding toward is the brightest thing on the tray.
const TILE_FACES := {
	2: Color("C9A0FF"), 4: Color("B07CFF"), 8: Color("FF8FD0"), 16: Color("FF6FA8"),
	32: Color("FF7A6B"), 64: Color("FFB347"), 128: Color("FFD166"), 256: Color("FFF4EC"),
}


static func tile_face(v: int) -> Color:
	return TILE_FACES.get(v, TILE_FACES[256])


static func tile_number_ink(_v: int) -> Color:
	return INK


static func tile(v: int) -> Color:
	return Fold.tile_color(v)


static func tile_ink(v: int) -> Color:
	return Fold.tile_ink(v)


## How much light a piece throws: the hot end of the ramp glows. In the dark it matters
## more than it did in daylight, so the ramp starts glowing earlier.
static func tile_glow(v: int) -> float:
	if v >= 128:
		return 1.0
	if v >= 32:
		return 0.8
	if v >= 8:
		return 0.5
	return 0.2


static func star_color(lit: bool) -> Color:
	return GOLD if lit else Color("5A2E3E")


# ---- measuring the above ------------------------------------------------------------------

static func luminance(c: Color) -> float:
	var ch := [c.r, c.g, c.b]
	var lin := []
	for v in ch:
		lin.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func rendered(c: Color) -> Color:
	return Color(minf(1.0, c.r * SURFACE_GAIN), minf(1.0, c.g * SURFACE_GAIN),
		minf(1.0, c.b * SURFACE_GAIN), c.a)


static func legibility_targets() -> Array:
	var out := []
	var tray := rendered(TABLE)
	for v in TILE_FACES.keys():
		out.append(["tile %d on the tray" % v, rendered(TILE_FACES[v]), tray, 3.0])
		out.append(["the %d's number on its tile" % v, tile_number_ink(v), rendered(TILE_FACES[v]), 4.5])
	out.append(["an empty well on the tray", rendered(WELL), tray, 2.0])
	out.append(["a wall on the tray", rendered(WALL_FACE), tray, 3.0])
	out.append(["a wall's outline on the tray", rendered(WALL_EDGE), tray, 1.5])
	out.append(["a wall against the brightest tile", rendered(WALL_FACE), rendered(TILE_FACES[256]), 1.1])
	out.append(["the tray against the page", tray, GROUND, 1.3])
	out.append(["body text on a card", TEXT, PANEL, 4.5])
	out.append(["muted text on the ground", MUTED, GROUND, 4.5])
	out.append(["HUD text on the ground", TEXT, GROUND, 4.5])
	return out

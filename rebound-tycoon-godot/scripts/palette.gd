## Palette — this title's own colours, under the studio's constant names, so
## studio_theme.gd (shared verbatim with play/beat-monday-godot and
## play/overtime-idle-godot) builds the same controls in this title's key.
##
## Key: a night gate. The ground is a deep midnight blue-black — the colour of wet
## asphalt under a sodium lamp, never neutral grey. Panels are a shade up, edged in
## brass. There are exactly two accents and each means one thing:
##   TEAL  — 老王 himself: his uniform, the water, the thing to press
##   GOLD  — money: coins, rent, rank, the skyline he is buying
## The hot coral is reserved for loss (a drained ball, the shift ending). Nothing pastel:
## the shipped JS build wore a candy skin that fought the character, and this does not.
class_name Palette

# ---- the spec's table ----------------------------------------------------------------
const GROUND := Color("0C1420")        # midnight asphalt, cool but blue not grey
const PANEL := Color("14202F")
const PANEL_EDGE := Color("2C4054")
const ACCENT := Color("2FD9C5")        # the water / the uniform: teal, the thing to press
const GOLD := Color("FFC24A")          # coins, rent, rank
const HEAT := Color("FF6B5B")          # a drain, the shift ending
const SUCCESS := Color("5AE08A")
const TEXT := Color("EEF6FB")
const MUTED := Color("7E93A8")
const COMMON := Color("9FB3C8")
const RARE := Color("7DD3FC")
const EPIC := Color("FFC24A")

# derived, still on the table's hues
const GROUND_DEEP := Color("060B12")
const PANEL_RAISED := Color("1C2C3F")
const PANEL_TOP := Color("24374D")
const ACCENT_DEEP := Color("12907F")
const ACCENT_SOFT := Color("7CEDDF")
const GOLD_DEEP := Color("C98A1E")
const GOLD_PALE := Color("FFE6AE")
const HEAT_DEEP := Color("C4453A")
const INK := Color("0F1A26")
const INK_SOFT := Color("445B70")
const PAPER := Color("EEF6FB")
const PAPER_ALPHA := 0.94

# the night's own light
const SODIUM := Color("FFB65C")        # the lamp over the booth: warm, low, always on
const NEON := Color("45E0FF")          # the skyline's sign light
const WATER := Color("8FF2FF")         # the jet, the spray, the saucer
const ASPHALT := Color("101A26")

# ---- the sibling's names (studio_theme.gd reads these) -------------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("3D5771")
const LINE_SOFT := Color("1B2A3A")
const LAMP := GOLD_PALE
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("A8803E")
const CREAM := TEXT
const PARCHMENT := TEXT
const DIM := Color("5E7387")
const FAINT := Color("34475A")
const PAPER_PLAYER := Color("E6F3FA")
const PAPER_GRAY := Color("DCE6EE")
const GREEN := SUCCESS
const GREEN_DEEP := Color("2B9A5C")
const RARE_TEXT := Color("BAE6FD")
const EPIC_TEXT := Color("FFE6AE")
const RED := HEAT_DEEP
const RED_TEXT := HEAT
const RED_DIM := Color("6E2E26")
const PLUM := Color("2C4054")

const PHASE := {}

## The four eras, each with the light it is lit in. The table, the backglass wash and the
## HUD rail all take their colour from here, so "the era went up" is visible without a
## word of text.
const ERA := {
	"booth":  {"key": Color("FFB65C"), "fill": Color("2A3648"), "rim": Color("7E93A8"), "glow": 0.25},
	"lobby":  {"key": Color("FFD089"), "fill": Color("2E3F55"), "rim": Color("A8803E"), "glow": 0.40},
	"towers": {"key": Color("9BE8FF"), "fill": Color("27405C"), "rim": Color("45E0FF"), "glow": 0.62},
	"neon":   {"key": Color("FFC24A"), "fill": Color("2A2246"), "rim": Color("FF6BD6"), "glow": 0.90},
}


static func era(id: String) -> Dictionary:
	return ERA.get(id, ERA["booth"])


static func rarity_color(_rarity: String, _kind: String = "") -> Color:
	return COMMON


static func rarity_text(_rarity: String, _kind: String = "") -> Color:
	return COMMON


static func rarity_glow(_rarity: String) -> float:
	return 0.0


static func glyph(_key: String) -> String:
	return "•"


static func label(key: String) -> String:
	return key.replace("_", " ")

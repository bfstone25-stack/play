## Palette — After Six's own colours, with the studio's constant names so studio_theme.gd
## (shared verbatim with the day game and the sibling titles) builds the same controls in
## this title's key.
##
## Key (ops/adult_forks/UI_DIRECTION.md, the night side of TWO_WORLDS): the same building
## after six. The ground is plum-black, never neutral; panels a shade up with a bruised
## edge; the one hot accent is magenta-pink — the thing to press, the lit window, the
## line she says — and gold is what goes up (XP, credits, the lamp). Coral is heat:
## momentum, closeness, damage. A screenshot must be tellable from the day game at a
## glance: no cyan tube light anywhere.
class_name Palette

# ---- the spec's table ----------------------------------------------------------------
const GROUND := Color("12080F")        # plum-black
const PANEL := Color("1E1017")
const PANEL_EDGE := Color("3A1F2E")
const ACCENT := Color("FF3D8A")        # hot magenta-pink
const GOLD := Color("FFB347")          # warm gold: XP, credits, the lamp
const HEAT := Color("FF6F61")          # coral: momentum, closer, damage
const SUCCESS := Color("4ADE80")
const TEXT := Color("FFF4EC")          # warm off-white
const MUTED := Color("B78AA0")         # mauve, not grey
const COMMON := Color("9FB3C8")
const RARE := Color("C084FC")
const EPIC := Color("FFD166")

const GROUND_DEEP := Color("0B0509")
const PANEL_RAISED := Color("2A1621")
const PANEL_TOP := Color("341C2A")
const ACCENT_DEEP := Color("B8225F")
const ACCENT_SOFT := Color("FF7AB0")
const GOLD_DEEP := Color("D08A2E")
const GOLD_PALE := Color("FFDCA3")
const HEAT_DEEP := Color("C4503B")
const INK := Color("160A11")
const INK_SOFT := Color("4A2A3C")
const PAPER := Color("FFF4EC")
const PAPER_ALPHA := 0.92

# the night's light: neon from the window, one desk lamp
const TUBE := Color("FF7AB0")          # the "tube" role is neon now
const TUBE_DIM := Color("9A4A72")
const CARPET := Color("1A0E16")
const GLASS := Color("C084FC")

# ---- the sibling's names ----------------------------------------------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("5A2F47")
const LINE_SOFT := Color("2A1520")
const LAMP := GOLD_PALE
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("9A7A3A")
const CREAM := TEXT
const PARCHMENT := TEXT
const DIM := Color("6E4A5E")
const FAINT := Color("3A2230")
const PAPER_PLAYER := Color("FFE9F1")
const PAPER_GRAY := Color("EAD8E0")
const GREEN := SUCCESS
const GREEN_DEEP := Color("2FA35A")
const RARE_TEXT := Color("E9D5FF")
const EPIC_TEXT := Color("FFE3A6")
const RED := HEAT_DEEP
const RED_TEXT := HEAT
const RED_DIM := Color("6E2A26")
const PLUM := Color("3A1F2E")

const PHASE := {}

## The night's pressures: the security round's torch and radio, the last train's crowd.
## Same foe ids as the day (the reflex core is shared); the colours are the night's.
const FOE := {
	"ping":   {"body": Color("FFB347"), "dark": Color("8A5A1E"), "mark": Color("FF3D8A")},
	"invite": {"body": Color("C084FC"), "dark": Color("5B2E8F"), "mark": Color("FF3D8A")},
	"thread": {"body": Color("FF6F61"), "dark": Color("8A2E28"), "mark": Color("B8225F")},
	"cc":     {"body": Color("E9D5FF"), "dark": Color("7C5AD6"), "mark": Color("4B2FA6")},
	"metric": {"body": Color("FFF4EC"), "dark": Color("9A4A72"), "mark": Color("FF3D8A")},
	"pager":  {"body": Color("2A1621"), "dark": Color("0B0509"), "mark": Color("FF6F61")},
}

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

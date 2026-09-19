## Palette — the studio's colours, one place. Dark bar/room, warm lamp, the parent's
## accents (play/silvertongue-x and the cards prototype share these hex values).
##
## Convention for the Godot forks: `Palette.X` for colour, `StudioTheme.build()` for the
## Theme. play/overtime-idle-godot is meant to reuse both files as-is.
class_name Palette

const ROOM := Color("141019")          # the room, behind everything
const ROOM_DEEP := Color("0e0b10")     # stage floor
const PANEL := Color("1a1418")
const PANEL_RAISED := Color("221a1e")
const PANEL_TOP := Color("211822")
const LINE := Color("3c3027")
const LINE_STRONG := Color("514434")
const LINE_SOFT := Color("2c2420")

const LAMP := Color("f0cd88")          # lamp light, headline gold
const AMBER := Color("e0a94e")         # accent, lit chips, active borders
const AMBER_DEEP := Color("d0913c")
const BRASS := Color("8a6a34")
const CREAM := Color("f0e9dd")         # body text on dark
const PARCHMENT := Color("f5ecd9")
const MUTED := Color("a89066")
const DIM := Color("8f7c62")
const FAINT := Color("5c5468")

const PAPER := Color("fdf9f0")         # her speech panel
const PAPER_PLAYER := Color("fff3d6")
const PAPER_GRAY := Color("d8d4cc")
const INK := Color("2a2018")
const INK_SOFT := Color("8a7860")

const GREEN := Color("7ac67a")         # energy, nerve, daily/free
const GREEN_DEEP := Color("4a9a4a")
const RARE := Color("6a8ad0")
const RARE_TEXT := Color("8fb0ff")
const EPIC := Color("c07ae0")
const EPIC_TEXT := Color("d8a0ff")
const RED := Color("b04030")
const RED_TEXT := Color("f08070")
const RED_DIM := Color("7a3a30")
const PLUM := Color("6f4f86")          # the parent's theme-color

## Phase treatments for the portrait: (saturation, brightness, tint colour, tint amount).
const PHASE := {
	"guarded":      {"sat": 0.45, "bright": 0.78, "tint": Color("14203a"), "amount": 0.30, "warm": 0.0},
	"engaged":      {"sat": 0.85, "bright": 0.95, "tint": Color("000000"), "amount": 0.15, "warm": 0.25},
	"wavering":     {"sat": 1.15, "bright": 1.02, "tint": Color("5a1e14"), "amount": 0.18, "warm": 0.6},
	"breakthrough": {"sat": 1.25, "bright": 1.08, "tint": Color("f0cd88"), "amount": 0.14, "warm": 1.0},
	"lost":         {"sat": 0.10, "bright": 0.60, "tint": Color("000000"), "amount": 0.45, "warm": 0.0},
}

static func rarity_color(rarity: String, kind: String = "") -> Color:
	if kind == "coercion":
		return RED
	match rarity:
		"rare": return RARE
		"epic": return EPIC
		"wild": return AMBER
	return BRASS

static func rarity_text(rarity: String, kind: String = "") -> Color:
	if kind == "coercion":
		return RED_TEXT
	match rarity:
		"rare": return RARE_TEXT
		"epic": return EPIC_TEXT
		"wild": return AMBER
	return MUTED

## Short glyphs for the engine's signal keys. No emoji: the fonts in the package are
## Latin serif/mono and an emoji face would double the download.
const GLYPH := {
	"warmth": "~", "respect": "=", "direct_request": "?", "empathy": "o", "accountability": "!",
	"exchange": "<>", "craft": "#", "precision": ".", "evidence": "¶", "safety": "+",
	"authority": "§", "calm_action": "-", "cooperation": "&", "riddle": "¿",
	"threat": "×", "bribe": "$", "insult": "×", "entitlement": "×",
}

static func glyph(key: String) -> String:
	return GLYPH.get(key, "•")

static func label(key: String) -> String:
	return key.replace("_", " ")

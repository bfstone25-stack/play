## Palette — the studio's colours, one place. ops/adult_forks/UI_DIRECTION.md, 2026-09-18:
## dark ground, hot accents. The ground is plum-black (warm, never neutral), the panels a
## shade up from it, and every accent is hot — magenta for the thing to press, gold for
## money and rarity, coral for anything that means *closer*. Grey does not appear.
##
## Convention for the Godot forks: `Palette.X` for colour, `StudioTheme.build()` for the
## Theme. The role names are the spec's table; the second block keeps the names
## play/silvertongue-cards-godot already uses, mapped onto the same hex values, so this
## file is a drop-in for it.
class_name Palette

# ---- the spec's table ----------------------------------------------------------------
const GROUND := Color("12080F")        # plum-black: warmth under everything
const PANEL := Color("1E1017")
const PANEL_EDGE := Color("3A1F2E")
const ACCENT := Color("FF3D8A")        # hot magenta-pink: buttons, active tabs, the pull button
const GOLD := Color("FFB347")          # warm gold: currency, rarity, numbers that go up
const HEAT := Color("FF6F61")          # coral: momentum, affection, anything that means closer
const SUCCESS := Color("4ADE80")       # green, kept only for "free / earned / confirmed"
const TEXT := Color("FFF4EC")          # warm off-white; never pure white
const MUTED := Color("B78AA0")         # mauve, not grey
const COMMON := Color("9FB3C8")        # rarity: thin steel
const RARE := Color("C084FC")          # rarity: violet, inner glow
const EPIC := Color("FFD166")          # rarity: gold, double edge, shine — always glows

# derived, still on the table's hues
const GROUND_DEEP := Color("0B0509")
const PANEL_RAISED := Color("281521")
const PANEL_TOP := Color("2E1826")
const ACCENT_DEEP := Color("C4235F")
const ACCENT_SOFT := Color("FF7DB0")
const GOLD_DEEP := Color("D98B1E")
const GOLD_PALE := Color("FFD9A0")
const HEAT_DEEP := Color("C94A3E")
const INK := Color("2A1220")           # text on paper
const INK_SOFT := Color("7A4A63")
const PAPER := Color("FFF4EC")         # her speech panel: warm paper, at 92% where it floats
const PAPER_ALPHA := 0.92

# ---- the sibling's names (play/silvertongue-cards-godot/scripts/palette.gd) ----------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("5A3147")
const LINE_SOFT := Color("2A1622")
const LAMP := GOLD_PALE                # lamp light, headline gold
const AMBER := GOLD                    # accent, lit chips, active borders
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("9A6A3A")
const CREAM := TEXT                    # body text on dark
const PARCHMENT := TEXT
const DIM := Color("8E6A7C")
const FAINT := Color("5A3F4E")
const PAPER_PLAYER := Color("FFE8DC")
const PAPER_GRAY := Color("E8D8DC")
const GREEN := SUCCESS
const GREEN_DEEP := Color("2FA35A")
const RARE_TEXT := Color("D9AEFF")
const EPIC_TEXT := Color("FFE29A")
const RED := HEAT_DEEP
const RED_TEXT := HEAT
const RED_DIM := Color("6E2A26")
const PLUM := Color("6F2F55")          # the studio's theme-colour

## Phase treatments for a portrait: (saturation, brightness, tint colour, tint amount).
## Kept for the sibling; the tints moved off blue onto the plum ground.
const PHASE := {
	"guarded":      {"sat": 0.50, "bright": 0.80, "tint": Color("2A1020"), "amount": 0.30, "warm": 0.0},
	"engaged":      {"sat": 0.90, "bright": 0.96, "tint": Color("000000"), "amount": 0.12, "warm": 0.25},
	"wavering":     {"sat": 1.15, "bright": 1.02, "tint": Color("7A1E3A"), "amount": 0.18, "warm": 0.6},
	"breakthrough": {"sat": 1.25, "bright": 1.08, "tint": Color("FFB347"), "amount": 0.14, "warm": 1.0},
	"lost":         {"sat": 0.15, "bright": 0.62, "tint": Color("000000"), "amount": 0.45, "warm": 0.0},
}


static func rarity_color(rarity: String, kind: String = "") -> Color:
	if kind == "coercion":
		return HEAT
	match rarity:
		"rare": return RARE
		"epic": return EPIC
		"wild": return GOLD
	return COMMON


static func rarity_text(rarity: String, kind: String = "") -> Color:
	if kind == "coercion":
		return HEAT
	match rarity:
		"rare": return RARE_TEXT
		"epic": return EPIC_TEXT
		"wild": return GOLD
	return COMMON


## The glow a rarity frame carries: alpha 0 for common (a thin steel line, no glow), soft
## violet for rare, and gold for epic — epic always glows.
static func rarity_glow(rarity: String) -> float:
	match rarity:
		"rare": return 0.45
		"epic": return 0.7
	return 0.0


## Short glyphs for the engine's signal keys. No emoji and no arrows: the three bundled
## faces are Latin (Lilita One, Nunito, Playfair Display Italic) and carry none.
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

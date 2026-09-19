## Palette — this title's own colours, with the studio's constant names so
## studio_theme.gd (shared verbatim with play/overtime-idle-godot and
## play/silvertongue-cards-godot) builds the same controls in this title's key.
##
## Key: a fluorescent office. The ground is Monday grey — cool, never black — panels a
## shade up from it with a cold cyan-white "tube light" edge; the one hot accent is the
## rant's coral-red, and it is reserved for the thing to press, damage, and the phrases
## that fly on Wednesday. XP and level land in amber. Nothing yellow, nothing pastel.
class_name Palette

# ---- the spec's table ----------------------------------------------------------------
const GROUND := Color("181B21")        # Monday grey, cool
const PANEL := Color("222630")
const PANEL_EDGE := Color("3A4152")
const ACCENT := Color("FF3B5C")        # the rant: coral-red, hot
const GOLD := Color("FFC857")          # amber: XP, level, numbers that go up
const HEAT := Color("FF7A59")          # damage flashes, boss bar
const SUCCESS := Color("4ADE80")
const TEXT := Color("F2F4F7")          # tube-light white
const MUTED := Color("8C95A6")         # slate, not mauve
const COMMON := Color("9FB3C8")
const RARE := Color("7DD3FC")
const EPIC := Color("FFC857")

const GROUND_DEEP := Color("0F1115")
const PANEL_RAISED := Color("2A2F3B")
const PANEL_TOP := Color("323848")
const ACCENT_DEEP := Color("C41E3F")
const ACCENT_SOFT := Color("FF7A91")
const GOLD_DEEP := Color("D9A03A")
const GOLD_PALE := Color("FFE3A6")
const HEAT_DEEP := Color("C4503B")
const INK := Color("1B1F27")
const INK_SOFT := Color("4A5468")
const PAPER := Color("F2F4F7")
const PAPER_ALPHA := 0.94

# fluorescent light, the office's own colour
const TUBE := Color("CFEFFF")          # cold tube light
const TUBE_DIM := Color("7FB3C9")
const CARPET := Color("2B3038")
const GLASS := Color("9CC7D8")

# ---- the sibling's names ----------------------------------------------------------------
const ROOM := GROUND
const ROOM_DEEP := GROUND_DEEP
const LINE := PANEL_EDGE
const LINE_STRONG := Color("4C5568")
const LINE_SOFT := Color("2C313C")
const LAMP := GOLD_PALE
const AMBER := GOLD
const AMBER_DEEP := GOLD_DEEP
const BRASS := Color("9A7A3A")
const CREAM := TEXT
const PARCHMENT := TEXT
const DIM := Color("6B7486")
const FAINT := Color("3E4554")
const PAPER_PLAYER := Color("E8F4FA")
const PAPER_GRAY := Color("DDE3EA")
const GREEN := SUCCESS
const GREEN_DEEP := Color("2FA35A")
const RARE_TEXT := Color("BAE6FD")
const EPIC_TEXT := Color("FFE3A6")
const RED := HEAT_DEEP
const RED_TEXT := HEAT
const RED_DIM := Color("6E2A26")
const PLUM := Color("3A4152")

const PHASE := {}

## The office nuisances: each foe kind has its own colour family (the JS data.js hex is
## kept as the "seed" and these are the drawn shades around it).
const FOE := {
	"ping":   {"body": Color("7FA8FF"), "dark": Color("3B5FC7"), "mark": Color("FF3B5C")},
	"invite": {"body": Color("F1F3F6"), "dark": Color("5C6B87"), "mark": Color("FF3B5C")},
	"thread": {"body": Color("E8E4DA"), "dark": Color("9A3A33"), "mark": Color("C41E3F")},
	"cc":     {"body": Color("D8C8FF"), "dark": Color("7C5AD6"), "mark": Color("4B2FA6")},
	"metric": {"body": Color("F2F4F7"), "dark": Color("2FA37A"), "mark": Color("FF3B5C")},
	"pager":  {"body": Color("2A2F3B"), "dark": Color("11151B"), "mark": Color("FF8A3D")},
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

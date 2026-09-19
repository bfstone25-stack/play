## Palette — Cyber Fortune's own. Mainstream / SFW, so not the studio's hot-accent adult
## skin (ops/adult_forks/UI_DIRECTION.md): two rooms, one machine.
##   East (the slip tube): ink ground, lacquer red, gold leaf, incense smoke, paper.
##   West (the deck, the reader): deep violet, silver, candle light, parchment.
## Same API shape as the siblings' palette.gd (Palette.X, rank_color()).
class_name Palette

# ---- shared ground and text ------------------------------------------------------------
const INK := Color("141010")           # the ground under everything: warm ink, never neutral
const INK_DEEP := Color("0B0808")
const INK_SOFT := Color("221A18")      # panels
const INK_EDGE := Color("3A2C27")
const TEXT := Color("F3E9D8")          # warm off-white
const MUTED := Color("9C8F84")

# ---- East ------------------------------------------------------------------------------------
const LACQUER := Color("A8231F")       # the thing to press; the rank stamp
const LACQUER_DEEP := Color("6E1512")
const LACQUER_SOFT := Color("D24A3E")
const GOLD := Color("D9A441")          # gold leaf: merit, 大吉
const GOLD_PALE := Color("F0D290")
const GOLD_DEEP := Color("9A6E22")
const SMOKE := Color("C9BBA8")         # incense smoke, at low alpha
const PAPER := Color("F3E9D8")         # the slip
const PAPER_INK := Color("2A1F1A")     # text on paper
const PAPER_LINE := Color("C9B79A")
const WOOD := Color("6B4A2E")
const WOOD_LIGHT := Color("9C7248")
const WOOD_DARK := Color("3E2A18")

# ---- West ------------------------------------------------------------------------------------
const VIOLET := Color("1B1230")
const VIOLET_DEEP := Color("100A1E")
const VIOLET_SOFT := Color("2C1E4A")
const VIOLET_EDGE := Color("4A3870")
const SILVER := Color("C0C4CF")
const SILVER_DIM := Color("7E8290")
const CANDLE := Color("F2B65C")
const CANDLE_DEEP := Color("C77D2A")
const PARCHMENT := Color("EDE4D2")
const PARCHMENT_INK := Color("1E1728")

const SUCCESS := Color("7FB069")

## Rank colours: the six real ranks. 大吉 is gold leaf, the two 吉 warm, the 凶 pair cool
## and quiet — a 凶 is a thing you do something about, not an alarm.
const RANK := {
	"daji": Color("D9A441"), "zhongji": Color("D24A3E"), "xiaoji": Color("C98F5A"),
	"moji": Color("B8A98F"), "xiong": Color("6E7B8B"), "daxiong": Color("4B4F6B"),
}


static func rank_color(rank: String) -> Color:
	return RANK.get(rank, MUTED)


static func rank_text(rank: String) -> Color:
	match rank:
		"daji": return GOLD_PALE
		"zhongji": return Color("F0A090")
		"xiaoji": return Color("E8C9A0")
		"moji": return Color("D8CDB8")
		"xiong": return Color("AEBBC9")
	return Color("9DA2C4")

## Palette — GHOST CHANNEL's own colours, one place.
##
## The studio convention is `Palette.X` for colour and `StudioTheme.build()` for the Theme
## (play/overtime-idle-godot/scripts/palette.gd). The role *names* are that file's table so
## the shared idiom carries; the values are this title's own, because this title is not the
## plum-and-magenta boudoir the adult forks share — it is a radio relay station at night.
##
## The world decides the hues. A station has exactly four light sources and the palette is
## those four and nothing else:
##
##   the sea outside the glass   cold ink blue      the ground, and everything unlit
##   the desk lamp               amber              paper, the codebook, warmth, the human
##   the live channel            signal cyan        anything carrying a voice right now
##   the plot readout            phosphor green     instruments telling the truth
##
## and one colour that is not a light at all:
##
##   the ghost                   alarm magenta      the mimic, friendly fire, a lie
##
## Grey does not appear: unlit things go blue-steel, because they are lit by the sea.
## The five call-sign colours are NOT in this table — they come from the prototype's
## AGENTS list (GCRules.AGENTS) and must stay exactly what they were, because the roster,
## the plot markers and the conformance snapshots all agree on them.
class_name Palette

# ---- the four lights and the ghost ----------------------------------------------------
const GROUND := Color("060A10")          # the sea: cold ink, never neutral black
const PANEL := Color("0C131C")
const PANEL_EDGE := Color("1B2E3E")
const ACCENT := Color("2DF0F0")          # signal cyan: the live channel, the thing to press
const GOLD := Color("FFB347")            # the desk lamp: paper, the codebook, the score
const HEAT := Color("FF2D6F")            # alarm magenta: the ghost, friendly fire, a lie
const SUCCESS := Color("7CFF6B")         # phosphor: the plot, a check that passed
const TEXT := Color("DCE9F0")            # cold off-white; never pure white
const MUTED := Color("6E8496")           # blue-steel, not grey

# derived, still on those hues
const GROUND_DEEP := Color("02050A")
const PANEL_RAISED := Color("121E2A")
const PANEL_TOP := Color("1A2B3A")
const ACCENT_DEEP := Color("128F96")
const ACCENT_SOFT := Color("8FFBFB")
const GOLD_DEEP := Color("C97F26")
const GOLD_PALE := Color("FFE0B0")
const HEAT_DEEP := Color("A8154A")
const HEAT_SOFT := Color("FF7FA8")
const PHOS_DEEP := Color("2E8C3E")
const LINE := PANEL_EDGE
const LINE_STRONG := Color("2C4A62")
const LINE_SOFT := Color("122230")
const DIM := Color("4A6070")
const FAINT := Color("24384A")
const PAPER := Color("F0E2C8")           # the codebook card under the lamp
const INK := Color("2A2016")             # ink on that card

## The studio's theme-colour for this title (boot splash, the web page's <meta>).
const STATION := Color("0A1420")

## The five call-signs, exactly the prototype's hex. Keyed by agent id so a scene can ask
## for one without reaching into GCRules.AGENTS.
const CALLSIGN := {
	"viper": Color("2DF0F0"),
	"moth": Color("FF3DAD"),
	"hex": Color("F5D031"),
	"raven": Color("7CFF6B"),
	"quill": Color("FF8A3D"),
}


static func callsign(id: String) -> Color:
	return CALLSIGN.get(id, TEXT)


## A log row's colour by the prototype's class name ("", "sys", "bad").
static func log_color(cls: String) -> Color:
	match cls:
		"sys": return ACCENT
		"bad": return HEAT
	return TEXT

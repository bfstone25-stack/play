extends RefCounted
class_name Palette

## HOLDOVER's palette. The parent, Floor 13: Night Shift, has its own and they are not
## the same file — that was the single loudest thing wrong with this fork: it shipped the
## parent's art, the parent's interface and the parent's wordmark, so the two games were
## one build with the lights down. ops/STANDARD.md calls that out by name.
##
## The story the colour tells:
##
##   Floor 13   11:59 PM, the building still paying its power bill. Cold fluorescent
##              tubes, blue-steel shadows, cyan terminals, one red wound.
##   HOLDOVER   the lease has run out. The fluorescents are dead, the floor is on
##              emergency power, and the only light left is sodium from the stairwell and
##              the lift. Terminals burn magenta. Nothing here is blue.
##
## That is why the fork is BRIGHTER and more saturated than its parent rather than darker
## — "adult saturated, which is not the same as dark" (ops/STANDARD.md). Nutaku's horror
## bucket sells at 0.62 brightness / 0.38 saturation (ops/SHELF_STYLE.md); a fork that
## dimmed the parent would be walking away from the shelf it is on.
##
## The pixel plates in assets/pixel/ are the parent's geometry pushed through this same
## ramp by tools/palette_holdover.py — same building, different light — and the interface
## literals in hud.gd / game.gd / office_builder.gd were pushed through it too, so the art
## and the UI are one world. New colour goes HERE first; reach for a name, not a hex.

## The ground. Not black: an unlit room still has the lamp's colour in it.
const INK        := Color("#0a0603")
const PANEL      := Color("#160903")
const PANEL_SOFT := Color("#230e03")

## Sodium — the light the floor actually has. KEY is the lamp, GLOW is what it does to a
## surface, EMBER is the far end of the fall-off.
const KEY        := Color("#ffae3e")
const GLOW       := Color("#f2a83a")
const EMBER      := Color("#6a3002")

## Type. Warm greys, because a cold grey on this ground reads as a colour mistake.
const TEXT       := Color("#f7eae3")
const TEXT_SOFT  := Color("#bc9b89")
const PAPER      := Color("#f3e1d0")

## The accent. Floor 13's was a red wound; HOLDOVER's is magenta — the colour the
## terminals burn on emergency power, and the one thing on the floor that is not sodium.
## Held under full saturation on purpose: the interface is read for minutes at a time.
const ACCENT     := Color("#e00c5e")
const ACCENT_DIM := Color("#ce4170")
const ACCENT_HOT := Color("#f72a75")

## The one exception to "nothing here is blue, nothing here is green": the break room runs
## on a green emergency lamp, and the prose says so out loud. It is the only green in the
## game and it is a location, not a palette colour — see tools/grade_cg.py.
const EMERGENCY := Color("#4f7a3a")

## The lift indicator, which is also the wordmark (ops/title_logotypes.py :: holdover).
const LED_ON     := Color("#ffae3e")
const LED_OFF    := Color("#3a1e0e")
const BRASS      := Color("#78582c")

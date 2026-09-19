## Art — where the rendered plates are, and what stands in until they land.
##
## Every plate FOLD wants is a slot in ops/fold_art/fold_gen.py, rendered on the 3060
## through ops/render_queue.py and picked into assets/art/<slot>.png. Nothing here renders
## anything: this is the lookup, plus the stand-in a scene gets when a slot is not on disk
## yet.
##
## The stand-ins are deliberately NOT little drawings of the thing they replace. A hand-
## coded "paper texture" made of engine rectangles is exactly the look the brief is trying
## to get rid of, and worse, it is indistinguishable at a glance from a plate that did
## land, so nobody ever notices the render is missing. So a stand-in is a flat noise or
## gradient in the title's palette — good enough to light and composite, obviously not the
## final art — and `missing()` names every slot still waiting, which the title screen
## prints in the corner on a debug build and tests/headless_web.py reports.
class_name Art

const DIR := "res://assets/art/"

## slot -> what it is for, matching ops/fold_art/fold_gen.py's PLATES.
const SLOTS := {
	"key": "title screen key visual (1920x1080)",
	"bg_far": "parallax: the room behind everything",
	"bg_mid": "parallax: paper drifting between the room and the board",
	"table": "the lacquered surface the board sits on",
	"piece": "the folded-paper face of a playing piece",
	"wall": "the slate block that never moves",
	"foil": "gold leaf, the logotype's fill",
}

static var _cache := {}


static func has(slot: String) -> bool:
	return ResourceLoader.exists(DIR + slot + ".png")


static func missing() -> Array:
	var out := []
	for s in SLOTS.keys():
		if not has(s):
			out.append(s)
	return out


## The plate, or null. Callers that can compose without it should check for null rather
## than take a stand-in — a parallax layer of flat noise is worse than no layer.
static func plate(slot: String) -> Texture2D:
	if _cache.has(slot):
		return _cache[slot]
	var t: Texture2D = null
	if has(slot):
		t = load(DIR + slot + ".png")
	_cache[slot] = t
	return t


## The plate, or a flat stand-in in the palette. `tint` is the ground the stand-in sits on.
static func plate_or_stand_in(slot: String, tint: Color = Palette.PANEL, _detail: float = 12.0) -> Texture2D:
	var t := plate(slot)
	if t != null:
		return t
	var key := "stand_in:" + slot
	if _cache.has(key):
		return _cache[key]
	# A smooth two-stop gradient, not noise. The first build used seamless simplex noise
	# and every surface in the game read as television static under the lamp — worse than
	# a flat fill, and worse than an obviously-empty slot. A gradient takes light cleanly,
	# composites like a real plate will, and is unmistakably not finished art.
	var g := GradientTexture2D.new()
	g.gradient = _ramp(tint.lightened(0.10), tint.darkened(0.30))
	g.width = 256
	g.height = 256
	g.fill = GradientTexture2D.FILL_LINEAR
	g.fill_from = Vector2(0.15, 0.0)
	g.fill_to = Vector2(0.85, 1.0)
	_cache[key] = g
	return g


static func _ramp(a: Color, b: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	return g

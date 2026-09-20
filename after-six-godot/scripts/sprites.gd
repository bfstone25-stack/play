## Sprites — the drawn things. Every enemy, boss, character and icon in the game is vector
## art drawn here with CanvasItem draw calls, so it is crisp at any DPI, animates from the
## clock, and lives in git as text. Nothing here owns a number that matters: sizes come
## from the core's radii, motion from the core's positions; this file only decides what
## a "calendar invite" looks like when it comes for you.
##
## Conventions: `ci` is the CanvasItem drawing (the arena), `p` the centre, `t` the clock.
class_name Sprites

const SKIN := Color("F1C9A5")
const SKIN_DARK := Color("C9956B")
const HAIR := Color("2B2320")
const SHIRT := Color("DCE9F5")
const SHIRT_DARK := Color("9DB4CC")
const TROUSER := Color("2E3442")
const SHADOW := Color(0, 0, 0, 0.28)
const WHITE := Color("F7F9FC")
const PAPER := Color("EEF1F5")
const PAPER_LINE := Color("B9C2D0")
const INK := Color("1B1F27")

# ==== rendered actors =============================================================================
## 2026-09-18: the player, the colleagues and the bosses are rendered sprites when
## assets/art/sprite_<id>.webp exists (ops/beat_monday_art/beat_monday_gen.py sprites +
## pick), keyed out and cropped by the pipeline. The vector rigs below stay as the
## fallback so a missing render never leaves a hole on the plate. actor() draws the
## sprite to a height in px, feet at `p`, and tells the caller whether it did.
static var _tex: Dictionary = {}

static func tex(id: String) -> Texture2D:
	if _tex.has(id):
		return _tex[id]
	var path := "res://assets/art/sprite_%s.webp" % id
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[id] = t
	return t


static func has_actor(id: String) -> bool:
	return tex(id) != null


static func actor(ci: CanvasItem, id: String, p: Vector2, height: float, face: float = 1.0,
		tint := Color(1, 1, 1), bob := 0.0) -> bool:
	var tx := tex(id)
	if tx == null:
		return false
	var sz := tx.get_size()
	var s := height / sz.y
	var w := sz.x * s
	shadow(ci, p + Vector2(0, 2), w * 0.36, height * 0.06)
	ci.draw_set_transform(p + Vector2(0, -bob), 0.0, Vector2(s * (1.0 if face >= 0 else -1.0), s))
	ci.draw_texture_rect(tx, Rect2(Vector2(-sz.x / 2, -sz.y), sz), false, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


static func shadow(ci: CanvasItem, p: Vector2, rx: float, ry: float, a: float = 0.28) -> void:
	ci.draw_set_transform(p, 0.0, Vector2(rx, ry))
	ci.draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func rrect(ci: CanvasItem, r: Rect2, c: Color, radius: float = 3.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func rrect_line(ci: CanvasItem, r: Rect2, c: Color, radius: float = 3.0, w: float = 1.5) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(int(radius))
	sb.set_border_width_all(int(w))
	sb.border_color = c
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func poly(ci: CanvasItem, pts: PackedVector2Array, c: Color) -> void:
	ci.draw_colored_polygon(pts, c)


static func flash(c: Color, hit: float) -> Color:
	return c.lerp(Color.WHITE, clampf(hit, 0.0, 1.0) * 0.85)


# ==== the player ==================================================================================
## An office worker, 3/4 top-down, ~34 px tall. `walk` is 0..1 walk-cycle phase, `moving`
## scales the stride, `face` is -1 (left) / +1 (right), `hurt` 0..1 flashes and recoils.
static func player(ci: CanvasItem, p: Vector2, t: float, moving: float, face: float, hurt: float,
		lanyard: bool, headphones: bool) -> void:
	var stride := sin(t * 14.0) * moving
	var bob := absf(sin(t * 14.0)) * 2.0 * moving
	shadow(ci, p + Vector2(0, 14), 11, 4)
	var o := p + Vector2(0, -bob) + Vector2(-hurt * 3.0 * face, 0)
	# legs
	ci.draw_line(o + Vector2(-4, 4), o + Vector2(-4 + stride * 5.0, 14), TROUSER, 4.5)
	ci.draw_line(o + Vector2(4, 4), o + Vector2(4 - stride * 5.0, 14), TROUSER, 4.5)
	ci.draw_circle(o + Vector2(-4 + stride * 5.0, 15), 2.6, INK)
	ci.draw_circle(o + Vector2(4 - stride * 5.0, 15), 2.6, INK)
	# torso: shirt, rolled sleeves
	var shirt := flash(SHIRT, hurt)
	rrect(ci, Rect2(o + Vector2(-8, -8), Vector2(16, 15)), shirt, 4)
	ci.draw_line(o + Vector2(-8, -3), o + Vector2(-13 - stride * 3.0, 4), shirt, 4.0)
	ci.draw_line(o + Vector2(8, -3), o + Vector2(13 + stride * 3.0, 4), shirt, 4.0)
	ci.draw_circle(o + Vector2(-13 - stride * 3.0, 5), 2.3, SKIN)
	ci.draw_circle(o + Vector2(13 + stride * 3.0, 5), 2.3, SKIN)
	if lanyard:
		ci.draw_line(o + Vector2(-3, -8), o + Vector2(0, 2), Palette.ACCENT, 1.5)
		ci.draw_line(o + Vector2(3, -8), o + Vector2(0, 2), Palette.ACCENT, 1.5)
		rrect(ci, Rect2(o + Vector2(-2.5, 1), Vector2(5, 4)), WHITE, 1)
	else:
		ci.draw_line(o + Vector2(0, -8), o + Vector2(0, 3), SHIRT_DARK, 1.2)
	# head
	ci.draw_circle(o + Vector2(0, -15), 7.5, flash(SKIN, hurt))
	poly(ci, PackedVector2Array([o + Vector2(-7.5, -16), o + Vector2(-6, -21.5), o + Vector2(0, -23.5),
		o + Vector2(6, -21.5), o + Vector2(7.5, -16), o + Vector2(4, -18), o + Vector2(-3, -19)]), HAIR)
	if headphones:
		ci.draw_arc(o + Vector2(0, -15), 8.5, PI * 1.1, PI * 1.9, 12, INK, 2.2)
		rrect(ci, Rect2(o + Vector2(-10.5, -17), Vector2(4, 6)), INK, 2)
		rrect(ci, Rect2(o + Vector2(6.5, -17), Vector2(4, 6)), INK, 2)
	# eyes: looking where the thumb goes
	ci.draw_circle(o + Vector2(-2.5 + face * 1.2, -14.5), 1.1, INK)
	ci.draw_circle(o + Vector2(2.5 + face * 1.2, -14.5), 1.1, INK)
	if hurt > 0.3:
		ci.draw_line(o + Vector2(-4, -17.5), o + Vector2(-1, -16.5), INK, 1.2)
		ci.draw_line(o + Vector2(4, -17.5), o + Vector2(1, -16.5), INK, 1.2)


## A colleague, same rig, smaller, own outfit. id: intern | pm | hr.
static func colleague(ci: CanvasItem, p: Vector2, t: float, id: String, scale := 0.8) -> void:
	var s := scale
	var stride := sin(t * 10.0 + id.length())
	shadow(ci, p + Vector2(0, 12 * s), 9 * s, 3.5 * s)
	var o := p + Vector2(0, -absf(stride) * 1.5 * s)
	var top: Color
	var hair: Color
	match id:
		"intern": top = Color("6F8BFF"); hair = Color("6B3E2E")     # hoodie
		"pm": top = Color("2B2F3A"); hair = Color("1E1A1A")         # blazer
		_: top = Color("B9D8A8"); hair = Color("8C8C8C")            # cardigan
	ci.draw_line(o + Vector2(-3 * s, 4 * s), o + Vector2((-3 + stride * 4) * s, 12 * s), TROUSER, 3.5 * s)
	ci.draw_line(o + Vector2(3 * s, 4 * s), o + Vector2((3 - stride * 4) * s, 12 * s), TROUSER, 3.5 * s)
	rrect(ci, Rect2(o + Vector2(-7 * s, -7 * s), Vector2(14 * s, 13 * s)), top, 3)
	if id == "intern":
		ci.draw_arc(o + Vector2(0, -7 * s), 5 * s, PI, TAU, 8, top.darkened(0.25), 2.5 * s)
	if id == "pm":
		rrect(ci, Rect2(o + Vector2(6 * s, -4 * s), Vector2(6 * s, 8 * s)), Color("CFEFFF"), 1)  # tablet
	if id == "hr":
		rrect(ci, Rect2(o + Vector2(-12 * s, -2 * s), Vector2(7 * s, 9 * s)), Color("F5E6C8"), 1)  # folder
	ci.draw_circle(o + Vector2(0, -13 * s), 6.5 * s, SKIN)
	if id == "hr":
		ci.draw_arc(o + Vector2(0, -14 * s), 6.5 * s, PI * 1.05, PI * 1.95, 10, hair, 3 * s)
	else:
		poly(ci, PackedVector2Array([o + Vector2(-6.5 * s, -14 * s), o + Vector2(-5 * s, -19 * s), o + Vector2(0, -21 * s),
			o + Vector2(5 * s, -19 * s), o + Vector2(6.5 * s, -14 * s), o + Vector2(0, -16 * s)]), hair)
	ci.draw_circle(o + Vector2(-2 * s, -12.5 * s), 1.0 * s, INK)
	ci.draw_circle(o + Vector2(2 * s, -12.5 * s), 1.0 * s, INK)


# ==== the office nuisances ========================================================================
static func foe(ci: CanvasItem, f: Dictionary, t: float) -> void:
	var p := Vector2(f["x"], f["y"])
	var r: float = f["r"]
	var hit: float = f["hit"]
	var ph: float = f.get("seed", 0.0) * TAU
	match f["kind"]:
		"ping": _ping(ci, p, r, t + ph, hit)
		"invite": _invite(ci, p, r, t + ph, hit)
		"thread": _thread(ci, p, r, t + ph, hit)
		"cc": _cc(ci, p, r, t + ph, hit, Vector2(f.get("vx", 0.0), f.get("vy", 1.0)))
		"metric": _metric(ci, p, r, t + ph, hit)
		"pager": _pager(ci, p, r, t + ph, hit)
		_: ci.draw_circle(p, r, Color.MAGENTA)


## A Slack ping: a speech bubble with a tail and a red unread badge. Bobs, fast.
static func _ping(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float) -> void:
	var c: Dictionary = Palette.FOE["ping"]
	var bob := sin(t * 9.0) * 2.5
	shadow(ci, p + Vector2(0, r + 3), r * 0.9, r * 0.35)
	var o := p + Vector2(0, bob)
	var w := r * 2.2
	var h := r * 1.6
	rrect(ci, Rect2(o + Vector2(-w / 2, -h / 2 - 2), Vector2(w, h)), flash(c["body"], hit), 5)
	poly(ci, PackedVector2Array([o + Vector2(-4, h / 2 - 3), o + Vector2(2, h / 2 - 3), o + Vector2(-5, h / 2 + 4)]), flash(c["body"], hit))
	ci.draw_line(o + Vector2(-w / 2 + 4, -3), o + Vector2(w / 2 - 6, -3), c["dark"], 1.6)
	ci.draw_line(o + Vector2(-w / 2 + 4, 1), o + Vector2(w / 2 - 10, 1), c["dark"], 1.6)
	ci.draw_circle(o + Vector2(w / 2 - 2, -h / 2 - 1), 4.2, c["mark"])
	ci.draw_circle(o + Vector2(w / 2 - 2, -h / 2 - 1), 1.4, WHITE)


## A calendar invite: a page with a red header, a grid, the one blocked hour. Wobbles.
static func _invite(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float) -> void:
	var c: Dictionary = Palette.FOE["invite"]
	var rot := sin(t * 5.0) * 0.14
	shadow(ci, p + Vector2(0, r + 2), r * 0.85, r * 0.3)
	ci.draw_set_transform(p, rot, Vector2.ONE)
	var w := r * 1.9
	var h := r * 2.0
	rrect(ci, Rect2(Vector2(-w / 2, -h / 2), Vector2(w, h)), flash(c["body"], hit), 3)
	rrect(ci, Rect2(Vector2(-w / 2, -h / 2), Vector2(w, h * 0.3)), c["mark"], 3)
	ci.draw_circle(Vector2(-w * 0.28, -h / 2), 1.8, c["dark"])
	ci.draw_circle(Vector2(w * 0.28, -h / 2), 1.8, c["dark"])
	for i in 3:
		var y := -h / 2 + h * 0.3 + 3 + i * (h * 0.7 - 6) / 3.0
		ci.draw_line(Vector2(-w / 2 + 2, y), Vector2(w / 2 - 2, y), PAPER_LINE, 1.0)
	ci.draw_line(Vector2(-w / 6, -h / 2 + h * 0.3), Vector2(-w / 6, h / 2), PAPER_LINE, 1.0)
	ci.draw_line(Vector2(w / 6, -h / 2 + h * 0.3), Vector2(w / 6, h / 2), PAPER_LINE, 1.0)
	rrect(ci, Rect2(Vector2(-w / 6 + 1, -h / 2 + h * 0.3 + 4), Vector2(w / 3 - 2, h * 0.22)), Color(c["mark"], 0.85), 1)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A reply-all thread: envelopes stacked three deep, a red Re: Re: Re:. Turns slowly.
static func _thread(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float) -> void:
	var c: Dictionary = Palette.FOE["thread"]
	shadow(ci, p + Vector2(0, r + 3), r, r * 0.35)
	ci.draw_set_transform(p, sin(t * 2.2) * 0.25, Vector2.ONE)
	var w := r * 2.0
	var h := r * 1.3
	for i in range(2, -1, -1):
		var off := Vector2(-i * 3.0, i * 3.5)
		var body := flash(c["body"], hit).darkened(i * 0.12)
		rrect(ci, Rect2(off + Vector2(-w / 2, -h / 2), Vector2(w, h)), body, 2)
		ci.draw_line(off + Vector2(-w / 2, -h / 2), off + Vector2(0, 1), c["dark"], 1.4)
		ci.draw_line(off + Vector2(w / 2, -h / 2), off + Vector2(0, 1), c["dark"], 1.4)
	rrect(ci, Rect2(Vector2(w / 2 - 9, -h / 2 - 6), Vector2(14, 9)), c["mark"], 2)
	ci.draw_rect(Rect2(Vector2(w / 2 - 7, -h / 2 - 3), Vector2(10, 1.5)), WHITE)
	ci.draw_rect(Rect2(Vector2(w / 2 - 7, -h / 2), Vector2(6, 1.5)), WHITE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A cc: a paper plane, nose toward you, darting.
static func _cc(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float, dir: Vector2) -> void:
	var c: Dictionary = Palette.FOE["cc"]
	var ang := dir.angle() if dir.length() > 0.01 else 0.0
	shadow(ci, p + Vector2(0, r + 4), r * 1.1, r * 0.3, 0.2)
	ci.draw_set_transform(p + Vector2(0, sin(t * 12.0) * 1.5), ang, Vector2.ONE)
	var L := r * 2.4
	var body := flash(c["body"], hit)
	poly(ci, PackedVector2Array([Vector2(L / 2, 0), Vector2(-L / 2, -r * 0.9), Vector2(-L / 4, 0)]), body)
	poly(ci, PackedVector2Array([Vector2(L / 2, 0), Vector2(-L / 2, r * 0.9), Vector2(-L / 4, 0)]), body.darkened(0.18))
	poly(ci, PackedVector2Array([Vector2(L / 2, 0), Vector2(-L / 4, 0), Vector2(-L / 2, r * 0.35)]), c["dark"])
	ci.draw_line(Vector2(L / 2, 0), Vector2(-L / 4, 0), c["mark"], 1.2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A metric: a dashboard card, the line going the wrong way, a red arrow. Heavy, slow.
static func _metric(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float) -> void:
	var c: Dictionary = Palette.FOE["metric"]
	shadow(ci, p + Vector2(0, r + 3), r, r * 0.35)
	var o := p + Vector2(0, sin(t * 3.0) * 1.2)
	var w := r * 2.2
	var h := r * 1.7
	rrect(ci, Rect2(o + Vector2(-w / 2, -h / 2), Vector2(w, h)), flash(c["body"], hit), 4)
	var bx := -w / 2 + 5
	var bars := [0.35, 0.6, 0.8, 0.5, 0.25]
	for i in bars.size():
		var bh: float = bars[i] * (h - 10) * (1.0 + 0.08 * sin(t * 4.0 + i))
		var col: Color = c["dark"] if i < 3 else c["mark"]
		ci.draw_rect(Rect2(o + Vector2(bx + i * (w - 10) / 5.0, h / 2 - 4 - bh), Vector2((w - 10) / 5.0 - 2, bh)), col)
	# the arrow, down and to the right
	var a0 := o + Vector2(-w / 2 + 6, -h / 2 + 6)
	var a1 := o + Vector2(w / 2 - 6, h / 2 - 8)
	ci.draw_line(a0, a1, c["mark"], 2.2)
	poly(ci, PackedVector2Array([a1, a1 + Vector2(-7, -1), a1 + Vector2(-1, -7)]), c["mark"])


## A pager: the on-call beeper, antenna up, screen lit orange, shaking.
static func _pager(ci: CanvasItem, p: Vector2, r: float, t: float, hit: float) -> void:
	var c: Dictionary = Palette.FOE["pager"]
	var shake := Vector2(sin(t * 40.0) * 1.6, cos(t * 37.0) * 1.2)
	shadow(ci, p + Vector2(0, r + 3), r * 0.9, r * 0.35)
	var o := p + shake
	var w := r * 2.1
	var h := r * 1.5
	rrect(ci, Rect2(o + Vector2(-w / 2, -h / 2), Vector2(w, h)), flash(c["body"], hit), 4)
	rrect_line(ci, Rect2(o + Vector2(-w / 2, -h / 2), Vector2(w, h)), Color("4A5262"), 4, 1)
	ci.draw_line(o + Vector2(w / 2 - 4, -h / 2), o + Vector2(w / 2 - 2, -h / 2 - 8), Color("4A5262"), 2)
	var lit := 0.6 + 0.4 * (1.0 if fmod(t, 0.5) < 0.25 else 0.0)
	rrect(ci, Rect2(o + Vector2(-w / 2 + 4, -h / 2 + 4), Vector2(w - 8, h * 0.5)), Color(c["mark"], lit), 2)
	ci.draw_rect(Rect2(o + Vector2(-w / 2 + 6, -h / 2 + 7), Vector2(w * 0.5, 2)), Color(INK, 0.7))
	ci.draw_circle(o + Vector2(-w / 2 + 6, h / 2 - 5), 2, Color("4A5262"))
	ci.draw_circle(o + Vector2(-w / 2 + 12, h / 2 - 5), 2, Color("4A5262"))


# ==== the bosses ==================================================================================
static func boss(ci: CanvasItem, b: Dictionary, day_id: String, t: float) -> void:
	var p := Vector2(b["x"], b["y"])
	var hit: float = b["hit"]
	shadow(ci, p + Vector2(0, 44), 44, 14, 0.35)
	match day_id:
		"mon": _standup(ci, p, t, hit)
		"tue": _inbox(ci, p, t, hit)
		"wed": _allhands(ci, p, t, hit)
		"thu": _review(ci, p, t, hit)
		_: _deploy(ci, p, t, hit)


## THE STANDUP: a wall clock stuck at 9:00 with nine chairs circling it.
static func _standup(ci: CanvasItem, p: Vector2, t: float, hit: float) -> void:
	for i in 9:
		var a := t * 0.9 + i * TAU / 9.0
		var q := p + Vector2(cos(a), sin(a) * 0.6) * 50.0
		rrect(ci, Rect2(q + Vector2(-6, -5), Vector2(12, 10)), Color("3A4152"), 2)
		rrect(ci, Rect2(q + Vector2(-6, -9), Vector2(12, 4)), Color("4C5568"), 1)
	ci.draw_circle(p, 34, flash(WHITE, hit))
	ci.draw_arc(p, 34, 0, TAU, 48, INK, 3.5)
	for i in 12:
		var a := i * TAU / 12.0
		ci.draw_line(p + Vector2(cos(a), sin(a)) * 28, p + Vector2(cos(a), sin(a)) * (31 if i % 3 else 25), INK, 2 if i % 3 else 3)
	var tick := floorf(t * 2.0) * 0.05
	ci.draw_line(p, p + Vector2(0, -20), INK, 3.5)                       # hour: 12... it is always 9:00
	ci.draw_line(p, p + Vector2(-18, 0).rotated(tick), INK, 3.0)
	ci.draw_line(p, p + Vector2(0, -26).rotated(fmod(t, 60.0) / 60.0 * TAU), Palette.ACCENT, 1.5)
	ci.draw_circle(p, 3, Palette.ACCENT)


## THE INBOX: an envelope the size of a desk with a 999+ badge, letters sliding out.
static func _inbox(ci: CanvasItem, p: Vector2, t: float, hit: float) -> void:
	for i in 4:
		var q := p + Vector2(-30 + i * 20 + sin(t * 3 + i) * 4, 22 + i * 3)
		rrect(ci, Rect2(q, Vector2(24, 16)), PAPER.darkened(0.1 * i), 2)
	rrect(ci, Rect2(p + Vector2(-40, -26), Vector2(80, 54)), flash(PAPER, hit), 4)
	poly(ci, PackedVector2Array([p + Vector2(-40, -26), p + Vector2(40, -26), p + Vector2(0, 8)]), flash(Color("D5DBE5"), hit))
	ci.draw_line(p + Vector2(-40, -26), p + Vector2(0, 8), Color("8C95A6"), 2)
	ci.draw_line(p + Vector2(40, -26), p + Vector2(0, 8), Color("8C95A6"), 2)
	var badge := p + Vector2(38, -28)
	ci.draw_circle(badge, 15 + sin(t * 6) * 1.0, Palette.ACCENT)
	var f := StudioTheme.font("black")
	ci.draw_string(f, badge + Vector2(-14, 4), "999+", HORIZONTAL_ALIGNMENT_CENTER, 28, 10, WHITE)


## THE ALL-HANDS: a projector screen on a podium, a mic, the one slide.
static func _allhands(ci: CanvasItem, p: Vector2, t: float, hit: float) -> void:
	var cone := Color(Palette.TUBE, 0.10 + 0.04 * sin(t * 2.0))
	poly(ci, PackedVector2Array([p + Vector2(-12, -60), p + Vector2(12, -60), p + Vector2(70, 70), p + Vector2(-70, 70)]), cone)
	rrect(ci, Rect2(p + Vector2(-46, -44), Vector2(92, 58)), flash(WHITE, hit), 2)
	rrect_line(ci, Rect2(p + Vector2(-46, -44), Vector2(92, 58)), Color("3A4152"), 2, 2)
	ci.draw_rect(Rect2(p + Vector2(-48, -48), Vector2(96, 5)), Color("3A4152"))
	# the slide: a pie chart that is mostly "other"
	var cen := p + Vector2(-20, -15)
	ci.draw_circle(cen, 16, Color("CFD6E0"))
	var sweep := 1.2 + 0.4 * sin(t * 1.5)
	ci.draw_arc(cen, 8, -PI / 2, -PI / 2 + sweep, 16, Palette.ACCENT, 16)
	for i in 3:
		ci.draw_rect(Rect2(p + Vector2(4, -30 + i * 10), Vector2(34 - i * 8, 4)), Color("8C95A6"))
	# the podium and the mic
	rrect(ci, Rect2(p + Vector2(-16, 14), Vector2(32, 26)), Color("3A4152"), 3)
	ci.draw_line(p + Vector2(0, 14), p + Vector2(8, -2), Color("8C95A6"), 2)
	ci.draw_circle(p + Vector2(8, -3), 4, INK)


## THE REVIEW: the document about you, a red stamp turning.
static func _review(ci: CanvasItem, p: Vector2, t: float, hit: float) -> void:
	ci.draw_set_transform(p, sin(t * 1.3) * 0.05, Vector2.ONE)
	rrect(ci, Rect2(Vector2(-34, -46), Vector2(68, 92)), flash(PAPER, hit), 2)
	ci.draw_rect(Rect2(Vector2(-26, -38), Vector2(40, 5)), INK)
	for i in 9:
		ci.draw_rect(Rect2(Vector2(-26, -26 + i * 8), Vector2(52 - (i * 7) % 20, 2.5)), PAPER_LINE)
	ci.draw_rect(Rect2(Vector2(-26, 30), Vector2(30, 3)), Color("8C95A6"))
	ci.draw_set_transform(p + Vector2(10, 16), -0.35 + sin(t * 2.0) * 0.06, Vector2.ONE)
	ci.draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(Palette.ACCENT, 0.9), 3)
	ci.draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color(Palette.ACCENT, 0.9), 1.5)
	ci.draw_string(StudioTheme.font("black"), Vector2(-18, 3), "NEEDS", HORIZONTAL_ALIGNMENT_CENTER, 36, 8, Palette.ACCENT)
	ci.draw_string(StudioTheme.font("black"), Vector2(-18, 11), "WORK", HORIZONTAL_ALIGNMENT_CENTER, 36, 8, Palette.ACCENT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## THE FRIDAY DEPLOY: a server rack, every light the wrong colour.
static func _deploy(ci: CanvasItem, p: Vector2, t: float, hit: float) -> void:
	rrect(ci, Rect2(p + Vector2(-30, -48), Vector2(60, 96)), flash(Color("2A2F3B"), hit), 4)
	rrect_line(ci, Rect2(p + Vector2(-30, -48), Vector2(60, 96)), Color("4C5568"), 4, 2)
	for i in 6:
		var y := -42 + i * 15
		rrect(ci, Rect2(p + Vector2(-25, y), Vector2(50, 11)), Color("1B1F27"), 2)
		for j in 4:
			var on := fmod(t * (3.0 + i) + j * 0.7, 1.0) < 0.5
			var col := Palette.ACCENT if (i + j) % 3 else Color("FF8A3D")
			ci.draw_circle(p + Vector2(-19 + j * 7, y + 5.5), 2.2, col if on else Color("3A4152"))
		ci.draw_rect(Rect2(p + Vector2(12, y + 3), Vector2(10, 5)), Color("3A4152"))
	# smoke from the top
	for i in 3:
		var k := fmod(t * 0.6 + i * 0.33, 1.0)
		ci.draw_circle(p + Vector2(-10 + i * 10 + sin(t + i) * 6, -50 - k * 30), 6 + k * 10, Color(1, 1, 1, 0.16 * (1.0 - k)))


# ==== shots, picks ================================================================================
## The office reply: a paperclip dart.
static func shot(ci: CanvasItem, s: Dictionary) -> void:
	var p := Vector2(s["x"], s["y"])
	var v := Vector2(s["vx"], s["vy"])
	ci.draw_set_transform(p, v.angle(), Vector2.ONE)
	ci.draw_line(Vector2(-7, 0), Vector2(7, 0), Palette.TUBE, 3.0)
	ci.draw_line(Vector2(2, 0), Vector2(8, 0), WHITE, 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A rant phrase in flight: typography with weight, in the display face, hot.
static func rant_shot(ci: CanvasItem, s: Dictionary, font: Font) -> void:
	var p := Vector2(s["x"], s["y"])
	var v := Vector2(s["vx"], s["vy"])
	var age: float = s.get("age", 0.0)
	var pop := 1.0 + 0.35 * maxf(0.0, 1.0 - age * 6.0)
	var ang := v.angle()
	if ang > PI / 2 or ang < -PI / 2:
		ang += PI
	var text: String = s["text"]
	var size := 22
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
	ci.draw_set_transform(p, ang * 0.35, Vector2(pop, pop))
	ci.draw_string_outline(font, Vector2(-w / 2, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Palette.GROUND_DEEP)
	ci.draw_string(font, Vector2(-w / 2, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Palette.ACCENT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## An incoming bullet from the boss: a red "?" in a circle — the quick question.
static func foe_shot(ci: CanvasItem, s: Dictionary, t: float) -> void:
	var p := Vector2(s["x"], s["y"])
	ci.draw_circle(p, 7, Color(Palette.ACCENT, 0.9))
	ci.draw_circle(p, 7, Color(1, 1, 1, 0.25 + 0.25 * sin(t * 20)))
	ci.draw_string(StudioTheme.font("black"), p + Vector2(-6, 4), "?", HORIZONTAL_ALIGNMENT_CENTER, 12, 11, WHITE)


## A dropped phrase: a sticky note with a +, pulsing.
static func pick(ci: CanvasItem, pk: Dictionary, t: float) -> void:
	var p := Vector2(pk["x"], pk["y"])
	var a := 0.7 + 0.3 * sin(t * 8.0)
	ci.draw_set_transform(p, -0.15 + sin(t * 3.0) * 0.08, Vector2.ONE)
	rrect(ci, Rect2(Vector2(-11, -11), Vector2(22, 22)), Color(Palette.GOLD, a), 1)
	ci.draw_rect(Rect2(Vector2(-11, -11), Vector2(22, 4)), Color(Palette.GOLD_DEEP, a))
	ci.draw_line(Vector2(-5, 2), Vector2(5, 2), INK, 2.5)
	ci.draw_line(Vector2(0, -3), Vector2(0, 7), INK, 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ==== equipment and skill icons ===================================================================
## Drawn at `size` px square centred on p.
static func equip_icon(ci: CanvasItem, id: String, p: Vector2, size: float) -> void:
	var s := size / 40.0
	ci.draw_set_transform(p, 0.0, Vector2(s, s))
	match id:
		"stapler":
			rrect(ci, Rect2(Vector2(-16, -2), Vector2(32, 10)), Color("3A4152"), 3)
			rrect(ci, Rect2(Vector2(-16, -10), Vector2(30, 8)), Palette.ACCENT, 3)
			ci.draw_rect(Rect2(Vector2(-14, 8), Vector2(28, 3)), Color("8C95A6"))
		"headphones":
			ci.draw_arc(Vector2(0, 2), 14, PI, TAU, 20, Color("3A4152"), 4)
			rrect(ci, Rect2(Vector2(-18, -2), Vector2(8, 14)), INK, 3)
			rrect(ci, Rect2(Vector2(10, -2), Vector2(8, 14)), INK, 3)
			ci.draw_rect(Rect2(Vector2(-16, 1), Vector2(4, 8)), Palette.ACCENT)
			ci.draw_rect(Rect2(Vector2(12, 1), Vector2(4, 8)), Palette.ACCENT)
		"lanyard":
			ci.draw_line(Vector2(-8, -16), Vector2(0, 2), Palette.ACCENT, 3)
			ci.draw_line(Vector2(8, -16), Vector2(0, 2), Palette.ACCENT, 3)
			rrect(ci, Rect2(Vector2(-9, 0), Vector2(18, 14)), WHITE, 2)
			ci.draw_rect(Rect2(Vector2(-6, 4), Vector2(12, 2)), Color("8C95A6"))
			ci.draw_rect(Rect2(Vector2(-6, 8), Vector2(8, 2)), Color("8C95A6"))
		"chair":
			rrect(ci, Rect2(Vector2(-12, -18), Vector2(24, 18)), Color("3A4152"), 4)
			rrect(ci, Rect2(Vector2(-14, 0), Vector2(28, 8)), Color("4C5568"), 3)
			ci.draw_line(Vector2(0, 8), Vector2(0, 14), Color("8C95A6"), 3)
			ci.draw_line(Vector2(-12, 17), Vector2(12, 17), Color("8C95A6"), 3)
			ci.draw_rect(Rect2(Vector2(-8, -12), Vector2(16, 4)), Palette.ACCENT)
		"badge":
			rrect(ci, Rect2(Vector2(-14, -18), Vector2(28, 36)), Color("F2F4F7"), 3)
			ci.draw_rect(Rect2(Vector2(-14, -18), Vector2(28, 7)), Palette.ACCENT)
			ci.draw_circle(Vector2(0, -2), 6, SKIN)
			ci.draw_rect(Rect2(Vector2(-9, 8), Vector2(18, 2)), Color("8C95A6"))
			ci.draw_rect(Rect2(Vector2(-9, 12), Vector2(12, 2)), Color("8C95A6"))
		"coldbrew":
			rrect(ci, Rect2(Vector2(-10, -14), Vector2(20, 30)), Color(Palette.TUBE, 0.5), 3)
			rrect(ci, Rect2(Vector2(-8, -4), Vector2(16, 18)), Color("4A2C1A"), 2)
			ci.draw_line(Vector2(4, -18), Vector2(-2, 10), WHITE, 2)
		_:
			ci.draw_circle(Vector2.ZERO, 12, Palette.MUTED)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func skill_icon(ci: CanvasItem, id: String, p: Vector2, size: float) -> void:
	var s := size / 40.0
	ci.draw_set_transform(p, 0.0, Vector2(s, s))
	match id:
		"overtime":   # spite: a fist
			rrect(ci, Rect2(Vector2(-12, -8), Vector2(24, 20)), SKIN, 6)
			for i in 4:
				ci.draw_line(Vector2(-9 + i * 6, -8), Vector2(-9 + i * 6, 2), SKIN_DARK, 1.5)
			ci.draw_rect(Rect2(Vector2(-12, 12), Vector2(24, 6)), SHIRT)
		"boundary":   # a door, closed
			rrect(ci, Rect2(Vector2(-12, -18), Vector2(24, 36)), Color("6B4A2E"), 2)
			ci.draw_circle(Vector2(7, 2), 2.5, Palette.GOLD)
			rrect_line(ci, Rect2(Vector2(-8, -14), Vector2(16, 12)), Color("4A2C1A"), 1, 1.5)
		"caffeine":
			equip_icon(ci, "coldbrew", Vector2.ZERO, 40)
		"sneakers":
			poly(ci, PackedVector2Array([Vector2(-16, 6), Vector2(-10, -8), Vector2(2, -8), Vector2(16, 2), Vector2(16, 8), Vector2(-16, 8)]), WHITE)
			ci.draw_rect(Rect2(Vector2(-16, 6), Vector2(32, 4)), Palette.ACCENT)
			ci.draw_line(Vector2(-6, -6), Vector2(4, 0), Color("8C95A6"), 2)
		"delegate":   # an arrow handing it on
			ci.draw_line(Vector2(-16, 0), Vector2(10, 0), Palette.TUBE, 4)
			poly(ci, PackedVector2Array([Vector2(16, 0), Vector2(6, -8), Vector2(6, 8)]), Palette.TUBE)
			ci.draw_circle(Vector2(-16, 0), 5, SKIN)
		"mute":       # a bell with a line through it
			poly(ci, PackedVector2Array([Vector2(-10, 8), Vector2(-8, -6), Vector2(0, -12), Vector2(8, -6), Vector2(10, 8)]), Color("8C95A6"))
			ci.draw_rect(Rect2(Vector2(-13, 8), Vector2(26, 3)), Color("8C95A6"))
			ci.draw_line(Vector2(-14, -12), Vector2(14, 14), Palette.ACCENT, 3)
		"ccall":      # three envelopes
			for i in 3:
				var o := Vector2(-10 + i * 8, -6 + i * 4)
				rrect(ci, Rect2(o + Vector2(-9, -6), Vector2(18, 12)), PAPER.darkened(i * 0.1), 2)
				ci.draw_line(o + Vector2(-9, -6), o + Vector2(0, 1), Color("8C95A6"), 1.2)
				ci.draw_line(o + Vector2(9, -6), o + Vector2(0, 1), Color("8C95A6"), 1.2)
		_:
			ci.draw_circle(Vector2.ZERO, 12, Palette.MUTED)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ==== the drawn office (fallback ground under the plates, and the desk screen) ================
## A top-down office floor: carpet tiles, desk islands with monitors and chairs, a glass
## meeting-room wall. Used under the plate at low alpha, and alone when a plate is missing.
static func office(ci: CanvasItem, size: Vector2, day_id: String, t: float) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), Palette.CARPET)
	for x in range(0, int(size.x), 40):
		ci.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.035), 1)
	for y in range(0, int(size.y), 40):
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.035), 1)
	if day_id == "fri":
		for i in 4:
			var x := 30 + i * 100
			rrect(ci, Rect2(Vector2(x, 80), Vector2(60, 480)), Color("20242C"), 4)
			for j in 14:
				ci.draw_circle(Vector2(x + 10, 96 + j * 34), 2, Color("FF8A3D") if (i + j) % 2 else Palette.ACCENT)
		return
	if day_id == "wed":
		for r in 7:
			for c in 6:
				rrect(ci, Rect2(Vector2(40 + c * 60, 150 + r * 66), Vector2(40, 30)), Color("353B48"), 4)
		rrect(ci, Rect2(Vector2(60, 40), Vector2(300, 70)), Color("2B3140"), 2)
		rrect_line(ci, Rect2(Vector2(60, 40), Vector2(300, 70)), Color(Palette.TUBE, 0.35), 2, 2)
		ci.draw_rect(Rect2(Vector2(90, 58), Vector2(120, 6)), Color(Palette.TUBE, 0.2))
		ci.draw_rect(Rect2(Vector2(90, 72), Vector2(80, 6)), Color(Palette.TUBE, 0.15))
		return
	var desks := [Vector2(40, 120), Vector2(240, 120), Vector2(40, 330), Vector2(240, 330), Vector2(140, 500)]
	for d in desks:
		rrect(ci, Rect2(d, Vector2(140, 70)), Color("3B4250"), 5)
		rrect(ci, Rect2(d + Vector2(20, 12), Vector2(44, 28)), Color("161A21"), 2)
		rrect(ci, Rect2(d + Vector2(22, 14), Vector2(40, 24)), Color(Palette.TUBE, 0.35 + 0.05 * sin(t * 2 + d.x)), 1)
		rrect(ci, Rect2(d + Vector2(76, 10), Vector2(44, 28)), Color("161A21"), 2)
		rrect(ci, Rect2(d + Vector2(78, 12), Vector2(40, 24)), Color(Palette.TUBE, 0.3), 1)
		rrect(ci, Rect2(d + Vector2(30, 46), Vector2(80, 14)), Color("2A2F3B"), 2)
		rrect(ci, Rect2(d + Vector2(50, 80), Vector2(40, 34)), Color("30364A"), 8)
	ci.draw_rect(Rect2(Vector2(0, 60), Vector2(size.x, 3)), Color(Palette.GLASS, 0.5))
	ci.draw_rect(Rect2(Vector2(0, 0), Vector2(size.x, 60)), Color(Palette.GLASS, 0.08))


## The desk screen: a laminate desk seen from above, a monitor, a keyboard, a mug, three
## places where the kit lives (hand: beside the keyboard; desk: the chair / the badge
## reader; wear: the coat hook on the partition).
static func desk(ci: CanvasItem, size: Vector2, t: float) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), Palette.CARPET)
	rrect(ci, Rect2(Vector2(20, 52), Vector2(size.x - 40, 246)), Color("C9B79C"), 8)    # laminate
	rrect(ci, Rect2(Vector2(24, 56), Vector2(size.x - 48, 238)), Color("D8C7AC"), 6)
	for i in 10:
		ci.draw_line(Vector2(24, 70 + i * 24), Vector2(size.x - 24, 74 + i * 24), Color(0, 0, 0, 0.04), 1)
	# partition wall at the top, with the tube light
	rrect(ci, Rect2(Vector2(20, 16), Vector2(size.x - 40, 40)), Color("3A4152"), 4)
	ci.draw_rect(Rect2(Vector2(40, 22), Vector2(size.x - 80, 4)), Color(Palette.TUBE, 0.8 + 0.1 * sin(t * 30)))
	# monitor
	rrect(ci, Rect2(Vector2(130, 68), Vector2(160, 92)), Color("161A21"), 4)
	rrect(ci, Rect2(Vector2(136, 74), Vector2(148, 80)), Color("1D2431"), 2)
	for i in 5:
		ci.draw_rect(Rect2(Vector2(146, 84 + i * 13), Vector2(70 + (i * 37) % 50, 4)), Color(Palette.TUBE, 0.35))
	rrect(ci, Rect2(Vector2(192, 160), Vector2(36, 8)), Color("161A21"), 2)
	# keyboard, mouse, mug
	rrect(ci, Rect2(Vector2(135, 190), Vector2(150, 40)), Color("2A2F3B"), 4)
	for r in 3:
		for c in 12:
			ci.draw_rect(Rect2(Vector2(142 + c * 11.5, 196 + r * 11), Vector2(9, 8)), Color("3A4152"))
	rrect(ci, Rect2(Vector2(300, 194), Vector2(20, 30)), Color("2A2F3B"), 10)
	ci.draw_circle(Vector2(76, 210), 15, Color("F2F4F7"))
	ci.draw_circle(Vector2(76, 210), 11, Color("4A2C1A"))
	ci.draw_arc(Vector2(89, 210), 7, -PI / 2, PI / 2, 10, Color("F2F4F7"), 3)

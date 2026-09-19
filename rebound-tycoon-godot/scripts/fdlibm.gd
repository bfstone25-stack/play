class_name Fdlibm
## sin() and cos() the way V8 computes them, so the port can be bit-exact.
##
## Why this file exists. The conformance test (tests/) replays the shipped JS kernel's
## seeded runs against scripts/kernel.gd and compares doubles with `==`, no epsilon. With
## everything else exact, four runs out of seventy-two still drifted — by 1e-7 after fifty
## frames, from nothing at all before. The cause:
##
##   V8 does not call the system libm for sin/cos. It carries its own port of Sun's fdlibm
##   (src/base/ieee754.cc), and glibc's sin/cos are a *different*, more accurate
##   implementation. They disagree in the last ulp for about 6% of arguments — measured on
##   this box: 249 sin and 199 cos mismatches in 4000 samples over the flipper's range.
##
## One ulp is nothing until it is not: the only sin/cos in the kernel are the flipper's,
## and a flipper is a lever that multiplies a difference at the pivot into a difference at
## the tip, into a different angle off the bumper, into a ball that drains where the other
## did not. So the port carries fdlibm rather than rounding the comparison away.
##
## With this file in place the conformance run is 56,144 checks and zero failures, every
## double compared with `==`. It took three more findings to get there, all recorded where
## they bite: Godot's Vector2 is 32-bit (scripts/kernel.gd, LEFT_PIVOT), `x *= a / b` is
## not `x = x * a / b` (clamp_ball), and `x += A + B` is not `x = x + A + B` (hit_flipper).
##
## This is the sibling's `toFixed` trap one level down (play/overtime-idle-godot's note
## that JS ties round up and %.3f rounds to even) — same shape, same lesson: the language
## is not the runtime, and a plausible number is the dangerous kind of wrong.
##
## Ported from fdlibm's s_sin.c / s_cos.c / k_sin.c / k_cos.c / e_rem_pio2.c, restricted to
## finite arguments. The argument reduction's third iteration (|x| > 2^19 · π/2) is not
## reachable from any angle this game produces and is not carried.

## The polynomial coefficients and the pieces of π/2, as their exact IEEE-754 bit
## patterns rather than as decimal literals.
##
## This is not paranoia. Godot's decimal-to-double parser is not correctly rounded (the
## conformance transport hit the same thing: it reads "19.349999999999998" one ulp high),
## and a coefficient that is one ulp off makes a sin() that is *nearly* right — which is
## exactly the kind of wrong that survives every test written with an epsilon. Written
## out as decimals, this port was wrong for 76% of arguments; written as bits, zero.
static var _K := _consts()

## GDScript integers are signed 64-bit, so a bit pattern with the sign bit set cannot be
## written as one hex literal; the two 32-bit halves can.
static func _d(hi: int, lo: int) -> float:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_u32(0, lo)
	b.encode_u32(4, hi)
	return b.decode_double(0)

static func _consts() -> Dictionary:
	return {
		"S1": _d(0xbfc55555, 0x55555549),
		"S2": _d(0x3f811111, 0x1110f8a6),
		"S3": _d(0xbf2a01a0, 0x19c161d5),
		"S4": _d(0x3ec71de3, 0x57b1fe7d),
		"S5": _d(0xbe5ae5e6, 0x8a2b9ceb),
		"S6": _d(0x3de5d93a, 0x5acfd57c),
		"C1": _d(0x3fa55555, 0x5555554c),
		"C2": _d(0xbf56c16c, 0x16c15177),
		"C3": _d(0x3efa01a0, 0x19cb1590),
		"C4": _d(0xbe927e4f, 0x809c52ad),
		"C5": _d(0x3e21ee9e, 0xbdb4b1c4),
		"C6": _d(0xbda8fae9, 0xbe8838d4),
		"INVPIO2": _d(0x3fe45f30, 0x6dc9c883),
		"PIO2_1": _d(0x3ff921fb, 0x54400000),
		"PIO2_1T": _d(0x3dd0b461, 0x1a626331),
		"PIO2_2": _d(0x3dd0b461, 0x1a600000),
		"PIO2_2T": _d(0x3ba3198a, 0x2e037073),
	}


## high words of n·(π/2), n = 1..8 — fdlibm's npio2_hw
const NPIO2_HW := [0x3FF921FB, 0x400921FB, 0x4012D97C, 0x401921FB,
	0x401F6A7A, 0x4022D97C, 0x4025FDBB, 0x402921FB]

static var _buf := PackedByteArray()


## The top 32 bits of a double, as C's __HI does — SIGNED, because fdlibm tests `hx > 0`
## to find the sign of x. Reading it unsigned makes every negative argument take the
## positive branch, which is a plausible-looking wrong answer rather than a crash.
static func _hi(x: float) -> int:
	if _buf.size() != 8:
		_buf.resize(8)
	_buf.encode_double(0, x)
	return _buf.decode_s32(4)


static func _kernel_sin(x: float, y: float, iy: int) -> float:
	var ix := _hi(x) & 0x7fffffff
	if ix < 0x3e400000:                      # |x| < 2**-27
		if int(x) == 0:
			return x
	var z: float = x * x
	var v: float = z * x
	var r: float = _K["S2"] + z * (_K["S3"] + z * (_K["S4"] + z * (_K["S5"] + z * _K["S6"])))
	if iy == 0:
		return x + v * (_K["S1"] + z * r)
	return x - ((z * (0.5 * y - v * r) - y) - v * _K["S1"])


static func _kernel_cos(x: float, y: float) -> float:
	var ix := _hi(x) & 0x7fffffff
	if ix < 0x3e400000:                      # |x| < 2**-27
		if int(x) == 0:
			return 1.0
	var z: float = x * x
	var r: float = z * (_K["C1"] + z * (_K["C2"] + z * (_K["C3"] + z * (_K["C4"] + z * (_K["C5"] + z * _K["C6"])))))
	if ix < 0x3FD33333:                      # |x| < 0.3
		return 1.0 - (0.5 * z - (z * r - x * y))
	var qx: float
	if ix > 0x3fe90000:                      # |x| > 0.78125
		qx = 0.28125
	else:
		# qx = x/4, with the low word cleared — fdlibm builds it from the high word
		if _buf.size() != 8:
			_buf.resize(8)
		_buf.encode_u32(0, 0)
		_buf.encode_u32(4, ix - 0x00200000)
		qx = _buf.decode_double(0)
	var hz: float = 0.5 * z - qx
	var a: float = 1.0 - qx
	return a - (hz - (z * r - x * y))


## fdlibm __ieee754_rem_pio2, the branches a game angle can reach. Returns
## {"n": int, "y0": float, "y1": float}.
static func _rem_pio2(x: float) -> Dictionary:
	var hx := _hi(x)
	var ix := hx & 0x7fffffff
	var z: float
	var y0: float
	var y1: float
	if ix < 0x4002d97c:                      # |x| < 3π/4 — n is ±1
		if hx > 0:
			z = x - _K["PIO2_1"]
			if ix != 0x3ff921fb:
				y0 = z - _K["PIO2_1T"]
				y1 = (z - y0) - _K["PIO2_1T"]
			else:                            # near π/2: 33+33+53 bits
				z -= _K["PIO2_2"]
				y0 = z - _K["PIO2_2T"]
				y1 = (z - y0) - _K["PIO2_2T"]
			return {"n": 1, "y0": y0, "y1": y1}
		z = x + _K["PIO2_1"]
		if ix != 0x3ff921fb:
			y0 = z + _K["PIO2_1T"]
			y1 = (z - y0) + _K["PIO2_1T"]
		else:
			z += _K["PIO2_2"]
			y0 = z + _K["PIO2_2T"]
			y1 = (z - y0) + _K["PIO2_2T"]
		return {"n": -1, "y0": y0, "y1": y1}

	# medium size: |x| <= 2^19 · (π/2). Nothing in this game gets past it.
	var t: float = absf(x)
	var n := int(t * _K["INVPIO2"] + 0.5)
	var fn: float = float(n)
	var r: float = t - fn * _K["PIO2_1"]
	var w: float = fn * _K["PIO2_1T"]
	if n < 32 and ix != NPIO2_HW[n - 1]:
		y0 = r - w
	else:
		var j := ix >> 20
		y0 = r - w
		var i := j - ((_hi(y0) >> 20) & 0x7ff)
		if i > 16:                           # second iteration, more bits of π/2
			t = r
			w = fn * _K["PIO2_2"]
			r = t - w
			w = fn * _K["PIO2_2T"] - ((t - r) - w)
			y0 = r - w
	y1 = (r - y0) - w
	if hx < 0:
		return {"n": -n, "y0": -y0, "y1": -y1}
	return {"n": n, "y0": y0, "y1": y1}


static func sin(x: float) -> float:
	var ix := _hi(x) & 0x7fffffff
	if ix <= 0x3fe921fb:                     # |x| < π/4
		return _kernel_sin(x, 0.0, 0)
	if ix >= 0x7ff00000:
		return x - x                         # inf / NaN
	var rp := _rem_pio2(x)
	match int(rp["n"]) & 3:
		0: return _kernel_sin(rp["y0"], rp["y1"], 1)
		1: return _kernel_cos(rp["y0"], rp["y1"])
		2: return -_kernel_sin(rp["y0"], rp["y1"], 1)
	return -_kernel_cos(rp["y0"], rp["y1"])


static func cos(x: float) -> float:
	var ix := _hi(x) & 0x7fffffff
	if ix <= 0x3fe921fb:                     # |x| < π/4
		return _kernel_cos(x, 0.0)
	if ix >= 0x7ff00000:
		return x - x
	var rp := _rem_pio2(x)
	match int(rp["n"]) & 3:
		0: return _kernel_cos(rp["y0"], rp["y1"])
		1: return -_kernel_sin(rp["y0"], rp["y1"], 1)
		2: return -_kernel_cos(rp["y0"], rp["y1"])
	return _kernel_sin(rp["y0"], rp["y1"], 1)

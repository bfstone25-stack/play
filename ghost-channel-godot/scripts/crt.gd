## CRT — the static-and-scanline treatment, as one shader over the whole client.
##
## The brief asks for "a static/scanline treatment that belongs to a radio station", and the
## distinction that makes it belong rather than decorate is that it is *driven*: the noise
## floor sits low and almost still while the channel is quiet, lifts while a voice is on the
## air, and tears hard on the two moments the game wants the player's stomach to drop — a
## friendly-fire hit and the codebook being rewritten. A constant 40% scanline over
## everything is the "made by AI" look; a scanline that reacts is the console.
##
## Five things, in the order the shader applies them:
##   scanlines   fine horizontal rule at screen resolution, very low contrast
##   mask        a slow vertical roll bar, the way an unsynced monitor drifts
##   noise       per-pixel grain whose amount is `level`
##   tear        a horizontal band displaced sideways, fired by `tear()`
##   vignette    corners down; the tube is curved even if the geometry is not
extends ColorRect

const SHADER := """
shader_type canvas_item;

// Godot 4 reads the framebuffer through an explicit hinted uniform, not the old
// SCREEN_TEXTURE builtin.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float t = 0.0;
uniform float level = 0.10;        // noise floor, 0..1
uniform float tear = 0.0;          // 0..1, a band displaced sideways
uniform float tear_y = 0.5;
uniform float scan = 0.11;         // was 0.22
// 2026-09-21. The title measured 0.17 brightness against a 0.50 floor, and only part of
// that was the plate. Three multiplicative darkeners sit on top of whatever art lands:
// station.gd's CanvasModulate (x0.75), these scanlines (x0.89 on average at 0.22) and the
// vignette below (x0.82 on average at 0.85). Together they take a third off the frame
// before a single pixel of art is judged, so a plate that clears 0.50 on disk composes to
// 0.34 on screen. Halved rather than removed: the CRT treatment IS this game's look, and
// at 0.11 the scanlines are still plainly there in a still.
uniform vec4 tint : source_color = vec4(0.18, 0.94, 0.94, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// tear: a band of the picture slides sideways, the way a dropout looks
	float band = smoothstep(0.045, 0.0, abs(uv.y - tear_y));
	uv.x += band * tear * 0.06 * (hash(vec2(floor(t * 60.0), 3.0)) - 0.5) * 2.0;

	vec3 col = texture(screen_tex, uv).rgb;

	// the ghost: on a hard tear the channel splits into its two strikes, the same way
	// the logotype does. The picture and the title are the same effect at two scales.
	if (tear > 0.01) {
		float d = band * tear * 0.012;
		col.r = texture(screen_tex, uv + vec2(d, 0.0)).r;
		col.b = texture(screen_tex, uv - vec2(d, 0.0)).b;
	}

	// scanlines at screen resolution, so they do not crawl when the window resizes
	float line = 0.5 + 0.5 * sin(SCREEN_UV.y * (1.0 / SCREEN_PIXEL_SIZE.y) * 3.14159);
	col *= 1.0 - scan * line;

	// the roll bar: a soft lift drifting up the tube, ~9 s to cross
	float roll = fract(uv.y + t * 0.11);
	col += tint.rgb * 0.02 * smoothstep(0.985, 1.0, roll);

	// grain
	float n = hash(uv * vec2(1920.0, 1080.0) + vec2(t * 37.0, t * 17.0));
	col += (n - 0.5) * level * 0.5;
	col = mix(col, tint.rgb * dot(col, vec3(0.33)), level * 0.10);

	// vignette
	vec2 v = uv - 0.5;
	col *= 1.0 - dot(v, v) * 0.34;   // was 0.85; see the note on `scan`

	COLOR = vec4(col, 1.0);
}
"""

var _t := 0.0
var _tear := 0.0
var _level := 0.10
var _target := 0.10
var _mat: ShaderMaterial


func _ready() -> void:
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	material = _mat
	color = Color(1, 1, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)


## Where the noise floor rests. 0.06 is a quiet channel; 0.20 is a voice under weather.
func set_floor(v: float) -> void:
	_target = clampf(v, 0.0, 0.5)


## A dropout, now. `hard` for the two moments that are supposed to hurt.
func tear(hard: bool = false) -> void:
	_tear = 1.0 if hard else 0.45
	_mat.set_shader_parameter("tear_y", randf_range(0.15, 0.85))


func _process(delta: float) -> void:
	_t += delta
	_level = lerpf(_level, _target, minf(1.0, delta * 2.5))
	_tear = maxf(0.0, _tear - delta * 3.2)
	_mat.set_shader_parameter("t", _t)
	_mat.set_shader_parameter("level", _level + _tear * 0.25)
	_mat.set_shader_parameter("tear", _tear)

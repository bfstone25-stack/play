shader_type canvas_item;
// "Alive" pass for painted figures and CGs: the art itself is deformed in the shader (no
// drawn shapes). A breathing swell around the chest that also lifts the shoulders and head
// a hair, and a slow sway that grows with height above the feet (figures only). Every
// amplitude is scaled by `motion`, which Settings sets to 0 for players who turn motion off.

uniform float motion = 1.0;
uniform vec2 chest = vec2(0.5, 0.3);   // texture UV of the breathing centre
uniform float radius = 0.22;           // falloff, in units of texture height
uniform float breath_amp = 0.014;      // swell at the centre (fraction of the distance)
uniform float lift = 0.0035;           // upward travel of everything above the chest, in UV
uniform float rate = 0.24;             // breaths per second (~14 a minute)
uniform float sway = 0.0;              // horizontal travel at the top of the texture, in UV
uniform float sway_rate = 0.09;
uniform float phase = 0.0;             // per-character offset so two figures never breathe in step

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec2 sz = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 uv = UV;
	float br = 0.5 - 0.5 * cos(6.28318 * (TIME * rate) + phase);
	// swell: sample closer to the centre so the chest grows on the in-breath
	vec2 d = (UV - chest) * vec2(sz.x / sz.y, 1.0);
	float r = length(d / vec2(1.0, 1.3));
	float fall = 1.0 - smoothstep(0.0, radius, r);
	uv -= (UV - chest) * fall * breath_amp * br * motion;
	// lift: shoulders and head rise a little with the breath, fading out below the chest
	float above = smoothstep(chest.y + radius * 0.6, chest.y - radius * 0.2, UV.y);
	above *= 1.0 - smoothstep(radius * 0.9, radius * 1.8, abs(d.x));   // the body, not the room behind it
	uv.y += lift * br * above * motion;
	// sway: feet planted, the top drifts
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	uv.x -= sin(6.28318 * TIME * sway_rate + phase * 1.7) * sway * h * h * motion;
	COLOR = texture(TEXTURE, uv) * vcol;
}

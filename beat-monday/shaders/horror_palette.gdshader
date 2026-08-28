shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float red_wash : hint_range(0.0, 1.0) = 0.0;
uniform float blue_wash : hint_range(0.0, 1.0) = 0.35;
uniform float scanlines : hint_range(0.0, 0.5) = 0.12;
uniform float vignette : hint_range(0.0, 1.0) = 0.55;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 blood = vec3(0.89, 0.12, 0.08);
	vec3 eerie = vec3(0.12, 0.28, 0.95);
	float p = pulse * (0.5 + 0.5 * sin(TIME * 3.2));
	float scan = scanlines * step(0.55, fract(UV.y * 90.0 + TIME * 8.0));
	float vig = smoothstep(0.2, 1.05, distance(UV, vec2(0.5)));
	vec3 tint = mix(eerie, blood, clamp(red_wash + p * 0.5, 0.0, 1.0));
	float a = blue_wash * 0.18 + red_wash * 0.28 + scan * 0.22 + vig * vignette * 0.45 + p * 0.08;
	a = clamp(a, 0.0, 0.72);
	COLOR = vec4(tint, a);
}

shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.4) = 0.11;
uniform float lines : hint_range(0.0, 0.3) = 0.07;

void fragment() {
	float n = fract(sin(dot(UV * (TIME * 9.0 + 3.0), vec2(12.9898, 78.233))) * 43758.5453);
	float scan = 0.04 * sin(UV.y * 780.0 + TIME * 12.0);
	float vig = smoothstep(0.95, 0.25, distance(UV, vec2(0.5)));
	COLOR = vec4(vec3(n * grain + scan * lines), (1.0 - vig) * 0.55 + grain * 0.35);
}

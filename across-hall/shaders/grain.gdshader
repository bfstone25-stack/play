shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.4) = 0.06;
uniform float lines : hint_range(0.0, 0.3) = 0.03;

void fragment() {
	float n = fract(sin(dot(UV * (TIME * 9.0 + 3.0), vec2(12.9898, 78.233))) * 43758.5453);
	float scan = 0.03 * sin(UV.y * 780.0 + TIME * 12.0);
	float vig = smoothstep(0.2, 1.05, distance(UV, vec2(0.5)));
	COLOR = vec4(vec3(n * grain + scan * lines), vig * 0.22 + grain * 0.08);
}

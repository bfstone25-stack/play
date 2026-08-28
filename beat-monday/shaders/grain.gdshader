shader_type canvas_item;

uniform float grain : hint_range(0.0, 0.4) = 0.08;
uniform float lines : hint_range(0.0, 0.3) = 0.04;

void fragment() {
	float n = fract(sin(dot(UV * (TIME * 11.0 + 2.0), vec2(12.9898, 78.233))) * 43758.5453);
	float scan = lines * sin(UV.y * 640.0 + TIME * 14.0);
	float vig = smoothstep(0.25, 1.1, distance(UV, vec2(0.5)));
	COLOR = vec4(vec3(n * grain + scan), vig * 0.28 + grain * 0.1);
}

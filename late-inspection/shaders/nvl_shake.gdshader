shader_type canvas_item;

uniform float shake : hint_range(0.0, 8.0) = 2.4;
uniform float time = 0.0;

void vertex() {
	float t = time * 23.0;
	vec2 jitter = vec2(
		sin(t + VERTEX.y * 0.17) * shake,
		cos(t * 1.13 + VERTEX.x * 0.11) * shake * 0.7
	);
	VERTEX += jitter;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
}

shader_type canvas_item;

uniform float shake : hint_range(0.0, 8.0) = 2.2;
uniform float time = 0.0;

void vertex() {
	float t = time * 21.0;
	VERTEX += vec2(sin(t + VERTEX.y * 0.19) * shake, cos(t * 1.17 + VERTEX.x * 0.13) * shake * 0.65);
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
}

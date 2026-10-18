shader_type canvas_item;
render_mode unshaded;

uniform vec2 source_size = vec2(426.0, 240.0);

float bayer(vec2 pixel) {
	ivec2 p = ivec2(mod(pixel, 4.0));
	const float matrix[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (matrix[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 pixel = floor(UV * source_size);
	vec3 dithered = color.rgb + vec3(bayer(pixel) * 0.65 / 31.0);
	COLOR = vec4(floor(clamp(dithered, 0.0, 1.0) * 31.0 + 0.5) / 31.0, color.a);
}

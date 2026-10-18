shader_type sky;

void sky() {
	float height = clamp(EYEDIR.y + 0.2, 0.0, 1.0);
	vec3 horizon = vec3(0.10, 0.18, 0.30);
	vec3 zenith = vec3(0.025, 0.025, 0.09);
	vec3 background = mix(horizon, zenith, pow(height, 0.55));
	vec2 sky_uv = vec2(atan(EYEDIR.x, -EYEDIR.z), asin(EYEDIR.y));
	vec2 cell = floor(sky_uv * 180.0);
	float hash = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float stars = step(0.9965, hash) * (0.3 + fract(hash * 37.0) * 0.5);
	float moon = smoothstep(0.9992, 0.9994, dot(EYEDIR, normalize(vec3(0.28, -0.14, -1.0))));
	COLOR = background + vec3(0.8, 0.87, 0.66) * stars + vec3(0.78, 0.83, 0.58) * moon;
}

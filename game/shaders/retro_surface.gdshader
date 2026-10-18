shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D pixel_texture : source_color, hint_default_white, filter_nearest, repeat_enable;
uniform float retro_amount = 1.0;
uniform bool animated_water = false;
uniform vec2 uv_tiling = vec2(1.0);
uniform vec3 haze_color : source_color = vec3(0.075, 0.09, 0.17);
varying float view_depth;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view;
	view_depth = -view.z;
	if (clip.w > 0.0) {
		vec2 grid = vec2(256.0, 192.0);
		vec2 ndc = clip.xy / clip.w;
		vec2 snapped = floor(ndc * grid + 0.5) / grid;
		clip.xy = mix(ndc, snapped, retro_amount * 0.42) * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec2 uv = UV * uv_tiling;
	if (animated_water) {
		// Discrete steps and nearest sampling keep the water texture crunchy.
		float tick = floor(TIME * 7.0) / 32.0;
		uv += vec2(tick, -tick * 0.5);
	}
	vec3 texel = texture(pixel_texture, uv).rgb;
	vec3 color = albedo_color.rgb * texel;
	float haze = smoothstep(14.0, 43.0, view_depth) * retro_amount * 0.66;
	ALBEDO = mix(color, haze_color, haze);
	ROUGHNESS = 1.0;
	if (animated_water) {
		EMISSION = color * 0.16;
	}
}

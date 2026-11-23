shader_type spatial;
render_mode cull_back;

global uniform vec3 curve_origin;
global uniform vec2 curve_strength;

uniform vec3 dirt_base : source_color = vec3(0.42, 0.29, 0.18);
uniform vec3 dirt_light : source_color = vec3(0.54, 0.40, 0.25);
uniform vec3 dirt_dark : source_color = vec3(0.30, 0.20, 0.12);
uniform vec3 moss_edge : source_color = vec3(0.20, 0.40, 0.16);

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.5);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_pos = world_pos;

	float dz = max(0.0, curve_origin.z - world_pos.z);
	float d2 = dz * dz;
	world_pos.x += d2 * curve_strength.x;
	world_pos.y -= d2 * curve_strength.y;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	vec2 wp = v_world_pos.xz;
	float n_broad = noise2d(wp * 0.35);
	float n_fine = noise2d(wp * 2.4);
	float n_pebble = noise2d(wp * 6.5);

	// Rich organic woodland soil base (seamless across chunk boundaries via world XZ)
	vec3 col = mix(dirt_dark, dirt_base, n_broad * 0.7 + n_fine * 0.3);

	// Subtle naturally worn footpath ruts along the three lanes (x = -2, 0, +2)
	float rut_l = exp(-pow((wp.x + 2.0) * 1.65, 2.0));
	float rut_c = exp(-pow(wp.x * 1.65, 2.0));
	float rut_r = exp(-pow((wp.x - 2.0) * 1.65, 2.0));
	float rut = clamp(rut_l + rut_c + rut_r, 0.0, 1.0);
	col = mix(col, dirt_light, rut * (0.36 + 0.14 * n_fine));

	// Subtle grassy dividers between lanes (x = -1 and +1)
	float div_l = exp(-pow((wp.x + 1.0) * 5.0, 2.0));
	float div_r = exp(-pow((wp.x - 1.0) * 5.0, 2.0));
	float tuft = (div_l + div_r) * smoothstep(0.42, 0.78, n_broad * 0.6 + n_fine * 0.4);
	col = mix(col, moss_edge, tuft * 0.55);

	// Irregular mossy grass encroaching from the outer shoulders (|x| > 2.65)
	float edge_dist = abs(wp.x) + (n_broad - 0.5) * 0.55 + (n_fine - 0.5) * 0.25;
	float edge_moss = smoothstep(2.65, 3.15, edge_dist);
	col = mix(col, moss_edge, edge_moss * 0.92);

	// Tiny lighter pebbles/gravel flecks
	float pebble = smoothstep(0.84, 0.95, n_pebble) * (1.0 - edge_moss);
	col = mix(col, vec3(0.62, 0.56, 0.48), pebble * 0.45);

	ALBEDO = col;
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}

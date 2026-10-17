shader_type spatial;
render_mode cull_back;

// Shared wind field: every plant keeps the same dominant direction.
uniform vec3 wind_direction = vec3(0.85, 0.0, 0.53);
uniform float wind_speed : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float gust_depth : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float wander : hint_range(0.0, 0.5, 0.01) = 0.12;

// Per-mesh sway setup, filled in by the WindFoliage node.
uniform float sway_height = 1.0;
uniform float sway_amplitude = 0.15;

// Surface look copied from the model's own material.
uniform sampler2D albedo_texture : source_color;
uniform vec3 albedo_color : source_color = vec3(1.0);

// Cheap value hash, used to randomise each plant's rhythm without extra uniforms.
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 origin = MODEL_MATRIX[3].xyz;

	// Only the upper part of the plant bends; the rooted base stays planted.
	float height_factor = clamp(VERTEX.y / max(sway_height, 0.0001), 0.0, 1.0);
	height_factor = height_factor * height_factor;

	// Each plant derives its own phase and a slightly different speed from its
	// world position, so no two sway in lockstep while the direction stays shared.
	float seed = hash21(origin.xz);
	float phase_a = seed * 6.2831853;
	float phase_b = hash21(origin.zx + 17.3) * 6.2831853;
	float speed = wind_speed * (0.75 + seed * 0.5);

	// Layered sines with incommensurate ratios give a smooth, never repeating rhythm.
	float sway = 0.55 * sin(TIME * speed + phase_a)
	           + 0.30 * sin(TIME * speed * 1.7 + phase_b)
	           + 0.15 * sin(TIME * speed * 2.9 + phase_a * 1.3);

	// A slow gust envelope swells and eases the whole motion.
	float gust = 1.0 - gust_depth + gust_depth * 0.5 * (1.0 + sin(TIME * 0.37 + phase_b));

	// The push wanders gently around the main direction instead of being rigid.
	vec2 wind_axis = normalize(wind_direction.xz);
	vec2 perpendicular = vec2(-wind_axis.y, wind_axis.x);
	float drift = sin(TIME * speed * 1.3 + phase_a) * wander;
	vec2 direction = normalize(wind_axis + perpendicular * drift);

	float offset_amount = sway * gust * height_factor * sway_amplitude;
	vec3 offset = vec3(direction.x, 0.0, direction.y) * offset_amount;

	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_position + offset, 1.0)).xyz;
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb * albedo_color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
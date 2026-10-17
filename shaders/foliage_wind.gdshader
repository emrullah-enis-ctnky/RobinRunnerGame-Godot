shader_type spatial;
render_mode cull_back;

// Shared wind field: every instance bends toward the same world direction.
uniform vec3 wind_direction = vec3(0.85, 0.0, 0.53);
uniform float wind_speed : hint_range(0.0, 5.0, 0.01) = 1.1;
uniform float gust_turbulence : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float phase_spread : hint_range(0.0, 2.0, 0.01) = 0.6;

// Per-mesh sway setup, filled in by the WindFoliage node.
uniform float sway_height = 1.0;
uniform float sway_amplitude = 0.15;

// Surface look copied from the model's own material.
uniform sampler2D albedo_texture : source_color;
uniform vec3 albedo_color : source_color = vec3(1.0);

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Only the upper part of the plant bends; the rooted base stays planted.
	float height_factor = clamp(VERTEX.y / max(sway_height, 0.0001), 0.0, 1.0);
	height_factor = height_factor * height_factor;

	// World-space phase keeps neighbouring plants out of lockstep while the wind stays shared.
	float phase = world_position.x * phase_spread + world_position.z * phase_spread;
	float gust = sin(TIME * wind_speed + phase);
	float flutter = sin(TIME * wind_speed * 2.7 + phase * 1.9) * gust_turbulence;
	float sway = (gust + flutter) * height_factor * sway_amplitude;

	vec2 wind_axis = normalize(wind_direction.xz);
	vec3 offset = vec3(wind_axis.x, 0.0, wind_axis.y) * sway;

	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_position + offset, 1.0)).xyz;
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb * albedo_color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
shader_type spatial;
render_mode cull_back;

global uniform vec3 curve_origin;
global uniform vec2 curve_strength;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dz = max(0.0, curve_origin.z - world_pos.z);
	float d2 = dz * dz;
	world_pos.x += d2 * curve_strength.x;
	world_pos.y -= d2 * curve_strength.y;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	vec4 base = albedo_color;
	if (use_albedo_texture) {
		base *= texture(albedo_texture, UV);
	}
	ALBEDO = base.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission_color * emission_energy;
}

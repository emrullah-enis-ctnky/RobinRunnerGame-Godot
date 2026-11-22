shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

global uniform vec3 curve_origin;
global uniform vec2 curve_strength;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;

void vertex() {
	// Bend the particle center using the exact same curved-world math as meshes
	vec3 center_world = MODEL_MATRIX[3].xyz;
	float dz = max(0.0, curve_origin.z - center_world.z);
	float d2 = dz * dz;
	center_world.x += d2 * curve_strength.x;
	center_world.y -= d2 * curve_strength.y;

	// Preserve particle scale while billboarding cleanly toward the camera
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 cam_right = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_up = INV_VIEW_MATRIX[1].xyz;
	vec3 bent_pos = center_world + cam_right * (VERTEX.x * sx) + cam_up * (VERTEX.y * sy);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(bent_pos, 1.0);
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * COLOR.rgb;
	ALPHA = tex.a * COLOR.a;
}

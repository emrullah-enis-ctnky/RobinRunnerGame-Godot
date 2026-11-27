shader_type sky;

uniform vec3 sky_top_color : source_color = vec3(0.16, 0.42, 0.82);
uniform vec3 sky_horizon_color : source_color = vec3(0.66, 0.82, 0.96);
uniform vec3 ground_horizon_color : source_color = vec3(0.32, 0.48, 0.36);
uniform vec3 ground_bottom_color : source_color = vec3(0.10, 0.18, 0.12);

uniform vec3 sun_direction = vec3(0.3, 0.6, -0.7);
uniform vec3 sun_color : source_color = vec3(1.0, 0.92, 0.72);
uniform float sun_strength : hint_range(0.0, 2.0) = 1.0;

uniform vec3 moon_direction = vec3(-0.3, -0.6, 0.7);
uniform vec3 moon_color : source_color = vec3(0.82, 0.88, 1.0);
uniform float moon_strength : hint_range(0.0, 2.0) = 0.0;

uniform vec3 cloud_color : source_color = vec3(1.0, 0.98, 0.95);
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.65;
uniform float stars_alpha : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float cloud_fbm(vec2 p) {
	// 2-octave stylized clouds: soft painterly silhouette with half the WebGL2 fragment cost
	float v = 0.65 * value_noise(p);
	v += 0.35 * value_noise(p * 2.15 + vec2(13.1, 7.7));
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float y = dir.y;

	// Base sky & ground gradient
	vec3 col;
	if (y >= 0.0) {
		float t = pow(clamp(y, 0.0, 1.0), 0.58);
		col = mix(sky_horizon_color, sky_top_color, t);
	} else {
		float t = pow(clamp(-y, 0.0, 1.0), 0.45);
		col = mix(ground_horizon_color, ground_bottom_color, t);
	}

	// Twinkling stars in upper dome at night/dusk
	if (stars_alpha > 0.01 && y > 0.03) {
		vec2 star_uv = dir.xz / (y + 0.35) * 42.0;
		vec2 cell = floor(star_uv);
		vec2 local = fract(star_uv) - 0.5;
		float rnd = hash21(cell);
		if (rnd > 0.968) {
			float d = length(local);
			float twinkle = 0.65 + 0.35 * sin(TIME * (2.0 + rnd * 5.0) + rnd * 40.0);
			float star = smoothstep(0.16, 0.02, d) * twinkle * smoothstep(0.03, 0.28, y);
			col += vec3(0.92, 0.95, 1.0) * star * stars_alpha * 1.4;
		}
	}

	// Stylized sun disc + warm atmospheric halo
	vec3 s_dir = normalize(sun_direction);
	float sun_dot = max(dot(dir, s_dir), 0.0);
	float sun_disc = smoothstep(0.9972, 0.9988, sun_dot);
	float sun_halo = pow(sun_dot, 14.0) * 0.42 + pow(sun_dot, 4.0) * 0.14;
	float above_horizon = smoothstep(-0.08, 0.06, s_dir.y);
	col += sun_color * (sun_disc * 2.2 + sun_halo) * sun_strength * above_horizon;

	// Stylized moon disc + cool halo
	vec3 m_dir = normalize(moon_direction);
	float moon_dot = max(dot(dir, m_dir), 0.0);
	float moon_disc = smoothstep(0.9980, 0.9991, moon_dot);
	float moon_halo = pow(moon_dot, 22.0) * 0.28;
	float moon_above = smoothstep(-0.08, 0.08, m_dir.y);
	col += moon_color * (moon_disc * 1.6 + moon_halo) * moon_strength * moon_above;

	// Soft drifting stylized clouds above horizon
	if (y > 0.04) {
		vec2 cloud_uv = dir.xz / (y + 0.22) * 1.35 + vec2(TIME * 0.012, TIME * 0.006);
		float n = cloud_fbm(cloud_uv);
		float mask = smoothstep(0.48, 0.72, n) * smoothstep(0.04, 0.26, y) * smoothstep(0.95, 0.45, y);
		col = mix(col, cloud_color, mask * cloud_opacity);
	}

	COLOR = col;
}

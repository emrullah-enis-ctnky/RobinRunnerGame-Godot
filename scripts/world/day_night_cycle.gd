class_name DayNightCycle
extends Node
## Drives a continuous 24-hour stylized sky, sun/moon lighting, and fog cycle.
## Randomizes the starting hour on every new run for varied atmosphere.

const SKY_SHADER: Shader = preload("res://shaders/stylized_sky.gdshader")

@export var environment_path: NodePath = NodePath("../WorldEnvironment")
@export var sun_light_path: NodePath = NodePath("../SunLight")
@export var day_duration_seconds: float = 180.0
@export var randomize_on_start: bool = true

# Current hour of day in [0.0, 24.0)
var time_of_day: float = 10.0

var _world_env: WorldEnvironment
var _sun_light: DirectionalLight3D
var _sky_mat: ShaderMaterial
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Keyframe palettes across 24 hours: [hour, sky_top, sky_horizon, ground_horizon, ground_bottom, cloud, light_col, light_energy, ambient_col, ambient_energy, stars]
const KEYFRAMES: Array = [
	[0.0,  Color(0.03, 0.05, 0.14), Color(0.09, 0.14, 0.26), Color(0.06, 0.10, 0.14), Color(0.03, 0.05, 0.07), Color(0.24, 0.30, 0.44), Color(0.62, 0.74, 1.00), 0.45, Color(0.20, 0.26, 0.40), 0.48, 1.0],
	[5.5,  Color(0.14, 0.18, 0.38), Color(0.86, 0.48, 0.36), Color(0.30, 0.28, 0.26), Color(0.10, 0.12, 0.12), Color(0.98, 0.70, 0.56), Color(1.00, 0.68, 0.45), 0.72, Color(0.45, 0.36, 0.40), 0.45, 0.35],
	[8.0,  Color(0.20, 0.50, 0.88), Color(0.76, 0.88, 0.98), Color(0.32, 0.50, 0.34), Color(0.14, 0.26, 0.15), Color(1.00, 0.98, 0.94), Color(1.00, 0.94, 0.82), 1.05, Color(0.54, 0.64, 0.74), 0.42, 0.0],
	[13.0, Color(0.14, 0.44, 0.88), Color(0.64, 0.84, 0.98), Color(0.30, 0.52, 0.32), Color(0.14, 0.28, 0.14), Color(1.00, 1.00, 1.00), Color(1.00, 0.98, 0.92), 1.18, Color(0.56, 0.68, 0.80), 0.44, 0.0],
	[17.5, Color(0.24, 0.36, 0.66), Color(0.96, 0.58, 0.32), Color(0.42, 0.36, 0.24), Color(0.16, 0.18, 0.12), Color(1.00, 0.76, 0.52), Color(1.00, 0.72, 0.42), 0.90, Color(0.54, 0.44, 0.38), 0.44, 0.05],
	[19.5, Color(0.12, 0.16, 0.38), Color(0.78, 0.36, 0.40), Color(0.22, 0.20, 0.22), Color(0.08, 0.10, 0.12), Color(0.84, 0.50, 0.52), Color(0.95, 0.56, 0.50), 0.55, Color(0.34, 0.28, 0.40), 0.45, 0.55],
	[21.5, Color(0.04, 0.07, 0.18), Color(0.12, 0.18, 0.32), Color(0.08, 0.12, 0.16), Color(0.03, 0.06, 0.08), Color(0.28, 0.34, 0.48), Color(0.64, 0.76, 1.00), 0.48, Color(0.22, 0.28, 0.42), 0.48, 0.95],
	[24.0, Color(0.03, 0.05, 0.14), Color(0.09, 0.14, 0.26), Color(0.06, 0.10, 0.14), Color(0.03, 0.05, 0.07), Color(0.24, 0.30, 0.44), Color(0.62, 0.74, 1.00), 0.45, Color(0.20, 0.26, 0.40), 0.48, 1.0],
]


## Binds the stylized sky shader, picks a random starting hour, and listens for restarts.
func _ready() -> void:
	_rng.randomize()
	_world_env = get_node_or_null(environment_path) as WorldEnvironment
	_sun_light = get_node_or_null(sun_light_path) as DirectionalLight3D
	_setup_sky_material()

	if randomize_on_start:
		randomize_time()
	else:
		apply_time(time_of_day)

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").game_restarted.connect(_on_game_restarted)


## Advances the day-night cycle continuously while playing.
func _process(delta: float) -> void:
	if day_duration_seconds <= 0.0:
		return
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm.current_state != gm.GameState.PLAYING:
			return

	time_of_day = fposmod(time_of_day + (24.0 / day_duration_seconds) * delta, 24.0)
	apply_time(time_of_day)


## Picks a fresh random hour in [0.0, 24.0) and applies its sky & lighting palette.
func randomize_time() -> float:
	time_of_day = _rng.randf_range(0.0, 24.0)
	apply_time(time_of_day)
	return time_of_day


## Updates sky shader uniforms, sun/moon directional light, ambient light, and distance fog.
func apply_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	var sample: Dictionary = _sample_palette(time_of_day)

	# Sun angle: 06:00 rises east (+X), 12:00 overhead (+Y), 18:00 sets west (-X)
	var sun_angle: float = ((time_of_day - 6.0) / 24.0) * TAU
	var sun_dir := Vector3(cos(sun_angle) * 0.75, sin(sun_angle), -0.55).normalized()
	var moon_dir := (-sun_dir).normalized()
	var is_day: bool = sun_dir.y >= -0.05

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("sky_top_color", sample["sky_top"])
		_sky_mat.set_shader_parameter("sky_horizon_color", sample["sky_horizon"])
		_sky_mat.set_shader_parameter("ground_horizon_color", sample["ground_horizon"])
		_sky_mat.set_shader_parameter("ground_bottom_color", sample["ground_bottom"])
		_sky_mat.set_shader_parameter("cloud_color", sample["cloud"])
		_sky_mat.set_shader_parameter("stars_alpha", sample["stars"])
		_sky_mat.set_shader_parameter("sun_direction", sun_dir)
		_sky_mat.set_shader_parameter("moon_direction", moon_dir)
		_sky_mat.set_shader_parameter("sun_strength", clampf((sun_dir.y + 0.15) * 2.5, 0.0, 1.2))
		_sky_mat.set_shader_parameter("moon_strength", clampf((moon_dir.y + 0.15) * 2.2, 0.0, 1.0))

	if _sun_light != null:
		# Smoothly fade directional energy to zero across the horizon so switching between
		# sun and moon never causes an abrupt 180-degree shadow jump across the world.
		var active_dir: Vector3 = sun_dir if sun_dir.y >= 0.0 else moon_dir
		var horizon_fade: float = smoothstep(0.0, 0.14, absf(sun_dir.y))
		var elev: float = maxf(active_dir.y, 0.28)
		var light_from := Vector3(active_dir.x, elev, active_dir.z).normalized()
		_sun_light.look_at_from_position(light_from * 20.0, Vector3.ZERO, Vector3.UP)
		_sun_light.light_color = sample["light_col"]
		_sun_light.light_energy = float(sample["light_energy"]) * horizon_fade

	if _world_env != null and _world_env.environment != null:
		var env: Environment = _world_env.environment
		env.ambient_light_color = sample["ambient_col"]
		env.ambient_light_energy = sample["ambient_energy"]
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = (sample["sky_horizon"] as Color).lerp(sample["ground_horizon"] as Color, 0.25)
		env.fog_light_energy = 1.0
		env.fog_density = 0.01
		env.fog_depth_begin = 42.0
		env.fog_depth_end = 135.0
		env.fog_sky_affect = 0.35


func _on_game_restarted() -> void:
	if randomize_on_start:
		randomize_time()


func _setup_sky_material() -> void:
	if _world_env == null:
		return
	if _world_env.environment == null:
		_world_env.environment = Environment.new()
	var env: Environment = _world_env.environment
	env.background_mode = Environment.BG_SKY
	if env.sky == null:
		env.sky = Sky.new()
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	_sky_mat.set_shader_parameter("low_quality", OS.has_feature("web"))
	env.sky.sky_material = _sky_mat


func _sample_palette(hour: float) -> Dictionary:
	var a: Array = KEYFRAMES[0]
	var b: Array = KEYFRAMES[KEYFRAMES.size() - 1]
	for i in range(KEYFRAMES.size() - 1):
		if hour >= KEYFRAMES[i][0] and hour <= KEYFRAMES[i + 1][0]:
			a = KEYFRAMES[i]
			b = KEYFRAMES[i + 1]
			break
	var span: float = maxf(b[0] - a[0], 0.001)
	var t: float = clampf((hour - a[0]) / span, 0.0, 1.0)
	return {
		"sky_top": (a[1] as Color).lerp(b[1] as Color, t),
		"sky_horizon": (a[2] as Color).lerp(b[2] as Color, t),
		"ground_horizon": (a[3] as Color).lerp(b[3] as Color, t),
		"ground_bottom": (a[4] as Color).lerp(b[4] as Color, t),
		"cloud": (a[5] as Color).lerp(b[5] as Color, t),
		"light_col": (a[6] as Color).lerp(b[6] as Color, t),
		"light_energy": lerpf(a[7], b[7], t),
		"ambient_col": (a[8] as Color).lerp(b[8] as Color, t),
		"ambient_energy": lerpf(a[9], b[9], t),
		"stars": lerpf(a[10], b[10], t),
	}

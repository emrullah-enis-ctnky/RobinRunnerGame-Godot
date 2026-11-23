extends Node
## Centralized audio manager handling pooled SFX playback, dual-channel crossfaded music,
## pause ducking, and EventBus-driven sound triggers.

const GameConfig = preload("res://scripts/common/game_config.gd")

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const SFX_POOL_SIZE: int = 8

const MUSIC_BASE_DB: float = -12.0
const PAUSE_DUCK_DB: float = -22.0
const SILENT_DB: float = -45.0
const DUCK_FADE_TIME: float = 0.55
const MUSIC_FADE_IN_TIME: float = 2.0
const MUSIC_CROSSFADE_TIME: float = 3.2

const AUDIO_EXTENSIONS: Array[String] = [".ogg", ".wav", ".mp3"]

const MUSIC_PATHS: Dictionary = {
	"menu": "res://assets/audio/music/menu_theme",
	"gameplay": "res://assets/audio/music/gameplay_theme",
}

const SFX_PATHS: Dictionary = {
	"footstep": "res://assets/audio/sfx/footstep",
	"jump": "res://assets/audio/sfx/jump",
	"land": "res://assets/audio/sfx/land",
	"duck": "res://assets/audio/sfx/duck",
	"bow_shoot": "res://assets/audio/sfx/bow_shoot",
	"arrow_hit": "res://assets/audio/sfx/arrow_hit",
	"tree_burn": "res://assets/audio/sfx/tree_burn",
	"coin_pickup": "res://assets/audio/sfx/coin_pickup",
	"arrow_pickup": "res://assets/audio/sfx/arrow_pickup",
	"stumble": "res://assets/audio/sfx/stumble",
	"death": "res://assets/audio/sfx/death",
	"ui_click": "res://assets/audio/sfx/ui_click",
	"countdown_tick": "res://assets/audio/sfx/countdown_tick",
	"countdown_go": "res://assets/audio/sfx/countdown_go",
}

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0

var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _current_track: String = ""
var _is_ducked: bool = false
var _music_tween: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Sets up dual music players and SFX pool, loads audio assets, and wires EventBus signals.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_buses()
	_build_players()
	reload_audio_library()
	_connect_signals()
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager")._apply_audio()
	play_music("menu", MUSIC_FADE_IN_TIME)


## Scans assets/audio/ for any .ogg/.wav/.mp3 files matching the configured slots.
func reload_audio_library() -> void:
	_music_streams.clear()
	_sfx_streams.clear()
	for track_name in MUSIC_PATHS.keys():
		var stream: AudioStream = _load_audio_by_base(MUSIC_PATHS[track_name])
		if stream != null:
			_enable_loop(stream)
			_music_streams[track_name] = stream
	for sfx_name in SFX_PATHS.keys():
		var stream: AudioStream = _load_audio_by_base(SFX_PATHS[sfx_name])
		if stream != null:
			_sfx_streams[sfx_name] = stream


## Registers a stream directly at runtime (useful for tests or procedural sounds).
func register_sfx(sfx_name: String, stream: AudioStream) -> void:
	if stream != null:
		_sfx_streams[sfx_name] = stream


## Registers a music stream directly at runtime.
func register_music(track_name: String, stream: AudioStream) -> void:
	if stream != null:
		_enable_loop(stream)
		_music_streams[track_name] = stream


## Returns true if the given SFX slot has a loaded stream.
func has_sfx(sfx_name: String) -> bool:
	return _sfx_streams.has(sfx_name)


## Returns true if the given music track has a loaded stream.
func has_music(track_name: String) -> bool:
	return _music_streams.has(track_name)


## Plays a one-shot sound effect on the next pooled SFX player with optional pitch/volume.
func play_sfx(sfx_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> AudioStreamPlayer:
	if not _sfx_streams.has(sfx_name) or _sfx_players.is_empty():
		return null

	var player: AudioStreamPlayer = _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stream = _sfx_streams[sfx_name]
	player.volume_db = volume_db
	var jitter: float = _rng.randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 0.0
	player.pitch_scale = maxf(0.25, pitch_scale + jitter)
	player.play()
	return player


## Plays a distance-attenuated SFX; stays silent when distance >= max_distance.
func play_sfx_at_distance(
	sfx_name: String,
	distance: float,
	max_distance: float = 45.0,
	base_db: float = 0.0,
	pitch_jitter: float = 0.06
) -> AudioStreamPlayer:
	if distance >= max_distance:
		return null
	var t: float = clampf(distance / maxf(max_distance, 0.01), 0.0, 1.0)
	var falloff_db: float = lerpf(0.0, -28.0, t * t)
	return play_sfx(sfx_name, 1.0, base_db + falloff_db, pitch_jitter)


## Plays a distance-attenuated SFX measured from the player to world_pos.
func play_sfx_at_world_pos(
	sfx_name: String,
	world_pos: Vector3,
	max_distance: float = 45.0,
	base_db: float = 0.0,
	pitch_jitter: float = 0.06
) -> AudioStreamPlayer:
	var player: Node = get_tree().get_first_node_in_group("player")
	var dist: float = 0.0
	if player is Node3D:
		dist = (player as Node3D).global_position.distance_to(world_pos)
	return play_sfx_at_distance(sfx_name, dist, max_distance, base_db, pitch_jitter)


## Convenience helper for UI button clicks.
func play_ui_click() -> void:
	play_sfx("ui_click", 1.0, 1.0, 0.04)


## Smoothly fades in or crossfades to a named music track. If already playing that track,
## continues seamlessly from its current playback position without restarting.
func play_music(track_name: String, fade_time: float = MUSIC_CROSSFADE_TIME) -> void:
	if _active_music == null:
		return
	if not _music_streams.has(track_name):
		_current_track = track_name
		return

	var target_db: float = PAUSE_DUCK_DB if _is_ducked else MUSIC_BASE_DB
	if _current_track == track_name and _active_music.playing:
		# Keep playing from current position; just glide volume smoothly if needed
		_glide_active_volume(target_db, DUCK_FADE_TIME)
		return

	var incoming: AudioStreamPlayer = _music_b if _active_music == _music_a else _music_a
	var outgoing: AudioStreamPlayer = _active_music
	_active_music = incoming
	_current_track = track_name
	_kill_music_tween()

	incoming.stream = _music_streams[track_name]
	if fade_time <= 0.0:
		if outgoing.playing:
			outgoing.stop()
		incoming.volume_db = target_db
		incoming.play()
		return

	incoming.volume_db = SILENT_DB
	incoming.play()

	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", target_db, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", SILENT_DB, fade_time * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_tween.chain().tween_callback(outgoing.stop)


## Fades out and stops all active background music.
func stop_music(fade_time: float = MUSIC_CROSSFADE_TIME) -> void:
	_current_track = ""
	_kill_music_tween()
	if fade_time <= 0.0:
		if _music_a != null:
			_music_a.stop()
		if _music_b != null:
			_music_b.stop()
		return

	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	if _music_a != null and _music_a.playing:
		_music_tween.tween_property(_music_a, "volume_db", SILENT_DB, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if _music_b != null and _music_b.playing:
		_music_tween.tween_property(_music_b, "volume_db", SILENT_DB, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_music_tween.chain().tween_callback(func() -> void:
		if _music_a != null:
			_music_a.stop()
		if _music_b != null:
			_music_b.stop()
	)


## Ducks or restores background music smoothly (used on pause/resume/game over).
func set_music_ducked(ducked: bool) -> void:
	_is_ducked = ducked
	if _active_music == null or not _active_music.playing:
		return
	var target_db: float = PAUSE_DUCK_DB if ducked else MUSIC_BASE_DB
	_glide_active_volume(target_db, DUCK_FADE_TIME)


func _glide_active_volume(target_db: float, duration: float) -> void:
	if _active_music == null:
		return
	_kill_music_tween()
	if duration <= 0.0:
		_active_music.volume_db = target_db
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_active_music, "volume_db", target_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _connect_signals() -> void:
	if not has_node("/root/EventBus"):
		return
	var bus: Node = get_node("/root/EventBus")
	bus.game_started.connect(_on_game_started)
	bus.game_paused.connect(func() -> void: set_music_ducked(true))
	bus.game_resumed.connect(func() -> void: set_music_ducked(false))
	bus.game_over.connect(_on_game_over)
	bus.player_jumped.connect(func() -> void: play_sfx("jump", 1.0, -2.0, 0.05))
	bus.player_landed.connect(func() -> void: play_sfx("land", 1.0, -5.0, 0.08))
	bus.player_damaged.connect(func(_w: float) -> void: play_sfx("stumble", 1.0, 0.0, 0.04))
	bus.player_died.connect(func() -> void: play_sfx("death", 1.0, 0.0, 0.0))
	bus.arrow_fired.connect(func(_p: Vector3, _d: Vector3, _t: String) -> void: play_sfx("bow_shoot", 1.0, -1.0, 0.06))
	bus.collectible_picked.connect(_on_collectible_picked)


func _on_game_started() -> void:
	set_music_ducked(false)
	play_music("gameplay")


func _on_game_over(_final_score: int, _distance: float) -> void:
	if _active_music == null or not _active_music.playing:
		return
	_is_ducked = false
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_active_music, "volume_db", PAUSE_DUCK_DB, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_music_tween.tween_interval(1.0)
	_music_tween.tween_property(_active_music, "volume_db", MUSIC_BASE_DB, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_collectible_picked(collectible_type: String, _value: int) -> void:
	if collectible_type == GameConfig.COLLECTIBLE_TYPE_COIN:
		var combo_pitch: float = 1.0
		if has_node("/root/ScoreManager"):
			var streak: int = get_node("/root/ScoreManager").combo_count
			combo_pitch = minf(1.0 + float(streak) * 0.025, 1.45)
		play_sfx("coin_pickup", combo_pitch, -2.0, 0.02)
	elif collectible_type.begins_with("arrow_"):
		play_sfx("arrow_pickup", 1.0, -1.0, 0.05)


func _build_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicPlayerA"
	_music_a.bus = MUSIC_BUS
	_music_a.volume_db = SILENT_DB
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicPlayerB"
	_music_b.bus = MUSIC_BUS
	_music_b.volume_db = SILENT_DB
	add_child(_music_b)

	_active_music = _music_a

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = SFX_BUS
		add_child(p)
		_sfx_players.append(p)


func _ensure_buses() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index(SFX_BUS) < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, SFX_BUS)
		AudioServer.set_bus_send(idx, "Master")


func _load_audio_by_base(base_path: String) -> AudioStream:
	for ext in AUDIO_EXTENSIONS:
		var full_path: String = base_path + ext
		if ResourceLoader.exists(full_path):
			var res: Resource = load(full_path)
			if res is AudioStream:
				return res as AudioStream
	return null


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

extends Node
## Centralized audio manager handling pooled SFX playback, adaptive background music,
## pause ducking, and EventBus-driven sound triggers.

const GameConfig = preload("res://scripts/common/game_config.gd")

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const SFX_POOL_SIZE: int = 8
const PAUSE_DUCK_DB: float = -10.0
const DUCK_FADE_TIME: float = 0.25
const MUSIC_FADE_TIME: float = 0.6

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
	"coin_pickup": "res://assets/audio/sfx/coin_pickup",
	"arrow_pickup": "res://assets/audio/sfx/arrow_pickup",
	"stumble": "res://assets/audio/sfx/stumble",
	"death": "res://assets/audio/sfx/death",
	"ui_click": "res://assets/audio/sfx/ui_click",
	"countdown_tick": "res://assets/audio/sfx/countdown_tick",
	"countdown_go": "res://assets/audio/sfx/countdown_go",
}

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0

var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _current_track: String = ""
var _is_ducked: bool = false
var _music_tween: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Sets up audio players, preloads any available audio files, and wires EventBus signals.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_buses()
	_build_players()
	reload_audio_library()
	_connect_signals()
	if has_node("/root/SettingsManager"):
		get_node("/root/SettingsManager")._apply_audio()
	play_music("menu")


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


## Convenience helper for UI button clicks.
func play_ui_click() -> void:
	play_sfx("ui_click", 1.0, -2.0, 0.04)


## Starts or crossfades to a named background music track ("menu" or "gameplay").
func play_music(track_name: String, fade_time: float = MUSIC_FADE_TIME) -> void:
	if _music_player == null:
		return
	if not _music_streams.has(track_name):
		_current_track = track_name
		return
	if _current_track == track_name and _music_player.playing:
		return

	_current_track = track_name
	var target_db: float = PAUSE_DUCK_DB if _is_ducked else 0.0
	_kill_music_tween()

	if _music_player.playing and fade_time > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -36.0, fade_time * 0.45)
		_music_tween.tween_callback(func() -> void:
			_music_player.stream = _music_streams[track_name]
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", target_db, fade_time * 0.55)
	else:
		_music_player.stream = _music_streams[track_name]
		_music_player.volume_db = -30.0 if fade_time > 0.0 else target_db
		_music_player.play()
		if fade_time > 0.0:
			_music_tween = create_tween()
			_music_tween.tween_property(_music_player, "volume_db", target_db, fade_time)


## Fades out and stops the active background music.
func stop_music(fade_time: float = MUSIC_FADE_TIME) -> void:
	if _music_player == null or not _music_player.playing:
		_current_track = ""
		return
	_current_track = ""
	_kill_music_tween()
	if fade_time <= 0.0:
		_music_player.stop()
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


## Ducks or restores background music smoothly (used on pause/resume).
func set_music_ducked(ducked: bool) -> void:
	_is_ducked = ducked
	if _music_player == null:
		return
	var target_db: float = PAUSE_DUCK_DB if ducked else 0.0
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, DUCK_FADE_TIME)


func _connect_signals() -> void:
	if not has_node("/root/EventBus"):
		return
	var bus: Node = get_node("/root/EventBus")
	bus.game_started.connect(_on_game_started)
	bus.game_restarted.connect(_on_game_restarted)
	bus.game_paused.connect(func() -> void: set_music_ducked(true))
	bus.game_resumed.connect(func() -> void: set_music_ducked(false))
	bus.game_over.connect(_on_game_over)
	bus.player_jumped.connect(func() -> void: play_sfx("jump", 1.0, -2.0, 0.05))
	bus.player_landed.connect(func() -> void: play_sfx("land", 1.0, -5.0, 0.08))
	bus.player_damaged.connect(func(_w: float) -> void: play_sfx("stumble", 1.0, 0.0, 0.04))
	bus.player_died.connect(func() -> void: play_sfx("death", 1.0, 0.0, 0.0))
	bus.arrow_fired.connect(func(_p: Vector3, _d: Vector3, _t: String) -> void: play_sfx("bow_shoot", 1.0, -1.0, 0.06))
	bus.target_destroyed.connect(func(_n: String, _r: int) -> void: play_sfx("arrow_hit", 1.0, -1.0, 0.05))
	bus.collectible_picked.connect(_on_collectible_picked)


func _on_game_started() -> void:
	set_music_ducked(false)
	play_music("gameplay")


func _on_game_restarted() -> void:
	set_music_ducked(false)
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm.current_state == gm.GameState.READY:
			play_music("menu")
			return
	play_music("gameplay")


func _on_game_over(_final_score: int, _distance: float) -> void:
	set_music_ducked(true)


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
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

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

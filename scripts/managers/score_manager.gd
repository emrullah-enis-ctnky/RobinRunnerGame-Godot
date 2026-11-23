extends Node
## Tracks distance score, coin collection, 10-coin %10 combo steps, and -20% stumble penalty.

const GameConfig = preload("res://scripts/common/game_config.gd")

var coins_collected: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0

var _combo_timer: float = 0.0
var _penalty_timer: float = 0.0
var _last_distance_meters: float = 0.0
var _distance_score_buffer: float = 0.0


## Connects to EventBus lifecycle, distance, damage, and collectible signals.
func _ready() -> void:
	reset_run()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.game_started.connect(reset_run)
		bus.game_restarted.connect(reset_run)
		bus.distance_updated.connect(_on_distance_updated)
		bus.collectible_picked.connect(_on_collectible_picked)
		bus.player_damaged.connect(_on_player_damaged)


## Counts down active combo and stumble-penalty windows during gameplay.
func _process(delta: float) -> void:
	if _combo_timer <= 0.0 and _penalty_timer <= 0.0:
		return
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		if gm.current_state != gm.GameState.PLAYING:
			return

	if _penalty_timer > 0.0:
		_penalty_timer -= delta
		if _penalty_timer <= 0.0:
			_penalty_timer = 0.0
			_emit_combo_state()

	if combo_count > 0 and _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_reset_combo()


## Returns the active score multiplier (0.8 during stumble penalty, else 1.0 + 0.1 per 10 combo).
func get_effective_multiplier() -> float:
	if _penalty_timer > 0.0:
		return GameConfig.STUMBLE_SCORE_PENALTY_FACTOR
	return combo_multiplier


## Resets all per-run scoring, coin, combo, and penalty state.
func reset_run() -> void:
	coins_collected = 0
	_last_distance_meters = 0.0
	_distance_score_buffer = 0.0
	_penalty_timer = 0.0
	combo_count = 0
	combo_multiplier = 1.0
	_combo_timer = 0.0
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.coins_updated.emit(coins_collected)
		bus.combo_updated.emit(combo_count, get_effective_multiplier())


## Converts traveled meters into distance score scaled by the active multiplier.
func _on_distance_updated(distance_meters: float) -> void:
	var delta_m: float = distance_meters - _last_distance_meters
	if delta_m <= 0.0:
		return
	_last_distance_meters = distance_meters
	_distance_score_buffer += delta_m * GameConfig.SCORE_PER_METER * get_effective_multiplier()
	var whole_points: int = int(floor(_distance_score_buffer))
	if whole_points <= 0:
		return
	_distance_score_buffer -= float(whole_points)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").add_score(whole_points)


## Banks coin pickups with the active multiplier, refreshes combo, and emits popup feedback.
func _on_collectible_picked(collectible_type: String, value: int) -> void:
	if collectible_type != GameConfig.COLLECTIBLE_TYPE_COIN:
		return

	coins_collected += 1
	if _penalty_timer <= 0.0:
		combo_count += 1
		_combo_timer = GameConfig.COMBO_WINDOW_SECONDS
		combo_multiplier = _compute_multiplier(combo_count)

	var awarded: int = maxi(1, int(round(float(value) * get_effective_multiplier())))
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").add_score(awarded)

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.coins_updated.emit(coins_collected)
		bus.combo_updated.emit(combo_count, get_effective_multiplier())
		bus.score_popup.emit(awarded, "coin")


## Breaks the coin combo and applies the -20% score penalty across the stumble/damage window.
func _on_player_damaged(window_duration: float) -> void:
	combo_count = 0
	combo_multiplier = 1.0
	_combo_timer = 0.0
	_penalty_timer = maxf(window_duration, GameConfig.STUMBLE_DURATION)
	_emit_combo_state()


## Computes the combo multiplier (+10% per 10 consecutive coins).
func _compute_multiplier(streak: int) -> float:
	var steps: int = int(streak / GameConfig.COMBO_STEP_COINS)
	return minf(1.0 + float(steps) * GameConfig.COMBO_MULTIPLIER_STEP, GameConfig.COMBO_MAX_MULTIPLIER)


## Clears the active combo streak back to 1.0x.
func _reset_combo() -> void:
	combo_count = 0
	combo_multiplier = 1.0
	_combo_timer = 0.0
	_emit_combo_state()


func _emit_combo_state() -> void:
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").combo_updated.emit(combo_count, get_effective_multiplier())

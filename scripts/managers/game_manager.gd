extends Node
## Central game manager controlling game state, progression, and scoring.

const GameConfig = preload("res://scripts/common/game_config.gd")

enum GameState {
	READY,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.READY
var current_speed: float = GameConfig.INITIAL_FORWARD_SPEED
var score: int = 0
var distance_traveled: float = 0.0
var high_score: int = 0


## Initializes the game manager, prepares baseline values, and banks target rewards.
func _ready() -> void:
	reset_game()
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").target_destroyed.connect(_on_target_destroyed)


## Updates running metrics and speed progression while actively playing.
func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	# Accelerate forward speed smoothly up to max cap
	current_speed = minf(
		current_speed + GameConfig.SPEED_ACCELERATION_PER_SECOND * delta,
		GameConfig.MAX_FORWARD_SPEED
	)

	# Accumulate distance and notify listeners
	var frame_distance: float = current_speed * delta
	distance_traveled += frame_distance
	EventBus.distance_updated.emit(distance_traveled)


## Starts a new game run from the ready state.
func start_game() -> void:
	reset_game()
	current_state = GameState.PLAYING
	EventBus.game_started.emit()


## Pauses the active game session.
func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.PAUSED
	EventBus.game_paused.emit()


## Resumes the game session from a paused state.
func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return
	current_state = GameState.PLAYING
	EventBus.game_resumed.emit()


## Ends the run and records the high score.
func trigger_game_over() -> void:
	if current_state == GameState.GAME_OVER:
		return
	current_state = GameState.GAME_OVER
	if score > high_score:
		high_score = score
	EventBus.game_over.emit(score, distance_traveled)


## Restarts the game loop cleanly.
func restart_game() -> void:
	start_game()
	EventBus.game_restarted.emit()


## Resets all runtime metrics back to their initial values.
func reset_game() -> void:
	current_state = GameState.READY
	current_speed = GameConfig.INITIAL_FORWARD_SPEED
	score = 0
	distance_traveled = 0.0


## Adds points to the total score and notifies listeners.
func add_score(amount: int) -> void:
	score += amount
	EventBus.score_updated.emit(score)


## Banks the reward broadcast when a shootable target is destroyed.
func _on_target_destroyed(_target_name: String, score_reward: int) -> void:
	add_score(score_reward)

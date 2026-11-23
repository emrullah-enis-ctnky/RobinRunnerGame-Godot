class_name DamageOverlay
extends CanvasLayer
## Full-screen red pulse shown inside the damage window, darkening to black on death.

@export var flash_color: Color = Color(0.85, 0.05, 0.05)
@export_range(0.5, 20.0, 0.1) var pulse_hz: float = 6.0
@export_range(0.0, 1.0, 0.01) var peak_alpha: float = 0.45
@export_range(0.0, 1.0, 0.01) var min_alpha: float = 0.08
@export var fade_out_time: float = 1.0
@export_range(0.0, 5.0, 0.05) var death_fade_time: float = 1.2
@export_range(0.0, 1.0, 0.01) var death_start_alpha: float = 0.5

@onready var _tint: ColorRect = $Tint

var _active: bool = false
var _remaining: float = 0.0
var _phase: float = 0.0
var _dying: bool = false
var _death_elapsed: float = 0.0


## Seeds the tint and connects the overlay to the player's damage and run-end signals.
func _ready() -> void:
	_tint.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	_tint.visible = false

	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_damaged.connect(_on_player_damaged)
		bus.player_died.connect(_on_player_died)
		bus.game_restarted.connect(_clear)


## Starts a fresh pulse for the given damage window duration.
func _on_player_damaged(window_duration: float) -> void:
	_active = true
	_dying = false
	_remaining = maxf(window_duration, 0.01)
	_phase = 0.0
	_tint.visible = true


## Begins the death fade that darkens the impact red all the way to black.
func _on_player_died() -> void:
	_active = false
	_dying = true
	_death_elapsed = 0.0
	_tint.color = Color(flash_color.r, flash_color.g, flash_color.b, maxf(_tint.color.a, death_start_alpha))
	_tint.visible = true


## Drives the damage pulse or the death fade depending on the active state.
func _process(delta: float) -> void:
	if _dying:
		_update_death_fade(delta)
		return

	if not _active:
		return

	_remaining -= delta
	if _remaining <= 0.0:
		_clear()
		return

	_phase += delta
	var pulse: float = 0.5 + 0.5 * sin(_phase * TAU * pulse_hz)
	var alpha: float = lerpf(min_alpha, peak_alpha, pulse)
	alpha *= clampf(_remaining / fade_out_time, 0.0, 1.0)
	_tint.color.a = alpha


## Deepens the tint from the impact red toward solid black across the fade time.
func _update_death_fade(delta: float) -> void:
	_death_elapsed += delta
	var t: float = clampf(_death_elapsed / maxf(death_fade_time, 0.01), 0.0, 1.0)
	_tint.color = Color(
		lerpf(flash_color.r, 0.0, t),
		lerpf(flash_color.g, 0.0, t),
		lerpf(flash_color.b, 0.0, t),
		lerpf(death_start_alpha, 1.0, t))
	if t >= 1.0:
		_dying = false


## Hides the overlay and resets its pulse and death-fade state.
func _clear() -> void:
	_active = false
	_dying = false
	_remaining = 0.0
	_death_elapsed = 0.0
	_tint.color.a = 0.0
	_tint.visible = false

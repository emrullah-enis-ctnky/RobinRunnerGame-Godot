class_name CoinCounterHUD
extends CanvasLayer
## Displays the current run's collected coin count in the top-left corner.

const GOLD_COLOR: Color = Color(1.0, 0.78, 0.12)
const GOLD_RIM_COLOR: Color = Color(0.85, 0.56, 0.04)
const BG_COLOR: Color = Color(0.08, 0.1, 0.14, 0.68)
const PULSE_COLOR: Color = Color(1.0, 0.92, 0.45)

@onready var _panel: Control = $Root/Panel
@onready var _count_label: Label = $Root/Panel/Count

var _pulse_tween: Tween


## Connects to EventBus.coins_updated and initializes the displayed count.
func _ready() -> void:
	if _panel != null:
		_panel.draw.connect(_draw_panel)
		_panel.queue_redraw()

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").coins_updated.connect(_on_coins_updated)

	var initial: int = 0
	if has_node("/root/ScoreManager"):
		initial = get_node("/root/ScoreManager").coins_collected
	_set_count(initial, false)


## Updates the label and plays a subtle golden pulse when coins increase.
func _on_coins_updated(coin_count: int) -> void:
	_set_count(coin_count, coin_count > 0)


## Applies the coin count text and optional pickup pulse.
func _set_count(coin_count: int, pulse: bool) -> void:
	if _count_label == null:
		return
	_count_label.text = str(coin_count)
	if not pulse:
		_count_label.modulate = Color.WHITE
		return

	if _pulse_tween != null and _pulse_tween.is_running():
		_pulse_tween.kill()
	_count_label.modulate = PULSE_COLOR
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(1.12, 1.12)
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(_count_label, "modulate", Color.WHITE, 0.22)
	_pulse_tween.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Draws the rounded dark pill background and stylized golden star coin icon.
func _draw_panel() -> void:
	var rect := Rect2(Vector2.ZERO, _panel.size)
	_panel.draw_rect(rect, BG_COLOR, true)

	var center := Vector2(24.0, _panel.size.y * 0.5)
	_panel.draw_circle(center, 14.0, GOLD_RIM_COLOR)
	_panel.draw_circle(center, 11.0, GOLD_COLOR)
	_draw_star(center, 6.8, 3.3, GOLD_RIM_COLOR)


## Draws a 5-point star inside the coin icon.
func _draw_star(center: Vector2, outer_r: float, inner_r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var r: float = outer_r if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	_panel.draw_colored_polygon(pts, color)

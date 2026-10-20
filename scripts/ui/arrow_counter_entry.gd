class_name ArrowCounterEntry
extends Control
## One row in the arrow counter HUD: a drawn arrow icon plus its count.

const SLIDE_TIME: float = 0.25
const PULSE_SCALE: Vector2 = Vector2(1.3, 1.3)
const PULSE_GAIN_COLOR: Color = Color(0.35, 1.0, 0.4)
const PULSE_SPEND_COLOR: Color = Color(1.0, 0.35, 0.35)

@export var icon_color: Color = Color(0.82, 0.62, 0.34)

var slot_y: float = 0.0

var _count: int = 0
var _tween: Tween

@onready var _label: Label = $Count


## Prepares the pivot so pulses scale around the row's centre.
func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(_on_resized)
	queue_redraw()


## Keeps the draw centered and the pivot correct when the row is resized.
func _on_resized() -> void:
	pivot_offset = size * 0.5
	queue_redraw()


## Draws the arrow icon on the left of the row.
func _draw() -> void:
	var mid: float = size.y * 0.5
	var x: float = 2.0
	draw_line(Vector2(x, mid), Vector2(x + 18.0, mid), icon_color, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + 30.0, mid),
		Vector2(x + 18.0, mid - 6.0),
		Vector2(x + 18.0, mid + 6.0)
	]), icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + 2.0, mid),
		Vector2(x - 2.0, mid - 7.0),
		Vector2(x + 8.0, mid - 2.0)
	]), icon_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + 2.0, mid),
		Vector2(x - 2.0, mid + 7.0),
		Vector2(x + 8.0, mid + 2.0)
	]), icon_color)


## Updates the displayed count.
func set_count(value: int) -> void:
	_count = value
	if _label:
		_label.text = str(value)


## Slides the row down into its slot from above.
func appear(slot: float) -> void:
	slot_y = slot
	visible = true
	position = Vector2(position.x, slot - size.y - 8.0)
	_restart_tween()
	modulate.a = 0.0
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:y", slot, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, SLIDE_TIME * 0.7)


## Slides the row to a new slot when the counter reflows.
func move_to_slot(slot: float) -> void:
	slot_y = slot
	if not visible:
		return
	_restart_tween()
	_tween.tween_property(self, "position:y", slot, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Slides the row out and hides it, exiting upward or downward.
func exit(upward: bool) -> void:
	_restart_tween()
	var target_y: float = slot_y - size.y - 12.0 if upward else slot_y + size.y + 12.0
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:y", target_y, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, SLIDE_TIME * 0.8)
	_tween.chain().tween_callback(hide)


## Flashes the row green and scales it up when ammo is gained.
func pulse_gain() -> void:
	_pulse(PULSE_GAIN_COLOR)


## Flashes the row red and scales it up when ammo is spent.
func pulse_spend() -> void:
	_pulse(PULSE_SPEND_COLOR)


## Scales the row up and tints it before settling back.
func _pulse(color: Color) -> void:
	_restart_tween()
	modulate = color
	_tween.tween_property(self, "scale", PULSE_SCALE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.3)


## Kills any running animation and restores the resting transform.
func _restart_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector2.ONE
	modulate = Color.WHITE
	_tween = create_tween()

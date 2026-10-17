class_name ArrowCounterHUD
extends CanvasLayer
## Renders the quiver counts as animated rows in the top-right corner.

const GameConfig = preload("res://scripts/common/game_config.gd")
const ENTRY_SCENE: PackedScene = preload("res://scenes/ui/arrow_counter_entry.tscn")
const ENTRY_WIDTH: float = 120.0
const ROW_HEIGHT: float = 48.0
const ROW_GAP: float = 6.0
const ICON_COLOR_NORMAL: Color = Color(0.82, 0.62, 0.34)
const ICON_COLOR_FLAME: Color = Color(1.0, 0.5, 0.12)

@onready var _entries_root: Control = $Root/Entries

var _order: Array = [GameConfig.ARROW_TYPE_NORMAL, GameConfig.ARROW_TYPE_FLAME]
var _entries: Dictionary = {}
var _counts: Dictionary = {}
var _visible_types: Array = []


## Builds both rows and binds to the quiver signals.
func _ready() -> void:
	_build_entries()
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.arrow_ammo_updated.connect(_on_ammo_updated)

	var normal: int = 0
	var flame: int = 0
	if has_node("/root/AbilityManager"):
		var ability: Node = get_node("/root/AbilityManager")
		normal = ability.get_ammo(GameConfig.ARROW_TYPE_NORMAL)
		flame = ability.get_ammo(GameConfig.ARROW_TYPE_FLAME)
	_on_ammo_updated(normal, flame)


## Instantiates and pre-hides the two arrow rows.
func _build_entries() -> void:
	for arrow_type in _order:
		var entry: ArrowCounterEntry = ENTRY_SCENE.instantiate()
		entry.name = arrow_type
		entry.icon_color = ICON_COLOR_FLAME if arrow_type == GameConfig.ARROW_TYPE_FLAME else ICON_COLOR_NORMAL
		entry.size = Vector2(ENTRY_WIDTH, ROW_HEIGHT)
		entry.position = Vector2.ZERO
		entry.visible = false
		_entries_root.add_child(entry)
		_entries[arrow_type] = entry
		_counts[arrow_type] = 0


## Applies both quiver counts received from the event bus.
func _on_ammo_updated(normal_count: int, flame_count: int) -> void:
	_apply(GameConfig.ARROW_TYPE_NORMAL, normal_count)
	_apply(GameConfig.ARROW_TYPE_FLAME, flame_count)


## Applies one type's count with the right appear, exit, or pulse behaviour.
func _apply(arrow_type: String, new_count: int) -> void:
	var entry: ArrowCounterEntry = _entries.get(arrow_type)
	if entry == null:
		return

	var old_count: int = int(_counts.get(arrow_type, 0))
	entry.set_count(new_count)
	_counts[arrow_type] = new_count

	if new_count > 0 and old_count == 0:
		if not _visible_types.has(arrow_type):
			_visible_types.append(arrow_type)
		_layout(true)
	elif new_count == 0 and old_count > 0:
		_visible_types.erase(arrow_type)
		entry.exit(_is_top(arrow_type))
		_layout(false)
	elif new_count > old_count:
		entry.pulse_gain()
	elif new_count < old_count:
		entry.pulse_spend()


## Returns true when a type sits at the top of the counter (exits upward).
func _is_top(arrow_type: String) -> bool:
	return arrow_type == GameConfig.ARROW_TYPE_NORMAL


## Reflows the visible rows and slides newly shown rows down into place.
func _layout(animate_appear: bool) -> void:
	var y: float = 0.0
	for i in range(_visible_types.size()):
		var arrow_type: String = _visible_types[i]
		var entry: ArrowCounterEntry = _entries[arrow_type]
		var is_new: bool = not entry.visible
		if animate_appear and is_new:
			entry.appear(y)
		else:
			entry.move_to_slot(y)
		y += ROW_HEIGHT + ROW_GAP
class_name TrackChunk
extends Node3D
## Base class for modular track chunks in RobinRunner.
## Manages standardized entry/exit snap points, collision ground, and lane markers.

@export var chunk_length: float = GameConfig.CHUNK_LENGTH

@onready var start_anchor: Marker3D = $StartAnchor
@onready var end_anchor: Marker3D = $EndAnchor
@onready var lane_markers: Node3D = $LaneMarkers
@onready var pickups: Node3D = get_node_or_null("Pickups")

# State tracking for object pooling
var is_active: bool = false


func _ready() -> void:
	_ensure_anchors()


## Returns the local or global exit snap point for attaching the next chunk.
func get_exit_position() -> Vector3:
	if end_anchor:
		return end_anchor.global_position
	return global_position + Vector3(0.0, 0.0, -chunk_length)


## Returns the local or global entry snap point.
func get_entry_position() -> Vector3:
	if start_anchor:
		return start_anchor.global_position
	return global_position


## Called when the chunk is acquired from the pool and placed in the world.
func activate(spawn_position: Vector3) -> void:
	global_position = spawn_position
	is_active = true
	show()
	set_process(true)
	set_physics_process(true)
	_restore_pickups()


## Called when the chunk passes behind the player and is returned to the pool.
func deactivate() -> void:
	is_active = false
	hide()
	set_process(false)
	set_physics_process(false)
	global_position = Vector3(0.0, -500.0, 0.0)


## Resets collected pickups so a recycled chunk can present them again.
func _restore_pickups() -> void:
	if pickups == null:
		return
	_restore_descendants(pickups)


## Recursively calls respawn() on any descendant that supports it.
func _restore_descendants(node: Node) -> void:
	for child in node.get_children():
		if child.has_method("respawn"):
			child.respawn()
		elif child.has_method("restore"):
			child.restore()
		_restore_descendants(child)


## Verifies or dynamically creates anchor markers if not explicitly set in editor.
func _ensure_anchors() -> void:
	if not has_node("StartAnchor"):
		var marker: Marker3D = Marker3D.new()
		marker.name = "StartAnchor"
		marker.position = Vector3.ZERO
		add_child(marker)
		start_anchor = marker

	if not has_node("EndAnchor"):
		var marker: Marker3D = Marker3D.new()
		marker.name = "EndAnchor"
		marker.position = Vector3(0.0, 0.0, -chunk_length)
		add_child(marker)
		end_anchor = marker

class_name ObjectPool
extends RefCounted
## Generic high-performance Object Pool utility for recycling Node instances.
## Minimizes runtime heap allocations and garbage collection spikes in endless runner loops.

var scene: PackedScene
var parent_node: Node
var max_size: int = 100

var available_pool: Array[Node] = []
var active_pool: Array[Node] = []


func _init(p_scene: PackedScene, p_parent: Node, initial_capacity: int = 0, p_max_size: int = 100) -> void:
	scene = p_scene
	parent_node = p_parent
	max_size = p_max_size

	if initial_capacity > 0:
		prewarm(initial_capacity)


## Pre-instantiates a batch of objects to avoid runtime instantiation hitching.
func prewarm(count: int) -> void:
	for i in range(count):
		if get_total_count() >= max_size:
			break
		var instance: Node = _create_new_instance()
		if is_instance_valid(instance):
			available_pool.append(instance)


## Retrieves an inactive instance from the pool or instantiates a new one if permitted.
func acquire() -> Node:
	var instance: Node = null

	while not available_pool.is_empty():
		var candidate: Node = available_pool.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break

	if instance == null:
		if get_total_count() < max_size:
			instance = _create_new_instance()
		else:
			push_warning("ObjectPool: Maximum pool size reached (%d). Cannot allocate new instance." % max_size)
			return null

	if instance != null:
		active_pool.append(instance)

	return instance


## Releases an active instance back to the available pool.
func release(instance: Node) -> void:
	if not is_instance_valid(instance):
		return

	var active_idx: int = active_pool.find(instance)
	if active_idx != -1:
		active_pool.remove_at(active_idx)

	if instance.has_method("deactivate"):
		instance.deactivate()
	elif instance is CanvasItem or instance is Node3D:
		instance.visible = false

	if not available_pool.has(instance):
		available_pool.append(instance)


## Clears and frees all managed instances.
func clear() -> void:
	for node in active_pool:
		if is_instance_valid(node):
			node.queue_free()
	active_pool.clear()

	for node in available_pool:
		if is_instance_valid(node):
			node.queue_free()
	available_pool.clear()


## Returns the number of currently active objects in the game world.
func get_active_count() -> int:
	return active_pool.size()


## Returns the number of standby objects waiting in the pool.
func get_available_count() -> int:
	return available_pool.size()


## Returns the total number of managed objects across both pools.
func get_total_count() -> int:
	return active_pool.size() + available_pool.size()


func _create_new_instance() -> Node:
	if scene == null:
		push_error("ObjectPool: PackedScene is null.")
		return null

	var instance: Node = scene.instantiate()
	if parent_node != null and is_instance_valid(parent_node):
		parent_node.add_child(instance)

	if instance.has_method("deactivate"):
		instance.deactivate()
	elif instance is CanvasItem or instance is Node3D:
		instance.visible = false

	return instance

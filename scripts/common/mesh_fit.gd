class_name MeshFit
extends RefCounted
## Normalizes imported model sizes so gameplay props share a consistent scale.

const _CORNER_SIGNS: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.0),
	Vector3(0.0, 1.0, 0.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(1.0, 1.0, 0.0),
	Vector3(1.0, 0.0, 1.0),
	Vector3(0.0, 1.0, 1.0),
	Vector3(1.0, 1.0, 1.0)
]


## Scales a node so its largest mesh dimension matches the target length.
## A cross-section scale below 1.0 thins the two shorter axes for slender props.
static func fit_longest_axis(node: Node3D, target_length: float, cross_section_scale: float = 1.0) -> void:
	var size: Vector3 = local_bounds(node).size
	var longest: float = maxf(size.x, maxf(size.y, size.z))
	if longest <= 0.0:
		return

	var base: float = target_length / longest
	var scale := Vector3.ONE * base
	if cross_section_scale != 1.0:
		if size.x == longest:
			scale.y *= cross_section_scale
			scale.z *= cross_section_scale
		elif size.y == longest:
			scale.x *= cross_section_scale
			scale.z *= cross_section_scale
		else:
			scale.x *= cross_section_scale
			scale.y *= cross_section_scale
	node.scale = scale


## Returns the local bounds of every mesh under a node, including transforms.
static func local_bounds(node: Node3D) -> AABB:
	var state: Dictionary = {"bounds": AABB(), "has": false}
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		_include_mesh(state, Transform3D.IDENTITY, node as MeshInstance3D)
	_collect_bounds(node, Transform3D.IDENTITY, state)
	if not state["has"]:
		return AABB()
	return state["bounds"]


## Returns the longest axis end in the node's own local space.
static func local_long_axis_point(node: Node3D, positive: bool) -> Vector3:
	var box: AABB = local_bounds(node)
	var point: Vector3 = box.get_center()
	if box.size.x >= box.size.y and box.size.x >= box.size.z:
		point.x = box.end.x if positive else box.position.x
	elif box.size.y >= box.size.z:
		point.y = box.end.y if positive else box.position.y
	else:
		point.z = box.end.z if positive else box.position.z
	return point


## Returns the position of the longest axis end after the node transform.
static func local_long_axis_end(node: Node3D, positive: bool) -> Vector3:
	return node.transform * local_long_axis_point(node, positive)


## Recursively merges mesh bounds into the shared state dictionary.
static func _collect_bounds(node: Node, to_node: Transform3D, state: Dictionary) -> void:
	for child in node.get_children():
		var child_transform: Transform3D = to_node
		if child is Node3D:
			child_transform = to_node * (child as Node3D).transform
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			_include_mesh(state, child_transform, child as MeshInstance3D)
		_collect_bounds(child, child_transform, state)


## Expands the accumulated bounds with one mesh instance's transformed corners.
static func _include_mesh(state: Dictionary, to_node: Transform3D, mesh_instance: MeshInstance3D) -> void:
	var box: AABB = mesh_instance.get_aabb()
	for corner_sign in _CORNER_SIGNS:
		var point: Vector3 = box.position + box.size * corner_sign
		var transformed: Vector3 = to_node * point
		if state["has"]:
			state["bounds"] = (state["bounds"] as AABB).expand(transformed)
		else:
			state["bounds"] = AABB(transformed, Vector3.ZERO)
			state["has"] = true

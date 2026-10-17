class_name MeshFit
extends RefCounted
## Normalizes imported model sizes so gameplay props share a consistent scale.


## Scales a node so its largest mesh dimension matches the target length.
static func fit_longest_axis(node: Node3D, target_length: float) -> void:
	var longest: float = _longest_mesh_dimension(node)
	if longest <= 0.0:
		return
	node.scale = Vector3.ONE * (target_length / longest)


## Returns the largest dimension found across all mesh instances under a node.
static func _longest_mesh_dimension(node: Node) -> float:
	var longest: float = 0.0
	for child in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			var size: Vector3 = (child as MeshInstance3D).get_aabb().size
			longest = maxf(longest, maxf(size.x, maxf(size.y, size.z)))
		longest = maxf(longest, _longest_mesh_dimension(child))
	return longest
extends Node
## Automated unit test runner for RunnerCamera (tracking, dynamic FOV, screen shake).

const CameraScene: PackedScene = preload("res://scenes/camera/runner_camera.tscn")
const CameraScript = preload("res://scripts/camera/camera_controller.gd")
const GameConfig = preload("res://scripts/common/game_config.gd")


## Runs all camera controller unit tests upon entering the scene tree.
func _ready() -> void:
	print("==========================================")
	print("--- Running Camera Controller Tests ---")
	print("==========================================")
	var success: bool = true

	success = success and _test_camera_instantiation()
	success = success and _test_target_tracking()
	success = success and _test_dynamic_fov()
	success = success and _test_screen_shake_and_events()

	if success:
		print("==========================================")
		print("--- ALL CAMERA CONTROLLER TESTS PASSED ---")
		print("==========================================")
		get_tree().quit(0)
	else:
		printerr("==========================================")
		printerr("--- CAMERA CONTROLLER TESTS FAILED ---")
		printerr("==========================================")
		get_tree().quit(1)


## Tests camera scene instantiation and default properties.
func _test_camera_instantiation() -> bool:
	print("[TEST] Camera Instantiation...")
	var camera: Camera3D = CameraScene.instantiate() as Camera3D
	if not camera:
		printerr("FAIL: Could not instantiate RunnerCamera from scenes/camera/runner_camera.tscn")
		return false

	add_child(camera)

	if not camera.current:
		printerr("FAIL: Camera 'current' flag should be true by default")
		camera.queue_free()
		return false

	if camera.fov != 68.0:
		printerr("FAIL: Default camera FOV should be 68.0, got: ", camera.fov)
		camera.queue_free()
		return false

	camera.queue_free()
	print("  -> Camera Instantiation passed.")
	return true


## Tests forward and lateral tracking behavior relative to a target node.
func _test_target_tracking() -> bool:
	print("[TEST] Target Tracking...")
	var camera: Camera3D = CameraScene.instantiate() as Camera3D
	add_child(camera)

	var target_dummy: Node3D = Node3D.new()
	target_dummy.position = Vector3(0.0, 0.0, 0.0)
	add_child(target_dummy)

	camera.set_target(target_dummy)

	# Simulate frame update
	camera._update_tracking(0.1)

	# Z should match target.z + follow_offset.z
	var expected_z: float = target_dummy.global_position.z + camera.follow_offset.z
	if absf(camera.global_position.z - expected_z) > 0.01:
		printerr("FAIL: Camera Z tracking mismatch, expected: ", expected_z, " got: ", camera.global_position.z)
		_cleanup(camera, target_dummy)
		return false

	# Move target forward along -Z and right to lane 1 (2.0)
	target_dummy.global_position = Vector3(2.0, 0.0, -15.0)
	camera._update_tracking(0.1)

	var expected_new_z: float = -15.0 + camera.follow_offset.z
	if absf(camera.global_position.z - expected_new_z) > 0.01:
		printerr("FAIL: Forward target follow failed")
		_cleanup(camera, target_dummy)
		return false

	# Lateral X should move toward 2.0
	if camera.global_position.x <= 0.0:
		printerr("FAIL: Lateral camera follow did not move toward positive X lane")
		_cleanup(camera, target_dummy)
		return false

	_cleanup(camera, target_dummy)
	print("  -> Target Tracking passed.")
	return true


## Tests dynamic field-of-view scaling under varying speeds.
func _test_dynamic_fov() -> bool:
	print("[TEST] Dynamic FOV...")
	var camera: Camera3D = CameraScene.instantiate() as Camera3D
	add_child(camera)

	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.current_speed = GameConfig.INITIAL_FORWARD_SPEED

		# At base speed, target FOV remains near base_fov
		camera._update_dynamic_fov(0.5)
		if camera.fov > 70.0:
			printerr("FAIL: FOV expanded while at base initial speed")
			camera.queue_free()
			return false

		# Set speed to maximum cap
		gm.current_speed = GameConfig.MAX_FORWARD_SPEED
		for i: int in range(10):
			camera._update_dynamic_fov(0.1)

		if camera.fov <= 70.0:
			printerr("FAIL: Dynamic FOV failed to scale up at max forward speed, got: ", camera.fov)
			camera.queue_free()
			return false

		gm.reset_game()

	camera.queue_free()
	print("  -> Dynamic FOV passed.")
	return true


## Tests trauma accumulation, clamping, decay, and EventBus impact triggering.
func _test_screen_shake_and_events() -> bool:
	print("[TEST] Screen Shake & Events...")
	var camera: Camera3D = CameraScene.instantiate() as Camera3D
	add_child(camera)

	# Initial trauma should be 0
	if camera.trauma != 0.0:
		printerr("FAIL: Initial trauma should be 0")
		camera.queue_free()
		return false

	# Add trauma and test clamping
	camera.add_trauma(0.4)
	if absf(camera.trauma - 0.4) > 0.01:
		printerr("FAIL: Trauma addition failed")
		camera.queue_free()
		return false

	camera.add_trauma(2.0)
	if camera.trauma != 1.0:
		printerr("FAIL: Trauma did not clamp to maximum cap of 1.0")
		camera.queue_free()
		return false

	# Test decay over time
	camera._update_screen_shake(0.2)
	if camera.trauma >= 1.0:
		printerr("FAIL: Trauma did not decay after update")
		camera.queue_free()
		return false

	# Test EventBus player_hit_hazard signal trigger
	camera.trauma = 0.0
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		bus.player_hit_hazard.emit("barrier")
		if camera.trauma <= 0.0:
			printerr("FAIL: EventBus player_hit_hazard did not trigger screen shake trauma")
			camera.queue_free()
			return false

	camera.queue_free()
	print("  -> Screen Shake & Events passed.")
	return true


## Safely frees nodes from the scene tree.
func _cleanup(node_a: Node, node_b: Node) -> void:
	if is_instance_valid(node_a):
		node_a.queue_free()
	if is_instance_valid(node_b):
		node_b.queue_free()

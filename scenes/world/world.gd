class_name World
extends Node3D
## Main 3D world scene hosting Player, RunnerCamera, and procedural TrackSpawner.

@onready var player: Node3D = $Player
@onready var camera: Node3D = $RunnerCamera
@onready var track_spawner: TrackSpawner = $TrackSpawner


func _ready() -> void:
	if OS.has_feature("web"):
		var sun: DirectionalLight3D = get_node_or_null("SunLight") as DirectionalLight3D
		if sun != null:
			sun.shadow_enabled = false
		if track_spawner != null:
			track_spawner.initial_chunk_count = 4
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.reset_game()

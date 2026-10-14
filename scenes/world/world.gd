class_name World
extends Node3D
## Main 3D world scene hosting Player, RunnerCamera, and procedural TrackSpawner.

@onready var player: Node3D = $Player
@onready var camera: Node3D = $RunnerCamera
@onready var track_spawner: TrackSpawner = $TrackSpawner


func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.start_game()

extends Node3D
## Test stage providing lighting, camera, and ground to test PlayerController interactively.

@onready var player: PlayerController = $Player


## Prepares the test run and initializes GameManager loop.
func _ready() -> void:
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.start_game()

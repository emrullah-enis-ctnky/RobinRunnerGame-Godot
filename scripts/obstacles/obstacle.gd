class_name Obstacle
extends StaticBody3D
## Base class for static track hazards that stagger or end a run on contact.

@export var hazard_type: String = "obstacle"


## Returns the hazard label reported to the EventBus when the player collides.
func get_hazard_type() -> String:
	return hazard_type

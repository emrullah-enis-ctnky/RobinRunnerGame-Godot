class_name Obstacle
extends StaticBody3D
## Base class for static track hazards that stagger or end a run on contact.

@export var hazard_type: String = "obstacle"
@export var is_lethal: bool = false


## Returns the hazard label reported to the EventBus when the player collides.
func get_hazard_type() -> String:
	return hazard_type


## Returns true when a single contact must end the run, bypassing the stumble allowance.
func is_lethal_hazard() -> bool:
	return is_lethal

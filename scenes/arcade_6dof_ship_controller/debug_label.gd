extends Label

@onready var ship: RigidBody3D = $"../../Ship"


@export var show_ship_details: bool = true
@export var show_ship_controller: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = ""
	if show_ship_details and is_instance_valid(ship):
		text += """--- Ship---
			velocity: %s
		""" % [
			str(ship.linear_velocity)
		]
		

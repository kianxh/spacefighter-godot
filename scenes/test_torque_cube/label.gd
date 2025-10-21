extends Label

@onready var ship: ShipRigidBody3D = $"../RigidBody3D"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var props = [
		"--- inputs ---",
		"u_move",
		"u_turn",
		"--- calc ---",
		"world_basis",
		"omega_local",
		"target_rate_local",
		"err_rate",
		"torque_local",
		"torque_world"
	]
	text = ""
	for prop_name in props:
		if !str(prop_name).begins_with("-"):
			text += ((prop_name + ": %s") % ship.get(prop_name)) + "\n" 
		else:
			text += prop_name + "\n"
		

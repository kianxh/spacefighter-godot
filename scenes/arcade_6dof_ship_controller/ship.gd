extends RigidBody3D

var move_input: Vector3 = Vector3.ZERO
var rotation_input: Vector3 = Vector3.ZERO

var current_velocity := Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _unhandled_input(event: InputEvent) -> void:
	move_input = _get_move_input()
	rotation_input = _get_rotation_input()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	current_velocity += move_input * 10 * delta
	
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	linear_velocity = current_velocity

# Returns inputs for linear movement as Vector3 (sway, heave & surge - in this order).
func _get_move_input() -> Vector3:
	var surge = Input.get_action_strength("ship_move_surge_reverse") - Input.get_action_strength("ship_move_surge_forward")
	var sway = Input.get_action_strength("ship_move_sway_right") - Input.get_action_strength("ship_move_sway_left")
	var heave = Input.get_action_strength("ship_move_heave_up") - Input.get_action_strength("ship_move_heave_down")
	
	return Vector3(sway, heave, surge)
	
# Returns inputs for rotations as Vector3 (pitch, yaw and roll - in this order)
func _get_rotation_input() -> Vector3:
	# Pitch along X-axis
	var pitch = 0
	# Yaw along Y-axis
	var yaw = 0
	# Roll along Z-axis
	var roll = 0
	
	return Vector3(pitch, yaw, roll)

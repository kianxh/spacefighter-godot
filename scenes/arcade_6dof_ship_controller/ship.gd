extends RigidBody3D
class_name ShipRigidBody3D

var move_input: Vector3 = Vector3.ZERO
var rotation_input: Vector3 = Vector3.ZERO

var current_velocity := Vector3.ZERO
var current_angular_velocity := Vector3.ZERO

@export var thrust_speed := 100.0
@export var max_rate_deg: Vector3 = Vector3(200, 200, 200)	# deg/s about local X/Y/Z

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
	# Thrust: local → world
	var local_force := move_input * thrust_speed
	apply_central_force(basis * local_force)

	# Turn by commanding angular velocity in rad/s (local axes)
	#var max_rate := Vector3(
		#deg_to_rad(max_rate_deg.x),
		#deg_to_rad(max_rate_deg.y),
		#deg_to_rad(max_rate_deg.z)
	#)
	
	#angular_velocity = Vector3(
		#rotation_input.x * max_rate.x,
		#rotation_input.y * max_rate.y,
		#rotation_input.z * max_rate.z
	#)
	
	# --- Build a local quaternion delta from desired body rates (no Euler) ---
	# Convert desired body rates to radians/s first:
	var max_rate_rad := Vector3(
		deg_to_rad(max_rate_deg.x) * rotation_input.x,
		deg_to_rad(max_rate_deg.y) * rotation_input.y,
		deg_to_rad(max_rate_deg.z) * rotation_input.z
	)
	
	# Small rotation this step around each local axis:
	var qx := Quaternion(Vector3.RIGHT,   max_rate_rad.x * delta)	# pitch
	var qy := Quaternion(Vector3.UP,      max_rate_rad.y * delta)	# yaw
	var qz := Quaternion(Vector3.FORWARD, max_rate_rad.z * delta)	# roll

	# Compose in LOCAL space. Order choice is mostly irrelevant for small dt.
	# Here: yaw * pitch * roll
	var dq_local: Quaternion = qy * qx * qz

	# Convert the local delta quaternion to instantaneous angular velocity ω_local:
	var angle := dq_local.get_angle()			# radians in (0..π]
	var omega_local := Vector3.ZERO
	if angle > 1e-8:
		var axis := dq_local.get_axis().normalized()
		omega_local = axis * (angle / delta)		# ω = axis * dθ/dt

	# Optional: clamp magnitude to your max single-axis rate (safety cap)
	var max_mag := deg_to_rad(max(max_rate_deg.x, max(max_rate_deg.y, max_rate_deg.z)))
	var mag := omega_local.length()
	if mag > max_mag:
#		omega_local *= max_mag / mag
		omega_local = omega_local * (max_mag / mag)

	# Godot stores angular_velocity in **world space**. Convert local → world.
	angular_velocity = global_transform.basis * omega_local

		

	
#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#linear_velocity = current_velocity

# Returns inputs for linear movement as Vector3 (sway, heave & surge - in this order).
func _get_move_input() -> Vector3:
	var surge = Input.get_action_strength("ship_move_surge_reverse") - Input.get_action_strength("ship_move_surge_forward")
	var sway = Input.get_action_strength("ship_move_sway_right") - Input.get_action_strength("ship_move_sway_left")
	var heave = Input.get_action_strength("ship_move_heave_up") - Input.get_action_strength("ship_move_heave_down")
	
	return Vector3(sway, heave, surge)
	
# Returns inputs for rotations as Vector3 (pitch, yaw and roll - in this order)
func _get_rotation_input() -> Vector3:
	# Pitch along X-axis
	var pitch = Input.get_action_strength("ship_rotate_pitch_up") - Input.get_action_strength("ship_rotate_pitch_down")
	# Yaw along Y-axis
	var yaw = Input.get_action_strength("ship_rotate_yaw_left") - Input.get_action_strength("ship_rotate_yaw_right")
	# Roll along Z-axis
	var roll = Input.get_action_strength("ship_rotate_roll_left") - Input.get_action_strength("ship_rotate_roll_right")
	
	return Vector3(pitch, yaw, roll)

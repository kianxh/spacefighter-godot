extends CharacterBody3D
class_name ArcadeSixDofController

@onready var aim_input: AimInput = $Inputs/Aim
@onready var throttle: ThrottleInput = $Inputs/Throttle


@export var sway_speed: float = 20.0	# m/s along local +X/-X (sway)
@export var heave_speed: float = 20.0	# m/s along local +Y/-Y (heave)
@export var surge_speed: float = 60.0	# m/s along local +Z/-Z (surge)

@export var pitch_rate_deg: float = 120.0	# deg/s around local X (pitch)
@export var yaw_rate_deg: float = 120.0		# deg/s around local Y (yaw)
@export var roll_rate_deg: float = 180.0	# deg/s around local Z (roll)



func _physics_process(delta: float) -> void:
	# raw inputs (no smoothing)
	var lin: Vector3 = get_movement_input()	# (sway, heave, surge)
	var ang2: Vector3 = get_rotation_input()	# (pitch, yaw, roll)
	var aim_cmd := aim_input.get_aim_direction() * aim_input.get_aim_strength()
	var ang: Vector3 = Vector3(-aim_cmd.y, ang2.y, aim_cmd.x)
	

	# rotations in local space
	if ang.x != 0.0:
		rotate_object_local(Vector3.RIGHT, deg_to_rad(pitch_rate_deg) * ang.x * delta)
	if ang.y != 0.0:
		rotate_object_local(Vector3.UP, deg_to_rad(yaw_rate_deg) * ang.y * delta)
	if ang.z != 0.0:
		# Note: Vector3.FORWARD is -Z in Godot. If roll feels inverted, swap to Vector3.BACK or flip the sign.
		rotate_object_local(Vector3.FORWARD, deg_to_rad(roll_rate_deg) * ang.z * delta)

	# local linear velocity -> world, then move with collisions
	var local_vel := Vector3(
		lin.x * sway_speed,
		lin.y * heave_speed,
		lin.z * surge_speed
	)
	velocity = transform.basis * local_vel
	move_and_slide()
	

# Returns inputs for linear movement as Vector3 (sway, heave & surge - in this order).
func get_movement_input() -> Vector3:
	var surge = Input.get_action_strength("ship_move_surge_reverse") - Input.get_action_strength("ship_move_surge_forward")
	
	var surge2 := -throttle.get_strength()
	
	var sway = Input.get_action_strength("ship_move_sway_right") - Input.get_action_strength("ship_move_sway_left")
	var heave = Input.get_action_strength("ship_move_heave_up") - Input.get_action_strength("ship_move_heave_down")
	
	return Vector3(sway, heave, surge2)
	
# Returns inputs for rotations as Vector3 (pitch, yaw and roll - in this order)
func get_rotation_input() -> Vector3:
	# Pitch along X-axis
	var pitch = Input.get_action_strength("ship_rotate_pitch_up") - Input.get_action_strength("ship_rotate_pitch_down")
	# Yaw along Y-axis
	var yaw = Input.get_action_strength("ship_rotate_yaw_left") - Input.get_action_strength("ship_rotate_yaw_right")
	# Roll along Z-axis
	var roll = Input.get_action_strength("ship_rotate_roll_right") - Input.get_action_strength("ship_rotate_roll_left")
	
	return Vector3(pitch, yaw, roll)

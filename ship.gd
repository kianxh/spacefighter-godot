# Ship.gd (extends RigidBody3D)
extends RigidBody3D

@onready var cam: Camera3D = $Camera3D
@onready var aim: AimController = $ShipAimController

# --- Roll tuning (resolution-agnostic) ---
@export var roll_max_rate_deg: float = 180.0     # max commanded roll rate (deg/s) at full input
@export var roll_rate_kp: float = 12.0           # P on roll rate error
@export var roll_rate_kd: float = 2.0            # D on measured roll rate
@export var roll_autolevel_kp: float = 3.0       # pulls bank back to 0 when no input
@export var roll_torque_scale: float = 1.0       # final scalar if your hull is heavy/light
@export var roll_strength_curve: Curve           # optional response shaping (0..1 -> 0..1)

func _physics_process(_delta: float) -> void:
	if aim == null:
		return

	# --- Resolution-free inputs from AimController ---
	var dir: Vector2 = aim.get_aim_direction()   # normalized, Zero inside deadzone
	var s: float = aim.get_aim_strength()        # 0..1, deadzone-aware

	# Optional shaping (ease-in). If no curve, simple quadratic.
	if roll_strength_curve:
		s = roll_strength_curve.sample_baked(clamp(s, 0.0, 1.0))
	else:
		s = s * s

	# Final roll input in [-1..1] uses only horizontal direction
	var roll_input: float = clamp(dir.x, -1.0, 1.0) * s

	# Target roll rate
	var target_rate: float = deg_to_rad(roll_max_rate_deg) * roll_input

	# Current angular velocity in local space (z = bank rate)
	var w_local: Vector3 = global_transform.basis.inverse() * angular_velocity
	var rate_err: float = target_rate - w_local.z

	# Inertia compensation (keeps gains consistent across different hulls)
	var Iz = max(inertia.z, 0.001)
	var torque_z = (roll_rate_kp * Iz) * rate_err - (roll_rate_kd * Iz) * w_local.z

	# Auto-level when no input
	if abs(roll_input) < 0.01:
		var bank: float = global_transform.basis.get_euler().z
		torque_z += -bank * roll_autolevel_kp * Iz

	# Apply local Z torque → world
	var torque_world := global_transform.basis * Vector3(0.0, 0.0, torque_z) * roll_torque_scale
	apply_torque(torque_world)

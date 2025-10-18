extends RigidBody3D

@onready var cam: Camera3D = $Camera3D
@onready var hud: Label = $CanvasLayer/Hud
@onready var crosshair: TextureRect = $CanvasLayer/Crosshair
# Debug hud
@onready var debug_hud: Control = $CanvasLayer/DebugHud
@onready var ship_aim_label: Label = $CanvasLayer/DebugHud/ShipAimLabel


# --- Tuning (start conservative, tweak while flying) ---
var max_speed: float = 200.0          # m/s, forward or reverse
var target_speed: float = 0.0         # setpoint we control toward
var throttle_step: float = 10.0       # m/s per tap

var max_thrust: float = 20000.0       # N (mass*accel). With mass=1000, ~20 m/s^2
var speed_kp: float = 400.0           # P controller for speed hold
var speed_ki: float = 0.0             # leave 0 for now (P-only is fine to start)
var speed_kd: float = 0.0

var ang_kp: float = 1800.0               # orientation PD (torque)
var ang_kd: float = 2.5               # damp wobble

var lateral_dampen: float = 3000.0    # fights sideways drift (flight assist)
var vertical_dampen: float = 3000.0

var integral_accum: float = 0.0       # (if you later try PI/PID)

var aim_pos: Vector2 = Vector2(0, 0)             # our virtual cursor
var aim_offset: Vector2 = Vector2(0,0)
var aim_min_offset: float = 50
var aim_max_offset: float = 320.0   # clamp distance from screen center (px)

# --- Roll tuning ---
var max_roll_rate: float = 2.5        # rad/s when holding Q/E (~143 deg/s)
var roll_kp: float = 50.0             # how hard we chase desired roll rate
var roll_kd: float = 0.0              # leave 0 for now
var roll_torque_limit: float = 3000.0 # clamp so we don't overdo it

# Optional auto-level (align ship 'up' to camera 'up' a bit when no input)
var autolevel_strength: float = 0.8   # 0 = off, 0.5..1.0 = subtle, >1 = strong



func _ready() -> void:
	_lock_mouse()
	

func _lock_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var viewport_center = get_viewport().size * 0.5
	Input.warp_mouse(viewport_center)
	aim_pos = viewport_center
	

func _unhandled_input(event: InputEvent) -> void:
	
	# Lock mouse when click on window
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				_lock_mouse()
				return  # don't process further clicks for this event
	
	# 
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# move by delta
		aim_pos += event.relative
		# clamp to a box around screen center
		var center = get_viewport().size * 0.5
		aim_offset = aim_pos - center
		if aim_offset.length() > aim_max_offset:
			aim_offset = aim_offset.normalized() * aim_max_offset
		
		aim_pos = center + aim_offset
	
	if event.is_action_pressed("toggle_mouse_capture"):
		var m = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if m == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("throttle_up"):
		target_speed = clamp(target_speed + throttle_step, -max_speed, max_speed)
	if event.is_action_pressed("throttle_down"):
		target_speed = clamp(target_speed - throttle_step, -max_speed, max_speed)
		


func _process(delta: float) -> void:
	if is_instance_valid(crosshair):
		crosshair.position = aim_pos - crosshair.pivot_offset
		crosshair.visible = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		
	_update_hud()



func _physics_process(delta: float) -> void:
	# 1) Aim: rotate ship toward mouse ray direction
	_apply_aim_torque(delta)

	# 2) Speed hold: push/pull along forward to match target_speed
	_apply_speed_control(delta)

	# 3) Optional flight-assist: damp lateral/vertical drift
	_apply_inertial_dampeners()

	# 4) HUD
	var fwd := -global_transform.basis.z
	var cur_speed := linear_velocity.dot(fwd)
	hud.text = "Target: %s  |  Speed: %s" % [target_speed, cur_speed]

func _apply_aim_torque(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	var mp: Vector2
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mp = aim_pos if aim_offset.length() < aim_min_offset else get_viewport().size * 0.5               # use our virtual cursor
	else:
		mp = get_viewport().get_mouse_position()  # normal when not captured
	var want_dir_world: Vector3 = cam.project_ray_normal(mp).normalized()       # camera forward-ish through mouse
	var fwd: Vector3 = (-global_transform.basis.z).normalized()
	
	print(mp)

	# Axis-angle between current forward and desired direction
	var axis: Vector3 = fwd.cross(want_dir_world)
	var sin_angle: float = axis.length()
	if sin_angle < 1e-5:
		return
	axis = axis / sin_angle
	var angle_err: float = fwd.angle_to(want_dir_world)

	# PD: torque ~ proportional to angle error, minus angular velocity around that axis
	# NOTE: angular_velocity is in local space; transform axis accordingly for damping
	var ang_vel_world: Vector3 = global_transform.basis * angular_velocity
	var ang_vel_along_axis: float = ang_vel_world.dot(axis)

	var torque_mag: float = ang_kp * angle_err - ang_kd * ang_vel_along_axis
	apply_torque(axis * torque_mag)

func _apply_speed_control(delta: float) -> void:
	var fwd: Vector3 = (-global_transform.basis.z).normalized()
	var cur_speed: float = linear_velocity.dot(fwd)
	var err: float = target_speed - cur_speed

	# Simple P (start here). Clamp by available thrust.
	var desired_force: float = clamp(speed_kp * err, -max_thrust, max_thrust)
	apply_central_force(fwd * desired_force)

	# (If you later want PI/PID: integrate err into integral_accum with clamping and add Ki * integral)

func _apply_inertial_dampeners() -> void:
	var fwd: Vector3 = (-global_transform.basis.z).normalized()
	var right: Vector3 = (global_transform.basis.x).normalized()
	var up: Vector3 = (global_transform.basis.y).normalized()

	var v: Vector3 = linear_velocity
	var forward_comp: float = v.dot(fwd)
	var lateral_comp: float = v.dot(right)
	var vertical_comp: float = v.dot(up)

	# Apply forces opposing lateral/vertical drift (do NOT cancel forward comp)
	apply_central_force(right * (-lateral_comp) * lateral_dampen)
	apply_central_force(up * (-vertical_comp) * vertical_dampen)

func _update_hud() -> void:
	if is_instance_valid(ship_aim_label):
		ship_aim_label.text = String().join([
			"aim_pos: %s",
			"aim_offset: %s",
			"aim_length: %s",
			"aim_:in_deadzone: %s",
		]) % ([
			aim_pos, aim_offset, aim_offset.length(), aim_offset.length() < aim_min_offset
		])
		#[] Stri "aim_pos: %s\naim_deadzone: %s\naim_length: %s" % [
			#str(aim_pos), 
			#str(aim_pos.length() < aim_min_deadzone), 
			#str(aim_pos.length())]

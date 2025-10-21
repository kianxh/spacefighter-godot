# Spacefighter.gd (Godot 4.5.1)
extends RigidBody3D
class_name ShipRigidBody3D

# --- Public API (normalized inputs; setze diese pro Frame von deinem Input-System) ---
@export var move: Vector3 = Vector3.ZERO	# (x=sway, y=heave, z=thrust) in [-1..1]
@export var turn: Vector3 = Vector3.ZERO	# (x=pitch, y=yaw, z=roll)   in [-1..1]

# --- Tuning: Raten (°/s) & Geschwindigkeiten (m/s) ---
@export var max_rate_deg: Vector3 = Vector3(200.0, 200.0, 200.0)	# pitch, yaw, roll
@export var max_speed: Vector3 = Vector3(180.0, 180.0, 180.0)		# sway, heave, thrust (|x|, |y|, |–z|)

# --- Regler-Gewinne (P auf Rate/Geschwindigkeit, D = Velocity-Dämpfung) ---
@export var kp_ang: Vector3 = Vector3(20,20,20)
@export var kd_ang: Vector3 = Vector3(12,12,12)
@export var kp_lin: Vector3 = Vector3(300.0, 300.0, 500.0)
@export var kd_lin: Vector3 = Vector3(60.0, 60.0, 90.0)

# --- Aktorgrenzen ---
@export var max_torque: Vector3 = Vector3(800.0, 800.0, 800.0)	# Nm per axis
@export var max_force: Vector3 = Vector3(20000.0, 20000.0, 30000.0)	# N per axis

# --- Komfort ---
@export var input_deadzone: float = 0.05	# kleine Inputs ignorieren
@export var inertial_dampener: bool = true	# bei Input=0 auf v=0 & w=0 bremsen

func _ready() -> void:
	# Dämpfungsmodus: Winkel REPLACE (wir regeln selbst), Linear COMBINE (weltweite Dämpfung additiv)
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	# Grunddämpfung leicht, Feinregelung übernimmt kd_*:
	angular_damp = 0.0
	linear_damp = 0.0
	gravity_scale = 0.0	

var u_move: Vector3
var u_turn: Vector3
var world_basis: Basis
var omega_local: Vector3
var target_rate_local: Vector3
var err_rate: Vector3
var torque_local: Vector3
var torque_world: Vector3

func _physics_process(delta: float) -> void:
	# --- 0) Inputs mit Deadzone ---
	u_move = _deadzone(_get_move_input(), input_deadzone)
	u_turn = _deadzone(_get_rotation_input(), input_deadzone)

	# --- 1) Rotation: inertia-aware PD + gyro feed-forward ---
	var B: Basis = global_transform.basis.orthonormalized()
	var B_T: Basis = B.transposed()

	var w: Vector3 = B_T * angular_velocity
	var w_target: Vector3 = Vector3(
		deg_to_rad(max_rate_deg.x) * u_turn.x,	# pitch
		deg_to_rad(max_rate_deg.y) * u_turn.y,	# yaw
		deg_to_rad(max_rate_deg.z) * u_turn.z	# roll
	)
	if inertial_dampener and u_turn == Vector3.ZERO:
		w_target = Vector3.ZERO

	var e: Vector3 = w_target - w

	# Trägheit (Diagonal) aus dem Body; guard gegen 0
	var I: Vector3 = inertia
	I.x = max(I.x, 1e-3)
	I.y = max(I.y, 1e-3)
	I.z = max(I.z, 1e-3)

	# gewünschte Winkelbeschleunigung (rad/s^2)
	var alpha_des: Vector3 = Vector3(
		kp_ang.x * e.x - kd_ang.x * w.x,
		kp_ang.y * e.y - kd_ang.y * w.y,
		kp_ang.z * e.z - kd_ang.z * w.z
	)

	# Gyro-Feed-Forward: tau = I·alpha_des + w × (I·w)   (alles im lokalen Raum)
	var Iw: Vector3 = Vector3(I.x * w.x, I.y * w.y, I.z * w.z)
	var tau_local: Vector3 = Vector3(I.x * alpha_des.x, I.y * alpha_des.y, I.z * alpha_des.z) + w.cross(Iw)

	tau_local = _clamp_axis(tau_local, max_torque)
	apply_torque(B * tau_local)

	# --- 2) Translation: Speed-Hold im lokalen Raum + Transport-FF ---
	var v_local: Vector3 = B_T * linear_velocity
	var target_v_local := Vector3(
		max_speed.x * u_move.x,
		max_speed.y * u_move.y,
		- max_speed.z * u_move.z	# +1 => vorwärts (−Z)
	)
	if inertial_dampener and u_move == Vector3.ZERO:
		target_v_local = Vector3.ZERO

	var err_v := target_v_local - v_local

	# PD auf Geschwindigkeit (in lokalem Raum)
	var dv_des_local := Vector3(
		kp_lin.x * err_v.x - kd_lin.x * v_local.x,
		kp_lin.y * err_v.y - kd_lin.y * v_local.y,
		kp_lin.z * err_v.z - kd_lin.z * v_local.z
	)

	# *** Transport-/Coriolis-Kompensation ***
	# In einem rotierenden Frame gilt: d(v_local)/dt = B^T * a_world - w_local × v_local
	# ⇒ um gewünschtes dv_local zu erreichen: a_world = B * (dv_des_local + w_local × v_local)
	var omega_local_now: Vector3 = B_T * angular_velocity
	dv_des_local += omega_local_now.cross(v_local)

	# Kraft = m * a_world, danach wieder in lokale Achsen begrenzen
	var a_world := B * dv_des_local
	var force_world := a_world * mass

	var force_local := B_T * force_world
	force_local = _clamp_axis(force_local, max_force)

	apply_force(B * force_local)

# --- Helpers ---
func _deadzone(v: Vector3, dz: float) -> Vector3:
	return Vector3(
		v.x if abs(v.x) >= dz else 0.0,
		v.y if abs(v.y) >= dz else 0.0,
		v.z if abs(v.z) >= dz else 0.0
	)

func _clamp_axis(v: Vector3, lim: Vector3) -> Vector3:
	return Vector3(
		clamp(v.x, -lim.x, lim.x),
		clamp(v.y, -lim.y, lim.y),
		clamp(v.z, -lim.z, lim.z)
	)

# Returns (x=sway, y=heave, z=thrust) in [-1..1]
func _get_move_input() -> Vector3:
	var heave := Input.get_action_strength("heave_up") - Input.get_action_strength("heave_down")
	var thrust := Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down") # +1 = vorwärts
	return Vector3(0.0, heave, thrust)

func _get_rotation_input() -> Vector3:
	# (x=pitch, y=yaw, z=roll)   in [-1..1]
	var pitch = Input.get_action_strength("pitch_down") - Input.get_action_strength("pitch_up")
	var roll = Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	return Vector3(pitch, 0.0, roll)

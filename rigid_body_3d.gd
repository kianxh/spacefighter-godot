extends RigidBody3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var label: Label = $"../Label"

# --- Rollregelung mit PD-Regler -----------------------
# PD-Regler = Proportional + Derivativ:
#   - P-Anteil (Kp): zieht Richtung Ziel (Fehler * Kp) → macht das System schnell.
#   - D-Anteil (Kd): bremst abhängig von aktueller Geschwindigkeit → stabilisiert, verhindert Überschwingen.
# Für Rollen regeln wir die *Winkelgeschwindigkeit* (ω) um die lokale Z-Achse.

# Ziel-Maximalgeschwindigkeit beim Rollen (rad/s).
# Beispiel: 6 rad/s ≈ 343°/s – recht flott.

# Verstärkungen des PD-Reglers:
# - kp_roll (Proportional): je größer, desto aggressiver zieht es zum Ziel-ω.
# - kd_roll (Derivativ): je größer, desto stärker die „eingebaute Bremse“.

@export var max_roll_speed: float = 6.0		# rad/s – Ziel-Max-Rollgeschwindigkeit
@export var kp_roll: float = 40.0			# P-Verstärkung (zieht zum Soll-ω)
@export var kd_roll: float = 6.0			# D-Verstärkung (eingebaute Bremse)
@export var max_roll_torque: float = 400.0	# Nm – Sicherheitslimit fürs Moment
@export var deadzone: float = 0.05			# Totzone für Eingabe [-1..1], gegen Zittern

func _physics_process(_dt: float) -> void:
	_apply_roll_controll(_dt)
	

func _apply_roll_controll(delta: float) -> void:
		# 1) Eingabe lesen: Roll-Input in [-1, 1]
	var input := roll_input()

	# 2) Ist-Winkelgeschwindigkeit (Welt) → Lokal
	var omega_world := angular_velocity
	var omega_local := global_transform.basis.inverse() * omega_world

	# 3) Soll-Winkelgeschwindigkeit aus Input ableiten
	var omega_target := input * max_roll_speed

	# 4) Regelfehler auf der Roll-Achse (lokal Z)
	var error := omega_target - omega_local.z

	# 5) PD-Regler-Moment (lokal): M = Kp * error - Kd * ω_ist
	var torque_local := Vector3(0.0, 0.0, kp_roll * error - kd_roll * omega_local.z)

	# 6) Sicherheitsbegrenzung
	if torque_local.length() > max_roll_torque:
		torque_local = torque_local.normalized() * max_roll_torque

	# 7) Moment in Weltkoordinaten anwenden
	var torque_world := global_transform.basis * torque_local
	apply_torque(torque_world)

# Beispiel-Input (ersetzen durch deine Aim-/Inputlogik nach Bedarf)
func roll_input() -> float:
	var right := Input.get_action_strength("roll_right")
	var left := Input.get_action_strength("roll_left")
	var raw := right - left
	if abs(raw) < deadzone:
		return 0.0
	return clamp(raw, -1.0, 1.0)

func thrust_input() -> Vector3:
	var forward := Input.get_action_strength("throttle_up")
	var backward := Input.get_action_strength("throttle_down")
	var strafe_upwards := Input.get_action_strength("heave_up")
	var strafe_downwards := Input.get_action_strength("heave_down")
	var strafe_left := Input.get_action_strength("sway_left")
	var strafe_right := Input.get_action_strength("sway_right")
	
	var thrust := forward - backward
	var sway := strafe_right - strafe_left
	var heave := strafe_upwards - strafe_downwards
	
	return Vector3(sway, heave, thrust)


@onready var main_thruster_a: Thruster = $Body/MainThrusterA
@onready var main_thruster_b: Thruster = $Body/MainThrusterB
@onready var aux_thruster_bottom_1: Thruster = $Body/AuxThrusterBottom1
@onready var aux_thruster_bottom_3: Thruster = $Body/AuxThrusterBottom3
@onready var aux_thruster_bottom_2: Thruster = $Body/AuxThrusterBottom2
@onready var aux_thruster_bottom_4: Thruster = $Body/AuxThrusterBottom4
@onready var aux_thruster_up_1: Thruster = $Body/AuxThrusterUp1
@onready var aux_thruster_up_2: Thruster = $Body/AuxThrusterUp2
@onready var aux_thruster_up_3: Thruster = $Body/AuxThrusterUp3
@onready var aux_thruster_up_4: Thruster = $Body/AuxThrusterUp4
@onready var aux_thruster_left_1: Thruster = $Body/AuxThrusterLeft1
@onready var aux_thruster_left_2: Thruster = $Body/AuxThrusterLeft2
@onready var aux_thruster_right_1: Thruster = $Body/AuxThrusterRight1
@onready var aux_thruster_right_2: Thruster = $Body/AuxThrusterRight2
@onready var aux_thruster_forward_1: Thruster = $Body/AuxThrusterForward1
@onready var aux_thruster_forward_2: Thruster = $Body/AuxThrusterForward2


func _update_thrust_animation() -> void:
	var input := thrust_input()
	var sway := input.x
	var heave := input.y
	var thrust := input.z

	
	if thrust == 0:
		_set_thruster_states([
			main_thruster_a,
			main_thruster_b,
			aux_thruster_forward_1,
			aux_thruster_forward_2,
		], false)
	elif thrust > 0:
		_set_thruster_states([
			aux_thruster_forward_1,
			aux_thruster_forward_2,
		], false)
		_set_thruster_states([
			main_thruster_a,
			main_thruster_b,
		], true)
	elif thrust < 0:
		_set_thruster_states([
			aux_thruster_forward_1,
			aux_thruster_forward_2,
		], true)
		_set_thruster_states([
			main_thruster_a,
			main_thruster_b,
		], false)
	
	if sway == 0:
		_set_thruster_states([
			aux_thruster_left_1,
			aux_thruster_left_2,
			aux_thruster_right_1,
			aux_thruster_right_2,
		], false)
	elif sway > 0:
		_set_thruster_states([
			aux_thruster_right_1,
			aux_thruster_right_2,
		], false)
		_set_thruster_states([
			aux_thruster_left_1,
			aux_thruster_left_2,
		], true)
	elif sway < 0:
		_set_thruster_states([
			aux_thruster_right_1,
			aux_thruster_right_2,
		], true)
		_set_thruster_states([
			aux_thruster_left_1,
			aux_thruster_left_2,
		], false)
	
	if heave == 0:
		_set_thruster_states([
			aux_thruster_bottom_1,
			aux_thruster_bottom_2,
			aux_thruster_bottom_3,
			aux_thruster_bottom_4,
			aux_thruster_up_1,
			aux_thruster_up_2,
			aux_thruster_up_3,
			aux_thruster_up_4,
		], false)
	elif heave > 0:
		_set_thruster_states([
			aux_thruster_up_1,
			aux_thruster_up_2,
			aux_thruster_up_3,
			aux_thruster_up_4,
		], false)
		_set_thruster_states([
			aux_thruster_bottom_1,
			aux_thruster_bottom_2,
			aux_thruster_bottom_3,
			aux_thruster_bottom_4,
		], true)
	elif heave < 0:
		_set_thruster_states([
			aux_thruster_up_1,
			aux_thruster_up_2,
			aux_thruster_up_3,
			aux_thruster_up_4,
		], true)
		_set_thruster_states([
			aux_thruster_bottom_1,
			aux_thruster_bottom_2,
			aux_thruster_bottom_3,
			aux_thruster_bottom_4,
		], false)
	

func _update_roll_animation() -> void:
	var input := roll_input()
	
	#if input == 0.0:
		#_set_thruster_states([
			#aux_thruster_bottom_2,
			#aux_thruster_bottom_3, 
			#aux_thruster_up_2,
			#aux_thruster_up_3,
			#aux_thruster_up_1,
			#aux_thruster_up_4,
			#aux_thruster_bottom_1,
			#aux_thruster_bottom_4, 
		#], false)
	if input > 0.0:
		_set_thruster_states([
			aux_thruster_bottom_2,
			aux_thruster_bottom_3, 
			aux_thruster_up_2,
			aux_thruster_up_3,
		], false)
		_set_thruster_states([
			aux_thruster_up_1,
			aux_thruster_up_4,
			aux_thruster_bottom_1,
			aux_thruster_bottom_4, 
		], true)
	elif input < 0.0:
		# roll left
		_set_thruster_states([
			aux_thruster_up_1,
			aux_thruster_up_4,
			aux_thruster_bottom_1,
			aux_thruster_bottom_4, 
		], false)
		_set_thruster_states([
			aux_thruster_bottom_2,
			aux_thruster_bottom_3, 
			aux_thruster_up_2,
			aux_thruster_up_3,
		], true)
	
func _set_thruster_states(thrusters: Array[Thruster], value: bool) -> void:
	for thruster in thrusters:
		if thruster:
			thruster.is_thrusting = value


# Debug Anzeige

func _process(delta: float) -> void:
	_update_thrust_animation()
	_update_roll_animation()
	_update_label()

func _update_label() -> void:	
	label.text = """Inputs:
		inertia: %s
		angular velocity: %s
		angular damp: %s
		
		roll input: %s
		thrust input: %s
	
	""" % [
		str(inertia),
		str(angular_velocity),
		str(angular_damp),
		str(roll_input()),
		str(thrust_input()),
	]

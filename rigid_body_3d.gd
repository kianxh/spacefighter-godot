extends RigidBody3D
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


# Debug Anzeige

func _process(delta: float) -> void:
	_update_label()

func _update_label() -> void:
	label.text = """Inputs:
		inertia: %s
		angular velocity: %s
		angular damp: %s
	
	""" % [
		str(inertia),
		str(angular_velocity),
		str(angular_damp),

	]

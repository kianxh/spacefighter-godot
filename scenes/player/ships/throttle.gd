extends Node
class_name ThrottleInput

## Emits when the throttle postion or strength changes.
signal strength_changed(new_strength_value: float)

@export var _change_rate: float = 2

## Current position of the throttle between -1.0 and 1.0.
var _strength: float = 0.0:
	set(value):
		_strength = clamp(value, -1.0, 1.0)
		strength_changed.emit(_strength)


func _physics_process(delta: float) -> void:
	var _change_cmd = Input.get_action_strength("ship_throttle_increase") - Input.get_action_strength("ship_throttle_decrease")
	
	# Only updae _strength when it makes sense as it is bound
	# to values from -1.0 to 1.0
	if _change_cmd != 0.0 and not (_change_cmd > 0 and _strength == 1.0) and not (_change_cmd < 0 and _strength == -1.0):
		_strength = _strength + _change_cmd * _change_rate * delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("ship_throttle_increase") or event.is_action("ship_throttle_decrease"):
		return
	
	# Handle throttle reset
	if event.is_action_released("ship_throttle_set_0"):
		_strength = 0.0
		return
	
	# Handle negative set events
	if event.is_action_released("ship_throttle_set_25_neg"):
		_strength = -0.25
	if event.is_action_released("ship_throttle_set_33_neg"):
		_strength = -0.33
	if event.is_action_released("ship_throttle_set_50_neg"):
		_strength = -0.50
	if event.is_action_released("ship_throttle_set_67_neg"):
		_strength = -0.67
	if event.is_action_released("ship_throttle_set_75_neg"):
		_strength = -0.75
	if event.is_action_released("ship_throttle_set_100_neg"):
		_strength = -1.0

	# Handle positive set events
	if event.is_action_released("ship_throttle_set_25_pos"):
		_strength = 0.25
	if event.is_action_released("ship_throttle_set_33_pos"):
		_strength = 0.33
	if event.is_action_released("ship_throttle_set_50_pos"):
		_strength = 0.50
	if event.is_action_released("ship_throttle_set_67_pos"):
		_strength = 0.67
	if event.is_action_released("ship_throttle_set_75_pos"):
		_strength = 0.75
	if event.is_action_released("ship_throttle_set_100_pos"):
		_strength = 1.0


# --- API ---
## Returns the current set throttle strength from -1.0 to 1.0.
func get_strength() -> float:
	return _strength

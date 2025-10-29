extends Label

@onready var aim: AimInput = $"../../../../../../../../../../Inputs/Aim"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var vec := aim.get_aim_direction() * aim.get_aim_strength()
	text = "(%s,%s)" % [
		_format_float(vec.x), 
		_format_float(vec.y), 
	]

## Formats floats to match a given string length
func _format_float(val: float) -> String:
	var _val = str(round(val * 100) / 100)
	var _delta: int = 5 - _val.length()
	
	if _delta > 0:
		for n in range(_delta):
			_val = " " + _val
	elif _delta < 0:
		_val = "#OV"
	
	return _val
	
	 

extends Node

@export var cameras: Array[Camera3D] = []
var current_index := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

func cycle_cameras() -> void:
	if cameras.size() == 0:
		printerr("No cameras assigned to camera operator")
		return
	
	var next_index := current_index + 1
	if next_index >= cameras.size():
		next_index = 0
	
	cameras[next_index].current = true
	current_index = next_index
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("camera_toggle"):
		cycle_cameras()

@tool
extends MeshInstance3D
class_name Thruster

@onready var beam: MeshInstance3D = $Beam

@export var is_thrusting: bool = false:
	set(value):
		if beam:
			beam.visible = value
		is_thrusting = value

func _ready() -> void:
	is_thrusting = is_thrusting

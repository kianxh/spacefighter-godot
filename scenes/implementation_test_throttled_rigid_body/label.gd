extends Label

@onready var rigid_body: RigidBody3D = $"../../RigidBody3D"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = """
		linvel: %s
	""" % [
		str(rigid_body.linear_velocity)
	]

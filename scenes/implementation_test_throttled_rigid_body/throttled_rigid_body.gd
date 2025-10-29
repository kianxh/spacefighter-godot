extends RigidBody3D

@export_range(-1, 1, 1.0) var throttle: float = 0.0

@export var applied_force: Vector3 = Vector3.FORWARD * 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	apply_force(throttle * applied_force * delta)

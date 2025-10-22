extends RigidBody3D

@onready var camera_3d: Camera3D = $"../Camera3D"
@onready var label: Label = $"../CanvasLayer/Label"


var target_value: float = 0
@export var power: float = 12
@export var is_pid_active: bool = true

@export var pid_p_gain := 1.0
@export var pid_i_gain := 0.0
@export var pid_d_gain: float

var controller: PidController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_value = position.y
	controller = PidController.new(pid_p_gain, pid_i_gain, pid_d_gain, PidController.DerivativeMeasurement.Velocity)
	

var input: float = -1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_pid_active:
		input = controller.update(delta, position.y, target_value)
		apply_force(Vector3(0, input * power, 0), Vector3.ZERO)

# Update the debug label texts
func _process(delta: float) -> void:
	if(label):
		label.text = ""
		for prop_name in ["input", "target_value", "position", "pid_p_gain", "pid_d_gain"]:
			label.text += prop_name + ": %s\n" % str(get(prop_name))

# Capture click on nodes to determine the target
const RAY_LENGTH = 1000.0
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var space_state = get_world_3d().direct_space_state
		var from = camera_3d.project_ray_origin(event.position)
		var to = from + camera_3d.project_ray_normal(event.position) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)

		if result and result.collider is CSGBox3D and result.collider.get_meta("is_clickable"):
			var collider := result.collider as CSGBox3D
			print(collider.position)
			target_value = collider.position.y
			

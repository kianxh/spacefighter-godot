extends Node3D

@onready var rigid_body: RigidBody3D = $"../RigidBody3D"
@onready var template_line: MeshInstance3D = $TemplateLine
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

@export var count: int = 10
@export var spacing: float = 1
@export var direction: Vector3 = Vector3.FORWARD


var _lines: Array[MeshInstance3D] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for n in range(count):
		var dupe := template_line.duplicate()
		dupe.global_position = self.global_position + direction * (n+1) * spacing
		dupe.visible = true
		_lines.append(dupe)
		add_child(dupe)
		print("add line: ", str(dupe.global_position))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var _tracked_position := rigid_body.global_position
	var _first_line = _lines[0]
	var _last_line = _lines[-1]
	
	var _dist_to_first_line = _tracked_position.distance_to(_first_line.global_position)
	var _dist_to_last_line = _tracked_position.distance_to(_last_line.global_position)
	
	
	var _dist_delta = abs(_dist_to_first_line - _dist_to_last_line)
	
	if _dist_delta < spacing:
		return
		
	if _dist_to_first_line > _dist_to_last_line:
		print("repos first line")
		_remove_line_at(0)
		_append_line(_first_line)
	elif _dist_to_first_line < _dist_to_last_line:
		print("repos last line")
		_remove_line_at(_lines.size()-1)
		_prepend_line(_last_line)
	
	
		

func _remove_line_at(index: float) -> void:
	_lines.remove_at(index)

func _append_line(mesh: Node3D) -> void:
	mesh.global_position = _lines[-1].global_position + direction * spacing
	_lines.push_back(mesh)
	
func _prepend_line(mesh: Node3D) -> void:
	var dt = direction * -1 * spacing
	var pos = _lines[0].global_position + dt
	mesh.global_position = pos
	_lines.push_front(mesh)

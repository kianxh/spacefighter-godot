extends Camera3D

@export var target: Node3D
@export var max_target_distance: float = 200
@export var min_target_distance: float = 0
@export var camera_spawn_distance: float = 30
@export var camera_spawn_radius: float = 40


func _process(delta: float) -> void:
	if not current or not is_instance_valid(target):
		return
	
	
	var distance_to_target = global_position.distance_to(target.global_position)
	print(distance_to_target)
	if distance_to_target > max_target_distance or distance_to_target < min_target_distance:
		# Reposition camera
		global_position = target.global_position + random_on_sphere(camera_spawn_radius) + ((target.position * Vector3.FORWARD).normalized() * camera_spawn_distance)
		
	look_at(target.global_position)


func random_on_sphere(radius : float) -> Vector3:
   # Generate random spherical coordinates
	var theta = 2 * PI * randf()
	var phi = PI * randf()
   
   # Convert to cartesian
	var x = sin(phi) * cos(theta) * radius
	var y = sin(phi) * sin(theta) * radius	
	var z = cos(phi) * radius
   
	return Vector3(x,y,z)

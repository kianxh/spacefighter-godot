extends Camera3D

@export var target: RigidBody3D
@export var max_target_distance: float = 100
@export var camera_spawn_distance: float = 40
@export var camera_spawn_radius: float = 40


func _process(delta: float) -> void:
	if not current or not is_instance_valid(target):
		return
	
	look_at(target.position)
	
	if position.distance_to(target.position) > max_target_distance:
		position = target.position + random_on_sphere(camera_spawn_radius) + (target.linear_velocity.normalized() * camera_spawn_distance)
		
	

func random_on_sphere(radius : float) -> Vector3:
   # Generate random spherical coordinates
	var theta = 2 * PI * randf()
	var phi = PI * randf()
   
   # Convert to cartesian
	var x = sin(phi) * cos(theta) * radius
	var y = sin(phi) * sin(theta) * radius	
	var z = cos(phi) * radius
   
	return Vector3(x,y,z)

extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("free_fly_camera_move_left", "free_fly_camera_move_right", "free_fly_camera_move_forward", "free_fly_camera_move_back")
	var direction := (transform.basis * Vector3(
		input_dir.x, 
		Input.get_action_strength("free_fly_camera_move_up") - Input.get_action_strength("free_fly_camera_move_down"), 
		input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

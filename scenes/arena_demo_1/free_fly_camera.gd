extends CharacterBody3D

@export var move_speed := 8.0
@export var fast_mult := 4.0
@export var slow_mult := 0.25
@export var mouse_sens := 0.002

var look_enabled := false
var yaw := 0.0
var pitch := 0.0

@onready var cam: Camera3D = $Camera3D

func _ready():
	yaw = rotation.y
	pitch = cam.rotation.x

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		look_enabled = event.pressed
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if look_enabled else Input.MOUSE_MODE_VISIBLE)
	elif look_enabled and event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sens
		pitch -= event.relative.y * mouse_sens
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		rotation.y = yaw
		cam.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		look_enabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("free_fly_camera_move_forward"): input_dir -= transform.basis.z
	if Input.is_action_pressed("free_fly_camera_move_back"): input_dir += transform.basis.z
	if Input.is_action_pressed("free_fly_camera_move_left"): input_dir -= transform.basis.x
	if Input.is_action_pressed("free_fly_camera_move_right"): input_dir += transform.basis.x

	input_dir.y = 0.0
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT): speed *= fast_mult
	if Input.is_key_pressed(KEY_CTRL): speed *= slow_mult

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed

	
	var vy := 0.0
	if Input.is_action_pressed("free_fly_camera_move_up"): vy += 1.0
	if Input.is_action_pressed("free_fly_camera_move_down"): vy -= 1.0
	velocity.y = vy * speed
	

	move_and_slide()

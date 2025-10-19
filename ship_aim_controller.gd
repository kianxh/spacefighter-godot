# AimController.gd
extends Node
class_name AimController

# --- Config shared by HUD + Ship ---
@export var cursor_boundary_radius: float = 240.0
@export var min_roll_radius: float = 80.0
@export var max_roll_radius: float = 180.0
@export var cursor_radius: float = 10.0

@export var toggle_action: StringName = &"toggle_mouse_capture"

# --- State (read-only for others; use getters) ---
var _center: Vector2
var _aim_vec: Vector2 = Vector2.ZERO
var _cursor_pos: Vector2

signal aim_changed(aim_vec: Vector2, cursor_pos: Vector2)
signal mouse_captured_changed(captured: bool)

func _ready() -> void:
	_update_center()
	_cursor_pos = _center
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resized"))
	set_process_input(true)

func _on_viewport_resized() -> void:
	_update_center()
	_clamp_and_update_cursor(_center + _aim_vec)
	emit_signal("aim_changed", _aim_vec, _cursor_pos)

func _update_center() -> void:
	_center = get_viewport().size * 0.5

func _input(event: InputEvent) -> void:
	# Capture toggle
	if event.is_action_pressed(toggle_action):
		var m = Input.get_mouse_mode()
		var to_captured = (m != Input.MOUSE_MODE_CAPTURED)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if to_captured else Input.MOUSE_MODE_VISIBLE)
		emit_signal("mouse_captured_changed", to_captured)
		return

	# While captured, read RELATIVE motion and clamp
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_aim_vec += event.relative
		if _aim_vec.length() > cursor_boundary_radius:
			_aim_vec = _aim_vec.normalized() * cursor_boundary_radius
		_cursor_pos = _center + _aim_vec
		emit_signal("aim_changed", _aim_vec, _cursor_pos)

# --- API for consumers (HUD/Ship) ---
func get_center() -> Vector2: return _center
func get_aim_vector() -> Vector2: return _aim_vec
func get_cursor_pos() -> Vector2: return _cursor_pos

func get_aim_direction() -> Vector2:
	return _aim_vec.normalized() if _aim_vec.length() > 0.0 else Vector2.ZERO

func is_outside_deadzone() -> bool:
	return _aim_vec.length() >= min_roll_radius


func get_aim_strength() -> float:
	# Distance of the cursor from center
	var d := _aim_vec.length()

	# Use an effective max that respects your clamp
	# (in case cursor_boundary_radius < max_roll_radius)
	var effective_max = max(min_roll_radius, min(max_roll_radius, cursor_boundary_radius))

	# Normalize: 0 at min_roll_radius, 1 at effective_max
	var range = max(effective_max - min_roll_radius, 0.0001)
	var s = (min(d, effective_max) - min_roll_radius) / range
	return clamp(s, 0.0, 1.0)

# Utility if you ever want to set from absolute mouse when not captured
func set_target_from_screen(screen_pos: Vector2) -> void:
	_clamp_and_update_cursor(screen_pos)
	emit_signal("aim_changed", _aim_vec, _cursor_pos)

func _clamp_and_update_cursor(world_target: Vector2) -> void:
	var v := world_target - _center
	if v.length() > cursor_boundary_radius:
		v = v.normalized() * cursor_boundary_radius
	_aim_vec = v
	_cursor_pos = _center + _aim_vec

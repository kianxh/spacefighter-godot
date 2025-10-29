# Hud2D.gd
extends Control
class_name ShipHudAim

@onready var hud: ShipHudCanvasLayer = $".."
@onready var aim_input: AimInput = $"../../Inputs/Aim"

# --- Aim Config ---
@export var outline_width: float = 1
@export var outline_color_primary: Color
@export var outline_color_secondary: Color = Color(1, 1, 1, 0.4)
@export var cursor_radius: float = 10.0


func _ready() -> void:	
	if not outline_color_primary:
		outline_color_primary = hud.global_outline_color
	# Don't consume GUI mouse
	aim_input.connect("aim_changed", Callable(self, "_on_aim_changed"))
	aim_input.connect("mouse_captured_changed", Callable(self, "_on_capture_changed"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _on_aim_changed(_v: Vector2, _p: Vector2) -> void:
	queue_redraw()

func _on_capture_changed(_captured: bool) -> void:
	queue_redraw()

func _draw() -> void:
	
	var center := aim_input.get_center()
	# Read radii from the controller so visuals match logic
	var r_min := aim_input.min_roll_radius
	var r_max := aim_input.max_roll_radius
	var r_cap := aim_input.cursor_boundary_radius
	var cursor_pos := aim_input.get_cursor_pos() 

	# Rings
	_draw_circle_outline(center, r_min, outline_color_secondary, outline_width)
	#_draw_circle_outline(center, r_max, outline_color_secondary, outline_width)
	# Optional: visualize the clamp boundary (you had this in your last version)
	#_draw_circle_outline(center, r_cap, outline_color_secondary, outline_width)

	# Line center → cursor
	draw_line(center, cursor_pos, outline_color_secondary, outline_width, true)
	# Cursor outline
	_draw_circle_outline(cursor_pos, cursor_radius, outline_color_primary, outline_width)

func _draw_circle_outline(c: Vector2, r: float, color: Color, width: float, segments: int = 96) -> void:
	draw_arc(c, r, 0.0, TAU, segments, color, width, true)

# Hud2D.gd
extends Control
class_name ShipHudAim

@onready var hud: ShipHudCanvasLayer = $".."

var aim_controller: AimController

func connect_aim_controller(c: AimController) -> void:
	aim_controller = c
	aim_controller.connect("aim_changed", Callable(self, "_on_aim_changed"))
	aim_controller.connect("mouse_captured_changed", Callable(self, "_on_capture_changed"))
	queue_redraw()

func _ready() -> void:	
	# Don't consume GUI mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _on_aim_changed(_v: Vector2, _p: Vector2) -> void:
	queue_redraw()

func _on_capture_changed(_captured: bool) -> void:
	queue_redraw()

func _draw() -> void:
	if not aim_controller:
		printerr("No 'aim_controller' specified. ShipHudAim will not draw")
		return
	
	var center := aim_controller.get_center()
	# Read radii from the controller so visuals match logic
	var r_min := aim_controller.min_roll_radius
	var r_max := aim_controller.max_roll_radius
	var r_cap := aim_controller.cursor_boundary_radius
	var cursor_pos := aim_controller.get_cursor_pos() 

	# Rings
	_draw_circle_outline(center, r_min, hud.aim_outline_color_secondary, hud.aim_outline_width)
	_draw_circle_outline(center, r_max, hud.aim_outline_color_secondary, hud.aim_outline_width)
	# Optional: visualize the clamp boundary (you had this in your last version)
	_draw_circle_outline(center, r_cap, hud.aim_outline_color_secondary, hud.aim_outline_width)

	# Line center → cursor
	draw_line(center, cursor_pos, hud.aim_outline_color_secondary, hud.aim_outline_width, true)
	# Cursor outline
	_draw_circle_outline(cursor_pos, hud.aim_cursor_radius, hud.aim_outline_color_primary, hud.aim_outline_width)

func _draw_circle_outline(c: Vector2, r: float, color: Color, width: float, segments: int = 96) -> void:
	draw_arc(c, r, 0.0, TAU, segments, color, width, true)

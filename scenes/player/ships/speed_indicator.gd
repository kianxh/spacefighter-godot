# SpeedTape.gd (Godot 4.x)
extends Control

@export var spacing_px: float = 60.0   # distance between lines
@export var thickness_px: float = 0.5
@export var color := Color(0.85, 0.95, 1.0, 0.9)

var _offset_px: float = 0.0 
@onready var ship_body: ArcadeSixDofController = $"../../.."

		   # vertical phase in pixels
func _ready() -> void:
	print("siz: ",str(size))
	print("pos: ",str(global_position))

func _process(delta: float) -> void:
	# --- choose how fast to scroll ---
	# Example 1: constant scroll (visual test)
	#var pixels_per_sec := 140.0
	

	# Example 2 (bind to ship forward speed):
	var v_global: Vector3 = ship_body.velocity
	var v_local:  Vector3 = ship_body.global_transform.basis.inverse() * v_global
	var mps =  -v_local.z  # (+) = toward camera / down
	var pixels_per_meter := 6.0
	var pixels_per_sec:float = mps * pixels_per_meter

	_offset_px = fposmod(_offset_px + pixels_per_sec * delta, spacing_px)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0: return

	# Start above the top so we cover the whole rect after adding offset
	var y := -_offset_px
	while y <= h + spacing_px:
		# Geradengleichung aus den Punkten A(0, 0) und B(w*0.5, h)
		var A := Vector2(0, 0)
		var B := Vector2(size.x * 0.2, size.y)
		var m: float = (B.y - A.y) / (B.x - A.x) # Geradensteigung
		var b: float = A.y - m * A.x # y-Achsenabschnitt
		var x: float = clamp(( clamp(y, 0, size.y) - b ) / m, 0, B.x)
		
		if (y < size.y) and y > 0:
			draw_line(Vector2(x, y), Vector2(size.x-x, y), color, thickness_px, true)
		y += spacing_px

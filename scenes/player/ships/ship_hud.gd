extends CanvasLayer
class_name ShipHudCanvasLayer

@onready var debug_label: Label = $DebugLabel



# --- Global HUD Configs ---
@export var global_outline_width: float = 0.5
@export var global_outline_color: Color = Color(1, 1, 1, 0.8)
@export var global_debug: bool = false



@onready var aim_input: AimInput = $"../Controls/AimInput"


func _ready() -> void:
	if global_debug:
		debug_label.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if debug_label.visible:
		debug_label.text = """center: %s
			cursor pos: %s
			
			aim vector: %s
			aim strength: %s
			aim direction: %s
			is outside deadzone %s 
		""" % [
			str(aim_input.get_center()),
			str(aim_input.get_cursor_pos()),
			str(aim_input.get_aim_vector()),
			str(aim_input.get_aim_strength()),
			str(aim_input.get_aim_direction()),
			str(aim_input.is_outside_deadzone()),
		]

extends CanvasLayer
class_name ShipHudCanvasLayer

@onready var ship_hud_aim: ShipHudAim = $ShipHudAim
@onready var debug_label: Label = $DebugLabel



# --- Global HUD Configs ---
@export var global_outline_width: float = 0.5
@export var global_outline_color: Color = Color(1, 1, 1, 0.8)
@export var global_debug: bool = false

# --- Aim Config ---
@export var aim_outline_width: float = 0.0

@export var aim_outline_color_primary: Color = global_outline_color

@export var aim_outline_color_secondary: Color = Color(1, 1, 1, 0.4)
@export var aim_cursor_radius: float = 10.0
@export var aim_controller_path: NodePath

@onready var aim_controller: AimController = get_node(aim_controller_path) as AimController


func _ready() -> void:
	ship_hud_aim.connect_aim_controller(aim_controller)
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
			str(aim_controller.get_center()),
			str(aim_controller.get_cursor_pos()),
			str(aim_controller.get_aim_vector()),
			str(aim_controller.get_aim_strength()),
			str(aim_controller.get_aim_direction()),
			str(aim_controller.is_outside_deadzone()),
		]

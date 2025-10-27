extends Label

@onready var ship: ArcadeSixDofController = $"../../ShipBody"

@export var show_ship: bool = true
@export var show_ship_controller: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = ""
	if show_ship and is_instance_valid(ship):
		text += """--- Ship---ww
			move_inputs: %s
			rotation_inputs: %s
			
			position: %s
			rotation: %s
			
			
		""" % [
			str(ship.get_movement_input()),
			str(ship.get_rotation_input()),

			str(ship.position),
			str(ship.rotation),
			
		]
	
	

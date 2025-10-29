extends Label

@onready var ship_body: ArcadeSixDofController = $"../../../../../../../../../.."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = str(ship_body.global_position)

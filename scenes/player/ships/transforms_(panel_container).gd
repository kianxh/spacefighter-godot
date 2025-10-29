extends PanelContainer

@onready var ship_body: ArcadeSixDofController = $"../../../../../.."

@onready var value_position: Label = $MarginContainer/VBoxContainer/GridContainer/ValuePosition
@onready var value_rotation: Label = $MarginContainer/VBoxContainer/GridContainer/ValueRotation
@onready var value_linear_velocity: Label = $MarginContainer/VBoxContainer/GridContainer/ValueLinearVelocity
@onready var value_angular_velocity: Label = $MarginContainer/VBoxContainer/GridContainer/ValueAngularVelocity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value_position.text = str(ship_body.global_position)
	value_rotation.text = str(ship_body.global_rotation)
	value_linear_velocity.text = str(ship_body.velocity)

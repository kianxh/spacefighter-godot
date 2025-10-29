extends Label

func _on_throttle_strength_changed(new_strength_value: float) -> void:
	text =  String.num(new_strength_value, 2)

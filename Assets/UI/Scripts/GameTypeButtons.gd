extends VBoxContainer

func _ready() -> void:
	get_child(2).get_node("CheckBox").button_pressed = true

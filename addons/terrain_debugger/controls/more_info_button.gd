@tool
extends Button

@export var node_path : NodePath
var node : Node

func _ready() -> void:
	toggled.connect(_on_toggled)
	node = get_node(node_path)
	button_pressed = false
	_toggle(false)


func _toggle(value : bool) -> void:
	if !is_instance_valid(node):
		return

	if value:
		node.show()
		text = "[less info]"
	else:
		node.hide()
		text = "[more info]"


func _on_toggled(p_button_pressed : bool) -> void:
	_toggle(p_button_pressed)

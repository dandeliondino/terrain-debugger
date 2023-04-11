@tool
extends Button

var icon_expanded : Texture2D
var icon_collapsed : Texture2D

var expand_container : Control


func _ready() -> void:
	icon_expanded = get_theme_icon("GuiTreeArrowDown", "EditorIcons")
	icon_collapsed = get_theme_icon("GuiTreeArrowRight", "EditorIcons")


func setup(p_score : int, p_expand_container : Control, start_expanded := true) -> void:
	text = str(p_score)
	expand_container = p_expand_container
	button_pressed = start_expanded
	_update_expanded_state()


func _update_expanded_state() -> void:
	if button_pressed:
		icon = icon_expanded
	else:
		icon = icon_collapsed
	expand_container.visible = button_pressed


func _on_toggled(_button_pressed: bool) -> void:
	_update_expanded_state()

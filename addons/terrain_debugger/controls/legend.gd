@tool
extends Control

const Globals := preload("res://addons/terrain_debugger/globals.gd")


@onready var item_list: ItemList = %ItemList
@onready var title_label: Label = %TitleLabel

func _ready() -> void:
	hide_title()

func set_title(text : String) -> void:
	title_label.text = text
	show_title()

func show_title() -> void:
	title_label.show()

func hide_title() -> void:
	title_label.hide()


func add_text_item(text : String, tooltip := "") -> void:
	var idx := item_list.add_item(text, null, false)
	if tooltip:
		item_list.set_item_tooltip(idx, tooltip)


func add_color_item(text : String, color : Color, tooltip := "") -> void:
	var icon := _get_color_icon(color)
	var idx := item_list.add_item(text, icon, false)
	if tooltip:
		item_list.set_item_tooltip(idx, tooltip)


func add_icon_item(text : String, icon_name : String, tooltip := "") -> void:
	var icon := get_theme_icon(icon_name, "EditorIcons")
	var idx := item_list.add_item(text, icon, false)
	if tooltip:
		item_list.set_item_tooltip(idx, tooltip)


func _get_color_icon(color : Color) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	img.fill(Globals.ICON_BORDER_COLOR)
	img.fill_rect(Rect2i(0, 0, 32, 32).grow(-2), color)
	return ImageTexture.create_from_image(img)

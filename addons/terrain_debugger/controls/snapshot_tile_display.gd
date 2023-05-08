@tool
extends "res://addons/terrain_debugger/controls/tile_display.gd"

signal pressed

const INDEX_LABEL_ALPHA := 0.5


var border_size := 2

var normal_color : Color
var hover_color : Color

var _empty_tile : bool

var _selected : bool
var _hovered : bool

@onready var border_rect: ColorRect = %BorderRect
@onready var texture_rect: TextureRect = %TextureRect
@onready var index_label: Label = %IndexLabel


func update(tile : Dictionary, index : int, tile_bits : Dictionary, updated : bool, context : Context) -> void:
	reset()
	if not updated:
		_populate_colors(Globals.PREVIOUS_TILE_COLOR)
	else:
		if tile["score"] == 0:
			_populate_colors(Globals.SUCCESS_COLOR)
		else:
			_populate_colors(Globals.ERROR_COLOR)
	_update_color()

	_update_index_label(index)

	texture_rect.texture_filter = context.tile_map.texture_filter
	texture_rect.texture = context.get_tile_texture(tile["source_id"], tile["atlas_coords"])

	for bit in tile_bits:
		var bit_button : BitButton = bit_buttons[bit]
		var bit_properties : Dictionary = tile_bits[bit]
		var terrain : int = bit_properties["terrain"]
		bit_button.setup(
			context.terrain_colors[terrain],
			bit_properties.get("priority", BitButton.NULL_PRIORITY),
			bit_properties.get("origin", BitButton.NULL_ORIGIN),
		)
		bit_button.toggle_transparency(true)
		bit_button.show()

	_empty_tile = false


func update_empty_tile(context : Context) -> void:
	reset()
	texture_rect.texture = context.get_empty_texture()
	_empty_tile = true


func set_selected(value : bool) -> void:
	_selected = value
	_update_color()
	pressed.emit()


func set_hovered(value : bool) -> void:
	_hovered = value
	_update_color()


func _update_color() -> void:
	if _selected:
		_set_color(Globals.SELECTED_COLOR)
	elif _hovered:
		_set_color(hover_color)
	else:
		_set_color(normal_color)


func _set_color(color : Color) -> void:
	border_rect.color = color
	var index_color = Color(color, INDEX_LABEL_ALPHA)
	index_label.set("theme_override_colors/font_color", index_color)


func _populate_colors(color : Color) -> void:
	normal_color = color
	hover_color = color.lightened(0.4)


func _update_index_label(index : int) -> void:
	index_label.text = str(index)
	index_label.set("theme_override_fonts/font", get_theme_font("doc_title", "EditorFonts"))
	index_label.set("theme_override_font_sizes/font_size", get_theme_font_size("doc_title_size", "EditorFonts") * 3)


func _update_tile_size() -> void:
	texture_rect.custom_minimum_size = tile_size
	custom_minimum_size = tile_size + Vector2(border_size * 2, border_size * 2)
	super._update_tile_size()


func reset() -> void:
	texture_rect.texture = null
	border_rect.color = Color.TRANSPARENT
	index_label.text = ""
	_hovered = false
	_selected = false
	_empty_tile = true
	super.reset()



func _on_mouse_entered() -> void:
	if _empty_tile:
		return
	set_hovered(true)


func _on_mouse_exited() -> void:
	if _empty_tile:
		return
	set_hovered(false)


func _on_gui_input(event: InputEvent) -> void:
	if _empty_tile:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			set_selected(true)

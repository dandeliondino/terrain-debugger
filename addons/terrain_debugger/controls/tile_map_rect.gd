@tool
extends ReferenceRect


const Globals := preload("res://addons/terrain_debugger/globals.gd")
const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context


var normal_color : Color
var hover_color : Color
var pressed_color : Color


var _selected := false
var _hovered := false

var coords : Vector2i

var result : Dictionary
var context : Context
var control : Control

@onready var index_label: Label = %IndexLabel
@onready var status_icon: TextureRect = %StatusIcon
@onready var painted_icon: TextureRect = %PaintedIcon


func init(p_result : Dictionary, p_context : Context, p_control : Control) -> void:
	result = p_result
	context = p_context
	control = p_control


func _ready() -> void:
	setup()


func setup() -> void:
	coords = result["coords"]
	
#	var label := Label.new()
#	add_child(label)
#	label.text = "46"
	
	if result["selected_tile"]["score"] == 0:
		_populate_colors(Globals.SUCCESS_COLOR)
		status_icon.texture = control.get_theme_icon("StatusSuccess", "EditorIcons")
	else:
		_populate_colors(Globals.ERROR_COLOR)
		status_icon.texture = control.get_theme_icon("StatusError", "EditorIcons")
	
	if context.is_tile_painted(coords):
		print("tile is painted")
		painted_icon.texture = control.get_theme_icon(Globals.PAINTED_ICON, "EditorIcons")
		painted_icon.modulate = context.get_painted_terrain_color()
		painted_icon.show()
	else:
		painted_icon.hide()
	
	index_label.text = str(result["index"])
	index_label.set("theme_override_colors/font_color", Color.WHITE)
	index_label.set("theme_override_fonts/font", control.get_theme_font("doc_title", "EditorFonts"))
	index_label.set("theme_override_font_sizes/font_size", control.get_theme_font_size("doc_title_size", "EditorFonts"))
	index_label.scale = Vector2(0.25, 0.25)
	
	
	_update_color()
	_update_position.call_deferred()


func set_selected(value : bool) -> void:
	_selected = value
	_update_color()


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
	border_color = color
	index_label.set("theme_override_colors/font_color", color.lightened(0.2))

	
func _update_position() -> void:
	var pos_offset := Vector2(border_width, border_width)
	position = (context.tile_map.map_to_local(coords) - Vector2(context.tile_size/2)) + pos_offset
	size = context.tile_size - (2 * Vector2i(pos_offset))
	_update_children.call_deferred()


func _update_children() -> void:
	status_icon.custom_minimum_size = size/4
	painted_icon.custom_minimum_size = size/4
	index_label.custom_minimum_size = Vector2(4,4) * size


func _populate_colors(color : Color) -> void:
	normal_color = color
	hover_color = color.lightened(0.4)
	pressed_color = color.darkened(0.4)


@tool
extends Button

enum State {NORMAL, HOVER, PRESSED}

const MORE_INFO_TEXT_TEMPLATE := "{origin} (priority={priority})"

const REQUIRED_BIT_PRIORITY := 999
const REQUIRED_BIT_STRING := "*"
const REQUIRED_BIT_STRING_VERBOSE := "Required"

const NULL_COLOR := Color.TRANSPARENT
const NULL_PRIORITY := -1
const NULL_ORIGIN := -1

const TRANSPARENT_ALPHA := 0.66

const OriginTexts := {
	NULL_ORIGIN : "",
	TileMap.ORIGIN_PAINTED_TERRAIN: "Painted terrain",
	TileMap.ORIGIN_NEIGHBOR_TERRAIN_IS_PAINTED_TERRAIN: "Neighbor cell's terrain matches painted terrain",
	TileMap.ORIGIN_PATH_NEIGHBOR: "Neighbor cell is on painted path",
	TileMap.ORIGIN_ADDED_PATTERN: "Updated to match newly-chosen neighbor",
	TileMap.ORIGIN_OVERLAPPING_BITS: "Most frequent terrain found in overlapping peering bits",
	TileMap.ORIGIN_CURRENT_TERRAIN: "Terrain of cell's previous tile",
	TileMap.ORIGIN_DEFAULT_TO_CURRENT_TILE: "Defaulted to match bits of cell's previous tile",
}

const Globals := preload("res://addons/terrain_debugger/globals.gd")


# updated below
var state_colors := {
	State.NORMAL: Color.TRANSPARENT,
	State.HOVER: Color.TRANSPARENT,
	State.PRESSED: Color.TRANSPARENT,
}


var _state : State :
	set(value):
		_state = value
		_update_button_state()

var _color : Color :
	set(value):
		_color = value
		_update_color_rect()

var _priority : int :
	set(value):
		_priority = value
		_update_priority()

var _origin : int

var _more_info_text : String :
	set(value):
		_more_info_text = value
		_update_more_info_text()

@onready var _color_rect: ColorRect = %ColorRect
@onready var _priority_label: Label = %PriorityLabel
@onready var _priority_icon: TextureRect = %PriorityIcon
@onready var _priority_container: MarginContainer = %PriorityContainer
@onready var _priority_bkg_rect: ColorRect = %PriorityBkgRect



func _ready() -> void:
	reset()


func setup(p_color : Color, p_priority : int, p_origin : int) -> void:
	_color = p_color
	_priority = p_priority
	_origin = p_origin
	_more_info_text = MORE_INFO_TEXT_TEMPLATE.format({
		"origin": OriginTexts[_origin],
		"priority": _get_priority_string(true),
	})
	if has_tooltip_data():
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func remove_priority_background() -> void:
	_priority_bkg_rect.queue_free()


func get_more_info_text() -> String:
	return _more_info_text


func has_tooltip_data() -> bool:
	if _more_info_text == "":
		return false
	if _origin == NULL_ORIGIN:
		return false
	return true


func toggle_transparency(value : bool) -> void:
	if _color_rect.color == Color.TRANSPARENT:
		return
		
	if value:
		_color_rect.color.a = TRANSPARENT_ALPHA
	else:
		_color_rect.color.a = 1.0


func reset() -> void:
	_state = State.NORMAL
	_color = NULL_COLOR
	_priority = NULL_PRIORITY
	_origin = NULL_ORIGIN
	_more_info_text = ""


func _update_button_state() -> void:
	_color_rect.color = state_colors[_state]


func _update_color_rect() -> void:
	if !is_instance_valid(_color_rect):
		return
	
	_color_rect.color = _color

	
	state_colors[State.NORMAL] = _color
	state_colors[State.HOVER] = _color.lightened(0.2)
	state_colors[State.PRESSED] = _color.lightened(0.2)


func _update_priority() -> void:
	if !is_instance_valid(_priority_label):
		return
	
	_priority_container.hide()
	_priority_label.hide()
	_priority_icon.hide()
	
	if _priority == NULL_PRIORITY:
		return
	
	_priority_container.show()
	
	if _priority == REQUIRED_BIT_PRIORITY:
		_priority_icon.texture = get_theme_icon("Lock", "EditorIcons")
		_priority_icon.show()
	elif _priority == Globals.PAINTED_PRIORITY:
		_priority_icon.texture = get_theme_icon("CanvasItem", "EditorIcons")
		_priority_icon.show()
	else:
		_priority_label.text = _get_priority_string()
		_priority_label.show()


func _update_more_info_text() -> void:
	if has_tooltip_data():
		tooltip_text = _more_info_text
	else:
		tooltip_text = ""


func _get_priority_string(verbose := false) -> String:
	if _priority == NULL_PRIORITY:
		return ""
	
	if _priority == REQUIRED_BIT_PRIORITY:
		if verbose:
			return REQUIRED_BIT_STRING_VERBOSE
		else:
			return REQUIRED_BIT_STRING
	
	return str(_priority)


func _on_mouse_entered() -> void:
	if has_tooltip_data():
		_state = State.HOVER


func _on_mouse_exited() -> void:
	_state = State.NORMAL


func _on_pressed() -> void:
	_state = State.PRESSED


func _on_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_state = State.PRESSED
	else:
		_state = State.NORMAL

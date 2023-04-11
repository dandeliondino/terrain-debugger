@tool
extends "res://addons/terrain_debugger/controls/tile_display.gd"


@onready var texture_rect: TextureRect = %TextureRect
@onready var margin_control: Control = %MarginControl

var left_margin := 0 :
	set(value):
		left_margin = value
		margin_control.custom_minimum_size.x = value


func setup(tile : Dictionary, context : Context) -> void:
	# bit_container size not updating immediately;
	# signal works more reliably than doing this in-line
	bit_container.minimum_size_changed.connect(_update_texture_size)
		
	texture_rect.texture_filter = context.tile_map.texture_filter
	texture_rect.texture = context.get_tile_texture(tile["source_id"], tile["atlas_coords"])
	
	var bit_list : Array = CellNeighborsByMode[context.terrain_mode].duplicate()
	bit_list.append(Globals.CENTER_BIT_ID)
	
	for bit in bit_list:
		var bit_button : BitButton = bit_buttons[bit]
		if tile["bit_scores"].has(bit):
			var bit_properties : Dictionary = tile["bit_scores"][bit]
			bit_button.setup(
				Globals.ERROR_COLOR, 
				bit_properties.get("priority", BitButton.NULL_PRIORITY), 
				Globals.NULL_ORIGIN,
			)
		else:
			bit_button.setup(
				Globals.SCORED_BIT_COLOR,
				Globals.NULL_PRIORITY,
				Globals.NULL_ORIGIN,
			)
			
		bit_button.remove_priority_background()
		bit_button.show()
	

func _update_texture_size() -> void:
	texture_rect.custom_minimum_size = bit_container.size


func _update_tile_size() -> void:
	custom_minimum_size = tile_size
	super._update_tile_size()

@tool
extends "res://addons/terrain_debugger/controls/tile_display.gd"


func update(results : Dictionary, context : Context) -> void:
	reset()

	for bit in results["target_bits"]:
		var bit_button : BitButton = bit_buttons[bit]
		var bit_properties : Dictionary = results["target_bits"][bit]
		var terrain : int = bit_properties["terrain"]
		bit_button.setup(
			context.terrain_colors[terrain], 
			bit_properties["priority"], 
			bit_properties["origin"],
		)
		bit_button.show()

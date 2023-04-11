@tool
extends Panel

signal change_coords_requested(coords)

const REQUIRED_BIT_PRIORITY := 999

const NULL_TERRAIN := -99

const Globals := preload("res://addons/terrain_debugger/globals.gd")

const SnapshotTileDisplay := preload("res://addons/terrain_debugger/controls/snapshot_tile_display.gd")
const SnapshotTileDisplayControl := preload("res://addons/terrain_debugger/controls/snapshot_tile_display.tscn")
const TargetTileDisplay := preload("res://addons/terrain_debugger/controls/target_tile_display.gd")
const TargetTileDisplayControl := preload("res://addons/terrain_debugger/controls/target_tile_display.tscn")

const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context


var tile_directions := {
	SnapshotTileDisplay.TerrainBits.TOP_LEFT_CORNER: Vector2i.UP + Vector2i.LEFT,
	SnapshotTileDisplay.TerrainBits.TOP_SIDE: Vector2i.UP,
	SnapshotTileDisplay.TerrainBits.TOP_RIGHT_CORNER: Vector2i.UP + Vector2i.RIGHT,
	SnapshotTileDisplay.TerrainBits.LEFT_SIDE: Vector2i.LEFT,
	SnapshotTileDisplay.TerrainBits.CENTER: Vector2i.ZERO,
	SnapshotTileDisplay.TerrainBits.RIGHT_SIDE: Vector2i.RIGHT,
	SnapshotTileDisplay.TerrainBits.BOTTOM_LEFT_CORNER: Vector2i.DOWN + Vector2i.LEFT,
	SnapshotTileDisplay.TerrainBits.BOTTOM_SIDE: Vector2i.DOWN,
	SnapshotTileDisplay.TerrainBits.BOTTOM_RIGHT_CORNER: Vector2i.DOWN + Vector2i.RIGHT,
}

var terrain_set : int
var terrain_mode : TileSet.TerrainMode
var terrain_bits_by_coords := {}
var colors_by_terrain := {}

var _tile_displays := {}

@onready var tiles_container: GridContainer = %TilesContainer
@onready var show_bits_checkbutton: CheckButton = %ShowBitsCheckbutton
@onready var selected_tile_label: Label = %SelectedTileLabel


func _ready() -> void:
	_populate_tiles_container()


func update(p_coords : Vector2i, results_by_coords : Dictionary, context : Context) -> void:
	_reset_tiles()
	
	var selected_tile_results : Dictionary = results_by_coords[p_coords]
	var selected_tile_index : int = selected_tile_results["index"]
	
	selected_tile_label.text = "[ %s ]" % selected_tile_index
	selected_tile_label.set("theme_override_colors/font_color", Globals.SELECTED_COLOR)
	
	for neighbor in _tile_displays:
		var coords : Vector2i = p_coords + tile_directions[neighbor]
		var tile_display = _tile_displays[neighbor]
		
		if !results_by_coords.has(coords):
			tile_display.update_empty_tile(context)
			continue
		
		var neighbor_results : Dictionary = results_by_coords[coords]
		var index : int = neighbor_results["index"]
		
		var tile : Dictionary
		var updated : bool
		var tile_bits : Dictionary
		
		if index == selected_tile_index:
			tile_display.update(
				selected_tile_results,
				context,
			)
			continue
		elif index < selected_tile_index:
			tile = neighbor_results["selected_tile"]
			tile_bits = context.get_tile_bits(tile["source_id"], tile["atlas_coords"])
			updated = true
		elif index > selected_tile_index:
			tile = neighbor_results["previous_tile"]
			if context.is_tile_painted(coords):
				tile_bits = {Globals.CENTER_BIT_ID: 
					{
						"terrain": context.painted_terrain,
						"priority": Globals.PAINTED_PRIORITY,
					}
				}
			else:
				tile_bits = context.get_tile_bits(tile["source_id"], tile["atlas_coords"])
			updated = false

		tile_display.update(
			tile,
			index,
			tile_bits,
			updated,
			context,
		)
		
		# connect with new coords
		if tile_display.pressed.is_connected(_on_neighbor_tile_display_pressed):
			tile_display.pressed.disconnect(_on_neighbor_tile_display_pressed)
		tile_display.pressed.connect(_on_neighbor_tile_display_pressed.bind(coords))


func _toggle_bit_visibility(value : bool) -> void:
	for bit in _tile_displays:
		if bit == SnapshotTileDisplay.TerrainBits.CENTER:
			continue
		var tile_display : SnapshotTileDisplay = _tile_displays[bit]
		tile_display.toggle_bit_visibility(value)


func _populate_tiles_container() -> void:
	_tile_displays.clear()
	for child in tiles_container.get_children():
		child.queue_free()
	
	for neighbor in tile_directions:
		var tile_display : Control
		if neighbor == SnapshotTileDisplay.TerrainBits.CENTER:
			tile_display = TargetTileDisplayControl.instantiate()
		else:
			tile_display = SnapshotTileDisplayControl.instantiate()
		tiles_container.add_child(tile_display)
		
		_tile_displays[neighbor] = tile_display

	await get_tree().process_frame
	_toggle_bit_visibility(show_bits_checkbutton.button_pressed)


func _reset_tiles() -> void:
	for tile_display in _tile_displays.values():
		tile_display.reset()


func _on_show_bits_checkbutton_toggled(button_pressed: bool) -> void:
	_toggle_bit_visibility(button_pressed)


func _on_neighbor_tile_display_pressed(coords : Vector2i) -> void:
	change_coords_requested.emit(coords)

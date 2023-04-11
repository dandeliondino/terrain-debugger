@tool
extends Control

enum TerrainBits {
	CENTER=99,
	TOP_LEFT_CORNER=TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TOP_SIDE=TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TOP_RIGHT_CORNER=TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	RIGHT_SIDE=TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	BOTTOM_RIGHT_CORNER=TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	BOTTOM_SIDE=TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	BOTTOM_LEFT_CORNER=TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	LEFT_SIDE=TileSet.CELL_NEIGHBOR_LEFT_SIDE,
}

const CellNeighborsByMode := {
	TileSet.TerrainMode.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES: [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	],
	TileSet.TerrainMode.TERRAIN_MODE_MATCH_CORNERS: [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	],
	TileSet.TerrainMode.TERRAIN_MODE_MATCH_SIDES: [
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	],
}

const GridBits := [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	CENTER_BIT_ID,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]

const CENTER_BIT_ID := 99

const MINIMUM_TILE_SIZE := Vector2(16,16)

const Globals := preload("res://addons/terrain_debugger/globals.gd")

const BitButton := preload("res://addons/terrain_debugger/controls/bit_button.gd")
const BitButtonControl := preload("res://addons/terrain_debugger/controls/bit_button.tscn")
const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context



var tile_size : Vector2 :
	set(value):
		tile_size = value
		_update_tile_size()

var bit_buttons := {}

@onready var bit_container: GridContainer = %BitContainer


func _ready() -> void:
	_populate_bit_buttons()
	tile_size = MINIMUM_TILE_SIZE


func toggle_bit_visibility(value : bool) -> void:
	bit_container.visible = value

	
func reset() -> void:	
	for bit_button in bit_buttons.values():
		bit_button.reset()


func _update_tile_size() -> void:
	for bit_button in bit_buttons.values():
		bit_button.custom_minimum_size = tile_size/3


func _populate_bit_buttons() -> void:
	for child in bit_container.get_children():
		child.queue_free()
	
	for bit in GridBits:
		var bit_button : BitButton = BitButtonControl.instantiate()
		bit_container.add_child(bit_button)
		bit_buttons[bit] = bit_button




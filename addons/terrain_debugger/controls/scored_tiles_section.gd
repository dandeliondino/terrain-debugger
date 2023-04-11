@tool
extends Control

const Globals := preload("res://addons/terrain_debugger/globals.gd")
const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context

const ScoreButton := preload("res://addons/terrain_debugger/controls/score_button.gd")
const ScoredTileDisplay := preload("res://addons/terrain_debugger/controls/scored_tile_display.gd")
const ScoredTileDisplayControl := preload("res://addons/terrain_debugger/controls/scored_tile_display.tscn")

@onready var score_button: ScoreButton = %ScoreButton
@onready var scored_tiles_container: VBoxContainer = %ScoredTilesContainer

var tiles : Array
var context : Context
var tile_size : Vector2i

var tiles_added := false
var ready_complete := false

func ready() -> void:
	print(score_button)
	ready_complete = true


func setup(score : int, p_tiles : Array, p_tile_size : Vector2i, p_context : Context, start_expanded : bool) -> void:
	tiles = p_tiles
	tile_size = p_tile_size
	context = p_context
	
	if not ready_complete:
		await ready

	score_button.toggled.connect(_score_button_toggled) # TODO: see if signal called
	score_button.setup(score, scored_tiles_container, start_expanded)


func _add_tiles() -> void:
	print("_add_tiles()")
	for tile in tiles:
		var scored_tile_display : ScoredTileDisplay = ScoredTileDisplayControl.instantiate()
		scored_tiles_container.add_child(scored_tile_display)
		scored_tile_display.setup(tile, context)
#		scored_tile_display.left_margin = 48
		scored_tile_display.tile_size = tile_size
		var separator := HSeparator.new()
		scored_tiles_container.add_child(separator)
	tiles_added = true


func _score_button_toggled(button_pressed : bool) -> void:
	if button_pressed and not tiles_added:
		_add_tiles()

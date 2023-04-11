@tool
extends Panel

const Globals := preload("res://addons/terrain_debugger/globals.gd")
const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context

const ScoredTileDisplay := preload("res://addons/terrain_debugger/controls/scored_tile_display.gd")
const ScoredTileDisplayControl := preload("res://addons/terrain_debugger/controls/scored_tile_display.tscn")

var default_tile_size := Vector2i(32, 32)
var tile_size : Vector2i

@onready var results_tree: Tree = %ResultsTree
@onready var tiles_container: GridContainer = %TilesContainer


func _ready() -> void:
	tile_size = default_tile_size * EditorPlugin.new().get_editor_interface().get_editor_scale()



func update(results : Dictionary, context : Context) -> void:
	reset()
	
	_populate_results_tree(results)
	_populate_tiles(results, context)


func _populate_results_tree(results : Dictionary) -> void:
	var discarded_center_count : int = results["rejected_tiles_center_bit"].size()
	var discarded_peering_count : int = results["rejected_tiles_peering_bit"].size()
	var scored_count : int = results["evaluated_tiles"].size()
	var total_count : int = discarded_center_count + discarded_peering_count + scored_count
	
	results_tree.set_column_title(1, "Tiles")
	var root := results_tree.create_item()
	var total_item := results_tree.create_item(root)
	total_item.set_text(0, "Total tiles")
	total_item.set_text(1, str(total_count))	
	total_item.set_selectable(0, false)
	total_item.set_selectable(1, false)

	var discarded_center_item := results_tree.create_item(root)
	discarded_center_item.set_text(0, "Tiles missing required center bit")
	var discarded_center_string = "-" + str(discarded_center_count) if discarded_center_count > 0 else "0"
	discarded_center_item.set_text(1, discarded_center_string)
	discarded_center_item.set_selectable(0, false)
	discarded_center_item.set_selectable(1, false)
	
	var discarded_peering_item := results_tree.create_item(root)
	discarded_peering_item.set_text(0, "Tiles missing required peering bit")
	var discarded_peering_string = "-" + str(discarded_peering_count) if discarded_peering_count > 0 else "0"
	discarded_peering_item.set_text(1, discarded_peering_string)
	discarded_peering_item.set_selectable(0, false)
	discarded_peering_item.set_selectable(1, false)

	var scored_item := results_tree.create_item(root)
	scored_item.set_text(0, "Scored tiles")
	scored_item.set_text(1, str(scored_count))
	scored_item.set_selectable(0, false)
	scored_item.set_selectable(1, false)
	


func _populate_tiles(results : Dictionary, context : Context) -> void:
	for i in results["min_score_tiles"].size():
		var tile : Dictionary = results["min_score_tiles"][i]
		
		for evaluated_tile in results["evaluated_tiles"]:
			if tile.has("bit_scores"):
				break
			if evaluated_tile["source_id"] == tile["source_id"]:
				if evaluated_tile["atlas_coords"] == tile["atlas_coords"]:
					tile["bit_scores"] = evaluated_tile["bit_scores"]
					break
		
		var score : int = tile["score"]
		var score_text := str(score)
		
		var text : String
		if i == 0:
			text = "Previous tile"
			score_text = "∞"
		elif i == results["min_score_tiles"].size() - 1:
			text = "Final tile"
		
		var text_label := Label.new()
		tiles_container.add_child(text_label)
		text_label.text = text
		
		var score_label := Label.new()
		tiles_container.add_child(score_label)
		score_label.text = score_text
		
		var scored_tile_display : ScoredTileDisplay = ScoredTileDisplayControl.instantiate()
		tiles_container.add_child(scored_tile_display)
		scored_tile_display.setup(tile, context)
		scored_tile_display.tile_size = tile_size



func reset() -> void:
	results_tree.clear()
	for child in tiles_container.get_children():
		child.queue_free()

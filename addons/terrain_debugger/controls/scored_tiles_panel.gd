@tool
extends Panel

const Globals := preload("res://addons/terrain_debugger/globals.gd")
const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context

const ScoredTilesSection := preload("res://addons/terrain_debugger/controls/scored_tiles_section.gd")
const ScoredTilesSectionControl := preload("res://addons/terrain_debugger/controls/scored_tiles_section.tscn")

var default_tile_size := Vector2i(32, 32)
var tile_size : Vector2i

@onready var score_list_container: VBoxContainer = %ScoreListContainer


func _ready() -> void:
	tile_size = default_tile_size * EditorPlugin.new().get_editor_interface().get_editor_scale()


func update(results : Dictionary, context : Context) -> void:
	reset()
	
	var results_by_score := _get_results_by_score(results)
	var sorted_scores := results_by_score.keys().duplicate()
	sorted_scores.sort_custom(func (a,b): return a < b)
	
	var first_section := true

	for score in sorted_scores:
		var scored_tiles_section : ScoredTilesSection = ScoredTilesSectionControl.instantiate()
		score_list_container.add_child(scored_tiles_section)
		scored_tiles_section.setup(score, results_by_score[score], tile_size, context, first_section)
		first_section = false


func reset() -> void:
	for child in score_list_container.get_children():
		child.queue_free()
	

func _get_results_by_score(results : Dictionary) -> Dictionary:
	var results_by_score := {}
	for tile in results["evaluated_tiles"]:
#		print("_get_results_by_score() tile=%s" % tile)
		if !results_by_score.has(tile["score"]):
			results_by_score[tile["score"]] = []
		results_by_score[tile["score"]].append(tile)
#	print(results_by_score)
	return results_by_score

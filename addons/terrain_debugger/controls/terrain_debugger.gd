@tool
extends Control

signal state_changed(value)
signal bottom_panel_show_requested
signal bottom_panel_hide_requested

enum State {WAITING, UPDATING, RESULTS}

const META_BORDER_COLOR := "BORDER_COLOR"
const META_COORDS := "COORDS"

const MAP_RECT_HOVER_COLOR := Color.WHITE
const MAP_RECT_CLICK_COLOR := Color.BLACK

const VOID_TERRAIN_COLOR := Color.DIM_GRAY
const EMPTY_TILE_COLOR := Color.BLACK

const OverlayReference := preload("res://addons/terrain_debugger/controls/overlay_reference.tscn")
const TileMapRect := preload("res://addons/terrain_debugger/controls/tile_map_rect.gd")
const TileMapRectControl := preload("res://addons/terrain_debugger/controls/tile_map_rect.tscn")

# --------------------------------
#		CONTEXT
# --------------------------------

class Context:
	enum PaintMode {Connect, Path}
	
	const INVALID_SOURCE := -1
	const REQUIRED_BIT_PRIORITY := 999

	const NULL_TERRAIN := -99
	const VOID_TERRAIN := -1
	
	const CENTER_TERRAIN_BIT := 99

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

	var tile_map : TileMap
	var tile_set : TileSet
	var terrain_set : int
	var painted_terrain : int
	var painted_coords_list : Array
	var paint_mode : PaintMode
	
	var terrain_mode : TileSet.TerrainMode
	var tile_size : Vector2i
	var terrain_colors : Dictionary
	
	var image_format : int
	
	func _init(p_tile_map : TileMap, p_terrain_set : int, p_terrain : int, p_painted_coords_list : Array, p_paint_mode : PaintMode) -> void:
		tile_map = p_tile_map
		tile_set = tile_map.tile_set
		terrain_set = p_terrain_set
		painted_terrain = p_terrain
		painted_coords_list = p_painted_coords_list
		paint_mode = p_paint_mode
		
		terrain_mode = tile_map.tile_set.get_terrain_set_mode(terrain_set)
		tile_size = tile_set.tile_size
		_setup_terrain_colors()
		_setup_image_format()
		

	func _setup_terrain_colors() -> void:
		terrain_colors = {}
		for terrain in tile_map.tile_set.get_terrains_count(terrain_set):
			terrain_colors[terrain] = tile_map.tile_set.get_terrain_color(terrain_set, terrain)
		terrain_colors[VOID_TERRAIN] = VOID_TERRAIN_COLOR

	
	func _setup_image_format() -> void:
		for source_id in tile_set.get_source_count():
			if not tile_set.get_source(source_id) is TileSetAtlasSource:
				continue
			var source : TileSetAtlasSource = tile_set.get_source(source_id)
			image_format = source.texture.get_image().get_format()
			break
			
	

	func get_terrain_name(terrain : int) -> String:
		return tile_set.get_terrain_name(terrain_set, terrain)


	func get_painted_terrain_color() -> Color:
		return terrain_colors[painted_terrain]
	
	
	func get_painted_terrain_name() -> String:
		return get_terrain_name(painted_terrain)


	func get_tile_texture(source_id : int, atlas_coords : Vector2i) -> ImageTexture:
		var image := get_tile_image(source_id, atlas_coords)
		return ImageTexture.create_from_image(image)
		
		
	func get_tile_image(source_id : int, atlas_coords : Vector2i) -> Image:
		if source_id == INVALID_SOURCE:
			return _get_void_image()
		var source : TileSetAtlasSource = tile_set.get_source(source_id)
		var texture_region : Rect2i = source.get_tile_texture_region(atlas_coords)
		return source.texture.get_image().get_region(texture_region)


	func is_tile_painted(coords : Vector2i) -> bool:
		return coords in painted_coords_list


	func _get_void_image() -> Image:
		var image := Image.create(tile_map.tile_set.tile_size.x, tile_map.tile_set.tile_size.y, false, Image.FORMAT_RGB8)
		image.fill(VOID_TERRAIN_COLOR)
		return image
		

	func _get_void_texture() -> ImageTexture:
		var image := _get_void_image()
		return ImageTexture.create_from_image(image)


	func get_empty_texture() -> ImageTexture:
		var image := Image.create(tile_map.tile_set.tile_size.x, tile_map.tile_set.tile_size.y, false, Image.FORMAT_RGB8)
		image.fill(EMPTY_TILE_COLOR)
		return ImageTexture.create_from_image(image)
	
	
	func get_tile_bits(source_id : int, atlas_coords : Vector2i) -> Dictionary:
		var bits := {}
		if source_id == INVALID_SOURCE:
			return bits
		var source : TileSetAtlasSource = tile_set.get_source(source_id)
		var tile_data := source.get_tile_data(atlas_coords, 0)
		for bit in CellNeighborsByMode[terrain_mode]:
			# formatted to match bit_property dictionaries
			bits[bit] = {}
			bits[bit]["terrain"] = tile_data.get_terrain_peering_bit(bit)
		bits[CENTER_TERRAIN_BIT] = {}
		bits[CENTER_TERRAIN_BIT]["terrain"] = tile_data.get_terrain()
		return bits
	
	
var state := State.WAITING :
	set(value):
		var changed = (state != value)
		state = value
		if changed:
			state_changed.emit(value)
		

var tile_map : TileMap

var tile_size : Vector2i

var tile_map_rects := []

var tile_results := []

var results_by_coords := {}

var current_coords = Vector2i(9999,9999)

var context : Context

var connections := {
	"best_terrain_pattern_for_constraints_found": _on_best_terrain_pattern_for_constraints_found,
	"terrain_updates_started": _on_terrain_updates_started,
	"terrain_updates_finished": _on_terrain_updates_finished,
}

var overlay_reference : Control

var canvas_item_editor : Control

@onready var replay_panel: Panel = %ReplayPanel
@onready var tile_state_panel: Panel = %TileStatePanel
@onready var scored_tiles_panel: Panel = %ScoredTilesPanel


func _ready() -> void:
	tile_state_panel.change_coords_requested.connect(_on_show_tile_at_coords_requested)


# -------------------------------------------------
# 			WAITING STATE
# -------------------------------------------------

func update(p_tile_map : TileMap) -> void:
	_disconnect_tile_map()
	_reset()
	state = State.WAITING
	current_coords = Vector2i(9999,9999)
	
	tile_map = p_tile_map
	if tile_map == null:
		return
	
	tile_size = tile_map.tile_set.tile_size
	_connect_tile_map()


func _connect_tile_map() -> void:
	if !is_instance_valid(tile_map):
		return
	
	for signal_name in connections:
		var callable : Callable = connections[signal_name]
		if tile_map.is_connected(signal_name, callable):
			continue
		tile_map.connect(signal_name, callable)
	

func _disconnect_tile_map() -> void:
	if !is_instance_valid(tile_map):
		return
	
	for signal_name in connections:
		var callable : Callable = connections[signal_name]
		if !tile_map.is_connected(signal_name, callable):
			continue
		tile_map.disconnect(signal_name, callable)


# -------------------------------------------------
# 			UPDATING STATE
# -------------------------------------------------


func _process_results() -> void:
	results_by_coords.clear()
	
	if tile_results.size() == 0:
		return
	
	for i in tile_results.size():
		var result : Dictionary = tile_results[i]
		result["index"] = i
		results_by_coords[result["coords"]] = result
		_create_tile_map_rect(result)
	
		
	if is_instance_valid(overlay_reference):
		overlay_reference.queue_free()
		
	overlay_reference = OverlayReference.instantiate()
	canvas_item_editor.add_child(overlay_reference)
	overlay_reference.setup(results_by_coords, context)


func _create_tile_map_rect(result : Dictionary) -> void:
	var tile_map_rect : TileMapRect = TileMapRectControl.instantiate()
	tile_map_rect.init(result, context, self)
	tile_map.add_child(tile_map_rect)
	tile_map_rects.append(tile_map_rect)





# -------------------------------------------------
# 			RESULTS STATE
# -------------------------------------------------

func has_results() -> bool:
	return state == State.RESULTS


func process_mouse_movement() -> bool:
	var pos := tile_map.get_local_mouse_position()
	var captured := false
	
	for map_rect in tile_map_rects:
		if map_rect.get_rect().has_point(pos):
			map_rect.set_hovered(true)
			captured = true
		else:
			map_rect.set_hovered(false)
	
	return captured


func process_left_click() -> bool:
	var pos := tile_map.get_local_mouse_position()
	var captured := false
	
	for map_rect in tile_map_rects:
		if map_rect.get_rect().has_point(pos):
			captured = true
			_show_tile_at_coords(map_rect.coords)
			break
	
	if !captured:
		_exit_results_state()
	
	return true


func escape() -> bool:
	_exit_results_state()
	await get_tree().create_timer(0.1).timeout
	return true


func _show_tile_at_coords(coords : Vector2i) -> void:
	if current_coords == coords:
		return
		
	print("moving to coords: %s" % coords)
	current_coords = coords
	
	for map_rect in tile_map_rects:
		if map_rect.coords == coords:
			map_rect.set_selected(true)
		else:
			map_rect.set_selected(false)
	
	_update_bottom_panel(coords)


func _update_bottom_panel(coords : Vector2i) -> void:
	replay_panel.update(results_by_coords[coords], context)
	scored_tiles_panel.update(results_by_coords[coords], context)
	tile_state_panel.update(coords, results_by_coords, context)
	bottom_panel_show_requested.emit()


func _exit_results_state() -> void:
	_reset()
	bottom_panel_hide_requested.emit()



func _on_show_tile_at_coords_requested(coords : Vector2i) -> void:
	_show_tile_at_coords(coords)



# -------------------------------------------------
# 				CLEAN UP
# -------------------------------------------------

func clean_up() -> void:
	_clear_tile_map_rects() 


func _reset() -> void:
	_clear_tile_map_rects()
	state = State.WAITING


func _clear_tile_map_rects() -> void:
	if is_instance_valid(overlay_reference):
		overlay_reference.queue_free()
	while tile_map_rects.size() > 0:
		tile_map_rects.pop_back().queue_free()


# -------------------------------------------------
# 				SIGNALS
# -------------------------------------------------

func _on_terrain_updates_started(painted_coords_list : Array, terrain_set : int, terrain : int, path_mode : bool) -> void:
	var paint_mode : Context.PaintMode
	if path_mode:
		paint_mode = Context.PaintMode.Path
	else:
		paint_mode = Context.PaintMode.Connect
		
	context = Context.new(tile_map, terrain_set, terrain, painted_coords_list, paint_mode)
	state = State.UPDATING
	tile_results.clear()


func _on_best_terrain_pattern_for_constraints_found(results : Dictionary) -> void:
#	print("_on_best_terrain_pattern_for_constraints_found")
	if state != State.UPDATING:
		printerr("_on_best_terrain_pattern_for_constraints_found called in wrong state")
	tile_results.append(results)


func _on_terrain_updates_finished() -> void:
#	print("_on_terrain_updates_finished")
	_reset()
	_process_results()
	# wait here so the prior mouseclick is not processed as click
	await get_tree().create_timer(0.1).timeout
	state = State.RESULTS


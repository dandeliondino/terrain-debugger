@tool
extends PanelContainer

const SCALE_FACTOR := Vector2i(4,4)

const Globals := preload("res://addons/terrain_debugger/globals.gd")
const Legend := preload("res://addons/terrain_debugger/controls/legend.gd")

const Context := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd").Context

var context : Context
var results_by_coords : Dictionary
var scaled_tile_size : Vector2i

@onready var legend: Legend = %Legend

@onready var before_rect: TextureRect = %BeforeRect
@onready var after_rect: TextureRect = %AfterRect
@onready var arrow_rect: TextureRect = %ArrowRect


func _ready() -> void:
	arrow_rect.texture = get_theme_icon("ArrowRight", "EditorIcons")
	_setup_legend()


func setup(p_results_by_coords : Dictionary, p_context : Context) -> void:
	context = p_context
	results_by_coords = p_results_by_coords
	
	_setup_texture("previous_tile", before_rect, true)
	_setup_texture("selected_tile", after_rect, false)


func _setup_texture(tile_key : String, texture_rect : TextureRect, substitute_painted := false) -> void:
	scaled_tile_size = context.tile_size * SCALE_FACTOR
	var coords_rect := _get_tile_rect(results_by_coords)
	var image_size = (coords_rect.size * scaled_tile_size) + scaled_tile_size
	var image := Image.create(image_size.x, image_size.y, false, context.image_format)
	
	var filter : int
	if context.tile_map.texture_filter == TEXTURE_FILTER_LINEAR:
		filter = Image.INTERPOLATE_BILINEAR
	else:
		filter = Image.INTERPOLATE_NEAREST
	
	var painted_image := _get_painted_image()
	
	for coords in results_by_coords:
		var tile_image : Image
		if substitute_painted && context.is_tile_painted(coords):
			tile_image = painted_image
		else:
			var tile : Dictionary = results_by_coords[coords][tile_key]
			tile_image = context.get_tile_image(tile["source_id"], tile["atlas_coords"])
			tile_image.resize(scaled_tile_size.x, scaled_tile_size.y, filter)
		var pos := _coords_to_pos(coords, coords_rect.position, scaled_tile_size)
		image.blit_rect(tile_image, tile_image.get_used_rect(), pos)

	texture_rect.texture_filter = context.tile_map.texture_filter
	texture_rect.texture = ImageTexture.create_from_image(image)



func _coords_to_pos(coords : Vector2i, coords_offset : Vector2i, tile_size : Vector2i) -> Vector2i:
	var adj_coords := coords - coords_offset
	var pos := adj_coords * tile_size
	return pos

	
func _get_painted_image() -> Image:
	var image := Image.create(scaled_tile_size.x, scaled_tile_size.y, false, context.image_format)
	var color_rect := Rect2i(Vector2i.ZERO, scaled_tile_size).grow(-4)
	var icon_rect := color_rect.grow(-2)
	image.fill(Globals.ICON_BORDER_COLOR)
	image.fill_rect(color_rect, context.get_painted_terrain_color())
	var painted_icon := get_theme_icon(Globals.PAINTED_ICON, "EditorIcons").get_image()
	painted_icon.resize(icon_rect.size.x, icon_rect.size.y)
	image.blend_rect(painted_icon, painted_icon.get_used_rect(), icon_rect.position)
	return image


func _get_tile_rect(results_by_coords : Dictionary) -> Rect2i:
	var sorted_coords := results_by_coords.keys().duplicate()
	sorted_coords.sort_custom(func(a,b): return a.x < b.x)
	var x_pos : int = sorted_coords.front().x
	var x_end : int = sorted_coords.back().x
	sorted_coords.sort_custom(func(a,b): return a.y < b.y)
	var y_pos : int = sorted_coords.front().y
	var y_end : int = sorted_coords.back().y
	return Rect2i(x_pos, y_pos, x_end - x_pos, y_end - y_pos)


func _setup_legend() -> void:
#	legend.set_title("Tile Icons")
	legend.add_icon_item("Painted tile", Globals.PAINTED_ICON)
	legend.add_icon_item("Score = 0", "StatusSuccess")
	legend.add_icon_item("Score > 0", "StatusError")
	legend.add_text_item("Numbers represent the order tiles were chosen")


func _create_view() -> void:
	pass


func sort_coords(a,b) -> bool:
	if a.x == b.x:
		return a.y < b.y
	return a.x < b.x

@tool
extends EditorPlugin

const PLUGIN_NAME := "terrain_debugger"

const TerrainDebugger := preload("res://addons/terrain_debugger/controls/terrain_debugger.gd")
const TerrainDebuggerControl := preload("res://addons/terrain_debugger/controls/terrain_debugger.tscn")

var terrain_debugger : TerrainDebugger
var terrain_debugger_button : Button

var tile_map_editor : Node

func _enter_tree() -> void:
	if !TileMap.new().has_signal("terrain_updates_started"):
		printerr("Terrain Debugger: Required custom editor build not detected. Disabling plugin.")
		print("See github.com/dandeliondino/terrain-debugger for details.")
		get_editor_interface().set_plugin_enabled(PLUGIN_NAME, false)
		return

	tile_map_editor = get_editor_interface().get_base_control().find_children("*", "TileMapEditor", true, false)[0]

	_add_terrain_debugger()


func _handles(object: Object) -> bool:
	if object.get_class() == "TileMap":
		terrain_debugger.update(object)
		return true
	elif object.get_class() == "TileSet":
		return true
	else:
		terrain_debugger.update(null)
	return false


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if !terrain_debugger.has_results():
		return false

	if event is InputEventMouseMotion:
		return terrain_debugger.process_mouse_movement()
	elif event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		terrain_debugger.process_left_click()
		return true
	elif event is InputEventKey && event.keycode == KEY_ESCAPE:
		terrain_debugger.escape()
		return true

	return false


func _exit_tree() -> void:
	_remove_terrain_debugger()


func _add_terrain_debugger() -> void:
	terrain_debugger = TerrainDebuggerControl.instantiate()
	terrain_debugger_button = add_control_to_bottom_panel(terrain_debugger, "Terrain Debugger")
	terrain_debugger_button.hide()

	terrain_debugger.state_changed.connect(_on_terrain_debugger_state_changed)
	terrain_debugger.bottom_panel_show_requested.connect(_on_bottom_panel_show_requested)
	terrain_debugger.bottom_panel_hide_requested.connect(_on_bottom_panel_hide_requested)

	terrain_debugger.canvas_item_editor = get_editor_interface().get_base_control().find_children("*", "CanvasItemEditor", true, false)[0]


func _remove_terrain_debugger() -> void:
	if is_instance_valid(terrain_debugger):
		terrain_debugger.clean_up()
		remove_control_from_bottom_panel(terrain_debugger)
		terrain_debugger.queue_free()


func _on_terrain_debugger_state_changed(value : TerrainDebugger.State) -> void:
	pass


func _on_bottom_panel_show_requested() -> void:
	terrain_debugger_button.show()
	make_bottom_panel_item_visible(terrain_debugger)


func _on_bottom_panel_hide_requested() -> void:
	terrain_debugger_button.hide()
	make_bottom_panel_item_visible(tile_map_editor)

extends Node2D

var leave_menu = false

var my_seed
var object_id = 0
var obj_properties = []
var object_ids = {}

var player
var map
var music

var map_manager
var quest_system = null
var current_map_id 

func _init():
	Res.game = self
	quest_system = load( "res://Scripts/QuestSystem.gd" ).new()

func set_map_manager(location_manager):
	map_manager    = location_manager
	current_map_id = -1

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	ProjectSettings.set_setting("rendering/environment/default_clear_color", "1a1918") ##usunąć, gdy naprawią powyższe :/
	player = $Player
	
	DungeonState.current_floor = 0
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)
	
	PlayerStats.health = PlayerStats.statistic["max_health"][0]
	PlayerStats.mana   = PlayerStats.statistic["max_mana"][0]
	
	change_map(0, "Mechania")
	player.UI.init_map_menu(map_manager.get_location_numbers(), map_manager.get_location_types(), map_manager.get_locations_names(), map_manager.get_loations_descriptions())
	

func acquire_new_map( change, type_of_flor, selected_world = "" ):
	get_tree().paused = true
	if map:
		map.remove_child(player)
		call_deferred("remove_child", map )
	#	get_tree().paused = true
		map.clear()
	#	get_tree().paused = false
	else: remove_child(player)
	
	var new_map = map_manager.get_new_map(change, selected_world) if type_of_flor == "Location" else map_manager.get_new_floor(change)
	map_manager.mutex.unlock()
	
	new_map.add_child(player)
	
	map = new_map
	
#	for child in get_children():
#		if new_map.name == child.name: 
#			new_map.set_player_position(change)
#			return
			
	add_child(new_map)
	new_map.initialize()
	new_map.fill()
	new_map.set_player_position(change)
	get_tree().paused = false

func on_queue_free():
	map_manager.force_thread_stop = true
	map_manager = null
	call_deferred("queue_free")

func change_map(map_id, selected_world):
	player.UI.disable_map_change()
	if current_map_id == map_id : 
		return
	current_map_id = map_id
	
	acquire_new_map( map_id, "Location" , selected_world )

func _physics_process(delta):
	
	if player.UI.need_map_change():
		change_map(player.UI.get_new_map_id(), player.UI.get_new_map_world())
	
	if Input.is_action_just_pressed("Menu") and !leave_menu:
		Res.ui_sample("MenuEnter")
		open_menu()
	elif Input.is_action_just_released("Menu"):
		leave_menu = false

func open_menu():
	player.UI.enable()
	player.UI.get_node("FloorLabel").visible = false
	get_tree().paused = true


func change_floor(change, location_change = false):
	if location_change: 
		open_menu()
		player.UI.set_location_change_screen()
		return
	
	acquire_new_map( change, "Floor" )
	player.change_dir(2)
	
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)

func perma_state(object, method):
	var already_saved = false
	
	for obj in obj_properties:
		if obj.id == object_id and obj.saved:
			object.call(method)
			already_saved = true
	
	if !already_saved: object_ids[object] = object_id
	object_id += 1

func save_state(object):
	obj_properties.append({"id": object_ids[object], "saved": true})
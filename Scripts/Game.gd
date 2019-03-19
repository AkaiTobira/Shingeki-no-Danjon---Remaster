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
var current_map_id 

func _init():
	Res.game = self
	map_manager = load("res://Scripts/MapManager.gd").new()

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
#	ProjectSettings.set_setting("rendering/environment/default_clear_color", "1a1918") ##usunąć, gdy naprawią powyższe :/
	player = $Player
	
	DungeonState.current_floor = 0
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)
	
	PlayerStats.health = PlayerStats.statistic["mx_hpp"][0]
	PlayerStats.mana   = PlayerStats.statistic["mx_man"][0]
	
	player.UI.init_map_menu(map_manager.get_location_numbers(), map_manager.get_location_types(), map_manager.get_locations_names(), map_manager.get_loations_descriptions())
	current_map_id = -1
	change_map(0)

func acquire_new_map( change, type_of_flor ):
	if map:
		map.remove_child(player)
		remove_child(map) #Debug : find a way to disable physical detections
	else: remove_child(player)
	
	var new_map = map_manager.get_new_map(change) if type_of_flor == "Location" else map_manager.get_new_floor(change)
	new_map.add_child(player)
	
	map = new_map
	add_child(new_map)
	new_map.initialize()
	new_map.set_player_position(change)

func change_map(map_id):
	player.UI.disable_map_change()
	if current_map_id == map_id : 
		return
	current_map_id = map_id
	
	acquire_new_map( map_id, "Location" )
	

func _process(delta):
	
	if player.UI.need_map_change():
		var new_id = player.UI.get_new_map_id()
		change_map(new_id)
	
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
	
	#TO BE CHECKED (_)
	
	#if map.get("my_seed"):
	#	DungeonState.visited_floors[DungeonState.current_floor] = {"seed": map.my_seed, "obj_properties": obj_properties}
	#DungeonState.current_floor += change
	
	#object_id = 0
	#var new_map = load("res://Maps/RandomMap.tscn").instance()
	#if DungeonState.current_floor == 0: #ULTRAMEGAOSTATECZNYHACK
	#	new_map = load("res://Maps/JigsawRoom.tscn").instance()
	#elif DungeonState.current_floor == 4: #ULTRAMEGAOSTATECZNYHACK
	#	new_map = load("res://Maps/BossRoom.tscn").instance()
	#else:
#		if DungeonState.visited_floors.has(DungeonState.current_floor):
#			var state = DungeonState.visited_floors[DungeonState.current_floor]
#			new_map.my_seed = state.seed
#			obj_properties = state.obj_properties
#		else:
#			obj_properties = []
#		new_map.from = ("UP" if change > 0 else "DOWN")
	
#	set_map(new_map)
	player.change_dir(2)
	
#s	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)

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
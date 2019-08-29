extends Node2D

var numbers_of_locations = []

func get_location_numbers() :
	return numbers_of_locations
	
func get_location_types() :
	var types = []
	for location in Res.location:
		types.append(Res.location[location]["types_names"])
	return types
	
func get_locations_names():
	var names = []
	for location in Res.location:
		names.append(Res.location[location]["location_names"])
	return names
	
func get_loations_descriptions():
	var descriptions = []
	for location in Res.location:
		descriptions.append(Res.location[location]["types_descriptions"])
	return descriptions

func load_basic_maps(): load_worlds()

var maps = {}
var thread = Thread.new()
var mutex  = Mutex.new()

var current_location = -1
var current_floor    = 0
var current_world    = ""

var is_next_map_ready  = false
var preloaded_map_list = []
var active_map         = null

func get_new_floor(change):
	if is_next_map_ready : print( "OK : Map ready ", len( preloaded_map_list ) )

	if not is_next_map_ready and current_floor + change > len(preloaded_map_list) or current_floor + change ==  maps[current_world]["ST" + str(current_location)]["number_of_floors"] : 
		print( "Reach the top ... or cheated" )
		return maps[current_world]["ST" + str(current_location)]["top"]

	current_floor += change	
	mutex.lock()
	return maps[current_world]["ST" + str(current_location)]["begin"] if current_floor-1 < 0 else preloaded_map_list[current_floor-1]

func get_new_map(location_id, selected_world):
	
	current_location = location_id
	current_floor    = 0
	current_world    = selected_world

	if not thread.is_active():
		thread.start( self, "generate_maps", [] )
	else: 
		Res.background_generation_lock = true
	
	is_next_map_ready = false
	return maps[current_world]["ST" + str(current_location)]["begin"]


func _bg_load_done():
	thread.wait_to_finish()
	if Res.background_generation_lock : 
		is_next_map_ready = false
		thread.start( self, "generate_maps", [] )

func generate_maps( non_used ):
	
	Res.background_generation_lock = false
	if maps[current_world]["ST" + str(current_location)]["number_of_floors"] == 0: 
		call_deferred( "_bg_load_done" )
		return
	mutex.lock()
	preloaded_map_list = []
	mutex.unlock()
	
	for i in range( maps[current_world]["ST" + str(current_location)]["number_of_floors"] ):
		if Res.background_generation_lock : 
			is_next_map_ready = false
			call_deferred( "_bg_load_done" )
			return
		
		var new_floor = load("res://Maps/RandomMap.tscn").instance()
				
		if len( maps[current_world]["ST" + str(current_location)]["seeds"] ) < i : 
			call_deferred( "_bg_load_done" )
			return
		
		new_floor.generate( Res.location[current_world]["asset_info"], i + 1, maps[current_world]["ST" + str(current_location)]["seeds"][i] )
		mutex.lock()
		if Res.background_generation_lock : 
			is_next_map_ready = false
			call_deferred("_bg_load_done")
			mutex.unlock()
			return
		preloaded_map_list.append( new_floor )
		is_next_map_ready = true
		mutex.unlock()
		
	call_deferred( "_bg_load_done" )

func load_start_point(location):
	maps[location]["ST0"] = { 
				"begin" :  load("res://Maps/" + Res.location[location]["start_point"] + ".tscn").instance() ,
				"number_of_floors" : 0
				}

func load_main_tower(location):
	maps[location]["ST1"] = {
		"begin" : load("res://Maps/RandomMap.tscn").instance(),
		"number_of_floors" : Res.location[location]["nmbBossFloors"],
		"seeds" : [],
		"top" : load("res://Maps/" + Res.location[location]["boss_tower_top"] + ".tscn").instance()
		}
	maps[location]["ST1"]["begin"].generate(Res.location[location]["asset_info"], 0)
	maps[location]["ST1"]["begin"].stairs_holder[0].location_change = true
	for sed in range( maps[location]["ST1"]["number_of_floors"] ): 
		maps[location]["ST1"]["seeds"].append( randi() )

func load_supply_towers(location):
	for i in range( randi() % int( Res.location[location]["nmbSmallTowers"] ) + 1 ):
		var tower_name = "ST" + str(i + 2) 
		maps[location][tower_name] = { 
			"begin" :  load("res://Maps/RandomMap.tscn").instance() ,
			"number_of_floors" : randi() % int(Res.location[location]["nmbSmallFloors"]) + 1,
			"top"   :  load("res://Maps/" + Res.location[location]["small_tower_top"][randi() % len(Res.location[location]["small_tower_top"])] + ".tscn").instance()				
			}
		maps[location][tower_name]["begin"].generate(Res.location[location]["asset_info"], i)
		maps[location][tower_name]["begin"].stairs_holder[0].location_change = true
		maps[location][tower_name]["seeds"] = []
		for sed in range( maps[location][tower_name]["number_of_floors"] ): maps[location][tower_name]["seeds"].append( randi() )
	
func load_settlements(location): pass
	
func load_worlds():
	current_world = "Mechania"
	maps.clear()
	numbers_of_locations = []
	
	for location in Res.location:
		if location == "Locked" : 
			numbers_of_locations.append( [1, 1, 0, 0] )
			continue

		maps[location] = {}
		load_start_point(location)
		load_main_tower(location)
		load_supply_towers(location)
		load_settlements(location)
		
		Res.background_generation_lock = false
		numbers_of_locations.append( [ 1, 1, len( maps[location] ) -2, 0 ] ) # 0 reserved for non_existing_town
		print(maps)

func _exit_tree():
	Res.background_generation_lock = true
	for map_name in maps:
		for location in maps[map_name]:
			maps[map_name][location]["begin"].free()
			if maps[map_name][location].has("top"):
				maps[map_name][location]["top"].free()
	
	mutex.lock()
	for map in preloaded_map_list:
		map.free()
	mutex.unlock()

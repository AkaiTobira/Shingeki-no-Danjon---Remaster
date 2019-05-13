extends Node2D

var maps = {}


 
const ENABLE_SMALLTOWER = true
const ENABLE_TOWN       = false

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

func load_basic_maps(): new_init()


func old_init():
	var index = -1

	for location in Res.location:
		index += 1
		if location == "Locked" : 
			numbers_of_locations.append( [1, 1, 0, 0] )
			continue
		maps[location] = []
		numbers_of_locations.append( [1, 1, randi() % int( Res.location[location]["nmbSmallTowers"] ) + 1 if ENABLE_SMALLTOWER else 0, 1 if ENABLE_TOWN else 0] )

		maps[location].append( [  load("res://Maps/" + Res.location[location]["start_point"] + ".tscn").instance() ] )
		
		var main_tower_floors = []
		for i in range( Res.location[location]["nmbBossFloors"] ):
			var new_floor = load("res://Maps/RandomMap.tscn").instance()
			new_floor.generate(Res.location[location]["asset_info"], i)
			if i == 0 : new_floor.stairs_holder[0].location_change = true
			main_tower_floors.append( new_floor )
		main_tower_floors.append( load("res://Maps/" + Res.location[location]["boss_tower_top"] + ".tscn").instance() )
		maps[location].append( main_tower_floors )
	
		if ENABLE_SMALLTOWER:
			for i in numbers_of_locations[index][2]:
				var small_tower_floors = []
				for i in range( randi() % int(Res.location[location]["nmbSmallFloors"]) + 1 ):
					var new_floor = load("res://Maps/RandomMap.tscn").instance()
					new_floor.generate( Res.location[location]["asset_info"], i)
					if i == 0 : new_floor.stairs_holder[0].location_change = true
					small_tower_floors.append( new_floor )
				small_tower_floors.append( load("res://Maps/" + Res.location[location]["small_tower_top"][randi() % len(Res.location[location]["small_tower_top"])] + ".tscn").instance()  ) ##predefined top
				maps[location].append( small_tower_floors )
				
		if ENABLE_TOWN :
			##GENERATE TOWN
			pass
	print(maps)	


var new_maps = {}
var thread = Thread.new()
var mutex  = Mutex.new()

var current_location = -1
var current_floor    = 0
var current_world    = ""

var is_next_map_ready  = false
var preloaded_map_list = []
var active_map         = null

func get_new_floor(change):

	print( " NUMBER OF FLOORS FOR THIS TOWER IS : ",  new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] )

	if is_next_map_ready : print( "OK : Map ready ", len( preloaded_map_list ) )

	if not is_next_map_ready or current_floor + change ==  new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] : 
		print( "Reach the top ... or cheated" )
		return new_maps[current_world]["ST" + str(current_location)]["top"]

	current_floor += change	
	mutex.lock()
	return new_maps[current_world]["ST" + str(current_location)]["begin"] if current_floor-1 < 0 else preloaded_map_list[current_floor-1]



func get_new_map(location_id, selected_world):
	
	current_location = location_id
	current_floor    = 0
	current_world    = selected_world

	if not thread.is_active():
		thread.start( self, "generate_maps", [] )
	else: 
		force_thread_stop = true
	
	is_next_map_ready = false
	return new_maps[current_world]["ST" + str(current_location)]["begin"]


func _bg_load_done():
	print( preloaded_map_list )
	print( "THREAD : I End" )
	thread.wait_to_finish()
	if force_thread_stop : 
		is_next_map_ready = false
		print( "THREAD : I am restarting " )
		thread.start( self, "generate_maps", [] )

var force_thread_stop = false

func generate_maps( non_used ):
	
	force_thread_stop = false
	
	print( "I try to generate : ", new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] , " floors " )
	
	if new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] == 0: 
		call_deferred( "_bg_load_done" )
		return
	mutex.lock()
	preloaded_map_list = []
	mutex.unlock()
	
	for i in range( new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] ):
		if force_thread_stop : 
			print( "I AM FORCED TO END" )
			is_next_map_ready = false
			call_deferred( "_bg_load_done" )
			return
		
		var new_floor = load("res://Maps/RandomMap.tscn").instance()
		new_floor.generate( Res.location[current_world]["asset_info"], i + 1, new_maps[current_world]["ST" + str(current_location)]["seeds"][i] )
		mutex.lock()
		preloaded_map_list.append( new_floor )
		is_next_map_ready = true
		mutex.unlock()
		
	call_deferred( "_bg_load_done" )
#	print( preloaded_map_list )

func new_init():
	for location in Res.location:
		if location == "Locked" : 
			numbers_of_locations.append( [1, 1, 0, 0] )
			continue
		new_maps[location] = {}
		new_maps[location]["ST0"] = { 
					"begin" :  load("res://Maps/" + Res.location[location]["start_point"] + ".tscn").instance() ,
					"number_of_floors" : 0
					}

		new_maps[location]["ST1"] = {
			"begin" : load("res://Maps/RandomMap.tscn").instance(),
			"number_of_floors" : Res.location[location]["nmbBossFloors"],
			"seeds" : [],
			"top" : load("res://Maps/" + Res.location[location]["boss_tower_top"] + ".tscn").instance()
			}
		new_maps[location]["ST1"]["begin"].generate(Res.location[location]["asset_info"], 0)
		for sed in range( new_maps[location]["ST1"]["number_of_floors"] ): new_maps[location]["ST1"]["seeds"].append( randi() )

		for i in range( randi() % int( Res.location[location]["nmbSmallTowers"] ) + 1 ):
			var tower_name = "ST" + str(i + 2) 
			new_maps[location][tower_name] = { 
				"begin" :  load("res://Maps/RandomMap.tscn").instance() ,
				"number_of_floors" : randi() % int(Res.location[location]["nmbSmallFloors"]) + 1,
				"top"   :  load("res://Maps/" + Res.location[location]["small_tower_top"][randi() % len(Res.location[location]["small_tower_top"])] + ".tscn").instance()				
				}
			new_maps[location][tower_name]["begin"].generate(Res.location[location]["asset_info"], i)
			new_maps[location][tower_name]["begin"].stairs_holder[0].location_change = true
			new_maps[location][tower_name]["seeds"] = []
			for sed in range( new_maps[location][tower_name]["number_of_floors"] ): new_maps[location][tower_name]["seeds"].append( randi() )
		

		numbers_of_locations.append( [ 1, 1, len( new_maps[location] ) -2, 0 ] ) # 0 reserved for non_existing_town
#		print( new_maps )
#		print( maps ) 
#		print( [ 1, 1, len( new_maps[location] ) - 2, 0 ] )
#		print( numbers_of_locations[index] )

func _init(): #TO complete when time strikes
	current_world = "Mechania"
#	old_init()
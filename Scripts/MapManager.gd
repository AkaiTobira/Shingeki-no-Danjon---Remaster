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

	#print( " NUMBER OF FLOORS FOR THIS TOWER IS : ",  new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] )

	if is_next_map_ready : print( "OK : Map ready ", len( preloaded_map_list ) )

#	if change < 0: current_floor += change	

	if not is_next_map_ready and current_floor + change > len(preloaded_map_list) or current_floor + change ==  new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] : 
		#print( current_floor, change, new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] )
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
		Res.background_generation_lock = true
	
	is_next_map_ready = false
	return new_maps[current_world]["ST" + str(current_location)]["begin"]


func _bg_load_done():
	#print( preloaded_map_list )
	#print( "THREAD : I End" )
	thread.wait_to_finish()
	if Res.background_generation_lock : 
		is_next_map_ready = false
		#print( "THREAD : I am restarting " )
		thread.start( self, "generate_maps", [] )

func generate_maps( non_used ):
	
	Res.background_generation_lock = false
	
	#print( "I generate : ", new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] , " floors " )
	
	if new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] == 0: 
		call_deferred( "_bg_load_done" )
		return
	mutex.lock()
	preloaded_map_list = []
	mutex.unlock()
	
	
	
	for i in range( new_maps[current_world]["ST" + str(current_location)]["number_of_floors"] ):
		if Res.background_generation_lock : 
			#print( "I AM FORCED TO END" )
			is_next_map_ready = false
			call_deferred( "_bg_load_done" )
			return
		
		var new_floor = load("res://Maps/RandomMap.tscn").instance()
		
		#print (Res.location[current_world]["asset_info"], " ", i + 1, " ", new_maps[current_world]["ST" + str(current_location)]["seeds"] )
		
		
		if len( new_maps[current_world]["ST" + str(current_location)]["seeds"] ) < i : 
			call_deferred( "_bg_load_done" )
			return
		
		new_floor.generate( Res.location[current_world]["asset_info"], i + 1, new_maps[current_world]["ST" + str(current_location)]["seeds"][i] )
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
#	#print( preloaded_map_list )

func new_init():
	
	maps.clear()
	numbers_of_locations = []
	
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
		new_maps[location]["ST1"]["begin"].stairs_holder[0].location_change = true
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
		
		Res.background_generation_lock = false
		numbers_of_locations.append( [ 1, 1, len( new_maps[location] ) -2, 0 ] ) # 0 reserved for non_existing_town
#		#print( new_maps )
#		#print( maps ) 
#		#print( [ 1, 1, len( new_maps[location] ) - 2, 0 ] )
#		#print( numbers_of_locations )

func _init(): #TO complete when time strikes
	current_world = "Mechania"

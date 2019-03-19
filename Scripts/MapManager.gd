extends Node2D

var maps = {}

var current_location = -1
var current_floor    = 0
var current_world    = ""

const ENABLE_SMALLTOWER = false
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
	
func get_new_floor(change):
	current_floor += change
	return maps[current_world][current_location][current_floor]

func get_new_map(location_id, selected_world):
	current_location = location_id
	current_floor    = 0
	current_world    = selected_world
	return maps[current_world][current_location][0]
	
func _init(): #TO complete when time strikes
	current_world = "Mechania"

	for location in Res.location:
		if location == "Locked" : 
			numbers_of_locations.append( [1, 1, 0, 0] )
			continue
		maps[location] = []
		numbers_of_locations.append( [1, 1, randi() % int( Res.location[location]["nmbSmallTowers"] - 5 ) + 5 if ENABLE_SMALLTOWER else 0, 1 if ENABLE_TOWN else 0] )

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
			for i in numbers_of_locations[2]:
				var small_tower_floors = []
				for i in range( Res.location[location]["nmbSmallFloors"] - randi()%4 ):
					var new_floor = load("res://Maps/RandomMap.tscn").instance()
					new_floor.generate( Res.location[location]["asset_info"], i)
					if i == 0 : new_floor.stairs_holder[0].location_change = true
					small_tower_floors.append( new_floor )
				#small_tower_floors.append( load("res://Maps/" + Res.location[location]["boss_tower_top"] + ".tscn").instance()  ) ##predefined top
		if ENABLE_TOWN :
			##GENERATE TOWN
			pass
				
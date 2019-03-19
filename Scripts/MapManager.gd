extends Node2D

var maps = []

var current_location = -1
var current_floor    = 0

#TODO change in load from json
func get_location_numbers() :
	return [ [1,1,0,0],[2,5,1,1] ]
	
func get_location_types() :
	return [ { 0 : "Start Point", 1: "Main Tower", 2 : "Supply Tower", 3 : "Settlement" }, { 0 : "Start Point", 1: "Main Tower", 2 : "Supply Tower", 3 : "Settlement" }]

func get_locations_names():
	return [ { 0 : ["Jigsaw Room"], 1 : ["Mechanic Tower"], 2 : ["Test Name1","Test Name2","Test Name3"], 3 :["Forgoten Mine Town"]}, { 0 : ["Jigsaw Room"], 1 : ["Mechanic Tower"], 2 : ["Test Name1","Test Name2","Test Name3"], 3 :["Forgoten Mine Town"] } ] 

func get_loations_descriptions():
	return [ { 0 : ["test:jigsaw"], 1 : ["Test:Mechanik"], 2 : [ "Test:Tower"], 3 : [ "Test:Settlement" ] }, { 0 : ["test:jigsaw"], 1 : ["Test:Mechanik"], 2 : [ "Test:Tower"], 3 : [ "Test:Settlement" ] }]

func get_new_floor(change):
	current_floor += change
	return maps[current_location][current_floor]

func get_new_map(location_id):
	current_location = location_id
	current_floor    = 0
	return maps[current_location][0]
	
func _init(): #TODO ... still
	var new_map = load("res://Maps/JigsawRoom.tscn").instance()
	maps.append( [ new_map ] )
	
	var new_map1 = load("res://Maps/RandomMap.tscn").instance()
	new_map1.generate(0)
	new_map1.stairs_holder[0].location_change = true

	var new_map2 = load("res://Maps/RandomMap.tscn").instance()
	new_map2.generate(1)

	var new_map3 = load("res://Maps/RandomMap.tscn").instance()
	new_map3.generate(2)
	
	var new_map4 = load("res://Maps/BossRoom.tscn").instance()	
	maps.append( [ new_map1, new_map2, new_map3, new_map4 ] )
	

extends Node
onready var dungeon = $"../Segments"

var NewToTest = "Uganda"#"Enemies/Puncher"#"Enemies/Mechanic" #jak zrobisz tak to masz fajny null ##DEBUG

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const DOFFSET    = [Vector2(1, 0), Vector2(0, 1)]
const OPPOSITE   = [2, 3, 0, 1]

const MIN_MAP_SIZE = 25

var disabled = []#["Puncher"] ##DEBUG

var width = 100
var height = 100
var dungeon_name 

var empty_spots   = []

var segments      = []
var map           = []
var floor_space   = {}
var wall_space    = []
var current_floor = -1

var navigation = AStar.new()

var aStar_points = []
#var aStar = AStar.new()

var file_json
var splitted_obj

var size_of_segments = [Vector2(999999999,999999999), Vector2(0,0)]

var l_generator = preload("res://Scripts/Lab_Generator.gd").new()

var graph = {}

func generate(level_name,w, h, aStar, current_floor1):
	width = w
	height = h
	map.resize(width * height)
	dungeon_name = level_name
	var end = false

	current_floor = current_floor1


	l_generator.generate()

	while( not l_generator.is_correct()):
		l_generator.generate()
		
	graph = l_generator.graph

	for segment in graph:
		if Res.background_generation_lock: 
			print( "Prestop" )
			return
		create_segment(segment, graph[segment]["name"], graph[segment]["position"])

	
	for i in range(len(aStar_points)):
		aStar.add_point(i,Vector3(aStar_points[i].x, aStar_points[i].y, 0 ))

	var corresponations = [ Vector2( 80,   0), Vector2( -80,   0), Vector2(   0, 80), Vector2(   0, -80),
					  	    Vector2( 80,  80), Vector2(  80, -80), Vector2( -80, 80), Vector2( -80, -80) ]

	for i in range(len(aStar_points)):
		var id_1 = aStar.get_closest_point( Vector3(aStar_points[i].x, aStar_points[i].y, 0 ))
		for direction in corresponations:
			var id_2 = aStar.get_closest_point( Vector3(aStar_points[i].x + direction.x, aStar_points[i].y + direction.y, 0 ))
			if id_1 == id_2: continue
			aStar.connect_points(id_1, id_2, true)

	var tileset = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]

	create_stairs()

	var tileset_dict = {}

	var ts = load("res://Resources/Tilesets/" +Res.dungeons[dungeon_name]["tileset"] + ".tres")

	for i in ts.get_tiles_ids():
		tileset_dict[ts.tile_get_name(i)] = i

	for index_g in graph:

		var bottom = graph[index_g]["segment"].find_node("BottomTiles", true, false)
		
		if bottom != null :
			for cell in bottom.get_used_cells():
				if bottom.get_cellv(cell) == tileset_dict["FloorMarker"]:
					var new_tile = Res.weighted_random(tileset.floor_ids_with_weights)
					var tile = tileset.tile_to_floor[new_tile]
					var tile_size   = tileset.tile_size[new_tile]

					var space = true
					for x in range( tile_size[0] ):
						for y in range( tile_size[1] ):
							if bottom.get_cellv(cell + Vector2( x, y )) != tileset_dict["FloorMarker"]:
								space = false
								break

					if !space: 
						bottom.set_cellv(cell, tileset_dict["Floor1"])
						continue

					var couter = 0
					for x in range( tile_size[0] ):
						for y in range( tile_size[1] ):
							var flip = [false, false, false]
							if tile.has("can_flip"): flip = [randi()%2 == 0, randi()%2 == 0, randi()%2 == 0]
							bottom.set_cellv(cell + Vector2(y, x), tileset_dict["Floor" + str(new_tile+couter) ], flip[0], flip[1], flip[2])
							couter+=1

				if bottom.get_cellv(cell) == tileset_dict["WallMarkerUp"]:
					var new_tile = Res.weighted_random(tileset.wall_ids_with_weights)
					var tile_colums = tileset.tile_colums[new_tile]
					var space = true
					for t in range(tile_colums):
						if bottom.get_cellv(cell + Vector2(t , 0)) != tileset_dict["WallMarkerUp"] or bottom.get_cellv(cell + Vector2(t , 1)) != tileset_dict["WallMarkerDown"]:
							space = false
							break

					if !space: 
						bottom.set_cellv(cell + Vector2(0, 0 ), tileset_dict["Wall1Up"  ])
						bottom.set_cellv(cell + Vector2(0, 1 ), tileset_dict["Wall1Down"])
						continue
					for t in range(tile_colums):
						bottom.set_cellv(cell + Vector2(t, 0 ), tileset_dict["Wall" + str(new_tile+t) + "Up"  ])
						bottom.set_cellv(cell + Vector2(t, 1 ), tileset_dict["Wall" + str(new_tile+t) + "Down"])

#	print( "G: Whole takes : ", OS.get_ticks_msec() - rest1 )

	get_parent().segments_holder = graph

	queue_free()

func create_stairs():
	var tileset = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]
	#var segments = se#dungeon.get_children()
	
	var segment_enter  = graph[ randi()%len(graph) ]["segment"]
#	get_parent().segments_holder[randi()%len(segments)]	
	var stairs_pos     = segment_enter.get_stairs_position() 
	while(!segment_enter.can_have_stairs or !len(stairs_pos) ):
		segment_enter  = graph[ randi()%len(graph) ]["segment"]
		stairs_pos = segment_enter.get_stairs_position() 


	var stairs_position = stairs_pos[randi()%len(stairs_pos)]*80

	var sprite = load("res://Sprites/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".png")

	var stairs = Res.create_instance("Objects/Stairs")
	stairs.texture = sprite
	stairs.position = stairs_position + Vector2(80, 80) + segment_enter.position
	stairs.set_stairs("up" if Res.dungeons[dungeon_name]["progress"] != get_parent().from else "down", tileset)
	
	get_parent().stairs_holder.append(stairs)

	var segment_exit  = graph[ randi()%len(graph) ]["segment"]
	stairs_pos = segment_exit.get_stairs_position() 
	while(!segment_exit.can_have_stairs 
	   or !len(stairs_pos) 
	   or segment_exit == segment_enter 
	   or segment_enter.position.distance_to(segment_exit.position) < 4000
	):
		segment_exit  = graph[ randi()%len(graph) ]["segment"]
		stairs_pos    = segment_exit.get_stairs_position() 

	stairs_position = stairs_pos[randi()%len(stairs_pos)]*80

	stairs = Res.create_instance("Objects/Stairs")
	stairs.texture = sprite
	stairs.position = stairs_position + Vector2(80, 80) + segment_exit.position
	stairs.set_stairs("up" if Res.dungeons[dungeon_name]["progress"] == get_parent().from else "down", tileset)
	get_parent().stairs_holder.append(stairs)

func place_for_test(what):
	if NewToTest == "": return
	
	var ug_inst = what.instance()
	ug_inst.position = Res.game.player.position + Vector2(200,200)
	dungeon.get_parent().add_child(ug_inst)


func create_segment(index, segment, position):
	
	var pos = Vector2( position[0], position[1] )
	
#	var rest1 = OS.get_ticks_msec() 
#	var rest  = OS.get_ticks_msec() 
	
	var seg    = Res.segment_nodes[segment].instance()
	var bottom = seg.get_node("BottomTiles")
	var top    = seg.get_node("TopTiles")
	
#	print( "SG: Initiation segment takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec() 
	
	bottom.tile_set = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.tile_set    = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.set_collision_layer_bit(3, true)

	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)

	var wallTileId  = bottom.tile_set.find_tile_by_name("WallMarkerUp") 
	var floorTileID = bottom.tile_set.find_tile_by_name("FloorMarker")

#	print( "SG: Tilesets takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec() 
	graph[index]["segment"] = seg
#	get_parent().segments_holder.append(seg)
#	print( "ApendTOHolder takes : ", OS.get_ticks_msec() - rest )
	
#	rest  = OS.get_ticks_msec() 
	if splitted_obj == null:
		seg.generate(Res.dungeons["Mechanic"], "Mechanic", splitted_obj, current_floor, Res.enemies)
		splitted_obj = seg.get_splitted_elements()
	else:
		seg.generate(Res.dungeons["Mechanic"], "Mechanic", splitted_obj, current_floor, Res.enemies)
		
#	print( "SG: Call Generation takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec()
	
	var segment_astar_points = seg.get_Astar_positions()
	for point in segment_astar_points:
		aStar_points.append(point+seg.position)
		
#	print( "SG: AstarSegment takes : ", OS.get_ticks_msec() - rest )
	
#	rest  = OS.get_ticks_msec() 
	if seg.has_node("Objects"):
		for i in range(seg.get_node("Objects").get_child_count()):
			var node = seg.get_node("Objects").get_child(0)
			seg.get_node("Objects").remove_child(node) ##może nie działać dla kilku
			get_parent().objects_holder.append([ node , node.position + seg.position ])
	
#	print( "SG: AppendingObjects takes : ", OS.get_ticks_msec() - rest )
#	print( "SG: Creating one segment takes : ", OS.get_ticks_msec() - rest1 )
			
	return seg

func reset():
	empty_spots.clear()
	segments.clear()
	map.clear()
	floor_space.clear()
	wall_space.clear()
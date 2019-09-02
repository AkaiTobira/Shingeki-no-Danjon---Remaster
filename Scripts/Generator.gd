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

var height = 100
var dungeon_name 

var empty_spots   = []

var segments      = []
var floor_space   = {}
var wall_space    = []
var current_floor = -1

var navigation_points = []


var file_json
var splitted_obj

var size_of_segments = [Vector2(999999999,999999999), Vector2(0,0)]

var l_generator = preload("res://Scripts/Lab_Generator.gd").new()

var graph = {}

func generate(level_name, navigation, current_floor1):
	#print( "Start")
	#print( "G: start generate " ) 
	var time_start = OS.get_ticks_msec()

	dungeon_name = level_name
	var end = false

	current_floor = current_floor1
	l_generator.generate()

	while( not l_generator.is_correct()): l_generator.generate()
		
	graph = l_generator.graph
	for segment in graph:
		if Res.background_generation_lock: 
			#print( "Prestop" )
			return
		create_segment(segment, graph[segment]["name"], graph[segment]["position"])

	#time_start = OS.get_ticks_msec()
	for i in range(len(navigation_points)):
		navigation.add_point(i,Vector3(navigation_points[i].x, navigation_points[i].y, 0 ))

	var corresponations = [ Vector2( 80,   0), Vector2( -80,   0), Vector2(   0, 80), Vector2(   0, -80),
					  	    Vector2( 80,  80), Vector2(  80, -80), Vector2( -80, 80), Vector2( -80, -80) ]

	for i in range(len(navigation_points)):
		var id_1 = navigation.get_closest_point( Vector3(navigation_points[i].x, navigation_points[i].y, 0 ))
		for direction in corresponations:
			var id_2 = navigation.get_closest_point( Vector3(navigation_points[i].x + direction.x, navigation_points[i].y + direction.y, 0 ))
			if id_1 == id_2: continue
			navigation.connect_points(id_1, id_2, true)

	create_stairs()
	var wallAndFloorReplacer = load( "res://Scripts/SegmentWallAndFloorReplacer.gd" ).new()
	get_parent().segments_holder = wallAndFloorReplacer.replace_wall_and_floors(graph, dungeon_name)
	#print( "G: generation takes : ", (OS.get_ticks_msec() - time_start)  ) 

	call_deferred("queue_free")

func create_stairs():
	var tileset = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]
	#var segments = se#dungeon.get_children()
	
	var segment_enter  = graph[ randi()%len(graph) ]["segment"]
#	get_parent().segments_holder[randi()%len(segments)]	
	var stairs_pos     = segment_enter.get_stairs_position() 

	while(!segment_enter.can_have_stairs or !len(stairs_pos) ):
		segment_enter  = graph[ randi()%len(graph) ]["segment"]
		stairs_pos     = segment_enter.get_stairs_position() 

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
	   or segment_enter.position.distance_to(segment_exit.position) < 3500
	):
		print( segment_exit.can_have_stairs , len(stairs_pos) ,segment_exit == segment_enter , segment_enter.position.distance_to(segment_exit.position) < 3500)
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
	
#	#print( "SG: Initiation segment takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec() 
	
	bottom.tile_set = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.tile_set    = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.set_collision_layer_bit(3, true)

	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)

	var wallTileId  = bottom.tile_set.find_tile_by_name("WallMarkerUp") 
	var floorTileID = bottom.tile_set.find_tile_by_name("FloorMarker")

#	#print( "SG: Tilesets takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec() 

	graph[index]["segment"] = seg
	seg.set_shape( Res.cache_segment_structure(segment) )
#	get_parent().segments_holder.append(seg)
#	#print( "ApendTOHolder takes : ", OS.get_ticks_msec() - rest )
	
#	rest  = OS.get_ticks_msec() 
	seg.generate( dungeon_name,  current_floor)
#	#print( "SG: Call Generation takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec()
	
	var segment_navigation_points = seg.get_navigation_points()
	for point in segment_navigation_points:
		navigation_points.append(point+seg.position)
		
#	#print( "SG: AstarSegment takes : ", OS.get_ticks_msec() - rest )
#	rest  = OS.get_ticks_msec() 
	if seg.has_node("Objects"):
		for i in range(seg.get_node("Objects").get_child_count()):
			var node = seg.get_node("Objects").get_child(0)
			seg.get_node("Objects").remove_child(node) ##może nie działać dla kilku
			get_parent().objects_holder.append([ node , node.position + seg.position ])
	
	for obj in seg.enviroment_list:
		obj["pos"] +=  seg.position
		get_parent().enviroment_object_list.append(obj)

#	#print( "SG: AppendingObjects takes : ", OS.get_ticks_msec() - rest )
#	#print( "SG: Creating one segment takes : ", OS.get_ticks_msec() - rest1 )
			
	return seg
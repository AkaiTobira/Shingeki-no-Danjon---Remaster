extends Node2D

export(bool) var can_have_stairs

var used_rect
var numration_counter = 0
var monster_counter   = 0

const DEBUG = false

var floor_number    = "-1"
var dungeon_name    = ""

var importantTileId = {}

var emptySpace    = {}


enum Objects{
	CONST,
	DESTROYABLE,
	CONTAINERS,
	TRAPS,
	ENEMIES,
	}

var shape         = []
var structure     = []
var Obj_to_Append = []
var enemies       = []
var Astar_points  = []


var list_of_obj = []
var object_list1 = []

var obj_splitted_by_wall_dependency = [ 
	[ [],[],[],[] ], 
	[ [],[],[],[] ], 
	[ [],[],[],[] ], 
	[ [],[],[],[] ],
	[ [],[],[],[] ]
	] # five diffrent types of obj

var Enters    = []
var AccesNeed = []

enum Wall_Orientations{
	Left,
	Right,
	Up,
	Down,
	Free
}

var debugCounter = 0

enum TileState{
	noTile,
	free,
	wallLeft,
	wallRight,
	wallUp,
	wallDown,
	wallLeftUp,
	wallLeftDown,
	wallRightUp,
	wallRightDown,
	blockedTile,
	exitTile,
	destroyableObject,
	containerObject,
	constObject
}

const SIDES = [
	[ TileState.wallLeft , TileState.wallLeftUp  , TileState.wallLeftDown  ],
	[ TileState.wallRight, TileState.wallRightUp , TileState.wallRightDown ],
	[ TileState.wallUp   , TileState.wallLeftUp  , TileState.wallRightUp   ],
	[ TileState.wallDown , TileState.wallLeftDown, TileState.wallRightDown ],
	[ TileState.free ]
	]

func get_size():
	return used_rect.end

func get_important_tile_ids():
	importantTileId["E"] = $BottomTiles.tile_set.find_tile_by_name("FloorE")
	importantTileId["F"] = $BottomTiles.tile_set.find_tile_by_name("FloorF")
	importantTileId["C"] = $BottomTiles.tile_set.find_tile_by_name("FloorC")
	importantTileId["B"] = $BottomTiles.tile_set.find_tile_by_name("FloorS")

var instances = {}
func cache_local_instance(instance_name, instance_type):
	if  not instance_name in instances.keys() : 
		instances[instance_name] =  load(get_path_toObj(instance_type) + instance_name +".tscn").instance()
	return instances[instance_name]

func initialize_tileset_info():
	used_rect = $BottomTiles.get_used_rect()

	$BottomTiles.cell_y_sort = true
	$TopTiles.cell_y_sort    = true	

	create_Objects_node()
	get_important_tile_ids()
	reset()

func set_shape(shape):
    structure = shape[0]
    Enters    = shape[1]

func split_enviroment_objects(  ):
		split_enviroments_by_wallDependency( Res.dungeons[dungeon_name]["environment_objects"], Objects.CONST)
		split_enviroments_by_wallDependency( Res.dungeons[dungeon_name]["breakable_objects"  ], Objects.DESTROYABLE)
		split_enviroments_by_wallDependency( Res.dungeons[dungeon_name]["containers_objects" ], Objects.CONTAINERS)
		split_enviroments_by_wallDependency( Res.dungeons[dungeon_name]["trap_objects"       ], Objects.TRAPS)
    
func initialize_generation( dungeon, current_floor ):
	floor_number = current_floor
	dungeon_name = dungeon
	
	if Res.dungeons[dungeon_name]["floor_Objects"] == []: split_enviroment_objects(  )
	initialize_tileset_info()
	convert_struct_to_set()

func convert_struct_to_set():
	emptySpace    = {}

	var multiplication = [ 
		[ Wall_Orientations.Left,  Wall_Orientations.Left,  Wall_Orientations.Left  ],
		[ Wall_Orientations.Right, Wall_Orientations.Right, Wall_Orientations.Right ],
		[ Wall_Orientations.Up,    Wall_Orientations.Up,    Wall_Orientations.Up,   ],
		[ Wall_Orientations.Down,  Wall_Orientations.Down,  Wall_Orientations.Down  ]
	]

	for i in range( len(structure) ):
		for j in range( len(structure[i])):
			var pos = Vector2(i,j)
			if structure[i][j] == TileState.free:          emptySpace[str(pos)] = [Wall_Orientations.Free]
			if structure[i][j] == TileState.wallLeft:      emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[0]
			if structure[i][j] == TileState.wallRight:     emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[1]
			if structure[i][j] == TileState.wallUp:        emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[2]
			if structure[i][j] == TileState.wallDown:      emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[3]
			if structure[i][j] == TileState.wallLeftUp:    emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[0] + multiplication[2]
			if structure[i][j] == TileState.wallLeftDown:  emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[0] + multiplication[3]
			if structure[i][j] == TileState.wallRightUp:   emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[1] + multiplication[2]
			if structure[i][j] == TileState.wallRightDown: emptySpace[str(pos)] = [Wall_Orientations.Free] + multiplication[1] + multiplication[3]
					
func object_to_prob(style):
	match(style):
		Objects.CONST:       return Res.dungeons[dungeon_name]["probs"]["const"]
		Objects.TRAPS:       return Res.dungeons[dungeon_name]["probs"]["traps"]
		Objects.DESTROYABLE: return Res.dungeons[dungeon_name]["probs"]["breakable"]
		Objects.CONTAINERS:  return Res.dungeons[dungeon_name]["probs"]["container"]
		Objects.ENEMIES:     return Res.dungeons[dungeon_name]["probs"]["enemies"]

func generate_objects():
	var styles = [ Objects.DESTROYABLE, Objects.CONST, Objects.CONTAINERS, Objects.TRAPS ]#Objects.TRAPS, Objects.CONST, Objects.DESTROYABLE,  ]
	for style in styles:
		for position in emptySpace.keys():
			if( randi()%1000 > object_to_prob(style) ) : continue
			var coord = position.replace('(', '').replace(')','').split(",")
			if not emptySpace.has( position ) : continue
			var orientation = emptySpace[position][ randi()%len(emptySpace[position]) ]
			put_wall_enviroment (int(coord[0]), int(coord[1]), object_to_prob(style), orientation, style)

func generate_enemies( ):
	var enemies = Res.dungeons[dungeon_name]["floor"][str(floor_number)]
	for position in emptySpace.keys():
		if( randi()%1000 > object_to_prob(Objects.ENEMIES) ) : continue
		var coord = position.replace('(', '').replace(')','').split(",")
		var enemy = enemies[randi()%len(enemies)]
		var obj_position = Vector2((int(coord[0])*80)+40,(int(coord[1])*80)+40)
		list_of_obj.append({ "type": "Enemy", "name":enemy, "pos":obj_position, "state":"Alive" })

func put_wall_enviroment(i,j, prob, orientation, style ):
	var object_list = Res.dungeons[dungeon_name]["floor_Objects"][orientation][style]
	if len(object_list) == 0: return false

	var object_name = object_list[randi()%len(object_list)]
	var instance = cache_local_instance(object_name, style )
	var obj_size = instance.size
	
	if orientation == Wall_Orientations.Right: i = i + 1 - obj_size.x
	if orientation == Wall_Orientations.Up   : j = j + 1 - obj_size.y
	
	for x in range( obj_size.x ):
		for y in range( obj_size.y ):
			var pos = str(Vector2( i + x, j + y ))
			if not emptySpace.has( pos ): return false
			match( orientation ):
				Wall_Orientations.Right:
					if x == obj_size.x-1 and not orientation in emptySpace[pos]: return 
					if instance.need_second_wall:
						if x == 0 and not Wall_Orientations.Left in emptySpace[pos]: return 
				Wall_Orientations.Left:
					if x == 0 and not orientation in emptySpace[pos]: return 
					if instance.need_second_wall:
						if x == obj_size.x-1 and not Wall_Orientations.Right in emptySpace[pos]: return 
				Wall_Orientations.Up:
					if y == obj_size.y-1 and not orientation in emptySpace[pos]: return 
					if instance.need_second_wall:
						if y == 0 and not Wall_Orientations.Down in emptySpace[pos]: return 
				Wall_Orientations.Down:
					if y == 0 and not orientation in emptySpace[pos]: return 
					if instance.need_second_wall:
						if y == obj_size.y-1 and not Wall_Orientations.Up in emptySpace[pos]: return 	

	reserve_tile_under_obj( obj_size, i, j , style)
	
	var obj_position = Vector2(i*80,j*80) + (instance.size*(40-1))
	
	match(style):
		Objects.TRAPS: 
			object_list1.append({ "type": "Trap", "name": object_name, "pos":obj_position, "flip":Wall_Orientations.Right != orientation, "local_pos":Vector2(i,j), "closest_empty_space":[0,0,0,0] })
			instance._change_sprite(Res.dungeons[dungeon_name]["tileset"])
		Objects.DESTROYABLE:
			object_list1.append({ "type": "Box", "name": object_name, "pos":obj_position, "state":"Alive" })
		Objects.CONTAINERS:
			AccesNeed.append([i,j])
			object_list1.append({ "type": "Chest", "name": object_name, "pos":obj_position, "state":"Alive" })	
		Objects.CONST:
			object_list1.append({ "type": "Decoration", "name": object_name, "pos":obj_position, "flip":Wall_Orientations.Right != orientation })


func generate(dungeon, current_level = 0):

	#var cout  = 0
	initialize_generation(dungeon, current_level)
	#var time_start = OS.get_ticks_msec()
	generate_objects()
	#print( "ISG: generating takes : ", (OS.get_ticks_msec() - time_start) , " " , cout ) 
	#time_start = OS.get_ticks_msec()
	while !is_correct():
#		cout += 1
		reset()
		generate_objects()
	#print( "ISG: generate correct takes : ", (OS.get_ticks_msec() - time_start) , " " , cout ) 
	#var time_start = OS.get_ticks_msec()
	generate_enemies()
	finish_trap_generation()
	list_of_obj += object_list1
	#print( "ISG: generate enemies takes : ", (OS.get_ticks_msec() - time_start)) 
	#time_start = OS.get_ticks_msec()
	#cout = 0
	change_tileset()
	#print( "ISG: loading tileset takes : ", (OS.get_ticks_msec() - time_start)) 
	#time_start = OS.get_ticks_msec()
	translate_const_obj()
	#print( "ISG: translate consts takes : ", (OS.get_ticks_msec() - time_start)) 


func finish_trap_generation():
	for obj in object_list1:
		var instance = cache_local_instance(obj.name, obj.type)
		if not instance.need_more_space: continue
		var pos = obj.local_pos
		for i in range( 1, 6 ): 
			if is_empty(pos.x + i,pos.y)  : obj.closest_empty_space[0]+=1
			else: break
		for i in range( 1, 6 ): 
			if is_empty(pos.x - i,pos.y)  : obj.closest_empty_space[1]+=1
			else: break
		for i in range( 1, 6 ): 
			if is_empty(pos.x, pos.y + i) : obj.closest_empty_space[2]+=1
			else: break
		for i in range( 1, 6 ): 
			if is_empty(pos.x, pos.y - i) : obj.closest_empty_space[3]+=1
			else: break
		obj.erase("local_pos")

func is_empty(i,j):
	return 	shape[i][j] >= TileState.free and shape[i][j] <= TileState.exitTile

func translate_const_obj():
	
	for i in Obj_to_Append:
		get_node("Objects").add_child(i)
	
	if has_node("ConstObjects"):
		for i in $ConstObjects.get_children():
			var node = i
			get_node("ConstObjects").remove_child(node)
			if i.has_method( "_change_sprite" ): i._change_sprite(Res.dungeons[dungeon_name]["tileset"])
			get_node("Objects").add_child(i)

func reset():
	debugCounter = 0
	numration_counter +=1;
	Obj_to_Append.clear()
	AccesNeed.clear()

	shape.clear()
	for i in structure:
		var cell = []
		for j in i:
			cell.append(j)
		shape.append(cell)
	
	object_list1.clear()
	convert_struct_to_set()

func get_path_toObj(objType):
	match(objType):
		Objects.CONST:
			return "res://Nodes/Environment/"
		Objects.DESTROYABLE:
			return "res://Nodes/Objects/"
		Objects.CONTAINERS:
			return "res://Nodes/Objects/"
		Objects.ENEMIES:
			return "res://Nodes/Enemies/"
		Objects.TRAPS:
			return "res://Nodes/Objects/"

func split_enviroments_by_wallDependency(enviroments, objType):

	for i in enviroments:
		var instance = Res.get_scene(get_path_toObj(objType) + i +".tscn")
		if instance == null  : 
			print( i, " Error in name in json : Check  =  " + get_path_toObj(objType) ) 
			continue
		instance = instance.instance()
		if instance.placement   == instance.PLACEMENT.LEFT_OR_RIGHT_WALL:
				obj_splitted_by_wall_dependency[Wall_Orientations.Left  ][objType].append(i)
				obj_splitted_by_wall_dependency[Wall_Orientations.Right ][objType].append(i)
		elif instance.placement == instance.PLACEMENT.UP_OR_DOWN_WALL:
				obj_splitted_by_wall_dependency[Wall_Orientations.Up    ][objType].append(i)
				obj_splitted_by_wall_dependency[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.PLACEMENT.DOWN_WALL:
				obj_splitted_by_wall_dependency[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.PLACEMENT.UP_WALL:
				obj_splitted_by_wall_dependency[Wall_Orientations.Up    ][objType].append(i)
		elif instance.placement == instance.PLACEMENT.EVERY_WALL:
				obj_splitted_by_wall_dependency[Wall_Orientations.Left  ][objType].append(i)
				obj_splitted_by_wall_dependency[Wall_Orientations.Right ][objType].append(i)
				obj_splitted_by_wall_dependency[Wall_Orientations.Up    ][objType].append(i)
				obj_splitted_by_wall_dependency[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.PLACEMENT.WALL_FREE:
				obj_splitted_by_wall_dependency[Wall_Orientations.Free  ][objType].append(i)
                
	Res.dungeons[dungeon_name]["floor_Objects"] = obj_splitted_by_wall_dependency

func get_splitted_elements():
	return Res.dungeons[dungeon_name]["floor_Objects"]

func create_Objects_node():
	if not has_node("Objects"):
		var Objects = Node2D.new()
		Objects.set_name("Objects")
		add_child(Objects) 

func print_segment_structure():
	for i in range(used_rect.end.x+2):
		print(shape[i])
	print("\n")

func get_Astar_positions():

	var special_points = []
		
	for i in range(used_rect.end.x+2):
		for j in range(used_rect.end.y+2):
			if shape[i][j] >= TileState.free and shape[i][j] <= TileState.containerObject:
				special_points.append(Vector2(40 + 80*i, 40 +80*j))

	return special_points

func find_every_stair_possible_wall():
	
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")

	var temp = []
	
	for i in range(used_rect.end.x+1):
		for j in range(used_rect.end.y+1):
			if $BottomTiles.get_cell(i,j) == id and $BottomTiles.get_cell(i+1,j) == id:
				if shape[i][j+2] >= TileState.free and shape[i][j+2] < TileState.destroyableObject and shape[i+1][j+2] >= TileState.free and shape[i+1][j+2] < TileState.destroyableObject:
					temp.append(Vector2(i,j))
	
	return temp
					

func get_stairs_position():
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")

	var rico = []

	for i in range(used_rect.end.y):
		if $BottomTiles.get_cell(0,i) == id and shape[0][i+2] >= TileState.free and shape[0][i+2] < TileState.destroyableObject  :
			rico.append(Vector2(-1,i))
	return rico + find_every_stair_possible_wall()


func convert_wall_pattern_to_new_tileset( wallMarkersIDs ):
	for i in range(used_rect.end.x+2):
		for j in range( used_rect.end.y+1):
			if $BottomTiles.get_cell(i,j+1) == wallMarkersIDs["OldLowerPartOfWall"] and $BottomTiles.get_cell(i,j) == wallMarkersIDs["OldUpperPartOfWall"]:
				$BottomTiles.set_cell(i,j  ,wallMarkersIDs["NewUpperPartOfWall"]) 
				$BottomTiles.set_cell(i,j+1,wallMarkersIDs["NewUpperPartOfWall"]) 

func convert_floor_pattern_to_new_tileset(floorId):
	for i in range(used_rect.end.x+2):
		for j in range(used_rect.end.y+1):
			if $BottomTiles.get_cell(i,j) in importantTileId.values():
				$BottomTiles.set_cell(i,j, floorId)

func change_tileset():
	var newTileset = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	var floorId    = newTileset.find_tile_by_name("FloorMarker")

	var wallMarkersIDs = {}
	wallMarkersIDs["OldUpperPartOfWall"] = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")
	wallMarkersIDs["NewUpperPartOfWall"] = newTileset.find_tile_by_name("WallMarkerUp")
	wallMarkersIDs["OldLowerPartOfWall"] = $BottomTiles.tile_set.find_tile_by_name("WallMarkerDown")
	wallMarkersIDs["NewLowerPartOfWall"] = newTileset.find_tile_by_name("WallMarkerDown")

	$BottomTiles.tile_set = newTileset
	$TopTiles.tile_set    = newTileset
	if has_node("SecretTiles"):
		$SecretTiles.tile_set    =  newTileset
		
	convert_wall_pattern_to_new_tileset(wallMarkersIDs)
	convert_floor_pattern_to_new_tileset(floorId)
    
	if has_node("Walls"):
		for i in $Walls.get_children():
			i.get_node("Sprite").texture =  load("res://Sprites/Tilesets/" +  Res.dungeons[dungeon_name]["tileset"] + ".png")
			i.get_node("Sprite2").texture = load("res://Sprites/Tilesets/" +  Res.dungeons[dungeon_name]["tileset"] + ".png")
	
func reserve_tile_under_obj( obj_size, i, j, style = Objects.CONST ):
	for x in range(obj_size.x):
		for y in range(obj_size.y):
			if style == Objects.CONST:
				shape[i+x][j+y] = TileState.constObject
			elif style == Objects.CONTAINERS:
				shape[i+x][j+y] = TileState.containerObject
			elif style == Objects.DESTROYABLE:
				shape[i+x][j+y] = TileState.destroyableObject
			elif style == Objects.TRAPS:
				shape[i+x][j+y] = TileState.destroyableObject
				
			var pos = str( Vector2(i+x,j+y) )
			if emptySpace.has(pos) : emptySpace.erase(pos)

func is_valid(array):
	if array[0] <= used_rect.position.x-1 or array[0] >= used_rect.end.x+1 : return false
	if array[1] <= used_rect.position.y-1 or array[1] >= used_rect.end.y+1 : return false
	if shape[array[0]][array[1]] < TileState.free or shape[array[0]][array[1]] >= TileState.constObject : return false
	return true   

func is_correct():
	var enters_number = 0
	var acces_need    = 0
	var directions    = [ [0,1], [0,-1], [1,0], [-1,0] ]
	var queue         = [ Enters[0] ]
	var checked       = []

	while( len(queue) > 0 ):
		var position = queue.pop_front()
		if position in Enters: enters_number += 1
		if position in AccesNeed: acces_need += 1
		if enters_number == len(Enters) and acces_need == len(AccesNeed) : return true

		for direction in directions:
			var new1 = [position[0] + direction[0], position[1] + direction[1]]
			if not new1 in checked and not new1 in queue and is_valid(new1): queue.push_back(new1)
		checked.append(position)
	return false

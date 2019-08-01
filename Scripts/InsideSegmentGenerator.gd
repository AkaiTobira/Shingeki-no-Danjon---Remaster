extends Node2D

export(bool) var can_have_stairs

var used_rect
var numration_counter = 0
var monster_counter   = 0

const DEBUG = false

var flooor 
var items_in_breakable
var items_in_containers
var tilesetName

var tile_exit_id 
var tile_free_id
var tile_const_id 
var tile_blocked_id 

enum Objects{
	CONST
	DESTROYABLE
	CONTAINERS
	TRAPS
	ENEMIES
	}

var shape       = []
var structure = []
var Obj_to_Append = []
var enemies   = []

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

var Astar_points = []

func get_size():
	return used_rect.end


func get_tile_ids_from_TileSet():
	tile_exit_id    = $BottomTiles.tile_set.find_tile_by_name("FloorE")
	tile_free_id    = $BottomTiles.tile_set.find_tile_by_name("FloorF")
	tile_const_id   = $BottomTiles.tile_set.find_tile_by_name("FloorC")
	tile_blocked_id = $BottomTiles.tile_set.find_tile_by_name("FloorS")

func initialize():
	used_rect = $BottomTiles.get_used_rect()

	$BottomTiles.cell_y_sort = true
	$TopTiles.cell_y_sort = true	

	get_tile_ids_from_TileSet()
	create_Objects_node()
	#covert_tiles_to_structure()

func put_object_enviroment(i,j,instance, flip = false ):
	instance.position = Vector2(i*80,j*80) + (instance.size*(40-1))
	if flip:
		if instance.has_node("Sprite"):
			instance.get_node("Sprite").flip_h = !instance.get_node("Sprite").flip_h
		if instance.has_node("Sprite2"):
			instance.get_node("Sprite2").flip_h = !instance.get_node("Sprite2").flip_h
	Obj_to_Append.append(instance)
	debugCounter += 1

func set_shape(shape):
    structure = shape[0]
    Enters    = shape[1]
    #pass

func put_wall_enviroment(i,j, prob, orientation, style ):
	#print("Called for [", i, ",", j,"] with ", shape[i][j] )

	var object_name = obj_splitted_by_wall_dependency[orientation][style][randi()%len(obj_splitted_by_wall_dependency[orientation][style])]
	var flip        = false

#	if Res.map_manager.force_thread_stop : return
	var instance = Res.get_scene(get_path_toObj(style) + object_name +".tscn")
	if instance == null:
		print( name + ":: not Found " + get_path_toObj(style) + object_name +".tscn" )
		return false
	instance = instance.instance()
	
	if style == Objects.DESTROYABLE:
		instance.fill(items_in_breakable,int(flooor))
	elif style == Objects.CONTAINERS:
		instance.fill(items_in_containers,int(flooor))
	
	
	var obj_size = instance.size
	
	match(SIDES[orientation][0]):
		TileState.wallDown:
			for x in range(obj_size.x):
				if not shape[i+x][j] in SIDES[orientation]: 
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not shape[i][j+obj_size.y - 1] in SIDES[2]:
						return false

		TileState.wallRight:
			for y in range(obj_size.y):
				if not shape[i][j+y] in SIDES[orientation]: 
					return false
			i = i + 1 - obj_size.x
			if instance.placement == instance.PLACEMENT.LEFT_OR_RIGHT_WALL or instance.can_flip_h:
				flip = true
				
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not shape[i+obj_size.x-1][j] in SIDES[0]:
						return false
						
		TileState.wallUp:
			for x in range(obj_size.x):
				if not shape[i+x][j] in SIDES[orientation]: 
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not shape[i][j+obj_size.y - 1] in SIDES[3]:
						return false
					
			j = j + 1 - obj_size.y
		TileState.wallLeft:
			for y in range(obj_size.y):
				if not shape[i][j+y] in SIDES[orientation]:
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not shape[i+obj_size.x-1][j] in SIDES[1]:
						return false
					
		TileState.free:
			if shape[i][j] < TileState.free or shape[i][j] >= TileState.blockedTile:
				return false
			pass

	for x in range(obj_size.x):
		for y in range(obj_size.y):
			if shape[i+x][j+y] < TileState.free or shape[i+x][j+y] >= TileState.blockedTile:
			#	print( "NO ENOUGHT ROOOM ",i," ",j, " in [", i+x , ",", j+y, "] is ",  shape[i+x][j+y] ) 
				return false
	
	reserve_tile_under_obj( obj_size, i, j , style)
	
	if instance.need_enemies_list :
		instance.fill_enemies_list(enemies)
	if instance.need_enable_directions:
		var enabler = []
		enabler.append(true) if ( shape[i-1][j] >= TileState.free and shape[i-1][j] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( shape[i+1][j] >= TileState.free and shape[i+1][j] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( shape[i][j-1] >= TileState.free and shape[i][j-1] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( shape[i][j+1] >= TileState.free and shape[i][j+1] <= TileState.exitTile )   else enabler.append(false)
		instance._build_wall(enabler)
	
	if style == Objects.CONTAINERS: AccesNeed.append([i,j])
	if style == Objects.TRAPS: 
		instance._change_sprite(tilesetName)

	put_object_enviroment(i,j,instance,flip)
	return true

func put_free_standing_objects(prob, style): 
	for i in range(used_rect.end.x):
		for j in range(used_rect.end.y):
#			if Res.map_manager.force_thread_stop : return
			if( randi()%1000 > prob) : continue
			if( len(obj_splitted_by_wall_dependency[Wall_Orientations.Free][style]) ):
				put_wall_enviroment(i,j, prob, Wall_Orientations.Free, style )

func put_wall_related_objects(prob, style):
	for i in range(used_rect.end.x):
		for j in range(used_rect.end.y):
			if( randi()%1000 > prob) : continue
#			if Res.map_manager.force_thread_stop : return
			match(shape[i][j]):
				TileState.wallLeft:
					if len(obj_splitted_by_wall_dependency[Wall_Orientations.Left][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
					break
				TileState.wallRight:
					if len(obj_splitted_by_wall_dependency[Wall_Orientations.Right][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue 				
					break
				TileState.wallDown:	
					if len(obj_splitted_by_wall_dependency[Wall_Orientations.Down][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Down , style) : continue 
					break
				TileState.wallUp:
					if len(obj_splitted_by_wall_dependency[Wall_Orientations.Up][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Up   , style) : continue
					break
				TileState.wallRightUp:
					match randi()%2:
						0:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Right][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue 
							break
						1:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Up][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Up   , style) : continue
							break
					break
				TileState.wallRightDown:
					match randi()%2:
						0:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Right][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue
							break
						1:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Down][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Down, style) : continue
							break
					break
				TileState.wallLeftUp:
					match randi()%2:
						0:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Left][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
							break
						1:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Up][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Up, style) : continue
							break
					break
				TileState.wallLeftDown:
					match randi()%2:
						0:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Left][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
							break
						1:
							if len(obj_splitted_by_wall_dependency[Wall_Orientations.Down][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Down, style) : continue
							break
					break

func put_enemies( enemies ,prob, current_lvl, enemy, dung_name):

	for i in range(used_rect.end.x+1):
		for j in range(used_rect.end.y+1):
			if shape[i][j] >= TileState.free and shape[i][j] < TileState.destroyableObject:
				if randi()%1000 < prob:
#					if Res.map_manager.force_thread_stop : return
					var object_name = enemies[randi()%len(enemies)]
					var instance = Res.get_scene(get_path_toObj(Objects.ENEMIES) + object_name + ".tscn").instance()
					instance.position = Vector2((i*80)+40,(j*80)+40) 
					instance._load_stats(enemy[dung_name][object_name],object_name)
					Obj_to_Append.append(instance)
					monster_counter +=1

func generate( file_json, dungeon, splitted_obj = null, current_level = 0, e = [] ):
	
#	var time_start = OS.get_ticks_msec()
#	var time_start1 = OS.get_ticks_msec()

	initialize()
	reset()
#	print( "ISG: initialization takes : ", (OS.get_ticks_msec() - time_start)) 
#	time_start = OS.get_ticks_msec()
	
	flooor = current_level
	
	items_in_containers = file_json["containers_contents"]
	items_in_breakable  = file_json["breakable_contents"]
	enemies             = file_json["floor"][str(current_level)]
	tilesetName         = file_json["tileset"]
	
#	print( "ISG: loading json takes : ", (OS.get_ticks_msec() - time_start)) 
#	time_start = OS.get_ticks_msec()

	if splitted_obj == null:
		split_enviroments_by_wallDependency(file_json["environment_objects"], Objects.CONST)
		split_enviroments_by_wallDependency(file_json["breakable_objects"  ], Objects.DESTROYABLE)
		split_enviroments_by_wallDependency(file_json["containers_objects" ], Objects.CONTAINERS)
		split_enviroments_by_wallDependency(file_json["trap_objects" ], Objects.TRAPS)
	else:
		obj_splitted_by_wall_dependency = splitted_obj
		
#	print( "ISG: spliting takes : ", (OS.get_ticks_msec() - time_start)) 
#	time_start = OS.get_ticks_msec()
#	var cout = 0
#	if Res.map_manager.force_thread_stop : return
	put_elements_on_scene( file_json["probs"] )
		
	while !check_correctnes():
#		if Res.map_manager.force_thread_stop : return
#		cout += 1
		reset()
		put_elements_on_scene( file_json["probs"] )

#	if Res.map_manager.force_thread_stop : return
	put_wall_related_objects ( file_json["probs"]["breakable"], Objects.DESTROYABLE )
	put_free_standing_objects( file_json["probs"]["breakable"], Objects.DESTROYABLE )

	put_enemies              ( file_json["floor"][str(current_level)],file_json["probs"]["enemies"], str(current_level), e,dungeon )

#	print( "ISG: checking coreectness takes : ", (OS.get_ticks_msec() - time_start) , " " , cout ) 
#	time_start = OS.get_ticks_msec()

	if DEBUG :
		print(name," : Reset Called ", numration_counter, " times" )
		print(name," :: ",  len(Obj_to_Append)-monster_counter == debugCounter, " : Control sum of Objects ", len(Obj_to_Append)-monster_counter, " in order to ", debugCounter )
		print(name," :: Monster Number  is ", monster_counter )

	var tileset = load("res://Resources/Tilesets/" + file_json["tileset"] + ".tres")
#	print( "ISG: loading tileset takes : ", (OS.get_ticks_msec() - time_start)) 
#	time_start = OS.get_ticks_msec()
	
	switch_patern_into_normal_tile(tileset, file_json["tileset"])
#	print( "ISG: switch patern takes : ", (OS.get_ticks_msec() - time_start)) 
#	time_start = OS.get_ticks_msec()
	translate_const_obj()
#	print( "ISG: translate consts takes : ", (OS.get_ticks_msec() - time_start)) 
#	print( "ISG: end takes : ", (OS.get_ticks_msec() - time_start1)) 

func put_elements_on_scene( probs ):
#	if Res.map_manager.force_thread_stop : return
	put_wall_related_objects ( probs["traps"], Objects.TRAPS)
	put_wall_related_objects ( probs["const"], Objects.CONST)
	put_wall_related_objects ( probs["container"], Objects.CONTAINERS)
	

	put_free_standing_objects( probs["const"]/2, Objects.CONST )
	put_free_standing_objects( probs["container"], Objects.CONTAINERS )
	put_free_standing_objects( probs["traps"]/4, Objects.TRAPS)


func translate_const_obj():
	
	for i in Obj_to_Append:
		get_node("Objects").add_child(i)
	
	if has_node("ConstObjects"):
		for i in $ConstObjects.get_children():
			var node = i
			get_node("ConstObjects").remove_child(node)
			if i.has_method( "_change_sprite" ): i._change_sprite(tilesetName)
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
			print( i, " not insaid " + get_path_toObj(objType) ) 
			continue
		instance = instance.instance()
		if instance.placement == instance.PLACEMENT.LEFT_OR_RIGHT_WALL:
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

func get_splitted_elements():
	return obj_splitted_by_wall_dependency

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


func check_fields_around(i, j):
	if i > 0 and j > 0:
		if shape[i][j-1] >= TileState.free or shape[i-1][j]     <= TileState.containerObject:
			return false
		if shape[i-1][j] >= TileState.free or shape[i-1][j]     <= TileState.containerObject:
			return false
		if shape[i-1][j-1] >= TileState.free or shape[i-1][j-1] <= TileState.containerObject:
			return false
			
	if i < used_rect.end.x+1 and j < used_rect.end.y+1:
		if shape[i+1][j+1] >= TileState.free or shape[i+1][j+1] <= TileState.containerObject:
			return false
		if shape[i+1][j] >= TileState.free or shape[i+1][j]     <= TileState.containerObject:
			return false
		if shape[i][j+1] >= TileState.free or shape[i][j+1]     <= TileState.containerObject:
			return false

	if i < used_rect.end.x+1 and j > 0:
		if shape[i+1][j-1] >= TileState.free or shape[i+1][j-1] <= TileState.containerObject:
			return false
	if j < used_rect.end.y+1 and i > 0:
		if shape[i-1][j+1] >= TileState.free or shape[i-1][j+1] <= TileState.containerObject:
			return false
	
	return true

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

func switch_patern_into_normal_tile(ts, sptrite_sheet_name):
	var defaId   = ts.find_tile_by_name("FloorMarker")

	var wallUpIdOld = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")
	var wallUpIdNew = ts.find_tile_by_name("WallMarkerUp")

	var wallDoIdOld = $BottomTiles.tile_set.find_tile_by_name("WallMarkerDown")
	var wallDoIdNew = ts.find_tile_by_name("WallMarkerDown")

	$BottomTiles.tile_set = ts
	$TopTiles.tile_set    = ts
	if has_node("SecretTiles"):
		$SecretTiles.tile_set    =  ts
		
	for i in range(used_rect.end.x+2):
		for j in range( used_rect.end.y+1):
			if $BottomTiles.get_cell(i,j+1) == wallDoIdOld and $BottomTiles.get_cell(i,j) == wallUpIdOld:
				$BottomTiles.set_cell(i,j  ,wallUpIdNew) 
				$BottomTiles.set_cell(i,j+1,wallDoIdNew) 
			elif $BottomTiles.get_cell(i,j) == wallDoIdOld and $BottomTiles.get_cell(i,j+1) == wallUpIdOld:
				$BottomTiles.set_cell(i,j  ,wallUpIdNew) 
				$BottomTiles.set_cell(i,j+1,wallDoIdNew) 
		
	for i in range(used_rect.end.x+2):
		for j in range(used_rect.end.y+1):
			if  $BottomTiles.get_cell(i,j) == tile_exit_id  or $BottomTiles.get_cell(i,j) == tile_const_id or $BottomTiles.get_cell(i,j) == tile_blocked_id or $BottomTiles.get_cell(i,j) == tile_free_id:
				$BottomTiles.set_cell(i,j, defaId)

	if has_node("Walls"):
		for i in $Walls.get_children():
			i.get_node("Sprite").texture =  load("res://Sprites/Tilesets/" + sptrite_sheet_name + ".png")
			i.get_node("Sprite2").texture = load("res://Sprites/Tilesets/" + sptrite_sheet_name + ".png")

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

func check_correctnes():
	var set   = [ Enters[0] ]
	var i = 0
	
	while( i != len(set) ):
		if set[i][0] - 1 >= 0:
			if shape[set[i][0]-1][set[i][1]] >= TileState.free and  shape[set[i][0]-1][set[i][1]] < TileState.constObject :
				if not [set[i][0] - 1, set[i][1]  ] in set:
					set.append([ set[i][0] - 1, set[i][1]  ])

		if set[i][1] - 1 >= 0:
			if shape[set[i][0]][set[i][1]-1] >= TileState.free and  shape[set[i][0]][set[i][1]-1] < TileState.constObject :
				if not [ set[i][0] , set[i][1] -1 ] in set:
					set.append([ set[i][0] , set[i][1] -1  ])

		if set[i][0] +1 < used_rect.end.x + 2:
			if shape[set[i][0]+1][set[i][1]] >= TileState.free and  shape[set[i][0]+1][set[i][1]] < TileState.constObject :
				if not [ set[i][0] , set[i][1] +1 ] in set:
						set.append([ set[i][0] , set[i][1] +1  ])
					
		if set[i][1] +1 < used_rect.end.y + 2:
			if shape[set[i][0]][set[i][1]+1] >= TileState.free and  shape[set[i][0]][set[i][1]+1] < TileState.constObject :
				if not [ set[i][0] + 1, set[i][1]  ] in set:
						set.append([ set[i][0] + 1,set[i][1]  ])
		i+=1
		
	for enter in Enters:
		if not enter in set:
		#	print( "Not found Enter :",  enter, " in ", set ) 
			return false

	for must_have in  AccesNeed:
		if not must_have in set:
		#	print( "Not found Mhave :",  must_have, " in ", set )
			return false
	
	return true

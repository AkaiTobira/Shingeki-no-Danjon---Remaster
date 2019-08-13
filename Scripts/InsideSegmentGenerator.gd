extends Node2D

export(bool) var can_have_stairs

var used_rect
var floor_number    = "-1"
var dungeon_name    = ""

var emptySpace      = {}

var shape                     = []
var structure                 = []
var navigation_points         = []
var enviroment_list           = []
var temporary_enviroment_list = []
var enters                    = []
var accesNeed                 = []

enum Wall_Orientations{
	Left,
	Right,
	Up,
	Down,
	Free
}

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

func set_shape(shape):
	structure = shape[0]
	enters    = shape[1]

func get_navigation_points():
	for i in range(used_rect.end.x+2):
		for j in range(used_rect.end.y+2):
			if shape[i][j] >= TileState.free and shape[i][j] <= TileState.exitTile:
				navigation_points.append(Vector2(40 + 80*i, 40 +80*j))

	return navigation_points

#TOREFACTOR_AND_UPDATE
func find_every_stair_possible_wall():
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")
	var temp = []
	for i in range(used_rect.end.x+1):
		for j in range(used_rect.end.y+1):
			if $BottomTiles.get_cell(i,j) == id and $BottomTiles.get_cell(i+1,j) == id:
				if shape[i][j+2] >= TileState.free and shape[i][j+2] < TileState.destroyableObject and shape[i+1][j+2] >= TileState.free and shape[i+1][j+2] < TileState.destroyableObject:
					temp.append(Vector2(i,j))
	
	return temp
#TOREFACTOR_AND_UPDATE				
func get_stairs_position():
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")

	var rico = []

	for i in range(used_rect.end.y):
		if $BottomTiles.get_cell(0,i) == id and shape[0][i+2] >= TileState.free and shape[0][i+2] < TileState.destroyableObject  :
			rico.append(Vector2(-1,i))
	return rico + find_every_stair_possible_wall()

func initialize_generation(dungeon, current_floor):
	floor_number = current_floor
	dungeon_name = dungeon
	used_rect    = $BottomTiles.get_used_rect()
	
	$BottomTiles.cell_y_sort = true
	$BottomTiles.z_index       = -1
	$BottomTiles.z_as_relative = false
	$TopTiles.cell_y_sort    = true
	
	create_Objects_node()
	reset()
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
		Res.EnvironmentType.Decoration: return Res.dungeons[dungeon_name]["probs"]["const"]
		Res.EnvironmentType.Trap:       return Res.dungeons[dungeon_name]["probs"]["traps"]
		Res.EnvironmentType.Box:        return Res.dungeons[dungeon_name]["probs"]["breakable"]
		Res.EnvironmentType.Chest:      return Res.dungeons[dungeon_name]["probs"]["container"]
		Res.EnvironmentType.Enemy:      return Res.dungeons[dungeon_name]["probs"]["enemies"]

func generate_objects():
	var styles = [ Res.EnvironmentType.Box, Res.EnvironmentType.Decoration, Res.EnvironmentType.Chest, Res.EnvironmentType.Trap ]#Res.EnvironmentType.Trap, Res.EnvironmentType.Decoration, Res.EnvironmentType.Box,  ]
	for style in styles:
		for position in emptySpace.keys():
			if( randi()%1000 > object_to_prob(style) ) : continue
			var coord = position.replace('(', '').replace(')','').split(",")
			if not emptySpace.has( position ) : continue
			var orientation = emptySpace[position][ randi()%len(emptySpace[position]) ]
			generate_single_object(int(coord[0]), int(coord[1]), object_to_prob(style), orientation, style)

func generate_enemies( ):
	var enemies = Res.dungeons[dungeon_name]["floor"][str(floor_number)]
	for position in emptySpace.keys():
		if( randi()%1000 > object_to_prob(Res.EnvironmentType.Enemy) ) : continue
		var coord = position.replace('(', '').replace(')','').split(",")
		var enemy = enemies[randi()%len(enemies)]
		var obj_position = Vector2((int(coord[0])*80)+40,(int(coord[1])*80)+40)
		enviroment_list.append({ "type": Res.EnvironmentType.Enemy, "name":enemy, "pos":obj_position, "state":"Alive" })

func generate_single_object(i,j, prob, orientation, style ):
	var object_list = Res.dungeons[dungeon_name]["floor_Objects"][orientation][style]
	if len(object_list) == 0: return false

	var object_name = object_list[randi()%len(object_list)]
	var instance = Res.cache_instance(object_name, style)
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
		Res.EnvironmentType.Trap: 
			temporary_enviroment_list.append({ "type": Res.EnvironmentType.Trap, "name": object_name, "pos":obj_position, "flip":Wall_Orientations.Right != orientation, "local_pos":Vector2(i,j), "closest_empty_space":[0,0,0,0] })
		Res.EnvironmentType.Box:
			temporary_enviroment_list.append({ "type": Res.EnvironmentType.Box, "name": object_name, "pos":obj_position, "state":"Alive" })
		Res.EnvironmentType.Chest:
			accesNeed.append([i,j])
			temporary_enviroment_list.append({ "type": Res.EnvironmentType.Chest, "name": object_name, "pos":obj_position, "state":"Alive" })	
		Res.EnvironmentType.Decoration:
			temporary_enviroment_list.append({ "type": Res.EnvironmentType.Decoration, "name": object_name, "pos":obj_position, "flip":Wall_Orientations.Right != orientation })

func reserve_tile_under_obj( obj_size, i, j, style = Res.EnvironmentType.Decoration ):
	for x in range(obj_size.x):
		for y in range(obj_size.y):
			if style == Res.EnvironmentType.Decoration:
				shape[i+x][j+y] = TileState.constObject
			elif style == Res.EnvironmentType.Chest:
				shape[i+x][j+y] = TileState.containerObject
			elif style == Res.EnvironmentType.Box:
				shape[i+x][j+y] = TileState.destroyableObject
			elif style == Res.EnvironmentType.Trap:
				shape[i+x][j+y] = TileState.destroyableObject
				
			var pos = str( Vector2(i+x,j+y) )
			if emptySpace.has(pos) : emptySpace.erase(pos)

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
	enviroment_list += temporary_enviroment_list
	
	translate_const_obj()	
	
	
	#print( "ISG: generate enemies takes : ", (OS.get_ticks_msec() - time_start)) 
	#time_start = OS.get_ticks_msec()


	#print( "ISG: translate consts takes : ", (OS.get_ticks_msec() - time_start)) 

func finish_trap_generation():
	for obj in temporary_enviroment_list:
		var instance = Res.cache_instance(obj.name, obj.type)
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
	if has_node("ConstObjects"):
		for obj in $ConstObjects.get_children():
			var node = obj
			if node.has_method( "get_placement_info" ):
				var placement_info = node.get_placement_info()
				match( placement_info.type ):
					Res.EnvironmentType.Trap: 
						enviroment_list.append({ "type": Res.EnvironmentType.Trap, "name": placement_info.name, "pos":node.position, "flip":placement_info.flip, "closest_empty_space":[4,4,4,4] })
					Res.EnvironmentType.Box:
						enviroment_list.append({ "type": Res.EnvironmentType.Box, "name": placement_info.name, "pos":node.position,  "state":"Alive" })
					Res.EnvironmentType.Chest:
						enviroment_list.append({ "type": Res.EnvironmentType.Chest, "name": placement_info.name, "pos":node.position,  "state":"Alive" })
					Res.EnvironmentType.Decoration:
						enviroment_list.append({ "type": Res.EnvironmentType.Decoration, "name": placement_info.name, "pos":node.position, "flip":placement_info.flip })
			$ConstObjects.remove_child(node)

func reset():
	accesNeed.clear()

	shape.clear()
	for i in structure:
		var cell = []
		for j in i:
			cell.append(j)
		shape.append(cell)
	
	temporary_enviroment_list.clear()
	convert_struct_to_set()

func create_Objects_node():
	if not has_node("Objects"):
		var Objects = Node2D.new()
		Objects.set_name("Objects")
		add_child(Objects) 

func print_segment_structure():
	for i in range(used_rect.end.x+2):
		print(shape[i])
	print("\n")

func is_correct():
	var enters_number = 0
	var acces_need    = 0
	var directions    = [ [0,1], [0,-1], [1,0], [-1,0] ]
	var queue         = [ enters[0] ]
	var checked       = []

	while( len(queue) > 0 ):
		var position = queue.pop_front()
		if position in enters: enters_number += 1
		if position in accesNeed: acces_need += 1
		if enters_number == len(enters) and acces_need == len(accesNeed) : return true

		for direction in directions:
			var new1 = [position[0] + direction[0], position[1] + direction[1]]
			if not new1 in checked and not new1 in queue and is_valid(new1): queue.push_back(new1)
		checked.append(position)
	return false

func is_valid(array):
	if array[0] <= used_rect.position.x-1 or array[0] >= used_rect.end.x+1 : return false
	if array[1] <= used_rect.position.y-1 or array[1] >= used_rect.end.y+1 : return false
	if shape[array[0]][array[1]] < TileState.free or shape[array[0]][array[1]] >= TileState.constObject : return false
	return true  
extends Node2D

export(bool) var can_have_stairs

var G
var numration_counter = 0
var monster_counter   = 0

const DEBUG = false

var flooor 
var breakable_contains
var conatainer_contains
var tilesetName

var exitId 
var freeId
var consId 
var blokId 

enum Objects{
	CONST
	DESTROYABLE
	CONTAINERS
	TRAPS
	ENEMIES
	}

var tab       = []
var structure = []
var Obj_to_Append = []
var enemies   = []

var Wall_Splitted_Obj = [ 
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
	return G.end

func _ready():
	
	exitId = $BottomTiles.tile_set.find_tile_by_name("FloorE")
	freeId = $BottomTiles.tile_set.find_tile_by_name("FloorF")
	consId = $BottomTiles.tile_set.find_tile_by_name("FloorC")
	blokId = $BottomTiles.tile_set.find_tile_by_name("FloorS")
	
	create_Objects_code()
	G = $BottomTiles.get_used_rect()
	build_segment_structure()

func put_object_enviroment(i,j,instance, flip = false ):
	instance.position = Vector2(i*80,j*80) + (instance.size*(40-1))
	if flip:
		if instance.has_node("Sprite"):
			instance.get_node("Sprite").flip_h = !instance.get_node("Sprite").flip_h
		if instance.has_node("Sprite2"):
			instance.get_node("Sprite2").flip_h = !instance.get_node("Sprite2").flip_h
	Obj_to_Append.append(instance)
	debugCounter += 1

func put_wall_enviroment(i,j, prob, orientation, style ):
	#print("Called for [", i, ",", j,"] with ", tab[i][j] )

	var object_name = Wall_Splitted_Obj[orientation][style][randi()%len(Wall_Splitted_Obj[orientation][style])]
	var flip        = false

	var instance = load(get_path(style) + object_name +".tscn")
	if instance == null:
		print( name + ":: not Found " + get_path(style) + object_name +".tscn" )
		return false
	instance = instance.instance()
	
	if style == Objects.DESTROYABLE:
		instance.fill(breakable_contains,int(flooor))
	elif style == Objects.CONTAINERS:
		instance.fill(conatainer_contains,int(flooor))
	
	
	var obj_size = instance.size
	
	match(SIDES[orientation][0]):
		TileState.wallDown:
			for x in range(obj_size.x):
				if not tab[i+x][j] in SIDES[orientation]: 
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not tab[i][j+obj_size.y - 1] in SIDES[2]:
						return false

		TileState.wallRight:
			for y in range(obj_size.y):
				if not tab[i][j+y] in SIDES[orientation]: 
					return false
			i = i + 1 - obj_size.x
			if instance.placement == instance.LEFT_OR_RIGHT_WALL or instance.can_flip_h:
				flip = true
				
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not tab[i+obj_size.x-1][j] in SIDES[0]:
						return false
						
		TileState.wallUp:
			for x in range(obj_size.x):
				if not tab[i+x][j] in SIDES[orientation]: 
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not tab[i][j+obj_size.y - 1] in SIDES[3]:
						return false
					
			j = j + 1 - obj_size.y
		TileState.wallLeft:
			for y in range(obj_size.y):
				if not tab[i][j+y] in SIDES[orientation]:
					return false
					
			if style == Objects.TRAPS:
				if instance.need_two_side_wall:
					if not tab[i+obj_size.x-1][j] in SIDES[1]:
						return false
					
		TileState.free:
			if tab[i][j] < TileState.free or tab[i][j] >= TileState.blockedTile:
				return false
			pass

	for x in range(obj_size.x):
		for y in range(obj_size.y):
			if tab[i+x][j+y] < TileState.free or tab[i+x][j+y] >= TileState.blockedTile:
			#	print( "NO ENOUGHT ROOOM ",i," ",j, " in [", i+x , ",", j+y, "] is ",  tab[i+x][j+y] ) 
				return false
	
	reserve_tile_under_obj( obj_size, i, j , style)
	
	if instance.need_enemies_list :
		instance.fill_enemies_list(enemies)
	if instance.need_enable_directions:
		var enabler = []
		enabler.append(true) if ( tab[i-1][j] >= TileState.free and tab[i-1][j] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( tab[i+1][j] >= TileState.free and tab[i+1][j] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( tab[i][j-1] >= TileState.free and tab[i][j-1] <= TileState.exitTile )   else enabler.append(false)
		enabler.append(true) if ( tab[i][j+1] >= TileState.free and tab[i][j+1] <= TileState.exitTile )   else enabler.append(false)
		instance._build_wall(enabler)
	
	if style == Objects.CONTAINERS: AccesNeed.append([i,j])
	if style == Objects.TRAPS: 
		instance._change_sprite(tilesetName)


	put_object_enviroment(i,j,instance,flip)
	
	return true

func put_free_standing_objects(prob, style): 
	for i in range(G.end.x):
		for j in range(G.end.y):
			if( randi()%1000 > prob) : continue
			if( len(Wall_Splitted_Obj[Wall_Orientations.Free][style]) ):
				put_wall_enviroment(i,j, prob, Wall_Orientations.Free, style )

func put_wall_related_objects(prob, style):
	for i in range(G.end.x):
		for j in range(G.end.y):
			if( randi()%1000 > prob) : continue
			match(tab[i][j]):
				TileState.wallLeft:
					if len(Wall_Splitted_Obj[Wall_Orientations.Left][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
					break
				TileState.wallRight:
					if len(Wall_Splitted_Obj[Wall_Orientations.Right][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue 				
					break
				TileState.wallDown:	
					if len(Wall_Splitted_Obj[Wall_Orientations.Down][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Down , style) : continue 
					break
				TileState.wallUp:
					if len(Wall_Splitted_Obj[Wall_Orientations.Up][style]):
						if put_wall_enviroment (i,j,prob, Wall_Orientations.Up   , style) : continue
					break
				TileState.wallRightUp:
					match randi()%2:
						0:
							if len(Wall_Splitted_Obj[Wall_Orientations.Right][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue 
							break
						1:
							if len(Wall_Splitted_Obj[Wall_Orientations.Up][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Up   , style) : continue
							break
					break
				TileState.wallRightDown:
					match randi()%2:
						0:
							if len(Wall_Splitted_Obj[Wall_Orientations.Right][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Right, style) : continue
							break
						1:
							if len(Wall_Splitted_Obj[Wall_Orientations.Down][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Down, style) : continue
							break
					break
				TileState.wallLeftUp:
					match randi()%2:
						0:
							if len(Wall_Splitted_Obj[Wall_Orientations.Left][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
							break
						1:
							if len(Wall_Splitted_Obj[Wall_Orientations.Up][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Up, style) : continue
							break
					break
				TileState.wallLeftDown:
					match randi()%2:
						0:
							if len(Wall_Splitted_Obj[Wall_Orientations.Left][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Left, style) : continue
							break
						1:
							if len(Wall_Splitted_Obj[Wall_Orientations.Down][style]):
								if put_wall_enviroment (i,j,prob, Wall_Orientations.Down, style) : continue
							break
					break

func put_enemies( enemies ,prob, current_lvl, enemy, dung_name):

	for i in range(G.end.x+1):
		for j in range(G.end.y+1):
			if tab[i][j] >= TileState.free and tab[i][j] < TileState.destroyableObject:
				if randi()%1000 < prob:
					var object_name = enemies[randi()%len(enemies)]
					var instance = load(get_path(Objects.ENEMIES) + object_name + ".tscn").instance()
					instance.position = Vector2((i*80)+40,(j*80)+40)
#					print( enemy[dung_name][object_name] )
				#	print(dung_name,enemies[dung_name][object_name]) 
					instance._load_stats(enemy[dung_name][object_name],object_name)
					Obj_to_Append.append(instance)
					monster_counter +=1

func generate( file_json, dungeon, splitted_obj = null, current_level = 0, e = [] ):
	flooor = current_level
	
	conatainer_contains = file_json["containers_contents"]
	breakable_contains  = file_json["breakable_contents"]
	enemies = file_json["floor"][str(current_level)]

	if splitted_obj == null:
		split_enviroments(file_json["environment_objects"], Objects.CONST)
		split_enviroments(file_json["breakable_objects"  ], Objects.DESTROYABLE)
		split_enviroments(file_json["containers_objects" ], Objects.CONTAINERS)
		split_enviroments(file_json["trap_objects" ], Objects.TRAPS)
	else:
		Wall_Splitted_Obj = splitted_obj
		
	tilesetName = file_json["tileset"]
	put_elements_on_scene( file_json["probs"] )
	
	while !check_correctnes():
		reset()
		put_elements_on_scene( file_json["probs"] )

	put_wall_related_objects ( file_json["probs"]["breakable"], Objects.DESTROYABLE )
	put_free_standing_objects( file_json["probs"]["breakable"], Objects.DESTROYABLE )

	put_enemies              ( file_json["floor"][str(current_level)],file_json["probs"]["enemies"], str(current_level), e,dungeon )

	

	if DEBUG :
		print(name," : Reset Called ", numration_counter, " times" )
		print(name," :: ",  len(Obj_to_Append)-monster_counter == debugCounter, " : Control sum of Objects ", len(Obj_to_Append)-monster_counter, " in order to ", debugCounter )
		print(name," :: Monster Number  is ", monster_counter )


	var tileset = load("res://Resources/Tilesets/" + file_json["tileset"] + ".tres")

	switch_patern_into_normal_tile(tileset, file_json["tileset"])
	translate_const_obj()

func put_elements_on_scene( probs ):
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
			get_node("Objects").add_child(i)

func reset():
	debugCounter = 0
	numration_counter +=1;
	Obj_to_Append.clear()
	AccesNeed.clear()
	
	print( name , " : Reset Called : ", numration_counter )
	
	tab.clear()
	for i in structure:
		var cell = []
		for j in i:
			cell.append(j)
		tab.append(cell)	

func get_path(objType):
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

func split_enviroments(enviroments, objType):

	for i in enviroments:
		var instance = load(get_path(objType) + i +".tscn")
		if instance == null  : 
			print( i, " not insaid " + get_path(objType) ) 
			continue
		instance = instance.instance()
		if instance.placement == instance.LEFT_OR_RIGHT_WALL:
				Wall_Splitted_Obj[Wall_Orientations.Left  ][objType].append(i)
				Wall_Splitted_Obj[Wall_Orientations.Right ][objType].append(i)
		elif instance.placement == instance.UP_OR_DOWN_WALL:
				Wall_Splitted_Obj[Wall_Orientations.Up    ][objType].append(i)
				Wall_Splitted_Obj[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.DOWN_WALL:
				Wall_Splitted_Obj[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.UP_WALL:
				Wall_Splitted_Obj[Wall_Orientations.Up    ][objType].append(i)
		elif instance.placement == instance.EVERY_WALL:
				Wall_Splitted_Obj[Wall_Orientations.Left  ][objType].append(i)
				Wall_Splitted_Obj[Wall_Orientations.Right ][objType].append(i)
				Wall_Splitted_Obj[Wall_Orientations.Up    ][objType].append(i)
				Wall_Splitted_Obj[Wall_Orientations.Down  ][objType].append(i)
		elif instance.placement == instance.WALL_FREE:
				Wall_Splitted_Obj[Wall_Orientations.Free  ][objType].append(i)

func build_segment_structure():

	
	for i in range(G.end.x+2):
		var cell = []
		for j in range(G.end.y+2):
			if  $BottomTiles.get_cell(i,j) == freeId :
				cell.append(TileState.free)
			elif $BottomTiles.get_cell(i,j) == exitId :
				cell.append(TileState.exitTile)
				Enters.append([i,j])
			elif $BottomTiles.get_cell(i,j) == consId :
				cell.append(TileState.constObject)
			elif $BottomTiles.get_cell(i,j) == blokId :
				cell.append(TileState.blockedTile)
			else:
				cell.append(TileState.noTile)
		tab.append(cell)
		
	mark_walls()
	
	for i in tab:
		var cell = []
		for j in i:
			cell.append(j)
		structure.append(cell)	

func mark_walls():
	for i in range(G.end.x+2):
		for j in range(G.end.y+2):
			mark_wall_left (i,j)
			mark_wall_right(i,j)
			mark_wall_up   (i,j)
			mark_wall_down (i,j)
	correct_enter_wall()

func mark_wall_left(i,j):
	if i > 0:
		if tab[i][j] == TileState.free and tab[i-1][j] == TileState.noTile:
			tab[i][j] = TileState.wallLeft
		elif tab[i][j] == TileState.wallDown and tab[i-1][j] == TileState.noTile:
			tab[i][j] = TileState.wallLeftDown
		elif tab[i][j] == TileState.wallUp and tab[i-1][j] == TileState.noTile:
			tab[i][j] = TileState.wallLeftUp

func mark_wall_right(i,j):
	if i < G.end.x:
		if tab[i][j] == TileState.free and tab[i+1][j] == TileState.noTile:
			tab[i][j] = TileState.wallRight
		elif tab[i][j] == TileState.wallDown and tab[i+1][j] == TileState.noTile:
			tab[i][j] = TileState.wallRightDown
		elif tab[i][j] == TileState.wallUp and tab[i+1][j] == TileState.noTile:
			tab[i][j] = TileState.wallRightUp
	
func mark_wall_up(i,j):
	if j < G.end.y:
		if tab[i][j] == TileState.free and tab[i][j+1] == TileState.noTile:
			tab[i][j] = TileState.wallUp
		elif tab[i][j] == TileState.wallLeft and tab[i][j+1] == TileState.noTile:
			tab[i][j] = TileState.wallLeftUp
		elif tab[i][j] == TileState.wallRight and tab[i][j+1] == TileState.noTile:
			tab[i][j] = TileState.wallRightUp
		
func mark_wall_down(i,j):
	if j > 0:
		if tab[i][j] == TileState.free and tab[i][j-1] == TileState.noTile:
			tab[i][j] = TileState.wallDown
		elif tab[i][j] == TileState.wallLeft and tab[i][j-1] == TileState.noTile:
			tab[i][j] = TileState.wallLeftDown
		elif tab[i][j] == TileState.wallRight and tab[i][j-1] == TileState.noTile:
			tab[i][j] = TileState.wallRightDown

func correct_enter_wall():

	for x in range(G.end.x+2):
		for y in range(G.end.y+2):
			
			if y < G.end.y:
				if tab[x][y] == TileState.noTile and (tab[x][y+1] >= TileState.free and tab[x][y+1] < TileState.blockedTile) and tab[x][y+2] == TileState.exitTile:
					tab[x][y+1] = TileState.wallDown
	
				if tab[x][y] == TileState.exitTile and (tab[x][y+1] >= TileState.free and tab[x][y+1] < TileState.blockedTile) and tab[x][y+2] == TileState.noTile:
					tab[x][y+1] = TileState.wallUp
					
			if x < G.end.x:
				if tab[x][y] == TileState.noTile and (tab[x+1][y] >= TileState.free and tab[x+1][y] < TileState.blockedTile) and tab[x+2][y] == TileState.exitTile:
					tab[x+1][y] = TileState.wallLeft
	
				if tab[x][y] == TileState.exitTile and (tab[x+1][y] >= TileState.free and tab[x+1][y] < TileState.blockedTile) and tab[x+2][y] == TileState.noTile:
					tab[x+1][y] = TileState.wallRight

func get_splitted_elements():
	return Wall_Splitted_Obj

func create_Objects_code():
	if not has_node("Objects"):
		var Objects = Node2D.new()
		Objects.set_name("Objects")
		add_child(Objects) 

func print_segment_structure():
	for i in range(G.end.x+2):
		print(tab[i])
	print("\n")

func get_Astar_positions():

	var special_points = []
		
	for i in range(G.end.x+2):
		for j in range(G.end.y+2):
			if tab[i][j] >= TileState.free and tab[i][j] <= TileState.containerObject:
				special_points.append(Vector2(40 + 80*i, 40 +80*j))

	return special_points


func check_fields_around(i, j):
	if i > 0 and j > 0:
		if tab[i][j-1] >= TileState.free or tab[i-1][j] <= TileState.containerObject:
			return false
		if tab[i-1][j] >= TileState.free or tab[i-1][j] <= TileState.containerObject:
			return false
		if tab[i-1][j-1] >= TileState.free or tab[i-1][j-1] <= TileState.containerObject:
			return false
			
	if i < G.end.x+1 and j < G.end.y+1:
		if tab[i+1][j+1] >= TileState.free or tab[i+1][j+1] <= TileState.containerObject:
			return false
		if tab[i+1][j] >= TileState.free or tab[i+1][j] <= TileState.containerObject:
			return false
		if tab[i][j+1] >= TileState.free or tab[i][j+1] <= TileState.containerObject:
			return false

	if i < G.end.x+1 and j > 0:
		if tab[i+1][j-1] >= TileState.free or tab[i+1][j-1] <= TileState.containerObject:
			return false
	if j < G.end.y+1 and i > 0:
		if tab[i-1][j+1] >= TileState.free or tab[i-1][j+1] <= TileState.containerObject:
			return false
	
	return true


func block_unreacheable():
	var t = 0
	for i in range(G.end.x+1):
		for j in range(G.end.y+1):
			if check_fields_around(i,j):
				tab[i][j] = TileState.noTile
				t +=1

func find_every_stair_possible_wall():
	
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")
	
	var temp = []
	
	for i in range(G.end.x+1):
		for j in range(G.end.y+1):
			if $BottomTiles.get_cell(i,j) == id and $BottomTiles.get_cell(i+1,j) == id:
				if tab[i][j+2] >= TileState.free and tab[i][j+2] < TileState.destroyableObject and tab[i+1][j+2] >= TileState.free and tab[i+1][j+2] < TileState.destroyableObject:
					temp.append(Vector2(i,j))
	
	return temp
					

func get_stairs_position():
	var id = $BottomTiles.tile_set.find_tile_by_name("WallMarkerUp")

	var rico = []

	for i in range(G.end.y):
		if $BottomTiles.get_cell(0,i) == id and tab[0][i+2] >= TileState.free and tab[0][i+2] < TileState.destroyableObject  :
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
		
	for i in range(G.end.x+2):
		for j in range( G.end.y+1):
			if $BottomTiles.get_cell(i,j+1) == wallDoIdOld and $BottomTiles.get_cell(i,j) == wallUpIdOld:
				$BottomTiles.set_cell(i,j  ,wallUpIdNew) 
				$BottomTiles.set_cell(i,j+1,wallDoIdNew) 
			elif $BottomTiles.get_cell(i,j) == wallDoIdOld and $BottomTiles.get_cell(i,j+1) == wallUpIdOld:
				$BottomTiles.set_cell(i,j  ,wallUpIdNew) 
				$BottomTiles.set_cell(i,j+1,wallDoIdNew) 
		
	for i in range(G.end.x+2):
		for j in range(G.end.y+1):
			if  $BottomTiles.get_cell(i,j) == exitId  or $BottomTiles.get_cell(i,j) == consId or $BottomTiles.get_cell(i,j) == blokId or $BottomTiles.get_cell(i,j) == freeId:
				$BottomTiles.set_cell(i,j, defaId)

	if has_node("Walls"):
		for i in $Walls.get_children():
			i.get_node("Sprite").texture =  load("res://Sprites/Tilesets/" + sptrite_sheet_name + ".png")
			i.get_node("Sprite2").texture = load("res://Sprites/Tilesets/" + sptrite_sheet_name + ".png")



func reserve_tile_under_obj( obj_size, i, j, style = Objects.CONST ):
	for x in range(obj_size.x):
		for y in range(obj_size.y):
			if style == Objects.CONST:
				tab[i+x][j+y] = TileState.constObject
			elif style == Objects.CONTAINERS:
				tab[i+x][j+y] = TileState.containerObject
			elif style == Objects.DESTROYABLE:
				tab[i+x][j+y] = TileState.destroyableObject
			elif style == Objects.TRAPS:
				tab[i+x][j+y] = TileState.destroyableObject

			
func check_correctnes():
	var set   = [ Enters[0] ]
	var i = 0
	
	while( i != len(set) ):
		if set[i][0] - 1 >= 0:
			if tab[set[i][0]-1][set[i][1]] >= TileState.free and  tab[set[i][0]-1][set[i][1]] < TileState.constObject :
				if not [set[i][0] - 1, set[i][1]  ] in set:
					set.append([ set[i][0] - 1, set[i][1]  ])

		if set[i][1] - 1 >= 0:
			if tab[set[i][0]][set[i][1]-1] >= TileState.free and  tab[set[i][0]][set[i][1]-1] < TileState.constObject :
				if not [ set[i][0] , set[i][1] -1 ] in set:
					set.append([ set[i][0] , set[i][1] -1  ])

		if set[i][0] +1 < G.end.x + 2:
			if tab[set[i][0]+1][set[i][1]] >= TileState.free and  tab[set[i][0]+1][set[i][1]] < TileState.constObject :
				if not [ set[i][0] , set[i][1] +1 ] in set:
						set.append([ set[i][0] , set[i][1] +1  ])
					
		if set[i][1] +1 < G.end.y + 2:
			if tab[set[i][0]][set[i][1]+1] >= TileState.free and  tab[set[i][0]][set[i][1]+1] < TileState.constObject :
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

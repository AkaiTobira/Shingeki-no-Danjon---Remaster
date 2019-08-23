extends Node

#TO_REFACTOR
var importantTileId = {}
var used_rect       = null
var dungeon_name    = ""

func convert_wall_pattern_to_new_tileset(b_tiles, wallMarkersIDs):
	for i in range(used_rect.end.x+2):
		for j in range( used_rect.end.y+1):
			if b_tiles.get_cell(i,j+1) == wallMarkersIDs["OldLowerPartOfWall"] and b_tiles.get_cell(i,j) == wallMarkersIDs["OldUpperPartOfWall"]:
				b_tiles.set_cell(i,j  ,wallMarkersIDs["NewUpperPartOfWall"]) 
				b_tiles.set_cell(i,j+1,wallMarkersIDs["NewUpperPartOfWall"]) 

func convert_floor_pattern_to_new_tileset(b_tiles, floorId):
	for i in range(used_rect.end.x+2):
		for j in range(used_rect.end.y+1):
			if b_tiles.get_cell(i,j) in importantTileId.values():
				b_tiles.set_cell(i,j, floorId)

func change_tileset(b_tiles, t_tiles, s_tiles):
	var newTileset = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	var floorId    = newTileset.find_tile_by_name("FloorMarker")

	var wallMarkersIDs = {}
	wallMarkersIDs["OldUpperPartOfWall"] = b_tiles.tile_set.find_tile_by_name("WallMarkerUp")
	wallMarkersIDs["NewUpperPartOfWall"] = newTileset.find_tile_by_name("WallMarkerUp")
	wallMarkersIDs["OldLowerPartOfWall"] = b_tiles.tile_set.find_tile_by_name("WallMarkerDown")
	wallMarkersIDs["NewLowerPartOfWall"] = newTileset.find_tile_by_name("WallMarkerDown")

	b_tiles.tile_set = newTileset
	t_tiles.tile_set = newTileset
	if s_tiles: s_tiles.tile_set    =  newTileset
		
	convert_wall_pattern_to_new_tileset(b_tiles, wallMarkersIDs)
	convert_floor_pattern_to_new_tileset(b_tiles, floorId)
    
	#if has_node("Walls"):
	#	for i in $Walls.get_children():
	#		i.get_node("Sprite").texture =  load("res://Sprites/Tilesets/" +  Res.dungeons[dungeon_name]["tileset"] + ".png")
	#		i.get_node("Sprite2").texture = load("res://Sprites/Tilesets/" +  Res.dungeons[dungeon_name]["tileset"] + ".png")

func get_important_tile_ids(b_tiles):
	importantTileId["E"] = b_tiles.tile_set.find_tile_by_name("FloorE")
	importantTileId["F"] = b_tiles.tile_set.find_tile_by_name("FloorF")
	importantTileId["C"] = b_tiles.tile_set.find_tile_by_name("FloorC")
	importantTileId["B"] = b_tiles.tile_set.find_tile_by_name("FloorS")

func replace_wall_and_floors(graph, name):
	dungeon_name = name
	var tileset  = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]
	var ts       = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")

	var tileset_dict = {}
	for i in ts.get_tiles_ids():
		tileset_dict[ts.tile_get_name(i)] = i

	var b_tiles = graph[0]["segment"].find_node("BottomTiles", true, false)
	get_important_tile_ids(b_tiles)

	for index_g in graph:

		var bottom = graph[index_g]["segment"].find_node("BottomTiles", true, false)
		var top    = graph[index_g]["segment"].find_node("TopTiles", true, false)
		var secret = graph[index_g]["segment"].find_node("SecretTiles", true, false)
		used_rect  = bottom.get_used_rect()

		change_tileset( bottom, top, secret)

		if bottom != null :
			for cell in bottom.get_used_cells():
				if bottom.get_cellv(cell) == tileset_dict["FloorMarker"]:
					var new_tile    = Res.weighted_random(tileset.floor_ids_with_weights)
					var tile        = tileset.tile_to_floor[new_tile]
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

	return graph
extends Node
onready var dungeon = $"../Segments"

var NewToTest = "Uganda"#"Enemies/Puncher"#"Enemies/Mechanic" #jak zrobisz tak to masz fajny null ##DEBUG

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const DOFFSET = [Vector2(1, 0), Vector2(0, 1)]
const OPPOSITE = [2, 3, 0, 1]

const MIN_MAP_SIZE = 25

var disabled = []#["Puncher"] ##DEBUG

var width = 100
var height = 100
var dungeon_name 

var empty_spots = []
var segments = []
var map = []
var floor_space = {}
var wall_space = []


var file_json
var splitted_obj


func generate(level_name,w, h):
	width = w
	height = h
	map.resize(width * height)
	dungeon_name = level_name
	var end = false
	
	#print(DungeonState.current_floor)
	
	var start = Vector2(randi() % width, randi() % height)
	empty_spots.append({"pos": start})
	
	while !end:
		while !empty_spots.empty():
			var spot = empty_spots[randi() % empty_spots.size()]
			empty_spots.erase(spot)
			
			var segments = get_possible_segments(spot)
			
			if !segments.empty():
				var segment = segments[randi() % segments.size()]
				var offset = segment.offset
				segment = segment.segment
				
				set_segment(spot.pos + offset, segment)
				
				for dir in range(4):
					var dim = ["width", "height"][dir%2]
					for i in range(segment[dim]):
						var ds = DIRECTIONS[dir] + DOFFSET[dir%2] * i
						if segment["ways" + str(dir)][i]: empty_spots.append({"pos": spot.pos + offset + ds, "dir": dir})
		
		if segments.size() >= MIN_MAP_SIZE:
			end = true
#		elif !segments.empty():
#			remove_segment(segments[randi() % segments.size()])
		else:
			segments.clear()
			map.clear()
			map.resize(width * height)
			start = Vector2(randi() % width, randi() % height)
			empty_spots = [{"pos": start}]
	
	for x in range(width):
		for y in range(height):
			var segment = map[x + y * width]
			if segment and segment.piece_x + segment.piece_y == 0:
				create_segment(segment.segment.name, Vector2(x, y))


	var tileset = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]
	#dungeon_type.tileset]
	create_stairs()

	var tileset_dict = {}

	var ts = load("res://Resources/Tilesets/" +Res.dungeons[dungeon_name]["tileset"] + ".tres")

	for i in ts.get_tiles_ids():
		tileset_dict[ts.tile_get_name(i)] = i

	for segment in dungeon.get_children():
		var bottom = segment.find_node("BottomTiles", true, false)
		
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


	
#	place_environment()
#	place_containers()
#	place_breakables()
#	place_enemies()
#	for i in range(10): place_on_floor("NPC")
#	for i in range(100):
#		var instance = place_on_floor("NPC")
#		instance.id = 1
	queue_free()

func create_stairs():
	var tileset = Res.tilesets[Res.dungeons[dungeon_name]["tileset"]]
	var segments = dungeon.get_children()
	
	var segment_enter  = segments[randi()%len(segments)]	
	var stairs_pos = segment_enter.get_stairs_position() 
	while(!segment_enter.can_have_stairs or !len(stairs_pos) ):
		segment_enter  = segments[randi()%len(segments)]	
		stairs_pos = segment_enter.get_stairs_position() 


	var stairs_position = stairs_pos[randi()%len(stairs_pos)]*80
	Res.game.player.position = stairs_position  + segment_enter.position + Vector2(80, 160)

	var sprite = load("res://Sprites/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".png")

	var stairs = Res.create_instance("Objects/Stairs")
	stairs.texture = sprite
	stairs.position = stairs_position + Vector2(80, 80) + segment_enter.position
	stairs.set_stairs("up" if Res.dungeons[dungeon_name]["progress"] != get_parent().from else "down", tileset)
	dungeon.add_child(stairs)

	var segment_exit  = segments[randi()%len(segments)]	
	stairs_pos = segment_exit.get_stairs_position() 
	while(!segment_exit.can_have_stairs or !len(stairs_pos) or segment_exit == segment_enter ):
		segment_exit  = segments[randi()%len(segments)]	
		stairs_pos = segment_exit.get_stairs_position() 

	stairs_position = stairs_pos[randi()%len(stairs_pos)]*80

	stairs = Res.create_instance("Objects/Stairs")
	stairs.texture = sprite
	stairs.position = stairs_position + Vector2(80, 80) + segment_exit.position
	stairs.set_stairs("up" if Res.dungeons[dungeon_name]["progress"] == get_parent().from else "down", tileset)
	dungeon.add_child(stairs)


#
#func place_breakables():
#	var breakables = dungeon_type.breakables
#
#	var nil = 0
#
#	var chances = {}
#	for item in dungeon_type.breakable_contents:
#		chances[item[0]] = item[1]
#		nil += 1000 - item[1]
#
#	chances[-1] = nil
#
#	for i in range(dungeon_type.breakable_count):
#		var type = breakables[randi() % breakables.size()]
#		var instance = place_on_floor("Objects/" + type)
#		if instance: instance.item = int(Res.weighted_random(chances))
#		else: break

#func place_containers():
#	var containers = dungeon_type.containers
#
#	for i in range(dungeon_type.container_count):
#		var type = containers[randi() % containers.size()]
#		var instance = place_on_floor("Objects/" + type)
#		if instance: instance.item = int(Res.weighted_random(dungeon_type.container_contents))
#		else: break

func place_for_test(what):
	if NewToTest == "": return
	
	var ug_inst = what.instance()
	ug_inst.position = Res.game.player.position + Vector2(200,200)
	dungeon.get_parent().add_child(ug_inst)

#func place_enemies():
#	var enemies = dungeon_type.enemies
#
#	for i in range(dungeon_type.enemy_count):
#		var type = enemies[randi() % enemies.size()]
#		if !place_on_floor("Enemies/" + type): break
#
#	if NewToTest: place_for_test(Res.get_node(NewToTest))

#func place_on_floor(object):
#	if DungeonState.current_floor < 2 and ["Enemies/FLA-B", "Enemies/FLA-G", "Enemies/FLA-S"].has(object): return true
#	if DungeonState.current_floor < 3 and ["Enemies/PuncherMKII"].has(object): return true ##ULTRAMEGAKURESUPEREXTRAHACK
#	for dis in disabled: if object.find(dis) > -1: return ##DEBUG
#	if floor_space.empty(): return null
#
#	var instance = Res.get_node(object).instance()
#	var k = floor_space.keys()[randi() % floor_space.keys().size()]
#
#	instance.position = k + Vector2(40,40)
#	floor_space.erase(k)
#	dungeon.get_parent().add_child(instance)
#
#	return instance

#func place_treasure_into_maze(what, how_many):
#	for nmb in range(how_many):
#		if floor_space.empty(): break
#
#		var ug_inst = what.instance()
#		var i = randi()%floor_space.size()
#		var temp = floor_space[i]+ Vector2(40,40)
#		floor_space.remove(i)
#
#		ug_inst.position = temp
#		ug_inst.item = 17
#
#		if what == Res.get_node("Objects/Chest"):
#			ug_inst.item = randi()%4 + 28
#
#		dungeon.get_parent().add_child(ug_inst)
#		if (what == Res.get_node("Objects/Barrel") and randi()%6 == 0) : ##hack ;_;
#			ug_inst.item = randi()%2

func get_possible_segments(spot):
	var pos = spot.pos
	var dir = -1
	if spot.has("dir"): dir = spot.dir
	
	var segments = []
	
	for segment in Res.segments.values():
		var offset = Vector2()
		if dir > -1:
			var ways = segment["ways" + str(OPPOSITE[dir])]
			
			for i in range(ways.size()):
				if !ways[i]: continue
				offset = [Vector2(-i, -segment.height + 1), Vector2(0, -i), Vector2(-i, 0), Vector2(-segment.width + 1, -i)][dir]
				
				if can_fit(segment, pos + offset):
					segments.append({"offset": offset, "segment": segment})
		else:
			if can_fit(segment, pos):
				segments.append({"offset": offset, "segment": segment})
	
	return segments

func can_fit(segment, pos):
	var can_be = true
	
	for i in range(4):
		var dim = ["width", "height"][i%2]
		var dim2 = ["width", "height"][1-i%2]
		var piece = ["piece_x", "piece_y"][i%2]
		
		for k in range(segment[dim]):
			var way = segment["ways" + str(i)][k]
			var p = pos + DIRECTIONS[i] * [1, segment[dim2], segment[dim2], 1][i] + DOFFSET[i%2] * k
			var seg = get_segment_data(p)
			
			if way and (p.x < 0 or p.y < 0 or p.x >= width or p.y >= width): can_be = false
			if seg and seg.segment["ways" + str(OPPOSITE[i])][seg[piece]] != way: can_be = false
			
			if !can_be: break
		if !can_be: break
	if !can_be: return false
	
	for x in range(segment.width):
		for y in range(segment.height):
			var p = pos + Vector2(x, y)
			if p.x < 0 or p.y < 0 or p.x >= width or p.y >= width or get_segment(p):
				can_be = false
	
	return can_be

func get_segment(pos):
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height: return
	if !map[pos.x + pos.y * width]: return null
	
	return map[pos.x + pos.y * width].segment

func get_segment_data(pos):
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height: return
	if !map[pos.x + pos.y * width]: return null
	
	return map[pos.x + pos.y * width]

func set_segment(pos, segment):
	for x in range(segment.width):
		for y in range(segment.height):
			map[pos.x + x + (pos.y + y)  * width] = {"segment": segment, "piece_x": x, "piece_y": y, "pos_x": pos.x, "pos_y": pos.y}
	
	segments.append({"segment": segment, "pos_x": pos.x, "pos_y": pos.y})

func find_floor_spot(spot):
	if floor_space.has(spot): return true

func remove_segment(segment):
	for x in range(segment.segment.width):
		for y in range(segment.segment.height):
			map[segment.pos_x + x + (segment.pos_y + y)  * width] = null
	
	empty_spots.append({"pos": Vector2(segment.pos_x, segment.pos_y)})
	segments.erase(segment)

func create_segment(segment, pos):
	var seg = Res.segment_nodes[segment].instance()
	var bottom = seg.get_node("BottomTiles")
	var top = seg.get_node("TopTiles")
	
	bottom.tile_set = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.tile_set = load("res://Resources/Tilesets/" + Res.dungeons[dungeon_name]["tileset"] + ".tres")
	top.set_collision_layer_bit(3, true)
	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)
	var no_objects = get_segment_data(pos).segment.has("no_objects")
	
	var wallTileId  = bottom.tile_set.find_tile_by_name("WallMarkerUp") 
	var floorTileID = bottom.tile_set.find_tile_by_name("FloorMarker")
#
#	for cell in bottom.get_used_cells():
#		var poss = Vector2(pos.x*SEG_W, pos.y*SEG_H) + cell * 80
#		var celll = {"no_walls": true}
#
#		match bottom.get_cellv(cell):
#			floorTileID:
#				for i in range(4):
#					var dcell = cell + DIRECTIONS[i]
#					if bottom.get_cellv(dcell) != 19:
#						celll.no_walls = false
#						if i == 0 and cell.y > 0: celll.top_wall = true
#						elif i == 1 and cell.x < 9: celll.right_wall = true
#						elif i == 2 and cell.y < 9: celll.bottom_wall = true
#						elif i == 3 and cell.x > 0: celll.left_wall = true
#
#				if !no_objects: floor_space[poss] = celll
#				pass
#			wallTileId : if !no_objects: wall_space.append(Vector2(pos.x*SEG_W, pos.y*SEG_H) + cell * 80)
#
	dungeon.add_child(seg)
	
	if splitted_obj == null:
		seg.generate(Res.dungeons["Mechanic"], "Mechanic", splitted_obj, str(DungeonState.current_floor-1), Res.enemies)
		splitted_obj = seg.get_splitted_elements()
	else:
		seg.generate(Res.dungeons["Mechanic"], "Mechanic", splitted_obj, str(DungeonState.current_floor-1), Res.enemies)
	
	if seg.has_node("Objects"):
		for i in range(seg.get_node("Objects").get_child_count()):
			var node = seg.get_node("Objects").get_child(0)
			var npos = node.global_position
			seg.get_node("Objects").remove_child(node) ##może nie działać dla kilku
			dungeon.get_parent().add_child(node)
			node.global_position = npos
	
	return seg

func reset():
	empty_spots.clear()
	segments.clear()
	map.clear()
	floor_space.clear()
	wall_space.clear()
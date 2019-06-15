extends Node

var DIRECTIONS	   = [ "L", "R", "U", "D" ]
var O_DIRECTION	  = { "L":"R", "R":"L", "U":"D", "D":"U" }
var POS_CHANGE	   = { "L": [-1, 0], "R": [1,0], "U": [0,-1], "D":[0,1]}


var locked_positions = {}
var graph		= {}
var empty_spots	  = []
	
var require_size	 = 35
var min_size	 = 20
#var dump		 = open("dump1", "w")

func _ready():
	_reset()

func _reset():
	graph.clear()
	empty_spots.clear()
	locked_positions.clear()
	locked_positions = {}
	empty_spots	  = []
	graph		= {}


func shuffleList(list):
    var shuffledList = []
    var indexList = range(list.size())
    for i in range(list.size()):
        randomize()
        var x = randi()%indexList.size()
        shuffledList.append(list[x])
        indexList.remove(x)
        list.remove(x)
    return shuffledList
	
func generate():
	_reset()
	
	
	var start = [ randi() % 15, randi() % 15 ]
	empty_spots.append({"pos": start, "is_start": true})

	while len(empty_spots) > 0:
#		print( len(graph) )
		empty_spots = shuffleList(empty_spots)
		var next_spot = empty_spots[0]

		var segments = _get_posible_segments(next_spot)
		segments = shuffleList(segments)

		_lock_segment(   segments[0][0], next_spot, segments[0][1] )
		_add_new_points( segments[0][0], next_spot, segments[0][1] )

#	print_locked()
	#	for i in graph: print( graph[i] )

func _get_all_segments():
	var segments = []
	for segment in segment_list:
		if not segment["is_deadend"]: segments.append( [ segment, [0,0] ])
	return segments

func _get_posible_segments( spot):
	if spot["is_start"]: return _get_all_segments()

	var segments = []
	for segment in segment_list:
		if require_size <= len(graph) and not segment["is_deadend"]: continue
		if min_size	 >= len(graph) and segment["is_deadend"] : continue
		var positions = _get_matching_pos( segment, spot["dir"] )
		for position in positions:
			if can_fit_by_size(segment["shape"], spot, position) and can_fit_by_neighbours(segment, spot, position):
				segments.append( [segment, position] )

	if len( segments ) == 0: 
		var found_one = false
		for segment in segment_list:
			if not found_one: 
				var positions = _get_matching_pos( segment, spot["dir"] )
				for position in positions:
					if can_fit_by_neighbours(segment, spot, position) and can_fit_by_size(segment["shape"], spot, position):
						segments.append( [segment, position] )
						found_one = true

	return segments

func can_fit_by_neighbours(segment, spot, position): 
	var scale = [ spot["pos"][0] - int(position[0]), spot["pos"][1] - int(position[1]) ]

	for entry in segment["shape"]:
		var t = entry.split(",")
		var pos = [ scale[0] + int(t[0]),  scale[1] + int(t[1]) ]

		if len(segment["shape"][entry]) == 0:
			for d in DIRECTIONS:
				var str_pos = [ pos[0] + POS_CHANGE[d][0], pos[1] + POS_CHANGE[d][1]]
				for enter in empty_spots:
					if str_pos == enter["pos"] : return false

		for d in segment["shape"][entry]:
			var str_pos = str( pos[0] + POS_CHANGE[d][0]) + "," + str( pos[1] + POS_CHANGE[d][1])

			if str_pos in locked_positions.keys():
				if not O_DIRECTION[d] in locked_positions[str_pos] : return false
				if len(locked_positions[str_pos]) == 0 : return false

	return true

func _get_matching_pos(segment, directions):
	var positions = []

	for place in segment["shape"].keys():
		var matches = true
		for d in directions:
			if not d in segment["shape"][place]: matches = false
		if matches:
			var p = place.split(",")
			positions.append( [int(p[0]), int(p[1])] )

	return positions

func create_segment(): return null

func _add_points_by_directions( directions, spot):
	for direction in directions:
		var new_spot = [ spot[0] + POS_CHANGE[direction][0], spot[1] + POS_CHANGE[direction][1]]

		if str(new_spot[0]) + "," + str(new_spot[1]) in locked_positions.keys(): continue

		var need_add = true
		for spot2 in empty_spots:
			if spot2["pos"] == new_spot:
				spot2["neighbours"].append(len(graph) - 1)
				spot2["dir"].append( O_DIRECTION[direction] )
				need_add = false

		if need_add:
			var nn =  {"pos"	   : new_spot,
				"is_start"  : false,
				"neighbours": [len(graph) -1],
				"dir"	   : [O_DIRECTION[direction]]
				}
			empty_spots.append(nn)

func _add_new_points(  segment, spot, seg_shift): 
	for s in segment["shape"]:
		if segment["shape"][s] == "": continue
		var t = s.split(",")
		var new_spot = [ spot["pos"][0] + int(t[0]) - seg_shift[0], spot["pos"][1] + int(t[1]) - seg_shift[1]]
		_add_points_by_directions( segment["shape"][s], new_spot )

func _lock_segment(    segment, spot, seg_shift): 

	var LU_corner = [ spot["pos"][0] - seg_shift[0], spot["pos"][1] - seg_shift[1] ]

	graph[len(graph)] = {
		"id"	    : len(graph),
		"name"      : segment.name,
		"position"  : LU_corner,
		"neighbours": []
	}

	if not spot["is_start"]:
		for neigh in spot["neighbours"]:
			graph[ neigh ][ "neighbours" ].append( len(graph)-1 )
			graph[ len(graph)-1 ]["neighbours"] +=  spot["neighbours"]


	for place in segment["shape"].keys():
		var p = place.split(",")
		var str_place = str(LU_corner[0]+int(p[0])) + "," + str(LU_corner[1]+int(p[1]))
		_remove_from_free_spots( [LU_corner[0] + int(p[0]), LU_corner[1] + int(p[1]) ])
		locked_positions[str_place] = segment["shape"][place]

func _remove_from_free_spots( to_check):

	for spot in empty_spots:
		if spot["pos"] == to_check: 
			empty_spots.erase(spot)
			return

func can_fit_by_size(shape, free_spot, position):

	var scale = [ free_spot["pos"][0]-position[0], free_spot["pos"][1]-position[1] ] 


	for point in shape.keys():
		var p   = point.split(",")
		var arr = [ int(p[0]) + scale[0], int(p[1]) + scale[1]]
		if str(arr[0]) + "," + str(arr[1]) in locked_positions.keys() : return false

		for empty_spot in empty_spots:
			if arr == empty_spot["pos"] :
				for requirement in empty_spot["dir"]:
					if not requirement in shape[point] : return false

	return true

func is_correct():
	var correct = true
	for locked in locked_positions.keys():
		for direction in locked_positions[locked]:
			var l = locked.split(",")
			var pos = str(int(l[0]) + POS_CHANGE[direction][0]) + "," + str(int(l[1]) + POS_CHANGE[direction][1])
			if pos in locked_positions.keys(): 
				if not O_DIRECTION[direction] in locked_positions[pos] : correct = false
			else : correct = false
			
	if len(graph) < min_size : return false
	return correct

func print_locked():
	var s = ""

	var ranges = [99999, -99999, 99999, -99999]

	for key in locked_positions.keys():
		var p = key.split(",")
		if int(p[0]) < ranges[0] : ranges[0] = int(p[0]) 
		if int(p[0]) > ranges[1] : ranges[1] = int(p[0])
		if int(p[1]) < ranges[2] : ranges[2] = int(p[1]) 
		if int(p[1]) > ranges[3] : ranges[3] = int(p[1])

	for x in range( ranges[2] - 1, ranges[3] + 2):
		for y in range(  ranges[0] - 1, ranges[1] + 2):
			if not str(y) + "," + str(x) in locked_positions.keys(): 
				s += "XXXX "
				continue
			s += (locked_positions[str(y) + "," + str(x)] + "      ").substr(0,5)
		s+="\n"
	print( s )
#	dump.write(s)

var segment_list = [
		{ #C1x1H
			"name"       : "Corridor1x1H",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "LR"
			}
		},
		{ #C1x1V
			"name"       : "Corridor1x1V",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "UD"
			}
		},
		{ #C1x1VCraft
			"name"       : "Corridor1x1VCrafting",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "UD"
			}
		},
		{ #C1x2VSmash
			"name" : "Corridor1x2Smash",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "U",
				"0,1" : "D"
			}       
		},
		{ #C3x1VGhost
			"name" : "Corridor3x1Ghost",
			"is_deadend" : false,
			"shape"      : {
				"0,2" : "U",
				"0,0" : "D",
				"0,1" : ""
			}       
		},
		{ #C1x1DL
		"name" : "Curve1x1DL",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "DL"
			}
		},
		{ #C1x1DR
		"name" : "Curve1x1DR",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "DR"
			}
		},
		{ #C1x1UL
		"name" : "Curve1x1UL",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "UL"
			}
		},
		{ #C1x1UR
		"name" : "Curve1x1UR",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "UR"
			}
		},

		{ #C2x2UL
		"name" : "Curve2x2UL",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "U",
				"1,0" : "",
				"0,1" : "L",
				"1,1" : "",
			}
		},
		{ #D1x1D
		"name" : "DeadEnd1x1D",
			"is_deadend" : true,
			"shape"      : {
				"0,0" : "D"
			}
		},
		{ #D1x1U
		"name" : "DeadEnd1x1L",
			"is_deadend" : true,
			"shape"      : {
				"0,0" : "R"
			}
		},
		{ #D1x1R
		"name" : "DeadEnd1x1R",
			"is_deadend" : true,
			"shape"      : {
				"0,0" : "L"
			}
		},
		{ #D1x1L
		"name" : "DeadEnd1x1U",
			"is_deadend" : true,
			"shape"      : {
				"0,0" : "U"
			}
		},
		{ #D2x2D
		"name" : "DeadEnd2x2D",
			"is_deadend" : true,
			"shape"      : {
				"0,0" : "U",
				"1,0" : "",
				"0,1" : "",
				"1,1" : "",
			}
		},
		{ #J1x1DLUR
		"name" : "Junction1x1",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "DLRU"
			}
		},
		{ #J1x1HD
		"name" : "Junction1x1HD",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "RLD"
			}
		},
		{ #J1x1HU
		"name" : "Junction1x1HU",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "URL"
			}
		},
		{ #J1x1VL
		"name" : "Junction1x1VL",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "DLU"
			}
		},
		{ #J1x1VR
		"name" : "Junction1x1VR",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "DRU"
			}
		},
		{ #D2x1LSecret
		"name" : "Secret2x1L",
			"is_deadend" : true,
			"shape"      : {
				"1,0" : "R",
				"0,0" : ""
			}
		},
		{ #T2x1UU
		"name" : "Turn2x1U",
			"is_deadend" : false,
			"shape"      : {
				"0,0" : "D",
				"1,0" : "D"
			}
		}
	]
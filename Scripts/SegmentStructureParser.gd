extends Node


var s = null
var Astar_points = []

func _ready(): pass

func parse(segment):
	s = segment.instance()
	print(s.get_node("BottomTiles").get_used_rect() )
	initialize()
	return [shape, Enters]


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

var tile_exit_id  = 0
var tile_free_id  = 0
var tile_const_id = 0
var tile_blocked_id =0
var used_rect     = null
var shape         = []
var Enters        = []
var structure     = []


func get_tile_ids_from_TileSet():
    tile_exit_id    = s.get_node("BottomTiles").tile_set.find_tile_by_name("FloorE")
    tile_free_id    = s.get_node("BottomTiles").tile_set.find_tile_by_name("FloorF")
    tile_const_id   = s.get_node("BottomTiles").tile_set.find_tile_by_name("FloorC")
    tile_blocked_id = s.get_node("BottomTiles").tile_set.find_tile_by_name("FloorS")
    
func initialize():
    used_rect = s.get_node("BottomTiles").get_used_rect()
    get_tile_ids_from_TileSet()
    covert_tiles_to_structure()



func covert_tiles_to_structure():

	
#	var time_start = OS.get_unix_time()
    
    for i in range(used_rect.end.x+2):
        var cell = []
        for j in range(used_rect.end.y+2):
            if  s.get_node("BottomTiles").get_cell(i,j) == tile_free_id :
                cell.append(TileState.free)
            elif s.get_node("BottomTiles").get_cell(i,j) == tile_exit_id :
                cell.append(TileState.exitTile)
                Enters.append([i,j])
            elif s.get_node("BottomTiles").get_cell(i,j) == tile_const_id :
                cell.append(TileState.constObject)
            elif s.get_node("BottomTiles").get_cell(i,j) == tile_blocked_id :
                cell.append(TileState.blockedTile)
            else:
                cell.append(TileState.noTile)
        shape.append(cell)
        
    mark_walls()
    
    for i in shape:
        var cell = []
        for j in i:
            cell.append(j)
        structure.append(cell)	
        
#	var time_now = OS.get_unix_time()
#	print( "mark_functions : ", (time_now - time_start)) 
        

func mark_walls():
    for i in range(used_rect.end.x+2):
        for j in range(used_rect.end.y+2):
            mark_wall_left (i,j)
            mark_wall_right(i,j)
            mark_wall_up   (i,j)
            mark_wall_down (i,j)
    correct_enter_wall()

func mark_wall_left(i,j):
    if i > 0:
        if shape[i][j] == TileState.free and shape[i-1][j] == TileState.noTile:
            shape[i][j] = TileState.wallLeft
        elif shape[i][j] == TileState.wallDown and shape[i-1][j] == TileState.noTile:
            shape[i][j] = TileState.wallLeftDown
        elif shape[i][j] == TileState.wallUp and shape[i-1][j] == TileState.noTile:
            shape[i][j] = TileState.wallLeftUp

func mark_wall_right(i,j):
    if i < used_rect.end.x:
        if shape[i][j] == TileState.free and shape[i+1][j] == TileState.noTile:
            shape[i][j] = TileState.wallRight
        elif shape[i][j] == TileState.wallDown and shape[i+1][j] == TileState.noTile:
            shape[i][j] = TileState.wallRightDown
        elif shape[i][j] == TileState.wallUp and shape[i+1][j] == TileState.noTile:
            shape[i][j] = TileState.wallRightUp
    
func mark_wall_up(i,j):
    if j < used_rect.end.y:
        if shape[i][j] == TileState.free and shape[i][j+1] == TileState.noTile:
            shape[i][j] = TileState.wallUp
        elif shape[i][j] == TileState.wallLeft and shape[i][j+1] == TileState.noTile:
            shape[i][j] = TileState.wallLeftUp
        elif shape[i][j] == TileState.wallRight and shape[i][j+1] == TileState.noTile:
            shape[i][j] = TileState.wallRightUp
        
func mark_wall_down(i,j):
    if j > 0:
        if shape[i][j] == TileState.free and shape[i][j-1] == TileState.noTile:
            shape[i][j] = TileState.wallDown
        elif shape[i][j] == TileState.wallLeft and shape[i][j-1] == TileState.noTile:
            shape[i][j] = TileState.wallLeftDown
        elif shape[i][j] == TileState.wallRight and shape[i][j-1] == TileState.noTile:
            shape[i][j] = TileState.wallRightDown

func correct_enter_wall():

    for x in range(used_rect.end.x+2):
        for y in range(used_rect.end.y+2):
            
            if y < used_rect.end.y:
                if shape[x][y] == TileState.noTile and (shape[x][y+1] >= TileState.free and shape[x][y+1] < TileState.blockedTile) and shape[x][y+2] == TileState.exitTile:
                    shape[x][y+1] = TileState.wallDown
    
                if shape[x][y] == TileState.exitTile and (shape[x][y+1] >= TileState.free and shape[x][y+1] < TileState.blockedTile) and shape[x][y+2] == TileState.noTile:
                    shape[x][y+1] = TileState.wallUp
                    
            if x < used_rect.end.x:
                if shape[x][y] == TileState.noTile and (shape[x+1][y] >= TileState.free and shape[x+1][y] < TileState.blockedTile) and shape[x+2][y] == TileState.exitTile:
                    shape[x+1][y] = TileState.wallLeft
    
                if shape[x][y] == TileState.exitTile and (shape[x+1][y] >= TileState.free and shape[x+1][y] < TileState.blockedTile) and shape[x+2][y] == TileState.noTile:
                    shape[x+1][y] = TileState.wallRight
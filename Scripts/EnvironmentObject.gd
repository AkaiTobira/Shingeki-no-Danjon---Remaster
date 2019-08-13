extends Node2D

enum PLACEMENT{ EVERY_WALL, LEFT_OR_RIGHT_WALL, UP_OR_DOWN_WALL, UP_WALL, DOWN_WALL ,WALL_FREE }

export(PLACEMENT) var placement
export var offset_position = Vector2(0, 0)
export var size = Vector2(1, 1)
export var variants = ""
export(bool) var can_flip_h
export var const_object = true
export(bool) var randomize_speed_of_animation 
export var need_enemies_list = false


export(bool) var need_second_wall
export(bool) var need_more_space

enum STATE{ CONST, DESTROYABLE, CHESTS }

export(STATE) var state = 0

var block_animation = false

var setted          = false

func reset() :
	if not setted:
		setted = true
		if has_node("Sprite10"):
			if $"Sprite10".flip_h    !=  $"Sprite".flip_h:	
				$"Sprite".offset     += Vector2(6,0)
				$"Sprite10".position += Vector2(50,0)
				$"Sprite10".flip_h    = $"Sprite".flip_h
				if $"Sprite10".visible == false: return

func disable_collisions(): pass

var my_id = -1

func initialize(id, dungeon_name, my_name, dungeon_level = 0, flip = false):
	my_id = id
	
	if has_node("Animation") and const_object and not block_animation:
		var anim = $Animation.get_animation_list()
		if len(anim) > 0 :
			#if randi()%2 == 0:
			$Animation.play(anim[randi()%(len(anim))],-1,1, randi()%2==0)
			$Animation.advance(randi()% ( int($Animation.current_animation_length )) )
			if randomize_speed_of_animation:
				$Animation.playback_speed = (randi()%9 + 12)

	if has_node("Sprite"):
		get_node("Sprite").flip_h  = flip
	if has_node("Sprite2"):
		get_node("Sprite2").flip_h = flip

	if has_node("Sprite10"):
		if $"Sprite10".flip_h    !=  $"Sprite".flip_h:	
			$"Sprite".offset     += Vector2(6,0)
			$"Sprite10".position += Vector2(50,0)
			$"Sprite10".flip_h    = $"Sprite".flip_h
			$"Shape".position     = Vector2(21.534, 11.652)
			if $"Sprite10".visible == false: return

func _build_wall( tab = [] ): pass
	#if has_node("Node2D/Sprite") and has_node("CollisionR"):
	#	get_node("CollisionR").disabled = false
	#	get_node("CollisionL").disabled = false
#
	#	if randi()%2 and tab[2]:
	#		$Node2D/Up/Sprite.visible = false
	#	if randi()%2 and tab[0]:
	#		$Node2D/Left/Sprite.visible = false
	#		get_node("CollisionL").disabled = true
	#	if randi()%2 and tab[1]:
	#		$Node2D/Right/Sprite.visible = false
	#		get_node("CollisionR").disabled = true
	#	if randi()%2 and tab[3]:
	#		$Node2D/Back/Sprite.visible = false

	#if $Node2D/Back/Sprite.visible == false:
	#	$CollisionShape2D.scale = Vector2(1.781887,2.901224)
#	$CollisionShape2D.position = Vector2(3.621228,-16.660124)

func build_trap_arms( enabled_tiles_size ): #TODO


#	if has_node("Node2D/Sprite") and has_node("CollisionR"):
	get_node("CollisionR").disabled = false
	get_node("CollisionL").disabled = false
		
	if enabled_tiles_size[2] < 3:
		$Node2D/Up/Sprite.visible      = false
	if enabled_tiles_size[1] < 3:
		$Node2D/Left/Sprite.visible     = false
		get_node("CollisionL").disabled = true
	if enabled_tiles_size[0] < 3:
		$Node2D/Right/Sprite.visible    = false
		get_node("CollisionR").disabled = true
	if enabled_tiles_size[3] < 3:
		$Node2D/Back/Sprite.visible     = false

	if $Node2D/Back/Sprite.visible == false:
		$CollisionShape2D.scale = Vector2(1.781887,2.901224)
		$CollisionShape2D.position = Vector2(3.621228,-16.660124)

func _change_sprite( tileset_name = "Default" ):
	#Res.dungeons[dungeon_name]["tileset"]
	if tileset_name == "Dungeon":
		pass
	elif tileset_name == "SteamPunk":
		pass
#		$"Sprite".texture = load("res://Sprites/Objects/CrushingWallsSteel.png")
#		$"Sprite2".frame = 1
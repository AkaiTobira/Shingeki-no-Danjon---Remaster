extends Node2D

enum PLACEMENT{ EVERY_WALL, LEFT_OR_RIGHT_WALL, UP_OR_DOWN_WALL, UP_WALL, DOWN_WALL ,WALL_FREE }

export(PLACEMENT) var placement
export var offset_position = Vector2(0, 0)
export var size = Vector2(1, 1)
export var variants = ""
export(bool) var can_flip_h
export var const_object = true
export(bool) var randomize_speed_of_animation 

enum STATE{ CONST, DESTROYABLE, CHESTS }

export(STATE) var state = 0
#
func _ready():
	if has_node("Sprite10"):
		if $"Sprite10".flip_h !=  $"Sprite".flip_h:	
			$"Sprite".offset += Vector2(6,0)
			$"Sprite10".position += Vector2(50,0)
			$"Sprite10".flip_h = $"Sprite".flip_h
			if !$"Sprite10".visible:
				$"Animation".stop()
				return
	
	if has_node("Animation") and const_object:
		var anim = $Animation.get_animation_list()
		if len(anim) > 0 :
			$Animation.play(anim[randi()%(len(anim))])
			$Animation.advance(randi()% ( int($Animation.current_animation_length )) )
			if randomize_speed_of_animation:
				$Animation.playback_speed = (randi()%9 + 12)
	pass
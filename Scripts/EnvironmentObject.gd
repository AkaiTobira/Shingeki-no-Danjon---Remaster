extends Node2D

enum PLACEMENT{ EVERY_WALL, LEFT_OR_RIGHT_WALL, UP_OR_DOWN_WALL, WALL_FREE }

export(PLACEMENT) var placement = 0
export var offset_position = Vector2(0, 0)
export var size = Vector2(1, 1)
export var variants = ""
export var can_flip_h = false
export var const_object = true
export(bool) var randomize_speed_of_animation 

enum STATE{ CONST, DESTROYABLE, CHESTS }

export(STATE) var state = 0
#
func _ready():
	if has_node("Animation") and const_object:
		var anim = $Animation.get_animation_list()
		if len(anim) > 0 :
			$Animation.play(anim[randi()%(len(anim))])
			$Animation.advance(randi()% ( int($Animation.current_animation_length )) )
			if randomize_speed_of_animation:
				$Animation.playback_speed = (randi()%9 + 12)
	pass
extends "res://Scripts/BaseEnemy.gd"

func _ready():
	._ready()
	drops.append([3,  500 ])
	drops.append([19, 500 ])
	#MAT.set_shader_param("ucolor", Color(1, 1, 1))

func _process(delta):
	
	if current_state == "Dead":
		meansure_dead_timeout(delta)
		return

	if current_state == "Wait":
		play_animation_if_not_playing("Idle")
		return

	if current_state == "Follow" and !block_logic:
		prepeare_ability()
		
		_move5(delta)

		if current_atack == "Wait":
			if is_close_enought():
				if   ability_ready[ABILITY_TYPE["Magic"]] and can_use_ability[ABILITY_TYPE["Magic"]]:
					_magic()
				elif ability_ready[ABILITY_TYPE["Skill"]] and can_use_ability[ABILITY_TYPE["Skill"]]:
					_skill()
				elif ability_ready[ABILITY_TYPE["Atack"]] and can_use_ability[ABILITY_TYPE["Atack"]]:
					_atack()
		else:
			if ameansure_preparation_timeout( delta ):
				process_atacks()
				block_logic = true
				pass

func process_atacks():
	match(current_atack):
		"Magic":
			#play_animation_if_not_played()
			return
		"Skill":
			play_animation_if_not_playing("Special")
			return
		"Atack":
			play_animation_if_not_playing("Punch" + direction)
			return


func _on_Radar_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"
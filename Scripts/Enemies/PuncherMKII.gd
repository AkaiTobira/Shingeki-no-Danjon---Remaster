extends "res://Scripts/BaseEnemy.gd"

func _ready():
	._ready()

func _physics_process(delta):
	
	if current_state == "Dead":
		meansure_dead_timeout(delta)
		return

	if current_state == "Wait":
		play_animation_if_not_playing("Idle")
		return

	if current_state == "Charge":
		play_animation_if_not_playing("Special")
		Res.play_sample(self, music["Special"])
		move_to_nav_point(delta)

	if current_state == "Follow" and !block_logic:
		prepeare_ability()

		_move5(delta)

		if current_atack == "Wait":
			if is_close_enought():
				if   ability_ready[ABILITY_TYPE["Magic"]] and can_use_ability[ABILITY_TYPE["Magic"]] and !magic_active:
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
			.turn_on_magic_state()
			return
		"Skill":
			play_animation_if_not_playing("Special")
			Res.play_sample(self, music["Special"])
			
			calculate_special_atack()
			
			return
		"Atack":
			play_animation_if_not_playing("Punch" + direction)
			Res.play_sample(self, music["Normal"])
			return



var special_nav_poit

func move_to_nav_point(delta):
		var extra_movesped = movespeed + 60 
		var move = Vector2(sign(special_nav_poit.x - position.x), sign(special_nav_poit.y - position.y)).normalized() * movespeed * delta
		
		var x_player_monster_distance = abs(position.x - player.position.x)
		var y_player_monster_distance = abs(position.y - player.position.y) 

		var x_distance = abs(position.x - special_nav_poit.x)
		var y_distance = abs(position.y - special_nav_poit.y) 

		if( x_distance < move.x*extra_movesped ): move.x = x_distance/extra_movesped
		if( y_distance < move.y*extra_movesped ): move.y = y_distance/extra_movesped
		
		#if( axix_X and axix_Y):
		move_and_slide(move * extra_movesped)
		
		if move.length() < 0.1:
			 current_state = "Follow"
#
#
#
#func in_special_state(delta):
#	 play_animation_if_not_playing("Special")
#	 move_to_nav_point(delta)
#
#



func calculate_special_atack():
	block_logic = true
	current_state = "Charge"

	special_nav_poit    = player.position
	special_nav_poit.x += (player.position.x - position.x)# if player.position.x > position.x else (- position.x + player.position.x)
	special_nav_poit.y += (player.position.y - position.y)
	
	path = []
	
#	if player.position.y > position.y:
#		special_nav_poit.y = player.position.y + (player.position.y - position.y)
#	else:
#		special_nav_poit.y = player.position.y - (position.y - player.position.y)



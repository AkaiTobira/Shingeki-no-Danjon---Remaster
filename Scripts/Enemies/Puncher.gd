extends "res://Scripts/BaseEnemy.gd"

func _physics_process(delta):
	
	if current_state == "Dead":
		meansure_dead_timeout(delta)
		return

	if current_state == "Wait":
		play_animation_if_not_playing("Idle")
		return

	if current_state == "Follow" and !block_logic:
		_player_run_away()
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

func _ready():
	._ready()


func process_atacks():
	if current_state == "Dead": return 
	
	match(current_atack):
		"Magic":
			#play_animation_if_not_played()
			return
		"Skill":
			play_animation_if_not_playing("Special")
			Res.play_sample(self, music["Special"])
			return
		"Atack":
			play_animation_if_not_playing("Punch" + direction)
			Res.play_sample(self, music["Normal"])
			return
			
#func calculate_move(delta):
#		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
#
#		var x_distance = abs(position.x - player.position.x)
#		var y_distance = abs(position.y - player.position.y) 
#
#		var axix_X = x_distance >= PERSONAL_SPACE
#		var axix_Y = y_distance >= PERSONAL_SPACE
#
#		if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
#		if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
#
#		if (axix_X or axix_Y):
#			move_and_slide(move * SPEED )#+ test_move*SPEED)
#			if( position == prevPos ):
#
#				var temp
#				if (  abs(move.x) > abs(move.y) ):
#					temp = move.x
#				else:
#					temp = move.y
#
#
#				test_move = Vector2( temp *SPEED,temp*SPEED )  ;
#
#				if( test_move(Transform2D(), test_move*SPEED )):
#					test_move = Vector2(0,0)
#
#					pass
#				#print(position, move*SPEED*delta)
#			else:
#				prevPos = position
#
#
#		if( x_distance > y_distance and axix_X ):
#			if abs(move.x) != 0: 
#				sprites[0].flip_h = move.x > 0
#				play_animation_if_not_playing("Left")
#				last_animation = "Left"
#				direction = "Right" if move.x > 0 else "Left"
#		elif(x_distance < y_distance and axix_Y):
#			if move.y < 0: 
#				play_animation_if_not_playing("Down")
#				last_animation = "Down"				
#				direction = "Down"
#			elif move.y > 0: 
#				play_animation_if_not_playing("Up")
#				last_animation = "Up"			
#				direction = "Up"
#		else:
#			play_animation_if_not_playing(last_animation)
#			pass
#
#
#		#if axix_X:
#		#	if abs(move.x) != 0: 
#
#		#		sprites[0].flip_h = move.x > 0
#		#		play_animation_if_not_playing("Left")
#		#		direction = "Right" if move.x > 0 else "Left"
##				elif move.x > 0: play_animation_if_not_playing("Right") na później
#		#elif axix_Y:
#		#	if move.y < 0: 
#		#		play_animation_if_not_playing("Down")
#		#		direction = "Up"
#		#	elif move.y > 0: 
#		#		play_animation_if_not_playing("Up")
#		#		direction = "Down"
#		#else:
#		#	play_animation_if_not_playing("Down")
#		#	direction = "Down"
#
#func preparation(delta):
#	if preparing :
#		flash_time += delta
#
#		kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu += 0.2
#		if int(kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu)%4 == 0:
#			for i in range(sprites.size()):
#				sprites[i].modulate = Color(10,10,10,10) if not (special_ready and can_use_special) else Color(10,1,1,10)
#		else:
#			for i in range(sprites.size()):
#				sprites[i].modulate = Color(1,1,1,1)
#

#
#func _physics_process(delta):
#	._physics_process(delta)
#
#
#	if dead :
#		calculate_dead(delta)
#		return
#
#	preparation(delta)
#
#
#	if in_special_state:
#		in_special_state(delta)
#		return
#
#	if !follow_player :
#		play_animation_if_not_playing("Idle")
#
#	if follow_player and !in_action :
#		check_atacks_prepeare()
#		test_calculate_move(delta)
#		#calculate_move(delta)
#
#		var player_monster_distance_x = abs(position.x - player.position.x) 
#		var player_monster_distance_y = abs(position.y - player.position.y) 
#
#		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
#			follow_player = false
#		#	play_animation_if_not_playing("Idle")
#
#
#		if player_monster_distance_x < 79 and player_monster_distance_y < 79:
#			if special_ready and can_use_special:
#				preparing = true
#			elif atack_ready: 
#				preparing = true
#
#
#var is_avoiding = false
#var avoid_distance = Vector2(0,0)
#var avoid_stack    = 1
#var acc = Vector2(0,0)
#var randomDirection = randi()%2
#
#
#func test_calculate_move(delta):
#	var move = Vector2(sign(player.position.x - position.x + acc.x), sign(player.position.y - position.y+ acc.y)).normalized() * SPEED * delta
#
#	var x_distance = abs(position.x - player.position.x)
#	var y_distance = abs(position.y - player.position.y) 
#
#	var axix_X = x_distance >= PERSONAL_SPACE
#	var axix_Y = y_distance >= PERSONAL_SPACE
#
#	if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
#	if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
#
#	if( x_distance > y_distance and axix_X ):
#		if abs(move.x) != 0: 
#			sprites[0].flip_h = move.x > 0
#			play_animation_if_not_playing("Left")
#			last_animation = "Left"
#			direction = "Right" if move.x > 0 else "Left"
#	elif(x_distance < y_distance and axix_Y):
#		if move.y < 0: 
#			play_animation_if_not_playing("Down")
#			last_animation = "Down"				
#			direction = "Down"
#		elif move.y > 0: 
#			play_animation_if_not_playing("Up")
#			last_animation = "Up"			
#			direction = "Up"
#	else:
#		play_animation_if_not_playing(last_animation)
#
#	if test_move( get_transform(), move  ):
#
#		match direction:
#			"Up":
#				if( ! test_move( get_transform(), Vector2( 80 , 0) ) ) and !randomDirection: #and  abs(position.x+120 + 90*acc.x/100)  - abs(player.position.x)  <= 0  :
#					acc.x += 1
#
#				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection: #and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
#					acc.x += -1
#
#			"Down":		
#
#				if( ! test_move( get_transform(), Vector2(  80 , 0) ) ) and !randomDirection:# and  abs(position.x+120-90*acc.x/100)  - abs(player.position.x)  <= 0  :
#					acc.x += 1
#
#				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection:# and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
#					acc.x += -1
#
#			"Left" :
#
#				if( ! test_move( get_transform(), Vector2(  0 , 80) ) )and !randomDirection:# and  abs(position.y+120 + 80*acc.y/100)  - abs(player.position.y)  <= 0  :
#					acc.y += 1
#
#				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection:# and  abs(position.y+120 - 80*acc.y/100) - abs(player.position.y)  >= 0 :
#					acc.y += -1
#
#
#			"Right" :
#
#				if( ! test_move( get_transform(), Vector2(  0 , 80) ) ) and !randomDirection :#and  abs(position.y+120)  - abs(player.position.y)  <= 0  :
#					acc.y += 1
#
#				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection :#and  abs(position.y+120) - abs(player.position.y)  >= 0 :
#					acc.y += -1
#
#		var repairer = Vector2(0,0)
#
#		if direction == "Left": repairer.x -=1
#		if direction == "Right": repairer.x +=1
#		if direction == "Up": repairer.y +=1
#		if direction == "Down": repairer.y -=1
#
#		move_and_slide((acc + repairer).normalized() *delta * SPEED * SPEED   )
#
#	else :
#		move_and_slide( (move + acc.normalized() *delta * SPEED) * SPEED )
#		randomDirection = randi()%2
#		acc = Vector2(0,0)
#
#func move_to_nav_point(delta):
#		var move = Vector2(sign(special_nav_poit.x - position.x), sign(special_nav_poit.y - position.y)).normalized() * SPEED * delta
#
#		var x_player_monster_distance = abs(position.x - player.position.x)
#		var y_player_monster_distance = abs(position.y - player.position.y) 
#
#		var x_distance = abs(position.x - special_nav_poit.x)
#		var y_distance = abs(position.y - special_nav_poit.y) 
#
#		if( x_distance < move.x*(SPEED+20) ): move.x = x_distance/(SPEED+20)
#		if( y_distance < move.y*(SPEED+20) ): move.y = y_distance/(SPEED+20)
#
#		#if( axix_X and axix_Y):
#		move_and_slide(move * (SPEED+20))
#
#		if move.x == 0 and move.y == 0:
#			 in_special_state = false
#
#
#
#func in_special_state(delta):
#	 play_animation_if_not_playing("Special")
#
#	 #move_to_nav_point(delta)
#
#
#
#func call_special_atack():
#	Res.play_sample(self, "SpinAttack")
#	in_action = true
#	play_animation_if_not_playing("Special")
#	damage = SPECIAL_DAMAGE
#	knockback = KNOCKBACK_ATACK
#	in_special_state = true
#
#	if player.position.x > position.x:
#		special_nav_poit.x = player.position.x + (player.position.x - position.x)
#	else:
#		special_nav_poit.x = player.position.x - (position.x - player.position.x)
#
#	if player.position.y > position.y:
#		special_nav_poit.y = player.position.y + (player.position.y - position.y)
#	else:
#		special_nav_poit.y = player.position.y - (position.y - player.position.y)
#
#	#print(special_nav_poit, position)
#
#func call_normal_atack():
#	in_action = true
#	atack_ready = false
#	punch_in_direction()
#	damage = BASIC_DAMAGE
#	knockback = 0
#





		


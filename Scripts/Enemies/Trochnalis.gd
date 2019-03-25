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

	if current_state == "Follow" and !block_logic:
		_player_run_away()
		prepeare_ability()
		
		_move5(delta)

		if current_atack == "Wait":
			if is_close_enought():
				if   ability_ready[ABILITY_TYPE["Magic"]] and can_use_ability[ABILITY_TYPE["Magic"]]:
					_magic()
				elif ability_ready[ABILITY_TYPE["Skill"]] and can_use_ability[ABILITY_TYPE["Skill"]] and health < max_health*0.25 :
					_skill()
				elif ability_ready[ABILITY_TYPE["Atack"]] and can_use_ability[ABILITY_TYPE["Atack"]]:
					_atack()
		else:
			if ameansure_preparation_timeout( delta ):
				process_atacks()
				block_logic = true
				pass


func sueside_dead():
	Res.game.player.updateQuest(enemy_name)
	
	Res.play_sample(self, "RobotCrash")
	
	current_state = "Dead"
	#current_atack = "Dead"
	block_logic   =  true
	
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true
	
	for i in range(sprites.size()):
		sprites[i].modulate = Color(1,1,1,1)

func process_atacks():
	match(current_atack):
		"Magic":
			#play_animation_if_not_played()
			return
		"Skill":
			play_animation_if_not_playing("Special")
			sueside_dead()
			Res.play_sample(self, music["Special"])
			return
		"Atack":
			play_animation_if_not_playing("Punch" + direction)
			Res.play_sample(self, music["Normal"])
			return


func _on_Radar_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"
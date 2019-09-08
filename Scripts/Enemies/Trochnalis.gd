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
			if is_close_enough():
				if actions["Magic"]["is_ready"] and actions["Magic"]["can_use"] and !magic_active:
					_use_action( "Magic" )
				elif actions["Skill"]["is_ready"] and actions["Skill"]["can_use"]:
					_use_action( "Skill" )
				elif actions["Attack"]["is_ready"] and actions["Attack"]["can_use"]:
					_use_action( "Attack" )
		else:
			if ameansure_preparation_timeout( delta ):
				process_atacks()
				block_logic = true
				pass


func sueside_dead():
	Res.game.quest_system.updateQuest(enemy_name)
	
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
		"Attack":
			play_animation_if_not_playing("Punch" + direction)
			Res.play_sample(self, music["Normal"])
			return


func _on_Radar_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"
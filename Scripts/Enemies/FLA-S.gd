extends "res://Scripts/BaseEnemy.gd"


func _ready():
	._ready()
	drops.append([18, 800])
	drops.append([23, 100 ])
	drops.append([21, 400])
	$"AnimationPlayer".play("Idle")
	MAT.set_shader_param("ucolor", Color(1, 0.4, 0.4))


func _process(delta):
	
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

		if magic_active:
			timeout_magic += delta
			if timeout_magic > 15:
				turn_off_magic_state()

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
			turn_on_magic_state()
			return
		"Skill":
			play_animation_if_not_playing("Special"+ direction)
			return
		"Atack":
			play_animation_if_not_playing("Punch" + direction)
			return

func turn_off_magic_state():
	Res.play_sample(self, "FLABuffCancel")
	$Sprites.material = null
	block_logic = true
	timeout_magic = 0.0
	magic_active = false
	
	red_color_changing = false
	
	damages_modif[ABILITY_TYPE["Atack"]] = 0
	ab_prob_modif[ABILITY_TYPE["Atack"]] = 0
	movespeed              -= 50

	for resist in resists_modif:
		resist = 0
	

	play_animation_if_not_playing("Magic", true)

func turn_on_magic_state():
	Res.play_sample(self, "FLABuff")

	play_animation_if_not_playing("Magic")
	$Sprites.material = MAT
	red_color_changing = true
	block_logic = true
	magic_active = true
	
	damages_modif[ABILITY_TYPE["Atack"]] = 12
	ab_prob_modif[ABILITY_TYPE["Atack"]] = -50
	movespeed              += 50

	for i in range(len(resists_modif)):
		resists_modif[i] = -0.2

	pass	
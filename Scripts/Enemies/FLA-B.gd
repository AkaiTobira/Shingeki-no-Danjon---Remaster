extends "res://Scripts/BaseEnemy.gd"



func _ready():
	._ready()
#	if !DEBBUG_RUN : .set_statistics(HP, XP, ARM)
	$"AnimationPlayer".play("Idle")
	
	
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

		runaway_move_behaviour(delta)

		if magic_active:
			timeout_magic += delta
			if timeout_magic > 15:
				.turn_off_magic_state()

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

			
func process_atacks():
	match(current_atack):
		"Magic":
			turn_on_magic_state()
			return
		"Skill":
			play_animation_if_not_playing("Special"+ direction)
			Res.play_sample(self, music["Special"])
			return
		"Attack":
			play_animation_if_not_playing("Punch" + direction)
			Res.play_sample(self, music["Normal"])
			return
			
var path_length = 100

func runaway_move_behaviour(delta):
	if path_length * 0.3 >= len(path) or len(path) == 1:
		path_length =  len(path)

		var x_distance = position.x - player.position.x
		var y_distance = position.y - player.position.y
		
		var distance_to_shoot_position = Vector3(0,0,0)
		
		if abs(x_distance) <= abs(y_distance):
			distance_to_shoot_position += Vector3(0,180,0) * sign(y_distance)
		else :
			distance_to_shoot_position += Vector3(180,0,0) * sign(x_distance)

		path = Map.nav.get_point_path(
			Map.nav.get_closest_point(Vector3(position.x,position.y,0)),
			Map.nav.get_closest_point(Vector3(player.position.x,player.position.y,0) + distance_to_shoot_position)
			)
	if len(path) != 0 : path.remove(0)

	move_along_path(movespeed*delta)

		#TO REFACTOR And Update
	var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * movespeed * delta
	
	var x_distance = abs(position.x - player.position.x)
	var y_distance = abs(position.y - player.position.y) 
	
	var axix_X = x_distance >= 80
	var axix_Y = y_distance >= 80
	
	if( x_distance > y_distance and axix_X ):
		if abs(move.x) != 0: 
			sprites[0].flip_h = move.x > 0
			play_animation_if_not_playing("Left")
			current_animation = "Left"
			direction = "Right" if move.x > 0 else "Left"
	elif(x_distance < y_distance and axix_Y):
		if move.y < 0: 
			play_animation_if_not_playing("Down")
			current_animation = "Down"				
			direction = "Down"
		elif move.y > 0: 
			play_animation_if_not_playing("Up")
			current_animation = "Up"			
			direction = "Up"
	else:
		play_animation_if_not_playing(current_animation)

func shoot_arrow():
	Res.play_sample(self, "Arrow")
	var projectile = Res.create_instance("Projectiles/FireArrow")
	get_parent().add_child(projectile)
	projectile.position  = position + Vector2(0, -40)  #+ Vector2(100,100)
	
	match direction:
		"Left":
			projectile.direction = 3
		"Right":
			projectile.direction = 1
		"Up":
			projectile.direction = 2
		"Down":
			projectile.direction = 0	
	
	projectile.intiated()
	projectile.damage = actions["Attack"]["damage"][0][0]

func shoot_arrows():
	Res.play_sample(self, "MultiArrow")
	var rotation = -15
	 
	var arrows = []
	for i in range(3):
		arrows.append(Res.create_instance("Projectiles/FireArrow"))
		
	for arrow in arrows:
		get_parent().add_child(arrow)
		arrow.position  = position + Vector2(0, -40)  #+ Vector2(100,100)
		
		match direction:
			"Left":
				arrow.new_dir(3)
				arrow.set_rot(-rotation)
			"Right":
				arrow.new_dir(1)
				arrow.set_rot(-rotation)
			"Up":
				arrow.new_dir(2)
				arrow.set_rot(-rotation)
			"Down":
				arrow.new_dir(0)
				arrow.set_rot(rotation)
				
		rotation += 15

	match direction:
		"Left":
			arrows[0].position -= Vector2(0,30) 
			arrows[0].set_mod( Vector2(0,-0.3) )
			arrows[2].position += Vector2(0,30)
			arrows[2].set_mod( Vector2(0,0.3) )
		"Right":
			arrows[2].position -= Vector2(0,30) 
			arrows[2].set_mod( Vector2(0,-0.3) )
			arrows[0].position += Vector2(0,30)
			arrows[0].set_mod( Vector2(0,0.3) )
		"Up":
			arrows[0].set_mod( Vector2(-0.3,0) )
			arrows[0].position -= Vector2(40,0) 
			arrows[2].set_mod( Vector2(0.3,0) )
			arrows[2].position += Vector2(40,0)
		"Down":
			arrows[0].set_mod( Vector2(-0.3,0) )
			arrows[0].position -= Vector2(30,0) 
			arrows[2].set_mod( Vector2(0.3,0) )
			arrows[2].position += Vector2(30,0)
				
	for arrow in arrows:
		arrow.intiated()
		arrow.damage = actions["Skill"]["damage"][0][0]
		
func turn_off_magic_state():
	pass
	
func turn_on_magic_state():
	pass
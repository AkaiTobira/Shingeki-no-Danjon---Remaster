extends KinematicBody2D

const DEBBUG_RUN = false
const DAMAGE_TYPE  = ["NoDamage", "Physical", "Explosion","Shock", "Crush"]
const ABILITY_TYPE = { "Atack" : 0,"Skill" : 1, "Magic" : 2 }

var can_use_ability = []
var ability_probs   = [0,0,0]
var damages         = [0,0,0]
var knockbacks      = [0,0,0]
var damage_type     = [0,0,0]
var resists         = [0,0,0,0]

var max_health = 5
var health     = 5
var experience = 5
var movespeed  = 0
var personal_space = 40
var enemy_name = ""
var last_atack_type = 0

func _load_stats(file, kind):
	enemy_name = kind

	
	max_health     = file["HP"]
	health         = file["HP"]
	movespeed      = file["Speed"]
	experience     = file["Exp"]
	personal_space = file["Range"]
	
	for abillity in ABILITY_TYPE.keys():
		can_use_ability.append(bool(file[abillity][0]))
		damages[ABILITY_TYPE[str(abillity)] ] = file[str(abillity)][1]
		knockbacks[ABILITY_TYPE[str(abillity)] ] = file[str(abillity)][2]
		ability_probs[ABILITY_TYPE[str(abillity)] ] = int(file[str(abillity)][3])
		damage_type[ABILITY_TYPE[str(abillity)] ] = DAMAGE_TYPE[file[str(abillity)][4]]

	resists = file["Resists"]

onready var health_bar = $HealthBar

var timeout_bar   = 0.0
var timeout_flash = 0.0
var timeout_dead  = 0.0


var current_state     = "Wait"
var current_atack     = "Wait"
var block_logic       = false
var current_animation = ""

onready var player = get_tree().get_root().find_node("Player", true, false)

var ability_ready = [ false, false, false ]
const TIME_TO_DISAPEARD = 4.5

func prepeare_ability():
	for abillity in ABILITY_TYPE.keys():
		if !ability_ready[ABILITY_TYPE[str(abillity)] ] and can_use_ability[ABILITY_TYPE[str(abillity)]]:  
			ability_ready[ABILITY_TYPE[str(abillity)] ]  = (randi()%ability_probs[ABILITY_TYPE[str(abillity)]] == 0)

func meansure_dead_timeout(delta):
	timeout_dead += delta
	if timeout_dead > TIME_TO_DISAPEARD: queue_free()

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)
	if fb:
		$"AnimationPlayer".play_backwards(anim)

func _physics_process(delta):
	timeout_bar -= 1
	if timeout_bar == 0: health_bar.visible = false
	
func _atack():
	current_atack = "Atack"
	last_atack_type = ABILITY_TYPE["Atack"]
	ability_ready[ABILITY_TYPE["Atack"] ] = false

func _magic():
	current_atack = "Magic"
	
	last_atack_type = ABILITY_TYPE["Magic"]
	ability_ready[ABILITY_TYPE["Magic"]] = false

func _skill():
	current_atack = "Skill"
	last_atack_type = ABILITY_TYPE["Skill"]
	ability_ready[ABILITY_TYPE["Skill"]] = false

var time = 0.0

func flash(delta):
	
	timeout_flash += delta
	time += 0.2
	if int(time)%4 == 0:
		for i in range(sprites.size()):
			if current_atack == "Atack":
				sprites[i].modulate = Color(1000,1000,1,1000) 
			elif current_atack == "Skill":
				sprites[i].modulate =  Color(10,1,1,10)
			elif current_atack == "Magic":
				sprites[i].modulate =  Color(1,10,1,10)
	else:
		for i in range(sprites.size()):
			sprites[i].modulate = Color(1,1,1,1)
	pass
	
func ameansure_preparation_timeout(delta ):
	
	flash(delta)
	
	if timeout_flash > 1.5:
		for i in range(sprites.size()):
			sprites[i].modulate = Color(1,1,1,1)
		timeout_flash = 0
		return true
	return false
	
func is_close_enought():
#	print((player.position - position).length())
	if (player.position - position).length() >  personal_space :
		return false
	return true
	
func calculate_player_position():
	pass
	
func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
	#	print( damage_type[ABILITY_TYPE[current_atack]] )
		collider.get_parent().damage(self, 
			damages[ABILITY_TYPE[current_atack]] , 
			knockbacks[ABILITY_TYPE[current_atack]],
			damage_type[last_atack_type] )

var damage = 10
var knockback = 0
var armour = 0

var is_avoiding = false
var avoid_distance = Vector2(0,0)
var avoid_stack    = 1
var acc = Vector2(0,0)
var randomDirection = randi()%2

func _move(delta):
	#	if current_state == "Dead" : return
	
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta

		var x_distance = abs(position.x - player.position.x)
		var y_distance = abs(position.y - player.position.y) 

		var axix_X = x_distance >= PERSONAL_SPACE
		var axix_Y = y_distance >= PERSONAL_SPACE

		if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
		if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED

		if (axix_X or axix_Y):
			move_and_slide(move * SPEED )#+ test_move*SPEED)
			if( position == prevPos ):

				var temp
				if (  abs(move.x) > abs(move.y) ):
					temp = move.x
				else:
					temp = move.y

				test_move = Vector2( temp *SPEED,temp*SPEED )  ;

				if( test_move(Transform2D(), test_move*SPEED )):
					test_move = Vector2(0,0)

					pass
				#print(position, move*SPEED*delta)
			else:
				prevPos = position


		if( x_distance > y_distance and axix_X ):
			if abs(move.x) != 0: 
				sprites[0].flip_h = move.x > 0
				play_animation_if_not_playing("Left")
				last_animation = "Left"
				direction = "Right" if move.x > 0 else "Left"
		elif(x_distance < y_distance and axix_Y):
			if move.y < 0: 
				play_animation_if_not_playing("Down")
				last_animation = "Down"				
				direction = "Down"
			elif move.y > 0: 
				play_animation_if_not_playing("Up")
				last_animation = "Up"			
				direction = "Up"
		else:
			play_animation_if_not_playing(last_animation)
			pass


func calculate_move_new(delta):
	var move = Vector2(sign(player.position.x - position.x + acc.x), sign(player.position.y - position.y+ acc.y)).normalized() * SPEED * delta

	var x_distance = abs(position.x - player.position.x)
	var y_distance = abs(position.y - player.position.y) 

	var axix_X = x_distance >= PERSONAL_SPACE
	var axix_Y = y_distance >= PERSONAL_SPACE

	if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
	if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED

	if( x_distance > y_distance and axix_X ):
		if abs(move.x) != 0: 
			sprites[0].flip_h = move.x > 0
			play_animation_if_not_playing("Left")
			last_animation = "Left"
			direction = "Right" if move.x > 0 else "Left"
	elif(x_distance < y_distance and axix_Y):
		if move.y < 0: 
			play_animation_if_not_playing("Down")
			last_animation = "Down"				
			direction = "Down"
		elif move.y > 0: 
			play_animation_if_not_playing("Up")
			last_animation = "Up"			
			direction = "Up"
	else:
		play_animation_if_not_playing(last_animation)

	if test_move( get_transform(), move  ):

		match direction:
			"Up":
				if( ! test_move( get_transform(), Vector2( 80 , 0) ) ) and !randomDirection: #and  abs(position.x+120 + 90*acc.x/100)  - abs(player.position.x)  <= 0  :
					acc.x += 1

				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection: #and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
					acc.x += -1

			"Down":		

				if( ! test_move( get_transform(), Vector2(  80 , 0) ) ) and !randomDirection:# and  abs(position.x+120-90*acc.x/100)  - abs(player.position.x)  <= 0  :
					acc.x += 1

				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection:# and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
					acc.x += -1

			"Left" :

				if( ! test_move( get_transform(), Vector2(  0 , 80) ) )and !randomDirection:# and  abs(position.y+120 + 80*acc.y/100)  - abs(player.position.y)  <= 0  :
					acc.y += 1

				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection:# and  abs(position.y+120 - 80*acc.y/100) - abs(player.position.y)  >= 0 :
					acc.y += -1


			"Right" :

				if( ! test_move( get_transform(), Vector2(  0 , 80) ) ) and !randomDirection :#and  abs(position.y+120)  - abs(player.position.y)  <= 0  :
					acc.y += 1

				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection :#and  abs(position.y+120) - abs(player.position.y)  >= 0 :
					acc.y += -1

		var repairer = Vector2(0,0)

		if direction == "Left": repairer.x -=1
		if direction == "Right": repairer.x +=1
		if direction == "Up": repairer.y +=1
		if direction == "Down": repairer.y -=1

		move_and_slide((acc + repairer).normalized() *delta * SPEED * SPEED   )

	else :
		move_and_slide( (move + acc.normalized() *delta * SPEED) * SPEED )
		randomDirection = randi()%2
		acc = Vector2(0,0)

func _on_damage():
	prevPos = position
	follow_player = true
	player = Res.game.player
	
	current_state = "Follow"
	
	var fx = Res.create_instance("Effects/MetalHitFX")
	fx.position = position - Vector2(0, 40)
	get_parent().add_child(fx)

func _on_animation_finished(anim_name):
#	if current_state == "Dead": return 
	
	if anim_name == "Special":
		current_atack = "Wait"
		block_logic = false
		
		in_special_state = false
		special_ready = false
		in_action     = false
	if "Punch" in anim_name:
		current_atack = "Wait"
		block_logic = false
		
		in_action     = false

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		prevPos = position
		follow_player = true;
		
		current_state = "Follow"
		
		player = body

func _on_animation_started(anim_name):
	var anim = $AnimationPlayer.get_animation(anim_name)
	
	if anim and sprites:
		var main_sprite = int(anim.track_get_path(0).get_name(1))
	
		for i in range(sprites.size()):
			sprites[i].visible = (i+1 == main_sprite)
			

func _on_dead():
	Res.game.player.updateQuest(enemy_name)
	
	Res.play_sample(self, "RobotCrash")
	dead = true
	
	current_state = "Dead"
	current_atack = "Dead"
	block_logic   =  true
	
	$"AnimationPlayer".play("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true
	
	for i in range(sprites.size()):
		sprites[i].modulate = Color(1,1,1,1)

var drops = []


var _dead = false

var preparing = false

var kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu = 0.0

var HP  = 35
var XP  = 35
var ARM = 0.1

var BASIC_DAMAGE         = 4
var SPECIAL_DAMAGE       = 7.5

var SPECIAL_PROBABILITY  = 250
var ATACK_SPEED          = 170

var SPEED                = 100

var KNOCKBACK_ATACK      = 50

var FOLLOW_RANGE         = 400
var PERSONAL_SPACE       = 60
var TIME_OF_LIYUGN_CORPS = 3


var direction       = "Down"


var can_use_special = true

onready var sprites = $Sprites.get_children()

var prevPos
var test_move = Vector2(0,0)

var MAT = load("res://Resources/Materials/ColorShader.tres")

var follow_player   = false
var in_action       = false
var special_ready   = false
var atack_ready     = true
var suesided        = false
var in_special      = false
var in_special_state = false
var magic_ready     = false 
var special_countown = 0.0
var last_animation = ""
var special_nav_poit = Vector2(0,0)
var special_destination = Vector2(0,0)

var wertical        = -1
var distance_from_player = 300
var MAGIC_PROBABILITY  = 500
var dead            = false

var special_dmg_type 
var basic_dmg_type
var flash_time = 0.0
var dead_time = 0.0




func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$"/root/Game".perma_state(self, "queue_free")
	$"AnimationPlayer".play("Idle")

func scale_stats_to( max_hp, ar ):
	armour = ar
	var t = float(health)/float(max_health)
	#print("Callculating  :: ",  t , "From :: ", health, " divided by :: ", max_health  )
	health = t*max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	max_health = max_hp
	#print( " Coll :: ", t,"  Max_HP_New :: ",  max_hp," Current_HP ::", health, " new_armour ::", ar )


func set_statistics(max_hp, given_exp, ar):
	max_health = max_hp
	health = max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	experience = given_exp 
	armour = ar




func damage(amount, source = "", type = ""):
	if _dead: return
#	if current_state == "Dead" : return

	var damage = amount

	match(type):
		"Physical":
			damage = max(1, int(amount * (1.0-resists[0])))
		"Explosion":
			damage = max(1, int(amount * (1.0-resists[1])))
		"Shock":
			damage = max(1, int(amount * (1.0-resists[2])))
		"Crush":
			damage = max(1, int(amount * (1.0-resists[3])))

	if randi()%100 < PlayerStats.critical_cnc*100 and source == "player": 
	
		damage += PlayerStats.critical_dmg
		
		Res.create_instance("DamageNumber").damage(self, str(damage)+"!", "crit")
	else:
		Res.create_instance("DamageNumber").damage(self, damage,type)
	
	health -= damage
	
	health_bar.visible = true
	health_bar.value = health
	timeout_bar = 180
	
	if health <= 0:
		$"/root/Game".save_state(self)
		_dead = true
		
		current_state = "Dead"
		
		health_bar.visible = false
		PlayerStats.add_experience(experience)

		z_index -=1

		_on_dead()

		var drop = get_drop_id()

		if drop > -1:
			var item = Res.create_instance("Item")
			item.position = position + Vector2(randi()%60-30,randi()%60-30)
			item.id = drop
			get_parent().add_child(item)
		elif randi() % 1000 < 100:
			var item = Res.create_instance("Money")
			item.position = position + Vector2(randi()%60-30,randi()%60-30)
			get_parent().add_child(item)
	else:
		_on_damage()

func get_drop_id():
	if drops.empty(): return -1
	var nil = 0
	
	var chances = {}
	for drop in drops:
		chances[drop[0]] = drop[1]
		nil += 1000 - drop[1]
	
	chances[-1] = nil
	return Res.weighted_random(chances)


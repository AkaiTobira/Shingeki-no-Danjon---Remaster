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

var resists_modif   = [0,0,0,0]
var ab_prob_modif   = [0,0,0]
var damages_modif   = [0,0,0]

var max_health = 5
var health     = 5
var experience = 5
var movespeed  = 0
var personal_space = 40
var enemy_name = ""
var last_atack_type = 0

var music 

func _load_stats(file, kind):
	enemy_name = kind

	max_health     = file["HP"     ]
	health         = file["HP"     ]
	movespeed      = file["Speed"  ]
	experience     = file["Exp"    ]
	personal_space = file["Range"  ]
	music          = file["Music"  ]
	resists        = file["Resists"]
	
	for abillity in ABILITY_TYPE.keys():
		can_use_ability.append(bool(file[abillity][0]))
		damages[ABILITY_TYPE[str(abillity)] ]       = file[str(abillity)][1]
		knockbacks[ABILITY_TYPE[str(abillity)] ]    = file[str(abillity)][2]
		ability_probs[ABILITY_TYPE[str(abillity)] ] = int(file[str(abillity)][3])
		damage_type[ABILITY_TYPE[str(abillity)] ]   = DAMAGE_TYPE[file[str(abillity)][4]]



onready var health_bar = $HealthBar

var timeout_bar   = 0.0
var timeout_flash = 0.0
var timeout_dead  = 0.0
var timeout_magic = 0.0

var current_state     = "Wait"
var current_atack     = "Wait"
var magic_active      = false
var block_logic       = false
var current_animation = ""

onready var player = get_tree().get_root().find_node("Player", true, false)
onready var Map    = get_tree().get_root().find_node("RandomMap",true,false)

var ability_ready = [ false, false, false ]
const TIME_TO_DISAPEARD = 4.5

func prepeare_ability():
	for abillity in ABILITY_TYPE.keys():
		
		if !ability_ready[ABILITY_TYPE[str(abillity)] ] and can_use_ability[ABILITY_TYPE[str(abillity)]]:  
			ability_ready[ABILITY_TYPE[str(abillity)] ]  = (
				randi()%(
					ability_probs[ABILITY_TYPE[str(abillity)]] + 
					ab_prob_modif[ABILITY_TYPE[str(abillity)]]) == 0)

func meansure_dead_timeout(delta):
	if timeout_dead == 0 : create_drop()
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
var path = []

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
	
func turn_off_magic_state():
	pass
	
func is_close_enought():
#	print((player.position - position).length())
	if (player.position - position).length() >  personal_space :
		return false
	return true
	
func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
		if current_atack == "Wait" or current_atack == "Dead": return
		collider.get_parent().damage(self, 
			damages[ABILITY_TYPE[current_atack]] + damages_modif[ABILITY_TYPE[current_atack]], 
			knockbacks[ABILITY_TYPE[current_atack]],
			damage_type[last_atack_type] )

func move_along_path(distance):
	var last_point = position
	for index in range(path.size()):
		var distance_between_points = last_point.distance_to(Vector2(path[0].x,path[0].y))
		# the position to move to falls between two points
		if distance <= distance_between_points and distance >= 0.0:
			var info = last_point.linear_interpolate(Vector2(path[0].x,path[0].y), distance / distance_between_points)
			var move_vector = (info-position)*movespeed
			move_and_slide(move_vector)
			break
		# the character reached the end of the path
		elif distance < 0.0:
			position = Vector2(path[0].x,path[0].y)
#			set_process(false)
			break
		distance -= distance_between_points
		last_point = Vector2(path[0].x,path[0].y)
		path.remove(0)


var path_length = 100

func  _move5(delta):
	if path_length * 0.6 >= len(path) or len(path) == 1:
		path_length =  len(path)
		path = Map.nav.get_point_path(
			Map.nav.get_closest_point(Vector3(position.x,position.y,0)),
			Map.nav.get_closest_point(Vector3(player.position.x,player.position.y,0))
			)
	if len(path) != 0 : path.remove(0)

	move_along_path(movespeed*delta)

		#TO REFACTOR And Update
	var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y))
	var distance = (position - player.position ).abs()
	#var axis     = Vector2( distance.x >= personal_space, distance.y >= personal_space )
	
	if( distance.x > distance.y ):#and axis.x ):
		if abs(move.x) != 0: 
			direction         = "Right" if move.x > 0 else "Left"
	elif(distance.x <= distance.y ):# and axis.y):
		if abs(move.y) != 0: 
			direction         = "Up"    if move.y > 0 else "Down"
	print( direction )
	play_animation_if_not_playing(direction)


func _on_damage():
	player = Res.game.player
	
	current_state = "Follow"
	
	var fx = Res.create_instance(music["Hit"])
	fx.position = position - Vector2(0, 40)
	get_parent().add_child(fx)

func _on_animation_finished(anim_name):

	if "Magic" in anim_name:
		current_atack = "Wait"
		block_logic = false
	if "Special" in anim_name:
		current_atack = "Wait"
		block_logic = false
	if "Punch" in anim_name:
		current_atack = "Wait"
		block_logic = false


func _player_run_away():
	if position.distance_to(player.position) > 700:
		current_state = "Wait"
		path = []
		play_animation_if_not_playing("Idle")

func _on_Radar_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"


var red_color_changing = false
func _on_animation_started(anim_name):
	var anim = $AnimationPlayer.get_animation(anim_name)
	if anim and sprites:
		var main_sprite = int(anim.track_get_path(0).get_name(1))
		for i in range(sprites.size()):
			sprites[i].visible = (i+1 == main_sprite)
			
			if red_color_changing:
				sprites[i].modulate =Color(1,0.4,0.4)
			else:
				sprites[i].modulate = Color(1,1,1)
			

func _on_dead():
	Res.game.player.updateQuest(enemy_name)
	
	Res.play_sample(self, music["Dead"])
	
	current_state = "Dead"
	current_atack = "Dead"
	block_logic   =  true
	
	$"AnimationPlayer".play("Dead")
	$"Shape".queue_free()
	$"DamageCollider/Shape".queue_free() 
	$"AttackCollider/Shape".queue_free() 
	
	for i in range(sprites.size()):
		sprites[i].modulate = Color(1,1,1,1)

var drops = []

var direction       = "Down"

onready var sprites = $Sprites.get_children()


var MAT = load("res://Resources/Materials/ColorShader.tres")

func _ready():
	Map    = get_parent()
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$"/root/Game".perma_state(self, "queue_free")
	$"AnimationPlayer".play("Idle")

func scale_stats_to( max_hp, ar ):
	var t = float(health)/float(max_health)
	health = t*max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	max_health = max_hp


func set_statistics(max_hp, given_exp, ar):
	max_health = max_hp
	health = max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	experience = given_exp 
	
func damage(amount, source = "", type = ""):
	if current_state == "Dead" : return
	
	var damage = amount

	match(type):
		"Physical":
			damage = max(1, int(amount  -( resists[0] + resists_modif[0])/2))
		"Explosion":
			damage = max(1, int(amount  -( resists[1] + resists_modif[1])/2))
		"Shock":
			damage = max(1, int(amount  -( resists[2] + resists_modif[2])/2))
		"Crush":
			damage = max(1, int(amount  -( resists[3] + resists_modif[3])/2))


	if randi()%100 < PlayerStats.statistic["ct_chc"][0]*100 and source == "player": 
	
		damage += PlayerStats.statistic["ct_dmg"][0]
		
		Res.create_instance("DamageNumber").damage(self, str(damage)+"!", "crit")
	else:
		Res.create_instance("DamageNumber").damage(self, damage,type)
	
	health -= damage
	
	health_bar.visible = true
	health_bar.value = health
	timeout_bar = 180
	
	if health <= 0:
		$"/root/Game".save_state(self)
		
		current_state = "Dead"
		
		health_bar.visible = false
		PlayerStats.add_experience(experience)

		z_index -=1

		_on_dead()


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

func create_drop():
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
		
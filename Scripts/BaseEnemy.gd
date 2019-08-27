extends KinematicBody2D

const DEBBUG_RUN = false
const DAMAGE_TYPE  = ["NoDamage", "Earth", "Fire", "Water", "Wind", "Physical"]
const ABILITY_TYPE = { "Atack" : 0,"Skill" : 1, "Magic" : 2 }

onready var sprites    = $Sprites.get_children()
onready var health_bar = $HealthBar
onready var player = get_tree().get_root().find_node("Player", true, false)
onready var Map    = get_tree().get_root().find_node("RandomMap",true,false)

var can_use_ability = []
var ability_probs   = [0,0,0]
var damages         = [0,0,0]
var knockbacks      = [0,0,0]
var damage_type     = [0,0,0]
var resists         = [0,0,0,0,0]

var resists_modif   = [0,0,0,0,0]
var ab_prob_modif   = [0,0,0]
var damages_modif   = [0,0,0]

var max_health = 5
var health     = 5
var experience = 5
var movespeed  = 0
var personal_space = 40
var enemy_name = ""
var level      = 0
var last_atack_type = 0

var music 
var drops 
var MAT

var my_id           = -1
var direction       = "Down"

func initialize(id, dung_name, kind):
	enemy_name = kind
	my_id      = id
	level      = max(PlayerStats.level + randi()%6 - 3, 0)

	max_health     = Res.enemies[dung_name][kind]["HP"     ]
	health         = Res.enemies[dung_name][kind]["HP"     ] 
	movespeed      = Res.enemies[dung_name][kind]["Speed"  ]
	experience     = Res.enemies[dung_name][kind]["Exp"    ] 
	personal_space = Res.enemies[dung_name][kind]["Range"  ]
	music          = Res.enemies[dung_name][kind]["Music"  ]
	resists        = [] +Res.enemies[dung_name][kind]["Resists"]
	drops          = Res.enemies[dung_name][kind]["Drops"  ]
	
	for abillity in ABILITY_TYPE.keys():
		can_use_ability.append(bool(Res.enemies[dung_name][kind][abillity][0]))
		damages[ABILITY_TYPE[str(abillity)] ]       = Res.enemies[dung_name][kind][str(abillity)][1]
		knockbacks[ABILITY_TYPE[str(abillity)] ]    = Res.enemies[dung_name][kind][str(abillity)][2]
		ability_probs[ABILITY_TYPE[str(abillity)] ] = int(Res.enemies[dung_name][kind][str(abillity)][3])
		damage_type[ABILITY_TYPE[str(abillity)] ]   = DAMAGE_TYPE[Res.enemies[dung_name][kind][str(abillity)][4]]

	scale_enemy_level()

func scale_enemy_level():
	var level_scale = 1.0 + level/10.0

	max_health     *=  level_scale
	health         *=  level_scale
	experience     *=  level_scale

	for index in range(len(resists)): resists[index] *= level_scale
	for index in range(len(damages)): damages[index] *= level_scale

func set_resists_to_bar():
	health_bar.get_node("Health").max_value = max_health
	health_bar.get_node("Health").value     = health
	health_bar.get_node("Level").text       = str(level + 1)

	var resist_sum = 0 
	var sorted = [ ]
	for resist in range(len(resists)):
		resist_sum += resists[resist] + resists_modif[resist]
		sorted.append([ resists[resist] + resists_modif[resist], resist + 1 ])

	if resist_sum <= 0 : return
	
	var max_value = 100
	for value_index in range(len(resists)):
		var values    = sorted[value_index]
		var node      = health_bar.get_node("Resist" + str(value_index + 1) )
		node.value    = max_value
		max_value    -= int( (resists[value_index] + resists_modif[value_index]) * 100 /resist_sum)
		node.visible  = true
		health_bar.move_child(node, 7)


var timeout_bar   = 0.0
var timeout_flash = 0.0
var timeout_dead  = 0.0
var timeout_magic = 0.0

var current_state     = "Wait"
var current_atack     = "Wait"
var magic_active      = false
var block_logic       = false
var current_animation = ""

var ability_ready = [ false, false, false ]
const TIME_TO_DISAPEARD = 4.5


func select_shader(shader_color):
	match(shader_color):
		"red"  : 
			MAT = load("res://Resources/Materials/FLAG-shader.tres")
			MAT.set_shader_param("ucolor", Color(1.1, 0.4, 0.4))
		"blue" : 
			MAT = load("res://Resources/Materials/FLAS-shader.tres")
			MAT.set_shader_param("ucolor", Color(0.4, 0.4, 1))
		_: 
			MAT = null

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
	if timeout_dead > TIME_TO_DISAPEARD: call_deferred("queue_free")

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)
	if fb:
		$"AnimationPlayer".play_backwards(anim)

func _physics_process(delta):
	timeout_bar -= 1
#	if timeout_bar == 0: health_bar.visible = false
	
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
				sprites[i].modulate = Color(2,2,0.1,3) 
			elif current_atack == "Skill":
				sprites[i].modulate =  Color(2,0.1,0.1,3)
			elif current_atack == "Magic":
				sprites[i].modulate =  Color(0.1,2,0.1,3)
	else:
		for i in range(sprites.size()):
			sprites[i].modulate = Color(1,1,1,1)
	
func ameansure_preparation_timeout(delta ):
	
	flash(delta)
	
	if timeout_flash > 1.5:
		for i in range(sprites.size()):
			sprites[i].modulate = Color(1,1,1,1)
		timeout_flash = 0
		return true
	return false
	
func is_close_enough():
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
	#print( distance )
	var last_point = position
	for index in range(path.size()):
		var distance_between_points = last_point.distance_to(Vector2(path[0].x,path[0].y))
		# the position to move to falls between two points
		if distance <= distance_between_points and distance >= 0.0:
			var info = last_point.linear_interpolate(Vector2(path[0].x,path[0].y), distance / distance_between_points)
			var move_vector = (info-position)*movespeed
		#	print( move_vector )
			move_and_slide(move_vector)
			break
		# the character reached the end of the path
		elif distance < 0.0:
			position = Vector2(path[0].x,path[0].y)
			path.remove(0)
#			set_process(false)
			break
		distance -= distance_between_points
		last_point = Vector2(path[0].x,path[0].y)


func find_path():
	
	var player_position  = Vector2(int(player.position.x/80),int(player.position.y/80))
	var current_posiiton = Vector2(int(position.x/80),int(position.y/80)) 
	
	var distance = abs(player_position.x - current_posiiton.x ) + abs(player_position.y - current_posiiton.y) 

	#print( distance )
	if distance >= len(path) - 1:
		
	#if path_length * 0.6 >= len(path) or len(path) == 1:
#		path_length =  len(path)
		path = Map.nav.get_point_path(
			Map.nav.get_closest_point(Vector3(position.x,position.y,0)),
			Map.nav.get_closest_point(Vector3(player.position.x,player.position.y,0))
			)
		path.remove(0)
	#	print( position, path )
	#if len(path) != 0 : path.remove(0)



func  _move5(delta):
	find_path()

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
		find_path()

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		current_state = "Follow"
		find_path()

func _on_animation_started(anim_name):
	var anim = $AnimationPlayer.get_animation(anim_name)
	if anim and sprites:
		var main_sprite = int(anim.track_get_path(0).get_name(1))
		for i in range(sprites.size()):
			sprites[i].visible = (i+1 == main_sprite)

func enable_collisions():
	if is_instance_valid($"Shape"): $"Shape".set_disabled(false)
	if is_instance_valid($"AttackCollider/Shape"):   $"AttackCollider/Shape".set_disabled(false)
	if is_instance_valid($"DamageCollider/Shape"):   $"DamageCollider/Shape".set_disabled(false)
	if is_instance_valid($"Radar/Shape"): $"Radar/Shape".set_disabled(false)

func disable_collisions(): 
	if is_instance_valid($"Shape"): $"Shape".set_disabled(true)
	if is_instance_valid($"AttackCollider/Shape"):   $"AttackCollider/Shape".set_disabled(true)
	if is_instance_valid($"DamageCollider/Shape"):   $"DamageCollider/Shape".set_disabled(true)
	if is_instance_valid($"Radar/Shape"): $"Radar/Shape".set_disabled(true)

func _on_dead():
	Res.game.player.updateQuest(enemy_name)
	
	Res.play_sample(self, music["Dead"])
	
	current_state = "Dead"
	current_atack = "Dead"
	block_logic   =  true
	
	$"AnimationPlayer".play("Dead")
	$"Shape".call_deferred("queue_free")
	$"DamageCollider/Shape".call_deferred("queue_free") 
	$"AttackCollider/Shape".call_deferred("queue_free") 
	
	for i in range(sprites.size()):
		sprites[i].modulate = Color(1,1,1,1)

func _ready():
	Map    = get_parent()
	health = max_health
	set_resists_to_bar()
	$"/root/Game".perma_state(self, "queue_free")
	$"AnimationPlayer".play("Idle")
	enable_collisions()


func scale_stats_to( max_hp, ar ):
	var t = float(health)/float(max_health)
	health = t*max_hp
	set_resists_to_bar()
	max_health = max_hp


func set_statistics(max_hp, given_exp, ar):
	max_health = max_hp
	health = max_hp
	set_resists_to_bar()
	experience = given_exp 
	
func damage(amount, source = "", type = ""):
	if current_state == "Dead" : return
	
	var damage = amount

	var type_id = DAMAGE_TYPE.find(type) - 1
	damage = max( 1, int(amount -( resists[type_id] + resists_modif[type_id])/2))

	resists[DAMAGE_TYPE.find("Physical") - 1] = max( resists[DAMAGE_TYPE.find("Physical")-1] - damage, 0 )
	set_resists_to_bar()
	
	if resists[DAMAGE_TYPE.find("Physical") - 1] == 0 and type == "Physical" : 
		damage *= 1.5

	if randi()%100 < PlayerStats.statistic["critical_chance"][0]*100 and source == "player": 
		damage += PlayerStats.statistic["critical_damage"][0]
		type = "crit"
	Res.create_instance("DamageNumber").damage(self, damage, type)

	health -= damage

	health_bar.visible = true
	health_bar.get_node("Health").value = health
	timeout_bar = 180
	
	if health <= 0:
		$"/root/Game".save_state(self)
		current_state = "Dead"
		health_bar.visible = false
		PlayerStats.add_experience(experience)
		z_index -=1
		_on_dead()
		Map.call_deferred("mark_as_destroyed", my_id)
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
	
const MAX_NUMBER_OF_DROPS = 4
func create_drop():

	for i in range( MAX_NUMBER_OF_DROPS ):
		var drop = get_drop_id()
	
		if drop > -1:
			var stack = 1 
			stack += 1 if randi() % 30  < 15 else 0 
			stack += 1 if randi() % 60  < 20 else 0  
			stack += 1 if randi() % 90  < 25 else 0 
			stack += 1 if randi() % 120 < 30 else 0 
			
			var item      = Res.create_instance("Item")
			item.set_stack(stack)
			item.position = position + (Vector2( randf() * -1 if randi()%2 == 0 else 1, 
												 randf() * -1 if randi()%2 == 0 else 1 
												).normalized() * 40 )
			item.id       = drop
			get_parent().add_child(item)
		elif randi() % 1000 < 300:
			var stack     = randi()%121 + 1
			var item      = Res.create_instance("Money")
			item.set_stack(stack)
			item.position = position + (Vector2( randf() * -1 if randi()%2 == 0 else 1, 
												 randf() * -1 if randi()%2 == 0 else 1 
												).normalized() * 40 )
			get_parent().add_child(item)

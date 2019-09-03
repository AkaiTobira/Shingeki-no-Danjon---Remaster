extends KinematicBody2D

const DEBBUG_RUN = false
const DAMAGE_TYPE  = ["Earth", "Fire", "Water", "Wind", "Physical"]
const ABILITY_TYPE = { "Attack" : 0,"Skill" : 1, "Magic" : 2 }

onready var sprites    = $Sprites.get_children()
onready var health_bar = $HealthBar
onready var player = get_tree().get_root().find_node("Player", true, false)
onready var Map    = get_tree().get_root().find_node("RandomMap",true,false)

var actions = {
	"Attack" :{
		"can_use"   : false,
		"is_ready"  : false,
		"prob"      : 0,
		"knockback" : 0,
		"damage"    : []
	},
	"Skill" :{
		"can_use"   : false,
		"is_ready"  : false,
		"prob"      : 0,
		"knockback" : 0,
		"damage"    : []
	},
	"Magic" :{
		"can_use"   : false,
		"is_ready"  : false,
		"prob"      : 0,
		"knockback" : 0,
		"damage"    : []
	}
}

var Resists = {
	"Earth"    : [0, 0],
	"Fire"     : [0, 0],
	"Water"    : [0, 0],
	"Wind"     : [0, 0],
	"Physical" : [0, 0]
}

var damage_type     = [0,0,0]
var resists         = [0,0,0,0,0]

var max_health = 5
var health     = 5
var experience = 5
var movespeed  = 0
var personal_space = 40
var enemy_name = ""
var level      = 0
var last_atack_type = 0
var dungeon_name  = ""

var music 
var drops 
var MAT

var my_id           = -1
var direction       = "Down"

func initialize(id, dung_name, kind):
	dungeon_name = dung_name
	enemy_name = kind
	my_id      = id
	level      = max(PlayerStats.level + randi()%6 - 3, 0)

	var enemy_info = Res.enemies[dung_name][kind]

	max_health     = enemy_info["HP"   ]
	health         = enemy_info["HP"   ] 
	movespeed      = enemy_info["Speed"]
	experience     = enemy_info["Exp"  ] 
	personal_space = enemy_info["Range"]
	music          = enemy_info["Music"]
	drops          = enemy_info["Drops"]
	
	for resist in Resists.keys():
		Resists[resist][0] = enemy_info["Resists"][resist]

	for action in ABILITY_TYPE.keys():
		if enemy_info["Actions"][action]["can_use"]:
			actions[action]["prob"]      = enemy_info["Actions"][action]["prob"]
			actions[action]["knockback"] = enemy_info["Actions"][action]["knockback"]
			actions[action]["can_use"]   = enemy_info["Actions"][action]["can_use"]
			actions[action]["is_ready"]  = enemy_info["Actions"][action]["is_ready"]

			for damage in enemy_info["Actions"][action]["damage"]:
				actions[action]["damage"].append( [ damage[0], damage[1] ] )

	scale_enemy_level()

func scale_enemy_level():
	var level_scale = 1.0 + level/5.0

	max_health     *=  level_scale
	health         *=  level_scale
	experience     *=  level_scale

	for damage in DAMAGE_TYPE: Resists[damage][0] *= level_scale
	
	for action in ABILITY_TYPE:
		for damage in actions[action]["damage"]:
			damage[0] *= level_scale

func set_resists_to_bar():
	health_bar.get_node("Health").max_value = max_health
	health_bar.get_node("Health").value     = health
	health_bar.get_node("Level").text       = str(level + 1)

	var resist_sum = 0 

	for damage in DAMAGE_TYPE: resist_sum += Resists[damage][0] + Resists[damage][1]

	if resist_sum <= 0 : return
	
	var max_value = 100
	for value_index in range(len(resists)):
		var damage_type = DAMAGE_TYPE[value_index]

		var node      = health_bar.get_node("Resist" + str(value_index + 1) )
		node.value    = max_value
		max_value    -= int( (Resists[damage_type][0] + Resists[damage_type][1]) * 100 /resist_sum)
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
		var ability_type = ABILITY_TYPE[str(abillity)]

		if actions[abillity]["can_use"] and !actions[abillity]["is_ready"]:
			actions[abillity]["is_ready"] = (randi()% int(actions[abillity]["prob"])) == 0


func meansure_dead_timeout(delta):
	if timeout_dead == 0 : create_drop()
	timeout_dead += delta
	if timeout_dead > TIME_TO_DISAPEARD: call_deferred("queue_free")

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim: $"AnimationPlayer".play(anim)
	if fb: $"AnimationPlayer".play_backwards(anim)

func _physics_process(delta):
	timeout_bar -= 1
#	if timeout_bar == 0: health_bar.visible = false
	
func _use_action( action_type ):
	current_atack   = action_type	
	last_atack_type = ABILITY_TYPE[current_atack]
	actions[current_atack]["is_ready"] = false

var time = 0.0
var path = []

func flash(delta):
	
	timeout_flash += delta
	time += 0.2
	if int(time)%4 == 0:
		for i in range(sprites.size()):
			match( current_atack ):
				"Attack": sprites[i].modulate = Color(2,2,0.1,3) 
				"Skill":  sprites[i].modulate = Color(2,0.1,0.1,3)
				"Magic":  sprites[i].modulate = Color(0.1,2,0.1,3)
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
			 actions[current_atack]["damage"] ,
			 actions[current_atack]["knockback"]
			 )

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
			path.remove(0)
			break
		distance -= distance_between_points
		last_point = Vector2(path[0].x,path[0].y)


func find_path():
	var player_position  = Vector2(int(player.position.x/80),int(player.position.y/80))
	var current_posiiton = Vector2(int(position.x/80),int(position.y/80)) 
	var distance         = abs(player_position.x - current_posiiton.x ) + abs(player_position.y - current_posiiton.y) 

	if distance >= len(path) - 1:
		path = Map.nav.get_point_path(
			Map.nav.get_closest_point(Vector3(position.x,position.y,0)),
			Map.nav.get_closest_point(Vector3(player.position.x,player.position.y,0))
			)
		if len(path) > 0: path.remove(0)

func  _move5(delta):
	find_path()

	move_along_path(movespeed*delta)

	#TO REFACTOR And Update
	var move     = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y))
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
	Res.game.quest_system.updateQuest(enemy_name)
	
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
#	enable_collisions()
	

func get_resist_value(type):
	var ressist = 0 
	if type == "Physical":
		var physical_id = DAMAGE_TYPE.find("Physical") - 1
		ressist = ( Resists[type][0] + Resists[type][1] )/2.0
	elif type == "Chaos":
		for damage in DAMAGE_TYPE:
			if damage == "Physical": continue
			ressist = ( Resists[damage][0] + Resists[damage][1])/8.0
	else:
		ressist = ( Resists[type][0] + Resists[type][1] )
	return ressist

func damage(amount_array, source = ""):
	if current_state == "Dead" : return

	for index in range(len(amount_array)):
		var amount = amount_array[index][0]
		var type   = amount_array[index][1]

		var ressist = get_resist_value(type)
		var damage  = amount - ressist

		if type == "Physical":
			Resists["Physical"][0] = max( Resists["Physical"][0] - amount, 0 )

		if randi()%100 < PlayerStats.statistic["critical_chance"][0]*100 and source == "player": 
			damage += PlayerStats.statistic["critical_damage"][0]
			if damage > 0: type    = "crit"

		Res.create_instance("DamageNumber").damage(self, damage, type, index)

		health                             -= max( damage, 0 )
		health_bar.visible                  = true
		health_bar.get_node("Health").value = health
		set_resists_to_bar()
	
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

	var drop = get_drop_id()

	for i in range( MAX_NUMBER_OF_DROPS ):
		if randi() % 1000 < 250:
			var stack     = randi()%121 + 1
			var item      = Res.create_instance("Money")
			item.set_stack(stack)
			item.position = position + (Vector2( randf() * -1 if randi()%2 == 0 else 1, 
												 randf() * -1 if randi()%2 == 0 else 1 
												).normalized() * 40 )
			get_parent().add_child(item)
		elif drop > -1:
			var stack = 1 
			stack += 1 if randi() % 30  < 10 else 0 
			stack += 1 if randi() % 60  < 15 else 0  
			stack += 1 if randi() % 90  < 20 else 0 
			stack += 1 if randi() % 120 < 25 else 0 
				
			var item      = Res.create_instance("Item")
			item.id       = drop
			item.set_stack(stack)
			item.position = position + (Vector2( randf() * -1 if randi()%2 == 0 else 1, 
												 randf() * -1 if randi()%2 == 0 else 1 
												).normalized() * 40 )

			get_parent().add_child(item)

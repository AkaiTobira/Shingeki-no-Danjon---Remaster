extends Node2D

enum PLACEMENT{ EVERY_WALL, LEFT_OR_RIGHT_WALL, UP_OR_DOWN_WALL, UP_WALL, DOWN_WALL ,WALL_FREE }


export(PLACEMENT) var placement = 0
export var offset_position = Vector2(0, 0)
export var size = Vector2(1, 1)
export var variants = ""
export var can_flip_h = false
export var const_object = false 
export(bool)var need_enemies_list 

export(bool) var need_enable_directions

const HOW_MANT_ITMES = 23

enum STATE{ CONST, DESTROYABLE, CHESTS }

export(STATE) var state = 0

var spawning_time = 0.0
var directions = [true,true,true,true]

var item = -1

var destroy_time = 0.0
var destroyed = false
var enemies_list = []

onready var player = get_tree().get_root().find_node("Player", true, false) 

func spawn():
	var re = randi()%4
	var breaker = 0
	while !directions[re]:
		if breaker > 100:
		#	print("FORCE BREAKER")
			return
		breaker += 1
		re = randi()%4
	
	var ug_inst = preload("res://Nodes/Projectiles/Summon_Mob.tscn").instance()
	ug_inst.position = position
	
	match( re ):
		0:
			ug_inst.position += Vector2(-80,0)

			#print("Left")
		1:
			ug_inst.position += Vector2(80,0)

			#print("Right")
		2:
			ug_inst.position += Vector2(0,-80)

			#print("UP")
		3:
			ug_inst.position += Vector2(0, 80)

			#print("Down")
	
	ug_inst.set_enemies(enemies_list)
	get_parent().add_child(ug_inst)
	
	pass
	
func fill_enemies_list(tab):
	for i in tab:
		enemies_list.append(load("res://Nodes/Enemies/"+ i  +".tscn"))

func _process(delta):
	if destroyed :
		destroy_time += delta
		if destroy_time > 3:
			queue_free()
		return
			
	if spawning_time < 25 :
		spawning_time += delta
	else:
		spawning_time = 0.0
		if player.position.distance_to(position) < 600:
			spawn()

func _ready():
	Res.game.perma_state(self, "queue_free")

func fill(breakable_contains,dungeon_level):
	item = -1	
	pass

func _build_wall( tab = [] ):
	directions = tab
#	print(directions)
	pass

func damage(amount):
	Res.play_sample(self, "WoodBreak")
	$Animation.play("Destroyed")
	$DamageCollider.queue_free()
	$Shape.disabled = true
	z_index = -1
	$"/root/Game".save_state(self)
	
	destroyed = true
	
	if item > -1:
		var it = Res.create_instance("Item")
		it.position = position
		it.id = item
		it.z_index = 100
		get_parent().add_child(it)
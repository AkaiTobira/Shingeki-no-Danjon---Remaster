extends Node2D

const MOVEMENT = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
var SPEED = 0.01

var direction = 0 setget new_dir
var damage = 0 setget set_damage

var numb
var player

var time = 0

func intiated():
	if Input.is_action_pressed("Magic_Special") and PlayerStats.mana > 1: accumulate_speed = false
	Res.play_sample(self, "RockFist")

	player = get_tree().get_root().find_node("Player", true, false)

	position = player.position - Vector2(0,20)

	numb = 10
	var angle = 0
	for i in range( numb ) :
		var inst = Res.create_instance("Projectiles/SmallRock")		
		inst.position          = Vector2( cos(angle) * 80 , sin( angle) * 80 )
		inst.rotation_degrees  = angle
		inst.damage            = damage
		inst.enable_mana_drain = false
		angle += 360 / numb 
		add_child(inst)

func set_damage(dmg):
	damage = dmg
	for child in get_children(): child.damage = dmg

var speed = 1
var accumulate_speed = true
var angle_addition = 0
func _physics_process(delta):
	PlayerStats.mana = max( PlayerStats.mana - numb*delta, 0 )
	if PlayerStats.mana <= PlayerStats.statistic["mana_regeneration"][0]: 
		for child in get_children():
			child.get_node("Sprite2").visible = true
		accumulate_speed = true

	
	if Input.is_action_just_released("Magic_Special") :  
		for child in get_children():
			child.get_node("Sprite2").visible = true
		accumulate_speed = true
	if accumulate_speed : speed *= 1.1 

	
	angle_addition += 1 * delta
	position = player.position
	var angle = 0 
	for child in get_children():
		angle += 360/numb
		child.damage = damage
		child.position = Vector2( cos(angle + angle_addition) * 80 * speed, sin( angle + angle_addition) * 80 * speed)
		child.rotation_degrees = angle + angle_addition
		if speed > 300 : child.queue_free()


	if get_child_count() == 0 : queue_free()

func new_dir(dir): pass
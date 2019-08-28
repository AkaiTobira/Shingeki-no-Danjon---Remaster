extends "res://Scripts/BaseEnemy.gd"

const SKILL_NAME = ["Summon", "FireBomb", "Payback"]

var active_skill = "Rest"
var timer        = 0.0
var tiredness    = 150

var timers = {
	"Payback" : 4,
	"Dead"    : 10
}

var skills = {
	"Payback" : {
		"prob"      : 100,
		"dmg"       : 75,
		"knockback" : 250,
		"is_ready"  : false,
		"animation" : "ShieldBlockON",
		"sample"    : "MechanicPaybackInitiate",
		"stacks"    : 0,
	},
	"Summon" : {
		"prob"      : 1000,
		"dmg"       : 0,
		"knockback" : 0,
		"is_ready"  : false,
		"animation" : "Idle",
		"sample"    : "SummonStart"	
	},
	"FireBomb" : {
		"prob"      : 250,
		"dmg"       : 12,
		"knockback" : 0,
		"is_ready"  : false,
		"animation" : "Idle",
		"sample"    : "MechanicExplosionInitiate"
	}
}

var follow = false

var RShieldON = true
var LShieldON = true

var base_resists = [ 60, 60, 60, 60, 450 ]


func _ready():
	max_health = 1500
	level      = PlayerStats.level
	randomize_shields_resistances()
	._ready()
	.set_resists_to_bar()

	$"AttackCollider/Shape".disabled = true
	
	$Sprites.material              = null
	$"LeftShield/Sprite" .material = null
	$"RightShield/Sprite".material = null

func update_skills_probs():
	for skill in SKILL_NAME:
		if not skills[skill]["is_ready"]:
			if randi() % skills[skill]["prob"] == 0 : skills[skill]["is_ready"] = true

func check_shields():
	if RShieldON:
		if $"RightShield".destroyed : 
			randomize_shields_resistances()
			RShieldON = false
	if LShieldON :
		if $"LeftShield".destroyed  : 
			randomize_shields_resistances()
			LShieldON = false

func is_dead(delta):
	if active_skill == "Dead":
		timer += delta
		if timer > timers["Dead"]: call_deferred("queue_free")
		return true
	return false	

func randomize_shields_resistances():
	
	if RShieldON: $RightShield.update_resists()
	if LShieldON:  $LeftShield.update_resists()
	
	for index in range(len(resists)):
		resists[index] = base_resists[index]
		if RShieldON: resists[index] += $RightShield.resists[index]
		if LShieldON: resists[index] +=  $LeftShield.resists[index]
	
	.set_resists_to_bar()

func _physics_process(delta):

	if is_dead(delta): return
	check_shields()
			
	if tiredness > 100:
		active_skill = "Tired"
		play_animation_if_not_playing("Tired")
		switch_playing_shields_animation(false)
		return
	
	if active_skill == "Rest" and follow:
		update_skills_probs()
		
		for skill in SKILL_NAME:
			if skills[skill]["is_ready"]:
				timer        = 0
				active_skill = skill
				play_animation_if_not_playing(skills[skill]["animation"])
				skills[skill]["is_ready"] = false
				Res.play_sample(self, skills[skill]["sample"])
				activate_efects()
				if skills[skill].has("stacks") : skills[skill]["stacks"] = 0
				return

	else : update_skills(delta)
	
func activate_efects():
	match(active_skill):
		"Payback" :
			switch_playing_shields_animation(false)
			switch_effects_visible(true)
		"Summon"  :
			$EfectsAnimator/EfectPlayer.play("Summon")
		"FireBomb":
			$EfectsAnimator/EfectPlayer.play("FireProof")

func switch_effects_visible( turn ):
	$EfectsAnimator/Payback.visible = turn
	$EfectsAnimator/Payback.frame   = 0	

func on_skill_end():
	if active_skill == "Dead":return
	skills[active_skill]["is_ready"] = false
	active_skill = "Rest"
	tiredness   +=   20

func update_skills(delta):

	match(active_skill):
		"Payback":
			timer += delta
			if skills[active_skill]["stacks"] >= 3:
				timer = 0
				Res.play_sample(self, "MechanicPayback")
				play_animation_if_not_playing("ShieldBlockPayback")
				switch_shields_visible( false )
				return
			if timer > timers[active_skill]:
				timer = 0 
				play_animation_if_not_playing("ShieldBlockOFF")

func set_firebombs():
	var directionList = [ Vector2(100,100), Vector2(100, -100), Vector2(-90, 90 ), Vector2(-90, -90 ) ] 

	var number_of_bombs = randi()%2 + 1
	for a in range(number_of_bombs):
		var instance = Res.get_node("Projectiles/FireBomb").instance()
		Res.play_sample(instance, "MechanicExplosionMark")
		get_parent().add_child(instance)
	
func summon():
	var dis = 120
	var directionList = [ Vector2( dis +20,        0), 
						  Vector2(-dis -20,        0), 
						  Vector2(       0, dis + 20), 
						  Vector2(       0,-dis - 20), 
						  Vector2(     dis,      dis), 
						  Vector2(     dis,     -dis), 
						  Vector2(    -dis,      dis), 
						  Vector2(    -dis,     -dis) ] 	
	var freeDirection = [ true, true, true, true, true, true, true, true ]

	Res.play_sample(self, "Summon")
	var number_of_enemies = randi()%5 + 2	
	for a in range(number_of_enemies):
		var instance = preload("res://Nodes/Projectiles/Summon_Mob.tscn").instance()
		var direction = randi() % len(freeDirection)
		while( !freeDirection[direction] ): direction = randi()%len(freeDirection)
		instance.position         = position + directionList[direction]
		freeDirection[direction]  = false
		get_parent().add_child(instance)
	
func _on_animation_finished(anim_name):
	#print(anim_name)

	match( anim_name ):
		"ShieldBlockOFF" : 
			timer        = 0.0
			tiredness   += 30
			active_skill = "Rest"
			switch_playing_shields_animation(true)
			switch_effects_visible(false)
			play_animation_if_not_playing("Idle")
		"ShieldBlockPayback":
			active_skill = "Rest"
			switch_playing_shields_animation(true)
			switch_effects_visible(false)
			switch_shields_visible(true )
			play_animation_if_not_playing("ShieldBlockOFF")
		"ShieldBlockON":
			play_animation_if_not_playing("ShieldBlockHOLD")
		"Tired":
			randomize_shields_resistances()
			tiredness = 0
			active_skill = "Rest"
			switch_playing_shields_animation(true)
			play_animation_if_not_playing("Idle")
		"Dead":
			$AnimationPlayer.stop()


func _on_animation_started(anim_name):
	pass # replace with function body

func _on_Radar_body_entered(body):
	if body.name == "Player":
		follow = true;
	pass # replace with function body

func switch_shields_visible( flag ):
	if flag:
		if RShieldON: $RightShield.visible = true
		if LShieldON: $LeftShield.visible  = true
	else:
		if RShieldON: $RightShield.visible = false
		if LShieldON: $LeftShield.visible  = false

func switch_playing_shields_animation( play ):
	match(play):
		true:
			if RShieldON: $RightShield/AnimationPlayer.play("Idle")	
			if LShieldON: $LeftShield/AnimationPlayer.play("Idle")
		false:
			if RShieldON: $RightShield/AnimationPlayer.stop()	
			if LShieldON: $LeftShield/AnimationPlayer.stop()
		
func _on_dead():
	active_skill = "Dead"
	play_animation_if_not_playing("Dead")
	
	$"Shape".call_deferred("queue_free")
	$"DamageCollider/Shape".call_deferred("queue_free")
	$"AttackCollider/Shape".call_deferred("queue_free")
	$"EfectsAnimator".visible = false

	if RShieldON: $"RightShield".kill_shield() 
	if LShieldON: $"LeftShield".kill_shield() 
	
func _on_damage():
	if "Payback" == active_skill :
		Res.play_sample(self, "MechanicPaybackTrigger")
		skills["Payback"]["stacks"] += 1
		if skills["Payback"]["stacks"] < 4: $EfectsAnimator/Payback.frame = skills["Payback"]["stacks"]
	else:
		var fx = Res.create_instance("Effects/MetalHitFX")
		fx.position = (position + Res.game.player.position)/2
		get_parent().add_child(fx)


func _on_payback_attack(collider):
	if collider.get_parent().is_in_group("players"):
		collider.get_parent().damage(self, 
			skills["Payback"]["dmg"], 
			skills["Payback"]["knockback"],
			"Chaos" )

extends KinematicBody2D

const SPEED = 220
const MEDITATION_TIME = 3
var GHOST = load("res://Nodes/Player.tscn")

onready var UI = $Camera/UI
onready var GHOST_EFFECT = $"/root/Game/GhostLayer/Effect"

var frame_counter = 0

var direction = -1
var static_time = 0
var motion_time = 0
var prev_move = Vector2()
var running = false
var knockback = Vector2()

var animations = {Body = "", RightArm = "", LeftArm = ""}
var sprite_direction = "Front"

var ghost_mode = false
var ghost_time = false

var attacking = false
var shielding = false
var current_element = 0

var charge_spin
var triggered_skill
var water_stream_hack = false
var wind_spam_hack = false

var active_damage_type = "Physical"

var damaged
var dead = false

const DAMAGE_TYPE  = ["Earth", "Fire", "Water", "Wind", "Physical"]

func _ready():
	change_animation("Body", "Idle")
	$BodyAnimator.play("Idle")
	change_animation("LeftArm", "ShieldOff")
	change_animation("RightArm", "SwordAttack")
	change_dir(2)
	reset_arms()
	
	PlayerStats.connect("equipment_changed", self, "update_weapon")
	PlayerStats.connect("equipment_changed", self, "update_shield")

func handle_ghost(delta):
	 ##( ･_･)
	$Body/RightArm/Weapon.visible = false
	$Body/LeftArm/Shield.visible = false
		
	ghost_time -= delta
	GHOST_EFFECT.material.set_shader_param("noise_power", 0.002 + max(2 - ghost_time, 0) * 0.02)
	if ghost_time <= 0 : get_parent().cancel_ghost()

func handle_move(not_move, delta):
	frame_counter += 1
	var move = Vector2()
	
	static_time += delta
	motion_time += delta
#	if static_time >= MEDITATION_TIME: SkillBase.inc_stat("Meditation")
	
	if !not_move:
		if Input.is_action_pressed("Up"):
			move.y = -1
			if prev_move.x == 0 or (direction == 0 and prev_move.y > 0): change_dir(0)
		if Input.is_action_pressed("Down"):
			move.y = 1
			if prev_move.x == 0 or (direction == 2 and prev_move.y < 0): change_dir(2)
		if Input.is_action_pressed("Left"):
			move.x = -1
			if prev_move.y == 0 or (direction == 1 and prev_move.x > 0): change_dir(3)
		if Input.is_action_pressed("Right"):
			move.x = 1
			if prev_move.y == 0 or (direction == 3 and prev_move.x < 0): change_dir(1)
	elif knockback.length_squared() > 0:
		move = knockback * 50
		if move.length() > 5000: move = move.normalized() * ( 5000  )
		knockback /= 1.5
		if knockback.length_squared() < 1: knockback = Vector2()

	if move.length_squared() == 0: 
		SkillBase.inc_stat("Meditation", delta)
		running = false

	if SkillBase.has_skill("FastWalkI") and SkillBase.check_combo(["Dir", "Same"]): running = true
	if !not_move:
		move = move.normalized() * ( SPEED +  PlayerStats.statistic["move_speed"][0] )
		if running and !not_move: 
			if   SkillBase.has_skill("FastWalkII") : move *= 1.55 
			elif SkillBase.has_skill("FastWalkIII"): move *= 3 #DEBBUG
			else : move *= 1.30

	if !damaged and !knockback:
		if move.length() > 0 and !not_move:
			static_time = 0
			PlayerStats.damage_equipment("boots")
			change_animation("Body", "Walk")
		else:
			motion_time = 0
			change_animation("Body", "Idle")
	else:
		damaged -= 1
		if damaged == 0: damaged = null
	
	var rem = move_and_slide(move)
	if rem.length() == 0: motion_time = 0
	elif motion_time > 1: SkillBase.inc_stat("PixelsTravelled", int(rem.length()))
	prev_move = move

func handle_sword_attack(delta):
	if !ghost_time and !attacking and !ghost_mode and !shielding and Input.is_action_just_pressed("Attack"):
		if PlayerStats.get_equipment("weapon"): Res.play_pitched_sample(self, "Sword")
		else: Res.play_pitched_sample(self, "Punch")
		change_animation("RightArm", "SwordAttack")
		reset_arms()
		$ArmAnimator.play("SwordAttack" + sprite_direction)
		attacking = true
		charge_spin = 1
	
	if charge_spin: charge_spin += delta
	#	if Input.is_action_just_released("Attack"):
#		if charge_spin and charge_spin > 2:
#			change_animation("Body", "SpinAttack")
#			change_animation("LeftArm", "SpinAttack")
#		charge_spin = null

func handle_shielding():
	if !attacking and !shielding : 
		if PlayerStats.get_equipment("shield") and Input.is_action_pressed("Shield"):
			change_animation("LeftArm", "ShieldOn")
			shielding = true
	elif shielding and Input.is_action_just_released("Shield"):
		change_animation("LeftArm", "ShieldOff")
		shielding = false

func handle_magic_menu(elements_on):
	if !elements_on:
		if Input.is_action_just_pressed("Magic"):#SkillBase.check_combo(["Magic", "Magic_"]):
			$Elements.visible = true
			SkillBase.current_combo.clear()
	else:
		if Input.is_action_pressed("Up"):
			Res.ui_sample("SelectElement")
			$Elements.visible = false
			current_element = 3
		elif Input.is_action_pressed("Right"):
			Res.ui_sample("SelectElement")
			$Elements.visible = false
			current_element = 2
		elif Input.is_action_pressed("Down"):
			Res.ui_sample("SelectElement")
			$Elements.visible = false
			current_element = 4
		elif Input.is_action_pressed("Left"):
			Res.ui_sample("SelectElement")
			$Elements.visible = false
			current_element = 1
		else: current_element = 0
		
		$Elements/Select.position = $Elements.get_child(current_element).position
		UI.get_node("HUD/Controls/ButtonElement").texture = Res.cache_resource("res://Sprites/UI/HUD/ButtonElement" + str(current_element) + ".png")
		
		if Input.is_action_just_released("Magic"):
			Res.ui_sample("SelectElement")
			$Elements.visible = false

func handle_skill_cast(elements_on, delta):
	if !elements_on :# and Input.is_action_pressed("Magic"):
		if !wind_spam_hack:
			use_magic()
			if triggered_skill:
				triggered_skill[1] -= delta
				
				if (ghost_time or ghost_mode): #block other skill in ghost mode
					if triggered_skill[0].name == "Ghost Change":
						if triggered_skill[1] <= 0: trigger_skill()
					else:
						triggered_skill = null
						SkillBase.current_combo.clear()
				else:
					if triggered_skill[1] <= 0: trigger_skill()
					
			elif water_stream_hack:
				water_stream_hack -= delta
				if water_stream_hack <= 0:
					trigger_skill(Res.skills["WaterBubble"])
					water_stream_hack = 0.1
				if !Input.is_action_pressed("Special"): water_stream_hack = false
		else:
			if Input.is_action_just_pressed("Special"):
				wind_spam_hack = 0.5
				trigger_skill(Res.skills["WindBanana"])
			
			wind_spam_hack -= delta
			if wind_spam_hack <= 0:
				wind_spam_hack = 0
				SkillBase.current_combo.clear()

func atribute_regeneration(delta):
	if PlayerStats.mana < PlayerStats.statistic["max_mana"][0]:
		PlayerStats.mana = min(PlayerStats.mana + PlayerStats.statistic["mana_regeneration"][0] * delta, 
							   PlayerStats.statistic["max_mana"][0]
							   )

func _physics_process(delta):

	if dead: return	
	if ghost_time:	handle_ghost(delta)

	var elements_on = (!ghost_time and $Elements.visible)
	var not_move    = (ghost_mode   or elements_on or knockback.length_squared() > 0)

	handle_move(not_move, delta)
	handle_sword_attack(delta)
	handle_shielding()
	handle_magic_menu(elements_on)
	handle_skill_cast(elements_on, delta)
	
	atribute_regeneration(delta)
#	if PlayerStats.hp   < PlayerStats.max_hp   and frame_counter % 20 == 0: PlayerStats.hp   = min(PlayerStats.hp + 1, PlayerStats.max_hp)

	UI.soft_refresh()

	if Input.is_key_pressed(KEY_F3): print(int(position.x / 800), ", ", int(position.y / 800)) ##debug
	if Input.is_key_pressed(KEY_F1): PlayerStats.add_experience(100000000) ##debug


func match_resistance_to_damage( type ):
	match ( type ):
		"Earth":    return PlayerStats.statistic["earth_resistance"][0]
		"Fire":     return PlayerStats.statistic["fire_resistance" ][0]
		"Water":    return PlayerStats.statistic["water_resistance"][0]
		"Wind":     return PlayerStats.statistic["wind_resistance" ][0]
		"Chaos":    return (PlayerStats.statistic["earth_resistance"][0] + 
							PlayerStats.statistic["fire_resistance" ][0] + 
							PlayerStats.statistic["water_resistance"][0] + 
							PlayerStats.statistic["wind_resistance" ][0])/8.0
		"Physical": return PlayerStats.statistic["armour"][0] / 2.0
	return 0


func damage(attacker, amount_array, _knockback):
	if dead: return
	damaged = 16 #Hack for old system

	for index in range(len(amount_array)):
		var amount = amount_array[index][0]
		var type   = amount_array[index][1]

		var resisit = match_resistance_to_damage(type)
		var damage  = amount - resisit

		if damage > 0:
			if shielding :
				damage -= PlayerStats.statistic["block"][0]/2.0 if type == "Physical" else PlayerStats.statistic["block"][0]/4.0
				if damage <= 0 :
					SkillBase.inc_stat("ShieldBlocks")
					PlayerStats.damage_equipment("shield")
					Res.play_sample(self, "ShieldBlock")
				else:
					SkillBase.inc_stat("DamageTaken", damage)
					PlayerStats.health -= damage
					PlayerStats.damage_equipment("shield")
					PlayerStats.damage_equipment("armor", 2)
					PlayerStats.damage_equipment("helmet")
				Res.create_instance("DamageNumber").blocked_damage(self, damage, type)
			else:
				SkillBase.inc_stat("DamageTaken", damage)
				PlayerStats.health -= damage
				PlayerStats.damage_equipment("armor", 2)
				PlayerStats.damage_equipment("helmet")
				Res.create_instance("DamageNumber").damage(self, damage, type)			
		else:
			Res.create_instance("DamageNumber").damage(self, damage, type)

	Res.play_pitched_sample(self, "PlayerHurt")
	UI.soft_refresh()
	
	knockback += (position - attacker.position).normalized() * _knockback
	if ghost_mode: cancel_ghost()
	
	if PlayerStats.health <= 0:
		dead = true
		$Body/LeftArm.visible = false
		$Body/RightArm.visible = false
		change_animation("Body", "Death")
		Res.play_sample(self, "Dead")
		yield(get_tree().create_timer(3), "timeout")
		$"/root/Preloader".re_init()
		$"/root/Game".call_deferred("queue_free")
	else:
		change_animation("Body", "Damage")

func _on_animation_finished(anim_name):
	if "SwordAttack" in anim_name: attacking = false
	elif "SpinAttack" in anim_name or "Magic" in anim_name:
		change_animation("Body", "Idle")
		change_animation("RightArm", "SwordAttack")
		change_animation("LeftArm", "ShieldOff")
		reset_arms()
		$ArmAnimator.stop()
		$Body/RightArm/Weapon.visible = true

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage( PlayerStats.get_damage() ,"player" )

func change_dir(dir, force = false):
	if !force and (direction == dir or !dead and (Input.is_action_pressed("Attack") or Input.is_action_pressed("Shield"))): return
#	running = false
	
	$ArmAnimator.playback_speed = 16 *  PlayerStats.statistic["attack_speed"][0]

	direction = dir
	sprite_direction = ["Back", "Right", "Front", "Left"][dir]
	change_texture($Body, "Body" + animations["Body"])
	change_texture($Body/RightArm, animations["RightArm"], ["Left", "Back"])
	change_texture($Body/LeftArm, alt_animation(animations["LeftArm"]), ["Right", "Back"], {"Back": 1, "Front": 0})
	update_weapon()
	update_shield()

func alt_animation(anim):
	match anim:
		"ShieldOn", "ShieldOff": return "Shield"
		_: return anim

var textures = {}
func get_texture_hack(texture):
	if dead : return load( "res://Sprites/Player/Front/Death.png" )
	if !textures.has(texture): textures[texture] = load(texture)
	return textures[texture]

func change_texture(sprite, texture, on_back = [], move_child = {}):
	var dir = sprite_direction
	if texture == "SpinAttack": dir = "Common"
	sprite.texture = get_texture_hack("res://Sprites/Player/" + dir + "/" + texture + ".png")
	sprite.show_behind_parent = on_back.has(sprite_direction)
	if move_child.has(sprite_direction):
		$Body.move_child(sprite, move_child[sprite_direction])

func change_animation(part, animation):
	if animations[part] == animation: return
	animations[part] = animation
	
	match animation:
		"Idle":
			change_texture($Body, "BodyIdle")
			$Body.hframes = 10
			$BodyAnimator.playback_speed = 16
			$Body.vframes = 1
		"Damage":
			change_texture($Body, "BodyDamage")
			$Body.hframes = 1
			$BodyAnimator.playback_speed = 1
			$Body.vframes = 1
		"Magic":
			$Body/RightArm/Weapon.visible = false
			change_texture($Body/RightArm, "Magic")
			$Body/RightArm.hframes = 1
			$Body/RightArm.vframes = 1
		"SpinAttack":
			change_texture($Body, "SpinAttack")
			change_texture($Body/LeftArm, "SpinAttack")
			change_texture($Body/RightArm, "SpinAttack")
			$Body.hframes = 7
			$Body/LeftArm.hframes = 7
			$Body/RightArm.hframes = 7
			$ArmAnimator.playback_speed = 16
			$BodyAnimator.playback_speed = 16
		"Death":
			change_dir(2)
			change_texture($Body, "Death")
			$Body.hframes = 8
			$BodyAnimator.playback_speed = 10
			$Body.vframes = 1
		"Walk":
			change_texture($Body, "BodyWalk")
			$Body.hframes = 9
			$Body.vframes = 2
			$BodyAnimator.playback_speed = 16
		"ShieldOn":
			change_texture($Body/LeftArm, "Shield", ["Back"])
			$Body/LeftArm.hframes = 2
			update_shield()
		"ShieldOff":
			change_texture($Body/LeftArm, "Shield", ["Right", "Back"])
			$Body/LeftArm.hframes = 2
			update_shield()
	
	if animation == "SwordAttack": return ##LOOOL
	
	match part:
		"Body": $BodyAnimator.play(animation)
		_: $ArmAnimator.play(animation)

func reset_arms():
	$Body/LeftArm.frame = 0
	$Body/RightArm.hframes = 10
	$Body/RightArm.frame = 0
	$Body/RightArm/Weapon.frame = 0
	$Body/RightArm.visible = true
	$Body/RightArm/Weapon.visible = true
	change_dir(direction, true) ##OSTATECZNY HACK ZAGŁADY KODU
	$AttackCollider/Shape.disabled = true

func weapon_sprite():
	if PlayerStats.get_equipment("weapon"):
		return Res.items[PlayerStats.get_equipment("weapon").id].sprite
	else:
		return "Stick" ##nie >:(

func shield_sprite():
	if PlayerStats.get_equipment("shield"):
		return Res.items[PlayerStats.get_equipment("shield").id].sprite
	else:
		return "" ##nope

func update_weapon():
	change_texture($Body/RightArm/Weapon, "Weapons/" + weapon_sprite(), ["Front", "Right", "Left", "Back"])

func update_shield():
	if shield_sprite() == "":
		$Body/LeftArm/Shield.visible = false
	else:
		$Body/LeftArm/Shield.visible = true
		var ordering = ["Back"]
		if animations.LeftArm != "ShieldOn": ordering.append("Right")
		change_texture($Body/LeftArm/Shield, "Shields/" + shield_sprite(), ordering)

func cancel_ghost():
	Res.play_sample(self, "GhostExit")
	ghost_mode.call_deferred("queue_free")
	ghost_mode = null
	GHOST_EFFECT.visible = false

func use_magic(): ##nie tylko magia :|
	for skill in SkillBase.get_active_skills():
		skill = Res.skills[skill]
		
		if  ((!skill.has("magic") or (current_element == skill.magic or skill.magic > 4) ) 
		    and SkillBase.check_combo(skill.combo) 
			and (!triggered_skill or skill != triggered_skill[0]
		    and (skill.combo.size() > triggered_skill[0].combo.size() 
			or skill.combo.back().length() > triggered_skill[0].combo.back().length()))):
			triggered_skill = [skill, 0.2]

func trigger_ghost():
	if ghost_time:
		get_parent().cancel_ghost()
	elif !ghost_mode:
		Res.play_sample(self, "GhostEnter")
		ghost_mode = GHOST.instance()
		ghost_mode.modulate = Color(1, 1, 1, 0.5)
		ghost_mode.ghost_time  = 11 + PlayerStats.statistic["ghost_duration"][0]
		ghost_mode.position.y += 8
		ghost_mode.remove_from_group("players")
		ghost_mode.add_to_group("ghosts")
		ghost_mode.name = "Ghost" ##tego nie powinno być, ale wrogowie sprawdzają name
		ghost_mode.get_node("Body/RightArm/Weapon").visible = false
		ghost_mode.get_node("Body/LeftArm/Shield").visible = false
			
		add_child(ghost_mode)
		GHOST_EFFECT.visible = true
		GHOST_EFFECT.get_node("../AnimationPlayer").play("Activate")

func trigger_skill(skill = triggered_skill[0]):
	triggered_skill = null
	attacking       = false
	SkillBase.current_combo.clear()

	if skill.has("magic"):
		if skill.magic == 5: 
			trigger_ghost()
			return 
	
	if ghost_time : return 
	
	if skill.has("cost"):
		if PlayerStats.mana < skill.cost:
			water_stream_hack = false
			return
		else: PlayerStats.mana -= skill.cost
		
	if skill.has("magic"): change_animation("RightArm", "Magic")
	if skill.has("stats"): for stat in skill.stats: SkillBase.inc_stat(stat)
	if skill.has("projectile"):
		var projectile = Res.create_instance("Projectiles/" + skill.projectile)
		projectile.z_index = 2 
		get_parent().add_child(projectile)
		projectile.position = position - Vector2(0,25)
		if( direction == 2 ):
			projectile.position = position + Vector2(0,15)
		
		projectile.direction = direction
		projectile.intiated()
		
		projectile.damage = skill.damage + int(PlayerStats.statistic["spell_power"][0])
		
		if skill.has("magic"):
			match( str(skill.magic) ):
				"1":
					if SkillBase.has_skill("FireAffinityI"):   projectile.damage *= 1.10
					if SkillBase.has_skill("FireAffinityII"):  projectile.damage *= 1.20
					if SkillBase.has_skill("FireAffinityIII"): projectile.damage *= 1.5151
					if SkillBase.has_skill("FireAffinityIV"):  projectile.damage *= 1.20
					if SkillBase.has_skill("FireAffinityV"):   projectile.damage *= 1.25
					
				"2":
					if SkillBase.has_skill("WaterAffinityI"):   projectile.damage *= 1.10
					if SkillBase.has_skill("WaterAffinityII"):  projectile.damage *= 1.20
					if SkillBase.has_skill("WaterAffinityIII"): projectile.damage *= 1.5151
					if SkillBase.has_skill("WaterAffinityIV"):  projectile.damage *= 1.20
					if SkillBase.has_skill("WaterAffinityV"):   projectile.damage *= 1.25
				"3":
					if SkillBase.has_skill("AirAffinityI"):   projectile.damage *= 1.10
					if SkillBase.has_skill("AirAffinityII"):  projectile.damage *= 1.20
					if SkillBase.has_skill("AirAffinityIII"): projectile.damage *= 1.5151
					if SkillBase.has_skill("AirAffinityIV"):  projectile.damage *= 1.20
					if SkillBase.has_skill("AirAffinityV"):   projectile.damage *= 1.25
				"4":
					if SkillBase.has_skill("EarthAffinityI"):   projectile.damage *= 1.10
					if SkillBase.has_skill("EarthAffinityII"):  projectile.damage *= 1.20
					if SkillBase.has_skill("EarthAffinityIII"): projectile.damage *= 1.5151
					if SkillBase.has_skill("EarthAffinityIV"):  projectile.damage *= 1.20
					if SkillBase.has_skill("EarthAffinityV"):   projectile.damage *= 1.25

				_: pass

		if skill.name == "Water Bubbles": water_stream_hack = 0.1
		if skill.name == "Razor Banana":  wind_spam_hack = 0.5

func _on_other_attack_hit(body):
	if body.is_in_group("secrets"):
		body.hit(self)

func _input(event):
	if event is InputEventMouseButton:
		get_tree().get_root().find_node("Player", true, false).position = get_global_mouse_position()

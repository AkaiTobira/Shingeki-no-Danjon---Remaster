extends Node

const INVENTORY_SIZE = 1000
const EQUIPMENT_SLOTS = ["amulet", "helmet", "shield", "weapon", "armor", "ring", "boots"]
const SLOTS = {}

var level = 1
var experience = 0
var stat_points = 0

var mana = 100
var health = 100

var shield_block = 0.7
var shield_amout = 12

var strength = 1
var dexterity = 1
var intelligence = 1
var vitality = 1

var statistic = {
				#sum, base, item, skill, mod
	"streng" : [    1,1,0,0,0],
	"dexter" : [    1,1,0,0,0],
	"smart"  : [    1,1,0,0,0],
	"vital"  : [    1,1,0,0,0],
	"ph_dmg" : [    1,1,0,0,0],
	"ct_dmg" : [    2,2,0,0,0],
	"cr_res" : [  0.0,0,0,0,0],
	"ct_chc" : [ 0.05,0.05,0,0,0],
	"at_spd" : [    1,1,0,0,0],
	"mv_spd" : [    1,1,0,0,0],
	"ph_res" : [  0.0,0,0,0,0],
	"mg_dmg" : [    1,1,0,0,0],
	"mx_hpp" : [  100,100,0,0,0],
	"mx_man" : [  100,100,0,0,0],
	"sh_res" : [  0.0,0,0,0,0],
	"gh_dur" : [    1,1,0,0,0],
	"mn_reg" : [    1,1,0,0,0],
	"ex_res" : [  0.0,0,0,0,0]
	}

var money = 0
var inventory = []
var equipment = []
var events = {}

signal level_up
signal got_item
signal equipment_changed

var multiplier = [2,2,2,2]
var parameter  = 0.9

var increments = [
	[   1.7, 3.2, 0.045],
	[0.015, 0.12, 0.045],
	[0.045,   1,   23, 0.45],
	[  30,0.5, 0.045, 5.0]
]

func update_skills(skill):
	parameter  = pow(0.90,multiplier[skill])
	match(skill):
		0:
			statistic["ph_dmg"][1] += increments[skill][0]*parameter
			statistic["ct_dmg"][1] += increments[skill][1]*parameter
			statistic["cr_res"][1] += increments[skill][2]*parameter
			multiplier[skill] += 1
		1:
			statistic["ct_chc"][1] += increments[skill][0]*parameter
			statistic["at_spd"][1]  += increments[skill][1]*parameter
			statistic["ph_res"][1] += increments[skill][2]*parameter
			if statistic["at_spd"][1] > 5: statistic["at_spd"][1] = 5.0
			multiplier[skill] += 1
		2:
			statistic["sh_res"][1] += increments[skill][0]*parameter
			statistic["mg_dmg"][1]  += increments[skill][1]*parameter
			statistic["mx_man"][1]     += increments[skill][2]*parameter
			mana         += increments[skill][2]*parameter
			statistic["gh_dur"][1]   += increments[skill][3]*parameter
			multiplier[skill] += 1
		3:
			statistic["mx_hpp"][1]   += increments[skill][0]*parameter
			health       += increments[skill][0]*parameter
			statistic["mn_reg"][1]   += increments[skill][1]*parameter
			statistic["ex_res"][1] += increments[skill][2]*parameter
			statistic["mv_spd"][1]   += increments[skill][3]*parameter
			multiplier[skill] += 1
	
	
	
	

func _ready():
	equipment.resize(EQUIPMENT_SLOTS.size())
	for i in range(EQUIPMENT_SLOTS.size()): SLOTS[EQUIPMENT_SLOTS[i]] = i

func get_damage():
	var damage = strength
	var eq = equipment[PlayerStats.SLOTS["weapon"]]
	
	if eq:
		damage_equipment("weapon") ##to nie powinno tu być, oj nie
		eq = Res.items[eq.id]
		
		damage = eq.attack
		for stat in eq.scaling.keys():
			damage += int(PlayerStats[stat] * eq.scaling[stat])
	
	if SkillBase.has_skill("SuperStrength"): damage *= 5
	
	return damage

func get_defense():
	var defense = vitality
	
	for eq in PlayerStats.equipment:
		if !eq: continue
		
		var item = Res.items[eq.id]
		if item.has("defense"): defense += item.defense
	
	return defense

func get_equipment(slot_name):
	return equipment[SLOTS[slot_name]]

func damage_equipment(slot, damage = 1):
	var eq = equipment[SLOTS[slot]]
	if eq:
		eq.durability -= damage
		
		if eq.durability <= 0:
			Res.play_sample(Res.game.player, "ItemBreak")
			equipment[SLOTS[slot]] = null
			emit_signal("equipment_changed")


func count_item(id):
	var amount = 0
	for item in inventory: if item.id == id: amount += item.stack
	return amount

func subtract_items(id, amount):
	var removed_stacks = []
	
	for item in inventory:
		if item.id == id:
			if item.stack >= amount:
				var am = amount
				amount -= am
				item.stack -= am
			else:
				amount = 0
				item.stack = 0
			
			if item.stack == 0: removed_stacks.append(item)
	
	for item in removed_stacks: inventory.erase(item)

func consume(item):
	var consumed
	
	if item.has("health") and PlayerStats.health < PlayerStats.statistic["mx_hpp"][0]:
		consumed = true
		PlayerStats.health = min(PlayerStats.statistic["mx_hpp"][0], PlayerStats.health + item.health)
	if item.has("mana") and PlayerStats.mana < PlayerStats.statistic["mx_man"][0]:
		consumed = true
		PlayerStats.mana = min(PlayerStats.statistic["mx_man"][0], PlayerStats.mana + item.mana)
	
	if consumed:
		Res.play_sample(Res.game.player, "Consume", false)
		return true
	else:
		Res.play_sample(Res.game.player, "MenuFailed", false)

func recalc_stats():
	for stat in statistic.keys():
		statistic[stat][0] =  statistic[stat][1] + statistic[stat][2] + statistic[stat][3] + statistic[stat][4] 
	pass

func exp_to_level(level):
	return level * level * 4 #+ int(pow(0.99,level)) * level
	
func total_exp(level):
	return level * level * 4#+ int(pow(0.9,level)) * level

func add_experience(amount):
	experience += amount
	
	while experience >= total_exp(level-1) + exp_to_level(level):
		level += 1
		stat_points += 1
		emit_signal("level_up")

func add_item(id, amount = 1, notify = true): ##dorobić obsługę amount
	
	
	var item = Res.items[id]
	
	var slot = -1
	for i in range(inventory.size()):
		if inventory[i].id == id and item.has("max_stack") and inventory[i].stack < item.max_stack:
			slot = i
			break
	
	if slot > -1:
		inventory[slot].stack += 1
		
	elif inventory.size() < PlayerStats.INVENTORY_SIZE:
		var _item = {"id": id, "stack": 1}
		if item.has("durability"):
			_item.durability = item.durability
			_item.max_durability = item.durability
		
		inventory.append(_item)
	else:
		return false
	
	Res.game.player.updateQuest("",id)
	if notify: emit_signal("got_item", id)
	return true
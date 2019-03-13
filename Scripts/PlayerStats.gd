extends Node

const INVENTORY_SIZE  = 1000
const STAT_LIST       = ["attack", "p.resist", "c.resist", "s.resist", "e.resist" , "block", "move speed"]
const EQUIPMENT_SLOTS = ["amulet", "helmet", "shield", "weapon", "armor", "ring", "boots"]
const SLOTS           = {}

var level = 1
var experience = 0
var stat_points = 0

var mana = 100
var health = 100

var shield_block = 0.7
var shield_amout = 12

var statistic = {
				#sum, base, item, skill, mod
	"streng" : [    1,   1,0,0,0],
	"dexter" : [    1,   1,0,0,0],
	"smart"  : [    1,   1,0,0,0],
	"vital"  : [    1,   1,0,0,0],
	"ph_dmg" : [    1,   1,0,0,0],
	"ct_dmg" : [    2,   2,0,0,0],
	"cr_res" : [  0.0,   0,0,0,0],
	"ct_chc" : [ 0.05,0.05,0,0,0],
	"at_spd" : [    1,   1,0,0,0],
	"mv_spd" : [    1,   1,0,0,0],
	"ph_res" : [  0.0,   0,0,0,0],
	"mg_dmg" : [    1,   1,0,0,0],
	"mx_hpp" : [  100, 100,0,0,0],
	"mx_man" : [  100, 100,0,0,0],
	"sh_res" : [  0.0,   0,0,0,0],
	"gh_dur" : [    1,   1,0,0,0],
	"mn_reg" : [    1,   1,0,0,0],
	"ex_res" : [  0.0,   0,0,0,0]
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
	[   1.7,  3.2, 4.5],
	[ 0.015, 0.12, 4.5],
	[ 0.045,    1,  23, 4.5],
	[    30,  0.5, 4.5, 5.0]
]

func update_skills(skill):
	parameter  = pow(0.90,multiplier[skill])
	match(skill):
		0:
			statistic["streng"][1] += 1
			statistic["ph_dmg"][1] += increments[skill][0]*parameter
			statistic["ct_dmg"][1] += increments[skill][1]*parameter
			statistic["cr_res"][1] += increments[skill][2]*parameter
			multiplier[skill]      += 1
		1:
			statistic["dexter"][1] += 1
			statistic["ct_chc"][1] += increments[skill][0]*parameter
			statistic["at_spd"][1] += increments[skill][1]*parameter
			statistic["ph_res"][1] += increments[skill][2]*parameter
			if statistic["at_spd"][1] > 5: statistic["at_spd"][1] = 5.0
			multiplier[skill]      += 1
		2:
			statistic["smart" ][1] += 1
			statistic["sh_res"][1] += increments[skill][0]*parameter
			statistic["mg_dmg"][1] += increments[skill][1]*parameter
			statistic["mx_man"][1] += increments[skill][2]*parameter
			mana                   += increments[skill][2]*parameter
			statistic["gh_dur"][1] += increments[skill][3]*parameter
			multiplier[skill]      += 1
		3:
			statistic["vital" ][1] += 1
			statistic["mx_hpp"][1] += increments[skill][0]*parameter
			health                 += increments[skill][0]*parameter
			statistic["mn_reg"][1] += increments[skill][1]*parameter
			statistic["ex_res"][1] += increments[skill][2]*parameter
			statistic["mv_spd"][1] += increments[skill][3]*parameter
			multiplier[skill]      += 1

func _ready():
	equipment.resize(EQUIPMENT_SLOTS.size())
	for i in range(EQUIPMENT_SLOTS.size()): SLOTS[EQUIPMENT_SLOTS[i]] = i

func get_stats_from_items():
	for eq in equipment:
		if eq :
			#print(eq)
			#var item = Res.items[eq.id]
			#for stat in item.scaling:
				pass


func get_damage():
	return statistic["ph_dmg"][0]

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


func simple_randomizer():
	var tresholds = [ 60 , 84, 96, 106, 110, 112 ]
	var prob = randi()%tresholds[5]
	for i in range(len(tresholds)):
		if prob < tresholds[i]: return i
	return 0
	
func bless_randomizer():
	var tresholds = { "none": 60 , "holy": 80, "cursed": 100 }
	var prob = randi()%100
	for i in tresholds.keys():
		if prob < tresholds[i]: return i
	return "none"
	
func get_if_have_one(id):
	for item_id in len(inventory):
		if inventory[item_id].id == id: return item_id
	return -1

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
		var _item = {"id": id, "stack": 1, "material": 0, "blessing": "none" , "add_to_stat": {} }
		
		var stacked = false
		
		match(item.type):
			"consumable":
				_item.material = 7
				var _tr = get_if_have_one(id)
				if _tr >= 0 : 
					inventory[_tr].stack += amount
					stacked = true
				_item.add_to_stat = item.stats
			"misc":
				_item.material = 6
				var _tr = get_if_have_one(id)
				if _tr >= 0:
					inventory[_tr].stack += amount
					stacked = true
			_:
				_item.material = simple_randomizer()
				_item.blessing =  bless_randomizer()
				
				if item.has("durability"):
					_item.durability     = int( item.durability *  ( 1.0 + (_item.material/5.0)) )
					_item.max_durability = int( item.durability *  ( 1.0 + (_item.material/5.0)) )
				
				if item.type == "ring" or item.type =="amulet":
					_item.add_to_stat[statistic.keys()[randi()%len(statistic.keys())]] =  randf() + 0.5
				
				match(_item.blessing):
					"holy" :
						var new_perk = statistic.keys()[randi()%len(statistic.keys())]
						_item.add_to_stat[new_perk] = randf() + 1
					"cursed" : 
						_item.add_to_stat[statistic.keys()[randi()%len(statistic.keys())]] =  randf() + 2.5
						_item.add_to_stat[statistic.keys()[randi()%len(statistic.keys())]] = -randf() - 0.5
					"none": pass

				if item.has("stats") :
					for stat in item.stats.keys():
						if _item.add_to_stat.has(stat): _item.add_to_stat[stat] += item.stats[stat] * ( 1.0 + (_item.material/5.0))
						else: _item.add_to_stat[stat] = item.stats[stat] * ( 1.0 + (_item.material/5.0))

		if not stacked : inventory.append(_item)
	else:
		return false
	
#	Res.game.player.updateQuest("",id)
	if notify: emit_signal("got_item", id)
	return true
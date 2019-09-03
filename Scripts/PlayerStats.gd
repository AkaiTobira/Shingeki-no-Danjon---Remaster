extends Node

const INVENTORY_SIZE  = 1000
const STAT_LIST       = ["attack", "p.resist", "c.resist", "s.resist", "e.resist" , "block", "move speed"]
const EQUIPMENT_SLOTS = ["amulet", "helmet", "shield", "weapon", "armor", "ring", "boots"]
const SLOTS           = {}

var level = 1
var experience  = 0
var next_level_exp    = total_exp(1)
var current_level_exp = 0
var stat_points = 0

var mana = 100
var health = 100

var shield_block = 0.7
var shield_amout = 12

var statistic = {
				            #sum,    base, item, skill, mod, level
	"streng"            : [    1,   1,0,0,0,0],
	"dexter"            : [    1,   1,0,0,0,0],
	"smart"             : [    1,   1,0,0,0,0],
	"vital"             : [    1,   1,0,0,0,0],
	"physical_damage"   : [    3,   3,0,0,0,0],
	"critical_damage"   : [    6,   6,0,0,0,0],
	"fire_damage"       : [    0,   0,0,0,0,0],
	"wind_damage"       : [    0,   0,0,0,0,0],
	"earth_damage"      : [    0,   0,0,0,0,0],
	"chaos_damage"      : [    0,   0,0,0,0,0],
	"water_damage"      : [    0,   0,0,0,0,0],
	"wind_resistance"   : [  0.0,   0,0,0,0,0],
	"critical_chance"   : [ 0.05,0.05,0,0,0,0],
	"attack_speed"      : [ 0.75,0.75,0,0,0,0],
	"move_speed"        : [    1,   1,0,0,0,0],
	"earth_resistance"  : [  0.0,   0,0,0,0,0],
	"spell_power"       : [    1,   1,0,0,0,0],
	"max_health"        : [  100, 100,0,0,0,0],
	"max_mana"          : [  100, 100,0,0,0,0],
	"water_resistance"  : [  0.0,   0,0,0,0,0],
	"ghost_duration"    : [    3,   3,0,0,0,0],
	"mana_regeneration" : [    5,   5,0,0,0,0],
	"fire_resistance"   : [  0.0,   0,0,0,0,0],
	"block"             : [  0.0,   0,0,0,0,0],
	"armour"            : [  0.0,   0,0,0,0,0],
	}

var money = 0
var inventory = []
var equipment = []
var events    = {}

signal level_up
signal got_item
signal equipment_changed

var increments = [
	[   1.25,   2.50,  1.01],
	[  0.015,   0.12,  1.01],
	[   1.01,      1,    23, 1.01],
	[     30,    0.5,  1.01,  5.0]
]

func update_skills(skill):
	match(skill):
		0: statistic["streng"][5] += 1
		1: statistic["dexter"][5] += 1
		2: statistic["smart" ][5] += 1
		3: statistic["vital" ][5] += 1
	refresh_skill()


func refresh_skill():
	statistic["physical_damage"][5]   = statistic["streng"][5] * increments[0][0]
	statistic["critical_damage"][5]   = statistic["streng"][5] * increments[0][1]
	statistic["wind_resistance"][5]   = statistic["streng"][5] * increments[0][2]

	statistic["critical_chance"][5]   = statistic["dexter"][5] * increments[1][0]
	statistic["attack_speed"][5]      = statistic["dexter"][5] * increments[1][1]
	statistic["earth_resistance"][5]  = statistic["dexter"][5] * increments[1][2]
	if statistic["attack_speed"][5] > 5: statistic["attack_speed"][5] = 4.25

	statistic["water_resistance"][5]  = increments[2][0]*statistic["smart" ][5]
	statistic["spell_power"][5]       = increments[2][1]*statistic["smart" ][5]
	statistic["max_mana"][5]          = increments[2][2]*statistic["smart" ][5]
	statistic["ghost_duration"][5]    = increments[2][3]*statistic["smart" ][5]

	statistic["max_health"][5]        = increments[3][0]*statistic["vital" ][5]
	statistic["mana_regeneration"][5] = increments[3][1]*statistic["vital" ][5] 
	statistic["fire_resistance"][5]   = increments[3][2]*statistic["vital" ][5] 
	statistic["move_speed"][5]        = increments[3][3]*statistic["vital" ][5] 

func _ready():
	equipment.resize(EQUIPMENT_SLOTS.size())
	for i in range(EQUIPMENT_SLOTS.size()): SLOTS[EQUIPMENT_SLOTS[i]] = i

func get_stats_from_items():
	for state in statistic:
		statistic[state][2] = 0 

	for eq in equipment:
		if eq :
			for stat in eq.add_to_stat:
				statistic[stat][2] += eq.add_to_stat[stat]
	refresh_skill()
	recalc_stats()
	
func get_damage():
	var active_dmg = [[statistic["physical_damage"][0], "Physical"]]
	if statistic["fire_damage"][0]  > 0: active_dmg.append([statistic["fire_damage"][0], "Fire"])
	if statistic["wind_damage"][0]  > 0: active_dmg.append([statistic["wind_damage"][0], "Wind"])
	if statistic["earth_damage"][0] > 0: active_dmg.append([statistic["earth_damage"][0], "Earth"])	
	if statistic["water_damage"][0] > 0: active_dmg.append([statistic["water_damage"][0], "Water"])
	if statistic["chaos_damage"][0] > 0: active_dmg.append([statistic["chaos_damage"][0], "Chaos"])
	return active_dmg

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
	
	if item.has("health") and PlayerStats.health < PlayerStats.statistic["max_health"][0]:
		consumed = true
		PlayerStats.health = min(PlayerStats.statistic["max_health"][0], PlayerStats.health + item.health)
	if item.has("mana") and PlayerStats.mana < PlayerStats.statistic["max_mana"][0]:
		consumed = true
		PlayerStats.mana = min(PlayerStats.statistic["max_mana"][0], PlayerStats.mana + item.mana)
	
	if consumed:
		Res.play_sample(Res.game.player, "Consume", false)
		return true
	else:
		Res.play_sample(Res.game.player, "MenuFailed", false)

func recalc_stats():

	var mana_level   = mana/statistic["max_mana"][0]
	var health_level = health/statistic["max_health"][0]

	refresh_skill()

	for stat in statistic.keys():
		statistic[stat][0] =  statistic[stat][1] + statistic[stat][2] + statistic[stat][3] + statistic[stat][4] + statistic[stat][5]

	health = statistic["max_health"][0] * health_level
	mana   = statistic["max_mana"][0]   * mana_level
			
func total_exp(level):
	return 3 * pow(level, 3) / 3 + level * (level+1) * 2 + 5 * level

func add_experience(amount):
	experience += amount
	
	while experience >= next_level_exp:
		level += 1
		stat_points += 1

		current_level_exp = next_level_exp
		next_level_exp   += total_exp(level+1)
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

func add_item(id, amount = 1, notify = true, crafted = false): ##dorobić obsługę amount
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
				if crafted:
					_item.material = 0
					_item.blessing = "none"
				else:
					_item.material = simple_randomizer()
					_item.blessing =  bless_randomizer()

				if item.has("durability"):
					_item.durability     = int( item.durability *  ( 1.0 + (_item.material/5.0)) )
					_item.max_durability = int( item.durability *  ( 1.0 + (_item.material/5.0)) )
				
				if item.type == "ring" or item.type =="amulet":
					_item.add_to_stat[statistic.keys()[randi()%( len(statistic.keys()) -1 )]] =  randf() + 0.5
				
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
	if notify: emit_signal("got_item", [ id, amount ])
	return true
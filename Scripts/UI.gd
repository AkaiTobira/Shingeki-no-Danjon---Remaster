extends CanvasLayer

onready var player = $"../.."

var just_opened = false

func _ready():
	PlayerStats.connect("level_up", $LevelUpLabel, "level_up")
	PlayerStats.connect("got_item",$ItemGetPanel, "got_item")
	SkillBase.connect("new_skill", $SkillAcquiredPanel, "new_skill")
	DungeonState.connect("floor_changed", $FloorLabel, "new_floor")

func _physics_process(delta):
	if !get_tree().paused: return
	
	if !$DialogueBox.process():
		if Input.is_action_just_pressed("Menu") and ($PlayerMenu.visible or $Shop.visible) and !just_opened or $PlayerMenu.new_location["id"] != -1:
			Res.ui_sample("MenuCancel")
			$"FloorLabel".visible = true
			Res.game.leave_menu = true
			$PlayerMenu.visible = false
			$PlayerMenu.in_tab = false
			$Shop.visible = false
			$HUD.visible = true
			get_tree().paused = false
	
	just_opened = false

func init_map_menu(values, types, names, descriptions):
	$PlayerMenu.set_maps_with_locations( values, types, names, descriptions )

func set_location_change_screen(): #TOFINISH
	$PlayerMenu.current_tab         = 4
	$PlayerMenu.can_change_location = true

func enable():
	$PlayerMenu.visible = true
	$HUD.visible = false
	just_opened = true
	refresh()

func soft_refresh():
	$HUD/HealthIndicator.max_value = PlayerStats.statistic["mx_hpp"][0]
	$HUD/HealthIndicator.value = PlayerStats.health
	$HUD/ManaIndicator.max_value = PlayerStats.statistic["mx_man"][0]
	$HUD/ManaIndicator.value = PlayerStats.mana

func refresh():
	$PlayerMenu.refresh()
	soft_refresh()

func on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	PlayerStats.recalc_stats()
	refresh()

func disable_map_change():
	$PlayerMenu.can_change_location = false
	$PlayerMenu.new_location["id"]  = -1

func need_map_change():
	return  $PlayerMenu.new_location["id"] != -1
	
func get_new_map_world():
	return  $PlayerMenu.new_location["world"]
	
func get_new_map_id():
	return  $PlayerMenu.new_location["id"]

func on_inventory_click(i):
	var item = Res.items[PlayerStats.inventory[i].id]
	
	if item.type == "consumable":
		Res.play_sample(player, "Consume", false)
		PlayerStats.inventory[i] = null
		PlayerStats.health += item.health
		refresh()
	else:
		var slot = PlayerStats.EQUIPMENT_SLOTS.find(item.type)
		
		if slot > -1:
			var old = null
			if PlayerStats.equipment[slot] > -1: old = PlayerStats.equipment[slot]
			PlayerStats.equipment[slot] = item.id
			
			if old != null: PlayerStats.inventory[i] = {"id": old, "stack": 1}
			else: PlayerStats.inventory[i] = null
			
			if slot == 3:
				player.update_weapon()
		refresh()
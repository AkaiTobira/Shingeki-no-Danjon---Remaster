extends StaticBody2D

export(String) var type

onready var player_menu = Res.game.player.UI.get_node("PlayerMenu")

func get_placement_info():
	return { "name" : "WorkshopCrafting", "type": Res.EnvironmentType.Box, "flip":false }

func enable_collisions():
	if is_instance_valid($"InteractArea/Shape"): $"InteractArea/Shape".set_disabled(false) 
	if is_instance_valid($"Shape"): $"Shape".set_disabled(false) 

func disable_collisions(): 
	if is_instance_valid($"InteractArea/Shape"): $"InteractArea/Shape".set_disabled(true) 
	if is_instance_valid($"Shape"): $"Shape".set_disabled(true) 

func initialize(id, dungeon_name, my_name, dungeon_level = 0, flip= 0): pass

func interact():
	Res.game.open_menu()
	player_menu.current_tab = 3

func interact_enter():
	player_menu.crafting_station = type

func interact_exit():
	player_menu.crafting_station = null
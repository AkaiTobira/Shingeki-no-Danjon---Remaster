extends Node

var cache = {}

var segments             = {}
var segment_nodes        = {}
var segment_structure    = {}
var enviroment_instances = {}
var tilesets = {}
var items    = []
var skills   = {}
var dungeons = {}
var crafting = []
var location = {}
var enemies

var map_manager = null
var background_generation_lock = false

var game
var music

var disable_cheats = true

enum EnvironmentType {
	Enemy,
	Box,
	Decoration,
	Chest,
	Trap,
}

enum EnviromentPlacement{
	LeftWall,
	RightWall,
	UpWall,
	DownWall,
	Free	
}

func _ready():
	for segment in get_resource_list("Segments"):
		segments[segment.name]      = segment.data
		segments[segment.name].name = segment.name
		segment_nodes[segment.name] = cache_resource("res://Nodes/Segments/" + segment.name + ".tscn")
	
	for tileset in get_resource_list("Tilesets"):
		tilesets[tileset.name] = tileset.data
		var basic_tile             = -1
		var tile_to_floor          = {}
		var tile_size              = {}
		var floor_ids_with_weights = {}
		for flooor in tileset.data.floor:
			if flooor.has("id"):
				floor_ids_with_weights[flooor.id] = flooor.weight
			else: for i in range(flooor.ids.size()):
				if not i : basic_tile = flooor.ids[i]
				floor_ids_with_weights[flooor.ids[i]] = flooor.weights[i]
				tile_to_floor[flooor.ids[i]]          = flooor
				tile_size[flooor.ids[i]]              = flooor.size
		
		tileset.data.tile_size              = tile_size
		tileset.data.tile_to_floor          = tile_to_floor
		tileset.data.floor_ids_with_weights = floor_ids_with_weights
		tileset.data.floor_basic            = basic_tile
		
		var tile_to_wall          = {}
		var wall_ids_with_weights = {}
		var tile_colums           = {}
		for wall in tileset.data.wall:
			if wall.has("id"):
				wall_ids_with_weights[wall.id] = wall.weight
			else: for i in range(wall.ids.size()):
				if not i : basic_tile = wall.ids[i]
				wall_ids_with_weights[wall.ids[i]] = wall.weights[i]
				tile_to_wall[wall.ids[i]]          = wall
				tile_colums[wall.ids[i]]           = wall.cols
		
		tileset.data.tile_to_wall          = tile_to_wall
		tileset.data.wall_ids_with_weights = wall_ids_with_weights
		tileset.data.wall_basic            = basic_tile
		tileset.data.tile_colums           = tile_colums
	
	var resources = get_resource_list("Items")
	items.resize(resources.size())
	for item in resources:
		var item_id       = int(item.name)
		items[item_id]    = item.data
		items[item_id].id = item_id
	
	for skill in get_resource_list("Skills"):
		skills[skill.name] = skill.data
	
	var enviroment_splitter = load( "res://Scripts/EnviromentSplitter.gd" ).new()
	for dungeon in get_resource_list("Dungeons"):
		dungeons[dungeon.name]                  = dungeon.data
		dungeons[dungeon.name]["floor_Objects"] = enviroment_splitter.load_enviroment_objects(dungeon.name)
		
	for enemie in get_resource_list("Enemies"):
		enemies = enemie.data

	
	crafting = read_json("res://Resources/CraftingList.json")
	location = read_json("res://Resources/LocationList.json")
	
	##meh meh (DEBUG)
	SkillBase.acquired_skills.append("Fireball")
#	SkillBase.acquired_skills.append("FireSpear")
#	SkillBase.acquired_skills.append("FireBolt")
#	SkillBase.acquired_skills.append("FireShield")
	SkillBase.acquired_skills.append("WaterBubble")
#	SkillBase.acquired_skills.append("RockPunch")
	SkillBase.acquired_skills.append("WindBanana")
	SkillBase.acquired_skills.append("DualSpark")
	SkillBase.acquired_skills.append("EarthNeedles")
#	SkillBase.acquired_skills.append("WaterBullet")
#	SkillBase.acquired_skills.append("Tornado")

func _process(delta):
	if disable_cheats: return
	delta += 1
	##wszystko to debug D:
	if Input.is_key_pressed(KEY_F2) and Input.is_action_just_pressed("Interact"):
		save_setting("no_music", !File.new().file_exists("user://no_music"))
	if Input.is_key_pressed(KEY_F5):
		PlayerStats.health = 99999999999
		PlayerStats.mana = 99999999999
#		PlayerStats.intelligence = 999999
	
	if Input.is_key_pressed(KEY_F4):
		for item in items:
			PlayerStats.add_item(item.id, 1, false)
		for skill in skills:
			if !skill in SkillBase.acquired_skills: SkillBase.acquired_skills.append(skill)
		game.player.UI.get_node("PlayerMenu").update_skills()

func save_setting(setting, set):
	if set:
		var f = File.new()
		f.open("user://" + setting, f.WRITE)
	else:
		var d = Directory.new()
		d.remove("user://" + setting)

func get_resource_list(resource):
	var resources = []
	
	var dir = Directory.new()
	if dir.open("res://Resources/" + resource +"/") == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if !name.ends_with(".json"):
				name = dir.get_next()
				continue
			
			resources.append({"name": name.left(name.length() - 5), "data": read_json("res://Resources/" + resource + "/" + name)})
			
			name = dir.get_next()
	
	return resources

func read_json(f):
	var file = File.new()
	file.open(f, file.READ)
	var text = file.get_as_text()
	file.close()
	
	var json = parse_json(text)

	assert(json != null)
	
	return json

func play_sample(source, sample, pausable = true, follow_source = true):
	if sample == "": return
	var player = create_instance("SampleInstance")
	player.init(source, sample, pausable, follow_source)
	get_parent().get_node("Game").add_child(player)
	return weakref(player)

func play_pitched_sample(source, sample, pausable = true, follow_source = true):
	if sample == "": return
	var player = create_instance("PitchedSampleInstance")
	player.init(source, sample, pausable, follow_source)
	get_parent().get_node("Game").add_child(player)
	
func ui_sample(sample):
	var player    = AudioStreamPlayer.new()
	player.stream = cache_resource("res://Samples/" + sample + ".ogg")
	player.play()
	get_parent().add_child(player)
	player.connect("finished", player, "queue_free")

func play_music(music):
	if File.new().file_exists("user://no_music"): return
	var player    = AudioStreamPlayer.new()
	player.stream = cache_resource("res://Music/" + music + ".ogg")
	player.play()
	set_music(player)

func set_music(player):
	if music: music.call_deferred("queue_free")
	music = player
	add_child(music)

func create_instance(node):
	return get_node(node).instance()

func get_node(node):
	return cache_resource("res://Nodes/" + node + ".tscn")

func get_scene(scene_path):
	return cache_resource(scene_path)

func get_item_texture(id):
	return cache_resource("res://Sprites/Items/" + str(id) + ".png")
	
#func get_item_hd_texture(id):
#	return cache_resource("res://Sprites/Items/HD/" + str(id) + ".png")
	
func get_skill_texture(skill):
	if cache_resource("res://Sprites/Skills/" + skill + ".png"):
		return cache_resource("res://Sprites/Skills/" + skill + ".png")
	else:
		return cache_resource("res://Sprites/Skills/NoSkill.png")

func get_skill_hd_texture(skill):
	if cache_resource("res://Sprites/Skills/HD/" + skill + ".png"):
		return cache_resource("res://Sprites/Skills/HD/" + skill + ".png")
	else:
		return cache_resource("res://Sprites/Skills/HD/NoSkill.png")

func cache_resource(res):
	if !cache.has(res): cache[res] = load(res)
	return cache[res]

func get_node_path( type_name ):
	match(type_name):
		EnvironmentType.Enemy     : return "res://Nodes/Enemies/"
		EnvironmentType.Box       : return "res://Nodes/Objects/"
		EnvironmentType.Decoration: return "res://Nodes/Environment/"
		EnvironmentType.Chest     : return "res://Nodes/Objects/"
		EnvironmentType.Trap      : return "res://Nodes/Objects/"
		_: return ""

func cache_instance(instance_name, instance_type):
	if not instance_name in enviroment_instances.keys():
		enviroment_instances[instance_name] =  load(get_node_path(instance_type) + instance_name +".tscn").instance()
	return enviroment_instances[instance_name]

func cache_segment_structure(segment):
	if segment_structure.has(segment) : return segment_structure[segment]
	var segment_shape_parser   = load( "res://Scripts/SegmentStructureParser.gd" ).new()
	segment_structure[segment] = segment_shape_parser.parse(Res.segment_nodes[segment])
	return segment_structure[segment]

func weighted_random(chances):
	var sum = 0
	for value in chances.values(): sum += int(value)
	if sum == 0: return
	
	var chances2 = {}
	chances2[chances.keys()[0]] = chances.values()[0]
	
	for i in range(chances.size()-1):
		chances2[chances.keys()[i+1]] = int(chances2[chances.keys()[i]] + chances[chances.keys()[i+1]])
	
	var value = randi() % (sum+1)
	for chance in chances2.keys():
		if chances2[chance] >= value:
			return chance
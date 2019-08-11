extends Node

var emviroment = {
    Res.EnviromentPlacement.LeftWall : { Res.EnvironmentType.Decoration: [], 
                                         Res.EnvironmentType.Box:        [], 
                                         Res.EnvironmentType.Chest:      [], 
                                         Res.EnvironmentType.Trap:       [] },
    Res.EnviromentPlacement.RightWall: { Res.EnvironmentType.Decoration: [], 
                                         Res.EnvironmentType.Box:        [], 
                                         Res.EnvironmentType.Chest:      [], 
                                         Res.EnvironmentType.Trap:       [] },
    Res.EnviromentPlacement.UpWall   : { Res.EnvironmentType.Decoration: [], 
                                         Res.EnvironmentType.Box:        [], 
                                         Res.EnvironmentType.Chest:      [], 
                                         Res.EnvironmentType.Trap:       [] },
    Res.EnviromentPlacement.DownWall : { Res.EnvironmentType.Decoration: [], 
                                         Res.EnvironmentType.Box:        [], 
                                         Res.EnvironmentType.Chest:      [], 
                                         Res.EnvironmentType.Trap:       [] },
    Res.EnviromentPlacement.Free     : { Res.EnvironmentType.Decoration: [], 
                                         Res.EnvironmentType.Box:        [], 
                                         Res.EnvironmentType.Chest:      [], 
                                         Res.EnvironmentType.Trap:       [] }
}

func load_enviroment_objects(dungeon_name):
	load_enviroments_by_type(Res.dungeons[dungeon_name]["environment_objects"], Res.EnvironmentType.Decoration)
	load_enviroments_by_type(Res.dungeons[dungeon_name]["breakable_objects"  ], Res.EnvironmentType.Box)
	load_enviroments_by_type(Res.dungeons[dungeon_name]["containers_objects" ], Res.EnvironmentType.Chest)
	load_enviroments_by_type(Res.dungeons[dungeon_name]["trap_objects"       ], Res.EnvironmentType.Trap)
	return emviroment

func load_enviroments_by_type(enviroments, objType):
	for obj in enviroments:
		var instance = Res.cache_instance(obj, objType)
		if instance == null  : 
			#print( obj, " Error in name in json : Check  =  " + objType) 
			continue
		if instance.placement   == instance.PLACEMENT.LEFT_OR_RIGHT_WALL:
			emviroment[ Res.EnviromentPlacement.LeftWall ][objType].append(obj)
			emviroment[ Res.EnviromentPlacement.RightWall][objType].append(obj)
		elif instance.placement == instance.PLACEMENT.UP_OR_DOWN_WALL:
			emviroment[ Res.EnviromentPlacement.UpWall   ][objType].append(obj)
			emviroment[ Res.EnviromentPlacement.DownWall ][objType].append(obj)
		elif instance.placement == instance.PLACEMENT.DOWN_WALL:
			emviroment[ Res.EnviromentPlacement.DownWall ][objType].append(obj)
		elif instance.placement == instance.PLACEMENT.UP_WALL:
			emviroment[ Res.EnviromentPlacement.UpWall   ][objType].append(obj)
		elif instance.placement == instance.PLACEMENT.EVERY_WALL:
			emviroment[ Res.EnviromentPlacement.LeftWall ][objType].append(obj)
			emviroment[ Res.EnviromentPlacement.RightWall][objType].append(obj)
			emviroment[ Res.EnviromentPlacement.UpWall   ][objType].append(obj)
			emviroment[ Res.EnviromentPlacement.DownWall ][objType].append(obj)
		elif instance.placement == instance.PLACEMENT.WALL_FREE:
			emviroment[ Res.EnviromentPlacement.Free     ][objType].append(obj)

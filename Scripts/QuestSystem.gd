extends Node

var Quests = {
	
	"Hunt" : { 
		"Status" : { "Aquired" : false, "Done" : false }, 
		"Items":{ 1 : { "Amount"   : 0, "Required" : 1, "Finished" : false }, },
		"Mob" : { "Puncher" : { "AlreadyKilled" : 0 , "NeedToBeKilled" : 1, "Finished" : false } , "Grinder" : { "AlreadyKilled" : 0 ,  "NeedToBeKilled" : 1, "Finished" : false } }, 
		"Reward" : { "Exp" : 100,  "Money" : 100, "Items" : { 1 : 1,  2 : 2 } } 
		}   ,
	"Uganda" : { 
		"Status" : { "Aquired" : false, "Done" : false }, 
		"Items":{  },
		"Mob" : { "Puncher" : { "AlreadyKilled" : 0 , "NeedToBeKilled" : 2, "Finished" : false } , "Grinder" : { "AlreadyKilled" : 0 ,  "NeedToBeKilled" : 2, "Finished" : false } }, 
		"Reward" : { "Exp" : 100,  "Money" : 100, "Items" : { randi()%20 : 1,  randi()%20 : 2, randi()%20 : 3, randi()%20 : 4  } } 
		}   
		
    }
    
func addQuest(ques):
	if ques in Quests.keys():
		if !Quests[ques]["Status"]["Aquired"]:
			Quests[ques]["Status"]["Aquired"] = true
		else:
			return
		
		for item in PlayerStats.inventory:
			if item.id in Quests[ques]["Items"].keys():
				Quests[ques]["Items"][item.id]["Amount"] = PlayerStats.count_item(item.id)
				if Quests[ques]["Items"][item.id]["Amount"] >= Quests[ques]["Items"][item.id]["Required"]:
					Quests[ques]["Items"][item.id]["Finished"] = true
					#print("Checkpoint ", item.id )
		#print(ques, " in progress")
		
func is_quest_done(ques):
	return Quests[ques]["Status"]["Done"]
		
func is_quest_aquired(ques):
	return Quests[ques]["Status"]["Aquired"]
		
func checkQuest(ques):
	
	for mob in Quests[ques]["Mob"].keys():
		if !Quests[ques]["Mob"][mob]["Finished"] : return false
				
	for item in Quests[ques]["Items"].keys():
		if !Quests[ques]["Items"][item]["Finished"] : return false
		
	return true
		
func updateQuest( mob = null, item = null, place = null ):

	for ques in Quests.keys():
		if Quests[ques]["Status"]["Aquired"] and !Quests[ques]["Status"]["Done"]:
			
			if  mob in Quests[ques]["Mob"].keys():
				Quests[ques]["Mob"][mob]["AlreadyKilled"] += 1
				if Quests[ques]["Mob"][mob]["AlreadyKilled"] >= Quests[ques]["Mob"][mob]["NeedToBeKilled"]:
					Quests[ques]["Mob"][mob]["Finished"] = true
					#print("Checkpoint ", mob )
					
			if item in Quests[ques]["Items"].keys():
				Quests[ques]["Items"][item]["Amount"] = PlayerStats.count_item(item)
				if Quests[ques]["Items"][item]["Amount"] >= Quests[ques]["Items"][item]["Required"]:
					Quests[ques]["Items"][item]["Finished"] = true
					#print("Checkpoint ", item )
				else:
					Quests[ques]["Items"][item]["Finished"] = false
					
			if !checkQuest(ques) : continue
					
			Quests[ques]["Status"]["Done"] = true
			#print(ques," Requierments Complete")
			
func add_quest_rewards(ques):
	PlayerStats.add_experience(Quests[ques]["Reward"]["Exp"])
	PlayerStats.money += Quests[ques]["Reward"]["Money"]
					
	for item in Quests[ques]["Reward"]["Items"].keys():
		for i in range(Quests[ques]["Reward"]["Items"][item]):
			PlayerStats.add_item(item)
	
	#print(ques," Rewards Recived")
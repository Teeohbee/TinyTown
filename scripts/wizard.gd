extends "res://scripts/world/npc.gd"

# The bee thief. Only appears once Granny has asked for help, and only until he's beaten.


func _ready():
	super._ready()
	if PlayerState.quest_stage("bees") != 1:
		queue_free()


func has_news():
	return true


func interact(player):
	await Dialogue.say([
		"Hah! I see that ol' granny spun you a yarn!",
		"Well, you've come for the bees then? Bring it!",
	], speaker_name)
	player.start_battle("wizard")

extends StaticBody2D


func _ready():
	match PlayerState.quest_status:
		PlayerState.QuestStatuses.NOT_STARTED:
			hide()
		PlayerState.QuestStatuses.ACCEPTED:
			show()
		PlayerState.QuestStatuses.COMPLETED:
			queue_free()


# Returns the dialogue for this character
func dialogue():
	return [
		"Hah! I see that ol' granny",
		"spun you a yarn!",
		"Well, you've come for the bees then?",
		"Bring it!"
	]

extends StaticBody2D

const NOT_STARTED_DIALOGUE = [
	"Hello, you look like a strapping lad",
	"I need some help y'see, an evil wizard",
	"has stolen all my bees, yes bees!",
	"I'd be grateful if you could get them back!",
	"He's holed up in the scary looking castle",
	"to the East, thanks lovey!"
]

const ACCEPTED_DIALOGUE = [
	"You're ever so kind lovey, helping", "a little old lady like me.", "Chop, chop now!"
]

const COMPLETED_DIALOGUE = ["This is impossible, how did you do this?"]


# Returns the dialogue for this character
func dialogue():
	match PlayerState.quest_status:
		PlayerState.QuestStatuses.NOT_STARTED:
			PlayerState.progress_quest_status()
			return NOT_STARTED_DIALOGUE
		PlayerState.QuestStatuses.ACCEPTED:
			return ACCEPTED_DIALOGUE
		PlayerState.QuestStatuses.COMPLETED:
			return COMPLETED_DIALOGUE

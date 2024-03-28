extends StaticBody2D

signal player_healed

const NOT_HURT_DIALOGUE = [
	"Hello, this water is so refreshing",
	"if ever you're tired and need to freshen",
	"up, come back and talk to me",
]

const HURT_DIALOGUE = [
	"Oooh have you been fighting?",
	"Here, have some refreshing water",
]


# Returns the dialogue for this character
func dialogue():
	if PlayerState.health < PlayerState.max_health:
		emit_signal("player_healed")
		return HURT_DIALOGUE
	return NOT_HURT_DIALOGUE

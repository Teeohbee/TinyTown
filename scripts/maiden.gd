extends "res://scripts/world/npc.gd"

# Heals the hero for free at the well. Also where you wake up after a defeat.

const NOT_HURT_DIALOGUE = [
	"Hello, this water is so refreshing.",
	"If ever you're tired and need to freshen up, come back and talk to me.",
]

const HURT_DIALOGUE = [
	"Oooh, have you been fighting?",
	"Here, have some refreshing water.",
]


func needs_healing():
	return PlayerState.is_hurt() or PlayerState.magic < PlayerState.max_magic or PlayerState.status_effect != ""


func has_news():
	return needs_healing()


func interact(_player):
	if not needs_healing():
		await Dialogue.say(NOT_HURT_DIALOGUE, speaker_name)
		return
	await Dialogue.say(HURT_DIALOGUE, speaker_name)
	Audio.play_sound("heal")
	PlayerState.full_restore()
	await Dialogue.say(["Your HP and MP were fully restored."])

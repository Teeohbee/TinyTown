extends "res://scripts/world/npc.gd"

# A clear spring by Bram's hut. Free healing so the mine isn't a long walk back to town.


func interact(_player):
	if not PlayerState.is_hurt() and PlayerState.magic >= PlayerState.max_magic and PlayerState.status_effect == "":
		await Dialogue.say(["A clear, cold spring. You're not thirsty right now."])
		return
	Audio.play_sound("heal")
	PlayerState.full_restore()
	await Dialogue.say(["You drink from the spring. HP and MP fully restored!"])

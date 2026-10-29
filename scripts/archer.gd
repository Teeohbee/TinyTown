extends "res://scripts/world/npc.gd"

# Gives up her bow if the hero wins 7 battles in a row without being defeated.


func has_news():
	var stage = PlayerState.quest_stage("sharpshooter")
	return stage == 0 or (stage == 1 and PlayerState.kills_since_last_defeat >= PlayerState.KILLS_FOR_BOW)


func interact(_player):
	if PlayerState.bow_upgrade:
		await Dialogue.say(["I've got nothing to say to you..."], speaker_name)
		return
	if PlayerState.kills_since_last_defeat < PlayerState.KILLS_FOR_BOW:
		PlayerState.set_quest_stage("sharpshooter", 1)
		var remaining = PlayerState.KILLS_FOR_BOW - PlayerState.kills_since_last_defeat
		await Dialogue.say([
			"Hah! Another bullseye! Oh... Hi!",
			"You as good a shot as me? I'll give you my trusty bow",
			"if you can defeat 7 enemies without being beaten. %d to go." % remaining,
		], speaker_name)
		return
	await Dialogue.say(["No way! You actually did it?", "This is so unfair... fine, have it!"], speaker_name)
	Audio.play_sound("obtain_upgrade")
	PlayerState.apply_bow_upgrade()
	PlayerState.set_quest_stage("sharpshooter", 2)
	await Dialogue.say(["You got the Archer's Bow! Attack +3-4, and you learned Volley!"])

extends "res://scripts/world/npc.gd"

# Bram the woodcutter. Lends the lantern for the mine, and hands over his axe once Pip is safe.


func has_news():
	var stage = PlayerState.quest_stage("apprentice")
	return stage == 1 or (PlayerState.has_flag("pip_freed") and not PlayerState.axe_upgrade)


func interact(_player):
	var stage = PlayerState.quest_stage("apprentice")
	if stage == 0:
		await Dialogue.say([
			"Name's Bram. I cut wood. That's about the size of it.",
			"Town folk don't come out this way much. Can't say I blame 'em lately.",
		], speaker_name)
	elif stage == 1:
		await Dialogue.say([
			"Granny sent you? About Pip?",
			"...Two weeks back a fella in a purple hood came by. Asked about the Old Mine.",
			"Pip followed him. Said he'd find out what the stranger was after. Brave lad. Daft lad.",
			"The mine's north of here, up the path. Nobody's been down there since the moles got big.",
			"You'll want this. It's dark as a boot down there.",
		], speaker_name)
		await give_item("lantern")
		PlayerState.set_quest_stage("apprentice", 2)
		await Dialogue.say(["Bring him back, will you?"], speaker_name)
	elif not PlayerState.has_flag("pip_freed"):
		await Dialogue.say([
			"The mine's north, up the path. Keep that lantern lit.",
			"If you get hurt, the spring by my hut will set you right.",
		], speaker_name)
	elif not PlayerState.axe_upgrade:
		await Dialogue.say([
			"Pip came running past an hour ago yelling about a hero. That'd be you, then.",
			"I'm not much for words. Here.",
			"My father's axe. Swing it like you mean it and shout TIMBER. Works every time.",
		], speaker_name)
		Audio.play_sound("obtain_upgrade")
		PlayerState.apply_axe_upgrade()
		await Dialogue.say(["You got the Woodcutter's Axe! Attack +4-5, and you learned Timber!"])
	else:
		await Dialogue.say(["Wood doesn't cut itself. Well. Not usually."], speaker_name)

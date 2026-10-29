extends "res://scripts/world/npc.gd"

# Fern the forager wants three Glowcaps.

const GLOWCAPS_WANTED = 3


func has_news():
	var stage = PlayerState.quest_stage("glowcaps")
	return stage == 0 or (stage == 1 and PlayerState.item_count("mushroom") >= GLOWCAPS_WANTED)


func interact(_player):
	var stage = PlayerState.quest_stage("glowcaps")
	if stage == 0:
		await Dialogue.say([
			"Oh! A visitor! Mind the mushrooms. Not those ones. Those ones are fine.",
			"I'm after Glowcaps. They glow, you see. Hence the name.",
			"They pop up all over these woods. Bring me three and I'll make it worth your while.",
		], speaker_name)
		PlayerState.set_quest_stage("glowcaps", 1)
	elif stage == 1 and PlayerState.item_count("mushroom") < GLOWCAPS_WANTED:
		var remaining = GLOWCAPS_WANTED - PlayerState.item_count("mushroom")
		await Dialogue.say(["%d more Glowcap%s, please! Try the quiet corners of the woods." % [remaining, "" if remaining == 1 else "s"]], speaker_name)
	elif stage == 1:
		PlayerState.remove_item("mushroom", GLOWCAPS_WANTED)
		await Dialogue.say(["Three Glowcaps! Oh, they're lovely. Look at them glow!", "Here, these will put a spring in your step."], speaker_name)
		await give_item("ether", 3)
		await give_gold(40)
		PlayerState.set_quest_stage("glowcaps", 2)
	else:
		await Dialogue.say(["My Glowcap stew is coming along nicely. Don't ask what's in it. Glowcaps. That's what's in it."], speaker_name)

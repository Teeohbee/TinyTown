extends "res://scripts/world/npc.gd"

# Forges the hero a sword once they reach level 3, and sells bombs to the brave.


func has_news():
	return PlayerState.quest_stage("blacksmith") == 0 or (
		PlayerState.level >= PlayerState.LEVEL_FOR_SWORD and not PlayerState.sword_upgrade
	)


func interact(_player):
	if PlayerState.quest_stage("blacksmith") == 0:
		PlayerState.set_quest_stage("blacksmith", 1)
	if PlayerState.level == 1:
		await Dialogue.say([
			"Hrmph, you look weak...",
			"Too weak to wield one of my swords. Come back when you're stronger.",
		], speaker_name)
	elif PlayerState.level < PlayerState.LEVEL_FOR_SWORD:
		await Dialogue.say([
			"You've got stronger, not bad.",
			"A little more and I'll give you one of my swords!",
		], speaker_name)
	elif not PlayerState.sword_upgrade:
		await Dialogue.say(["Very well, a promise is a promise.", "Here, your new blade."], speaker_name)
		Audio.play_sound("obtain_upgrade")
		PlayerState.apply_sword_upgrade()
		PlayerState.set_quest_stage("blacksmith", 2)
		await Dialogue.say(["You got the Blacksmith's Sword! Attack +3-4."])
	else:
		await Dialogue.say(["How's that new sword treating you?"], speaker_name)
		await offer_bombs()


func offer_bombs():
	var answer = await Dialogue.choose(
		"I've got bombs, if you're the sort. 25 gold apiece. Want one? (You have %d G)" % PlayerState.gold,
		["Buy a bomb", "No thanks"], speaker_name)
	if answer != 0:
		await Dialogue.say(["Go get killing, son."], speaker_name)
		return
	if PlayerState.spend_gold(Items.item("bomb")["price"]):
		PlayerState.add_item("bomb")
		Audio.play_sound("obtain_upgrade")
		await Dialogue.say(["Mind your fingers."], speaker_name)
	else:
		await Dialogue.say(["Come back when you've got the coin."], speaker_name)

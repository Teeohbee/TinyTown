extends "res://scripts/world/npc.gd"

# A travelling merchant. Lists her stock as a choice menu until you leave.

@export var stock: Array[String] = ["potion", "hi_potion", "ether", "antidote"]


func interact(_player):
	await Dialogue.say(["Welcome, welcome! Finest wares this side of the castle."], speaker_name)
	while true:
		var options = []
		for item_id in stock:
			options.append("%s  %dG" % [Items.display_name(item_id), Items.item(item_id)["price"]])
		options.append("Leave")
		var picked = await Dialogue.choose("What'll it be? You have %d G." % PlayerState.gold, options, speaker_name)
		if picked >= stock.size():
			await Dialogue.say(["Safe travels!"], speaker_name)
			return
		var item_id = stock[picked]
		if PlayerState.spend_gold(Items.item(item_id)["price"]):
			PlayerState.add_item(item_id)
			Audio.play_sound("obtain_upgrade")
			await Dialogue.say(["One %s. Pleasure doing business! (You have %d.)" % [Items.display_name(item_id), PlayerState.item_count(item_id)]], speaker_name)
		else:
			await Dialogue.say(["Ooh, you're a little short there, love."], speaker_name)

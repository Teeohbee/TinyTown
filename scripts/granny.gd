extends "res://scripts/world/npc.gd"

# Granny gives out both main quests: the bees (Chapter 1) and her grandson Pip (Chapter 2).

const END_SCENE_PATH = "res://scenes/end_screen.tscn"

const NOT_STARTED_DIALOGUE = [
	"Hello, you look like a strapping lad.",
	"I need some help y'see. An evil wizard has stolen all my bees. Yes, bees!",
	"I'd be ever so grateful if you could get them back.",
	"He's holed up in the scary looking castle to the East. Thanks lovey!",
]

const ACCEPTED_DIALOGUE = [
	"You're ever so kind lovey, helping a little old lady like me.",
	"The castle's to the East. Chop, chop now!",
]

const BEES_RETURNED_DIALOGUE = [
	"My golly, you actually did it! Listen to them buzz!",
	"Here, have some of their honey. And a little something for your trouble.",
]

const PIP_REQUEST_DIALOGUE = [
	"Oh, lovey... while you're here. It's my grandson, Pip.",
	"He went to work for Bram the woodcutter, out in the Autumn Woods past the West Gate.",
	"He always writes on Sundays. It's been three Sundays now.",
]

const PIP_WAITING_DIALOGUE = [
	"Any news of my Pip?",
	"The West Gate is past the orchard, left of the beehives. Bram's hut is in the woods.",
]

const PIP_RETURNED_DIALOGUE = [
	"Pip! Oh, my Pip is home!",
	"He told me everything. Mordrin, the mine, that dreadful Mole King...",
	"You're a hero, lovey. A proper hero. Tiny Town owes you everything.",
]

const AFTER_EVERYTHING_DIALOGUE = [
	"Pip hasn't stopped talking about you since he got home.",
	"The bees have been ever so busy too. Take another pot of honey, lovey.",
]


func has_news():
	var bees = PlayerState.quest_stage("bees")
	var apprentice = PlayerState.quest_stage("apprentice")
	var pip_home = apprentice == 4 and PlayerState.has_flag("pip_freed")
	return bees == 0 or bees == 2 or (bees == 3 and apprentice == 0) or pip_home


func interact(_player):
	var bees = PlayerState.quest_stage("bees")
	var apprentice = PlayerState.quest_stage("apprentice")
	if bees == 0:
		await Dialogue.say(NOT_STARTED_DIALOGUE, speaker_name)
		PlayerState.set_quest_stage("bees", 1)
	elif bees == 1:
		await Dialogue.say(ACCEPTED_DIALOGUE, speaker_name)
	elif bees == 2:
		await Dialogue.say(BEES_RETURNED_DIALOGUE, speaker_name)
		await give_item("honey", 2)
		await give_gold(50)
		PlayerState.set_quest_stage("bees", 3)
		await ask_about_pip()
	elif apprentice == 0:
		await ask_about_pip()
	elif apprentice < 4 or not PlayerState.has_flag("pip_freed"):
		await Dialogue.say(PIP_WAITING_DIALOGUE, speaker_name)
	elif apprentice == 4:
		await Dialogue.say(PIP_RETURNED_DIALOGUE, speaker_name)
		PlayerState.set_quest_stage("apprentice", 5)
		await give_gold(150)
		PlayerState.save_game(get_tree().get_first_node_in_group("player").position)
		SceneTransition.change_scene_to_file(END_SCENE_PATH)
	else:
		await Dialogue.say(AFTER_EVERYTHING_DIALOGUE, speaker_name)
		if not PlayerState.has_item("honey"):
			await give_item("honey")


func ask_about_pip():
	await Dialogue.say(PIP_REQUEST_DIALOGUE, speaker_name)
	var answer = await Dialogue.choose("Would you look for him, lovey?", ["Of course", "Not right now"], speaker_name)
	if answer == 0:
		await Dialogue.say(["Bless you! Here's my key to the West Gate. Do be careful."], speaker_name)
		await give_item("gate_key")
		PlayerState.set_quest_stage("apprentice", 1)
	else:
		await Dialogue.say(["Oh... alright, lovey. Do come back if you change your mind."], speaker_name)

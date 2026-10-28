extends RefCounted

# Quests shown in the pause menu's quest log. PlayerState.quests holds id -> stage.
# Stage 0 means not started (hidden). The last stage in "stages" means complete.

const QUESTS = {
	"bees": {
		"name": "Granny's Bees",
		"chapter": 1,
		"stages": [
			"",
			"A wizard stole Granny's bees! He's holed up in the castle to the East.",
			"The wizard is beaten and the bees are free. Tell Granny the good news.",
			"Granny has her bees back.",
		],
	},
	"apprentice": {
		"name": "The Lost Apprentice",
		"chapter": 2,
		"stages": [
			"",
			"Granny's grandson Pip hasn't come home from the Autumn Woods. Use the Gate Key on the West Gate.",
			"Bram the woodcutter says Pip followed a hooded stranger into the Old Mine. Take his lantern and find him.",
			"The Mole King is beaten. His Iron Key opens the deep gate of the mine.",
			"Mordrin is beaten and Pip is free! Let Granny know he's safe.",
			"Pip is home safe. Granny is over the moon.",
		],
	},
	"glowcaps": {
		"name": "Glowcaps for Fern",
		"chapter": 2,
		"stages": [
			"",
			"Fern the forager wants 3 Glowcaps. They grow in the Autumn Woods.",
			"Fern has her Glowcaps.",
		],
	},
	"sharpshooter": {
		"name": "Sharpshooter",
		"chapter": 1,
		"stages": [
			"",
			"The archer will hand over her bow if you defeat 7 enemies without dying.",
			"The archer's bow is yours.",
		],
	},
	"blacksmith": {
		"name": "Worthy of Steel",
		"chapter": 1,
		"stages": [
			"",
			"The blacksmith will forge you a sword once you reach level 3.",
			"The blacksmith's sword is yours.",
		],
	},
}

const QUEST_ORDER = ["apprentice", "glowcaps", "bees", "sharpshooter", "blacksmith"]


static func quest(quest_id):
	return QUESTS[quest_id]


static func final_stage(quest_id):
	return QUESTS[quest_id]["stages"].size() - 1


static func stage_description(quest_id, stage):
	return QUESTS[quest_id]["stages"][stage]

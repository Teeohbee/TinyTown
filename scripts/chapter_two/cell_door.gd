extends "res://scripts/world/npc.gd"

# The bars of Pip's cell. Pip talks through them until Mordrin is beaten.


func _ready():
	super._ready()
	if PlayerState.has_flag("pip_freed"):
		queue_free()


func has_news():
	return PlayerState.has_flag("mordrin_defeated")


func interact(_player):
	if not PlayerState.has_flag("mordrin_defeated"):
		await Dialogue.say([
			"Psst! Over here! Are you from town?",
			"I'm Pip! That hooded creep, Mordrin, locked me in here.",
			"He says the bee wizard was his master, and he's going to get even with Tiny Town.",
			"The keys are on his belt. You'll have to... persuade him.",
		], "Pip")
		return
	await Dialogue.say(["You wrench the cell door open."])
	PlayerState.set_flag("pip_freed")
	Audio.play_sound("obtain_upgrade")
	await Dialogue.say([
		"You did it! You actually did it!",
		"I'm running straight home to Gran. Tell Bram I'm sorry about the axe handle. He'll know.",
	], "Pip")
	get_tree().call_group("npc", "on_pip_freed")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()

extends "res://scripts/world/npc.gd"

# The locked gate between Tiny Town and the Autumn Woods. Granny has the key.


func _ready():
	super._ready()
	if PlayerState.has_flag("west_gate_open"):
		queue_free()


func interact(_player):
	if not PlayerState.has_item("gate_key"):
		await Dialogue.say(["The West Gate is locked tight.", "Beyond it, the Autumn Woods. Somebody in town must have a key."])
		return
	await Dialogue.say(["You unlock the West Gate with Granny's key."])
	Audio.play_sound("obtain_upgrade")
	PlayerState.set_flag("west_gate_open")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()

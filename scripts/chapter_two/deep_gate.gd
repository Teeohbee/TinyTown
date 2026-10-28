extends "res://scripts/world/npc.gd"

# The iron gate between the mine and Mordrin's sanctum. Opens with the Mole King's Iron Key.


func _ready():
	super._ready()
	if PlayerState.has_flag("deep_gate_open"):
		queue_free()


func interact(_player):
	if not PlayerState.has_item("iron_key"):
		await Dialogue.say([
			"A heavy iron gate with a big, mole-sized keyhole.",
			"You can hear chanting on the other side.",
		])
		return
	await Dialogue.say(["The Iron Key turns with a horrible screech. The gate swings open."])
	Audio.play_sound("obtain_upgrade")
	PlayerState.set_flag("deep_gate_open")
	PlayerState.remove_item("iron_key")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

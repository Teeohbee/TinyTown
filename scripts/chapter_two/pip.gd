extends "res://scripts/world/npc.gd"

# Granny's grandson. Locked up in the mine until rescued, then home in Tiny Town.

@export var in_town = false


func _ready():
	super._ready()
	var freed = PlayerState.has_flag("pip_freed")
	if freed != in_town:
		queue_free()


func on_pip_freed():
	if in_town:
		return
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 48, 0.8)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()


func interact(_player):
	if in_town:
		await Dialogue.say([
			"Gran won't let me out of her sight now. Worth it, though.",
			"Bram says I can have my job back when I'm 'less daft'. So, never.",
		], speaker_name)
	else:
		await Dialogue.say(["Mordrin's right there! Be careful!"], speaker_name)

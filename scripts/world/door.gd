extends "res://scripts/world/npc.gd"

# A doorway you walk into to travel. Can require a key item, with lines for when you lack it.

@export_file("*.tscn") var target_scene = ""
@export var target_spawn = ""
@export var required_item = ""
@export var locked_lines: Array[String] = []
@export var entering_lines: Array[String] = []


func interact(player):
	if required_item != "" and not PlayerState.has_item(required_item):
		await Dialogue.say(locked_lines)
		return
	if not entering_lines.is_empty() and not PlayerState.has_flag("entered_" + name):
		PlayerState.set_flag("entered_" + name)
		await Dialogue.say(entering_lines)
	player.warp_to(target_scene, target_spawn)

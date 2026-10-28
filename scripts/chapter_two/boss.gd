extends "res://scripts/world/npc.gd"

# A boss standing on the map. Talk to start the fight; gone for good once beaten.

@export var enemy_id = ""
@export var defeated_flag = ""
@export var intro_lines: Array[String] = []


func _ready():
	super._ready()
	if PlayerState.has_flag(defeated_flag):
		queue_free()
		return
	var breathe = create_tween().set_loops()
	breathe.tween_property($Sprite2D, "scale", Vector2(1.05, 0.95) * scale_hint(), 0.7).set_trans(Tween.TRANS_SINE)
	breathe.tween_property($Sprite2D, "scale", Vector2(0.95, 1.05) * scale_hint(), 0.7).set_trans(Tween.TRANS_SINE)


func scale_hint():
	return $Sprite2D.scale.x if $Sprite2D.scale.x > 0 else 1.0


func has_news():
	return true


func interact(player):
	await Dialogue.say(intro_lines, speaker_name)
	player.start_battle(enemy_id)

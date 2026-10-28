extends "res://scripts/world/npc.gd"

# A Glowcap growing on the forest floor. Walk into it to pick it.

@export var glowcap_id = ""


func _ready():
	super._ready()
	if PlayerState.has_flag("glowcap_" + glowcap_id):
		queue_free()
		return
	var glow = create_tween().set_loops()
	glow.tween_property(self, "modulate", Color(1.4, 1.4, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	glow.tween_property(self, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)


func interact(_player):
	PlayerState.set_flag("glowcap_" + glowcap_id)
	hide()
	await give_item("mushroom")
	queue_free()

extends StaticBody2D

# Anything the player can talk to or use by walking into it.
# Simple NPCs just set speaker_name and lines in the inspector. Others override interact().

const Items = preload("res://scripts/data/items.gd")

@export var speaker_name = ""
@export var lines: Array[String] = []

var marker = null


func _ready():
	add_to_group("npc")
	refresh_marker()


func interact(_player):
	await Dialogue.say(lines, speaker_name)


# Story beats broadcast to every NPC with get_tree().call_group("npc", ...)
func on_pip_freed():
	pass


# Override to show a bouncing "!" when this NPC has something new to say.
func has_news():
	return false


func refresh_marker():
	if has_news():
		if marker == null:
			marker = make_marker()
			add_child(marker)
	elif marker != null:
		marker.queue_free()
		marker = null


func make_marker():
	var label = Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-3, -24)
	label.z_index = 10
	var tween = label.create_tween().set_loops()
	tween.tween_property(label, "position:y", -27.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position:y", -24.0, 0.4).set_trans(Tween.TRANS_SINE)
	return label


# Shared helpers for NPC scripts

func give_item(item_id, count = 1):
	PlayerState.add_item(item_id, count)
	Audio.play_sound("obtain_upgrade")
	var item_name = Items.display_name(item_id)
	if count > 1:
		await Dialogue.say(["You got %d %ss!" % [count, item_name]])
	else:
		await Dialogue.say(["You got the %s!" % item_name])


func give_gold(amount):
	PlayerState.earn_gold(amount)
	Audio.play_sound("obtain_upgrade")
	await Dialogue.say(["You got %d gold!" % amount])

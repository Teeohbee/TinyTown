extends "res://scripts/world/npc.gd"

# A treasure chest. Each one has a unique chest_id so it stays open across saves.
# A mimic chest starts a battle instead of giving its loot straight away.

@export var chest_id = ""
@export var item_id = ""
@export var item_count = 1
@export var gold = 0
@export var equipment = ""
@export var mimic = false

@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	super._ready()
	if PlayerState.is_chest_opened(chest_id):
		show_open()


func show_open():
	animated_sprite.play("open")
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("open") - 1
	animated_sprite.pause()


func interact(player):
	if PlayerState.is_chest_opened(chest_id):
		await Dialogue.say(["It's empty."])
		return
	if mimic:
		PlayerState.mark_chest_opened(chest_id)
		await Dialogue.say(["The chest has teeth!"])
		player.start_battle("mimic")
		return
	PlayerState.mark_chest_opened(chest_id)
	animated_sprite.play("open")
	await animated_sprite.animation_finished
	if equipment == "armour":
		Audio.play_sound("obtain_upgrade")
		PlayerState.apply_armour_upgrade()
		await Dialogue.say(["You found some armour! Defence is now 35%."])
	if item_id != "":
		await give_item(item_id, item_count)
	if gold > 0:
		await give_gold(gold)

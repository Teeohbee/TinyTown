extends Control

signal text_box_closed

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
const WORLD_SCENE_PATH = "res://scenes/world.tscn"
const DUNGEON_SCENE_PATH = "res://scenes/dungeon.tscn"

@onready var enemy_name = $Enemy.enemy_name


# Called when the node enters the scene tree for the first time.
func _ready():
	$Enemy/AnimationPlayer.play(INTRO_ANIMATION)
	update_health_bar($EnemyHealth/ProgressBar, $Enemy)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("A " + enemy_name + " draws near!")
	await self.text_box_closed
	hide_text_box()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and $Panel/TextBox.visible:
		emit_signal("text_box_closed")


# Changes the current scene to the world scene when the run button is pressed
func _on_run_pressed():
	show_text_box("You attempt to run away!")
	await self.text_box_closed
	var chance = randi_range(0, 1)
	if chance == 1:
		show_text_box("You managed to escape!")
		await self.text_box_closed
		SceneTransition.change_scene_to_file(DUNGEON_SCENE_PATH)
	else:
		show_text_box("You couldn't escape!")
		await self.text_box_closed
		enemy_turn()


func _on_attack_pressed():
	show_text_box("You attack " + enemy_name + "!")
	await self.text_box_closed
	$Enemy.health = max(0, $Enemy.health - PlayerState.damage)
	update_health_bar($EnemyHealth/ProgressBar, $Enemy)
	$Enemy/AnimationPlayer.play("takes_damage")
	show_text_box("You dealt " + str(PlayerState.damage) + " damage!")
	await self.text_box_closed
	if $Enemy.health == 0:
		enemy_death()
	else:
		enemy_turn()


func _on_defend_pressed():
	show_text_box("You take a defensive position!")
	await self.text_box_closed
	enemy_turn(true)


func enemy_turn(defending: bool = false):
	show_text_box("The " + enemy_name + " attacks you!")
	await self.text_box_closed
	var damage = $Enemy.damage / 2 if defending else $Enemy.damage
	PlayerState.health = max(0, PlayerState.health - damage)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("You took " + str(damage) + " damage!")
	await self.text_box_closed
	if PlayerState.health == 0:
		player_death()
	else:
		hide_text_box()


func player_death():
	show_text_box("You were defeated!")
	await self.text_box_closed
	show_text_box("GAME OVER!")


func enemy_death():
	$Enemy/AnimationPlayer.play("death")
	await $Enemy/AnimationPlayer.animation_finished
	show_text_box("You defeated " + enemy_name + "!")
	await self.text_box_closed
	show_text_box("You earned " + str($Enemy.experience_earned) + " experience!")
	await self.text_box_closed
	if PlayerState.will_level_up($Enemy.experience_earned):
		show_text_box("You leveled up!")
		await self.text_box_closed
	PlayerState.gain_experience($Enemy.experience_earned)
	SceneTransition.change_scene_to_file(DUNGEON_SCENE_PATH)


func show_text_box(message):
	$Panel/TextBox.text = message
	$Panel/ActionButtons.hide()
	$Panel/TextBox.show()


func hide_text_box():
	$Panel/TextBox.hide()
	$Panel/ActionButtons.show()
	$Panel/ActionButtons/Attack.grab_focus()


func update_health_bar(health_bar, character):
	health_bar.value = character.health
	health_bar.max_value = character.max_health
	health_bar.get_node("Label").text = (
		"HP: " + str(character.health) + "/" + str(character.max_health)
	)

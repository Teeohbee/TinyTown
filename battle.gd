extends Control

signal text_box_closed

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
const WORLD_SCENE_PATH = "res://world.tscn"

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
	show_text_box("You managed to escape!")
	await self.text_box_closed
	SceneTransition.change_scene_to_file(WORLD_SCENE_PATH)


func _on_attack_pressed():
	show_text_box("You attacked " + enemy_name + "!")
	await self.text_box_closed
	$Enemy.health -= PlayerState.damage
	update_health_bar($EnemyHealth/ProgressBar, $Enemy)
	show_text_box("You dealt " + str(PlayerState.damage) + " damage!")
	await self.text_box_closed
	enemy_turn()


func enemy_turn():
	show_text_box("The " + enemy_name + " attacked you!")
	await self.text_box_closed
	PlayerState.health -= $Enemy.damage
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("You took " + str($Enemy.damage) + " damage!")
	await self.text_box_closed
	hide_text_box()


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

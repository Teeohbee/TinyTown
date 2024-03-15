extends Control

signal text_box_closed

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
const WORLD_SCENE_PATH = "res://world.tscn"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Enemy/AnimationPlayer.play(INTRO_ANIMATION)
	update_health_bar($EnemyHealth/ProgressBar, $Enemy)
	update_health_bar($PlayerHealth/ProgressBar, PlayerState)
	show_text_box("A " + $Enemy.enemy_name + " draws near!")
	await self.text_box_closed
	hide_text_box()
	$Panel/ActionButtons/Attack.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and $Panel/TextBox.visible:
		emit_signal("text_box_closed")


# Changes the current scene to the world scene when the run button is pressed
func _on_run_pressed():
	show_text_box("You managed to escape!")
	await self.text_box_closed
	SceneTransition.change_scene_to_file(WORLD_SCENE_PATH)


func show_text_box(message):
	$Panel/TextBox.text = message
	$Panel/ActionButtons.hide()
	$Panel/TextBox.show()


func hide_text_box():
	$Panel/TextBox.hide()
	$Panel/ActionButtons.show()


func update_health_bar(health_bar, character):
	health_bar.value = character.health
	health_bar.max_value = character.max_health
	health_bar.get_node("Label").text = (
		"HP: " + str(character.health) + "/" + str(character.max_health)
	)

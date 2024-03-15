extends Control

# Constants for animation names and scene paths
const INTRO_ANIMATION = "intro"
const WORLD_SCENE_PATH = "res://world.tscn"


# Called when the node enters the scene tree for the first time.
func _ready():
	$TextureRect/AnimationPlayer.play(INTRO_ANIMATION)
	$Panel/ActionButtons/Attack.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Changes the current scene to the world scene when the run button is pressed
func _on_run_pressed():
	SceneTransition.change_scene_to_file(WORLD_SCENE_PATH)

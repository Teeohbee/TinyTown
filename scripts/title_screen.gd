extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.grab_focus()


func _on_button_pressed():
	$Button/StartGame.play()
	await $Button/StartGame.finished
	SceneTransition.change_scene_to_file("res://scenes/world.tscn")

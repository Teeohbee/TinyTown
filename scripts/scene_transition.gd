extends CanvasLayer

# Fades to black, swaps the scene, fades back in. Ignores requests while one is running.

const DISSOLVE_ANIMATION = "dissolve"

var transitioning = false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100


func is_transitioning():
	return transitioning


# Changes the current scene to the one specified by the file path
func change_scene_to_file(file):
	if transitioning:
		return
	transitioning = true
	$AnimationPlayer.play(DISSOLVE_ANIMATION)
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	get_tree().change_scene_to_file(file)
	await get_tree().process_frame
	$AnimationPlayer.play_backwards(DISSOLVE_ANIMATION)
	await $AnimationPlayer.animation_finished
	transitioning = false

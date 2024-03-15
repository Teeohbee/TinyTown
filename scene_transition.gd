extends CanvasLayer

# Constants
const DISSOLVE_ANIMATION = "dissolve"


# Changes the current scene to the one specified by the file path
func change_scene_to_file(file):
	$AnimationPlayer.play(DISSOLVE_ANIMATION)
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(file)
	$AnimationPlayer.play_backwards(DISSOLVE_ANIMATION)

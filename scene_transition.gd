extends CanvasLayer

func change_scene_to_file(file):
	$AnimationPlayer.play('dissolve')
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(file)
	$AnimationPlayer.play_backwards('dissolve')

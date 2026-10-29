extends Control

# Rolls the credits after Chapter 2, then back to the title screen.

const SCROLL_SECONDS = 22.0

var can_leave = false

@onready var scroll = $Clip/Scroll
@onready var stats_label = $Clip/Scroll/Stats
@onready var prompt_label = $Prompt


func _ready():
	Audio.play_music("town", 0.9)
	stats_label.text = "Level %d\n%d battles won\nPlayed for %s" % [
		PlayerState.level, PlayerState.battles_won, PlayerState.format_play_time(PlayerState.play_time_seconds)]
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(scroll, "position:y", 520.0 - scroll.size.y, SCROLL_SECONDS)
	await get_tree().create_timer(3.0).timeout
	can_leave = true
	var prompt_tween = create_tween()
	prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)


func _process(_delta):
	if can_leave and Input.is_action_just_pressed("ui_accept"):
		can_leave = false
		Audio.play_sound("menu_click")
		SceneTransition.change_scene_to_file("res://scenes/title_screen.tscn")

extends Control

# Shown after losing a battle. Waking up in town keeps your progress but costs half
# your gold, your progress to the next level and the archer's win streak.

@onready var subtitle_label = $Rows/Subtitle
@onready var buttons = $Rows/Buttons
@onready var load_button = $Rows/Buttons/LoadSave


func _ready():
	subtitle_label.text = "You wake up by the well. (Lose half your gold: %d G)" % (PlayerState.gold - PlayerState.gold / 2)
	load_button.visible = PlayerState.has_save()
	for button in buttons.get_children():
		button.focus_entered.connect(func(): Audio.play_sound("menu_select"))
	$Rows/Buttons/WakeUp.pressed.connect(on_wake_up_pressed)
	load_button.pressed.connect(on_load_pressed)
	$Rows/Buttons/Title.pressed.connect(on_title_pressed)
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2)
	await tween.finished
	$Rows/Buttons/WakeUp.grab_focus()


func on_wake_up_pressed():
	Audio.play_sound("menu_click")
	PlayerState.record_defeat()
	SceneTransition.change_scene_to_file(PlayerState.current_scene_path)


func on_load_pressed():
	Audio.play_sound("menu_click")
	if PlayerState.load_game():
		SceneTransition.change_scene_to_file(PlayerState.current_scene_path)


func on_title_pressed():
	Audio.play_sound("menu_click")
	SceneTransition.change_scene_to_file("res://scenes/title_screen.tscn")

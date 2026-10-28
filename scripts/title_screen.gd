extends Control

const FIRST_SCENE_PATH = "res://scenes/world.tscn"

var starting = false

@onready var buttons = $MenuPanel/Buttons
@onready var continue_button = $MenuPanel/Buttons/Continue
@onready var save_summary_label = $SaveSummary
@onready var options_panel = $OptionsPanel
@onready var options_menu = $OptionsPanel/OptionsMenu
@onready var art = $Art


func _ready():
	get_tree().paused = false
	Audio.play_music("town", 0.8)
	continue_button.visible = PlayerState.has_save()
	save_summary_label.text = PlayerState.save_summary()
	save_summary_label.visible = PlayerState.has_save()
	for button in buttons.get_children():
		button.focus_entered.connect(func(): Audio.play_sound("menu_select"))
	continue_button.pressed.connect(on_continue_pressed)
	$MenuPanel/Buttons/NewGame.pressed.connect(on_new_game_pressed)
	$MenuPanel/Buttons/Options.pressed.connect(on_options_pressed)
	$MenuPanel/Buttons/Quit.pressed.connect(on_quit_pressed)
	options_menu.closed.connect(on_options_closed)
	# Quit makes no sense in a browser build
	$MenuPanel/Buttons/Quit.visible = not OS.has_feature("web")
	$Version.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	focus_default_button()
	var breathe = create_tween().set_loops()
	breathe.tween_property(art, "scale", Vector2(1.02, 1.02), 3.0).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(art, "scale", Vector2.ONE, 3.0).set_trans(Tween.TRANS_SINE)


func focus_default_button():
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		$MenuPanel/Buttons/NewGame.grab_focus()


func on_continue_pressed():
	if starting:
		return
	if not PlayerState.load_game():
		save_summary_label.text = "That save couldn't be read."
		return
	start(PlayerState.current_scene_path)


func on_new_game_pressed():
	if starting:
		return
	if PlayerState.has_save():
		Audio.play_sound("menu_click")
		var answer = await Dialogue.choose("Start a new game? Your saved game will be replaced when you next save.", ["New game", "Cancel"])
		if answer != 0:
			focus_default_button()
			return
	PlayerState.new_game()
	start(FIRST_SCENE_PATH)


func start(scene_path):
	starting = true
	Audio.stop_music()
	await Audio.play_sound_and_wait("start_game")
	SceneTransition.change_scene_to_file(scene_path)


func on_options_pressed():
	Audio.play_sound("menu_click")
	options_panel.show()
	options_menu.focus_first_row()


func on_options_closed():
	options_panel.hide()
	$MenuPanel/Buttons/Options.grab_focus()


func on_quit_pressed():
	get_tree().quit()

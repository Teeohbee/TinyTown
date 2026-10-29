extends VBoxContainer

# Options list used by both the title screen and the pause menu.
# Each row is a button; left and right change its value, accept toggles or steps it.

signal closed

const VOLUME_STEP = 10

var rows = {}

@onready var rows_container = $Rows


func _ready():
	for row_name in ["music", "sound", "text_speed", "fullscreen", "screen_shake", "back"]:
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(560, 0)
		button.pressed.connect(func(): on_row_pressed(row_name))
		button.focus_entered.connect(func(): Audio.play_sound("menu_select"))
		rows_container.add_child(button)
		rows[row_name] = button
	refresh_rows()


func focus_first_row():
	rows["music"].grab_focus()


func refresh_rows():
	rows["music"].text = "Music        < %d%% >" % Settings.music_volume_percent
	rows["sound"].text = "Sound        < %d%% >" % Settings.sound_effects_volume_percent
	rows["text_speed"].text = "Text speed   < %s >" % Settings.text_speed_name()
	rows["fullscreen"].text = "Fullscreen   < %s >" % on_off(Settings.fullscreen)
	rows["screen_shake"].text = "Screen shake < %s >" % on_off(Settings.screen_shake)
	rows["back"].text = "Back"


func on_off(value):
	return "On" if value else "Off"


func _process(_delta):
	if not is_visible_in_tree():
		return
	var focused_row = focused_row_name()
	if focused_row == "":
		return
	if Input.is_action_just_pressed("ui_left"):
		change_row(focused_row, -1)
	elif Input.is_action_just_pressed("ui_right"):
		change_row(focused_row, 1)
	elif Input.is_action_just_pressed("ui_cancel"):
		close()


func focused_row_name():
	for row_name in rows.keys():
		if rows[row_name].has_focus():
			return row_name
	return ""


func on_row_pressed(row_name):
	if row_name == "back":
		close()
	else:
		change_row(row_name, 1)


func change_row(row_name, step):
	match row_name:
		"music":
			Settings.music_volume_percent = clampi(Settings.music_volume_percent + step * VOLUME_STEP, 0, 100)
		"sound":
			Settings.sound_effects_volume_percent = clampi(Settings.sound_effects_volume_percent + step * VOLUME_STEP, 0, 100)
		"text_speed":
			Settings.text_speed = wrapi(Settings.text_speed + step, 0, Settings.TEXT_SPEED_NAMES.size())
		"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		"screen_shake":
			Settings.screen_shake = not Settings.screen_shake
		_:
			return
	Settings.apply_settings()
	Settings.save_settings()
	Audio.play_sound("menu_click")
	refresh_rows()


func close():
	Audio.play_sound("menu_click")
	emit_signal("closed")
